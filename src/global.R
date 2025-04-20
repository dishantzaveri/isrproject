
nodename <- Sys.info()[['nodename']]
projectName <- tail(strsplit(getwd(), '/')[[1]], 1)
drive_path <- '/srv/'
.libPaths(c(paste0(drive_path, 'shiny-server/public/', projectName, '/src/lib'), .libPaths()))
if (dir.exists('/srv/shiny-server/InsiderTrading')) {
  setwd('/srv/shiny-server/InsiderTrading')
}

rglBgColor <- '#174d89'
heatmapBgColor <- '#174d89'

# Import Libraries
#################################

# Base Packages
# Use check_package('package_name') to check if it exist before adding it here.
# This will reload the start-up time of shiny significantly.
# No need to load package if there's minimal usage of it.
# Instead add it to hidden and call it via <package_name>::
base_dependencies <- list(
  # Check for attached Packages with
  # names(sessionInfo()$otherPkgs)
  'attached' = c(
    'rlang', 'reticulate', 'magrittr', 'shiny'
  ),
  'hidden' = c(
    'reactR', 'shinydashboard', 'shinyBS', 'bsplus', 'shinydashboardPlus',
    'shinyjqui', 'shinyWidgets', 'shinycssloaders',
    'tidyverse', 'rlist', 'sodium',
    'DT', 'plotly', 'shinyChatR'
  )
)



# Module Packages
module_dependencies <- c()

# App Packages
app_dependencies <- list(
  'attached' = c(
    
  ),
  'hidden' = c(
    'httr', 'clusterSim', 'factoextra'
  )
)

# Load Packages
# Faster load time compared to loading it individually
suppressWarnings(suppressMessages(invisible(
  lapply(c(base_dependencies$attached, module_dependencies, app_dependencies$attached), library, character.only = T, quietly = T)
)))

#invisible(lapply(base_dependencies$hidden, function(pkg) {
#  if (!requireNamespace(pkg, quietly = TRUE)) {
#    install.packages(pkg)
#  }
#  suppressWarnings(suppressMessages(library(pkg, character.only = TRUE)))
#}))


# Python Modules
# Naming Convention:
# <package-name> = <module-name>
py_dependencies <- c(
  'numpy==1.22.3', 'pandas==1.5.2',
  'openai',
  #  'prophet==1.1.5',
   'yahoo_fin', 'requests==2.31.0'
)


# Prepare Reticulate Python Environment
#if (!('SIH' %in% reticulate::conda_list()[['name']])) {
#  reticulate::conda_create('SIH', packages = 'numpy=1.22.3', python_version = '3.10')
#  reticulate::conda_install(
#    envname = 'SIH',
#    packages = py_dependencies,
#    pip = TRUE,
#    pip_options = '--upgrade-strategy only-if-needed'
#  )
#}

# Use it
#reticulate::use_condaenv('SIH', required = TRUE)

# List of Python dependencies to install via pip
py_dependencies <- c(
  "numpy==1.22.3", 
  "pandas==1.5.2",
  "openai",
  # "prophet",
  "yahoo_fin",
  "requests==2.31.0"
)

# Check if the 'SIH' environment exists
if (!("SIH" %in% reticulate::conda_list()$name)) {
  message("Creating 'SIH' Conda environment...")
  reticulate::conda_create("SIH", packages = "python=3.10")

  
  # Install everything via pip to avoid conda/pip mixing issues
  reticulate::py_install(
    packages = py_dependencies,
    envname = "SIH",
    pip = TRUE,
    method = "auto"
  )
}

# Use the environment
reticulate::use_condaenv("SIH", required = TRUE)


options(default.stringsAsFactors = F)
options(readr.show_col_types = F)
options(reticulate.repl.quiet = T)
options(spinner.type = 5)
options(spinner.color = '#30beff')

R.utils::sourceDirectory("src/components/modules/UserManagement", modifiedOnly = FALSE)
if (!dir.exists("logs")) dir.create("logs")
if (!file.exists("logs/access.log")) {
  createAccessLog()
}

####################################################
robust.system <- function(cmd) {
  stderrFile = tempfile(pattern = "R_robust.system_stderr", fileext = as.character(Sys.getpid()))
  stdoutFile = tempfile(pattern = "R_robust.system_stdout", fileext = as.character(Sys.getpid()))

  retval = list()
  retval$exitStatus = system(paste0(cmd, " 2> ", shQuote(stderrFile), " > ", shQuote(stdoutFile)))
  retval$stdout = readLines(stdoutFile)
  retval$stderr = readLines(stderrFile)

  unlink(c(stdoutFile, stderrFile))
  return(retval)
}


# Generic Functions
#######################################################################
`%!in%` <- Negate(`%in%`)

all_avail_packages <- function() {
  c(unlist(base_dependencies), module_dependencies, app_dependencies) %>%
    tools::package_dependencies(recursive = T, db = installed.packages()) %>%
    unlist() %>%
    unique()
}

check_package <- function(x) {
  x %in% all_avail_packages()
}

provided <- function(data, condition, call, call2 = NULL) {
  condition <- ifelse(is.logical(condition), condition, rlang::eval_tidy(rlang::enquo(condition), data))

  if (condition) {
    rlang::eval_tidy(rlang::quo_squash(rlang::quo(data %>% !!rlang::enquo(call))))
  } else if (!is.null(call2)) {
    rlang::eval_tidy(rlang::quo_squash(rlang::quo(data %>% !!rlang::enquo(call2))))
  } else data
}

formatDTDisplay <- function(
  x, selectChoice = 'multiple', currencyCol = NULL, roundCol = NULL, roundDigit = 2, rownames = F,
  pagelen = 50, scrollX = T, scrollY = "500px", dom = 'T<"clear">lBfrtip'
) {
  DT::datatable(x,
    selection = selectChoice, rownames = rownames, filter = 'top', escape = F,
    options = list(pageLength = pagelen, dom = dom, scrollX = scrollX, scrollY = scrollY)
  ) %>%
  provided(!is.null(currencyCol), DT::formatCurrency(currencyCol, currency = "", interval = 3, mark = ",")) %>%
  provided(!is.null(roundCol), DT::formatRound(roundCol, digits = roundDigit))
}

modify_stop_propagation <- function(x) {
  x$children[[1]]$attribs$onclick = "event.stopPropagation()"
  x
}

createLink <- function(val, disp = 'Link') {
  sprintf('<a href="%s" target="_blank">%s</a>', val, disp)
}

create_btns <- function(x, ns = shiny::NS(''), username = NULL, admin = F) {
  if (admin) {
    x %>%
      purrr::map_chr(~ as.character(
        shiny::actionButton(ns(paste0('reset_', .x)), '', icon = shiny::icon('key'), class = 'btn-warning', onclick = 'get_id(this.id)')
      ))
  } else {
    x %>%
      purrr::map_chr(~ as.character(
        htmltools::div(class = "btn-group",
          if (shiny::isTruthy(.x)) {
            shiny::actionButton(ns(paste0('edit_', .x)), '', icon = shiny::icon('edit'), class = 'btn-info', onclick = 'get_id(this.id)')
          } else {
            shiny::actionButton(ns(paste0('new_', .x)), '', icon = shiny::icon('plus'), class = 'btn-success', onclick = 'get_id(this.id)')
          },
          if (shiny::isTruthy(.x)) {
            shiny::actionButton(ns(paste0('reset_', .x)), '', icon = shiny::icon('key'), class = 'btn-warning', onclick = 'get_id(this.id)')
          },
          if (.x != username && shiny::isTruthy(.x)) {
            shiny::actionButton(ns(paste0('delete_', .x)), '', icon = shiny::icon('trash-alt'), class = 'btn-danger', onclick = 'get_id(this.id)')
          }
        )
      ))
  }
}

create_delete_btns <- function(x, ns = shiny::NS('')) {
  purrr::map_chr(x, ~ paste0(
    '<button class="btn btn-default action-button message-button" id="',
    ns(paste0('delete_', .x)),
    '" type="button" onclick=delete_chat(this.id)><i class="fa fa-trash-alt"></i></button></div>'
  ))
}

getClusters <- function(selectedDate) {
  purrr::map(list.files('db/NASDAQ/market_data'),
    ~ readr::read_csv(sprintf('db/NASDAQ/market_data/%s', .x), show_col_types = F) %>%
      dplyr::mutate(
        'Ticker' = stringr::str_extract(.x, '[A-Z]*(?=\\.csv)'),
        'Volume Change' = 100 * (`Volume` - dplyr::lag(`Volume`)) / `Volume`,
        'Open Change' = 100 * (`Open` - dplyr::lag(`Open`)) / `Open`, 'Close Change' = 100 * (`Close` - dplyr::lag(`Close`)) / `Close`,
        'High Change' = 100 * (`High` - dplyr::lag(`High`)) / `High`, 'Low Change' = 100 * (`Low` - dplyr::lag(`Low`)) / `Low`
      ) %>%
      dplyr::select(
        `Ticker`, `Date`, `Volume`, `Volume Change`,
        `Open`, `Open Change`, `Close`, `Close Change`,
        `High`, `High Change`, `Low`, `Low Change`
      )
  ) %>%
    dplyr::bind_rows() %>%
    dplyr::mutate('Year' = stringr::str_extract(`Date`, '[0-9]{4}')) %>%
    dplyr::group_by(`Year`) %>%
    dplyr::group_split() %>%
    purrr::map(~ readr::write_csv(.x, sprintf('db/clustering/data/%s.csv', .x$Year[[1]])))
  
  clusterDF <- readr::read_csv(sprintf('db/clustering/data/%s.csv', stringr::str_extract(selectedDate, '[0-9]{4}')), show_col_types = F) %>%
    dplyr::filter(as.Date(`Date`) == as.Date(selectedDate))
  
  marketDFN <- dplyr::select(clusterDF, -`Ticker`, -`Date`, -`Year`) %>%
    as.matrix() %>%
    clusterSim::data.Normalization(type = 'n1', normalization = 'column')
  
  PCA <- prcomp(marketDFN, center = F, scale. = F)
  PCA <- prcomp(marketDFN, center = F, scale. = F, rank. = nrow(dplyr::filter(factoextra::get_eigenvalue(PCA), `eigenvalue` > 1)))
  
  num_cluster <- factoextra::fviz_nbclust(PCA$x, FUNcluster = kmeans, k.max = 8)$data %>%
    dplyr::filter(dplyr::lead(`y`) < `y`) %>%
    dplyr::slice_head(n = 1) %>%
    dplyr::pull(`clusters`) %>%
    as.numeric()
  
  clusters <- factoextra::eclust(PCA$x, 'kmeans', hc_metric = 'eucliden', k = num_cluster, graph = F)
  
  dplyr::mutate(clusterDF, 'Cluster' = clusters$cluster)
}



# Javascript Addons
#######################################################################
jscode <- 'shinyjs.collapse = function(boxid) { $("#" + boxid).closest(".box").find("[data-widget=collapse]").click(); };'


# App Static Data
#################################
wwwBaseDir <- 'www'

tickerList <- intersect(
  stringr::str_extract(list.files('db/pickle'), '^[A-Z]*(?=\\.)'),
  stringr::str_extract(list.files('db/NASDAQ/insider_data'), '^[A-Z]*(?=\\.)')
)

metaDF <- readr::read_csv('db/NASDAQ/meta.csv', show_col_types = F) %>%
  dplyr::filter(`Symbol` %in% tickerList) %>%
  dplyr::mutate(
    'Company Name' = stringr::str_replace_all(`Security Name`, '-|\\([A-z\\s]*\\)', '') %>%
      { ifelse(stringr::str_detect(., 'Common|Index|Ordinary'), stringr::str_extract(., '.*(?=(\\s)(Common|Index|Ordinary))'), .) } %>%
      { ifelse(stringr::str_detect(., 'Class'), stringr::str_extract(., '.*(?=(\\s)(Class [A-Z]))'), .) } %>%
      stringr::str_trim()
  ) %>%
  dplyr::mutate(
    'Stock Type' = stringr::str_replace_all(`Security Name`, ' - |\\([A-z\\s]*\\)', '') %>%
      stringr::str_replace(`Company Name`, '') %>%
      stringr::str_trim() %>%
      { ifelse(is.na(.) | . == '', 'Common Stock', .) }
  )

tickerList <- intersect(tickerList, dplyr::pull(metaDF, `Symbol`)) %>%
  rlang::set_names(dplyr::pull(metaDF, `Company Name`))


GPT <- reticulate::import_from_path('GPT', 'src/components/modules/LLM', convert = T)


# App Initialization
#################################

# Modules
R.utils::sourceDirectory('src/components/modules', pattern = '.*\\.(r|R)$', modifiedOnly = F, recursive = T)
pythonModules <- list.files('src/components/modules', pattern = '[^_][:alnum:]*.py$', recursive = T, full.names = T)

# Widgets
source('src/components/widgets/widgets.R')

# Pages
R.utils::sourceDirectory('src/pages/', modifiedOnly = F, recursive = T)
pythonPages <- list.files('src/pages/', pattern = '[^_][:alnum:]*.py$', recursive = T, full.names = T)

# Page Router
source('src/components/layout/AppPages.R')

# App Layout
R.utils::sourceDirectory('src/components/layout/', modifiedOnly = F)

# Python
pythonFiles <- c(pythonPages, pythonModules)
invisible(lapply(pythonPages, reticulate::source_python))

# Scripts


addDeps <- function(tag, options = NULL, ...) {
  # always use minified files (https://www.minifier.org)
  adminLTE_js <- ifelse(getOption("shiny.minified", T), "js/app.min.js", "js/app.js")
  shinydashboardPlus_js <- ifelse(getOption("shiny.minified", T), "js/shinydashboardPlus.min.js", "js/shinydashboardPlus.js")

  pkg_version <- as.character(utils::packageVersion("shinydashboardPlus"))

  dashboardDeps <- list(
    # custom adminLTE js and css for shinydashboardPlus
    htmltools::htmlDependency(
      "shinydashboardPlus-bindings",
      pkg_version,
      c(file = system.file(sprintf("shinydashboardPlus-%s", pkg_version), package = "shinydashboardPlus")),
      script = c(adminLTE_js, shinydashboardPlus_js)
    ),
    htmltools::htmlDependency(
      "shinydashboardPlus-css",
      pkg_version,
      c(file = system.file(sprintf("shinydashboardPlus-%s", pkg_version), package = "shinydashboardPlus")),
      stylesheet = c('css/AdminLTE.min.css')
    ),
    # shinydashboard css and js deps
    htmltools::htmlDependency(
      "shinydashboard-bindings",
      pkg_version,
      c(file = system.file(package = "shinydashboard"))
    ),
    htmltools::htmlDependency(
      "shinydashboard-css",
      pkg_version,
      c(file = system.file(package = "shinydashboard")),
      stylesheet = "shinydashboard.css"
    )
  )

  shiny::tagList(tag, dashboardDeps)
}

dashboardUI <- function(header, sidebar, body, scrollToTop = F, ...) {
  extractTitle <- function(header) {
    x <- header$children[[1]]
    if (x$name == "span" && !is.null(x$attribs$class) && x$attribs$class == "logo" && length(x$children) != 0) {
        x$children[[1]]
    } else {
      ""
    }
  }
  title <- extractTitle(header)
  
  content <- htmltools::div(class = "wrapper", header, sidebar, body)

  addDeps(htmltools::tags$body(
    `data-scrollToTop` = as.numeric(scrollToTop),
    class = 'hold-transition skin-blue', `data-skin` = 'blue', style = "min-height: 611px;",
    shiny::bootstrapPage(content, title = title, ...)
  ))
}




# End of script




# Dashboard Pages Module
#################################

RAppPageList <- stringr::str_extract(list.files('src/pages/', pattern = '*.R', recursive = T), '[^.]+') %>%
    purrr::discard(function(x) isTRUE(tryCatch(get(paste0(x, 'PageConfig'))$disabled)))

PyAppPageList <- stringr::str_extract(list.files('src/pages/', pattern = '[^_][:alnum:]*.py$', recursive = T), '[^.]+') %>%
    purrr::discard(function(x) isTRUE(tryCatch(py[paste0(x, 'PageConfig')]$disabled)))

AppPageList <- sort(c(RAppPageList, PyAppPageList))



# App Pages UI
#################################

AppPagesUI <- function(id) {

  ns <- shiny::NS(id)

  RPageUIList <- lapply(RAppPageList, function(x) {
    shinydashboard::tabItem(tabName = stringr::str_to_lower(x), get(paste0(x, 'ModuleUI'))(ns(paste0(x, 'PageModule'))))
  })

  PyPageUIList <- lapply(PyAppPageList, function(x) {
    shinydashboard::tabItem(tabName = stringr::str_to_lower(x),
      shiny::column(12,
        py[paste0(x, 'ModuleUI')]('PLACEHOLDER_NAMESPACE_')$get_html_string() %>%
          as.character() %>%
          stringr::str_replace_all('(?<=id=(\'|\"))PLACEHOLDER_NAMESPACE_(?=[^\'\"]*(\"|\'))', ns(paste0(x, 'PageModule-'))) %>%
          htmltools::HTML()
      )
    )
  })

  do.call(shinydashboard::tabItems, purrr::compact(c(RPageUIList, PyPageUIList)))
}



# App Pages Server
#################################

AppPages <- function(input, output, session, ...) {

  ns <- session$ns
  credentials <- shiny::reactive({shiny::req(session$userData$credentials())})
  permissions <- shiny::reactive({shiny::req(credentials()$info$permissions)})
  AppPagesData <- do.call(shiny::reactiveValues, sapply(AppPageList, function(x) NULL))

  shiny::observeEvent(permissions(), {
    RAppPageList %>%
      purrr::keep(~ any(
        permissions() %in% get(paste0(.x, 'PageConfig'))[['permission']],
        setequal(get(paste0(.x, 'PageConfig'))[['permission']], permissions())
      )) %>%
      lapply(function(x) {
        shiny::callModule(get(paste0(x, 'Module')), paste0(x, 'PageModule'), pageName = x, appData = AppPagesData, ...)
      })

    PyAppPageList %>%
      purrr::keep(~ any(
        permissions() %in% py[paste0(.x, 'PageConfig')][['permission']],
        setequal(py[paste0(.x, 'PageConfig')][['permission']], permissions())
      )) %>%
      lapply(function(x) {
        shiny::callModule(pythonServerModule, paste0(x, 'PageModule'), pageName = x, appData = AppPagesData, ...)
      })
  }, once = T)
}



# Python Page Module Extension
#################################

pythonServerModule <- function(input, output, session, pageName, appData, ...) {

  ns <- session$ns
  rlang::env_bind(parent.env(environment()), ...)
  credentials <- shiny::reactive({ shiny::req(session$userData$credentials()) })
  username <- shiny::reactive({ shiny::req(credentials()$info$username) })
  shiny::observe({ appendAccessLog(username(), getwd(), pageName, '', '') })

  # Define Reactive Data
  pyStaticData <- list()
  pyReactiveData <- shiny::reactiveValues(
    credentials = shiny::req(credentials()),
    username = shiny::req(username())
  )
  pyFullData <- shiny::reactive({
    c(pyStaticData, shiny::reactiveValuesToList(input), shiny::reactiveValuesToList(shiny::req(pyReactiveData)))
  })

  # Import Python Page Module
  serverOutput <- reticulate::import(paste('src.pages', pageName, sep = '.'))$output$items()

  # Create Reactive Data for Python Modules
  pyCalc <- sapply(serverOutput, function(x) {
    shiny::eventReactive(lapply(x$args, function(arg) input[[arg]]), {
      do.call(x$func, pyFullData()[names(pyFullData()) %in% x$args])
    }, ignoreNULL = F, ignoreInit = F)
  })

  # Render UI
  lapply(names(serverOutput), function(x) {
    renderType <- serverOutput[[x]]$renderType

    if (renderType == 'renderUI') {
      # Render UI/HTML
      output[[x]] <- get(serverOutput[[x]]$rRenderFunc)({
        pyCalc[[x]]()$get_html_string() %>%
          as.character() %>%
          stringr::str_replace_all('(?<=id=(\'|\"))PLACEHOLDER_NS_(?=[^\'\"]*(\"|\'))', ns('')) %>%
          htmltools::HTML()
      })
    } else if (renderType == 'renderPlotly') {
      # Render Plotly Div
      output[[x]] <- shiny::renderUI(plotly::plotlyOutput(ns(paste(x, 'Container'))))

      # Render Plotly Graph
      output[[paste(x, 'Container')]] <- plotly::renderPlotly({
        pyCalc[[x]]()$to_plotly_json() %>%
          plotly::plotly_build()
      })
    } else {
      # Default Render
      output[[x]] <- get(serverOutput[[x]]$rRenderFunc)(pyCalc[[x]]())
    }
  })
}























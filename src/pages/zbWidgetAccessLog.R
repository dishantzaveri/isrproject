


zbWidgetAccessLogModuleUI <- function(id) {
  ns <- NS(id)

  htmltools::div(class = 'page',
    shiny::column(12, style = 'margin: 1rem; padding: 1rem; border: 1px solid #36A2E0; width: calc(100% - 2rem);',
      shiny::actionButton(ns('refresh'), 'Refresh') %>%
        htmltools::tagAppendAttributes(class = 'button1', style = 'color: #FFF')
    ),
    shinydashboard::box(width = 12, shiny::fluidRow(
      shiny::column(4, plotly::plotlyOutput(ns('userView'))),
      shiny::column(4, plotly::plotlyOutput(ns('userDateView'))),
      shiny::column(4, plotly::plotlyOutput(ns('dateUserView')))
    )) %>%
      htmltools::tagAppendAttributes(.cssSelector = '.box-body', style = 'background: #002D4B;'),
    shinydashboard::box(title = 'accessUserView', width = 12, status = "primary", collapsible = T, class = 'classic-dt',
      DT::DTOutput(ns('accessUser'))
    ),
    shinydashboard::box(title = 'accessLogDetails', width = 12, status = "primary", collapsible = T, class = 'classic-dt',
      DT::DTOutput(ns('accessLog'))
    )
  )
}

zbWidgetAccessLogModule <- function(input, output, session, ...) {


  # Module Data
  ###############################

  # init
  ns <- session$ns
  rlang::env_bind(parent.env(environment()), ...)
  credentials <- shiny::reactive({ shiny::req(session$userData$credentials()) })
  username <- shiny::reactive({ shiny::req(credentials()$info$username) })
  shiny::observe({ appendAccessLog(username(), getwd(), session$ns('name'), '', '') })


  # Page Data
  ###############################

  # Access Log Data
  accessLog <- shiny::reactive({
    input$refresh

    getAccessLog()
  })

  # Access Log Table
  output$accessLog <- DT::renderDT({
    dplyr::select(accessLog(), -`page`) %>%
      formatDTDisplay()
  })

  # Access Log Bar Charts
  output$userView <- plotly::renderPlotly({
    accessLog() %>%
      dplyr::group_by(`username`) %>%
      dplyr::summarise(`Date` = dplyr::n()) %>%
      plotly::plot_ly(x = ~username, y = ~Date, type = 'bar') %>%
      plotly::layout(title = 'Access count by user', xaxis = list(title = 'Username'))
  })

  output$userDateView <- plotly::renderPlotly({
    accessLog() %>%
      dplyr::group_by(`username`, `Date`) %>%
      dplyr::summarise(`Module` = dplyr::n(), .groups = 'drop_last') %>%
      dplyr::summarise(`Date` = dplyr::n()) %>%
      plotly::plot_ly(x = ~username, y = ~Date, type = 'bar') %>%
      plotly::layout(title = 'Access count by user (unique Date)', xaxis = list(title = 'Username'), yaxis = list(title = 'Visits'))
  })


  output$dateUserView <- plotly::renderPlotly({
    accessLog() %>%
      dplyr::group_by(`Date`, `username`) %>%
      dplyr::summarise(`Module` = dplyr::n(), .groups = 'drop_last') %>%
      dplyr::summarise(`username` = dplyr::n()) %>%
      plotly::plot_ly(x = ~username, y = ~Date, type = 'bar') %>%
      plotly::layout(title = 'Access count by Date (Unique Users)', xaxis = list(title = 'Unique Users'))
  })

  # User View
  output$accessUser <- DT::renderDT({
    accessLog() %>%
      dplyr::group_by(`username`) %>%
      dplyr::summarise(AccessCnt = dplyr::n(), uniqueDateCnt = length(unique(Date)), earliestDate = min(`Date`), latestDate = max(`Date`)) %>%
      dplyr::ungroup() %>%
      formatDTDisplay()
  })
}



# Page Config
#################################

zbWidgetAccessLogPageConfig <- list(

  # Disable Page
  # disabled = T,

  # Title for menu
  'title' = 'Access Log',

  # Sub-menu
  'submenu' = 'Settings',

  # Icon for menu
  'icon' = 'file-text',

  # Roles with permission to view page.
  # Exclusion will cause user to be TOTALLY unable to view page
  # Partial permission will have to be controlled within module
  'permission' = c('admin')
)







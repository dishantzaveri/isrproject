
# Source Theme
# source('src/components/layout/AppTheme.R')



# Dashboard Body Module
#################################

AppBodyContentUI <- function(id) {

  ns <- shiny::NS(id)

  htmltools::tagList(
    loginUI(ns('login'), title = 'Fraud AI-Consultant'),
    AppPagesUI(ns('AppPages'))
  )
}


AppBody <- function(input, output, session, ...) {

  ns <- session$ns
  rlang::env_bind(parent.env(environment()), ...)

  # Authentication
  shiny::callModule(logout, "logout", session = global)
  shiny::callModule(login, "login", global = global)

  # Main App
  shiny::callModule(AppPages, 'AppPages', ...)
}



# Dashboard Body UI
#################################

AppBodyUI <- shinydashboard::dashboardBody(
  style = 'padding: 0;',

  # Scripts
  htmltools::tags$head(
    htmltools::tags$link(rel = 'preconnect', href = 'https://fonts.googleapis.com'),
    htmltools::tags$link(rel = 'preconnect', href = 'https://fonts.gstatic.com', crossorigin = NA),
    htmltools::tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=Oxanium:wght@200;300;400;500;600;700"),
    htmltools::tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=Roboto:wght@100;300;400;500;700;900&display=swap"),
    htmltools::tags$link(rel = 'stylesheet', href = 'https://fonts.googleapis.com/icon?family=Material+Icons'),
    htmltools::tags$script(crossorigin = 'anonymous', src = 'https://unpkg.com/react@17/umd/react.development.js'),
    htmltools::tags$script(crossorigin = 'anonymous', src = 'https://unpkg.com/react-dom@17/umd/react-dom.development.js'),
    htmltools::tags$script(crossorigin = 'anonymous', src = 'https://unpkg.com/@mui/material@latest/umd/material-ui.production.min.js'),
    htmltools::tags$link(rel = "stylesheet", type = "text/css", href = 'demo.css'),
    htmltools::tags$link(rel = "stylesheet", type = "text/css", href = 'style.css'),
    htmltools::tags$script(type = 'text/javascript', src = 'main.js'),
    shinyjs::useShinyjs()
  ),

  AppBodyContentUI('AppBodyContent')
)





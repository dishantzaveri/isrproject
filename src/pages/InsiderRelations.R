library(shiny)
library(shinyWidgets)
library(DT)
library(visNetwork)
library(readr)
library(dplyr)

InsiderRelationsModuleUI <- function(id) {
  ns <- NS(id)

  tagList(
      tags$style(HTML("
        .bootstrap-select .dropdown-toggle {
          background-color: #174d89 !important;
          color: white !important;
          border: 1px solid #174d89 !important;
        }
        .dropdown-menu {
          background-color: #0a1f44 !important;
          color: black !important;
        }
        .tab-content {
          background-color: #0a1f44;
          padding: 15px;
          border-radius: 8px;
          color: white;
        }
        .bootstrap-select .bs-searchbox input {
          background-color: #174d89 !important;
          color: white !important;
          border: 1px solid #ffffff;
        }
        .dataTables_wrapper .dataTables_filter input {
          background-color: #174d89 !important;
          color: white !important;
          border: 1px solid white !important;
        }
        .dropdown-menu.inner li a:hover {
          background-color: #1d5ea8 !important;
          color: white !important;
        }
        .dataTables_wrapper {
          color: white !important;
        }
        table.dataTable tbody td {
          color: white !important;
        }
        table.dataTable thead th {
          color: white !important;
        }
      ")),

    htmltools::tags$div(
      style = "background-color: #0a1f44; padding: 20px; min-height: 100vh; color: white;",
      fluidRow(
        column(
          width = 3,
          shinyWidgets::pickerInput(
            ns("ticker"),
            "Select Company Ticker",
            choices = NULL,
            multiple = FALSE,
            options = list(`live-search` = TRUE),
            selected = NULL
          ),
          shinyWidgets::pickerInput(
            ns("insiderID"),
            "Select by Insider",
            choices = NULL,
            multiple = FALSE,
            options = list(`live-search` = TRUE)
          )
        ),
        column(
          width = 9,
          tabsetPanel(
            tabPanel("Insider Table", DT::dataTableOutput(ns("insiderTable"))),
            tabPanel("Network Graph", visNetworkOutput(ns("insiderGraph"), height = "600px"))
          )
        )
      )
    )
  )
}

InsiderRelationsModule <- function(input, output, session, pageName, appData, ...) {
  ns <- session$ns

  insiderData <- reactive({
    files <- list.files("db/NASDAQ/insider_data", pattern = "\\.csv$", full.names = TRUE)
    names(files) <- stringr::str_remove(basename(files), "\\.csv$")
    files
  })

  observe({
    updatePickerInput(session, "ticker", choices = names(insiderData()))
  })

  selectedData <- reactive({
    req(input$ticker)
    read_csv(insiderData()[[input$ticker]], show_col_types = FALSE)
  })

  observeEvent(selectedData(), {
    ids <- unique(selectedData()[["Insider Trading"]])
    updatePickerInput(session, "insiderID", choices = ids)
  })

  output$insiderTable <- DT::renderDataTable({
    DT::datatable(
      selectedData(),
      options = list(pageLength = 10, scrollX = TRUE),
      class = "display nowrap compact stripe hover"
    )
  })

  output$insiderGraph <- visNetwork::renderVisNetwork({
    df <- selectedData()
    req(input$insiderID)

    filtered <- df[df$`Insider Trading` == input$insiderID, ]

    nodes <- data.frame(
      id = unique(c(filtered$`Insider Trading`, filtered$Relationship)),
      label = unique(c(filtered$`Insider Trading`, filtered$Relationship)),
      color = ifelse(
        unique(c(filtered$`Insider Trading`, filtered$Relationship)) == input$insiderID,
        "#00b5ff",  # Insider
        "#ffcc00"   # Role
      ),
      font = list(color = "#ffffff", size = 16)
    )

    edges <- data.frame(
      from = filtered$`Insider Trading`,
      to = filtered$Relationship,
      label = paste("Date:", filtered$Date),
      arrows = "to",
      color = list(color = "#ffffff", highlight = "#ff6666", hover = "#66ffcc"),
      font = list(color = "#ffffff", size = 12)
    )

    visNetwork(nodes, edges, height = "600px", width = "100%") %>%
      visEdges(smooth = list(enabled = TRUE, type = "dynamic")) %>%
      visOptions(highlightNearest = TRUE, nodesIdSelection = TRUE) %>%
      visInteraction(navigationButtons = TRUE) %>%
      visLayout(improvedLayout = TRUE, randomSeed = 42)
  })
}

InsiderRelationsPageConfig <- list(
  title = "Insider Relations",
  icon = "user-friends",
  permission = c("user", "admin"),
  submenu = "Insights",
  disabled = FALSE,
  id = "insiderRelations"
)
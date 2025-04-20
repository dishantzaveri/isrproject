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
          # border: 1px solid #ffffff;
          border: 1px solid #174d89;
        }
              select.vis-network-select {
        background-color: #174d89 !important;
        color: white !important;
        border: 1px solid #0a1f44;
        border-radius: 4px;
        padding: 5px;
      }
        .vis-network-tooltip {
          background-color: #0a1f44 !important;
          color: white !important;
          border: 1px solid #174d89 !important;
          padding: 10px;
          border-radius: 4px;
        }
        .vis-network-tooltip h4 {
          color: white !important;
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
        .vis-navigation .vis-button {
          filter: none !important;
          background-color: transparent !important;
          box-shadow: none !important;
          border: none !important;
        }

        .vis-navigation .vis-button:before {
          color: white !important;
          font-size: 16px;
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
    if (nrow(filtered) == 0) {
      return(visNetwork::visNetwork(nodes = data.frame(id = character(0)), 
                                    edges = data.frame(from = character(0), to = character(0))))
    }
    

    # nodes <- data.frame(
    #   id = unique(c(filtered$`Insider Trading`, filtered$Relationship)),
    #   label = unique(c(filtered$`Insider Trading`, filtered$Relationship)),
    #   color = ifelse(
    #     unique(c(filtered$`Insider Trading`, filtered$Relationship)) == input$insiderID,
    #     "#00b5ff",  # Insider
    #     "#ffcc00"   # Role
    #   ),
    #   font = list(color = "#ffffff", size = 16)
    # )
    # 
    # edges <- data.frame(
    #   from = filtered$`Insider Trading`,
    #   to = filtered$Relationship,
    #   # label = paste("Date:", filtered$Date),
    #   arrows = "to",
    #   color = list(color = "#ffffff", highlight = "#ff6666", hover = "#66ffcc"),
    #   font = list(color = "#ffffff", size = 12)
    # )
    # 
    # visNetwork(nodes, edges, height = "600px", width = "100%") %>%
    #   visEdges(smooth = list(enabled = TRUE, type = "dynamic")) %>%
    #   visOptions(highlightNearest = TRUE, nodesIdSelection = FALSE) %>%
    #   visInteraction(navigationButtons = TRUE) %>%
    #   visLayout(improvedLayout = TRUE, randomSeed = 42)
    
    insiders <- as.character(filtered$`Insider Trading`)
    roles <- as.character(filtered$Relationship)
    
    ids <- unique(c(insiders, roles))
    
    nodes <- data.frame(
      id = ids,
      label = ids,
      shape = ifelse(ids %in% insiders, "box", "ellipse"),
      color = ifelse(
        ids == input$insiderID,
        "#00b5ff",
        "#ffcc00"
      ),
      font = list(color = "#ffffff", size = 16)
    )
    edge_data <- filtered %>%
      dplyr::group_by(`Insider Trading`, Relationship) %>%
      dplyr::summarise(
        trade_count = n(),
        total_value = sum(`Value ($)`, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      dplyr::mutate(
        label = paste0(
          "Trades: ", trade_count,
          " | Value: $", formatC(total_value / 1e6, digits = 2, format = "f"), "M"
        )
      )
    edges <- data.frame(
      from = edge_data$`Insider Trading`,
      to = edge_data$Relationship,
      label = edge_data$label,
      arrows = "to",
      color = list(color = "#cccccc", highlight = "#ff6666", hover = "#66ffcc"),
      font = list(color = "#ffffff", size = 14)
    )
    
    visNetwork(nodes, edges, height = "600px", width = "100%") %>%
      visEdges(smooth = list(enabled = TRUE, type = "dynamic")) %>%
      visPhysics(solver = "repulsion", repulsion = list(nodeDistance = 200)) %>%
      visOptions(highlightNearest = TRUE, nodesIdSelection = FALSE) %>%
      # visInteraction(navigationButtons = TRUE) %>%
      visLayout(improvedLayout = TRUE)
    
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
# ─────────────────────────────────────────────
# InsiderRelations Page Module with Network Graph
# ─────────────────────────────────────────────

InsiderRelationsModuleUI <- function(id) {
  ns <- NS(id)

  htmltools::div(
    class = "p-4",
    style = "background-color: #0a192f; color: white; min-height: 100vh;",
    fluidRow(
      column(
        width = 3,
        selectInput(ns("ticker"), "Select Company Ticker", choices = NULL)
      ),
      column(
        width = 9,
        tabsetPanel(
          tabPanel("Insider Table", DT::dataTableOutput(ns("insiderTable"))),
          tabPanel("Network Graph", visNetwork::visNetworkOutput(ns("relationGraph"), height = "600px"))
        )
      )
    )
  )
}

InsiderRelationsModule <- function(input, output, session, pageName, appData, ...) {
  ns <- session$ns

  # Load available insider CSVs
  insiderData <- reactive({
    files <- list.files("db/NASDAQ/insider_data", pattern = "\\.csv$", full.names = TRUE)
    names(files) <- stringr::str_remove(basename(files), "\\.csv$")
    files
  })

  # Populate the dropdown
  observe({
    updateSelectInput(session, "ticker", choices = names(insiderData()))
  })

  # Load the selected data
  selectedData <- reactive({
    req(input$ticker)
    df <- readr::read_csv(insiderData()[[input$ticker]], show_col_types = FALSE)
    df
  })

  # Table Output
  output$insiderTable <- DT::renderDataTable({
    DT::datatable(selectedData(), options = list(pageLength = 10))
  })

  # Network Graph Output
  output$relationGraph <- visNetwork::renderVisNetwork({
    df <- selectedData()
    req(nrow(df) > 0)

    # Nodes: Insider, Role, Transaction
    insiders <- unique(df$`Insider Trading`)
    roles <- unique(df$Relationship)
    transactions <- unique(df$Transaction)

    node_df <- dplyr::bind_rows(
      data.frame(id = insiders, label = insiders, group = "Insider"),
      data.frame(id = roles, label = roles, group = "Role"),
      data.frame(id = transactions, label = transactions, group = "Transaction")
    ) %>%
      dplyr::distinct(id, .keep_all = TRUE)

    # Edges: Insider → Role, Insider → Transaction
    edge_df <- dplyr::bind_rows(
      df %>% dplyr::select(from = `Insider Trading`, to = Relationship),
      df %>% dplyr::select(from = `Insider Trading`, to = Transaction)
    )

    visNetwork::visNetwork(node_df, edge_df, height = "600px", width = "100%") %>%
      visNetwork::visEdges(arrows = "to") %>%
      visNetwork::visOptions(highlightNearest = TRUE, nodesIdSelection = TRUE) %>%
      visNetwork::visGroups(groupname = "Insider", color = "#1f77b4") %>%
      visNetwork::visGroups(groupname = "Role", color = "#2ca02c") %>%
      visNetwork::visGroups(groupname = "Transaction", color = "#ff7f0e") %>%
      visNetwork::visLayout(randomSeed = 123)
  })
}


# Page Config
InsiderRelationsPageConfig <- list(
  title = "Insider Relations",
  icon = "user-friends",
  permission = c("user", "admin"),
  submenu = "Insights",
  disabled = FALSE,
  id = "insiderRelations"
)

# ─────────────────────────────────────────────
# InsiderRelations Page Module for Insider–Company Relationship Exploration
# ─────────────────────────────────────────────

# UI Function
InsiderRelationsModuleUI <- function(id) {
  ns <- NS(id)

  fluidRow(
    column(
      width = 3,
      shinydashboard::box(
        title = "Select Company Ticker", width = 12, status = "primary", solidHeader = TRUE,
        selectInput(ns("ticker"), label = NULL, choices = NULL)
      )
    ),

    column(
      width = 9,
      shinydashboard::box(
        title = "Insider–Company Relationships", width = 12, status = "info", solidHeader = TRUE,
        tabsetPanel(
          tabPanel("Insider Table", DT::dataTableOutput(ns("insiderTable"))),
          tabPanel("Summary Plot", plotly::plotlyOutput(ns("insiderPlot")))
        )
      )
    )
  )
}
# Server Function
InsiderRelationsModule <- function(input, output, session, pageName, appData, ...) {

  ns <- session$ns

  # Reactive: load available CSVs from insider_data
  insiderData <- reactive({
    files <- list.files("db/NASDAQ/insider_data", pattern = "\\.csv$", full.names = TRUE)
    names(files) <- stringr::str_remove(basename(files), "\\.csv$")
    files
  })

  # Populate dropdown
  observe({
    updateSelectInput(session, "ticker", choices = names(insiderData()))
  })

  # Load selected CSV
  selectedData <- reactive({
    req(input$ticker)
    readr::read_csv(insiderData()[[input$ticker]], show_col_types = FALSE)
  })

  # Table output
  output$insiderTable <- DT::renderDataTable({
    DT::datatable(selectedData(), options = list(pageLength = 10))
  })

  # Summary plot by "Relationship" (e.g., CEO, Director, etc.)
  output$insiderPlot <- plotly::renderPlotly({
    df <- selectedData()

    if (!"Relationship" %in% names(df)) {
      return(plotly::plot_ly() %>%
               plotly::layout(title = "No 'Relationship' column found in data"))
    }

    df_summary <- df %>%
      dplyr::count(Relationship, name = "n") %>%
      dplyr::arrange(desc(n)) %>%
      dplyr::slice_head(n = 10)

    plotly::plot_ly(
      df_summary,
      x = ~Relationship,
      y = ~n,
      type = 'bar'
    ) %>%
    plotly::layout(
      title = "Top Insider Roles (Relationship)",
      xaxis = list(title = "Relationship"),
      yaxis = list(title = "Number of Records")
    )
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

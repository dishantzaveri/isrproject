


baDashboardModuleUI <- function(id) {
	ns <- NS(id)
	
	htmltools::tagList(
  	htmltools::div(class = 'page bg-dashboard tab-page', 
  	  htmltools::div(class = 'card-wrapper',
        htmltools::div(class = 'trade-select',
          htmltools::img(class = 'brain', src = 'img/icons/Icon-Brain.svg'),
          shinyWidgets::pickerInput(ns('selectedCompany'), label = 'Company',
            selected = as.character(tickerList)[1],
            choices = as.character(tickerList),  choicesOpt = list(subtext = names(tickerList)),
            options = list(title = 'Ticker Symbol', `live-search` = T, `liveSearchNormalize` = T)
          )
        ),
        TradeCardModuleUI(ns('TradeCard'))
      ),
      shiny::tabsetPanel(id = ns('analysisTabSet'), type = 'pills',
        shiny::tabPanel(title = 'Company', class = 'analysis-tabs', value = 'Company',
          htmltools::div(class = 'dashnav-text',
            htmltools::div(class = 'icon', htmltools::img(src = 'img/icons/icon-info.svg')),
            htmltools::div(class = 'text', htmltools::tags$b(class = 'bolded', 'Company'),
              'provides statistics of abnormaly indicators and information on crucial contextual information of recent price movements.'
            )
          ),
          htmltools::div(class = 'dashboard-content-wrapper', style = 'flex-direction: row; gap: .75rem; padding: 0;',
            htmltools::div(class = 'plot-holder',
              htmltools::div(class = 'plot-card plot-card-large',
                shinycssloaders::withSpinner(plotly::plotlyOutput(ns('clusterPlot'), height = '30vh'), hide.ui = F),
                htmltools::div(class = 'text',
                  'Companies are clustered with S&P500 based on their market movement of the day.',
                  'If price movement coincides with the general market movement and does not lie in the outlier cluster,',
                  'there is not need to investigate further on the particular counter.'
                )
              ),
              # htmltools::div(class = 'plot-card dark-dt full-dt cluster-dt',
              #   shinycssloaders::withSpinner(DT::DTOutput(ns('clusterDT'), height = '35vh'), hide.ui = F)
              # ),
              htmltools::div(class = 'plot-card',
                shinycssloaders::withSpinner(plotly::plotlyOutput(ns('marketPricePlot'), height = '30vh'), hide.ui = F),
                htmltools::div(class = 'text',
                  'This plot shows there is a drop in price once there is a sale or option exercise transaction.', 
                  'So we can draw a conclusion that they influenced the drop in price.', 
                  'This shows that their activities have a huge impact on the market price and they are the main players driving the price.'
                )
              ),
              htmltools::div(class = 'plot-card',
                shinycssloaders::withSpinner(plotly::plotlyOutput(ns('insiderMarketPlot'), height = '30vh'), hide.ui = F),
                htmltools::div(class = 'text',
                  'This plot compares the volume of insider sales (over time) to the volume of sales in the S&P 500 (over time).', 
                  'They are characterized by a tendency to increase their sales during market upswings and increase their purchases during downturns.', 
                  'It has been observed that insiders are net buyers of low P/E stocks and net sellers of high P/E stocks.'
                )
              )
            )
          )
        ),
        shiny::tabPanel(title = 'Account', class = 'analysis-tabs', value = 'Account',
          htmltools::div(class = 'dashnav-text',
            htmltools::div(class = 'icon', htmltools::img(src = 'img/icons/icon-info.svg')),
            htmltools::div(class = 'text', htmltools::tags$b(class = 'bolded', 'Account'),
              'provides statistics and analysis on abnormalies indicators of all trades done by an account.'
            )
          ),
          htmltools::div(class = 'dashboard-content-wrapper',
            shiny::inputPanel(
              shiny::dateRangeInput(ns('accountFilter'), label = 'Date',
                start = Sys.Date() - 365 * 2, end = Sys.Date(), min = Sys.Date() - 365 * 5, max = Sys.Date()
              )
            ),
            htmltools::div(class = 'dark-dt full-dt', DT::DTOutput(ns('accountDT')))
          )
        ),
        shiny::tabPanel(title = 'Market Data', class = 'analysis-tabs', value = 'Market',
          htmltools::div(class = 'dashnav-text',
            htmltools::div(class = 'icon', htmltools::img(src = 'img/icons/icon-info.svg')),
            htmltools::div(class = 'text', htmltools::tags$b(class = 'bolded', 'Market'),
              'market information on counter'
            )
          ),
          htmltools::div(class = 'dashboard-content-wrapper',
            htmltools::div(class = 'plot-holder',
              htmltools::div(class = 'plot-card plot-card-large',
                shinycssloaders::withSpinner(plotly::plotlyOutput(ns('marketMovementPlot'), height = '75vh'), hide.ui = F)
              )
            )
          )
        )
      )
    ),
	  htmltools::div(class = 'dash-line',
      shiny::uiOutput(ns('pagetext'), class = 'text'),
      htmltools::div(id = 'lineunder', class = 'line')
    )
	)
}


baDashboardModule <- function(input, output, session, credentials, ...) {


  # Module Data
  ###############################

  # init
  ns <- session$ns
  rlang::env_bind(parent.env(environment()), ...)
  credentials <- shiny::reactive({ shiny::req(session$userData$credentials()) })
  username <- shiny::reactive({ shiny::req(credentials()$info$username) })
  shiny::observe({ appendAccessLog(username(), getwd(), session$ns('name'), '', '') })

  ##########################################################################################

  companyID <- shiny::reactive({
    companyID <- 'AAPL'
    companyID <- shiny::req(input$selectedCompany)
  })
  

  # Page Data
  ###############################
  
  insiderDF <- shiny::reactive({ 
    companyID <- shiny::req(companyID())
    
    insiderDF <- readr::read_csv(sprintf('db/NASDAQ/insider_data/%s.csv', companyID), show_col_types = F)
  })
  
  selectedDate <- shiny::reactive({
    insiderDF <- shiny::req(insiderDF())
    
    selectedDate <- dplyr::pull(dplyr::slice_max(insiderDF, `Date`), `Date`)
  })
  
  InsiderActivityDFList <- shiny::reactive({
    insiderDF <- shiny::req(insiderDF())
    
    df_list <- purrr::map(c('Buy', 'Sale', 'Opt'), ~ dplyr::filter(insiderDF, `Transaction` == .x)) %>%
      rlang::set_names(c('df_buy', 'df_sale', 'df_opt'))
    
    InsiderActivityDFList <- purrr::map(c(list(insiderDF), df_list), ~ dplyr::summarise(.x, `count` = dplyr::n(), .by = c('Date'))) %>%
      rlang::set_names(c('df_count', 'df_buy_count', 'df_sale_count', 'df_opt_count')) %>%
      c(df_list, .)
  })
  
  marketDF <- shiny::reactive({
    companyID <- shiny::req(companyID())
    
    marketDF <- readr::read_csv(sprintf('db/NASDAQ/market_data/%s.csv', companyID), show_col_types = F) %>%
      dplyr::rename_with(stringr::str_to_title, dplyr::everything()) %>%
      dplyr::mutate('Date' = as.Date(`Date`))
  })
  
  insiderTradesDF <- shiny::reactive({
    insiderTradesDF <- readr::read_csv('db/insider.csv', show_col_types = F) %>%
      dplyr::mutate('Transaction Type' = stringr::str_extract(`Transaction Type`, '(?<=[A-Z]\\s-\\s).*')) %>%
      dplyr::mutate(dplyr::across(dplyr::ends_with('Date'), ~ as.Date(.x, format = '%d/%m/%Y')))
  })
  
  clusterDF <- shiny::reactive({
    selectedDate <- shiny::req(selectedDate())
    
    clusterDF <- readr::read_csv(sprintf('db/clustering/data/%s.csv', stringr::str_extract(selectedDate, '[0-9]{4}')), show_col_types = F) %>%
      dplyr::filter(as.Date(`Date`) == as.Date(selectedDate)) %>%
      dplyr::distinct(`Ticker`, .keep_all = T)
  })
  
  clusterData <- shiny::reactive({
    clusterDF <- shiny::req(clusterDF())
    
    marketDFN <- dplyr::select(clusterDF, -`Ticker`, -`Date`, -`Year`) %>%
      as.matrix() %>%
      clusterSim::data.Normalization(type = 'n1', normalization = 'column')
    
    PCA1 <- prcomp(marketDFN, center = F, scale. = F)
    PCA2 <- prcomp(marketDFN, center = F, scale. = F, rank. = nrow(dplyr::filter(factoextra::get_eigenvalue(PCA1), `eigenvalue` > 1)))
    
    num_cluster <- factoextra::fviz_nbclust(PCA2$x, FUNcluster = kmeans, k.max = 5)$data %>%
      dplyr::filter(dplyr::lead(`y`) < `y`) %>%
      dplyr::slice_head(n = 1) %>%
      dplyr::pull(`clusters`) %>%
      as.numeric()
    
    clusterData <- factoextra::eclust(PCA2$x, 'kmeans', hc_metric = 'eucliden', k = 3, graph = F)
  })
  
  outlierDF <- shiny::reactive({
    clusterDF <- shiny::req(clusterDF())
    clusterData <- shiny::req(clusterData())
    
    outlierDF <- dplyr::slice(clusterDF, which(clusterData$cluster == which.min(clusterData$size))) %>%
      dplyr::mutate('ID' = which(clusterData$cluster == which.min(clusterData$size))) %>%
      dplyr::select(-`Date`, -`Year`) %>%
      dplyr::select(
        `ID`, `Ticker`, `Volume`, `Volume Change`,
        `Open`, `Open Change`, `Close`, `Close Change`,
        `High`, `High Change`, `Low`, `Low Change`
      ) %>%
      dplyr::mutate(dplyr::across(where(is.double), ~ formatC(.x, big.mark = ',', digits = 2, format = 'f', drop0trailing = T))) %>%
      dplyr::mutate(dplyr::across(dplyr::ends_with('Change'), ~ paste0(.x, '%'))) %>%
      dplyr::mutate(dplyr::across(dplyr::matches('Open|Close|High|Low'), ~ paste0('$', .x))) %>%
      dplyr::mutate(
        'Volume' = sprintf('%s (%s)', `Volume`, `Volume Change`),
        'Open' = sprintf('%s (%s)', `Open`, `Open Change`),
        'Close' = sprintf('%s (%s)', `Close`, `Close Change`),
        'High' = sprintf('%s (%s)', `High`, `High Change`),
        'Low' = sprintf('%s (%s)', `Low`, `Low Change`)
      ) %>%
      dplyr::select(`ID`, `Ticker`, `Volume`, `Open`, `Close`, `High`, `Low`)
  })
  
  shiny::callModule(TradeCardModuleServer, 'TradeCard', username = username,
    companyID = companyID, marketDF = marketDF
  )

	####################################################################
  
  output$marketPricePlot <- plotly::renderPlotly({
    marketDF <- shiny::req(marketDF())
    
    dplyr::mutate(marketDF, 'Average 3' = zoo::rollmean(`Close`, 3, fill = NA), 'Average 7' = zoo::rollmean(`Close`, 7, fill = NA)) %>%
      dplyr::filter(`Date` > (Sys.Date() - 30)) %>%
      plotly::plot_ly(type = 'scatter', mode = 'lines+markers') %>%
      plotly::add_trace(x = ~`Date`, y = ~`Close`, name = 'Trend') %>%
      plotly::add_trace(x = ~`Date`, y = ~`Average 3`, name = 'Moving Average (3 Days)', mode = 'lines') %>%
      plotly::add_trace(x = ~`Date`, y = ~`Average 7`, name = 'Moving Average (7 Days)', mode = 'lines') %>%
      plotly::layout(
        xaxis = list(title = 'Date'), yaxis = list(title = 'Price'), legend = list(orientation = 'h'),
        title = 'Market Price'
      )
  })
  
  output$insiderMarketPlot <- plotly::renderPlotly({
    filterEndDate <- Sys.Date()
    filterStartDate <- Sys.Date() - 365 * 2
    InsiderActivityDFList <- shiny::req(InsiderActivityDFList())
    marketDF <- shiny::req(marketDF())
    dfNames <- c('buy', 'sale', 'opt')
    
    InsiderActivityDF <- InsiderActivityDFList[paste0('df_', dfNames)] %>%
      rlang::set_names(stringr::str_to_title(dfNames)) %>%
      purrr::map(~ dplyr::select(.x, c(`Date`, where(is.numeric)))) %>%
      purrr::map2(names(.), ~ dplyr::mutate(.x, 'Name' = .y, `Date` = as.Date(`Date`))) %>%
      dplyr::bind_rows()
    
    InsiderActivitySummaryDF <- dplyr::summarise(InsiderActivityDF, across(where(is.numeric), sum), .by = c(`Date`, `Name`)) %>%
      dplyr::filter(filterStartDate <= as.Date(`Date`) & as.Date(`Date`) <= filterEndDate)
    
    StockActivitySummaryDF <- dplyr::select(marketDF, `Date`, `Volume`) %>%
      dplyr::summarise(across(where(is.numeric), mean), .by = c(`Date`)) %>%
      dplyr::filter(filterStartDate <= as.Date(`Date`) & as.Date(`Date`) <= filterEndDate)
    
    plotly::plot_ly(data = InsiderActivitySummaryDF) %>%
      plotly::add_trace(x = ~`Date`, y = ~`Value ($)`, name = ~`Name`, color = ~`Name`, type = 'bar', yaxis = 'Value') %>%
      plotly::add_trace(
        data = StockActivitySummaryDF, x = ~`Date`, y = ~`Volume`, name = 'S&P 500',
        color = '#00FFD1', type = 'scatter', mode = 'lines', yaxis = 'Volume'
      ) %>%
      plotly::layout(
        xaxis = list(title = 'Date'), yaxis = list(title = 'Value'), yaxis2 = list(overlaying = 'right', side = 'right', title = 'Volume'),
        legend = list(orientation = 'h'), title = 'SEC 4 Activities Vs. S&P 500'
      )
  })
  
  # output$LLMContent <- shiny::renderUI({
  #   companyID <- shiny::req(companyID())
  #   marketDF <- shiny::req(marketDF())
  #   
  #   currentData <- dplyr::slice_tail(marketDF, n = 1)
  #   
  #   prompt <- paste(
  #     'Identify from the following data if there is any possibility of insider trade:',
  #     paste(purrr::map2(
  #       c('Company', 'Date', 'HighPrice', 'LowPrice', 'openPrice', 'closePrice', 'VolumeOfShares'), 
  #       c(companyID, paste(currentData$Date), as.character(as.integer(dplyr::select(currentData, `High`, `Low`, `Open`, `Close`, `Volume`)))),
  #       ~ paste(.x, .y)
  #     ), collapse = ' ')
  #   )
  #   
  #   llmAnalysis <- as.character(GPT$processQuery(prompt))
  #   
  #   shiny::markdown(llmAnalysis)
  # })
  
  output$accountDT <- DT::renderDT({
    insiderTradesDF <- shiny::req(insiderTradesDF())
    companyID <- shiny::req(companyID())
    accountFilter <- shiny::req(input$accountFilter)
    
    dplyr::filter(insiderTradesDF, `Ticker` == companyID) %>%
      dplyr::filter(accountFilter[1] < `Trade Date` & `Trade Date` < accountFilter[2]) %>%
      dplyr::select(
        `Ticker`, `Company`, `Trade Date`, `Insider Name`, `Title`, `Transaction Type`, `Price`, `Quantity`, `Owned`,
        '% Change (Owned)' = `Change of Amount Owned`, `Value`, 'Open Price' = `Date Traded Open`, 'Close Price' = `Date Traded Close`
      ) %>%
      dplyr::mutate(dplyr::across(where(is.numeric), ~ as.numeric(sprintf('%.2f', .x))))
  }, selection = 'single', escape = F, rownames = F, editable = F, options = list(pageLength = 100, processing = F, scrollX = T, scrollY = T, dom = 't'))
  
  output$marketMovementPlot <- plotly::renderPlotly({
    marketDF <- shiny::req(marketDF())
    
    dplyr::filter(marketDF, `Date` > Sys.Date() - 90) %>%
      plotly::plot_ly(x = ~Date, type = 'candlestick', open = ~Open, close = ~Close, high = ~High, low = ~Low)
  })
  
  output$marketDT <- DT::renderDT({
    marketDF <- shiny::req(marketDF())
  }, escape = F, rownames = F, editable = F, options = list(pageLength = 20, processing = F, scrollX = T, scrollY = T, dom = 't'))
  
  output$clusterPlot <- plotly::renderPlotly({
    clusterData <- shiny::req(clusterData())
    clusterDF <- shiny::req(clusterDF())
    companyID <- shiny::req(companyID())
    
    plot <- plotly::ggplotly(factoextra::fviz_cluster(clusterData))
    
    index <- which(clusterDF$Ticker == companyID)
    clusterIndex <- purrr::map(plot$x$data, ~ which(.x$text == index)) %>%
      purrr::compact() %>%
      as.numeric()
    clusterID <- clusterData$cluster[index]
    
    plot <- plotly::add_trace(plot, type = 'scatter', mode = 'markers', name = companyID, 
        x = plot$x$data[[clusterID]]$x[[clusterIndex]],
        y = plot$x$data[[clusterID]]$y[[clusterIndex]],
        text = stringr::str_replace(plot$x$data[[clusterID]]$text[[clusterIndex]], sprintf('cluster: %d$', clusterID), companyID),
        marker = list(size = 10, color = '#00FFD1')
      ) %>%
      plotly::layout(
        xaxis = list(title = 'PC1'), yaxis = list(title = 'PC2'),
        legend = list(orientation = 'h'), title = 'Market Movement Clusters'
      )
    
    for (i in seq(1:length(plot$x$data))) {
      plot$x$data[[i]]$name <- stringr::str_extract(plot$x$data[[i]]$name, '[0-9]')
    }
    
    plot
  })
  
  # output$clusterDT <- DT::renderDT({
  #   outlierDF <- shiny::req(outlierDF())
  # }, escape = F, rownames = F, editable = F, options = list(pageLength = 5, processing = F, scrollX = T, scrollY = T, dom = 't'))
  
  output$pagetext <- shiny::renderUI({
    analysisTabSet <- shiny::req(input$analysisTabSet)

    htmltools::HTML(analysisTabSet)
  })
}


# Page Config
#################################
baDashboardPageConfig <- list(

  # Title for menu
  'title' = 'Trade Dashboard',

  # Icon for menu
  'icon' = 'diagram-project',

  # Roles with permission to view page.
  # Exclusion will cause user to be TOTALLY unable to view page
  # Partial permission will have to be controlled within module
  'permission' = c('root', 'admin', 'user')
)

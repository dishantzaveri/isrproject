

TradeCardModuleUI <- function(id, ...) {
  ns <- NS(id)

  shiny::uiOutput(ns('tradeCardUI'))
}

TradeCardModuleServer <- function(input, output, session, companyID, marketDF, ...) {

  # Module Data
  ###############################

  # init
  ns <- session$ns
  rlang::env_bind(parent.env(environment()), ...)
  credentials <- shiny::reactive({shiny::req(session$userData$credentials())})
  username <- shiny::reactive({shiny::req(credentials()$info$username)})

  ##########################################################################################

  companyName <- shiny::reactive({
    companyID <- shiny::req(companyID())
    
    companyName <- dplyr::pull(dplyr::filter(metaDF, `Symbol` == companyID), `Company Name`)
  })
  
  stockType <- shiny::reactive({
    companyID <- shiny::req(companyID())
    
    stockType <- dplyr::pull(dplyr::filter(metaDF, `Symbol` == companyID), `Stock Type`)
  })
  
  newsMD <- shiny::reactive({
    companyID <- shiny::req(companyID())
    # companyName <- shiny::req(companyName())
    
    newsMD <- stringr::str_replace_all(companyID, 'Inc|,|\\.$', '') %>%
      stringr::str_trim() %>%
      GPT$get_news()
  })
  
  
  
  # Module Data
  ###############################

	output$tradeCardUI <- shiny::renderUI({
	  marketDF <- shiny::req(marketDF())
	  companyID <- shiny::req(companyID())
	  companyName <- shiny::req(companyName())
	  stockType <- shiny::req(stockType())
	  
	  marketInfo <- dplyr::slice_tail(marketDF, n = 1)
	  
	  marketChange <- dplyr::slice_tail(marketDF, n = 2) %>%
	    dplyr::select(-`Date`) %>%
	    dplyr::mutate(dplyr::across(dplyr::everything(), ~ 100 * ((.x - dplyr::lead(.x, 1)) / .x))) %>%
	    dplyr::slice_head(n = 1) %>%
	    as.list()
	  
    htmltools::div(class = 'card-details trade-details',
      htmltools::div(class = 'titlewrapper',
        htmltools::div(class = 'trade-title', 'Company'),
        htmltools::div(class = 'trade-code', companyName)
      ),
      htmltools::div(class = 'trade-statswrapper',
        htmltools::div(companyID),
        htmltools::div(class = 'gap', '|'),
        htmltools::div(stockType),
        htmltools::div(class = 'gap', '|'),
        htmltools::div(marketInfo$Date)
      ),
      htmltools::tags$table(class = 'custom-table',
        c('Open', 'High', 'Low', 'Close') %>%
          purrr::map(~ htmltools::tags$tr(
            htmltools::tags$td(.x),
            htmltools::tags$td(
              paste0('$', as.character(round(marketInfo[[.x]], 2))),
              htmltools::span(style = sprintf('margin-left: .25rem; color: %s', ifelse(marketChange[[.x]] >= 0, 'green', 'red')),
                paste0('(', as.character(round(marketChange[[.x]], 2)), '%)')
              )
            )
          )),
        htmltools::tags$tr(htmltools::tags$td('Volume'), htmltools::tags$td(prettyNum(marketInfo[['Volume']], big.mark = ',')))
      ),
      shiny::uiOutput(ns('newsUI'), class = 'news markdown')
    )
	})
  
  output$newsUI <- shiny::renderUI({
    newsMD <- shiny::req(newsMD())
    
    shiny::markdown(newsMD)
  })
}





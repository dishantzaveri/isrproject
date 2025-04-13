
locked <- FALSE
askChatGPT <- function(prompt) {
  response <- httr::POST(
    url = 'https://api.openai.com/v1/chat/completions', 
    httr::add_headers(Authorization = paste("Bearer", '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')),
    httr::content_type_json(),
    encode = "json",
    body = list(
      model = "gpt-3.5-turbo",
      messages = list(
        list(role = 'system', content = "
          You are an experienced financial fraud investigator specializing in insider trading.
          You are leading a team of junior investigators in investigating insider trading.
          You are to answer queries of other investigators truthfully.
          You are based in Monetary Authority of Singapore and your answers and reasonings should be based on United State's law and the US stock exchange.
          All you reasoning should be provided step by step.
          If you do not know the answer, you are to inform them of what other information is needed before you are able to conclude if there is any illegal insider trading.
          There is no need to provide qualitative instructions. Only provide instructions on quantitative data required.
        "),
        list(role = 'user', content = prompt)
      ),
      temperature = 0
    )
  )
  parsed <- httr::content(response, as = "parsed")
  
  if (!is.null(parsed$error)) {
    cat("GPT API Error:", parsed$error$message, "\n")
    return(paste("Error:", parsed$error$message))
  }
  
  return(stringr::str_trim(parsed$choices[[1]]$message$content))
}

ChatDataConnection <- R6::R6Class("ChatDataConnection", public = list(
  DB = NULL,
  chatID = NULL,
  initialize = function(selectedChat) {
    self$chatID <- selectedChat
    self$DB <- readr::read_csv('db/messages.csv') %>%
      dplyr::filter(`chat_id` == self$chatID)
  },
  get_data = function() {
    self$DB <- readr::read_csv('db/messages.csv') %>%
      dplyr::filter(`chat_id` == self$chatID)
  },
  insert_message = function(selectedChat, message, user, time, attachment = 0) {
    if (as.character(message) %!in% dplyr::pull(dplyr::slice_tail(readr::read_csv('db/messages.csv'), n = 2), `text`)) {
      self$DB <- readr::read_csv('db/messages.csv') %>%
        tibble::add_row(
          chat_id = selectedChat, user = as.character(user), text = as.character(message), time = as.integer(time), attach = attachment
        ) %>%
        readr::write_csv('db/messages.csv')
    }
  }
))


ChatWidgetUI <- function(id)  {
  ns <- shiny::NS(id)
  
  htmltools::div(class = "chatContainer",
    htmltools::tagAppendAttributes(shiny::uiOutput(ns("chatbox")), class = 'chatMessages'),
    htmltools::div(class = "chatForm", 
      shiny::textAreaInput(ns('chatInput'), label = NULL, placeholder = 'Enter message', rows = 8) %>%
        htmltools::tagAppendAttributes(class = 'chatInput input', style = 'height: 100%;'),
      htmltools::div(class = 'text-button-wrapper',
        shiny::actionButton(ns("attachInfo"), label = "Attach", class = 'text-button button2', style = 'flex-grow: 0'),
        shiny::actionButton(ns("chatFromSend"), label = "Send", class = 'text-button button2')
      )
    )
  )
}


ChatWidget <- function(input, output, session, username, selectedChat, ...) {
  ns <- session$ns
  print("ChatWidget initialized at")
  print(Sys.time())
  
  chatDF <- reactiveVal(NULL)
  
  observeEvent(selectedChat(), {
    chat_id <- ifelse(shiny::is.reactive(selectedChat), selectedChat(), selectedChat)
    chatDF(ChatDataConnection$new(chat_id))
    shinyjs::enable('chatFromSend')
  }) 
  
  chatData <- reactive({
    req(chatDF())
    shiny::invalidateLater(500)
    chatDF()$get_data()
  })
    
  output$chatbox <- renderUI({
    chatData <- req(chatData())
    
    if (nrow(chatData)) {
      msgs <- chatData %>%
        dplyr::filter(attach == 0) %>%
        dplyr::mutate(user = as.character(user), text = as.character(text))
      
      tagList(
        lapply(seq_len(nrow(msgs)), function(i) {
          user <- msgs$user[i]
          text <- msgs$text[i]
          
          div(
            class = paste("chatMessage", if (user == "llm") "ai-message" else "user-message"),
            style = "margin-bottom: 1rem;",
            div(
              style = "display: flex; flex-direction: row; gap: 0.5rem;",
              strong(
                class = "message-user",
                if (user == "llm") "AI Consultant" else stringr::str_to_title(user)
              ),
              div(
                class = "message-content",
                style = "white-space: pre-wrap; word-break: break-word; line-height: 1.5; background: rgba(255,255,255,0.05); padding: 0.5rem; border-radius: 6px; flex: 1;",
                HTML(htmltools::htmlEscape(text))
              )
            )
          )
        })
      )
    }
  })
    shiny::observeEvent(input$attachInfo, {
      shiny::showModal(
        shiny::modalDialog(title = 'Attach Data from AI Model',
          shinyWidgets::pickerInput(ns('selectedCompany'), label = 'Company',
            selected = tickerList[1],
            choices = tickerList,
            options = list(title = 'Ticker Symbol', `live-search` = T, `liveSearchNormalize` = T)
          ) %>%
            htmltools::tagAppendAttributes(class = 'trade-select') %>%
            htmltools::tagAppendAttributes(style = 'flex-basis: 100px;', .cssSelector = 'label'),
          shiny::uiOutput(ns('datePickerUI')),
          footer = htmltools::div(style = 'display: flex; justify-content: flex-end; gap: 1rem;',
            shiny::actionButton(ns('confirmAttachment'), 'Confirm', class = 'button1', style = 'flex-basis: 150px; flex-grow: 0;') %>%
              htmltools::tagQuery() %>%
              { .$removeClass('btn btn-default')$allTags() },
            htmltools::tagAppendAttributes(shiny::modalButton("Close"), class = 'button2', style = 'flex-basis: 150px; flex-grow: 0;') %>%
              htmltools::tagQuery() %>%
              { .$removeClass('btn btn-default')$allTags() }
          )
        ) %>%
          htmltools::tagAppendAttributes(
            style = 'display: flex; flex-direction: column; gap: 1.5rem; padding: 2rem 1.25rem;', .cssSelector = '.modal-body'
          )
      )
    }, ignoreNULL = T, ignoreInit = T)
    
    output$datePickerUI <- shiny::renderUI({
      selectedCompany <- shiny::req(input$selectedCompany)
      
      dateList <- readr::read_csv(sprintf('/srv/shiny-server/SIH/db/NASDAQ/market_data/%s.csv', selectedCompany), show_col_types = F) %>%
        dplyr::pull(`Date`)
      
      shiny::dateInput(ns('attachmentDate'), label = 'Date', min = min(dateList), max = max(dateList), value = max(dateList)) %>%
        htmltools::tagAppendAttributes(style = 'display: flex; gap: 1.25rem;') %>%
        htmltools::tagAppendAttributes(style = 'flex-basis: 100px;', .cssSelector = 'label') %>%
        htmltools::tagAppendAttributes(
          style = 'display: flex; background: none; border: 1px solid #36A2E0; box-shadow: 0px 2px 7px 0px #36A2E0;', .cssSelector = 'input'
        )
    })
    
    shiny::observeEvent(input$confirmAttachment, {
      shinyjs::disable('chatFromSend')
      shinyjs::disable('attachInfo')
      shiny::removeModal()
      chatID <- ifelse(shiny::is.reactive(selectedChat), selectedChat(), selectedChat)
      chatUser <- ifelse(shiny::is.reactive(username), username(), username)
      selectedCompany <- shiny::req(input$selectedCompany)
      attachmentDate <- shiny::req(input$attachmentDate)
      
      chatMessage <- sprintf(
        'Identify if there is any possibility of insider trade for the trade of shares of %s on date %s',
        selectedCompany, attachmentDate
      )
      
      chatDF()$insert_message(selectedChat = chatID, message = chatMessage, user = chatUser, time = as.integer(Sys.time()))
      
      cat("Calling GPT$processQuery with prompt:\n", prompt, "\n")
      LLMMessage <- GPT$processQuery(chatMessage)
      cat("Received LLM Response:\n", llmAnalysis, "\n")
      
      chatDF()$insert_message(selectedChat = chatID, message = shiny::req(LLMMessage), user = 'llm', time = as.integer(Sys.time()))
      
      shinyjs::enable('chatFromSend')
      shinyjs::enable('attachInfo')
    }, ignoreInit = T, ignoreNULL = T)
    
    shiny::observeEvent(input$chatFromSend, {
      if (locked) return()
      locked <<- TRUE
      shinyjs::disable('chatFromSend')
      shinyjs::disable('attachInfo')
      
      chatID <- ifelse(shiny::is.reactive(selectedChat), selectedChat(), selectedChat)
      chatUser <- ifelse(shiny::is.reactive(username), username(), username)
      
      chatMessage <- isolate(shiny::req(input$chatInput))

      shiny::updateTextAreaInput(session, 'chatInput', value = '')

      last_messages <- tail(readr::read_csv('db/messages.csv'), 1)

      if (nrow(last_messages) == 0 || last_messages$text != chatMessage || last_messages$user != chatUser) {
        chatDF()$insert_message(selectedChat = chatID, message = chatMessage, user = chatUser, time = as.integer(Sys.time()))
        
        LLMMessage <- askChatGPT(chatMessage)
        
        chatDF()$insert_message(selectedChat = chatID, message = LLMMessage, user = 'llm', time = as.integer(Sys.time()))
      
      } else {
        cat("Duplicate message blocked\n")
      }
      locked <<- FALSE
      
      shinyjs::enable('chatFromSend')
      shinyjs::enable('attachInfo')
    }, ignoreInit = TRUE, ignoreNULL = TRUE)
    
    
    return(chatData)
  
}


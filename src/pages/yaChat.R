


yaChatModuleUI <- function(id) {
	ns <- NS(id)
	
	htmltools::div(class = 'page bg-dashboard', style = 'flex-direction: row;',
	  shiny::tags$script(htmltools::HTML(paste0(
      "function delete_chat(clicked_id) {",
        "Shiny.setInputValue('", ns("chat_id"), "', clicked_id, {priority: 'event'});",
      "}"
    ))),
	  shinyjs::hidden(shiny::actionButton(ns('refresh'), label = NULL)),
	  htmltools::div(class = 'message-panel',
	    shiny::actionButton(ns('newChat'), label = 'New Chat', icon = shiny::icon('envelope-open-text')) %>%
	      htmltools::tagAppendAttributes(class = 'newchat-button btn-primary'),
	    htmltools::div(class = 'dark-dt simple-dt', DT::DTOutput(ns('chatListUI')))
	  ),
    ChatWidgetUI(ns('ChatWidget'))
	)
}


yaChatModule <- function(input, output, session, credentials, ...) {


  # Module Data
  ###############################

  # init
  ns <- session$ns
  rlang::env_bind(parent.env(environment()), ...)
  credentials <- shiny::reactive({ shiny::req(session$userData$credentials()) })
  username <- shiny::reactive({ shiny::req(credentials()$info$username) })
  shiny::observe({ appendAccessLog(username(), getwd(), session$ns('name'), '', '') })

  ##########################################################################################


  # Page Data
  ###############################
  chatList <- shiny::reactive({
    input$refresh
    
    dplyr::filter(readr::read_csv('db/chat.csv'), stringr::str_detect(`username`, shiny::req(username())) & `deleted` == 0) %>%
      dplyr::select(-`username`)
  })

	####################################################################
  
  output$chatListUI <- DT::renderDT({
    chatList <- shiny::req(chatList())

    dplyr::mutate(chatList, 'Update' = create_delete_btns(`chat_id`, ns)) %>%
      dplyr::select(`title`, `Update`)
    
  }, escape = F, rownames = F,
    editable = list(target = "cell", disable = list(columns = c(1))),
    selection = list(mode = 'single', selected = c(1)),
    options = list(dom = 't', paging = F, processing = F, scrollX = T)
  )
  
  shiny::observeEvent(input$chat_id, {
    chat_id <- stringr::str_extract(input$chat_id, '[0-9]*$')
    
    readr::read_csv('db/chat.csv') %>%
      dplyr::rows_update(tibble::tibble(`chat_id` = chat_id, deleted = 1), by = 'chat_id') %>%
      readr::write_csv('db/chat.csv')
    
    shinyjs::click('refresh')
  })
  
  shiny::observeEvent(input$newChat, {
    paste(
      chat_id = sprintf('%07d', nrow(readr::read_csv('db/chat.csv')) + 1), username = shiny::req(username()),
      title = 'New Chat', time = as.integer(Sys.time()), deleted = 0, sep = ','
    ) %>%
      write(file = 'db/chat.csv', append = T)
    
    shinyjs::click('refresh')
  })
  
  shiny::observeEvent(input$chatListUI_cell_edit, {
    chatList <- shiny::req(chatList())
    chatID  <- dplyr::pull(dplyr::slice(chatList, input$chatListUI_cell_edit$row), `chat_id`)
    newTitle <- shiny::req(input$chatListUI_cell_edit$value)
    
    readr::read_csv('db/chat.csv') %>%
      dplyr::rows_update(tibble::tibble(`chat_id` = chatID, title = newTitle), by = 'chat_id') %>%
      readr::write_csv('db/chat.csv')
    
    shinyjs::click('refresh')
  }, ignoreInit = T)
  
  selectedChat <- shiny::reactive({ 
    chatList <- shiny::req(chatList())
    rowNum <- shiny::req(input$chatListUI_rows_selected)
    
    dplyr::pull(dplyr::slice(chatList, rowNum), `chat_id`)
  })
  
  chatDF <- shiny::callModule(ChatWidget, 'ChatWidget', username = username, selectedChat = selectedChat)
}


# Page Config
#################################
yaChatPageConfig <- list(

  # Title for menu
  'title' = 'AI Assistant',

  # Icon for menu
  'icon' = 'brain',

  # Roles with permission to view page.
  # Exclusion will cause user to be TOTALLY unable to view page
  # Partial permission will have to be controlled within module
  'permission' = c('root', 'admin', 'user')
)

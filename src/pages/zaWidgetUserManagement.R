


zaWidgetUserManagementModuleUI <- function(id) {
  ns <- shiny::NS(id)

  htmltools::div(class = 'page',
    shiny::tags$script(htmltools::HTML(paste0(
      "function get_id(clicked_id) {",
        "Shiny.setInputValue('", ns("current_id"), "', clicked_id, {priority: 'event'});",
      "}"
    ))),
    shiny::column(12, style = 'margin: 1rem; padding: 1rem; border: 1px solid #36A2E0; width: calc(100% - 2rem);',
      shiny::actionButton(ns('refreshUser'), 'Refresh') %>%
        htmltools::tagAppendAttributes(class = 'button1', style = 'color: #FFF')
    ),
    shinydashboard::box(title = 'Users', width = 12, status = "primary", class = 'classic-dt',
      DT::DTOutput(ns('user_base_ui'))
    )
  )
}

zaWidgetUserManagementModule <- function(input,  output,  session,  ...) {


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
  rv <- reactiveValues(commit = NULL)

  user_base <- shiny::reactive({
    input$refreshUser
    rv$commit
    user_name <- shiny::req(username())
    permissions <- shiny::req(credentials()$info$permissions)

    getUserBase() %>%
      dplyr::bind_rows(rlang::set_names(rep('', ncol(.)), colnames(.))) %>% {
        if ('admin' %!in%  permissions) {
          dplyr::filter(., `username` == user_name) %>%
            dplyr::mutate('Update' = create_btns(`username`, ns, user_name, T))
        } else {
          dplyr::mutate(., 'Update' = create_btns(`username`, ns, user_name, F))
        }
      }
  })

  output$user_base_ui <- DT::renderDT({
    user_base() %>%
      dplyr::select(-`password_hash`)
  }, selection = 'single', escape = F, rownames = F, editable = F, options = list(processing = F, scrollX = T))


  # Page
  ###############################

  # Edit and Delete User
  shiny::observeEvent(input$current_id, {
    shiny::req(!is.null(input$current_id) & stringr::str_detect(input$current_id, pattern = "edit|delete|new|reset"))
    selected_username <- stringr::str_replace(input$current_id, '.*(edit_|delete_|new_|reset_)', '')
    mode <- stringr::str_extract(input$current_id, '(delete|edit|new|reset)')

    shiny::showModal(
      shiny::modalDialog(fade = F,
        title = h3(sprintf('%s User', stringr::str_to_title(mode))),
        htmltools::tags$head(htmltools::tags$script(
          shiny::HTML(sprintf(returnClickJS, ns("username"), ns("confirmPassword"), ns("confirmButton")))
        )),
        shiny::div(class = 'modal-inputs',
          if (mode == 'delete') {
            shiny::HTML(sprintf('Are you sure you want to delete the user <b>%s</b>?', selected_username))
          } else if (mode == 'edit') {
            user_base() %>%
              dplyr::filter(`username` == selected_username) %>%
              dplyr::select(-`Update`, -`password_hash`, -`username`) %>%
              tidyr::gather() %>%
              purrr::transpose() %>%
              purrr::map(~ shiny::textInput(
                inputId = ns(.$key), label = stringr::str_to_title(stringr::str_replace(.$key, '_', ' ')), value = .$value)
              ) %>%
              { do.call('tagList', purrr::compact(.)) } %>%
              htmltools::tagInsertChildren(after = 0, shinyjs::disabled(shiny::textInput(ns('username'), 'Username', value = selected_username)))
          } else if (mode == 'new') {
            names(user_base()) %>%
              purrr::discard(~ str_detect(.x, '(password_hash|Update)')) %>%
              unique() %>%
              purrr::map(~ shiny::textInput(inputId = ns(.), label = stringr::str_to_title(.), value = '')) %>%
              { do.call('tagList', purrr::compact(.)) } %>%
              shiny::tagAppendChildren(
                shiny::passwordInput(ns('newpass1'), 'New Password'),
                shiny::passwordInput(ns('newpass2'), 'Confirm New Password')
              )
          } else if (mode == 'reset') {
            shiny::tagList(
              shinyjs::disabled(shiny::textInput(ns('reset_username'), 'Username', value = selected_username)),
              shiny::passwordInput(ns('resetpass1'), 'New Password'),
              shiny::passwordInput(ns('resetpass2'), 'Confirm New Password')
            )
          }
        ),
        shiny::passwordInput(ns('confirmPassword'), NULL, placeholder = 'Password', width = '100%'),
        shiny::helpText('Admin actions require password reconfirmation.', style = 'padding-bottom: 12px;'),
        shiny::fluidRow(style = "font-weight: bold;", shiny::column(12, style = 'min-height: 16 px;',
          shinyjs::hidden(shiny::p(id = ns("error"), style = 'color: #dc3545;', textOutput(ns('error_message'), inline = T)))
        )),
        footer = shiny::div(
          shiny::actionButton(ns('confirmButton'), 'Confirm', class = ifelse(mode == 'delete', 'btn-danger', 'btn-info')),
          shiny::modalButton("Cancel")
        )
      )
    )
  })



  shiny::observeEvent(input$confirmButton, {
    mode <- stringr::str_extract(input$current_id, '(delete|edit|new|reset)')
    message <- list('status' = NULL, 'text' = '')

    if (verify_user(username(), input$confirmPassword)) {
      if (mode == 'delete') {
        deleteUser(stringr::str_replace(input$current_id, '.*(edit_|delete_|new_)', ''))
        message <- list('status' = T, 'text' = '')
      } else if (mode == 'edit') {
        args <- names(getUserBase()) %>%
          purrr::discard(~ str_detect(.x, 'password')) %>%
          unique() %>%
          { rlang::set_names(purrr::map(., ~ input[[.]]), .) }

        do.call('update_info', args)
        message <- list('status' = T, 'text' = '')
      } else if (mode == 'new') {
        if (input[['newpass1']] == input[['newpass2']]) {
          args_tmp <- names(user_base()) %>%
            compact() %>%
            purrr::discard(~ stringr::str_detect(.x, 'password')) %>%
            unique() %>%
            purrr::compact() %>%
            { rlang::set_names(c(purrr::map(., ~ input[[.]]), input[['newpass1']]), c(., 'password')) }
          do.call('add_user', args_tmp)
          message <- list('status' = T, 'text' = '')
        } else {
          message <- list('status' = F, 'text' = 'New passwords does not match')
        }

      } else if (mode == 'reset') {
        if (input$resetpass1 == input$resetpass2) {
          updatePassword(input$reset_username, input$resetpass1)
          message <- list('status' = T, 'text' = '')
        } else {
          message <- list('status' = F, 'text' = 'New passwords does not match')
        }
      }
    } else {
      message <- list('status' = F, 'text' = 'Password is incorrect')
    }

    if (shiny::isTruthy(message$status)) {
      shiny::updateTextInput(session = session, 'confirmPassword', label = NULL, value = '')
      shiny::removeModal()
      rv$commit <- input$confirmButton
    } else if (!is.null(message$status)) {
      shinyjs::show(id = "error", anim = T, time = 1, animType = "fade")
      shinyjs::delay(5000, shinyjs::hide(id = "error", anim = T, time = 1, animType = "fade"))

      output$error_message <- shiny::renderText({
        message$text
      })
    }
  })
}


# Page Config
#################################

zaWidgetUserManagementPageConfig <- list(

  # Disable Page
  # disabled = T,

  # Title for menu
  'title' = 'Account',

  # Sub-menu
  'submenu' = 'Settings',

  # Icon for menu
  'icon' = 'users',

  # Roles with permission to view page.
  # Exclusion will cause user to be TOTALLY unable to view page
  # Partial permission will have to be controlled within module
  'permission' = c('admin', 'guest')
)



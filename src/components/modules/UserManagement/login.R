


# Log In Module
#################################

returnClickJS <- '$(document).keydown(function(event) {
  if (($("#%s").is(":focus") || $("#%s").is(":focus") || $("#%s").is(":focus")) && (event.keyCode == 13)) $("#%s").click();
});'

autoLoginJS <- "document.addEventListener('DOMContentLoaded', function() {
  $.getJSON('https://api.ipgeolocation.io/ipgeo?format=json&apiKey=' +
    '500d26bc971942a2bf56a66dca698a1f',
    function(data) {
      if (data.time_zone.offset == 8) {
        $('#%s').click();
      }
    }
  );
}, false);"

OTPJS <- "const sendSms = (mobile, OTP, auth) => {
  // const client = require('twilio')(accountSid, authToken, { lazyLoading: true });
  // client.messages.create({ from: '+12342901868', to: mobile, body: OTP })
  let data = new FormData();
  data.append('Body', OTP);
  data.append('From', '+12342901868');
  data.append('To', mobile);
  let config = {
    method: 'post',
    maxBodyLength: Infinity,
    url: 'https://api.twilio.com/2010-04-01/Accounts/ACece45e7c1a6eb5997dde3823bf5a3cea/Messages.json',
    headers: { 'Authorization': auth },
    data: data
  };
  axios.request(config)
};"

customCSS <- ""

loginUI <- function(id, title = "Sign In", defaultUsername = 'admin', defaultPassword = 'admin', ...) {
  
  ns <- shiny::NS(id)
  
  htmltools::tagList(
    htmltools::tags$head(
      # htmltools::tags$script(htmltools::HTML(sprintf(autoLoginJS, ns('loginButton'), ns('loginButton')))),
      htmltools::tags$style(htmltools::HTML(customCSS)),
      htmltools::tags$script(htmltools::HTML(
        sprintf(returnClickJS, ns("loginUsername"), ns("loginPassword"), ns('OTP'), ns("loginButton"))
      )),
      htmltools::tags$script(type = "text/javascript",
        src = "https://cdnjs.cloudflare.com/ajax/libs/iframe-resizer/3.5.16/iframeResizer.contentWindow.min.js"
      ),
      htmltools::tags$script(type = 'text/javascript', src = "https://cdnjs.cloudflare.com/ajax/libs/axios/1.4.0/axios.min.js"),
      htmltools::tags$script(type = 'text/javascript', src = "https://cdnjs.cloudflare.com/ajax/libs/jquery.form/4.3.0/jquery.form.min.js"),
      htmltools::tags$script(htmltools::HTML(OTPJS))
    ),
    htmltools::div(class = 'login-ui',
      htmltools::div(id = ns("panel"), class = "contentwrapper logged-out",
        htmltools::div(class = "content",
          htmltools::div(class = "login",
            htmltools::div(class = "login-icon", htmltools::img(src = "img/icons/Icon-Lock.svg")),
            htmltools::div(class = "login-title", "Login to"),
            htmltools::div(class = "login-subtitle", title),
            htmltools::div(class = "login-formwrapper",
              htmltools::tags$form(
                htmltools::div(class = "input-group",
                  htmltools::tags$label(`for` = "Username", "Username"),
                  htmltools::div(class = "input",
                    htmltools::img(class = "input-icon", src = "img/icons/user-16.svg"),
                    shiny::textInput(ns("loginUsername"), label = NULL,
                      value = ifelse(Sys.info()[['user']] == 'Chua_ChengHong', 'admin', '')
                    )
                  )
                ),
                htmltools::div(class = "input-group",
                  htmltools::tags$label(`for` = "Password", "Password"),
                  htmltools::div(class = "input",
                    htmltools::img(class = "input-icon", src = "img/icons/lock-closed-16.svg"),
                    shiny::passwordInput(ns("loginPassword"), label = NULL,
                      value = ifelse(Sys.info()[['user']] == 'Chua_ChengHong', 'admin', '')
                    )
                  )
                ),
                htmltools::div(class = "btnwrapper",
                  htmltools::div(class = "button1", onclick = sprintf("$('#%s').click()", ns("loginButton")), "Sign in"),
                )
              )
            )
          )
        )
      ),
      shinyjs::hidden(
        shiny::actionButton(ns("loginButton"), 'Sign In')
      ),
      htmltools::div(class = 'login-line',
        htmltools::div(class = 'line'),
        htmltools::div(class = 'text', 'LOGIN')
      )
    )
  )
}

login <- function(input, output, session, user_db = getUserBase(), ...) {
  
  credentials <- shiny::reactiveValues(user_auth = F, info = NULL)
  
  # UI Defaults
  shiny::observeEvent(credentials$user_auth, {
    # cat("DEBUG: user_auth event triggered\n")
    if (shiny::isTruthy(credentials$user_auth)) {
      # shinyjs::runjs('$("body").removeClass("sidebar-collapse");')
      shinyjs::hide(id = "panel")
      shinyjs::hide(selector = ".login-line")
      shinyjs::removeClass(id = 'panel', 'logged-out')
      shinyjs::addClass(id = 'panel', 'logged-in')
      shinyjs::show(selector = '#logout-button')
    } else {
      # shinyjs::runjs('$("body").addClass("sidebar-collapse");')
      shinyjs::show(id = "panel")
      shinyjs::show(selector = ".login-line")
      shinyjs::removeClass(id = 'panel', 'logged-in')
      shinyjs::addClass(id = 'panel', 'logged-out')
      shinyjs::hide(selector = '#logout-button')
    }
  }, ignoreInit = T)
  
  # Reload Session on logout to remove all data
  shiny::observeEvent(session$userData$logout(), {
    shinyjs::runjs('sessionStorage.clear();')
    session$reload()
  }, ignoreInit = T)
  
  # Login Button Listener
  shiny::observeEvent(input$loginButton, {
    credentials$user_auth <- verify_user(input$loginUsername, input$loginPassword)
    credentials$userName <- input$loginUsername
  }, ignoreInit = T)
  
  shiny::observeEvent(credentials$user_auth, {

    # if user name row and password name row are same, credentials are valid
    if (shiny::isTruthy(credentials$user_auth)) {
      credentials$info <- user_db %>%
        dplyr::select(`name`, `username`, `permissions`, `email`) %>%
        dplyr::filter(`username` == credentials$userName) %>%
        dplyr::collect() %>%
        unlist() %>%
        as.list() %>%
        purrr::map_at('permissions', ~ stringr::str_split(.x, ',')[[1]])
    } else {
      # if not valid temporarily show error message to user
      shinyjs::toggle(id = session$ns('error'), anim = T, time = 1, animType = "fade")
      shinyjs::delay(5000, shinyjs::toggle(id = session$ns('error'), anim = T, time = 1, animType = "fade"))
    }
  }, ignoreInit = T)
  
  session$userData$credentials <- shiny::reactive({credentials})
}

# Verify Login Function
verify_user <- function(verify_username, verify_password, user_db = getUserBase()) {
  # check for match of input username to username column in data
  row_username <- user_db %>%
    dplyr::filter(`username` == verify_username) %>%
    dplyr::pull(`username`)
  
  passwordVerified <- F
  
  if (shiny::isTruthy(verify_username) && shiny::isTruthy(verify_password) && shiny::isTruthy(length(row_username))) {
    passwordVerified <- dplyr::filter(user_db, `username` == verify_username) %>%
      dplyr::pull(password_hash) %>%
      {tryCatch(sodium::password_verify(., verify_password), error = function(e) F)}
    
    if (passwordVerified ) {
      return(T)
    }
  }
  
  F
}


# Log Out Module
#################################

logoutUI <- function(id, label = "Log out") {
  ns <- shiny::NS(id)
  
  shinyjs::hidden(
    shinyWidgets::actionBttn(ns("button"), icon = shiny::icon('sign-out-alt'), style = 'bordered')
    # shiny::actionButton(ns("button"), label)
  )
}

logout <- function(input, output, session) {
  session$userData$logout <- shiny::reactive({input$button})
}






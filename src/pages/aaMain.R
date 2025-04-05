


aaMainModuleUI <- function(id) {
	ns <- NS(id)
	
	htmltools::div(style = 'max-height: calc(100vh - 50px); overflow: hidden;',
    htmltools::div(class = 'introwrapper',
      htmltools::div(class = 'widetile bg-pagetop',
        htmltools::div(class = 'welcomecontent',
          htmltools::div(class = 'titlewrapper',
            htmltools::div(class = 'title', 'Welcome'),
            shiny::uiOutput(ns('username'))
          ),
          htmltools::div(class = 'textwrapper',
            htmltools::div(class = 'text', style = 'margin-bottom: 20px;',
              htmltools::span(class = 'underglow', 'AI Consultant'),
              'is not just a tool. It\'s a companion to support and augment financial fraud investigators in their decision making in ',
              'Insider Trading investigations, preventing and solving financial crime and prosecuting offenders thus allowing the ',
              'specialists to focus on the parts that adds the most value'
            ),
            htmltools::div(class = 'text', 
              'The invaluable domain knowledge acquired over the years, feeding our capability ecosystem...'
            )
          )
        )
      )
    ),
	  htmltools::div(id = 'simulation', class = 'widetile bg-discover scroll-tile',
	    htmltools::div(class = 'tilecontent',
	      htmltools::div(class = 'titlewrapper',
	        htmltools::div(class = 'title', 'Discover'),
	        htmltools::div(class = 'subtitle', 'Chat Assistant')
	      ),
	      htmltools::div(class = 'textwrapper',
	        htmltools::div(class = 'text text-sm',
	          'Built on advance Large Language Model technologies, AI-Consultant is tuned on financial models to enhanced it\'s capabilities ', 
	          'in the financial field to better assist investigators in financial fraud and insider trading investigation'
	        )
	      )
	    )
	  ),
	  htmltools::div(id = 'survive', class = 'widetile bg-survive scroll-tile', style = 'display: none;',
      htmltools::div(class = 'tilecontent',
        htmltools::div(class = 'titlewrapper',
          htmltools::div(class = 'title', 'Discover'),
          htmltools::div(class = 'subtitle', 'Trade Dashboard')
        ),
        htmltools::div(class = 'textwrapper',
          htmltools::div(class = 'text text-sm',
            'Analytical Dashboard with insights from AI-Consultant\'s state-of-the-art AI detection algorithms and Generative AI ',
            'along with all the information the investigator needs to streamline the investigation process'
          )
        )
      )
    ),
	  htmltools::div(id = 'library', class = 'widetile bg-library scroll-tile', style = 'display: none;',
	    htmltools::div(class = 'tilecontent',
	      htmltools::div(class = 'titlewrapper',
	        htmltools::div(class = 'title', 'Discover'),
	        htmltools::div(class = 'subtitle', 'Search Companion')
	      ),
	      htmltools::div(class = 'textwrapper',
	        htmltools::div(class = 'text text-sm',
	          'AI-Consultant provides quick summarization capabilities to investigators when searching for relavent information on search engines ',
	          'while improving its\' own knowledge base with the new information to perform even better in the future'
	        )
	      )
	    )
	  ),
# 	  htmltools::div(id = 'treatment', class = 'widetile bg-treatment scroll-tile', style = 'display: none;',
# 	    htmltools::div(class = 'tilecontent',
# 	      htmltools::div(class = 'titlewrapper',
# 	        htmltools::div(class = 'title', 'Discover'),
# 	        htmltools::div(class = 'subtitle', 'Treatment')
# 	      ),
# 	      htmltools::div(class = 'textwrapper',
# 	        htmltools::div(class = 'text text-sm',
# 	          'AI Consultant provides alternative available drug recommendations that may not have been proven specifically ',
#             'for the cancer of interest, but are being used for other types of cancer.'
# 	        )
# 	      )
# 	    )
# 	  ),
	  htmltools::div(class = 'tile-line',
	    htmltools::div(id = 'lineunder', class = 'line'),
	    htmltools::div(id = 'pagetext', class = 'text', 'CHAT ASSISTANT')
	  ),
	  htmltools::div(class = 'nav-arrows',
	    htmltools::div(class = 'nav-spacer'),
	    htmltools::div(id = 'down', class = 'down', htmltools::img(id = 'scrollDown', src = 'img/icons/arrow-down-64px-01.svg')),
	    htmltools::div(id = 'up', class = 'up', htmltools::img(id = 'scrollUp', src = 'img/icons/arrow-up-64px-01.svg'))
    ),
    htmltools::div(class = 'pagenum',
      htmltools::div(id = 'currentPage', class = 'current', `data-page` = '1', '1'),
      htmltools::div(class = 'total', '/3')
    )
	)
}


aaMainModule <- function(input, output, session, credentials, ...) {


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


	####################################################################

  output$username <- shiny::renderUI({
    credentials <- shiny::req(credentials())

    htmltools::div(class = 'subtitle', credentials$info$name)
  })
}


# Page Config
#################################
aaMainPageConfig <- list(

  # Title for menu
  'title' = 'Main',

  # Icon for menu
  'icon' = 'home',

  # Roles with permission to view page.
  # Exclusion will cause user to be TOTALLY unable to view page
  # Partial permission will have to be controlled within module
  'permission' = c('root', 'admin', 'user')
)

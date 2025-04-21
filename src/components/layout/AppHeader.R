


# Header UI
#################################

widgetUI <- htmltools::tags$li(class = "dropdown"
  # logoutUI('logout')
)

AppHeaderUI <- if (packageVersion('shinydashboardPlus') < package_version("1.0.0")) {
  shinydashboardPlus::dashboardHeaderPlus(

    # Settings
    widgetUI,

    # Branding
title = htmltools::a(
  href = "https://tamu-insidertrading.streamlit.app/",  # <-- Replace this with your real URL
  target = "_blank",  # Opens in new tab
  htmltools::img(src = 'img/logo/LogoIcon.png', height = "40px")
),


    # Right Sidebar
    rightSidebarIcon = "bars",

    # Fix Header
    fixed = T
  )
} else {
  shinydashboardPlus::dashboardHeader(

    # Settings
    widgetUI,

    # Branding
title = htmltools::a(
  href = "https://tamu-insidertrading.streamlit.app/",  # <-- Replace this with your real URL
  target = "_blank",  # Opens in new tab
  htmltools::img(src = 'img/logo/LogoIcon.png', height = "40px")
),

    # Right Sidebar
    controlbarIcon = "bars",

    # Fix Header
    fixed = T
  )
}



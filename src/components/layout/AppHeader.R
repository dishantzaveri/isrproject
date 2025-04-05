


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
    title = htmltools::a(href = '#top',
      htmltools::img(src = 'img/logo/LogoLong.png')
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
    title = htmltools::a(href = '#top',
      htmltools::img(src = 'img/logo/LogoLong.png')
    ),

    # Right Sidebar
    controlbarIcon = "bars",

    # Fix Header
    fixed = T
  )
}



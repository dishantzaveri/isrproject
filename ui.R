
source('src/global.R')

# UI
################################

shiny::shinyUI(
  htmltools::tagList(
    do.call(
      dashboardUI,
      list(
        header = AppHeaderUI,
        sidebar = AppLeftSideBarUI,
        body = AppBodyUI
      )
    ) %>% {
      if ('shiny.tag' %in% class(.)) htmltools::tagAppendAttributes(., class = 'sidebar-collapse')
      else {
        .[[1]] <- htmltools::tagAppendAttributes(.[[1]], class = 'sidebar-collapse')
        .
      }
    } %>%
    htmltools::tagAppendAttributes(.cssSelector = '.content-wrapper',
      style = 'height: calc(100vh - 50px); !important; overflow: auto;'
    ),
    htmltools::suppressDependencies('shiny-css', 'ionrangeslider-css', 'datatables-css', 'shinydashboard-css')
  )
)




# End of script



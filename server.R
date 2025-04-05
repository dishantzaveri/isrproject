
shiny::shinyServer(function(input, output, session) {

  # App Layout
  #################################

  # Layout
  shiny::callModule(AppLeftSideBar, 'LeftSideBarContent')
  shiny::callModule(AppBody, 'AppBodyContent', global = session)


  # App Dynamic Data
  #################################



})

# End of script

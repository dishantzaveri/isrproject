


# JS
#################################

sidebarJS <- '$(".sidebar-menu > li.treeview").each(function() {
  $(this).children().first().on("click", function() {
    if ($(this).siblings().last().hasClass("menu-open")) {
      $(this).children().last().removeClass("fa-angle-left");
      $(this).children().last().addClass("fa-angle-down");
    } else {
      $(this).children().last().removeClass("fa-angle-down");
      $(this).children().last().addClass("fa-angle-left");
    }
  });
});'



# Left Side Bar Menu
#################################

RAppPageConfigList <- lapply(RAppPageList, function(x) {
  get(paste0(stringr::str_extract(x, '([^/]+$)'), 'PageConfig')) %>%
    purrr::list_modify(`submenu` = ifelse(exists('submenu', .), .$submenu, x)) %>%
    purrr::list_modify(`id` = x)
}) %>%
  rlang::set_names(purrr::map_chr(., ~ .x$id))

PyAppPageConfigList <- lapply(PyAppPageList, function(x) {
  py[paste0(stringr::str_extract(x, '([^/]+$)'), 'PageConfig')] %>%
    purrr::list_modify(`submenu` = ifelse(exists('submenu', .), .$submenu, x)) %>%
    purrr::list_modify(`id` = x)
}) %>%
  rlang::set_names(purrr::map_chr(., ~ .x$id))

AppPageConfigList <- c(RAppPageConfigList, PyAppPageConfigList)[sort(c(
  purrr::map_chr(RAppPageConfigList, ~ .x$id),
  purrr::map_chr(PyAppPageConfigList, ~ .x$id)
))]

AppMenuList <- AppPageConfigList %>%
  purrr::map(~ .$submenu) %>%
  unique()



# Left Side Bar Module
#################################

AppLeftSideBarContentUI <- function(id) {

  ns <- shiny::NS(id)

  htmltools::tagList(
    shinydashboard::sidebarMenuOutput(ns('menu'))
  )
}

AppLeftSideBar <- function(input, output, session, ...) {

  ns <- session$ns
  permissions <- shiny::reactive({ shiny::req(session$userData$credentials()$info$permissions) })

  shiny::observeEvent(permissions(), {
    # shiny::callModule(UserProfileWidget, 'UserProfileWidget')

    output$menu <- shinydashboard::renderMenu({
      MenuUIList <- lapply(AppMenuList, function(MenuName) {
        curAppSubMenuItemList <- AppPageConfigList %>%
          purrr::keep(~ any(permissions() %in% .x$permission), setequal(.x$permission, permissions())) %>%
          purrr::keep(~ .x$submenu == MenuName)

        if (length(curAppSubMenuItemList) > 1) {
          shinydashboard::menuItem(
            MenuName,
            purrr::map(curAppSubMenuItemList,
              ~ shinydashboard::menuSubItem(.x$title, tabName = stringr::str_to_lower(.x$id), icon = shiny::icon(.x$icon))
            ),
            startExpanded = T,
            icon = shiny::icon('bars')
          )
        } else {
          purrr::map(curAppSubMenuItemList,
            ~ shinydashboard::menuItem(.x$title, tabName = stringr::str_to_lower(.x$id), icon = shiny::icon(.x$icon))
          )
        }
      })

      do.call(shinydashboard::sidebarMenu, list(purrr::compact(MenuUIList), 'tabName' = MenuUIList[1]))
    })

  }, once = T)
}



# Left Side Bar UI
#################################

AppLeftSideBarUI <- if (packageVersion('shinydashboardPlus') < package_version("1.0.0")) {
  shinydashboard::dashboardSidebar(
    AppLeftSideBarContentUI('LeftSideBarContent'),
    htmltools::div(class = 'display: flex;',
      logoutUI('logout')
    )
  )
} else {
  shinydashboardPlus::dashboardSidebar(
    AppLeftSideBarContentUI('LeftSideBarContent'),
    htmltools::div(class = 'display: flex;',
      logoutUI('logout')
    )
  )
} %>%
  htmltools::tagAppendAttributes(
    style = 'width: 50px !important; top: 50px; min-height: calc(100% - 50px); background: white !important; padding-top: 0;'
  )

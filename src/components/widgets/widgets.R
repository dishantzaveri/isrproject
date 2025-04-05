


# Source App Widgets
#################################

# Widget Directory
widgetDir <- 'src/components/widgets'

# Source Widgets
list.files(widgetDir, recursive = T, full.names = T) %>%
  magrittr::extract(. != widgetDir & stringr::str_detect(., '/')) %>%
  purrr::discard(~ .x == paste0(widgetDir, '/widgets.R')) %>%
  lapply(source) %>%
  invisible()



# App Widgets Override
#################################












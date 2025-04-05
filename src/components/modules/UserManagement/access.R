


# Access Log
#################################

logFilePath <- 'logs/access.log'

# Get Access Log Connection
getAccessLog <- function(path = logFilePath) {
  readr::read_csv(path) %>% 
    dplyr::mutate(`dts` = as.POSIXct(strptime(`dts`, "%Y-%m-%d %H:%M:%S"))) %>%
    dplyr::mutate(`Date` = as.character(as.Date(`dts`)))
}

# Create Access Log
createAccessLog <- function(path = logFilePath) {
  write('username,dts,page,module,remark1,remark2', file = path)
}

# Add Entry to Access Log
appendAccessLog <- function(userid, module, page, remark1, remark2, path = logFilePath) {
  if (!file.exists(logFilePath)) createAccessLog()
  paste(userid, sprintf("%s", Sys.time()), module, page, remark1, remark2, sep = ',') %>%
    write(file = path, append = T)
}


  




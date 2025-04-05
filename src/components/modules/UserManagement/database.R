

userListFile <- 'db/userList.csv'


# Database
################################

# Create New User DB
createUserBase <- function(path = userListFile) {
  write('username,password_hash,permissions,name,email', file = path)
  add_user(username = 'guest', permissions = 'admin', name = 'Guest', email = 'guest@lipidall.com', password = 'guest')
}

# Get User DB Connection
getUserBase <- function(path = userListFile) {
  readr::read_csv(path)
}



# User
################################

# Add User
addUser <- function(addusername, addpassword, addPermissions, addname, addemail, addStuBatch, user_db = userListFile) {
  paste(addusername, sodium::password_store(password), addPermissions, addname, addemail, sep = ',') %>%
    write(file = user_db, append = T)
}

# Add User V2
addUser2 <- function(addusername, addpassword, addPermissions, addList, user_db = userListFile) {
  readr::read_csv(user_db) %>%
    dplyr::rows_upsert(
      tibble::tibble(username = username, password = sodium::password_store(password), permissions = permissions), by = 'username'
    ) %>%
    readr::write_csv(user_db)
}

# Add user v3
add_user <- function(..., user_db = userListFile) {
  new_user <- tibble::tibble(...) %>%
    dplyr::mutate('password_hash' = sodium::password_store(`password`)) %>%
    dplyr::select(-`password`)
  
  readr::read_csv(user_db) %>%
    dplyr::rows_upsert(dplyr::select(new_user, names(.)), by = 'username') %>%
    readr::write_csv(user_db)
}

# Delete User
deleteUser <- function(delUsername, user_db = userListFile) {
  readr::read_csv(user_db) %>%
    dplyr::filter(`username` != delUsername) %>%
    readr::write_csv(user_db)
}

# Update Permission
updatePermission <- function(uTypeSelect, usernameSelect, user_db = userListFile) {
  read_csv(user_db) %>%
    dplyr::rows_update(tibble::tibble(username = usernameSelect, permissions = uTypeSelect), by = 'username') %>%
    readr::write_csv(user_db)
}

# Update Password
updatePassword <- function(usernameSelect, newpassword, user_db = userListFile) {
  readr::read_csv(user_db) %>%
    dplyr::rows_update(
      tibble::tibble(`username` = usernameSelect, `password_hash` = sodium::password_store(as.character(newpassword)))
    , by = 'username') %>%
    readr::write_csv(user_db)
}

# Update info
updateInfo <- function(usernameSelect, nameTxt, emailTxt, user_db = userListFile) {
  readr::read_csv(user_db) %>%
    dplyr::rows_update(tibble::tibble(username = usernameSelect, name = nameTxt, email = emailTxt), by = 'username') %>%
    readr::write_csv(user_db)
}

# Update Info v2
update_info <- function(..., user_db = userListFile) {
  readr::read_csv(user_db) %>%
    dplyr::rows_update(dplyr::select(tibble::tibble(...), tidyselect::any_of(names(.))), by = 'username') %>%
    readr::write_csv(user_db)
}

# Get Info
get_info <- function(user_name, user_db = userListFile) {
  readr::read_csv(user_db) %>%
    dplyr::filter(`username` == user_name)
}










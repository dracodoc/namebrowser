# .onLoad <- function(libname, pkgname) {
#   data("name_table", envir = environment())
# }
#
# .onUnload <- function(libname, pkgname) {
#   rm(name_table, envir = environment())
# }

# .onAttach <- function(libname, pkgname) {
#   packageStartupMessage("Welcome to namebrowser!")
#   summary_name_table("-- Name Table Loaded", name_table)
# }
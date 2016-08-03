#' Get path of installed_package_folder\\data\\
#'
#' Always load and save data to this folder to make sure only one version of
#' data exist
#'
#' @return installed_package_folder\\data\\
#' @import stringr
#' @export
#'
get_data_folder <- function(){
  package_folder <- devtools::inst("namebrowser")
  data_folder <- str_c(package_folder, "\\data\\")
}

#' Scan package changes by name only
#'
#' Compare currently packages name with previous list \code{pkg_list}.
#'
#' Use \code{.packages(all.available = TRUE)} to check folder under library
#' location path \code{lib.loc}. Has more false positives but fast.
#'
#' @param startNew Default FALSE, compare user's environment with name table
#'   shipped with this package, only update difference. If True, build from
#'   scratch.
#'
#' @return list(pkg_to_add, pkg_to_remove)
#' @import stringr
#' @export
#'
pkg_name_changed <- function(startNew = FALSE){
  if (startNew) {
    pkg_list <- .packages(all.available = TRUE)
    pkg_to_add <- pkg_list
    pkg_to_remove <- NULL
    save(pkg_list, file = str_c(get_data_folder(), "pkg_list.rda"))
    list("pkg_to_add" = pkg_to_add, "pkg_to_remove" = pkg_to_remove)
  } else{
    data("pkg_list", envir = environment())
    pkg_list_now <- .packages(all.available = TRUE)
    # make some changes in both list in development to simulate changes.
    # TODO remove after passed
    pkg_list <- pkg_list[-(1:5)]
    pkg_list_now <- pkg_list_now[-(8:12)]
    # TODO remove above
    pkg_to_add <- pkg_list_now[!pkg_list_now %in% pkg_list]
    pkg_to_remove <- pkg_list[!pkg_list %in% pkg_list_now]
    #sync name list  to current version, use change list to sync names too
    pkg_list <- pkg_list_now
    save(pkg_list, file = str_c(get_data_folder(), "pkg_list.rda"))
    list("pkg_to_add" = pkg_to_add, "pkg_to_remove" = pkg_to_remove)
  }

}

#' Scan package changes by name and version
#'
#' Compare current packages name and version with previous table
#' \code{pkg_table}.
#'
#' Use \code{installed.packages} to check DESCRIPTION file for each package folder, more accurate but slower than checking name only.
#'
#' @param startNew Default FALSE, compare user's environment with name table
#'   shipped with this package, only update difference. If True, build from
#'   scratch.
#'
#' @return list(pkg_to_add, pkg_to_remove)
#' @import data.table stringr
#' @export
#'
pkg_name_version_changed <- function(startNew = FALSE){
  if (startNew) {
    pkg_table <- data.table(installed.packages(priority = "NA"))
    pkg_table <- pkg_table[, .(Package, LibPath, Version)]
    setkey(pkg_table, Package, Version)
    pkg_to_add <- pkg_table[, Package]
    pkg_to_remove <- NULL
    save(pkg_table, file = str_c(get_data_folder(), "pkg_table.rda"))
    list("pkg_to_add" = pkg_to_add, "pkg_to_remove" = pkg_to_remove)
  } else{
    data("pkg_table", envir = environment())
    pkg_table_now <- data.table(installed.packages(priority = "NA"))
    pkg_table_now <- pkg_table_now[, list(Package, LibPath, Version)]
    # make some changes for development test
    # TODO remove later, change rows, also change version numbers
    pkg_table <- pkg_table[6:379, ]
    pkg_table_now <- pkg_table_now[1:372,]
    pkg_table[5, Version := "3.2"]
    # TODO remove above later
    # Version is character
    setkey(pkg_table, Package, Version)
    setkey(pkg_table_now, Package, Version)
    pkg_to_remove <- pkg_table[!pkg_table_now][, Package]
    pkg_to_add <- pkg_table_now[!pkg_table][, Package]
    #sync pkg table  to current version ------
    pkg_table <- pkg_table_now
    save(pkg_table, file = str_c(get_data_folder(), "pkg_table.rda"))
    list("pkg_to_add" = pkg_to_add, "pkg_to_remove" = pkg_to_remove)
  }
}

#' Update name table
#'
#' Update name table by package name changes, or by changes both in name and
#' version.
#'
#' In one case, \code{.packages(all.available = TRUE)} found 408 packages
#' folder, \code{installed.packages} found 379 packages with valid DESCRIPTION
#' file, the final loading, attaching, listing names function found 267 packages
#' with at least one name.
#'
#' This package shipped with a name table of these 267 packages. When user
#' updated name table in first time, the package changes were based on this name
#' table. User can also manually build name table from scratch by sending all
#' package names to
#'
#' @param withVersion Default FALSE, update by package name changes. If TRUE,
#'   update name table by changes both in name and version version
#' @param startNew  Default FALSE, compare user's environment with name table
#'   shipped with this package, only update difference. If True, build from
#'   scratch.
#' @import data.table stringr
#' @export
#'
update_name_table <- function(withVersion = FALSE, startNew = FALSE){
  # get pkg update list ------
  if (withVersion) {
    pkg_updates <- pkg_name_version_changed(startNew)
    cat("-- Packages name and version changes:\n")
  } else {
    pkg_updates <- pkg_name_changed(startNew)
    cat("-- Packages name changes:\n")
  }
  # print changes to console
  print(pkg_updates)
  # update names by list ------
  name_table_updates <- scan_names(pkg_updates$pkg_to_add)
  setkey(name_table_updates, package, obj_name)
  # read previous data, merge, discard, setkey, save ------
  data("name_table", envir = environment())
  # names to be kept. No direct way to remove rows in data.table, select keeper
  name_table_keep <- name_table[!package %in% pkg_updates$pkg_to_remove,]
  name_table <- rbind(name_table_keep, name_table_updates)
  save(name_table, file = str_c(get_data_folder(), "name_table.rda"))
}

#' Build name table for selected packages
#'
#' All object names in packages are scanned with
#' \code{ls("package:pkgname")}.
#'
#' Functions, datasets, operators, symbols, alternative formats like
#' \code{body()<-} are included from \code{ls()}. Package must be loaded and
#' attached first before using \code{ls()}. Thus all available packages are
#' loaded and attached in the scanning process. Although extra efforts were made
#' to unload packages properly after use, there still will be some left over
#' when the scan finished. It's recommended to build index in a new R session
#' instead of working session with important data, and restart R session after
#' building.
#'
#' @param package_list packages to be scanned
#' @import stringr data.table
#' @return name_table name table of scanned packages
#'
scan_names <- function(package_list){
  # initial loaded packages need to be protected from the clean up process
  searchlist_0 <- .packages()
  namespace_0 <- loadedNamespaces()
  name_list <- vector("list", length(package_list))
  # some functions need prefix, some do not
  package_list_prefixed <- str_c("package:", package_list)
  error_packages <- character(length(package_list))
  for (i in seq_along(package_list)) {
    if (suppressPackageStartupMessages(require(package_list[i],
                                               character.only = TRUE,
                                               quietly = TRUE))) {
      name_list[[i]] <- ls(package_list_prefixed[i])
      cat(paste0("    Scanned ", package_list[i], "\n"))
      # unload package if not in initial environment
      if (!package_list[i] %in% searchlist_0) {
        # some cannot be unloaded because of order, dependency etc
        try(unloadNamespace(package_list[i]))
      }
    } else{# packages cannot be loaded properly
      error_packages[i] <- package_list[i]
    }
  }
  cat("-- Packages that have problem loading:\n")
  print(error_packages[error_packages != ""]) # initialized with ""
  # convert nested name list into data table ------
  name_table_list <- vector("list", length(name_list))
  for (i in seq_along(name_list)) {
    if (!is.null(name_list[[i]]) && !identical(name_list[[i]], character(0))) {
      #print(i)
      name_table_current <- data.table(package = package_list[i],
                                       obj_name = name_list[[i]])
      name_table_list[[i]] <- name_table_current
    }
  }
  rbindlist(name_table_list)
}

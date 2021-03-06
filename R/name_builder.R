#' Get path of installed_package_folder\\data\\
#'
#' Always load and save data to this folder to make sure only one version of
#' data exist
#'
#' @return installed_package_folder\\data\\
#' @import stringr
#'
get_data_folder <- function(){
  # devtools version need extra dll, when too many lib loading error happened, this cannot run, further prevent data to be saved, use base version instead.
  # package_folder <- "d:\\Work\\R\\namebrowser\\"
  package_folder <- find.package("namebrowser")
  data_folder <- file.path(package_folder, "data")
}

#' Scan package changes by name only
#'
#' Compare currently packages name with previous list \code{pkg_list}.
#'
#' Use \code{.packages(all.available = TRUE)} to check folder under library
#' location path \code{lib.loc}. Faster than checking name and version both, but
#' has more false positives. It's recommended to use this only when scan
#' packages name and version both is too slow for you.
#'
#' @param startNew Default FALSE, compare user's environment with name table
#'   shipped with this package, only update difference. If True, build from
#'   scratch.
#'
#' @return list(pkg_to_add, pkg_to_remove)
#' @import stringr
#'
pkg_name_changed <- function(startNew = FALSE){
  if (identical(startNew, TRUE)) {
    pkg_list <- .packages(all.available = TRUE)
    pkg_to_add <- pkg_list
    pkg_to_remove <- NULL
    save(pkg_list, file = file.path(get_data_folder(), "pkg_list.rda"))
    list("pkg_to_add" = pkg_to_add, "pkg_to_remove" = pkg_to_remove)
  } else if (identical(startNew, FALSE)) {
    data("pkg_list", package = "namebrowser", envir = environment())
    pkg_list_now <- .packages(all.available = TRUE)
    # make some changes in both list in development to simulate changes.
    # TODO remove after passed
    # pkg_list <- pkg_list[-(1:5)]
    # pkg_list_now <- pkg_list_now[-(8:12)]
    # TODO remove above
    pkg_to_add <- pkg_list_now[!pkg_list_now %in% pkg_list]
    pkg_to_remove <- pkg_list[!pkg_list %in% pkg_list_now]
    println("-- Packages to add:")
    print(pkg_to_add)
    println("-- Pckages to remove:")
    print(pkg_to_remove)
    #sync name list  to current version, use change list to sync names too
    pkg_list <- pkg_list_now
    save(pkg_list, file = file.path(get_data_folder(), "pkg_list.rda"))
    list("pkg_to_add" = pkg_to_add, "pkg_to_remove" = pkg_to_remove)
  }
}

#' Scan package changes by name and version
#'
#' Compare current packages name and version with previous table
#' \code{pkg_table}.
#'
#' Use \code{installed.packages()} to check DESCRIPTION file for each package
#' folder, more accurate than checking name only. R help cautioned it be slow if
#' thouands of packages available, but checking 300 ~ 400 packages didn't have
#' significant performance difference. It's recommended to always use this unless
#' it's too slow for you.
#'
#' @param startNew Default FALSE, compare user's environment with name table
#'   shipped with this package, only update difference. If True, build from
#'   scratch.
#'
#' @return list(pkg_to_add, pkg_to_remove)
#' @import data.table stringr
#'
pkg_name_version_changed <- function(startNew = FALSE){
  if (startNew) {
    pkg_table <- data.table(installed.packages())
    pkg_table <- pkg_table[, .(Package, LibPath, Version)]
    setkey(pkg_table, Package, Version)
    pkg_to_add <- pkg_table[, Package]
    pkg_to_remove <- NULL
    save(pkg_table, file = file.path(get_data_folder(), "pkg_table.rda"))
    list("pkg_to_add" = pkg_to_add, "pkg_to_remove" = pkg_to_remove)
  } else{
    data("pkg_table", package = "namebrowser", envir = environment())
    pkg_table_now <- data.table(installed.packages())
    pkg_table_now <- pkg_table_now[, list(Package, LibPath, Version)]
    # make some changes for development test
    # TODO remove later, change rows, also change version numbers
    # pkg_table <- pkg_table[6:379, ]
    # pkg_table_now <- pkg_table_now[1:300,]
    # pkg_table[5, Version := "3.2"]
    # TODO remove above later
    # Version is character
    setkey(pkg_table, Package, Version)
    setkey(pkg_table_now, Package, Version)
    pkg_to_remove_nv <- pkg_table[!pkg_table_now]
    pkg_to_add_nv <- pkg_table_now[!pkg_table]
    println("-- Packages to add:")
    print(pkg_to_add_nv)
    println("-- Pckages to remove:")
    print(pkg_to_remove_nv)
    #sync pkg table  to current version ------
    pkg_table <- pkg_table_now
    save(pkg_table, file = file.path(get_data_folder(), "pkg_table.rda"))
    list("pkg_to_add" = pkg_to_add_nv[, Package],
         "pkg_to_remove" = pkg_to_remove_nv[, Package])
  }
}

#' Update name table
#'
#' First generate list of package changes, then scan new or upgraded packages
#' for names, add to name table, remove deleted packages entries in name table.
#'
#' In one case, \code{.packages(all.available = TRUE)} found 408 packages
#' folder, \code{installed.packages} found 379 packages with valid DESCRIPTION
#' file, the final loading, attaching, listing names function found 267 packages
#' with at least one name.
#'
#' Common usage:
#'
#' \code{namebrowser::update_name_table()} Use all default parameter, called by
#' Addin menu Update name table. Compare package name and version changes to
#' existing name table, then update it.
#'
#' \code{namebrowser::update_name_table(withVersion = FALSE)} Compare changes by
#' package name change only, then update name table.
#'
#' \code{namebrowser::update_name_table(startNew = TRUE)} Build name table from
#' scratch, ignore existing name table content.
#'
#' \code{namebrowser::update_name_table(tryError = TRUE)} Used to finish
#' unscanned packages that failed to load in last scan because of DLL limit
#' error. Must run with new R session. May need to run several times to finish
#' all packages that can be scanned. There could still be some packages left at
#' last because of package installation problems.
#'
#' @param withVersion Default TRUE, check package changes both in name and
#'   version. If FALSE, check package name changes only, a little bit faster but
#'   with more false positives. The speed difference is minor compared to the
#'   package scanning process. It's recommended to use default option unless the
#'   package listing process is really slow. Though in that case the package
#'   scanning process will be much more slower anyway.
#' @param startNew Default FALSE, compare user's environment with name table
#'   shipped with this package, only update difference. If True, build from
#'   scratch.
#' @param tryError Default FALSE. If True, withVersion and startNew must be
#'   FALSE, Scan the packages cannot be loaded in last update again.
#'
#' @import data.table stringr
#' @export
#'
update_name_table <- function(withVersion = TRUE, startNew = FALSE, tryError = FALSE){
  # get pkg update list ------
  if (tryError) { # scan error pacakage again
    data(error_packages, package = "namebrowser", envir = environment())
    pkg_to_add <- error_packages
    pkg_to_remove <- NULL
    println("-- Rescan packages failed to load in last scan:")
    print(pkg_to_add)
  } else{# scan package changes
    if (withVersion) {
      pkg_updates <- pkg_name_version_changed(startNew)
      println("-- Scan packages name and version changes:")
    } else {
      pkg_updates <- pkg_name_changed(startNew)
      println("-- Scan packages name changes:")
    }
    if (identical(pkg_updates$pkg_to_add, character(0)) &&
        identical(pkg_updates$pkg_to_remove, character(0))) {
      println("Nothing to update.")
      return()
    }
    pkg_to_add <- pkg_updates$pkg_to_add
    pkg_to_remove <- pkg_updates$pkg_to_remove
    # move print to listing function, so that each have its own process, version changes can be printed
    #print(pkg_updates)
  }
  # update names by list ------
  name_table_updates <- scan_names(pkg_to_add)
  setkey(name_table_updates, package, obj_name)
  # read previous data, merge, discard, setkey, save ------
  data("name_table", package = "namebrowser", envir = environment())
  summary_name_table("-- Original Name table:", name_table)
  # names to be kept. No direct way to remove rows in data.table, select keeper
  if (startNew) {
    name_table_keep <- data.table(package = character(), obj_name = character())
  } else{
    name_table_keep <- name_table[!package %in% pkg_to_remove,]
  }
  summary_name_table("-- To be removed from original:",
                     name_table[package %in% pkg_to_remove,])
  summary_name_table("-- New scanned updates:", name_table_updates)
  # Note because of version changes, it's possible to remove package A then add package A again, must remove first, add later.
  name_table <- unique(rbind(name_table_keep, name_table_updates))
  setkey(name_table, package, obj_name)
  summary_name_table("-- Final updated Name table:", name_table)
  println("-- See more options of updating name table in ?namebrowser::update_name_table")
  save(name_table, file = file.path(get_data_folder(), "name_table.rda"))
}

#' Print summary of Name table
#'
#' @param nt name table to be summarized
#'
summary_name_table <- function(table_title, nt){
  println(table_title, "\n",
             uniqueN(nt[, package]), " packages, ", nt[, .N], " names")
}

#' Helper method to print console message with default new line
#'
#' @param ... send to paste0
#'
println <- function(...){
  cat(paste0(..., "\n"))
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
  if (identical(package_list, character(0))) {
    return(data.table(package = character(), obj_name = character()))
  }
  # initial loaded packages need to be protected from the clean up process
  searchlist_0 <- .packages()
  namespace_0 <- loadedNamespaces()
  name_list <- vector("list", length(package_list))
  # some functions need prefix, some do not
  package_list_prefixed <- str_c("package:", package_list)
  error_packages <- character(length(package_list))
  for (i in seq_along(package_list)) {
    println(paste0(".. Loading package ", package_list[i]))
    if (suppressPackageStartupMessages(require(package_list[i],
                                               character.only = TRUE,
                                               quietly = TRUE))) {
      name_list[[i]] <- ls(package_list_prefixed[i])
      println(paste0("** Scanned pacakge ", package_list[i]))
      # unload package if not in initial environment
      if (!package_list[i] %in% searchlist_0) {
        # some cannot be unloaded because of order, dependency etc
        println(paste0("** Unload  pacakge ", package_list[i]))
        try(unloadNamespace(package_list[i]))
      }
    } else{# packages cannot be loaded properly
      error_packages[i] <- package_list[i]
    }
  }
  error_packages <- error_packages[error_packages != ""] # initialized with ""
  if (length(error_packages) > 0) {
    println("\n-----------------------------\n!!!!Packages that have problem loading:")
    print(error_packages)
    println(">> If some packages cannot be loaded with error 'maximal number of DLLs reached...', it's because too many packages were loaded in scan but cannot be unloaded for dependency reason. The DLL limit is 100 according to http://stackoverflow.com/questions/24832030/exceeded-maximum-number-of-dlls-in-r\n>> Start a new R session, use namebrowser::update_name_table(tryError = TRUE) to scan them again. Every new scan will reduce error packages a little bit.\n>> After several runs, there could be still some error packages that were not installed properly thus cannot be loaded or scanned.\n-----------------------\n")
  }
  save(error_packages, file = file.path(get_data_folder(), "error_packages.rda"))
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
  name_table_updates <- rbindlist(name_table_list)
  if (name_table_updates[, .N] == 0) {# when all error packages have installation error, pkg_add is not empty but result is empty, set proper column name so other operations will not raise error
    name_table_updates <- data.table(package = character(), obj_name = character())
    println("-- All packages tried to scan cannot be loaded, could be installation problem")
  }
  setkey(name_table_updates, package, obj_name)
  return(name_table_updates)
}

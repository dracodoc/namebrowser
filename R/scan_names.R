#' Get path of installed_package_folder\\data\\
#'
#' Always load and save data to this folder to make sure only one version of
#' data exist
#'
#' @return installed_package_folder\\data\\
#' @export
#'
get_data_folder <- function(){
    package_folder <- devtools::inst("namebrowser")
    data_folder <- stringr::str_c(package_folder, "\\data\\")
}

#' Scan package changes by name only
#'
#' Compare currently packages name with previous list \code{pkg_list}.
#'
#' Use \code{.packages(all.available = TRUE)} to check folder under library
#' location path \code{lib.loc}. Has more false positives but fast.
#'
#' @return list(pkg_to_add, pkg_to_remove)
#' @export
#'
pkg_name_changed <- function(){
    # scan names by update list
    pkg_list_now <- .packages(all.available = TRUE)
    # merge updates and old data, remove to be removed, in function

    # save data, a character vector
    save(pkg_list_now,
         file = stringr::str_c(get_data_folder(),
                               "pkg_list.rda"))
}

#' Scan package changes by name and version
#'
#' Compare current packages name and version with previous table
#' \code{pkg_table}.
#'
#' Use \code{installed.packages} to check DESCRIPTION file for each package folder, more accurate but slower than checking name only.
#'
#' @return list(pkg_to_add, pkg_to_remove)
#' @export
#'
pkg_name_version_changed <- function(){
    data("all_packages_versioned", envir = environment())
    pkg_table_now <- data.table(installed.packages(priority = "NA"))
    pkg_table_now <- pkg_table_now[, .(Package, LibPath, Version)]



    #actually only save when previous version and current version are compared and used. a data.table
    save(pkg_table_now,
         file = stringr::str_c(get_data_folder(),
                               "pkg_table.rda"))
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
#' @param withVersion If TRUE, update name table by changes both in name and
#'   version version
#'
#' @export
#'
update_name_table <- function(withVersion = FALSE){
    # get pkg update list ----
    if (withVersion) {

    } else {

    }
    # update names by list ----

    # read previous data, merge, discard, save
    data("name_table", envir = environment())



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
#'
scan_names <- function(package_list){
    # TODO also need to save the list of packages that cannot load back to package table, next time even if the package name or version doesn't change, it may become usable.
    # load previous data ----
    data("name_table", envir = environment())
    # compare package table date, if too old, update with function

    # build list of package to be updated, include previous empty response packages, inquiry and build table, replace cooresponding part of old data
    # two standard: either by package name or by package version

    # save every data set
    sl_0 <- .packages() # search list
    ns_0 <- loadedNamespaces()
    all_packages <- .packages(all.available = TRUE)
    name_list <- vector("list", length(all_packages))
    # prepare all to utilize vectorization. note some function need prefixed version, some do not
    all_packages_prefixed <- str_c("package:", all_packages)
    error_packages <- character(length(all_packages))
    for (i in seq_along(all_packages)) {
        if (suppressPackageStartupMessages(require(all_packages[i],
                                                   character.only = TRUE,
                                                   quietly = TRUE))) {
            name_list[[i]] <- ls(all_packages_prefixed[i])
            cat(paste0(all_packages[i], "\n"))
            # cannot unload base list, use package string to match format
            if (!all_packages[i] %in% sl_0) {
                try(unloadNamespace(all_packages[i])) # some still cannot be unloaded
            }
        } else{
            error_packages[i] <- all_packages[i]
        }
    }
    error_packages <- error_packages[error_packages != ""]
    # ns_1 <- loadedNamespaces()
    # changes <- str_sub(state_1[!state_1 %in% state_0], start = 9)# doesn't need the package: prefix
    ns_changes <- ns_1[!ns_1 %in% ns_0]
    #try(lapply(map_chr(ns_changes, devtools::inst), devtools::unload))
    sl_0[order(sl_0)]
    sl_1 <- .packages()
    sl_1[order(sl_1)]
    ns_0[order(ns_0)]
    ns_2 <- loadedNamespaces()
    ns_2[order(ns_2)]
    proc.time() - ptm
    save(all_packages, file = "all_packages.Rdata")
    save(name_list, file = "name_list.Rdata")

    name_table_list <- vector("list", length(name_list))
    for (i in seq_along(name_list)) {
        if (!is.null(name_list[[i]]) &&
            !identical(name_list[[i]], character(0))) {
            #print(i)
            name_table_current <- data.table(package = all_packages[i],
                                             obj_name = name_list[[i]])
            name_table_list[[i]] <- name_table_current
        }
    }
    name_table <- rbindlist(name_table_list)
    # TODO return table
}
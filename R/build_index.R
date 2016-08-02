#' Build name table
#'
#' All object names in all installed packages are scanned with
#' \code{ls(\"package:pkgname\")}.
#'
#' Functions, datasets, operators, symbols, alternative formats like
#' \code{body()<-} are included from \code{ls()}. Package must be loaded and
#' attached first before using \code{ls()}. Thus all installed packages are
#' loaded and attached in the scanning process. Although extra efforts were made
#' to unload packages properly after use, there still will be some left over
#' when the scan finished. It's recommended to build index in a new R session
#' instead of working session with important data, and restart R session after
#' building.
#'
#' @export
#'
build_index <- function(){
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
    setkey(name_table, "obj_name")
    save(name_table, file = "name_table.Rdata")
}
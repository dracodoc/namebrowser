#' List of all installed packages from last scan
#'
#' Saved when \code{pkg_name_changed()} was called.
#' \code{.packages(all.available = TRUE)} was used to check folder under library
#' location path \code{lib.loc}
#'
#' @format A character vector of package names
"pkg_list"

#' data.table of all installed packages from last scan
#'
#' \code{installed.packages()} was used to check DESCRIPTION file for each package
#' folder, more accurate than checking name only.
#'
#' @format A data.table with 3 columns:
#' \describe{
#'  \item{Package}{Package name string}
#'  \item{LibPath}{Package installation folder}
#'  \item{Version}{Version number string}
#' }
"pkg_table"

#' data.table holding all scanned name result
#'
#' \code{ls("package:pkgname")} was used to scan all packages available.
#' Functions, datasets, operators, symbols, alternative formats like
#' \code{body()<-} are included from \code{ls()}.
#'
#' @format A data.table with 2 columns:
#' \describe{
#'  \item{package}{Package name string}
#'  \item{obj_name}{Object name in package}
#' }
#'
"name_table"

#' List of packages that failed to load in last scan
#'
#' While using \code{ls("package:pkgname")} to scan object names inside package
#' need to load and attach package first. Some packages cannot be loaded thus
#' cannot be scanned.
#'
#' Some packages are simply not installed properly thus cannot be loaded.
#'
#' In a big scan session some packages cannot be loadeded because of error
#' 'maximal number of DLLs reached...'. The DLL limit is 100 according to
#' http://stackoverflow.com/questions/24832030/exceeded-maximum-number-of-dlls-in-r
#'
#' The DLL limit was reached because too many packages were loaded in scan but
#' didn't get unloaded, although extra efforts was made to unload properly, some
#' still cannot be unloaded for dependency reason.
#'
#' Running update_name_table(tryError = TRUE) in new R session can scan packages
#' that previously have problems. Each new scan in new R session should cover
#' some packages that failed in last time because of DLL limit error. After
#' several attempts all the left packages are packages have installation
#' problems. There is no need to scan again.
#'
#' For example, there are 400 packages listed in package author's machine, 130
#' have errors in one scan from scratch, after 3 runs of scan error packages, 47
#' packages still left, all have installation problems.
#'
#' @format A character vector of package names
#'
"error_packages"
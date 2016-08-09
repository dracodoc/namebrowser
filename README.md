# namebrowser: RStudio Addin that search name in all installed packages

- Input or select (higlight or place cursor around) a name (including function, dataset etc) in editor or console, press a keyboard shortcut or click addin menu.
- A pop up window will search your input in all installed packages. Search, filter, sort to find the name you want, select the row, then you can choose to either
  + replace the word input with `pkg::name` format. This is good for one time use or interactive running in console. With the package name prefixed, you can search help on name with `F1` in RStudio too.

![search_normal_prefix](/inst/screenshot/search_normal_prefix.gif)

  + or insert `library(pkg)` in previous line, also run `library(pkg)` in console.

![search_regex_lib](/inst/screenshot/search_regex_lib.gif)

- Or you can just browse the table to look what's inside every package, compare packages to have a good overview.

![search_symbol](/inst/screenshot/search_symbol.gif)

## Installation

- Install RStudio newest release version.
- Run following in RStudio console:

        install.packages("devtools") 
        devtools::install_github("dracodoc/namebrowser")

You can assign keyboard shortcut to addins:

- Select Browse Addins from the Addin toolbar button.
![Addin toolbar](/inst/screenshot/addin_toolbar.png)

- Click Keyboard Shortcuts in left bottom.
- Click the Shortcut column for addin row to assign keyboard shortcut.

### Addin updates
#### 2016.08.09  
Removed the function of `update name table` from addin menu to reduce clutter or accidental click. This function is recommended to always be used in a new R session. See below for detailed usage information.

#### 2016.08.08  
Two improvements thanks to feedbacks and suggestions of @daattali . Be sure to check [his great addin of collection of known RStudio addins](https://github.com/daattali/addinslist)!
- The addin require newest version `DT` which is only available in github. Now it will be installed automatically by devtools installer.
- The regular expression search no longer take a separate menu item. There is a check box to switch regular expression mode in the dialog.

## Update name table

The name table shipped with package included about 300 packages so you can start to use immediately. You can update it to match your installed packages. 

- Save your important work. **Start a new R session** through RStudio menu `Session - Restart R` or `Ctrl+Shift+F10`. 
- Run `namebrowser::update_name_table()` in console to remove packages not installed locally from the name table, add packages not included before.

- There could be 3 type of errors in scanning packages, most of them can be solved with a new R session. After scanning, it's almost always better to start a new R session before your work.
  * Packages exist in lib path but cannot be loaded because of installation error. There is nothing can do with the addin itself. You can either uninstall/reinstall them or just leave it as is, it doesn't bother the addin working or updating except some error messages.
  * If too many packages were loaded in scanning, some packages could fail to be loaded because of [maximal number of DLLs reached....](http://stackoverflow.com/questions/24832030/exceeded-maximum-number-of-dlls-in-r).
  The addin have to load a package first to scan names inside, although extra efforts have been made to unload package after scan, there could be still some packages failed to unload because of dependency with other loaded packages. In one scan of several hundreds of packages, the packages failed to unload could exceed the 100 DLL limit, thus some new packages need those DLL cannot be loaded and scanned.
  The scanning process will still update the name table with success results, and save the list of packages that fail to load. You can **start a new R session** (it's a must since the DLL limit has been reached), run `namebrowser::update_name_table(tryError = TRUE)` to process these packages specifically. This time more packages would be scanned successfully, rinse and repeat. It took me 3 runs to scan 400 packages.
  After several runs, all the packages failed to load because of DLL limit error are scanned, but there could be some packages left because of installation problem. 
 * Sometimes there is this error in updaing name table if many packages were scanned without restarting R session first:

        Error in .Call("Crbindlist", l, use.names, fill) : 
          "Crbindlist" not resolved from current namespace (data.table)
 
  It looks to be a [`data.table` bug](https://github.com/Rdatatable/data.table/issues/1467) which can be avoided by restarting a new R session.However our last scan updated the package name list already, even if the name table was not updated because of the bug. Thus just restarting a new R session and updating name table again will not actually update the table.
  In this case you need to **start a new R session**, run `namebrowser::update_name_table(startNew = TRUE)` to build name table from scratch. The help of `?namebrowser::update_name_table` have more details on parameter options.

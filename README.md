# namebrowser
RStudio Addin that scan all installed packages for names, search name to insert `library(pkg)` or `pkg::` prefix

If you knew some function or dataset but not sure which package it is in (sometimes there seem to be many possible candidates), input the name in editor or console, press a keyboard shortcut will bring a pop up window to search all names in all installed packages, with your input as search term. You can further search and browse the table, select the one you want then the addin will insert the package prefix or run `library(pkg) in console automatically. 

![name_search](/inst/screenshot/name_search.gif)

_Note: I used keyboard shortcut to bring up the dialog in the gif recording._

Or you can just browse the table to look what's inside every package, compare packages to have a good overview.

![search_symbol](/inst/screenshot/search_symbol.gif)

## Installation and Usage

- Install RStudio newest release version.
- Run following lines in RStudio console:

        install.packages("devtools") 
        devtools::install_github("dracodoc/namebrowser")

You can assign keyboard shortcut to functions:

- Select Browse Addins from the Addin toolbar button.
- Click Keyboard Shortcuts in left bottom.
- Click the Shortcut column for each row to assign keyboard shortcut.

If you feel you don't need all the menu items registered by this Adddin, you can prevent some to be registered by RStudio. 
- find the package installation folder with `find.package("namebrowser")`.
- edit `rstudio\addins.dcf` under that folder, remove the sections you don't need.
- restart R session.

This way they will not appear in the addin menu, but you can still use the feature by running functions in console directly.

### name browser

You can use the name table shipped with package immediately, input some name in RStudio **source editor** or **console**, click the Addin toolbar button to select `Names - Search name`. 

![Addin toolbar](/inst/screenshot/addin_toolbar.png)

A pop up window will list all the names in the table with your input as search condition.

![pop up window](/inst/screenshot/browser.png)

Note the Addin can pick up the input automatically in these cases, the input don't have to be a complete word:
- Double click in a word to select that word, or select a word manually. Selected text will be the search input.
- When the cursor is in the begining, middle and end of a word, the word will be picked up. For example you are inputing a word but not sure about which package it is in, leave the cursor at the end of the word then bring up the Addin.

You can further modify the global search input, or filter the packages in package search box. After you select a row, either 
- click `Load Package` to run `library(pkg)` in console, insert `library(pkg)` in previous line, replace the name input in source editor with the name selected. With selected packaged loaded and attached, the usual auto completion and help are all available now.
- or click `Insert Package Prefix` button at bottom, just insert the full prefixed object name `pkg::name` to replace the input in source editor. This way you don't need to attach the package, and you still can check the help page for the name.

Of course you can just browsing and searching through the name table to see what's available in certain package.

You can also use the Addin menu `Names - Regex search name` to enable regular expression in search. Note regular expression written in source editor probably cannot be picked up automatically like normal mode, better input them in the pop up window. Unlike normal search, there is no highlight for regular expression matches.

![regex search](/inst/screenshot/regex.png)

### build name table

Since the name table shipped with package only include about 300 packages, you should update it to match the packages installed in your environment. 
- Run `Names - Update name table` to remove name entries not available, add packages not included. Because the updating process may need to load many packages then attempt to unload them, it's strongly recommended to ** always save your import work first, start a new R session** before updating.
- There could be two type of errors in scanning packages:
  * Packages exist in lib path but cannot be loaded because of installation error. 
  * If too many packages were loaded in scanning, some packages could fail to be loaded because of [maximal number of DLLs reached....](http://stackoverflow.com/questions/24832030/exceeded-maximum-number-of-dlls-in-r), the 100 limit is definitely low in our scanning. Extra efforts have been taken to make sure each package should be unloaded after scann, but some packages cannot be unloaded normally because of dependency with other packages.
  
  The scanning process will still update the name table with success results, and save the list of packages that fail to load. You can **start a new R session** (it's a must since the DLL limit has been reached), run `namebrowser::update_name_table(tryError = TRUE)` to process these packages specifically. This time more packages would be scanned successfully, but there could still be some left. Just start a new R session and run `namebrowser::update_name_table(tryError = TRUE)` again. It took 3 runs to process the 400 packages.
    
  After several runs, all the packages that left in the error package list are packages with installation problem. There is nothing can do with the Addin itself. You can either uninstall/reinstall them or just leave it as is, it doesn't bother the Addin working or updating except some error messages.

- Sometimes there is this error in updaing name table if many packages were scanned without restarting R session first:

        Error in .Call("Crbindlist", l, use.names, fill) : 
          "Crbindlist" not resolved from current namespace (data.table)
 
  It looks to be a [`data.table` bug](https://github.com/Rdatatable/data.table/issues/1467) which can be avoided by restarting an new R session. 
  However our last scan updated the package name list already, even if the name table was not updated because of the bug. Thus just restarting an new R session and updating name table again will not actually update the table. In this case you need to restart an new R session, run `namebrowser::update_name_table(startNew = TRUE)` to build name table from scratch. The help page of `namebrowser::update_name_table` have more details on different parameter options available.
  
  

# namebrowser
RStudio Addin that scan all installed packages for names, search name to insert `library(pkg)` or `pkg::` prefix

## Motivation
There are thousands of R packages, sometimes I knew a method or a dataset I want to use but not sure which package it is in, especially when there are several possible candidates. You also need to know the package name before you can search help on that method. R provided `??` search options but that is a full text search, slower than I expected, too many false positives.

RStudio can provide auto completion and help when you input even a partial name, but it also need to know the package first unless it was already loaded and attached. An ideal solution will be a global search mode in RStudio:
  
  - User input some name, press a keyboard shortcut, RStudio search all packages for that name, provide suggestions.
  - User select the package and name wanted, then either load the package by `library(pkg)` or insert the `pkg::` prefix.
  
I submitted the [feature request](https://support.rstudio.com/hc/en-us/community/posts/212206388-automatically-load-packages-like-the-auto-import-in-IntelliJ-IDEA) to RStudio. Then felt this could be good excercise for me to learn about RStudio Addin, I tried to implement it by myself. Because of the Addin UI is limited, this is not as optimal as the RStudio builtin auto complete. I think it could be a proof of concept to test the idea or gather feedback.  
  
When I had a working prototype, I found having a name table of all packages could provide another way to explore packages. For example, you can search and filter by package name, function, dataset or even symbol name (it's difficult to search symbol in usual way). You can have a quick look at what a package provides (it could be quicker than flipping though vignettes), insert the `pkg::`prefix with a name to source editor, then press F1 to look at the help page.

## Installation and Usage

- Install RStudio newest release version.
- Run following lines in RStudio console:

        install.packages("devtools") 
        # the CRAN version DT is not compatible with current code
        devtools::install_github('rstudio/DT')
        devtools::install_github("dracodoc/namebrowser")

You can assign keyboard shortcut to functions:

- Select Browse Addins from the Addin toolbar button.
- Click Keyboard Shortcuts in left bottom.
- Click the Shortcut column for each row to assign keyboard shortcut.

### name browser

You can use the name table shipped with package immediately, input some name in RStudio **source editor** or **console**, click the Addin toolbar button to select `Names - Search name`. 
![addin toolbar](/inst/screenshot/browser.png)

A pop up window will list all the names in the table with your input as search condition.

![pop up window]

Note the Addin can pick up the input automatically in these cases, the input don't have to be a complete word:
- Double click in a word to select that word, or select a word manually. Selected text will be the search input.
- When the cursor is in the begining, middle and end of a word, the word will be picked up. For example you are inputing a word but not sure about which package it is in, leave the cursor at the end of the word then bring up the Addin.

You can further modify the global search input, or filter the packages in package search box. After you select a name wanted, either 
- click `Load Package` to run `library(pkg)` in console, insert `library(pkg)` in previous line, replace the name input in source editor with the name selected. With selected packaged loaded and attached, the usual auto completion and help are all available now.
- or click `Insert Package Prefix` button at bottom, just insert the full prefixed object name `pkg::name` to replace the input in source editor. This way you don't need to attach the package, and you still can check the help page for the name.

Of course you can just browsing and searching through the name table to see what's available in certain package.

You can also use the Addin menu `Names - Regex search name` to enable regular expression in search. Note regular expression written in source editor probably cannot be picked up automatically like normal mode, better input them in the pop up window. Unlike normal search, there is no highlight for regular expression matches.

### build name table

Since the name table shipped with package only include about 300 packages, you should update it to match the packages installed in your environment. 
- Run `Names - Update name table` to remove name entries not available, add packages not included. Because the updating process may need to load many packages then attempt to unload them, it's strongly recommended to **save your import work first, start a new R session** for updating.
- There could be two type of errors in scanning packages:
  * Packages exist in lib path but cannot be loaded because of installation error. 
  * If too many packages were loaded in scanning, some packages could fail to be loaded because of [maximal number of DLLs reached....](http://stackoverflow.com/questions/24832030/exceeded-maximum-number-of-dlls-in-r), the 100 limit is definitely low in our scanning. Extra efforts have been taken to make sure each package should be unloaded after scann, but some packages cannot be unloaded normally because of dependency with other packages.
  
  The scanning process will still update the name table with success results, and save the list of packages that fail to load. You can **start a new R session** (it's a must since the DLL limit has been reached), run `update_name_table(tryError = TRUE)` to process these packages specifically. This time more packages would be scanned successfully, but there could still be some left. Just start a new R session and run `update_name_table(tryError = TRUE)` again. It took 3 runs to process the 400 packages.
    
  After several runs, all the packages that left in the error package list are packages with installation problem. There is nothing can do with the Addin itself. You can either uninstall/reinstall them or just leave it as is, it doesn't bother the Addin working or updating except some error messages.


 
  
  
  

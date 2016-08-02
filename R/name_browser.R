#' Seach name in name table
#'
#' With text selected or name around cursor as initial search term, find the
#' package and object name you need.
#'
#' \code{Load Package} button run \code{library(package)} in console, insert
#' \code{library(package)} before current line, replace text selected or name
#' around cursor with selected object name. \code{Insert Package Prefix} button
#' replace text selected or name around cursor with selected object name
#' prefixed by object name.
#'
#' @param search_regex Whether to use regular expression in search. Dialog title
#'   will be updated to show regex mode. Regex matchs may not be highlighted.
#'
#' @export
#'
searchnames <- function(search_regex = FALSE) {
    # get input. we need many variables later, abstract into functions bring more obstacles.
    context <- rstudioapi::getSourceEditorContext()
    selection_start <- context$selection[[1]]$range$start # named vector with "row" "column"
    selection_end <- context$selection[[1]]$range$end
    current_line <- context$content[selection_start["row"]]
    # start and end position of match is same since we are matching first single non space character
    indent <- str_match(current_line, "^\\s*")
    current_line_range <- context$selection[[1]]$range
    current_line_range$start["column"] <- 1
    current_line_range$end["column"] <- nchar(current_line) + 1 # full range end at length+1
    if (any(selection_start != selection_end)) { # text selected
        input_name <- context$selection[[1]]$text
        left_edge <- selection_start["column"] - 1
        right_edge <- selection_end["column"]
    } else {# no text select, infer input name
        # search left side of cursor for last partial word
        left_side <- str_sub(current_line, start = 1, end = selection_start["column"] - 1)
        first_word_char_till_end <- "[^\\w](\\w*)$"
        left_partial_word <- str_match(left_side, first_word_char_till_end)[2]
        left_edge <- str_locate(left_side, first_word_char_till_end)[1]
        # right side for first partial word
        right_side <- str_sub(current_line,
                              start = selection_start["column"],
                              end = nchar(current_line))
        start_till_last_word_char <- "^\\w*"
        right_partial_word <- str_extract(right_side, start_till_last_word_char)
        right_edge <- str_locate(right_side, start_till_last_word_char)[2] +
            selection_end["column"] # right side need index offset from cursor
        # cover input with cursor in end of word, and cursor inside a word.
        input_name <- str_c(left_partial_word, right_partial_word)
    }

    title <- ifelse(search_regex,
                    "Regex search name in all packages",
                    "Search name in all packages")
    ui <- miniPage(
        gadgetTitleBar(title,
                       right = miniTitleBarButton("load_package",
                                                  "Load Package",
                                                  primary = TRUE)),
        miniContentPanel(DT::dataTableOutput("table")),
        miniButtonBlock(actionButton("insert_prefix", strong("Insert Package Prefix")))
    )

    server <- function(input, output, session) {
        # Define reactive expressions, outputs, etc.
        # TODO regex by paramter, this function with default paramter, another helper call with non-default paramter.
        output$table <- DT::renderDataTable(name_table,
                                            server = TRUE,
                                            selection = "single",
                                            filter = 'top',
                                            options = list(
                                                searchHighlight = TRUE,
                                                search = list(search = input_name,
                                                              regex = search_regex
                                                ),
                                                pageLength = 7
                                            )
        )
        # insert library line, run in console, replace current line
        observeEvent(input$load_package, {
            if (!is.null(input$table_rows_selected)) {
                row_selected <- input$table_rows_selected
                lib_line <- str_c("library(", name_table[row_selected, "package"], ")")
                new_line <- str_c(str_sub(current_line, 1, left_edge),
                                  name_table[row_selected, "obj_name"],
                                  str_sub(current_line, right_edge,
                                          nchar(current_line)))
                rstudioapi::sendToConsole(lib_line, execute = TRUE)
                new_2_lines <- str_c(indent, lib_line, "\n", new_line)
                rstudioapi::insertText(current_line_range, new_2_lines, id = context$id)
                stopApp()
            }
        })
        # replace current line input name with full prefixed name
        observeEvent(input$insert_prefix, {
            if (!is.null(input$table_rows_selected)) {
                row_selected <- input$table_rows_selected
                prefixed_name <- str_c(name_table[row_selected, "package"],
                                       "::",
                                       name_table[row_selected, "obj_name"])
                new_line <- str_c(str_sub(current_line, 1, left_edge),
                                  prefixed_name,
                                  str_sub(current_line, right_edge,
                                          nchar(current_line)))
                rstudioapi::insertText(current_line_range, new_line, id = context$id)
                stopApp()
            }
        })
    }
    runGadget(ui, server, viewer = dialogViewer("Name browser"))
}

searchnames_regex <- function(){
    searchnames(search_regex = TRUE)
}
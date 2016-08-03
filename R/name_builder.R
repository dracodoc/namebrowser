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
#' @param search_regex Whether to use regular expression in search. Default
#'   FALSE to use normal search. Dialog title will be updated to show regex
#'   mode.
#'
#' @export
#'
searchname <- function(search_regex = FALSE) {
  data("name_table", envir = environment())
  # get input ----------
  context <- rstudioapi::getActiveDocumentContext()
  selection_start <- context$selection[[1]]$range$start
  selection_end <- context$selection[[1]]$range$end
  current_line <- context$content[selection_start["row"]]
  indent <- stringr::str_match(current_line, "^\\s*")
  current_line_range <- context$selection[[1]]$range
  current_line_range$start["column"] <- 1
  current_line_range$end["column"] <- nchar(current_line) + 1 # full range end at length+1
  if (any(selection_start != selection_end)) { # text selected
    input_name <- context$selection[[1]]$text
    # range to be replaced
    left_edge <- selection_start["column"] - 1
    right_edge <- selection_end["column"]
  } else {# no text select, infer input name
    # search left side of cursor for last partial word
    left_side <- stringr::str_sub(current_line,
                                  start = 1,
                                  end = selection_start["column"] - 1)
    first_word_char_till_end <- "[^\\w](\\w*)$"
    left_partial_word <- stringr::str_match(left_side,
                                        first_word_char_till_end)[2]
    left_edge <- stringr::str_locate(left_side,
                                     first_word_char_till_end)[1]
    # right side for first partial word
    right_side <- stringr::str_sub(current_line,
                          start = selection_start["column"],
                          end = nchar(current_line))
    start_till_last_word_char <- "^\\w*"
    right_partial_word <- stringr::str_extract(right_side,
                                              start_till_last_word_char)
    right_edge <- stringr::str_locate(right_side,
                                      start_till_last_word_char)[2] +
                    selection_end["column"] # index offset from cursor
    input_name <- stringr::str_c(left_partial_word, right_partial_word)
  }
  # build UI ------
  title <- ifelse(search_regex,
                  "Regex search name in all packages",
                  "Search name in all packages")
  ui <- miniUI::miniPage(
          miniUI::gadgetTitleBar(title,
              right = miniUI::miniTitleBarButton("load_package",
                                 "Load Package", primary = TRUE)),
          miniUI::miniContentPanel(DT::dataTableOutput("table")),
          miniUI::miniButtonBlock(shiny::actionButton("insert_prefix",
                                  shiny::strong("Insert Package Prefix")))
        )
  # build server -----
  server <- function(input, output, session) {
    # Define reactive expressions, outputs, etc.
    output$table <- DT::renderDataTable(name_table,
                                        server = TRUE,
                                        selection = "single",
                                        filter = 'top',
                                        options = list(
                                          searchHighlight = TRUE,
                                          search = list(search = input_name,
                                                        regex = search_regex),
                                          pageLength = 7
                                        )
    )
    # insert library line, run library in console, replace current line
    shiny::observeEvent(input$load_package, {
      if (!is.null(input$table_rows_selected)) {
        row_selected <- input$table_rows_selected
        lib_line <- stringr::str_c("library(",
                                   name_table[row_selected, "package"], ")")
        new_line <- stringr::str_c(
                        stringr::str_sub(current_line, 1, left_edge),
                        name_table[row_selected, "obj_name"],
                        stringr::str_sub(current_line, right_edge,
                                  nchar(current_line)))
        rstudioapi::sendToConsole(lib_line, execute = TRUE)
        new_2_lines <- stringr::str_c(indent, lib_line, "\n", new_line)
        rstudioapi::insertText(current_line_range, new_2_lines, id = context$id)
        shiny::stopApp()
      }
    })
    # replace current line input name with full prefixed name
    shiny::observeEvent(input$insert_prefix, {
      if (!is.null(input$table_rows_selected)) {
        row_selected <- input$table_rows_selected
        prefixed_name <- stringr::str_c(
                             name_table[row_selected, "package"],
                             "::",
                             name_table[row_selected, "obj_name"])
        new_line <- stringr::str_c(
                        stringr::str_sub(current_line, 1, left_edge),
                          prefixed_name,
                          stringr::str_sub(current_line, right_edge,
                                  nchar(current_line)))
        rstudioapi::insertText(current_line_range, new_line, id = context$id)
        shiny::stopApp()
      }
    })
  }
  shiny::runGadget(ui, server, viewer = shiny::dialogViewer("Name browser"))
}

#' Regex seach name in name table
#'
#' Helper function to call \code{searchname} with regex enabled.
#'
#' Need this because RStudio Addin currently don't support function with
#' parameters
#' @export
#'
searchname_regex <- function(){
  searchname(search_regex = TRUE)
}
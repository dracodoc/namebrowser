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
#' @import data.table stringr miniUI
#' @export
#'
searchname <- function() {
  data("name_table", package = "namebrowser", envir = environment())
  # get input ----------
  context <- rstudioapi::getActiveDocumentContext()
  selection_start <- context$selection[[1]]$range$start
  selection_end <- context$selection[[1]]$range$end
  current_line <- context$content[selection_start["row"]]
  # getting indent and current line full range no matter selection mode ----
  indent <- str_match(current_line, "^\\s*")
  current_line_range <- context$selection[[1]]$range
  current_line_range$start["column"] <- 1
  current_line_range$end["column"] <- nchar(current_line) + 1 # full range end at length + 1
  if (any(selection_start != selection_end)) { # text selected
    input_name <- context$selection[[1]]$text
    # range to be replaced
    left_edge <- selection_start["column"] - 1
    right_edge <- selection_end["column"]
  } else {# no text select, infer input name
    # search left side of cursor for last partial word
    left_side <- str_sub(current_line, start = 1, end = selection_start["column"] - 1)
    word_by_end <- "\\w*$" # "[^\\w]*(\\w*)$" with $ anchor, actually search from right side end
    left_partial_word <- str_match(left_side, word_by_end)[1]
    left_edge <- str_locate(left_side, word_by_end)[1] - 1 # need -1 now when regex pattern changed. previous pattern need a leading nonword character, missed when word in line start
    # right side for first partial word
    right_side <- str_sub(current_line, start = selection_start["column"],
                          end = nchar(current_line))
    starting_word <- "^\\w*" # symmetrical with left side
    right_partial_word <- str_extract(right_side, starting_word)
    right_edge <- str_locate(right_side, starting_word)[2] +
                  selection_end["column"] # index offset from cursor
    input_name <- str_c(NA_to_empty(left_partial_word),
                        NA_to_empty(right_partial_word))
  }
  # build UI ------
  ui <- miniPage(
    gadgetTitleBar("Search name in all packages",
                   right = miniTitleBarButton("load_package",
                                              "Load Package", primary = TRUE)),
    miniContentPanel(DT::dataTableOutput("table", height = "100%")),
    miniButtonBlock(shiny::checkboxInput("regex_mode",
                      shiny::strong("Regular Expression Search"),
                      value = FALSE),
      shiny::actionButton("insert_prefix",
                          shiny::strong("Insert Package Prefix")))
  )
  # build server -----
  server <- function(input, output, session) {
    init_table <- function(regexmode){
      DT::datatable(name_table, selection = "single", filter = 'top',
                    options = list(searchHighlight = TRUE,
                                   search = list(search = input_name,
                                                 regex = regexmode),
                                   pageLength = 7),
                    callback = DT::JS("$(table.table().container()).find('input').first().focus();"))
    }
    output$table <- DT::renderDataTable(init_table(regexmode = FALSE),
                                        server = TRUE)
    shiny::observeEvent(input$regex_mode, {
      output$table <- DT::renderDataTable(
        init_table(regexmode = input$regex_mode), server = TRUE)
    })
    # preselect first row after search update
    shiny::observeEvent(input$table_search, {
      current_1st <- input$table_rows_current[1]
      proxy = DT::dataTableProxy('table')
      DT::selectRows(proxy, current_1st)
    })

    # insert library line, run library in console, replace current line
    shiny::observeEvent(input$load_package, {
      if (!is.null(input$table_rows_selected)) {
        row_selected <- input$table_rows_selected
        lib_line <- str_c("library(", name_table[row_selected, package], ")")
        new_line <- str_c(str_sub(current_line, 1, left_edge),
                          name_table[row_selected, obj_name],
                          str_sub(current_line, right_edge,
                                  nchar(current_line)))
        rstudioapi::sendToConsole(lib_line, execute = TRUE)
        new_2_lines <- str_c(indent, lib_line, "\n", new_line)
        rstudioapi::insertText(current_line_range, new_2_lines, id = context$id)
        shiny::stopApp()
      }
    })
    # replace current line input name with full prefixed name
    shiny::observeEvent(input$insert_prefix, {
      if (!is.null(input$table_rows_selected)) {
        row_selected <- input$table_rows_selected
        prefixed_name <- str_c(name_table[row_selected, package], "::",
                               name_table[row_selected, obj_name])
        new_line <- str_c(str_sub(current_line, 1, left_edge), prefixed_name,
                          str_sub(current_line, right_edge, nchar(current_line)))
        rstudioapi::insertText(current_line_range, new_line, id = context$id)
        shiny::stopApp()
      }
    })
  }
  shiny::runGadget(ui, server, viewer = shiny::dialogViewer("Name browser",
                                                            height = 650))
}

#' Convert NAs to ""
#'
#' In concatnating strings, NAs would cause the result to be NA.
#'
NA_to_empty <- function(s){
  ifelse(is.na(s), "", s)
}

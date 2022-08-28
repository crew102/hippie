.invoke_view <- function() {
  context <- rstudioapi::getSourceEditorContext()
  selection <- rstudioapi::primary_selection(context$selection)
  cursor_line <- selection$range$start[[1]]
  cursor_col <- selection$range$start[[2]]

  src <- paste0(context$contents, collapse = "\n")
  prsd_src <- parse(text = src, keep.source = TRUE)
  prsd_data <- utils::getParseData(prsd_src, includeText = TRUE)
  expr <- prsd_data[prsd_data$token == "expr", ]

  # Here comes the ad hoc logic to ID the relevant expression
  left_of_cursor <- cursor_line == expr$line2 & cursor_col >= expr$col2
  above_cursor <- cursor_line > expr$line2
  prior_to_cursor <- expr[left_of_cursor | above_cursor, ]
  pipe_expr <- prior_to_cursor[grepl("%>%|\\|>", prior_to_cursor$text), ]

  if (nrow(pipe_expr) == 0) return()
  chosen_expr <- pipe_expr[pipe_expr$id == max(pipe_expr$id), "text"]
  to_eval <- paste0("View(", chosen_expr, ")")

  if (getOption("hippie.pipe_to_console", default = TRUE)) {
    rstudioapi::sendToConsole(to_eval, focus = FALSE)
  } else {
    eval(parse(text = to_eval))
  }
}

#' Invoke `View()` on a piped expression
#'
#' This function is meant to be called as a shortcut. It will look for the
#' left-nearest expression that contains either the magrittr or built in pipe
#' operator (`%>%` or `|>`), wrap it in a call to `View()`, then evaluate the
#' result. By default it'll send the code to the console and evaluate it from
#' there, so that it's available in your execution history. To evaluate the code
#' straight away instead of sending it to the console first, set
#' `option(hippie.pipe_to_console = FALSE)`.
#'
#' @return Nothing. Code is either sent to your console for evaluation or
#' evaluated straight away.
#' @examples
#' \dontrun{
#' # Not intended to be called directly. Rather, bind to a keyboard shortcut.
#' invoke_view()
#' }
#' @export
invoke_view <- function() {
  try(.invoke_view(), silent = TRUE)
}

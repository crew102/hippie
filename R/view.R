invoke_view_ <- function() {
  context <- rstudioapi::getSourceEditorContext()
  selection <- rstudioapi::primary_selection(context$selection)
  cursor_line <- selection$range$start[[1]]
  cursor_col <- selection$range$start[[2]]

  src <- paste0(context$contents, collapse = "\n")
  prsd_src <- parse(text = src, keep.source = TRUE)
  prsd_data <- utils::getParseData(prsd_src, includeText = TRUE)
  expr <- prsd_data[prsd_data$token == "expr", ]

  # Here comes the adhoc logic to ID the relevant expression
  left_of_cursor <- cursor_line == expr$line2 & cursor_col >= expr$col2
  above_cursor <- cursor_line > expr$line2
  prior_to_cursor <- expr[left_of_cursor | above_cursor, ]
  pipe_expr <- prior_to_cursor[grepl("%>%", prior_to_cursor$text), ]
  if (nrow(pipe_expr) == 0) return()
  chosen_expr <- pipe_expr[pipe_expr$id == max(pipe_expr$id), "text"]
  to_eval <- paste0("View(", chosen_expr, ")")

  if (getOption("hippie.pipe_to_console", default = "true") == "true") {
    rstudioapi::sendToConsole(to_eval, focus = FALSE)
  } else {
    eval(parse(text = to_eval))
  }
}

#' @export
invoke_view <- function() {
  try(invoke_view_(), silent = TRUE)
}

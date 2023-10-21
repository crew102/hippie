#' @export
style_forward_assignment_selection <- function() {
  ct <- rstudioapi::getSourceEditorContext()
  prm <- rstudioapi::primary_selection(ct)
  forward_as <- any(grepl("->", prm$text))
  long_line <- any(nchar(prm$text) >= 80)
  if (forward_as || long_line) {
    prsd <- parse(text = prm$text)
    dprs <- sapply(
      as.list(prsd),
      function(x) paste0(deparse(x), collapse = "\n")
    )
    dprs <- paste0(dprs, collapse = "\n")
    formatted <- paste0(styler::style_text(dprs), collapse = "\n")
    to_insert <- paste0(formatted, collapse = "\n")
    rstudioapi::modifyRange(prm$range, to_insert, id = ct$id)
  } else {
    styler:::style_selection()
  }
}

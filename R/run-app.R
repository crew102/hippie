#' @export
run_app <- function() {
  rstudioapi::sendToConsole(code = "shiny::runApp('app')", execute = TRUE)
}

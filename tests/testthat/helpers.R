expect_hippie_match <- function(cursor_posish, expected_match, code = NULL,
                                envir = parent.frame()) {
  skip_if_not(rstudioapi::isAvailable())
  fixture_file <- test_path('src-fixture.R')
  tmp_file <- fs::file_temp()

  suppressMessages(
    withr::defer_parent(try({
      rstudioapi::documentClose(tmp_file_id, save = FALSE)
      fs::file_delete(tmp_file)
    }))
  )

  fs::file_copy(fixture_file, tmp_file)
  rstudioapi::navigateToFile(tmp_file)
  Sys.sleep(1)
  tmp_content <- rstudioapi::getSourceEditorContext()

  tmp_file_id <- tmp_content$id
  rstudioapi::setCursorPosition(cursor_posish , tmp_file_id)

  code

  src_post_hippie <- rstudioapi::getSourceEditorContext()
  matched_token <- src_post_hippie$selection[[1]]$text

  expect_identical(matched_token, expected_match)
  withr::deferred_run(envir = envir)
}

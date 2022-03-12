expect_hippie_matches_across_modes <- function(cursor_posish,
                                               expected_match,
                                               sequence,
                                               mode,
                                               envir = parent.frame()) {

  skip_if_not(rstudioapi::isAvailable())
  withr::local_options(list("hippie.mode" = mode))
  fixture_file <- test_path("src-fixture.R")
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
  rstudioapi::setCursorPosition(cursor_posish, tmp_file_id)

  for (direction in sequence) {
    if (direction == "down") hippie_down() else hippie_up()
    Sys.sleep(.2)
  }

  src_post_hippie <- rstudioapi::getSourceEditorContext()

  if (mode == "select") {
    matched_token <- src_post_hippie$selection[[1]]$text
  } else {
    matched_token <- extract_nearest_token(src_post_hippie)
  }

  expect_identical(matched_token, expected_match)
  withr::deferred_run(envir = envir)
}

expect_hippie_match <- function(cursor_posish, expected_match,
                                sequence, modes = c("select", "insert")) {
  for (mode in modes) {
    expect_hippie_matches_across_modes(
      cursor_posish = cursor_posish,
      expected_match = expected_match,
      sequence = sequence,
      mode = mode,
      envir = parent.frame()
    )
  }
}

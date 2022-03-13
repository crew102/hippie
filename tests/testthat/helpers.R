expect_hippie_match <- function(cursor_posish,
                                expected_match,
                                sequence,
                                modes = c("select", "insert"),
                                fixture_file = "r-source.R") {
  for (mode in modes) {
    expect_hippie_match_single_mode(
      cursor_posish = cursor_posish,
      expected_match = expected_match,
      sequence = sequence,
      mode = mode,
      fixture_file = fixture_file,
      envir = parent.frame()
    )
  }
}

expect_hippie_match_single_mode <- function(cursor_posish,
                                            expected_match,
                                            sequence,
                                            mode,
                                            fixture_file,
                                            envir = parent.frame()) {

  skip_if_not(rstudioapi::isAvailable())
  withr::local_options(list("hippie.mode" = mode))
  fixture <- test_path("fixtures", fixture_file)
  tmp_file <- fs::file_temp(ext = gsub(".*(\\..*)", "\\1", fixture_file))

  suppressMessages(
    withr::defer_parent(try({
      rstudioapi::documentClose(tmp_file_id, save = FALSE)
      fs::file_delete(tmp_file)
    }))
  )

  fs::file_copy(fixture, tmp_file)
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

# These tests have to be run interactively in RStudio by first calling
# devtools::load_all("."), then sourcing this file.

test_that("Targets within string literals match R symbols", {
  expect_hippie_match(c(5, 11), "matching_token", sequence = "up")
  expect_hippie_match(c(5, 11), "matching_token", sequence = "up")
})

test_that("Targets within assigned string literals work", {
  expect_hippie_match(c(7, 18), "matching_", sequence = "up")
  expect_hippie_match(c(7, 18), "matc", sequence = c("up", "up"))
  expect_hippie_match(c(7, 18), "match", sequence = "down")
})

test_that("Candidate matches are recycled/iterated through correctly", {
  expect_hippie_match(c(7, 18), "match", sequence = rep("up", 5))
  expect_hippie_match(c(7, 18), "matching", sequence = c("up", "down", "down"))
})

test_that("Targets within strings match tokens within other literals", {
  expect_hippie_match(c(9, 16), "matching_", sequence = "up")
})

test_that("Numeric targets work", {
  expect_hippie_match(c(13, 2), "19847", sequence = "up")
})

test_that("Targets within strings with escape chars work", {
  expect_hippie_match(c(15, 33), "matching_", sequence = c("up", "up"))
})

test_that("No matching candidate matches means no text is selected", {
  expect_hippie_match(c(17, 20), "", sequence = "up", modes = "select")
})

test_that("No target token means no text is selected", {
  expect_hippie_match(c(26, 3), "", sequence = "up")
})

test_that("Candidate matches that are R symbols with a . in them match fine", {
  expect_hippie_match(c(20, 5), "blah.blah", sequence = "up")
})

test_that("Targets within comments match to strings", {
  expect_hippie_match(c(22, 17), "matching_", sequence = "up")
})

test_that("Intra-line matching works", {
  expect_hippie_match(c(24, 19), "funny_object", sequence = "up")
  expect_hippie_match(c(25, 3), "funny", sequence = "down")
})

test_that("Phrase matching while cursor within string works", {
  expect_hippie_match(
    c(28, 6), "Luke Skywalker", sequence = "down", modes = "select"
  )
})

test_that("Non-parsable lines are not a problem", {
  expect_hippie_match(c(36, 22), "matching", sequence = "up")
})

test_that("Non-r source files work", {
  expect_hippie_match(
    c(20, 3), "formatting", sequence = rep("up", 3),
    fixture_file = "rmd-source.Rmd"
  )
})

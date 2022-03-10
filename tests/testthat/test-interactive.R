# These tests have to be run interactively in RStudio by sourcing this file.

context("Interactive tests")

test_that("Target chars within string literal work", {
  expect_hippie_match(c(5, 11), "matching_token", code = hippie_up())
  expect_hippie_match(c(5, 11), "matching_token", code = hippie_down())
})

test_that("Target chars within assigned string literal work", {
  expect_hippie_match(c(7, 18), "matching_", code = hippie_up())
  expect_hippie_match(c(7, 18), "matc", code = {
    hippie_up()
    hippie_up()
  })
  expect_hippie_match(c(7, 18), "match", code = hippie_down())
})

test_that("Candidate matches are recycled/iterated through correctly", {
  expect_hippie_match(c(7, 18), "match", code = {
    hippie_up()
    hippie_up()
    hippie_up()
    hippie_up()
    hippie_up()
  })
  expect_hippie_match(c(7, 18), "matching", code = {
    hippie_up()
    hippie_down()
    hippie_down()
  })
})

test_that("Target chars within substring work", {
  expect_hippie_match(c(9, 16), "matching_", code = hippie_up())
})

test_that("Numeric target works", {
  expect_hippie_match(c(13, 2), "19847", code = hippie_up())
})

test_that("Targets within strings with escape chars works", {
  expect_hippie_match(c(15, 33), "matching_", code = {
    hippie_up()
    hippie_up()
  })
})

test_that("No matching candidate matches means no text is selected", {
  expect_hippie_match(c(17, 20), "", code = hippie_up())
})

test_that("No target token means no text is selected", {
  expect_hippie_match(c(26, 3), "", code = hippie_up())
})

test_that("Candidate matches extend to tokens with . in them", {
  expect_hippie_match(c(20, 5), "blah.blah", code = hippie_up())
})

test_that("Target chars inside comments work", {
  expect_hippie_match(c(22, 17), "matching_", code = hippie_up())
})

test_that("Intra-line matching works", {
  expect_hippie_match(c(24, 19), "funny_object", code = hippie_up())
  expect_hippie_match(c(25, 3), "funny", code = hippie_down())
})

test_that("Non-parsable lines are not a problem", {
  expect_hippie_match(c(27, 22), "matching", code = hippie_up())
})

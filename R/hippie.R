.hippie <- new.env(parent = emptyenv())

TOKENIZE_ON <- "[^[:alnum:]_.]"

#' @export
hippie_up <- function() {
  try(hippie_up_down(direction = "up"))
}

#' @export
hippie_down <- function() {
  try(hippie_up_down(direction = "down"))
}

init_flag <- getOption("hippie.first_invoke_flag", "token_len") # select is another option
target_token_max_len <- getOption("hippie.target_token_max_len", 3)

parse_target_token <- function(editor_context) {
  selection <- rstudioapi::primary_selection(editor_context)
  cursor <- id_cursor_position(selection)
  src <- editor_context$contents
  cursor_line_src <- src[[cursor$row]]
  substr_left_of_cursor <- substr(cursor_line_src, 1, cursor$column - 1)
  tokens <- unlist(strsplit(substr_left_of_cursor, TOKENIZE_ON))
  if (length(tokens) == 0 || is.null(tokens)) return("")
  tokens[length(tokens)]
}

hippie_up_down <- function(direction) {
  editor_context <- rstudioapi::getSourceEditorContext()
  selection <- rstudioapi::primary_selection(editor_context)

  if (init_flag == "token_len") {
    target_token <- parse_target_token(editor_context)
    if (nchar(target_token) <= target_token_max_len) {
      is_1st_invoke <- TRUE
      .hippie$target_token <- target_token
    } else {
      is_1st_invoke <- FALSE
    }
  } else {
    is_1st_invoke <- is_first_invocation(selection)
  }

  if (is_1st_invoke)
    init_state(editor_context)

  # Bail if no good match target or candidate matches
  if (is.null(.hippie$target_token)) return()
  if (is.null(.hippie$num_candidates)) return()
  if (.hippie$target_token == "") return()
  if (.hippie$num_candidates == 0) return()

  # Direction doesn't matter ---------------------
  if (.hippie$num_candidates == 1) {
    candidate <- .hippie$all_candidates
  # Direction = Up ---------------------
  } else if (direction == "up") {
    if (is_1st_invoke) {
      .hippie$candidate_index <- .hippie$num_up_candidates
    } else {
      .hippie$candidate_index <- .hippie$candidate_index - 1
    }
    if (.hippie$candidate_index <= 0) {
      # Cycling through to bottom of file
      .hippie$candidate_index <- .hippie$num_candidates
    }
    candidate <- .hippie$all_candidates[.hippie$candidate_index]
  # Direction = Down ---------------------
  } else {
    if (is_1st_invoke) {
      .hippie$candidate_index <- .hippie$num_up_candidates + 1
    } else {
      .hippie$candidate_index <- .hippie$candidate_index + 1
    }
    if (.hippie$candidate_index > .hippie$num_candidates) {
      # Cycling through to top of file
      .hippie$candidate_index <- 1
    }
    candidate <- .hippie$all_candidates[.hippie$candidate_index]
  }

  if (init_flag == "token_len") {
    rstudioapi::setSelectionRanges(.hippie$target_token_range, id = .hippie$doc_id)
    rstudioapi::insertText(
      text = candidate,
      id = .hippie$doc_id
    )

    cur_context <- rstudioapi::getSourceEditorContext()
    .hippie$target_token_range <- cur_context$selection[[1]]$range
    rstudioapi::setCursorPosition(.hippie$target_token_range$end, id = .hippie$doc_id)
  } else {
    rstudioapi::insertText(text = candidate, id = .hippie$doc_id)
  }
  invisible()
}

is_first_invocation <- function(selection) {
  selection[["text"]] == ""
}

init_state <- function(editor_context) {
  selection <- rstudioapi::primary_selection(editor_context)
  cursor <- id_cursor_position(selection)
  src <- editor_context$contents
  cursor_line_src <- src[[cursor$row]]

  # Tokens above cursor ---------------------------
  if (cursor$row == 1) {
    lines_above_cursor <- NULL
  } else {
    lines_above_cursor <- src[1:(cursor$row - 1)]
  }
  substr_left_of_cursor <- substr(cursor_line_src, 1, cursor$column - 1)
  up_src <- paste0(
    paste0(lines_above_cursor, collapse = "\n"),
    "\n",
    substr_left_of_cursor
  )
  up_tokens <- parse_candidate_tokens(up_src)
  if (init_flag != "token_len") {
    .hippie$target_token <- up_tokens[length(up_tokens)]
  }
  up_candidates <- find_unique_matches(
    up_tokens, .hippie$target_token, from_last = TRUE
  )

  # Tokens below cursor ---------------------------
  num_src_lines <- length(src)
  if (cursor$row == num_src_lines) {
    lines_below_cursor <- NULL
  } else {
    lines_below_cursor <- src[(cursor$row + 1):num_src_lines]
  }
  line_len <- nchar(cursor_line_src)
  substr_right_of_cursor <- substr(cursor_line_src, cursor$column, line_len)
  down_src <- paste0(
    substr_right_of_cursor,
    "\n",
    paste0(lines_below_cursor, collapse = "\n")
  )
  down_tokens <- parse_candidate_tokens(down_src)
  down_candidates <- find_unique_matches(
    down_tokens, .hippie$target_token, from_last = FALSE
  )

  # Note that if a candidate token appears both above and below the cursor,
  # the user would be shown it twice when iterating through.
  .hippie$all_candidates <- c(up_candidates, down_candidates)
  .hippie$num_candidates <- length(.hippie$all_candidates)
  .hippie$num_up_candidates <- length(up_candidates)
  .hippie$doc_id <- editor_context$id

  if (.hippie$num_candidates == 0 || .hippie$target_token == "")
    return()

  .hippie$target_token_range <- rstudioapi::document_range(
    start = c(cursor$row, cursor$column),
    end = c(cursor$row, cursor$column - nchar(.hippie$target_token, type = "width"))
  )

  if (init_flag != "token_len") {
    rstudioapi::setSelectionRanges(.hippie$target_token_range, id = .hippie$doc_id)
  }
}

id_cursor_position <- function(selection) {
  rng <- selection[["range"]]
  start <- rng[["start"]]
  end <- rng[["end"]]
  stopifnot(all(start == end))
  list(row = start[["row"]], column = end[["column"]])
}

parse_candidate_tokens <- function(src_text) {
  tokens <- sourcetools::tokenize_string(src_text)
  relevant_token_types <- c(
    "string", "symbol", "keyword", "comment", "number", "invalid"
  )
  relevant_tokens <- tokens[tokens$type %in% relevant_token_types, ]
  # Remove leading and trailing ' and "
  relevant_tokens$value <- ifelse(
    relevant_tokens$type == "string",
    gsub("^(\"|')|(\"|')$", "", relevant_tokens$value),
    relevant_tokens$value
  )
  relevant_tokens$value <- trimws(relevant_tokens$value, "both")

  split_str_tokens <- function(value, type) {
    if (type == "string") {
      # We put the full string above the tokens found within the string
      # when ordering match candidates
      c(value, unlist(strsplit(value, TOKENIZE_ON)))
    } else if (type %in% c("comment", "invalid")) {
      unlist(strsplit(value, TOKENIZE_ON))
    } else {
      value
    }
  }

  candidate_tokens <- unlist(mapply(
    FUN = split_str_tokens,
    value = relevant_tokens$value,
    type = relevant_tokens$type,
    USE.NAMES = FALSE
  ))

  if (init_flag == "token_len") {
    candidate_tokens[nchar(candidate_tokens) > target_token_max_len]
  } else {
    candidate_tokens
  }
}

find_unique_matches <- function(token_vec,
                                target_token,
                                from_last = TRUE) {
  # Not sure if this is the fastest way to do this (i.e., first filter empties,
  # then apply regex). May be faster to just apply the regex before filtering
  # empties?
  non_empties <- token_vec[token_vec != ""]
  if (is.null(non_empties))
    return(NULL)
  matches <- non_empties[startsWith(toupper(non_empties), toupper(target_token))]
  unique_matches <- unique(matches, fromLast = from_last)
  unique_matches[unique_matches != target_token]
}

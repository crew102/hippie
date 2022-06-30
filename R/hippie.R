.hippie <- new.env(parent = emptyenv())

SPLIT_SYMBOL_ON <- "[^[:alnum:]_.]"
SPLIT_STR_ON <- "[^[:alnum:]_]"

#' @rdname hippie-invoke
#' @export
hippie_up <- function() {
  try(hippie_up_down(direction = "up"), silent = TRUE)
}

#' @rdname hippie-invoke
#' @export
hippie_down <- function() {
  try(hippie_up_down(direction = "down"), silent = TRUE)
}

hippie_up_down <- function(direction) {
  editor_context <- rstudioapi::getSourceEditorContext()
  selection <- rstudioapi::primary_selection(editor_context)

  is_1st_invoke <- is_first_invocation(selection, editor_context)
  if (is_1st_invoke)
    init_state(editor_context)

  # Bail if no good match target or no match candidates
  if (is.null(.hippie$target_token)) return()
  if (is.null(.hippie$num_candidates)) return()
  if (.hippie$target_token == "") return()
  if (.hippie$num_candidates == 0) return()

  # Get the match candidate to insert ---------------------
  # Direction doesn't matter
  if (.hippie$num_candidates == 1) {
    candidate <- .hippie$all_candidates
  # Direction = up
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
  # Direction = down
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

  # Insert candidate ---------------------
  if (mode_is_insert()) {
    cursor <- id_cursor_position(selection)
    end <- rstudioapi::document_position(cursor$row, cursor$column)
    range_to_modify <- rstudioapi::document_range(
      start = .hippie$target_token_start, end = end
    )
    rstudioapi::modifyRange(
      location = range_to_modify,
      text = candidate,
      id = .hippie$doc_id
    )
  } else {
    rstudioapi::insertText(text = candidate, id = .hippie$doc_id)
  }

  invisible()
}

is_first_invocation <- function(selection, editor_context) {
  if (mode_is_insert()) {
    nearest_token <- extract_nearest_token(editor_context)
    if (is.null(.hippie$all_candidates)) {
      TRUE
    } else if (nearest_token %in% .hippie$all_candidates) {
      FALSE
    } else {
      # The nearest token isn't in existing candidate list, hence we just started
      TRUE
    }
  } else {
    selection[["text"]] == ""
  }
}

mode_is_insert <- function() {
  getOption("hippie.mode", "insert") == "insert"
}

mode_is_select <- function() {
  getOption("hippie.mode", "insert") == "select"
}

extract_nearest_token <- function(editor_context) {
  selection <- rstudioapi::primary_selection(editor_context)
  cursor <- id_cursor_position(selection)
  src <- editor_context$contents
  cursor_line_src <- src[[cursor$row]]
  substr_left_of_cursor <- substr(cursor_line_src, 1, cursor$column - 1)
  tokens <- unlist(strsplit(substr_left_of_cursor, SPLIT_SYMBOL_ON))
  if (length(tokens) == 0 || is.null(tokens)) return("")
  tokens[length(tokens)]
}

init_state <- function(editor_context) {
  selection <- rstudioapi::primary_selection(editor_context)
  cursor <- id_cursor_position(selection)
  src <- editor_context$contents
  cursor_line_src <- src[[cursor$row]]

  # ID match candidates above cursor ---------------------------
  if (cursor$row == 1) {
    lines_above_cursor <- NULL
  } else {
    lines_above_cursor <- src[1:(cursor$row - 1)]
  }
  substr_on_left <- substr(cursor_line_src, 1, cursor$column - 1)
  substr_on_left <- maybe_close_str(substr_on_left, side_lopped_off = "right")
  up_src <- paste0(
    paste0(lines_above_cursor, collapse = "\n"),
    "\n",
    substr_on_left
  )
  up_tokens <- parse_candidate_tokens(editor_context$path, up_src)
  target_token <- up_tokens[length(up_tokens)]
  up_candidates <- find_unique_matches(
    up_tokens, target_token, from_last = TRUE
  )

  # ID match candidates below cursor ---------------------------
  num_src_lines <- length(src)
  if (cursor$row == num_src_lines) {
    lines_below_cursor <- NULL
  } else {
    lines_below_cursor <- src[(cursor$row + 1):num_src_lines]
  }
  line_len <- nchar(cursor_line_src)
  substr_on_right <- substr(cursor_line_src, cursor$column, line_len)
  substr_on_right <- maybe_close_str(substr_on_right, side_lopped_off = "left")
  down_src <- paste0(
    substr_on_right,
    "\n",
    paste0(lines_below_cursor, collapse = "\n")
  )
  down_tokens <- parse_candidate_tokens(editor_context$path, down_src)
  down_candidates <- find_unique_matches(
    down_tokens, target_token, from_last = FALSE
  )

  # Set stateful vars ---------------------------
  .hippie$target_token <- target_token
  .hippie$all_candidates <- c(up_candidates, down_candidates)
  .hippie$num_candidates <- length(.hippie$all_candidates)
  .hippie$num_up_candidates <- length(up_candidates)
  .hippie$doc_id <- editor_context$id
  .hippie$target_token_start <- c(
    cursor$row, cursor$column - nchar(.hippie$target_token, type = "width")
  )

  if (.hippie$num_candidates == 0 || .hippie$target_token == "")
    return()

  if (mode_is_select()) {
    current_token_range <- rstudioapi::document_range(
      start = .hippie$target_token_start,
      end = c(cursor$row, cursor$column)
    )
    rstudioapi::setSelectionRanges(current_token_range, .hippie$doc_id)
  }
}

id_cursor_position <- function(selection) {
  rng <- selection[["range"]]
  start <- rng[["start"]]
  end <- rng[["end"]]
  stopifnot(all(start == end))
  list(row = start[["row"]], column = end[["column"]])
}

parse_candidate_tokens <- function(path, src_text) {
  if (is_r_file(path))
    parse_candidates_from_r_file(src_text)
  else
    parse_candidates_from_non_r_file(src_text)
}

is_r_file <- function(path) {
  grepl("\\.r$", path, ignore.case = TRUE)
}

parse_candidates_from_r_file <- function(src_text) {
  tokens <- sourcetools::tokenize_string(src_text)
  relevant_token_types <- c(
    "string", "symbol", "keyword", "comment", "number", "invalid"
  )
  relevant_tokens <- tokens[tokens$type %in% relevant_token_types, ]
  if (nrow(relevant_tokens) == 0) return("")
  # Remove leading and trailing ' and "
  relevant_tokens$value <- ifelse(
    relevant_tokens$type == "string",
    gsub("^(\"|')|(\"|')$", "", relevant_tokens$value),
    relevant_tokens$value
  )
  relevant_tokens$value <- trimws(relevant_tokens$value, "both")

  using_select_mode <- mode_is_select()

  split_str_tokens <- function(value, type, using_select_mode) {
    if (type == "string") {
      # We want to be able to match an entire string literal and also the tokens
      # inside those strings. We allow for that here, but only when we can
      # accurately keep track of the match token (i.e., when using "select
      # mode"). Note that the full string literal is prioritized lower
      # than the constituent tokens in the match list, by nature of fact that
      # it's put before the tokens in the token list and most times people will
      # be using hippie_up().
      if (using_select_mode) {
        c(value, unlist(strsplit(value, SPLIT_STR_ON)))
      } else {
        unlist(strsplit(value, SPLIT_STR_ON))
      }
    } else if (type %in% c("comment", "invalid")) {
      unlist(strsplit(value, SPLIT_STR_ON))
    } else {
      value
    }
  }

  unlist(mapply(
    FUN = split_str_tokens,
    value = relevant_tokens$value,
    type = relevant_tokens$type,
    using_select_mode = using_select_mode,
    USE.NAMES = FALSE
  ))
}

parse_candidates_from_non_r_file <- function(src_text) {
  unlist(strsplit(src_text, SPLIT_STR_ON))
}

maybe_close_str <- function(src_line_frag, side_lopped_off) {
  chars <- unlist(strsplit(src_line_frag, ""))
  has_odd_single_quotes <- (length(chars[chars == "'"]) %% 2) != 0
  has_odd_dbl_quotes <- (length(chars[chars == "\""]) %% 2) != 0
  # Odd number of single quotes probably more coincident with cases where the
  # src_line_frag is actually parsable R code (i.e., b/c of prevalence of ' vs
  # " in English), hence we'll prioritize case where we have odd number of
  # double quotes. You're out of luck if you have an odd number of both single
  # and double. Not trying to figure out that edge case right now.
  if (has_odd_dbl_quotes) {
    if (side_lopped_off == "right") {
      return(paste0(src_line_frag, "\""))
    } else {
      return(paste0("\"", src_line_frag))
    }
  } else if (has_odd_single_quotes) {
    if (side_lopped_off == "right") {
      return(paste0(src_line_frag, "'"))
    } else {
      return(paste0("'", src_line_frag))
    }
  }
  src_line_frag
}

find_unique_matches <- function(token_vec,
                                target_token,
                                from_last = TRUE) {
  # May be faster to just apply the regex and skip filtering of empties?
  non_empties <- token_vec[token_vec != ""]
  if (is.null(non_empties)) return(NULL)
  matches <- non_empties[startsWith(toupper(non_empties), toupper(target_token))]
  unique_matches <- unique(matches, fromLast = from_last)
  unique_matches[unique_matches != target_token]
}

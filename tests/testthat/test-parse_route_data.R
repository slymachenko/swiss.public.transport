# Tests for parse_route_data()

mock_response <- list(connections = list(
  list(
    departure = "2026-06-20T08:04:00", arrival = "2026-06-20T08:23:00",
    duration = 1140, legs = list(list(), list()) # direct -> 0 transfers
  ),
  list(
    departure = "2026-06-20T09:04:00", arrival = "2026-06-20T09:40:00",
    duration = 2160, legs = list(
      list(), list(), list()
    ) # one change -> 1 transfer
  )
))

test_that("parse_route_data returns one tidy row per connection", {
  parsed <- parse_route_data(mock_response)

  expect_s3_class(parsed, "tbl_df")
  expect_equal(nrow(parsed), 2)
  expect_true(all(
    c("departure", "arrival", "duration", "transfers") %in% names(parsed)
  ))
  # transfers = number of legs - 2
  expect_equal(parsed$transfers, c(0L, 1L))
})

test_that("parse_route_data returns an empty tibble for empty responses", {
  expect_equal(nrow(parse_route_data(list())), 0)
  expect_equal(nrow(parse_route_data(list(connections = list()))), 0)
})

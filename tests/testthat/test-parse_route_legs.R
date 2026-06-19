# Tests for parse_route_legs() (optional route-mapping task)

mock_response <- list(connections = list(list(legs = list(
  list(
    name = "Bern", stopid = "8507000", lon = 7.44, lat = 46.95,
    type = "express_train", line = "IC 81",
    exit = list(name = "Thun", stopid = "8507100", lon = 7.63, lat = 46.75)
  ),
  # final leg is the arrival node (no exit) and must be dropped
  list(arrival = "2026-06-20 08:23:00", name = "Thun", stopid = "8507100",
       lon = 7.63, lat = 46.75)
))))

test_that("parse_route_legs returns one row per travel leg", {
  legs <- parse_route_legs(mock_response)

  expect_s3_class(legs, "tbl_df")
  expect_equal(nrow(legs), 1)
  expect_true(all(
    c("connection_id", "leg_id", "from_stop", "from_stop_id",
      "to_stop", "to_stop_id", "mode", "line") %in% names(legs)
  ))
  expect_equal(legs$from_stop, "Bern")
  expect_equal(legs$to_stop, "Thun")
  expect_equal(legs$mode, "express_train")
  expect_equal(legs$line, "IC 81")
})

test_that("parse_route_legs returns an empty tibble for empty responses", {
  expect_equal(nrow(parse_route_legs(list())), 0)
  expect_equal(nrow(parse_route_legs(list(connections = list()))), 0)
})

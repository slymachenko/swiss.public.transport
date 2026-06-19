# Tests for compute_waiting_time() and summarise_waiting()

mock_routes <- tibble::tibble(
  from_city     = "Bern",
  to_city       = "Thun",
  to_station_id = "8507100",
  query_date    = "2026-06-20",
  query_time    = "08:00",
  # one departure before the query time (negative wait, must be dropped)
  departure = c(
    "2026-06-20T07:50:00", "2026-06-20T08:10:00", "2026-06-20T08:25:00"
  )
)

test_that("compute_waiting_time keeps the smallest non-negative wait", {
  waiting <- compute_waiting_time(mock_routes)

  # one row per origin-destination-query_time combination
  expect_equal(nrow(waiting), 1)
  expect_equal(waiting$waiting_time_min, 10)
})

test_that("summarise_waiting reports the median wait per destination", {
  summary <- summarise_waiting(mock_routes)

  expect_equal(nrow(summary), 1)
  expect_equal(summary$median_waiting_time, 10)
  expect_equal(summary$n_connections, 1L)
  expect_true("station_id" %in% names(summary))
})

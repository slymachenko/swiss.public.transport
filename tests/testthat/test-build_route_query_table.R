# Tests for build_route_query_table()

mock_station_data <- tibble::tibble(
  region    = "Test region",
  is_origin = c(TRUE, FALSE, FALSE),
  city      = c("Origin", "DestA", "DestB"),
  station_id = c("1", "2", "3")
)

test_that("build_route_query_table crosses origins, destinations and times", {
  query_table <- build_route_query_table(
    mock_station_data,
    query_date  = "2026-06-20",
    query_times = c("07:00", "09:00")
  )

  # 1 origin * 2 destinations * 2 query times
  expect_equal(nrow(query_table), 4)
  expect_true(all(
    c("region", "from_city", "from_station_id", "to_city",
      "to_station_id", "query_date", "query_time") %in% names(query_table)
  ))
  expect_setequal(query_table$to_city, c("DestA", "DestB"))
})

test_that("build_route_query_table rejects more than 5 query times", {
  expect_error(
    build_route_query_table(
      mock_station_data,
      query_date  = "2026-06-20",
      query_times = c("07:00", "09:00", "12:00", "16:00", "18:00", "20:00")
    )
  )
})

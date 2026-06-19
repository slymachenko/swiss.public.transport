# Tests for read_station_data()

test_that("read_station_data returns a tidy tibble for a valid group", {
  station_data <- read_station_data(2)

  expect_s3_class(station_data, "tbl_df")
  expect_gt(nrow(station_data), 0)
  # group_id is dropped after filtering
  expect_false("group_id" %in% names(station_data))
  # exactly one origin station per group
  expect_equal(sum(station_data$is_origin), 1)
})

test_that("read_station_data warns when the group has no data", {
  expect_warning(read_station_data(999))
})

#' @title Build Route Query Table
#'
#' @description
#' Builds a tidy table of all origin-destination-date-time combinations
#' for one regional group.
#'
#' @param station_data A tibble returned by `read_station_data()`.
#' @param query_date Date or character. The date used for API queries.
#' @param query_times Character vector of query times, maximum length 5.
#'
#' @return A tidy tibble containing route query combinations.
#' @export
#'
#' @importFrom dplyr filter select rename mutate
#' @importFrom tidyr crossing
build_route_query_table <- function(
    station_data,
    query_date,
    query_times = c("07:00", "09:00", "12:00", "16:00", "18:00")
) {
  .data <- rlang::.data

  if (length(query_times) > 5) {
    stop("Please use no more than 5 query times.")
  }

  origin <- station_data |>
    dplyr::filter(.data$is_origin == TRUE) |>
    dplyr::select(
      region = .data$region,
      from_city = .data$city,
      from_station_id = .data$station_id
    )

  destinations <- station_data |>
    dplyr::filter(.data$is_origin == FALSE) |>
    dplyr::select(
      to_city = .data$city,
      to_station_id = .data$station_id
    )

  query_table <- tidyr::crossing(
    origin,
    destinations,
    query_date = as.character(query_date),
    query_time = query_times
  )

  query_table
}

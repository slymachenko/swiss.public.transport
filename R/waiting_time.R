#' @title Compute the Minimum Waiting Time for Each Query
#'
#' @description
#' Calculates the waiting time (in minutes) between the requested
#' timetable query time and the actual departure time of each connection.
#' Filters out connections that departed before the query time, then keeps
#' only the connection with the smallest non-negative waiting time for each
#' unique origin-destination-query_time combination.
#'
#' @param routes_df A tidy tibble containing connection details.
#'
#' @return A tibble containing only one row per query
#' (the next available departure)
#'   with `waiting_time_min` added.
#' @export
#'
#' @importFrom dplyr mutate filter group_by slice_min ungroup
#' @importFrom rlang .data
compute_waiting_time <- function(routes_df) {
  .data <- rlang::.data

  routes_df |>
    dplyr::mutate(
      query_datetime_parsed = as.POSIXct(
        paste(.data$query_date, .data$query_time),
        tz = "CET"
      ),
      departure_time_parsed = as.POSIXct(
        gsub("T", " ", substring(.data$departure, 1, 19)),
        tz = "CET"
      ),
      waiting_time_min = as.numeric(
        difftime(
          .data$departure_time_parsed, .data$query_datetime_parsed,
          units = "mins"
        )
      )
    ) |>
    dplyr::filter(
      !is.na(.data$waiting_time_min), .data$waiting_time_min >= 0
    ) |>
    dplyr::group_by(
      .data$from_city, .data$to_city, .data$query_date, .data$query_time
    ) |>
    dplyr::slice_min(.data$waiting_time_min, n = 1, with_ties = FALSE) |>
    dplyr::ungroup()
}

#' @title Summarise Waiting Times by Destination
#'
#' @description
#' Aggregates the per-query minimum waiting times for each destination,
#' computing the median waiting time across all queried times of day.
#' It internally calls `compute_waiting_time()` to process the raw
#' connection data before summarizing.
#'
#' @param routes_df A tidy tibble containing connection details
#' (the parsed API route output).
#' @return A summarised tibble with median waiting times
#' per destination station.
#' @export
#'
#' @importFrom dplyr group_by summarise n
#' @importFrom stats median
#' @importFrom rlang .data
summarise_waiting <- function(routes_df) {
  .data <- rlang::.data

  waiting_df <- compute_waiting_time(routes_df)

  waiting_df |>
    dplyr::group_by(station_id = .data$to_station_id, .data$to_city) |>
    dplyr::summarise(
      median_waiting_time = stats::median(.data$waiting_time_min, na.rm = TRUE),
      n_connections = dplyr::n(),
      .groups = "drop"
    )
}

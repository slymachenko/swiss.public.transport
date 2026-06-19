#' Compute the Minimum Non-Negative Waiting Time for Each Query
#'
#' @param routes_df A tidy data frame containing connection details.
#' @return A data frame containing only one row per query (the next available departure)
#'   with `waiting_time_min` added.
#' @export
#'
#' @importFrom dplyr mutate filter group_by slice_min ungroup
#' @importFrom rlang .data
compute_waiting_time <- function(routes_df) {
  .data <- rlang::.data
  
  routes_df |>
    dplyr::mutate(
      query_datetime_parsed = as.POSIXct(paste(.data$query_date, .data$query_time), tz = "CET"),
      departure_time_parsed = as.POSIXct(gsub("T", " ", substring(.data$departure, 1, 19)), tz = "CET"),
      waiting_time_min = as.numeric(difftime(.data$departure_time_parsed, .data$query_datetime_parsed, units = "mins"))
    ) |>
    dplyr::filter(!is.na(.data$waiting_time_min), .data$waiting_time_min >= 0) |>
    dplyr::group_by(.data$from_city, .data$to_city, .data$query_date, .data$query_time) |>
    dplyr::slice_min(.data$waiting_time_min, n = 1, with_ties = FALSE) |>
    dplyr::ungroup()
}

#' Summarise Waiting Times by Destination
#'
#' @param waiting_df A data frame containing the outputs of `compute_waiting_time()`.
#' @return A summarised data frame with median waiting times per destination station.
#' @export
#'
#' @importFrom dplyr group_by summarise n
#' @importFrom stats median
#' @importFrom rlang .data
summarise_waiting <- function(waiting_df) {
  .data <- rlang::.data
  
  waiting_df |>
    dplyr::group_by(station_id = .data$to_station_id, .data$to_city) |>
    dplyr::summarise(
      median_waiting_time = stats::median(.data$waiting_time_min, na.rm = TRUE),
      n_connections = dplyr::n(),
      .groups = "drop"
    )
}


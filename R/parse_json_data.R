#' @title Parse and Combine All Route Queries
#'
#' @description Iterates over the query table, loads the cached API responses,
#' parses them, and combines everything into a single tidy data frame.
#'
#' @param query_table A tibble created by `build_route_query_table()`.
#' @param cache_dir Character. The directory where API responses are saved.
#'
#' @return A tidy tibble with the extracted connections and query metadata.
#' @export
#'
#' @importFrom dplyr mutate select bind_rows everything
#' @importFrom purrr pmap_dfr
#' @importFrom rlang .data
combine_parsed_queries <- function(query_table, cache_dir = "cache") {
  .data <- rlang::.data

  # Use purrr::pmap_dfr to iterate over each row of the query table
  all_routes <- purrr::pmap_dfr(query_table, function(...) {
    row_data <- list(...)

    # Build the expected cache file name (assuming a logical naming convention)
    # Example: "route_8507000_8502113_1600.rds"
    safe_time <- gsub(":", "", row_data$query_time)
    file_name <- paste0("route_", row_data$from_station_id, "_",
                        row_data$to_station_id, "_", safe_time, ".rds")
    file_path <- file.path(cache_dir, file_name)

    # Check if the file exists in the cache
    if (!file.exists(file_path)) {
      warning(paste("Cache file not found:", file_path))
      return(tibble::tibble())
    }

    # Load the cached response and parse it using the helper function
    # Note: parse_route_data() is expected to extract 'duration', 'departure', etc.
    api_response <- readRDS(file_path)
    parsed_data <- parse_route_data(api_response)

    # Add the original query metadata to the parsed result
    if (nrow(parsed_data) > 0) {
      parsed_data <- parsed_data |>
        dplyr::mutate(
          from_city       = row_data$from_city,
          to_city         = row_data$to_city,
          from_station_id = row_data$from_station_id,
          to_station_id   = row_data$to_station_id,
          query_date      = row_data$query_date,
          query_time      = row_data$query_time
        )
    }
    return(parsed_data)
  })

  return(all_routes)
}

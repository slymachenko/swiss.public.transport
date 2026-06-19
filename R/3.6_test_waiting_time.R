# Test Script for Phase 3.6 — Waiting Time Indicators Calculation
# This script is self-contained and demonstrates the logic offline using mock data.

library(dplyr)

# ==============================================================================
# 1. ANALYTICAL FUNCTIONS IMPLEMENTATION
# ==============================================================================

#' Compute the Minimum Non-Negative Waiting Time for Each Query
#'
#' This function calculates the waiting time (in minutes) between the requested
#' timetable query time and the actual departure time of the connection.
#' It handles the filtering of invalid connections (those that departed before
#' the query time) and selects the next available departure (the connection with
#' the smallest waiting time) for each unique query.
#'
#' @param routes_df A tidy data frame containing connection details.
#'   Must include the following columns:
#'   - `from_city` (character): Origin city/station.
#'   - `to_city` (character): Destination city/station.
#'   - `query_time` (POSIXct): The exact date-time requested by the user.
#'   - `departure_time` (POSIXct): The actual departure date-time of the connection.
#'
#' @return A data frame containing only one row per query (the next available 
#'   departure), with an additional numeric column `waiting_time_min` representing 
#'   the waiting time in minutes.
compute_waiting_time <- function(routes_df) {
  # Bind variable names to avoid R CMD check notes about undefined global variables
  .data <- rlang::.data
  
  routes_df |>
    # STEP A: Calculate the difference in minutes between departure and query time.
    # We use difftime and explicitly cast it as numeric to prevent class issues.
    dplyr::mutate(
      waiting_time_min = as.numeric(difftime(.data$departure_time, .data$query_time, units = "mins"))
    ) |>
    # STEP B: Filter out negative waiting times.
    # Connections with negative values departed before the query time (e.g. departed 
    # at 07:55 when query was at 08:00), making them invalid options for the user.
    dplyr::filter(.data$waiting_time_min >= 0) |>
    # STEP C: Group the connections by each unique query.
    # A single query is uniquely defined by the origin, the destination, and the query time.
    dplyr::group_by(.data$from_city, .data$to_city, .data$query_time) |>
    # STEP D: Select the connection with the smallest waiting time.
    # slice_min keeps only the minimum waiting_time_min per group. 
    # with_ties = FALSE ensures that if two connections have the exact same waiting time, 
    # only the first one is kept, avoiding duplicate records in the final tidy dataset.
    dplyr::slice_min(.data$waiting_time_min, n = 1, with_ties = FALSE) |>
    # STEP E: Ungroup the resulting dataset to prevent downstream side-effects.
    dplyr::ungroup()
}

#' Summarise Waiting Times by Destination
#'
#' Aggregates the computed minimum waiting times for each destination city.
#' It calculates the median waiting time across all queried times of day and
#' counts the number of valid connection queries analyzed.
#'
#' @param waiting_df A data frame containing the outputs of `compute_waiting_time()`.
#'   Must include columns: `to_city` and `waiting_time_min`.
#'
#' @return A summarised data frame with one row per destination city containing:
#'   - `to_city` (character): Destination city name.
#'   - `median_waiting` (numeric): Median waiting time in minutes.
#'   - `n_connections` (integer): Total number of valid connection queries analyzed.
summarise_waiting <- function(waiting_df) {
  # Bind variable names to avoid R CMD check notes about undefined global variables
  .data <- rlang::.data
  
  waiting_df |>
    # STEP A: Group the rows by destination city.
    dplyr::group_by(.data$to_city) |>
    # STEP B: Calculate statistical metrics for each group.
    dplyr::summarise(
      # median() computes the median waiting time. na.rm = TRUE handles any missing values safely.
      median_waiting = stats::median(.data$waiting_time_min, na.rm = TRUE),
      # n() counts how many queries had valid departures for this destination.
      n_connections = dplyr::n(),
      .groups = "drop"
    )
}


# ==============================================================================
# 2. MOCK DATA GENERATION FOR OFFLINE TESTING
# ==============================================================================

cat("--- GENERATING MOCK DATA FOR OFFLINE TESTING ---\n")

# Define a baseline date and a vector of 3 representative query times (morning, noon, evening)
base_date <- "2026-06-22"
q_times <- as.POSIXct(paste(base_date, c("08:00:00", "12:00:00", "17:00:00")), tz = "CET")

# Construct the mock routes data frame.
# This simulates nested API responses that have already been flattened.
# We create 8 connection records for Lugano and 8 connection records for Locarno.
mock_routes <- tibble::tibble(
  from_city = "Bellinzona",
  to_city = rep(c("Lugano", "Locarno"), each = 8),
  query_time = rep(rep(q_times, times = c(3, 2, 3)), times = 2),
  
  # Define departure times. Some are before the query time (negative waiting time),
  # some are immediately after, and some are much later.
  departure_time = as.POSIXct(c(
    # --- DESTINATION: LUGANO ---
    # Query at 08:00
    "2026-06-22 07:58:00", # Train already departed (waiting: -2 min, should be filtered out)
    "2026-06-22 08:05:00", # Next available departure (waiting: 5 min, should be chosen)
    "2026-06-22 08:23:00", # Later connection (waiting: 23 min)
    # Query at 12:00
    "2026-06-22 12:12:00", # Next available departure (waiting: 12 min, should be chosen)
    "2026-06-22 12:30:00", # Later connection (waiting: 30 min)
    # Query at 17:00
    "2026-06-22 16:55:00", # Train already departed (waiting: -5 min, should be filtered out)
    "2026-06-22 17:15:00", # Next available departure (waiting: 15 min, should be chosen)
    "2026-06-22 17:45:00", # Later connection (waiting: 45 min)
    
    # --- DESTINATION: LOCARNO ---
    # Query at 08:00
    "2026-06-22 08:10:00", # Next available departure (waiting: 10 min, should be chosen)
    "2026-06-22 08:15:00", # Later connection (waiting: 15 min)
    "2026-06-22 08:40:00", # Later connection (waiting: 40 min)
    # Query at 12:00
    "2026-06-22 12:08:00", # Next available departure (waiting: 8 min, should be chosen)
    "2026-06-22 12:20:00", # Later connection (waiting: 20 min)
    # Query at 17:00
    "2026-06-22 16:59:00", # Train already departed (waiting: -1 min, should be filtered out)
    "2026-06-22 17:06:00", # Next available departure (waiting: 6 min, should be chosen)
    "2026-06-22 17:12:00"  # Later connection (waiting: 12 min)
  ), tz = "CET")
)

print(mock_routes)


# ==============================================================================
# 3. RUNNING CALCULATIONS AND VALIDATING
# ==============================================================================

cat("\n--- STEP 1: CALCULATING MINIMUM WAITING TIME PER QUERY ---\n")
# Filter invalid connections and extract the next available departure
waiting_times <- compute_waiting_time(mock_routes)
print(waiting_times)

cat("\n--- STEP 2: STATISTICAL SUMMARY (MEDIAN WAITING TIME PER DESTINATION) ---\n")
# Compute the median waiting time for each destination city
summary_results <- summarise_waiting(waiting_times)
print(summary_results)

# Theoretical check verification:
# Lugano: minimum waiting times are c(5, 12, 15). Median of these values is 12.
# Locarno: minimum waiting times are c(10, 8, 6). Median of these values is 8.
cat("\nExpected Theoretical Calculation -> Lugano: 12, Locarno: 8\n")
cat("Actual Programmatic Calculation  -> Lugano:", 
    summary_results$median_waiting[summary_results$to_city == "Lugano"], 
    ", Locarno:", 
    summary_results$median_waiting[summary_results$to_city == "Locarno"], "\n")

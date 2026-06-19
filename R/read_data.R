#' @title Read Regional Station Data
#'
#' @description Reads the `SwissCities.csv` file using tidyverse functions
#' and filters it for a specific group ID.
#'
#' @param target_group Numeric or character
#' specifying the group ID to filter (e.g., 2).
#'
#' @return A tidy tibble containing the station data for the specified group.
#' @export
#'
#' @importFrom readr read_delim
#' @importFrom dplyr filter rename_with
read_station_data <- function(target_group) {
  .data <- rlang::.data

  # Locate the file inside inst/extdata safely across environments
  file_path <- system.file(
    "extdata", "SwissCities.csv",
    package = "swiss.public.transport"
  )

  if (file_path == "") {
    stop(
      "Critical Error: SwissCities.csv could not be found inside inst/extdata/"
    )
  }

  # Read using semicolon separation
  station_data <- readr::read_delim(
    file = file_path,
    delim = ","
  ) |>
    dplyr::filter(.data$group_id == target_group)

  if (nrow(station_data) == 0) {
    warning(paste("No data found for group ID:", target_group))
  }

  station_data
}

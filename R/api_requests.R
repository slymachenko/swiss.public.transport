#' @title Download a Route from the search.ch Timetable API
#' @param from Character. Origin station ID (e.g. "8507000").
#' @param to Character. Destination station ID (e.g. "8507100").
#' @param date Character. Date in DD.MM.YYYY format.
#' @param time Character. Departure time in HH:MM format.
#' @param num Integer. Number of connections to retrieve (default 5).
#' @description
#' Sends a request to the search.ch timetable API and returns the parsed JSON
#' response as a list. Retries up to 3 times with increasing delays if the
#' server returns a 429 rate-limit error.
#'
#' @returns A list with the parsed JSON API response.
#'
#' @examples
#' \dontrun{
#' route <- get_route("8507000", "8507100", "25.06.2026", "08:00")
#' }
get_route <- function(from, to, date, time, num = 5) {
  url <- paste0(
    "https://search.ch/timetable/api/route.json",
    "?from=", from,
    "&to=",   to,
    "&date=", date,
    "&time=", time,
    "&num=",  num
  )

  result <- NULL

  for (attempt in 1:3) {
    result <- tryCatch(
      jsonlite::fromJSON(url, simplifyVector = FALSE),
      error = function(e) NULL
    )

    if (!is.null(result)) break

    if (attempt < 3) {
      wait <- 60 * attempt
      message(
        "Rate limited (429). Waiting ",
        wait,
        "s before retry ",
        attempt + 1,
        "/3..."
      )
      Sys.sleep(wait)
    } else {
      stop("API still returning 429 after 3 attempts for: ", url)
    }
  }

  result
}

#' @title Get Cached Route Data from search.ch API
#'
#' @description
#' Wraps `get_route()` to provide local caching,
#' fulfilling the mandatory hackathon requirement.
#' It checks if an API response is already saved locally as an `.rds` file.
#' If it exists, it loads the local file.
#' Otherwise, it queries the API, saves the result locally,
#' and then returns the data.
#'
#' @param from Character. Origin station ID (e.g., "8507000").
#' @param to Character. Destination station ID (e.g., "8507100").
#' @param date Character. Date in DD.MM.YYYY format.
#' @param time Character. Departure time in HH:MM format.
#' @param cache_dir Character. Path to the directory
#' where cache files are stored.
#' @param num Integer. Number of connections to retrieve (default 5).
#'
#' @return A list with the parsed JSON API response.
#' @export
#'
#' @examples
#' \dontrun{
#' # Assuming a "cache" directory exists in your working directory
#' route <- get_cached_route(
#'   from = "8507000",
#'   to = "8507100",
#'   date = "25.06.2026",
#'   time = "08:00",
#'   cache_dir = "cache"
#' )
#' }
get_cached_route <- function(
  from, to, date, time, cache_dir = "cache", num = 5
) {
  # Ensure the cache directory exists, create it if it doesn't
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
    message("Created cache directory: ", cache_dir)
  }

  # Sanitize inputs to create a safe, unique file name
  # Replace colons in time to avoid OS file system errors
  safe_time <- gsub(":", "-", time)

  # Create a unique filename for this exact query
  file_name <- paste0(
    "route_", from, "_", to, "_", date, "_", safe_time, ".rds"
  )
  file_path <- file.path(cache_dir, file_name)

  # Check if the cache file exists
  if (file.exists(file_path)) {
    message("Loading cached data for: ", from, " -> ", to, " at ", time)

    # Load and return the local file instead of calling the API
    cached_data <- readRDS(file_path)
    cached_data
  } else {
    message("No cache found. Calling API for: ", from, " -> ", to, " at ", time)

    # Call the original API function
    api_data <- get_route(
      from = from,
      to = to,
      date = date,
      time = time,
      num = num
    )

    # Save the response locally as an .rds file
    if (!is.null(api_data)) {
      saveRDS(api_data, file = file_path)
      message("Saved response to cache: ", file_path)
    } else {
      warning("API returned NULL. Data was not cached.")
    }

    api_data
  }
}

#' @title Populate Local Cache from Query Table
#'
#' @description
#' Iterates through a route query table and fetches data for each row using
#' `get_cached_route()`. This function effectively pre-loads your local cache
#' so that subsequent analysis and mapping steps can run instantly without
#' hitting the search.ch API. It also handles necessary date reformatting.
#'
#' @param query_table A data frame or tibble generated
#' by `build_route_query_table()`.
#' @param cache_dir Character. Path to the cache directory. Defaults to "cache".
#' @param num Integer. Number of connections to retrieve per query (default 5).
#' @param sleep Numeric. Seconds to pause between API calls
#' to avoid rate limits (default 0.5).
#'
#' @return Invisibly returns the original `query_table`.
#' @export
#'
#' @examples
#' \dontrun{
#' # Assuming 'my_queries' is your generated query table
#' my_cache <- file.path(tempdir(), "cache")
#' populate_route_cache(my_queries, cache_dir = my_cache)
#' }
populate_route_cache <- function(
  query_table, cache_dir = "cache", num = 5, sleep = 3
) {
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  message("Starting cache population for ", nrow(query_table), " queries...")

  for (i in seq_len(nrow(query_table))) {
    # Extract row parameters
    row <- query_table[i, ]
    from <- as.character(row$from_station_id)
    to <- as.character(row$to_station_id)
    time <- as.character(row$query_time)
    date <- as.Date(row$query_date)

    message(sprintf(
      "[%d/%d] Fetching: Station %s -> %s at %s",
      i, nrow(query_table), from, to, time
    ))

    # Call the caching wrapper
    get_cached_route(
      from = from,
      to = to,
      date = date,
      time = time,
      cache_dir = cache_dir,
      num = num
    )

    # Pause slightly to respect the API server (prevents instant blocking)
    Sys.sleep(sleep)
  }

  message("Cache population complete!")
  invisible(query_table)
}

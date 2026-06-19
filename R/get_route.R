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
#' @export
#'
#' @examples
#' route <- get_route("8507000", "8507100", "25.06.2026", "08:00")
#'
get_route <- function(from, to, date, time, num = 5) {
  url <- paste0("https://search.ch/timetable/api/route.json",
                "?from=", from,
                "&to=",   to,
                "&date=", date,
                "&time=", time,
                "&num=",  num)

  result <- NULL

  for (attempt in 1:3) {
    result <- tryCatch(
      jsonlite::fromJSON(url, simplifyVector = FALSE), error = function(e) NULL)

    if (!is.null(result)) break

    if (attempt < 3) {
      wait <- 30 * attempt
      message("Rate limited (429). Waiting ", wait, "s before retry ", attempt + 1, "/3...")
      Sys.sleep(wait)
    } else {
      stop("API still returning 429 after 3 attempts for: ", url)
    }
  }

  result
}

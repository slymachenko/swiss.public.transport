#' @title Creates a simplified route map
#'
#' @description
#' Draws simplified routes on the Swiss base map as polylines through the
#' ordered sequence of stops, coloured by transport mode. The assigned origin
#' station is highlighted with a star, matching the waiting-time map.
#'
#' @param route_points A tidy data frame of ordered route stops with
#' coordinates (output of `parse_route_points()` or`combine_parsed_points()`).
#' @param station_data A tidy data frame containing regional station
#'   coordinates (output of `read_station_data()`), used to mark the origin.
#'
#' @return A ggplot object representing the simplified route map
#' @export
#'
#' @importFrom dplyr filter pull
#' @importFrom sf read_sf st_transform
#' @importFrom ggplot2 ggplot geom_sf geom_path geom_point geom_sf_text aes
#' @importFrom scale_color_brewer labs coord_sf theme_minimal theme element_rect
#' @importFrom element_blank element_text margin
plot_route_map <- function(route_points, station_data) {
  .data <- rlang::.data

  # LOAD SWISS CANTON BOUNDARIES (same source as the waiting-time map)
  extdata_path <- system.file("extdata", package = "swiss.public.transport")
  shapefile_path <- list.files(
    path = extdata_path, pattern = "\\.shp$", full.names = TRUE
  )[1]

  swiss_map <- NULL
  if (!is.na(shapefile_path) && file.exists(shapefile_path)) {
    swiss_map <- sf::read_sf(shapefile_path) |>
      sf::st_transform(4326) # Match longitude/latitude system
  }

  # Origin station, highlighted with a star
  origin <- station_data |> dplyr::filter(.data$is_origin == TRUE)
  origin_city_name <- origin |>
    dplyr::pull(.data$city) |>
    unique()

  # Bounding box derived from the route coordinates (with a small buffer)
  lon <- route_points$lon
  lat <- route_points$lat
  x_margin <- (max(lon) - min(lon)) * 0.1
  y_margin <- (max(lat) - min(lat)) * 0.1

  # Palette (shared with the accessibility map)
  bg_cream <- "#F5F2EB"
  map_gray <- "#DCD8C5"
  swiss_red <- "#E61A1A"
  text_dark <- "#1C1C1C"

  route_map <- ggplot2::ggplot()

  # Base layer: Swiss cantons (omitted if the shapefile is unavailable)
  if (!is.null(swiss_map)) {
    route_map <- route_map +
      ggplot2::geom_sf(
        data = swiss_map, fill = map_gray, color = bg_cream, size = 0.5
      )
  }

  route_map +
    # Route polylines through the ordered stops, coloured by transport mode
    ggplot2::geom_path(
      data = route_points,
      ggplot2::aes(
        x = .data$lon, y = .data$lat,
        group = interaction(.data$connection_id, .data$leg_id),
        color = .data$mode
      ),
      linewidth = 0.8, alpha = 0.8
    ) +

    # Stops along the routes
    ggplot2::geom_point(
      data = route_points,
      ggplot2::aes(x = .data$lon, y = .data$lat),
      color = text_dark, size = 1.5
    ) +

    # Origin center highlight (Star)
    ggplot2::geom_point(
      data = origin,
      ggplot2::aes(x = .data$longitude, y = .data$latitude),
      color = swiss_red, shape = 18, size = 6.5
    ) +

    # Colour scale and labels
    ggplot2::scale_color_brewer(palette = "Dark2", name = "Transport mode") +
    ggplot2::labs(
      title = paste("Simplified routes from", origin_city_name),
      subtitle =
        "Straight segments connect consecutive stops, by transport mode.",
      caption = "Data: SwissCities.csv & search.ch API"
    ) +

    # Dynamic zoom focusing on the region's routes
    ggplot2::coord_sf(
      xlim = c(min(lon) - x_margin, max(lon) + x_margin),
      ylim = c(min(lat) - y_margin, max(lat) + y_margin),
      expand = FALSE
    ) +

    # Custom theme (shared with the accessibility map)
    ggplot2::theme_minimal(base_family = "Helvetica") +
    ggplot2::theme(
      panel.background = ggplot2::element_rect(fill = bg_cream, color = NA),
      plot.background = ggplot2::element_rect(fill = bg_cream, color = NA),
      panel.grid = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(
        face = "bold", size = 13, color = text_dark,
        margin = ggplot2::margin(b = 4)
      ),
      plot.subtitle = ggplot2::element_text(
        size = 9, color = "gray20", margin = ggplot2::margin(b = 14)
      ),
      plot.caption = ggplot2::element_text(
        size = 7.5, color = "gray40", face = "italic",
        margin = ggplot2::margin(t = 12)
      ),
      legend.title = ggplot2::element_text(
        face = "bold", size = 8.5, color = text_dark
      ),
      legend.text = ggplot2::element_text(size = 8, color = text_dark),
      legend.position = "right"
    )
}

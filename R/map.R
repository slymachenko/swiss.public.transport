#' @title Creates waiting-time accessibility map
#'
#' @description
#' Generates a regional accessibility map overlaying destination cities onto a
#' Swiss base map. Point sizes reflect population, and colors reflect median
#' waiting time.
#'
#' @param waiting_times_data A tidy data frame containing computed waiting times
#'   per destination (output of `summarise_waiting()`).
#' @param station_data A tidy data frame containing regional station coordinates
#'   and population (output of `read_station_data()`).
#'
#' @return A ggplot object representing the accessibility map
#' @export
#'
#' @importFrom dplyr left_join filter pull
#' @importFrom sf st_as_sf read_sf st_transform st_bbox st_as_sfc
#' @importFrom ggplot2 ggplot geom_sf geom_sf_text aes scale_color_gradientn
#' scale_size_continuous labs coord_sf theme_minimal theme element_rect
#' element_blank element_text margin
plot_accessibility_map <- function(waiting_times_data, station_data) {
  .data <- rlang::.data

  # DATA PREPARATION

  # Join station coordinates/population with the waiting times
  swiss_cities <- station_data |>
    dplyr::left_join(waiting_times_data, by = "station_id")

  # Convert data coordinates to a spatial object (CRS 4326 = Longitude/Latitude)
  cities_sf <- sf::st_as_sf(
    swiss_cities,
    coords = c("longitude", "latitude"),
    crs = 4326
  )

  # Separate origin from destinations to style them differently
  origin_sf <- cities_sf |> dplyr::filter(.data$is_origin == TRUE)
  destinations_sf <- cities_sf |> dplyr::filter(.data$is_origin == FALSE)

  # Extract the actual origin city name dynamically for titles
  origin_city_name <- origin_sf |>
    dplyr::pull(.data$city) |>
    unique()

  # LOAD SWISS CANTON BOUNDARIES

  # Pull matching shapefile from the package's inst/extdata folder
  extdata_path <- system.file("extdata", package = "swiss.public.transport")
  shapefile_path <- list.files(
    path = extdata_path, pattern = "\\.shp$", full.names = TRUE
  )[1]

  # If the shapefile exists, read it; otherwise, create a fallback bounding box
  if (!is.na(shapefile_path) && file.exists(shapefile_path)) {
    swiss_map <- sf::read_sf(shapefile_path) |>
      sf::st_transform(4326) # Match longitude/latitude system
  } else {
    swiss_map <- sf::st_as_sfc(sf::st_bbox(cities_sf))
  }

  # Calculate dynamic bounding box based on the region's cities
  # (with a small buffer)
  bbox <- sf::st_bbox(cities_sf)
  x_margin <- (bbox["xmax"] - bbox["xmin"]) * 0.1
  y_margin <- (bbox["ymax"] - bbox["ymin"]) * 0.1

  # DESIGN AND PLOT

  # Palette
  bg_cream <- "#F5F2EB"
  map_gray <- "#DCD8C5"
  swiss_red <- "#E61A1A"
  text_dark <- "#1C1C1C"

  ch_map <- ggplot2::ggplot() +
    # Base layer: Swiss cantons
    ggplot2::geom_sf(
      data = swiss_map, fill = map_gray, color = bg_cream, size = 0.5
    ) +

    # Destination data points
    ggplot2::geom_sf(
      data = destinations_sf,
      ggplot2::aes(size = .data$population, color = .data$median_waiting_time),
      alpha = 0.9
    ) +

    # Exact waiting-time labels for destinations
    ggplot2::geom_sf_text(
      data = destinations_sf,
      ggplot2::aes(label = paste0(.data$median_waiting_time, " min")),
      color = text_dark,
      size = 2.7,
      vjust = -0.8,
      check_overlap = TRUE
    ) +

    # Origin center highlight (Star)
    ggplot2::geom_sf(
      data = origin_sf, color = swiss_red, shape = 18, size = 6.5
    ) +
    ggplot2::geom_sf(
      data = origin_sf, color = swiss_red, shape = 1, size = 9, stroke = 1.2
    ) +
    ggplot2::geom_sf_text(
      data = origin_sf,
      ggplot2::aes(label = paste0(origin_city_name, "\n(Origin)")),
      color = swiss_red,
      fontface = "bold",
      size = 3.1,
      vjust = 1.8
    ) +

    # Destination city names
    ggplot2::geom_sf_text(
      data = destinations_sf,
      ggplot2::aes(label = .data$city),
      color = text_dark,
      family = "Helvetica",
      fontface = "bold",
      vjust = -1.8,
      size = 3.3
    ) +

    # Mapping scales
    ggplot2::scale_color_gradientn(
      colors = c("#1E6B38", "#E6A100", "#B81414"),
      name = "Median wait time\n(min)"
    ) +
    ggplot2::scale_size_continuous(
      range = c(3.5, 9),
      labels = scales::comma,
      name = "Population"
    ) +

    # Labels and canvas framing (Dynamic Titles)
    ggplot2::labs(
      title = paste("Waiting times from", origin_city_name),
      subtitle = "Circle size shows population. Color shows median wait time.",
      caption = "Data: SwissCities.csv & search.ch API"
    ) +

    # Dynamic zoom focusing purely on the region's points
    ggplot2::coord_sf(
      xlim = c(bbox["xmin"] - x_margin, bbox["xmax"] + x_margin),
      ylim = c(bbox["ymin"] - y_margin, bbox["ymax"] + y_margin),
      expand = FALSE
    ) +

    # Custom theme
    ggplot2::theme_minimal(base_family = "Helvetica") +
    ggplot2::theme(
      panel.background = ggplot2::element_rect(fill = bg_cream, color = NA),
      plot.background = ggplot2::element_rect(fill = bg_cream, color = NA),
      panel.grid = ggplot2::element_blank(),

      # Text aesthetics
      plot.title = ggplot2::element_text(
        face = "bold",
        size = 13,
        color = text_dark,
        margin = ggplot2::margin(b = 4)
      ),
      plot.subtitle = ggplot2::element_text(
        size = 9, color = "gray20", margin = ggplot2::margin(b = 14)
      ),
      plot.caption = ggplot2::element_text(
        size = 7.5,
        color = "gray40",
        face = "italic",
        margin = ggplot2::margin(t = 12)
      ),

      # Legend aesthetics
      legend.title = ggplot2::element_text(
        face = "bold", size = 8.5, color = text_dark
      ),
      legend.text = ggplot2::element_text(size = 8, color = text_dark),
      legend.position = "right"
    )

  ch_map
}

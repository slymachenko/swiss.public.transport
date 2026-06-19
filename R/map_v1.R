#' Creates waiting-time accessibility map

#' @param waiting_times_data a tidy data frame containing computed waiting times per destination
#' @return a ggplot object representing the accessibility map
#' @export plot_accessibility_map

plot_accessibility_map <- function(waiting_times_data) {
    # -------------------------------------------------------------------------
    # LOAD SWISS CITIES DATA
    # -------------------------------------------------------------------------

    # only from our group
    cities_of_interest <- readr::read_csv(
        system.file("extdata", "SwissCities.csv", package = "swiss.public.transport"),
        show_col_types = FALSE
    ) |>
        dplyr::filter(group_id == 2)

    # join with the real-time updating waiting times data
    # this ensures the map dynamically refreshes with live data
    swiss_cities <- cities_of_interest |>
        dplyr::left_join(waiting_times_data, by = "station_id")

    # convert data coordinates to an spatial object
    cities_sf <- sf::st_as_sf(swiss_cities, coords = c("longitude", "latitude"), crs = 4326)

    # separate origin (Bern) from destinations to style differently
    origin_sf <- cities_sf |>
        dplyr::filter(is_origin == TRUE)
    destinations_sf <- cities_sf |>
        dplyr::filter(is_origin == FALSE)

    # -------------------------------------------------------------------------
    # LOAD SWISS CANTON BOUNDARIES
    # -------------------------------------------------------------------------

    # pulling matching shapefile from our inst/extdata folder
    extdata_path <- system.file("extdata", package = "swiss.public.transport")
    shapefile_path <- list.files(path = extdata_path, pattern = "\\.shp$", full.names = TRUE)[1]

    # if the shapefile exists, read it; otherwise, create a fallback bounding box
    if (!is.na(shapefile_path) && file.exists(shapefile_path)) {
        swiss_map <- sf::read_sf(shapefile_path) |>
            sf::st_transform(4326) # match longitude/latitude system
    } else {
        # fallback boundary canvas box if you run this script standalone
        swiss_map <- sf::st_as_sfc(sf::st_bbox(cities_sf))
    }

    # -------------------------------------------------------------------------
    # DESIGN
    # -------------------------------------------------------------------------

    # palette
    bg_cream <- "#F5F2EB"
    map_gray <- "#DCD8C5"
    swiss_red <- "#E61A1A"
    text_dark <- "#1C1C1C"

    ch_map <- ggplot2::ggplot() +
        # 1. base layer: Swiss cantons
        ggplot2::geom_sf(data = swiss_map, fill = map_gray, color = bg_cream, size = 0.5) +

        # 2. destination data points
        ggplot2::geom_sf(
            data = destinations_sf,
            ggplot2::aes(size = population, color = median_waiting_time),
            alpha = 0.9
        ) +

        # 2b. exact waiting-time labels for destinations
        ggplot2::geom_sf_text(
            data = destinations_sf,
            ggplot2::aes(label = paste0(median_waiting_time, " min")),
            color = text_dark,
            size = 2.7,
            vjust = -0.8,
            check_overlap = TRUE
        ) +

        # 3. origin center (Bern HB)
        ggplot2::geom_sf(data = origin_sf, color = swiss_red, shape = 18, size = 6.5) +
        ggplot2::geom_sf(data = origin_sf, color = swiss_red, shape = 1, size = 9, stroke = 1.2) +
        ggplot2::geom_sf_text(
            data = origin_sf,
            ggplot2::aes(label = "Bern (origin)"),
            color = swiss_red,
            fontface = "bold",
            size = 3.1,
            vjust = 1.8
        ) +

        # 4. typography
        ggplot2::geom_sf_text(
            data = cities_sf,
            ggplot2::aes(label = city),
            color = text_dark,
            family = "Helvetica",
            fontface = "bold",
            vjust = -1.4,
            size = 3.3
        ) +

        # 5. mapping scales
        ggplot2::scale_color_gradientn(
            colors = c("#1E6B38", "#E6A100", "#B81414"),
            name = "Median wait time\n(min)"
        ) +
        ggplot2::scale_size_continuous(
            range = c(3.5, 9),
            labels = scales::comma,
            name = "Population"
        ) +

        # 6. labels and canvas framing
        ggplot2::labs(
            title = "Waiting times from Bern",
            subtitle = "Circle size shows population. Colour shows median wait time. Labels show the exact minutes.",
            caption = "Red star = Bern origin. Data comes from SwissCities.csv plus the live waiting-time summary."
        ) +
        # custom coordinates view bounding box tailored to your exact city list min/max limits
        ggplot2::coord_sf(xlim = c(6.8, 8.15), ylim = c(46.6, 47.6), expand = FALSE) +

        # 7. custom theme
        ggplot2::theme_minimal(base_family = "Helvetica") +
        ggplot2::theme(
            panel.background = ggplot2::element_rect(fill = bg_cream, color = NA),
            plot.background = ggplot2::element_rect(fill = bg_cream, color = NA),
            panel.grid = ggplot2::element_blank(),

            # text aesthetics
            plot.title = ggplot2::element_text(face = "bold", size = 13, color = text_dark, margin = ggplot2::margin(b = 4)),
            plot.subtitle = ggplot2::element_text(size = 9, color = "gray20", margin = ggplot2::margin(b = 14)),
            plot.caption = ggplot2::element_text(size = 7.5, color = "gray40", face = "italic", margin = ggplot2::margin(t = 12)),

            # legend aesthetics
            legend.title = ggplot2::element_text(face = "bold", size = 8.5, color = text_dark),
            legend.text = ggplot2::element_text(size = 8, color = text_dark),
            legend.position = "right"
        )

    return(ch_map)
}

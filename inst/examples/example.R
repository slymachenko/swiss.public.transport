# swiss.public.transport use example
#
# Demonstrates the full workflow from reading the station data
# to producing the waiting-time accessibility map.
#
# Run with:
# source(system.file(
#   "examples", "run_pipeline.R", package = "swiss.public.transport"
# ))

library(swiss.public.transport)

# Using a temporary directory keeps the user's workspace clean
cache_dir <- "cache"
figs_dir <- file.path("figs")
output_map <- file.path(figs_dir, "waiting_time_map.png")
if (!dir.exists(figs_dir)) {
  dir.create(figs_dir, recursive = TRUE)
  message("Created figs directory: ", figs_dir)
}

# Read regional station data
station_data <- read_station_data(target_group = 2)

# Build the tidy origin-destination-date-time query table
query_table <- build_route_query_table(
  station_data = station_data,
  query_date   = "2026-06-20",
  query_times  = c("07:00", "09:00", "12:00", "16:00", "18:00")
)

# Download (and cache) all route connections
populate_route_cache(query_table, cache_dir = cache_dir)

# Parse all cached responses into one tidy data frame
parsed_queries <- combine_parsed_queries(query_table, cache_dir = cache_dir)

# Compute waiting-time indicatorscache_dir <- "cache"
waiting_times <- compute_waiting_time(parsed_queries)
waiting_summary <- summarise_waiting(waiting_times)

# Plot the waiting-time accessibility map (Fixed: passed target_group = 2)
map <- plot_accessibility_map(waiting_summary, station_data)
print(map)

message("Saving map to: ", getwd(), "/", output_map)
ggplot2::ggsave(output_map, map, width = 8, height = 6, dpi = 300)

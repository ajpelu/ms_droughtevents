library(droughtevents)
library(tidyverse)
library(ggrepel)
library(sf)
library(rnaturalearth)
library(here)
library(patchwork)

# SPEIbase (spei12.nc): https://spei.csic.es/database.html
# Chorology (Pinus_sylvestris_plg.shp): https://doi.org/10.6084/m9.figshare.5091901

sites <- tibble(
  site = c("Sierra de Baza", "Pfynwald", "Hyytiälä"),
  lon = c(-2.85, 7.61, 24.29),
  lat = c(37.38, 46.30, 61.85)
)

# Only to get the spei for sites (once)
r <- terra::rast(here("data/spei12.nc"))
pts <- terra::vect(sites, geom = c("lon", "lat"), crs = "EPSG:4326")
terra::extract(r, pts, ID = FALSE) |>
  t() |>
  as_tibble(.name_repair = ~ sites$site) |>
  mutate(date = as.Date(terra::time(r))) |>
  pivot_longer(-date, names_to = "site", values_to = "spei12") |>
  write_csv(here::here("data/spei12_sites.csv"))


spei1950 <- read_csv(here::here("data/spei12_sites.csv"), show_col_types = FALSE) |>
  filter(date >= as.Date("1950-01-01"))

# Drought events per site
ev12 <- spei1950 |>
  group_split(site) |>
  map_dfr(\(d) droughts(d, vname = "spei12", threshold = -1.28)$drought_assessment |>
    mutate(site = d$site[1]))

ev12 |>
  group_by(site) |>
  summarise(
    n_events = n(),
    mean_duration = mean(d_duration),
    max_duration = max(d_duration),
    mean_severity = mean(d_severity),
    mean_intensity = mean(d_intensity),
    min_peak = min(lowest_spei),
    n_since_1990 = sum(minyear >= 1990)
  )

top5 <- ev12 |>
  group_by(site) |>
  slice_max(d_severity, n = 5) |>
  ungroup()

site_cols <- setNames(c("#c0392b", "#e69f00", "#2c7bb6"), sites$site)

# Map: Caudullo et al. (2017) range clipped to land
sf_use_s2(FALSE)

land <- ne_countries(scale = "medium", returnclass = "sf") |>
  st_union() |>
  st_make_valid()

range_ps <- st_read(here::here("data/Pinus_sylvestris_plg.shp"), quiet = TRUE) |>
  st_zm() |>
  st_transform(4326) |>
  st_make_valid() |>
  st_union() |>
  st_intersection(land) |>
  st_make_valid() |>
  st_transform(3035)

europe <- ne_countries(scale = "medium", returnclass = "sf") |>
  st_make_valid() |>
  st_crop(xmin = -25, ymin = 30, xmax = 45, ymax = 72) |>
  st_transform(3035)

sf_use_s2(TRUE)

sites_sf <- st_as_sf(sites, coords = c("lon", "lat"), crs = 4326) |>
  st_transform(3035)

map_eu <- ggplot() +
  geom_sf(data = europe, fill = "grey92", colour = "grey70", linewidth = 0.2) +
  geom_sf(data = range_ps, fill = "#7fa26b", colour = NA, alpha = 0.7) +
  geom_sf(data = europe, fill = NA, colour = "grey60", linewidth = 0.2) +
  geom_sf_label(
    data = sites_sf, aes(label = site), size = 3,
    hjust = 0, nudge_x = 1.5e5, linewidth = 0,
    fill = alpha("white", 0.8)
  ) +
  geom_sf(
    data = sites_sf, aes(fill = site), shape = 21, size = 3, stroke = 0.6,
    show.legend = FALSE
  ) +
  scale_fill_manual(values = site_cols) +
  coord_sf(crs = 3035, xlim = c(2.5e6, 6.5e6), ylim = c(1.3e6, 5.3e6), expand = FALSE) +
  labs(x = NULL, y = NULL) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid = element_line(colour = "grey85", linewidth = 0.2),
    panel.background = element_rect(fill = "aliceblue", colour = NA)
  )

# Duration-intensity space
p_space <- ggplot(ev12, aes(d_duration, d_intensity)) +
  geom_point(aes(colour = site), alpha = 0.35, size = 1.8) +
  geom_point(data = top5, aes(colour = site, size = d_severity)) +
  geom_text_repel(
    data = top5, aes(label = minyear, colour = site),
    size = 2.8, show.legend = FALSE, max.overlaps = 20
  ) +
  scale_size_continuous(name = "Severity", range = c(2, 6)) +
  scale_colour_manual(name = NULL, values = site_cols) +
  scale_x_continuous(expand = expansion(mult = c(0.05, 0.1))) +
  guides(
    colour = guide_legend(override.aes = list(size = 2.5), order = 1),
    size = guide_legend(order = 2)
  ) +
  labs(x = "Duration (months)", y = "Intensity (mean SPEI-12)") +
  theme_bw(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "inside",
    legend.position.inside = c(0.98, 0.98),
    legend.justification = c(1, 1),
    legend.box = "horizontal",
    legend.background = element_rect(
      fill = alpha("white", 0.85), colour = "grey70", linewidth = 0.3
    ),
    legend.key.size = unit(0.35, "cm"),
    legend.text = element_text(size = 7),
    legend.title = element_text(size = 7),
    legend.spacing.y = unit(0.05, "cm")
  )

# Time series with the five most severe events
plot_site <- function(s, show_x = FALSE) {
  d <- spei1950 |>
    filter(site == s) |>
    select(date, spei12) |>
    as.data.frame()
  da <- ev12 |>
    filter(site == s) |>
    select(-site) |>
    as.data.frame()
  p <- plot_drought_ts(d, vname = "spei12", y_axis_title = "SPEI-12") |>
    add_drought_events(
      drought_assessment = da, which_events = "top",
      metric = "severity", top_n = 5, type = "polygon"
    ) +
    ggtitle(s) +
    theme(
      plot.title = element_text(size = 9, face = "bold", margin = margin(b = 1)),
      plot.margin = margin(1, 5, 1, 5),
      axis.title.y = element_text(size = 8)
    )
  if (!show_x) {
    p <- p + theme(
      axis.text.x = element_blank(),
      axis.title.x = element_blank(),
      axis.ticks.x = element_blank()
    )
  }
  p
}

p_ts <- wrap_plots(
  plot_site("Sierra de Baza"),
  plot_site("Pfynwald"),
  plot_site("Hyytiälä", show_x = TRUE),
  ncol = 1
)

combined_plot <- (map_eu | p_space) / p_ts +
  plot_layout(heights = c(1, 1.4)) +
  plot_annotation(tag_levels = "a") &
  theme(plot.tag = element_text(size = 10, face = "bold"))

ggsave(here::here("output/plot_scots_pine.png"), combined_plot,
  width = 18, height = 18, units = "cm", dpi = 300
)

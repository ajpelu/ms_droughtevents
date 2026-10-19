library(droughtevents)
library(tidyverse)
library(here)

data(spei_granada)
vname <- "spei12"
result <- droughts(spei_granada, vname = vname, threshold = -1.28)


ev <- result$data |>
  dplyr::semi_join(result$drought_assessment, by = "index_events") |>
  group_by(index_events) |>
  summarise(
    start = min(date),
    end = max(date),
    peak = date[which.min(.data[[vname]])],
    .groups = "drop"
  ) |>
  inner_join(
    select(result$drought_assessment, index_events, d_intensity, d_duration, d_severity),
    by = "index_events"
  ) |>
  arrange(desc(start)) |>
  mutate(
    y = row_number(),
    y0 = year(start),
    x_start = month(start),
    x_end = (year(end) - y0) * 12 + month(end),
    x_peak = (year(peak) - y0) * 12 + month(peak),
    label = format(start, "%b %Y"),
    period = if_else(y0 < 1990, "1901–1989", "1990–2024")
  )

n_years <- ceiling(max(ev$x_end) / 12)
n_months <- n_years * 12
month_lab <- rep(c("J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"), n_years)
summers <- tibble(xmin = 12 * (0:(n_years - 1)) + 5.5, xmax = xmin + 3)
yr_lab <- c("Onset year", paste0("Year +", 1:(n_years - 1)))[seq_len(n_years)]

p_cal <- ggplot(ev) +
  geom_rect(
    data = summers, aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
    fill = "#fdf1d8", inherit.aes = FALSE
  ) +
  geom_vline(
    xintercept = seq(12.5, n_months - 0.5, by = 12),
    linetype = "dashed", colour = "grey55", linewidth = 0.3
  ) +
  geom_linerange(aes(y = y, xmin = x_start - 0.5, xmax = x_end + 0.5, colour = d_intensity),
    linewidth = 3.8
  ) +
  geom_point(aes(y = y, x = x_peak, shape = "Peak (min. SPEI)"),
    fill = "white", colour = "black", size = 1.6, stroke = 0.3
  ) +
  geom_text(aes(y = y, x = x_end + 0.9, label = paste0(d_duration, " mo")),
    hjust = 0, size = 2.5, colour = "grey30"
  ) +
  geom_text(
    data = tibble(
      x = seq(6.5, n_months, by = 12), lab = yr_lab,
      period = "1901–1989"
    ),
    aes(x = x, y = Inf, label = lab),
    vjust = -0.8, size = 3, fontface = "bold", inherit.aes = FALSE
  ) +
  scale_x_continuous(
    breaks = 1:n_months, labels = month_lab,
    limits = c(0.5, n_months + 3), expand = c(0, 0)
  ) +
  scale_y_continuous(breaks = ev$y, labels = ev$label, expand = expansion(add = 0.6)) +
  scale_colour_viridis_c(
    option = "rocket", begin = 0.1, end = 0.85,
    name = "Intensity (mean SPEI-12)",
    guide = guide_colourbar(
      title.position = "top",
      barwidth = unit(4, "cm"),
      barheight = unit(0.25, "cm")
    )
  ) +
  scale_shape_manual(values = 21, name = NULL) +
  coord_cartesian(clip = "off") +
  labs(x = "Month (from January of onset year)", y = NULL) +
  theme_bw(base_size = 10) +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(colour = "grey92", linewidth = 0.2),
    panel.spacing.y = unit(0.4, "lines"),
    axis.ticks.y = element_blank(),
    strip.background = element_blank(),
    strip.text.y = element_text(angle = 0, face = "bold", hjust = 0),
    legend.position = "bottom",
    plot.margin = margin(15, 5, 5, 5)
  ) +
  facet_grid(period ~ ., scales = "free_y", space = "free_y")

p_cal


ggsave(here::here("output/fig_drought_calendar.png"), p_cal,
  width = 15, height = 14, units = "cm", dpi = 300
)
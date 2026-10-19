library(droughtevents)
library(tidyverse)
library(patchwork)

data(spei_granada)

result <- droughts(spei_granada, vname = "spei12", threshold = -1.28, min_duration = 2)
result$drought_assessment

p <- plot_drought_ts(spei_granada, vname = "spei12", y_axis_title = "SPEI-12")

p_a <- p +
  geom_hline(yintercept = -1.28, linetype = "dashed", linewidth = 0.4) +
  ggtitle("SPEI-12 time series and threshold")

p_b <- add_drought_events(p, drought_assessment = result$drought_assessment,
                          which_events = "all", type = "polygon") +
  ggtitle("All detected drought events")

p_c <- add_drought_events(p, drought_assessment = result$drought_assessment,
                          which_events = "top", metric = "severity",
                          top_n = 5, type = "both") +
  ggtitle("Five most severe events")


no_x <- theme(
  axis.text.x = element_blank(),
  axis.title.x = element_blank(),
  axis.ticks.x = element_blank()
)

plot_spei_granada <- (p_a + no_x) / (p_b + no_x) / p_c +
  plot_annotation(tag_levels = "a") &
  theme(
    plot.title = element_text(size = 10, margin = margin(b = 2)),
    plot.margin = margin(2, 5, 2, 5)
  )

ggsave(here::here("output/fig_spei_granada.png"),
       plot_spei_granada, width = 22, height = 15,
       units = "cm", dpi = 300)
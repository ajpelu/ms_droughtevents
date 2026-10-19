# Code and data for: *droughtevents: an R package to identify, characterise and visualise drought events from standardised indices*

This repository contains the code and data needed to reproduce the application examples and figures of the manuscript. All analyses use the R package **droughtevents** (v0.1.0), available on CRAN.

## Repository structure

```
.
├── plots.R                    # Runs all scripts and generates all figures
├── plot_spei_granada.R        # Example 1: drought events in Granada
├── plot_calendar_drought.R    # Example 1: timing of drought events in Granada
├── plot_scot_pine.R           # Example 2: drought regimes at three Scots pine sites
├── data/
│   ├── spei12_sites.csv       # SPEI-12 series extracted for the three Scots pine sites
│   └── Pinus_sylvestris_*     # Distribution of Pinus sylvestris (shapefiles)
└── output/                    # Figures
```

## Requirements

R (≥ 4.1) and the following packages:

```r
install.packages(c("droughtevents", "tidyverse", "patchwork", "ggrepel",
                   "sf", "rnaturalearth", "terra", "here"))
```

## How to reproduce the figures

Open `ms_droughtevents.Rproj` and run:

```r
source("plots.R")
```

Figures are saved in `output/`:

| Script | Figure | Output |
|---|---|---|
| `plot_spei_granada.R` | Detection of drought events in Granada | `fig_spei_granada.png` |
| `plot_calendar_drought.R` | Timing of drought events in Granada | `fig_drought_calendar.png` |
| `plot_scot_pine.R` | Drought regimes at three Scots pine sites | `plot_scots_pine.png` |

## Data

- **Example 1** uses the `spei_granada` dataset included in the droughtevents package. No external data are required.
- **Example 2** uses:
  - Monthly SPEI-12 series for Sierra de Baza (Spain), Pfynwald (Switzerland) and Hyytiälä (Finland). The global SPEI-12 NetCDF file (`spei12.nc`) was downloaded from SPEIbase (Beguería et al., 2014; https://spei.csic.es/database.html; version [2.11], accessed [September 2026]), and the series of the grid cells containing each site were extracted with `plot_scot_pine.R` and saved in `data/spei12_sites.csv`. The NetCDF file (~360 MB) is not included in this repository because of its size. It is only needed to regenerate `spei12_sites.csv`: download it from SPEIbase and place it in `data/`.
  - The chorological map of *Pinus sylvestris* from the European Atlas of Forest Tree Species (Caudullo et al., 2017; https://doi.org/10.6084/m9.figshare.5091901).
  - Country boundaries from Natural Earth, accessed through the R package rnaturalearth.

## References

Beguería, S., Vicente-Serrano, S. M., Reig, F., & Latorre, B. (2014). Standardized precipitation evapotranspiration index (SPEI) revisited: Parameter fitting, evapotranspiration models, tools, datasets and drought monitoring. *International Journal of Climatology*, 34(10), 3001–3023. https://doi.org/10.1002/joc.3887

Caudullo, G., Welk, E., & San-Miguel-Ayanz, J. (2017). Chorological maps for the main European woody species. *Data in Brief*, 12, 662–666. https://doi.org/10.1016/j.dib.2017.05.007

## Licence

Code is released under the MIT licence. Third-party data are subject to the licences of their original sources.

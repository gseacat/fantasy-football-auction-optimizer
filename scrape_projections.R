# -------------------------------------------------------------------------------------------
# Fantasy Football Projection Scraper
# Author: Graham Seacat
#
# Date: 7-29-25
#
# Description:
#   - Scrape 2025 player projections using ffanalytics
#
#  ------------------------------------------------------------------------------------------



### Install & load packages
if (!requireNamespace("remotes")) install.packages("remotes")
remotes::install_github("FantasyFootballAnalytics/ffanalytics")

library(rvest)
library(ffanalytics)
library(tidyverse)


### Scrape 2025 projections
scrape_2025 <- scrape_data(
  pos = c("QB", "RB", "WR", "TE"),
  season = 2025,
  week = 0
)

### Extract positions
QB_df <- as_tibble(scrape_2025$QB)
RB_df <- as_tibble(scrape_2025$RB)
WR_df <- as_tibble(scrape_2025$WR)
TE_df <- as_tibble(scrape_2025$TE)

### Get unique player names
names <- bind_rows(QB_df, RB_df, WR_df, TE_df) %>%
  filter(data_src == "FantasyPros") %>%
  select(id, player, team, pos)

### Average projections across sources
combined_df <- bind_rows(QB_df, RB_df, WR_df, TE_df) %>%
  relocate(id) %>%
  select(-games, -player, -team, -pos, -site_pts, -site_fppg,
         -src_id, -data_src, -bye) %>%
  group_by(id) %>%
  summarise(across(pass_att:rec_200_yds, \(x) mean(x, na.rm = TRUE)),
            .groups = "drop") %>%
  inner_join(names, by = "id") %>%
  relocate(player, team, pos, .after = "id")


### Calculate Standard, Half-PPR, and PPR scoring
df <- combined_df %>% 
  # Calculate projected points using FH Old Balls standard scoring
  mutate(standard_points = 
           # Touchdowns
           coalesce(pass_tds, 0) * 4 +
           coalesce(rush_tds, 0) * 6 +
           coalesce(rec_tds, 0) * 6 +
           # coalesce(return_tds, 0) * 6 +
           
           # Passing yards & interceptions
           coalesce(pass_yds, 0) * 0.04 +
           coalesce(pass_int, 0) * -1 +
           
           # Rushing and Receiving yards
           coalesce(rush_yds, 0) * 0.1 +
           coalesce(rec_yds, 0) * 0.1 +
           
           # Fumbles
           coalesce(fumbles_lost, 0) * -2
  ) %>% 
  mutate(
    ## Half-PPR
    half_ppr_points = standard_points + 
      # Receptions 
      coalesce(rec, 0) * 0.5,
    ppr_points = standard_points +
      # Receptions
      coalesce(rec, 0) * 1) %>% 
  
  ## Round points to 2 digits
  mutate(
    standard_points = round(standard_points, digits = 2),
    half_ppr_points = round(half_ppr_points, digits = 2),
    ppr_points = round(ppr_points, digits = 2)
  ) %>% 
  arrange(desc(half_ppr_points)) %>% 
  # Select only the necessary columns for GitHub project
  select(player, team, pos, standard_points, half_ppr_points, ppr_points)

# -------------------------------------------------------------------------------------------
# Example Usage Script for Fantasy Football Auction Draft Optimizer
# Author: Graham Seacat
#
# Date: 8-1-25
#
# Description:
#   - Loads projections and auction values
#   - Applies optional top-tier value adjustments
#   - Adjusts budget for bench/K/DST
#   - Runs the optimizer with a sample configuration
#   - Displays the optimal roster and summary stats
# -------------------------------------------------------------------------------------------

# Load required libraries
library(tidyverse)
library(Rglpk)

# Source the optimizer function
source("R/auction_draft_optimizer.R")

# Load input data
proj <- read_csv("data/projections_2025_ffanalytics.csv")
values <- read_csv("data/auction_values_2025_all.csv")

# Join projections with auction values
auction_data <- proj %>%
  left_join(values, by = c("player", "team", "pos", "scoring")) %>%
  mutate(value = ifelse(is.na(value), 1, value))

# Optional: boost top-tier player auction values to reflect real draft behavior
adjust_top_values <- function(data, position, top_n = 5, multiplier = 1.5) {
  data <- data %>%
    group_by(scoring, pos) %>%
    arrange(desc(points), .by_group = TRUE) %>%
    mutate(value = if_else(pos == position & row_number() <= top_n,
                           round(value * multiplier, digits = 0),
                           value)) %>%
    ungroup()
  return(data)
}

# Apply 50% increase to top 5 RB's and 25% increase to top 5 WR's
auction_data_values_adjusted <- auction_data %>%
  filter(scoring == "Half-PPR", teams == 12) %>% 
  adjust_top_values("RB", top_n = 5, multiplier = 1.5) %>%
  adjust_top_values("WR", top_n = 5, multiplier = 1.25) %>%
  arrange(desc(points))

check <- auction_data_values_adjusted %>% 
  filter(pos == "RB")

# Define draft and roster settings
total_roster_size <- 16         # Full roster including bench, K, DST
starter_roster_size <- 7        # Number of starters optimized
min_cost_per_extra_player <- 1  # Minimum cost per bench/K/DST player

# Adjust budget to account for required $1 bids on remaining players
reserved_budget <- (total_roster_size - starter_roster_size) * min_cost_per_extra_player
available_budget <- 200 - reserved_budget

# Show message to user about budget adjustment
message(glue::glue(
  "Adjusted budget from $200 → ${available_budget} to reserve ${reserved_budget} for ",
  "{total_roster_size - starter_roster_size} bench/K/DST spots at $1 each."
))

# Define and run optimizer
result <- optimize_auction_roster(
  data = auction_data_values_adjusted,
  budget = available_budget,
  roster_size = 7,
  teams = 12,
  scoring = "Half-PPR",
  pos_limits = tribble(
    ~pos, ~min, ~max,
    "QB", 1, 1,
    "RB", 2, 3,
    "WR", 2, 3,
    "TE", 1, 2
  )
)

# Output results
print(result$roster)
print(result$totals)

# -------------------------------------------------------------------------------------------
# Fantasy Football Auction Draft Optimizer
# Author: Graham Seacat
#
# Date: 8-1-25
#
# Description:
#   - Optimize roster for auction draft using salary and position constraints.
#
#  ------------------------------------------------------------------------------------------

## Load packages
if (!requireNamespace("Rglpk")) install.packages("Rglpk")
library(Rglpk)
library(tidyverse)

## Load projections and auction values
proj <- read_csv("data/projections_2025_ffanalytics.csv")
values <- read_csv("data/auction_values_2025_all.csv")

## Inner join by player name and team/position if needed
auction_data <- proj %>%
  left_join(values, by = c("player", "team", "pos", "scoring")) %>% 
  # Any NA values were $1 or $0 (replace with $1 since that is the minimum value per player)
  mutate(value = ifelse(is.na(value), 1, value))


## Function to optimize auction roster (maximize the points the starters are projected to score)
optimize_auction_roster <- function(data, 
                                    budget = 200,
                                    roster_size = 7,
                                    teams = 12,
                                    scoring = "Half-PPR",
                                    pos_limits = tribble(
                                      ~pos, ~min, ~max,
                                      "QB", 1, 1,
                                      "RB", 2, 3,
                                      "WR", 2, 3,
                                      "TE", 1, 2
                                    )) {
  data <- data %>% 
    filter(teams == !!teams, scoring == !!scoring) %>% 
    select(player, team, pos, points, value)
  
  n <- nrow(data)
  if (n == 0) stop("No players found for the given settings.")
  
  obj <- data$points
  cost <- matrix(data$value, nrow = 1)
  
  pos_list <- unique(pos_limits$pos)
  pos_mat <- sapply(pos_list, function(p) as.integer(data$pos == p))
  if (is.null(dim(pos_mat))) pos_mat <- matrix(pos_mat, ncol = 1)
  colnames(pos_mat) <- pos_list
  
  mat <- rbind(
    cost,
    rep(1, n),
    t(pos_mat),
    -t(pos_mat)
  )
  
  dir <- c(
    "<=",
    "==",
    rep("<=", ncol(pos_mat)),
    rep("<=", ncol(pos_mat))
  )
  
  rhs <- c(
    budget,
    roster_size,
    pos_limits$max,
    -pos_limits$min
  )
  
  sol <- Rglpk_solve_LP(
    obj = obj,
    mat = mat,
    dir = dir,
    rhs = rhs,
    types = rep("B", n),
    max = TRUE
  )
  
  team <- data[sol$solution == 1, ] %>%
    arrange(desc(points))
  
  team_totals <- team %>%
    summarise(
      total_points = sum(points),
      total_cost = sum(value)
    )
  
  list(
    roster = team,
    totals = team_totals
  )
}

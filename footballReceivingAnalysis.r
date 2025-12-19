############################################################
# NFL Receiving (PBP-derived): WR-only YAC/Rec vs aDOT
# - Color by season
# - Label extreme YAC WRs
# - Robust roster join (auto-detects ID column)
############################################################

library(nflreadr)
library(dplyr)
library(ggplot2)
library(janitor)
library(plotly)
library(ggrepel)

# ---- Settings ----
seasons <- c(2023, 2024)
min_targets <- 40
top_n_labels <- 8

# ---- Load play-by-play ----
pbp <- load_pbp(seasons) %>%
  clean_names()

recv_pbp <- pbp %>%
  filter(
    play_type == "pass",
    !is.na(receiver_player_id),
    !is.na(receiver_player_name)
  )

# ---- Aggregate to player-season ----
receiving_total <- recv_pbp %>%
  group_by(season, receiver_player_id, receiver_player_name, posteam) %>%
  summarise(
    targets = n(),
    receptions = sum(complete_pass == 1, na.rm = TRUE),
    yards = sum(receiving_yards, na.rm = TRUE),
    air = sum(air_yards, na.rm = TRUE),
    yac = sum(yards_after_catch, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(targets >= min_targets, receptions > 0) %>%
  mutate(
    adot = air / targets,
    yac_per_rec = yac / receptions
  )

# ---- Load rosters ----
rosters <- load_rosters(seasons) %>%
  clean_names()

# ---- AUTO-detect the player ID column in rosters ----
possible_id_cols <- c("player_id", "gsis_id", "gameday_player_id", "gsisp_id")
roster_id_col <- intersect(possible_id_cols, colnames(rosters))[1]

if (is.na(roster_id_col)) {
  stop("No compatible player ID column found in rosters.")
}

# Keep only ID + position
rosters_small <- rosters %>%
  select(all_of(roster_id_col), position)

# ---- Join + WR filter ----
receiving_wr <- receiving_total %>%
  left_join(
    rosters_small,
    by = setNames(roster_id_col, "receiver_player_id")
  ) %>%
  filter(position == "WR")

# ---- Extremes: highest YAC/Rec WRs ----
top_yac_wr <- receiving_wr %>%
  arrange(desc(yac_per_rec)) %>%
  slice_head(n = top_n_labels)

# ---- Plot ----
plot_yac_adot_wr <- ggplot(
  receiving_wr,
  aes(
    x = adot,
    y = yac_per_rec,
    color = factor(season),
    text = paste(
      "Player:", receiver_player_name,
      "<br>Team:", posteam,
      "<br>Season:", season,
      "<br>Targets:", targets,
      "<br>Receptions:", receptions,
      "<br>aDOT:", round(adot, 2),
      "<br>YAC/Rec:", round(yac_per_rec, 2)
    )
  )
) +
  geom_point(alpha = 0.75) +
  geom_smooth(method = "lm", se = FALSE) +
  geom_text_repel(
    data = top_yac_wr,
    aes(label = receiver_player_name),
    size = 3,
    show.legend = FALSE
  ) +
  labs(
    title = "WR-only: YAC per Reception vs aDOT (After-Catch Style vs Depth)",
    x = "aDOT (Air Yards / Target)",
    y = "YAC per Reception",
    color = "Season"
  ) +
  theme_minimal()

ggplotly(plot_yac_adot_wr, tooltip = "text")

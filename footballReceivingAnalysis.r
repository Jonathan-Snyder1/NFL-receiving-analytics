############################################################
# NFL Receiving (PBP-derived): YAC/Rec vs aDOT (Interactive)
############################################################

# install.packages(c("nflreadr","dplyr","ggplot2","janitor","plotly"))
library(nflreadr)
library(dplyr)
library(ggplot2)
library(janitor)
library(plotly)

# ---- Settings ----
seasons <- c(2023, 2024)
min_targets <- 40

# ---- Load play-by-play (this is bigger than player_stats) ----
pbp <- load_pbp(seasons) %>%
  clean_names()

# Keep only completed or targeted pass plays with a receiver
# (targets are pass attempts with a receiver; receptions are completions to that receiver)
recv_pbp <- pbp %>%
  filter(
    play_type == "pass",
    !is.na(receiver_player_id),
    !is.na(receiver_player_name)
  )

# ---- Aggregate to player-season totals ----
receiving_total <- recv_pbp %>%
  group_by(season, receiver_player_id, receiver_player_name, posteam) %>%
  summarise(
    targets = n(),  # every targeted pass to that receiver
    receptions = sum(complete_pass == 1, na.rm = TRUE),
    yards = sum(receiving_yards, na.rm = TRUE),
    # air_yards and yac exist in pbp for most passes; use na.rm=TRUE
    air = sum(air_yards, na.rm = TRUE),
    yac = sum(yards_after_catch, na.rm = TRUE),
    touchdowns = sum(pass_touchdown == 1 & complete_pass == 1, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  # Minimum volume + avoid divide-by-zero
  filter(targets >= min_targets, receptions > 0) %>%
  mutate(
    adot = air / targets,
    yac_per_rec = yac / receptions
  )

# ---- Sanity checks (prints in console) ----
cat("Rows:", nrow(receiving_total), "\n")
cat("Any NA adot?:", sum(is.na(receiving_total$adot)), "\n")
cat("Any NA yac_per_rec?:", sum(is.na(receiving_total$yac_per_rec)), "\n")
print(head(receiving_total))

# ---- Plot: YAC per Reception vs aDOT (interactive hover) ----
plot_yac_adot <- ggplot(
  receiving_total,
  aes(
    x = adot,
    y = yac_per_rec,
    text = paste(
      "Player:", receiver_player_name,
      "<br>Team:", posteam,
      "<br>Season:", season,
      "<br>Targets:", targets,
      "<br>Receptions:", receptions,
      "<br>Yards:", yards,
      "<br>aDOT:", round(adot, 2),
      "<br>YAC/Rec:", round(yac_per_rec, 2)
    )
  )
) +
  geom_point(alpha = 0.7) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(
    title = "YAC per Reception vs aDOT (After-Catch Style vs Depth)",
    x = "aDOT (Air Yards / Target)",
    y = "YAC per Reception"
  ) +
  theme_minimal()

ggplotly(plot_yac_adot, tooltip = "text")

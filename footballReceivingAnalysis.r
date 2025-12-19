############################################################
# NFL Receiving (PBP-derived): WR-only Advanced Analytics
# - YAC/Rec vs aDOT (interactive, colored by season, label extremes)
# - Adds: target share, air yards share, YAC Over Expected (YACOE)
# - New chart: YACOE vs Target Share (interactive)
############################################################

# install.packages(c("nflreadr","dplyr","ggplot2","janitor","plotly","ggrepel"))
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

# ---- Aggregate to player-season totals ----
receiving_total <- recv_pbp %>%
  group_by(season, receiver_player_id, receiver_player_name, posteam) %>%
  summarise(
    targets = n(),
    receptions = sum(complete_pass == 1, na.rm = TRUE),
    yards = sum(receiving_yards, na.rm = TRUE),
    air = sum(air_yards, na.rm = TRUE),
    yac = sum(yards_after_catch, na.rm = TRUE),
    touchdowns = sum(pass_touchdown == 1 & complete_pass == 1, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(targets >= min_targets, receptions > 0) %>%
  mutate(
    catch_rate = receptions / targets,
    yards_per_target = yards / targets,
    yards_per_rec = yards / receptions,
    adot = air / targets,
    yac_per_rec = yac / receptions
  ) %>%
  filter(!is.na(adot), !is.na(yac_per_rec))

# ---- Load rosters + WR filter (robust ID detection) ----
rosters <- load_rosters(seasons) %>%
  clean_names()

possible_id_cols <- c("player_id", "gsis_id", "gameday_player_id", "gsisp_id")
roster_id_col <- intersect(possible_id_cols, colnames(rosters))[1]
if (is.na(roster_id_col)) stop("No compatible player ID column found in rosters.")

rosters_small <- rosters %>%
  select(all_of(roster_id_col), position)

receiving_wr <- receiving_total %>%
  left_join(rosters_small, by = setNames(roster_id_col, "receiver_player_id")) %>%
  filter(position == "WR")

# ==========================================================
# ADVANCED METRICS
# ==========================================================

# ---- Target Share ----
team_targets <- receiving_wr %>%
  group_by(season, posteam) %>%
  summarise(team_targets = sum(targets), .groups = "drop")

receiving_wr <- receiving_wr %>%
  left_join(team_targets, by = c("season", "posteam")) %>%
  mutate(target_share = targets / team_targets)

# ---- Air Yards Share ----
team_air <- receiving_wr %>%
  group_by(season, posteam) %>%
  summarise(team_air_yards = sum(air), .groups = "drop")

receiving_wr <- receiving_wr %>%
  left_join(team_air, by = c("season", "posteam")) %>%
  mutate(air_yards_share = air / team_air_yards)

# ---- YAC Over Expected (YACOE) using a simple expected-YAC model from aDOT ----
yac_model <- lm(yac_per_rec ~ adot, data = receiving_wr)

receiving_wr <- receiving_wr %>%
  mutate(
    expected_yac = predict(yac_model, newdata = receiving_wr),
    yac_over_expected = yac_per_rec - expected_yac
  )

# ==========================================================
# CHART 1: WR-only YAC/Rec vs aDOT (interactive)
# ==========================================================

top_yac_wr <- receiving_wr %>%
  arrange(desc(yac_per_rec)) %>%
  slice_head(n = top_n_labels)

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
      "<br>aDOT:", round(adot, 2),
      "<br>YAC/Rec:", round(yac_per_rec, 2),
      "<br>Target Share:", round(100 * target_share, 1), "%"
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

# ==========================================================
# CHART 2 (NEW): YACOE vs Target Share (interactive)
# ==========================================================


plot_yacoe_share <- ggplot(
  receiving_wr,
  aes(
    x = target_share,
    y = yac_over_expected,
    color = factor(season),
    text = paste(
      "Player:", receiver_player_name,
      "<br>Team:", posteam,
      "<br>Season:", season,
      "<br>Targets:", targets,
      "<br>Target Share:", round(100 * target_share, 1), "%",
      "<br>aDOT:", round(adot, 2),
      "<br>YAC/Rec:", round(yac_per_rec, 2),
      "<br>Exp YAC/Rec:", round(expected_yac, 2),
      "<br>YACOE:", round(yac_over_expected, 2)
    )
  )
) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_point(alpha = 0.75) +
  labs(
    title = "WR-only: YAC Over Expected (YACOE) vs Target Share",
    x = "Target Share (Targets / Team Targets)",
    y = "YAC Over Expected (YAC/Rec - Expected)",
    color = "Season"
  ) +
  theme_minimal()

ggplotly(plot_yacoe_share, tooltip = "text")

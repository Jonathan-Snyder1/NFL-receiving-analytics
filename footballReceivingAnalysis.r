############################################################
# WR Receiving Analytics (PBP-derived) — Clean Version
# Adds:
#   1) Efficiency-Adjusted Volume (EAV) score
#   2) WR Archetype clustering with human-readable labels:
#        - Deep Threat (vertical)
#        - YAC Specialist (space creator)
#        - Alpha Volume (WR1 usage)
#        - Balanced / Possession
############################################################

# install.packages(c("nflreadr","dplyr","ggplot2","janitor","plotly","ggrepel"))
library(nflreadr)
library(dplyr)
library(ggplot2)
library(janitor)
library(plotly)
library(ggrepel)

# ----------------------------
# Settings
# ----------------------------
SEASONS <- c(2024)
#SEASONS <- c(2023, 2024)


MIN_TARGETS <- 50
K_CLUSTERS <- 4
LABEL_TOP_N_YAC <- 8
LABEL_TOP_N_EAV <- 8

# ----------------------------
# 1) Build WR dataset from PBP
# ----------------------------
pbp <- load_pbp(SEASONS) %>% clean_names()

wr_pbp <- pbp %>%
  filter(
    play_type == "pass",
    !is.na(receiver_player_id),
    !is.na(receiver_player_name)
  )

player_season <- wr_pbp %>%
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
  filter(targets >= MIN_TARGETS, receptions > 0) %>%
  mutate(
    catch_rate = receptions / targets,
    yards_per_target = yards / targets,
    yards_per_rec = yards / receptions,
    adot = air / targets,
    yac_per_rec = yac / receptions
  ) %>%
  filter(!is.na(adot), !is.na(yac_per_rec))

# Roster join (robustly detect ID col)
rosters <- load_rosters(SEASONS) %>% clean_names()

possible_id_cols <- c("player_id", "gsis_id", "gameday_player_id", "gsisp_id")
roster_id_col <- intersect(possible_id_cols, colnames(rosters))[1]
if (is.na(roster_id_col)) stop("No compatible player ID column found in rosters.")

rosters_small <- rosters %>%
  select(all_of(roster_id_col), position)

receiving_wr <- player_season %>%
  left_join(rosters_small, by = setNames(roster_id_col, "receiver_player_id")) %>%
  filter(position == "WR")

# ----------------------------
# 2) Team context metrics: target share + air yards share
# ----------------------------
team_targets <- receiving_wr %>%
  group_by(season, posteam) %>%
  summarise(team_targets = sum(targets), .groups = "drop")

team_air <- receiving_wr %>%
  group_by(season, posteam) %>%
  summarise(team_air = sum(air), .groups = "drop")

receiving_wr <- receiving_wr %>%
  left_join(team_targets, by = c("season", "posteam")) %>%
  left_join(team_air, by = c("season", "posteam")) %>%
  mutate(
    target_share = targets / team_targets,
    air_yards_share = air / team_air
  )

# ----------------------------
# 3) YAC Over Expected (YACOE) from aDOT
# ----------------------------
yac_model <- lm(yac_per_rec ~ adot, data = receiving_wr)

receiving_wr <- receiving_wr %>%
  mutate(
    expected_yac = predict(yac_model, newdata = receiving_wr),
    yac_over_expected = yac_per_rec - expected_yac
  )

# ----------------------------
# 4) Efficiency-Adjusted Volume (EAV) score
#    (z-weighted mix of usage + efficiency)
# ----------------------------
receiving_wr <- receiving_wr %>%
  mutate(
    z_target_share = as.numeric(scale(target_share)),
    z_ypt = as.numeric(scale(yards_per_target)),
    z_catch = as.numeric(scale(catch_rate)),
    z_yacoe = as.numeric(scale(yac_over_expected)),
    eav_score = 0.40 * z_target_share +
      0.25 * z_ypt +
      0.20 * z_catch +
      0.15 * z_yacoe
  )

# ============================================================
# 5) Archetype clustering + automatic human-readable labels
#    Features: aDOT, YAC/Rec, target_share, air_yards_share
# ============================================================

# Keep only complete rows for clustering
cluster_df <- receiving_wr %>%
  select(adot, yac_per_rec, target_share, air_yards_share) %>%
  filter(if_all(everything(), ~ !is.na(.)))

# Scale for kmeans
X <- scale(cluster_df)

set.seed(42)
km <- kmeans(X, centers = K_CLUSTERS, nstart = 25)

# Convert cluster centers back to original units for interpretation
centers_scaled <- km$centers
centers_unscaled <- sweep(centers_scaled, 2, attr(X, "scaled:scale"), `*`)
centers_unscaled <- sweep(centers_unscaled, 2, attr(X, "scaled:center"), `+`)
centers <- as.data.frame(centers_unscaled)
centers$cluster_id <- 1:K_CLUSTERS

# ----- Assign archetype names based on center characteristics -----
# Rules:
# - Deep Threat: highest aDOT AND high air_yards_share
# - YAC Specialist: lowest aDOT AND highest yac_per_rec
# - Alpha Volume: highest target_share (remaining)
# - Balanced/Possession: leftover cluster

deep_id <- centers %>%
  mutate(score = adot + air_yards_share) %>%
  arrange(desc(score)) %>%
  slice(1) %>%
  pull(cluster_id)

yac_id <- centers %>%
  mutate(score = (-adot) + yac_per_rec) %>%
  arrange(desc(score)) %>%
  slice(1) %>%
  pull(cluster_id)

remaining <- setdiff(1:K_CLUSTERS, c(deep_id, yac_id))

alpha_id <- centers %>%
  filter(cluster_id %in% remaining) %>%
  arrange(desc(target_share)) %>%
  slice(1) %>%
  pull(cluster_id)

balanced_id <- setdiff(1:K_CLUSTERS, c(deep_id, yac_id, alpha_id))

cluster_map <- tibble(
  cluster_id = 1:K_CLUSTERS,
  archetype = case_when(
    cluster_id == deep_id ~ "Deep Threat (vertical)",
    cluster_id == yac_id ~ "YAC Specialist (space creator)",
    cluster_id == alpha_id ~ "Alpha Volume (WR1 usage)",
    cluster_id == balanced_id ~ "Balanced / Possession",
    TRUE ~ "Balanced / Possession"
  )
)

# Attach cluster id back to receiving_wr (row-aligned to cluster_df)
# We create a row key so we only assign clusters where complete cases exist.
receiving_wr <- receiving_wr %>%
  mutate(.row_id = row_number())

cluster_rows <- receiving_wr %>%
  select(.row_id, adot, yac_per_rec, target_share, air_yards_share) %>%
  filter(if_all(c(adot, yac_per_rec, target_share, air_yards_share), ~ !is.na(.)))

cluster_rows$cluster_id <- km$cluster

receiving_wr <- receiving_wr %>%
  left_join(cluster_rows %>% select(.row_id, cluster_id), by = ".row_id") %>%
  left_join(cluster_map, by = "cluster_id") %>%
  select(-.row_id)

# ============================================================
# 6) Charts
# ============================================================

# A) Interactive: YAC/Rec vs aDOT (colored by season, label top YAC/Rec)
top_yac_wr <- receiving_wr %>%
  arrange(desc(yac_per_rec)) %>%
  slice_head(n = LABEL_TOP_N_YAC)

p_yac_adot <- ggplot(
  receiving_wr,
  aes(
    x = adot,
    y = yac_per_rec,
    color = factor(season),
    text = paste(
      "Player:", receiver_player_name,
      "<br>Team:", posteam,
      "<br>Season:", season,
      "<br>Archetype:", ifelse(is.na(archetype), "NA", archetype),
      "<br>Targets:", targets,
      "<br>aDOT:", round(adot, 2),
      "<br>YAC/Rec:", round(yac_per_rec, 2),
      "<br>Target Share:", round(100 * target_share, 1), "%",
      "<br>EAV Score:", round(eav_score, 2)
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
    title = "WR-only: YAC per Reception vs aDOT (colored by season)",
    x = "aDOT (Air Yards / Target)",
    y = "YAC per Reception",
    color = "Season"
  ) +
  theme_minimal()

ggplotly(p_yac_adot, tooltip = "text")

# B) Interactive: YACOE vs Target Share (colored by season)
p_yacoe_share <- ggplot(
  receiving_wr,
  aes(
    x = target_share,
    y = yac_over_expected,
    color = factor(season),
    text = paste(
      "Player:", receiver_player_name,
      "<br>Team:", posteam,
      "<br>Season:", season,
      "<br>Archetype:", ifelse(is.na(archetype), "NA", archetype),
      "<br>Targets:", targets,
      "<br>Target Share:", round(100 * target_share, 1), "%",
      "<br>aDOT:", round(adot, 2),
      "<br>YAC/Rec:", round(yac_per_rec, 2),
      "<br>Exp YAC/Rec:", round(expected_yac, 2),
      "<br>YACOE:", round(yac_over_expected, 2),
      "<br>EAV Score:", round(eav_score, 2)
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

ggplotly(p_yacoe_share, tooltip = "text")

# C) Interactive Archetype map: aDOT vs YAC/Rec colored by archetype + label top EAV
top_eav_wr <- receiving_wr %>%
  filter(!is.na(archetype)) %>%
  arrange(desc(eav_score)) %>%
  slice_head(n = LABEL_TOP_N_EAV)

p_arch <- ggplot(
  receiving_wr %>% filter(!is.na(archetype)),
  aes(
    x = adot,
    y = yac_per_rec,
    color = archetype,
    text = paste(
      "Player:", receiver_player_name,
      "<br>Team:", posteam,
      "<br>Season:", season,
      "<br>Archetype:", archetype,
      "<br>Targets:", targets,
      "<br>Target Share:", round(100 * target_share, 1), "%",
      "<br>AirYds Share:", round(100 * air_yards_share, 1), "%",
      "<br>aDOT:", round(adot, 2),
      "<br>YAC/Rec:", round(yac_per_rec, 2),
      "<br>YACOE:", round(yac_over_expected, 2),
      "<br>EAV Score:", round(eav_score, 2)
    )
  )
) +
  geom_point(alpha = 0.75) +
  geom_text_repel(
    data = top_eav_wr,
    aes(label = receiver_player_name),
    size = 3,
    show.legend = FALSE
  ) +
  labs(
    title = "WR Archetypes (K-means) — labeled by top EAV score",
    x = "aDOT",
    y = "YAC per Reception",
    color = "Archetype"
  ) +
  theme_minimal()

ggplotly(p_arch, tooltip = "text")

# ============================================================
# 7) Optional: quick archetype summary table for README
# ============================================================
archetype_summary <- receiving_wr %>%
  filter(!is.na(archetype)) %>%
  group_by(archetype) %>%
  summarise(
    n_players = n(),
    avg_adot = mean(adot, na.rm = TRUE),
    avg_yac_per_rec = mean(yac_per_rec, na.rm = TRUE),
    avg_target_share = mean(target_share, na.rm = TRUE),
    avg_air_share = mean(air_yards_share, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(n_players))

print(archetype_summary)

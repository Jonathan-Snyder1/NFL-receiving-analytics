# NFL WR Receiving Analysis (R)

# 1. Project Overview:
-This project analyzes NFL wide receiver performance using play by play data from 2023 through 2024 seasons (mainly stats like depth of target, yards after catch, etc) to derive advanced receiving metrics and identify receiver archetypes.

# 2. Data Source:
   -Source: Data pulled from nflreadr
   -Ho, T., & Carl, S. (2025). nflreadr: Download 'nflverse' Data (R package version 1.5.0.9000). https://github.com/nflverse/nflreadr
   -Seasons: 2023-2024
   -Oficial NFL PBP data
   -Aggregated to player-season level
   -RBs and TEs excluced (only wr)

# 3. Data Processing and Feature
   -Aggregation:
     *pass plays filtered,
     *player-season aggregation
     *minimum target threshold
   -Derived Metrics:
     *Targets, receptions, yards
     *Catch rate
     *Yards per target
     *aDOT (average depth of target)
     *YAC per reception
     *Target share
     *Air yards share

# 4. Advanced Metrics
  -YACOE (YAC over expected)
    * Expected YAC modeled from aDOT
    * Difference between actual and expected YAC
    * Interpretation of positive vs negative values
  -EAV Score (Effiency-Adjusted Volume)
    * Composotie metric combining usage and effiency 
    * Z-scored componenents
    * Purpose: identify WRs who combine role + performance

  # 5. Receiver Archetype Modeling
    -
   



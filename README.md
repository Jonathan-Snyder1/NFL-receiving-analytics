# NFL WR Receiving Analysis (R)

# 1. Project Overview:
-This project analyzes NFL wide receiver performance using play by play data from 2023 through 2024 seasons (mainly stats like depth of target, yards after catch, etc) to derive advanced receiving metrics and identify receiver archetypes.

# 2. Data Source:
      -Source: Data pulled from nflreadr
      -Ho, T., & Carl, S. (2025). nflreadr: Download 'nflverse' Data (R package version 1.5.0.9000). https://github.com/nflverse/nflreadr
      -Seasons: 2023-2024
      -Official NFL PBP data
      -Aggregated to player-season level
      -RBs and TEs excluced (only wr)
# 3. How to use 
      1. Install required packages
      2. Run main r script
      3. Interactive plots render in RStudio Viewer

# 4. Data Processing and Feature
   ## Aggregation:
     -pass plays filtered,
     -player-season aggregation
     -minimum target threshold
   ## Derived Metrics:
     -Targets, receptions, yards
     -Catch rate
     -Yards per target
     -aDOT (average depth of target)
     -YAC per reception
     -Target share
     -Air yards share

# 5. Advanced Metrics
  ## YACOE (YAC over expected)
    * Expected YAC modeled from aDOT
    * Difference between actual and expected YAC
    * Interpretation of positive vs negative values
  ## EAV Score (Effiency-Adjusted Volume)
    * Composotie metric combining usage and effiency 
    * Z-scored componenents
    * Purpose: identify WRs who combine role + performance

# 6. Receiver Archetype Modeling
   ## Clustering Method
      -Unsupervied k-means clustering
      -Features used
      -Reason for scaling
   ## Archetypes
      -Deep threat
      -YAC specialist
      -Alpha Volume
      -Balanced
# 7. Visualizations
   ## Interactive charts
      -Yac vs aDOT
      -YACOE vs Target share
      -WR Archetype map
      - screenshots (later)
# 8. Key insights
      -Depth vs YAC
      -High volume doesn't mean high efficiency
      - Existence of distinct WR play styles
      -Some WRs outperform expecatiion of given role
# 9. Tools/libarries used
      -R
      -nflreadr
      -dplyr
      -ggplot2
      -ploty
      -janitor
      -ggrepel
# 10. Limitations/future implemantions
      -YACOE based on linear expectation model
      -No defensive context taken into account
      -No route tree data
      -Archetypes may shift with more/less seasons
# 11. Future implementations
      -EPA per target
      -Red zone analyis
      -wr yearly development
      -team offensive identity
      
         -
    -
   



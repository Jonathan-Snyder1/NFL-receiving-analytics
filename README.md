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
     -Only pass plays with an identified receiver
     -Plays are aggregrated to receiver season team totals
     -Minimum target threshold is used to remove some low usage outliers that we aren't interested in
   ## Derived Metrics:
     -Targets, receptions, yards
     -Catch rate
     -Yards per target
     -aDOT (average depth of target)
     -YAC (yards after catch) per reception
     -Target share
     -Air yards share

# 5. Advanced Metrics
  ## YACOE (YAC over expected)
    * Expected YAC modeled from aDOT
    * Difference between actual and expected YAC given aDOT
    * Positve YACOE means that a receiver generates more after catch value than expected
  ## EAV Score (Effiency-Adjusted Volume)
    * Composite metric designed to identify receivers who combine high involvement with strong efficiency
    * Uses standardized Z-scored componenents
    * Higher EAV scores indicate receivers who are both heavily used and consistently productive

# 6. Receiver Archetype Modeling
   ## Clustering Method
      -Unsupervied k-means clustering
      -Features are standardized prior to clustering
      -Cluster centers are transfromed back into original units for interpretation
   ## Archetypes
      -Deep threat (High aDOT and high air-yards share; downfield strectchers)
      -YAC specialist (Low aDOT with high YAC per recepetion; short-area receivers who generate explosive plays after the catch)
      -Alpha Volume (Receivers with high target shares; they are usually the first read and focal point of their offense)
      -Balanced (Intermediate depth and usage, versatile do it all players)
# 7. Visualizations
   ## Interactive charts
      -Visualizations built using ggplot2 and plotly
      -Yac vs aDOT (Illustartes tradeoff between route depth and after-catch production)
      -YACOE vs Target share (Highlights receivers who outperform expecation given offensive role)
      -WR Archetype map (Shows the different types of receivers)
      - Hover tooltips provide player context like team, season, and other advanced metrics
# 8. Key insights
      -There is a strong negative relationship between route depth and YAC per reception 
      -High volume receivers are not always the most efficient
      -Distinct types of receiver archetypes emerge from usage and efficiency patterns
      -Some WRs outperform expecation of their given role
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
   



# NFL Receiving Stats Analysis (R)

Using play-by-play data, I derived receiver-level metrics including aDOT, YAC per reception, target share, and air yards share. I estimated expected YAC from route depth and calculated YAC over expected (YACOE) to isolate after-catch skill. Clustering analysis reveals distinct receiver archetypes such as YAC specialists, deep threats, and high-volume WR1s.

##Data
- Source: nflreadr
- Ho, T., & Carl, S. (2025). nflreadr: Download 'nflverse' Data (R package version 1.5.0.9000). https://github.com/nflverse/nflreadr
- Season: 2024
- Format: Excel

## Metrics
- Catch Rate
- Yards per target
- Yards per game

## Key insights
- High volume receivers
- Mid volume receivers

## Tools
- R
- nflread, dplyr, ggplot2, janitor, plotly

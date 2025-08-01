# fantasy-football-auction-optimizer

R script collection to optimize fantasy football auction drafts using projected points and budget constraints.

## 📂 Project Structure

fantasy-football-auction-optimizer/
├── data/
│   ├── projections_2025_ffanalytics.csv
│   └── auction_values_2025_all.csv
│
├── R/
│   └── auction_draft_optimizer.R     # Core optimizer function
│
├── scripts/
│   └── scrape_projections.R          # Script to scrape projections
│
├── example_usage.R                   # Sample usage of the optimizer
└── README.md # This file


## 🚀 How to Use

1. **Clone or download the repository**  
   Use GitHub Desktop or download as ZIP.

2. **Open in RStudio as a Project**  
   It's recommended to open this folder as an RStudio project for easy file management and sourcing.

3. **Run projection scrapes**  
   Open `scrape_projections.R` and click “Source” in RStudio to generate fantasy projections.

4. **Edit and run the optimizer**  
   Open `example_usage.R`, adjust the parameters (budget, roster size, scoring format, etc.), and run the script.

5. **View your results**  
   The console will show:
   - Your optimized roster under salary and positional constraints
   - Total projected points and cost

## 🧠 Notes

- The optimizer uses `Rglpk::Rglpk_solve_LP()` to maximize projected points under auction draft constraints.
- You can simulate realistic league behavior by inflating top-tier player values (e.g., top 5 RBs or WRs).
- The script automatically subtracts $1 per bench/K/DST spot to ensure your budget doesn’t exceed league rules.

## 🧰 Requirements

- R packages:
  - `tidyverse`
  - `Rglpk`
  - `ffanalytics` *(used in projection scraping)*

Install with:

```r
install.packages(c("tidyverse", "Rglpk"))
# ffanalytics is available from GitHub
install.packages("remotes")
remotes::install_github("FantasyFootballAnalytics/ffanalytics")
```

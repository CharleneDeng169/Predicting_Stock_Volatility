# install.packages("edgar")
library("edgar")
source("/Users/vickie/edgar_mda10q.R")

useragent = "YiyingChen yiyingchen@brandeis.edu"

# Define your CIK list
cik_list <- c(
      '19617', # JPM
      '70858', # BAC
      '4962', # AXP
      '927628', # COF
  
      '200406', # JNJ
      '78003', # PFE
      '1800', # ABT
      '14272', # BMY
  
      '34088', # XOM
      '93410', # CVX
      '1163165', # COP
      '101778'  # MRO
)

# Define the years
years <- 2013:2023

# Loop through each year and get filings
for (year in years) {
  output <- getFilingsHTML(cik.no = cik_list, c('10-K', '10-Q'), year, quarter = c(1, 2, 3))
  # Process the output as needed
}

output1 <- edgar_mda10q(cik.no = cik_list, filing.year = years) # Extracting md&a from 10q
output2 <- getMgmtDisc(cik.no = cik_list, filing.year = years) # Extracting md&a from 10k


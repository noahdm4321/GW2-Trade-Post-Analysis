# Load necessary packages
# install.packages("tidyverse")
# install.packages("RSQLite")
# install.packages("knitr")

library(tidyverse)
library(RSQLite)
library(knitr)

# Define function to convert price value to currency value
currency <- function(price) {
  gold <- floor(price / 10000)
  silver <- floor((price %% 10000) / 100)
  copper <- price %% 100
  
  if (gold == 0 && silver == 0) {
    result <- paste0(copper, "c")
  } else if (gold == 0) {
    result <- paste0(silver, "s ", copper, "c")
  } else {
    result <- paste0(gold, "g ", silver, "s ", copper, "c")
  }
  
  return(result)
}


# Connect to the database
con <- dbConnect(SQLite(), dbname = "../data.db")

# Query the raw data from database
query <- "SELECT [id], [name], [value] FROM [items]"
items <- dbGetQuery(con, query)
query <- "SELECT [item_id], [buy_price], [buy_quantity], [sell_price], 
  [sell_quantity] FROM [prices]"
prices <- dbGetQuery(con, query)

# Close the database connection
dbDisconnect(con)


# Define item_data dataframe
item_data <- merge(
  items, prices, 
  by.x = "id", by.y = "item_id"
)

# Replace missing price values with vendor values
item_data$buy_price <- ifelse(
  is.na(item_data$buy_price), 
  item_data$value, 
  item_data$buy_price
)
item_data$sell_price <- ifelse(
  is.na(item_data$sell_price), 
  item_data$value, 
  item_data$sell_price
)

# Replace missing quantity value with 0
item_data$sell_quantity[is.na(item_data$sell_quantity)] <- 0
item_data$buy_quantity[is.na(item_data$buy_quantity)] <- 0

# Remove vendor value
item_data <- subset(item_data, select = -value)

# Add flipping profit column
item_data$profit <- ceiling((item_data$sell_price-1) * 0.85) -
  item_data$buy_price-1

glimpse(item_data)


# Plot data
ggplot(data = item_data, mapping = aes(x=buy_price, y=profit)) +
  geom_point() +
  # Add profit loss line
  geom_hline(yintercept = 0, color = "red")


# Create dataframe of investment opportunities
investments <- item_data %>%
  # Filter out items that are not profitable
  filter(profit > 0, buy_quantity > 0) %>%
  
  # If two items cost the same, take highest profit
  group_by(buy_price) %>%
  slice_max(profit) %>%
  ungroup()


# Plot data
ggplot(data = investments, mapping = aes(x=buy_price, y=profit)) +
  geom_point() +
  # Add profit loss line
  geom_hline(yintercept = 0, color = "red")


# Plot irrelevant items
ggplot(data = investments, mapping = aes(x=sell_price, y=buy_price)) +
  geom_point() +
  # Add deal line: line at which items will instant sell/buy
  geom_abline(slope = 1, intercept = 0, color = "red")

# Refine investments
investments <- investments %>%
  # Filter out items that have a sell price of more than 2x the buy price
  filter(sell_price <= buy_price * 2)

# Plot irrelevant items
ggplot(data = investments, mapping = aes(x=sell_price, y=buy_price)) +
  geom_point() + 
  # Add deal line: line at which items will sell/buy
  geom_abline(slope = 1, intercept = 0, color = "red") +
  # Add 2x buy price line
  geom_abline(slope = 0.5, intercept = 0, color = "blue")


# Plot data
ggplot(data = investments, mapping = aes(x=buy_price, y=profit)) +
  geom_point() +
  # Add profit minimum line
  geom_abline(slope = 0.5, intercept = 0, color = "blue") +
  # Add max buy line
  geom_vline(xintercept = 10000000, color = "red")


# Refine investments
investments <- investments %>%
  # Filter out items with profit less than 50% of buy price
  filter(profit >= buy_price * 0.5) %>%
  # Filter out low profit and high cost items
  filter(profit > 10000, buy_price < 10000000)


# Plot data
ggplot(data = investments, mapping = aes(x=buy_price, y=profit)) +
  geom_point() +
  # Add profit minimum line
  geom_abline(slope = 0.5, intercept = 0, color = "blue") +
  # Add max buy line
  geom_vline(xintercept = 10000000, color = "red")

################################################################################

# Sort results
investments <- investments %>% arrange(desc(profit))

# Create a data frame with formatted currency values
investment_table <- data.frame(
  Name = character(),
  Buy = character(),
  Sell = character(),
  Profit = character(),
  stringsAsFactors = FALSE
)

# Iterate through top 20 rows and store values to investment_table
row_counter <- 0  # Counter for limiting rows
for (i in 1:nrow(investments)) {
  item <- investments[i, ]
  name <- item$name
  buy <- currency(item$buy_price+1)
  sell <- currency(item$sell_price-1)
  profit <- currency(item$profit)
  investment_table <- rbind(investment_table, c(name, buy, sell, profit))
  
  row_counter <- row_counter + 1
  if (row_counter == 10) {
    break
  }
}

# Set column names
colnames(investment_table) <- c("Name", "Buy", "Sell", "Profit")

# Print the table
print(investment_table)


# Sort results
investments <- investments %>% arrange(desc(buy_quantity))

# Create a data frame with formatted currency values
investment_table <- data.frame(
  Name = character(),
  Buy = character(),
  Sell = character(),
  Profit = integer(),
  stringsAsFactors = FALSE
)

# Iterate through top 20 rows and store values to investment_table
row_counter <- 0  # Counter for limiting rows
for (i in 1:nrow(investments)) {
  item <- investments[i, ]
  name <- item$name
  buy <- currency(item$buy_price+1)
  sell <- currency(item$sell_price-1)
  profit <- currency(item$profit)
  investment_table <- rbind(investment_table, c(name, buy, sell, profit))
  
  row_counter <- row_counter + 1
  if (row_counter == 10) {
    break
  }
}

# Set column names
colnames(investment_table) <- c("Name", "Buy", "Sell", "Profit")

# Print the table
print(investment_table)

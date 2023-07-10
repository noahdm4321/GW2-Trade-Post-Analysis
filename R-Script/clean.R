# Load necessary packages
# install.packages("tidyverse")
# install.packages("RSQLite")

library(tidyverse)
library(RSQLite)

################################################################################

# Connect to the database
con <- dbConnect(SQLite(), dbname = "../data.db")

# Query the raw data from database
query <- "SELECT [id], [name], [value] FROM [items]"
items <- dbGetQuery(con, query)
query <- "SELECT [item_id], [buy_price], [buy_quantity], [sell_price], 
  [sell_quantity] FROM [prices]"
prices <- dbGetQuery(con, query)
query <- "SELECT [output_id], [output_count], [input1_id], [input1_count], 
  [input2_id], [input2_count], [input3_id], [input3_count], [input4_id], 
  [input4_count] FROM [recipes]"
recipes <- dbGetQuery(con, query)
rm(query)

################################################################################

# Define item_data dataframe
item_data <- merge(
  items, prices, 
  by.x = "id", by.y = "item_id"
)

item_data$buy_price <- ifelse(
  is.na(item_data$buy_price), 
  item_data$value, 
  item_data$buy_price
)
item_data$sell_price[is.na(item_data$sell_price)] <- 0
item_data$sell_quantity[is.na(item_data$sell_quantity)] <- 0
item_data$buy_quantity[is.na(item_data$buy_quantity)] <- 0
item_data <- subset(item_data, select = -value)
# Add profit column
item_data$profit <- item_data$sell_price-1 -
  ceiling((item_data$buy_price+1) * 0.85)
# Add profit column for buy now and sell now
item_data$profit_now <- ceiling((item_data$buy_price) * 0.85) -
  item_data$sell_price

################################################################################

# Create dataframe of investment opportunities
investments <- item_data %>%
  # Filter out items that are not profitable
  filter(profit > 0, sell_quantity > 0, buy_quantity > 0) %>%
  # If two items cost the same, take highest profit
  group_by(sell_price) %>%
  slice_max(profit) %>%
  ungroup()

# Plot data
ggplot(data = investments, mapping = aes(x=sell_price, y=profit)) +
  geom_point() + 
  # Add maximum profit line
  geom_abline(slope = 1, intercept = 0, color = "red")

### Remove irrelevant items: items that have listings which would never sell. ##

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
  geom_abline(slope = 1, intercept = 0, color = "red")

################################# Finalize filter ##############################

# Refine investments
investments <- investments %>%
  # Filter out items more than 10000 away from maximum profit
  filter(profit >= sell_price - 10000) %>%
  # Filter out lower profit items
  filter(profit > 10000, sell_price < 1000000)

# Plot data
ggplot(data = investments, mapping = aes(x=sell_price, y=profit)) +
  geom_point() + 
  # Add maximum profit line
  geom_abline(slope = 1, intercept = 0, color = "red")

# List investment items
print(investments %>% arrange(desc(profit)))

################################################################################

# Create dataframe of investment_now opportunities
investments_now <- item_data %>%
  # Filter out items that are not profitable
  filter(profit_now > 0, sell_quantity > 0, buy_quantity > 0)

print(investments_now %>% arrange(desc(profit_now)))  #typically blank

################################################################################

# Save the cleaned data to database
# dbWriteTable(con, "investments", clean, overwrite = TRUE)

# Close the database connection
dbDisconnect(con)
rm(con)

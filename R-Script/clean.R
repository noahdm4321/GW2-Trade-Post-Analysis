# Load necessary packages
install.packages("tidyverse")
install.packages("RSQLite")

library(tidyverse)
library(RSQLite)

# Connect to the database
con <- dbConnect(SQLite(), dbname = "../data.db")

# Query the raw data from database
query <- "SELECT [id], [name], [value] FROM [items]"
items <- dbGetQuery(con, query)
query <- "SELECT [item_id], [buy_price], [sell_price] FROM [prices]"
prices <- dbGetQuery(con, query)
query <- "SELECT [output_id], [output_count], [input1_id], [input1_count], [input2_id], [input2_count], [input3_id], [input3_count], [input4_id], [input4_count] FROM [recipes]"
recipes <- dbGetQuery(con, query)
rm(query)

#################################################################################

# Define item_data dataframe
item_data <- merge(
  items, prices, 
  by.x = "id", by.y = "item_id", 
  all.x = TRUE
)
item_data$buy_price <- ifelse(
  is.na(item_data$buy_price), 
  item_data$value, 
  item_data$buy_price
)
item_data$sell_price[is.na(item_data$sell_price)] <- 0



# Create empty dataframe with desired structure
recipe_data <- data.frame(
  output_id = integer(),
  output_price = numeric(),
  output_count = integer(),
  input_ids = I(list()),
  input_counts = I(list()),
  input_prices = I(list()),
  stringsAsFactors = FALSE
)

# Pre-allocate rows in the dataframe
recipe_data <- recipe_data[rep(NA, nrow(recipes)), ]

# Iterate over each row in 'recipes' dataframe
for (i in 1:nrow(recipes)) {
  new_row <- data.frame(
    output_id = recipes[i, "output_id"],
    output_price = item_data[recipes[i, "output_id"], "sell_price"],
    output_count = recipes[i, "output_count"],
    stringsAsFactors = FALSE
  )
  
  # Form input_ids as nested list
  input_ids <- list(
    as.character(recipes[i, "input1_id"]),
    as.character(recipes[i, "input2_id"]),
    as.character(recipes[i, "input3_id"]),
    as.character(recipes[i, "input4_id"])
  )
  
  # Form input_counts as nested list
  input_counts <- list(
    as.integer(recipes[i, "input1_count"]),
    as.integer(recipes[i, "input2_count"]),
    as.integer(recipes[i, "input3_count"]),
    as.integer(recipes[i, "input4_count"])
  )
  
  # Form input_prices as nested list
  input_prices <- list(
    item_data[recipes[i, "input1_id"], "buy_price"],
    ifelse(is.na(recipes[i, "input2_id"]), NA, item_data[recipes[i, "input2_id"], "buy_price"]),
    ifelse(is.na(recipes[i, "input3_id"]), NA, item_data[recipes[i, "input3_id"], "buy_price"]),
    ifelse(is.na(recipes[i, "input4_id"]), NA, item_data[recipes[i, "input4_id"], "buy_price"])
  )
  
  # Assign nested lists to the new_row dataframe
  new_row$input_ids <- input_ids
  new_row$input_counts <- input_counts
  new_row$input_prices <- input_prices
  
  # Assign new_row to the corresponding row in recipe_data
  recipe_data[i, ] <- new_row
}





# Create a function to iteratively replace input_price values
iterative_replace <- function(recipe_data) {
  while (TRUE) {
    replaced_flag <- FALSE
    
    # Iterate over each row in 'recipe_data'
    for (i in 1:nrow(recipe_data)) {
      # Check if input_price is NA
      if (is.na(recipe_data$input1_price[i])) {
        # Retrieve corresponding output_id
        output_id <- recipe_data$input1_id[i]
        
        # Find corresponding row in 'recipe_data' based on output_id
        matching_row <- recipe_data[recipe_data$output_id == output_id, ]
        
        # Check if a corresponding row is found
        if (nrow(matching_row) > 0) {
          # Replace input_price with the sum of input1_price, input2_price, input3_price, and input4_price
          recipe_data$input1_price[i] <- sum(matching_row$input1_price, matching_row$input2_price,
                                             matching_row$input3_price, matching_row$input4_price)
          replaced_flag <- TRUE
        }
      }
    }
    
    # Break the loop if no input_price values were replaced in the iteration
    if (!replaced_flag) {
      break
    }
  }
  
  return(recipe_data)
}

# Call the iterative_replace function
updated_recipe_data <- iterative_replace(recipe_data)

###################################################################################

# Display the cleaned data
glimpse(merged_data)
glimpse(recipe_data)

# Save the cleaned data to database
dbWriteTable(con, "crafting_prices", clean, overwrite = TRUE)

# Close the database connection
dbDisconnect(con)

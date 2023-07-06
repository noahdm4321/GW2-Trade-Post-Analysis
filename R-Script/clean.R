# Load necessary packages
install.packages("tidyverse")
install.packages("RSQLite")

library(tidyverse)
library(RSQLite)

# Connect to the database
con <- dbConnect(SQLite(), dbname = "../item_data.db")

# Query the raw data from database
query <- "SELECT * FROM items"
result <- dbGetQuery(con, query)

# Display the result
glimpse(result)

# Clean data
clean <- result %>%
  filter(level == 80, type == "Armor", rarity == "Exotic")

# Display the cleaned data
glimpse(clean)

# Save the cleaned data to database
dbWriteTable(con, "cleaned_items", clean, overwrite = TRUE)

# Close the database connection
dbDisconnect(con)

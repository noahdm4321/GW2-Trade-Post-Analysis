Investment Oportunities
================

#### This documents outlines the process of cleaning, agrigating, and analysing the Guild Wars 2 trading post data, taken from the Gw2 API (stored in local SQLite database). By the end of the document, we will have a list of all viable investment oportunities for flipping items on the Guild Wars 2 Trading Post.

## Data Retrieval

##### In this section, we connect to the database and query the necessary raw data. We retrieve the items’ information, including their names and values, as well as the price data, which includes buy and sell prices and quantities.

``` r
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
```

## Data Transformation

##### In this section, we merge the items and prices data to create the `item_data` dataframe. We handle missing values, replacing them with appropriate values. Then, we calculate the profit for flipping each item based on buy and sell prices.

``` r
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
  item_data$buy_price - 1
```

    ## Rows: 27,143
    ## Columns: 7
    ## $ id            <int> 24, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, …
    ## $ name          <chr> "Sealed Package of Snowballs", "Mighty Country Coat", "M…
    ## $ buy_price     <int> 183, 83, 32, 29, 34, 32712, 1916, 177, 1258, 43745, 17, …
    ## $ buy_quantity  <dbl> 122, 1010, 228, 1509, 1, 2, 10, 235, 12, 1, 24, 294, 4, …
    ## $ sell_price    <int> 230, 97, 58, 44, 87, 99000, 2819, 1185, 1740, 103705, 35…
    ## $ sell_quantity <dbl> 1, 2, 2, 5, 2, 7, 1, 1, 2, 1, 1, 1, 1, 1, 2, 1, 6, 3, 1,…
    ## $ profit        <dbl> 11, -2, 16, 7, 39, 51437, 479, 829, 220, 44403, 11, 27, …

## Identifying Investment Opportunities

##### In this section, we filter the `item_data` dataframe to select items that are profitable, considering the sell and buy quantities. If multiple items have the same sell price, we choose the one with the highest profit. We then plot the data points to visualize the relationship between sell price and profit, with a reference line indicating the maximum profit (red) and profit loss (blue).

![](investments_files/figure-gfm/chart%200-1.png)<!-- -->

``` r
# Create dataframe of investment opportunities
investments <- item_data %>%
  # Filter out items that are not profitable
  filter(profit > 0, sell_quantity > 0, buy_quantity > 0) %>%
  # If two items cost the same, take highest profit
  group_by(sell_price) %>%
  slice_max(profit) %>%
  ungroup()
```

![](investments_files/figure-gfm/chart%201-1.png)<!-- -->

## Refining Investment Opportunities

##### In this section, we filter all items in `investments`. We use a reference line to indicate the threshold at which items will instantly sell or buy (red). Then, we further refine the investment opportunities by filtering out items that have a sell price exceeding twice the buy price, with a reference line indicating 2x buy value (blue).

![](investments_files/figure-gfm/chart%202-1.png)<!-- -->

``` r
# Refine investments
investments <- investments %>%
  # Filter out items that have a sell price of more than 2x the buy price
  filter(sell_price <= buy_price * 2)
```

![](investments_files/figure-gfm/chart%203-1.png)<!-- -->

## Finalizing Investment Opportunities

##### In this section, we further refine the investment opportunities by filtering out lower-profit items that have a profit less than 30% of buy price (blue). We also remove items with a buy price higher than 100 gold (red). Finally, we plot the data to visualize the remaining investment opportunities and list the items sorted by their profit in descending order.

![](investments_files/figure-gfm/chart%203.5-1.png)<!-- -->

``` r
# Refine investments
investments <- investments %>%
  # Filter out items with profit less than 50% of buy price
  filter(profit >= buy_price * 0.5) %>%
  # Filter out lower profit and high cost items
  filter(profit > 10000, buy_price < 1000000)
```

![](investments_files/figure-gfm/chart%204-1.png)<!-- -->

# Conclusion

#### We have our results! All of these items you should purchase and list at the recommended prices. Keep in mind that there is no garentee that all of the items will sell or be purchased as the market tends to flucuate. I am working on creating a historical database to calculate a fullfilment probability percentage.

| Name                                           | Buy         | Sell         | Profit      |
|:-----------------------------------------------|:------------|:-------------|:------------|
| Polysaturating Reverberating Infusion (Purple) | 95g 0s 28c  | 189g 90s 12c | 66g 41s 31c |
| Wall of the Mists                              | 90g 1s 6c   | 179g 0s 0c   | 62g 13s 93c |
| Polysaturating Reverberating Infusion (Red)    | 92g 90s 3c  | 180g 0s 0c   | 60g 9s 96c  |
| Mainsail of the Lion’s Champion                | 79g 32s 21c | 157g 99s 99c | 54g 97s 77c |
| Polysaturating Reverberating Infusion (Purple) | 86g 0s 0c   | 159g 32s 99c | 49g 43s 3c  |
| Unspoken Curse                                 | 82g 62s 13c | 154g 54s 54c | 48g 74s 22c |
| Polysaturating Reverberating Infusion (Purple) | 72g 0s 1c   | 141g 97s 97c | 48g 68s 25c |
| Mini Copper Skyscale Hatchling                 | 70g 50s 2c  | 139g 99s 98c | 48g 49s 95c |
| Jormag’s Needle                                | 75g 7s 13c  | 144g 98s 99c | 48g 17s 0c  |
| Mini Silver Jackal Pup                         | 65g 1s 21c  | 129g 99s 88c | 45g 48s 67c |
| Might of the Lion’s Champion                   | 88g 95s 13c | 157g 0s 99c  | 44g 50s 70c |
| Polysaturating Reverberating Infusion (Red)    | 81g 0s 2c   | 146g 98s 97c | 43g 94s 9c  |
| Kaiser Snake Warhorn Skin                      | 84g 2s 37c  | 149g 58s 45c | 43g 12s 30c |
| Mini Green Tigris Cub                          | 80g 2s 35c  | 143g 98s 96c | 42g 36s 75c |
| Bloodstone Sword Skin                          | 64g 12s 76c | 125g 12s 69c | 42g 23s 1c  |
| Polysaturating Reverberating Infusion (Purple) | 76g 0s 15c  | 137g 99s 99c | 41g 29s 83c |
| Boots of the Obsidian Path of the Cavalier     | 60g 11s 69c | 118g 98s 98c | 41g 2s 43c  |
| Recipe: Zehtuka’s Guise                        | 54g 0s 1c   | 105g 95s 93c | 36g 6s 52c  |
| Recipe: Zehtuka’s Pauldrons                    | 51g 0s 3c   | 99g 98s 87c  | 33g 99s 0c  |
| Recipe: Zehtuka’s Striders                     | 48g 0s 6c   | 95g 55s 55c  | 33g 22s 14c |

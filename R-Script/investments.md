Investment Oportunities
================

##### This documents outlines the process of cleaning, agrigating, and analysing the Guild Wars 2 trading post data, taken from the Gw2 API (stored in local SQLite database). By the end of the document, we will have a list of all viable investment oportunities for flipping items on the Guild Wars 2 Trading Post.

### Data Retrieval

###### In this section, we connect to the database and query the necessary raw data. We retrieve the items’ information, including their names and values, as well as the price data, which includes buy and sell prices and quantities.

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

### Data Transformation

###### In this section, we merge the items and prices data to create the `item_data` dataframe. We handle missing values, replacing them with appropriate values. Then, we calculate the profit for flipping each item based on buy and sell prices.

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
item_data$profit <- item_data$sell_price-1 -
  ceiling((item_data$buy_price+1) * 0.85)
```

    ## Rows: 27,143
    ## Columns: 7
    ## $ id            <int> 24, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, …
    ## $ name          <chr> "Sealed Package of Snowballs", "Mighty Country Coat", "M…
    ## $ buy_price     <int> 183, 83, 32, 29, 34, 32712, 1916, 177, 1258, 43745, 17, …
    ## $ buy_quantity  <dbl> 122, 1010, 228, 1509, 1, 2, 10, 235, 12, 1, 24, 294, 4, …
    ## $ sell_price    <int> 230, 97, 58, 44, 87, 99000, 2819, 1185, 1740, 103705, 35…
    ## $ sell_quantity <dbl> 1, 2, 2, 5, 2, 7, 1, 1, 2, 1, 1, 1, 1, 1, 2, 1, 6, 3, 1,…
    ## $ profit        <dbl> 72, 24, 28, 17, 56, 71192, 1188, 1032, 668, 66519, 18, 5…

### Identifying Investment Opportunities

###### In this section, we filter the `item_data` dataframe to select items that are profitable, considering the sell and buy quantities. If multiple items have the same sell price, we choose the one with the highest profit. We then plot the data points to visualize the relationship between sell price and profit, with a reference line indicating the maximum profit (red) and profit loss (blue).

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

### Refining Investment Opportunities

###### In this section, we all items in `investments`. We use a reference line to indicate the threshold at which items will instantly sell or buy (red). Then, we further refine the investment opportunities by filtering out items that have a sell price exceeding twice the buy price, with a reference line indicating 2x buy value (blue).

![](investments_files/figure-gfm/chart%202-1.png)<!-- -->

``` r
# Refine investments
investments <- investments %>%
  # Filter out items that have a sell price of more than 2x the buy price
  filter(sell_price <= buy_price * 2)
```

![](investments_files/figure-gfm/chart%203-1.png)<!-- -->

### Finalizing Investment Opportunities

###### In this section, we further refine the investment opportunities by filtering out lower-profit items that have a profit more than 1 gold away from the maximum profit. We also remove items with a sell price higher than 100 gold. Finally, we plot the data to visualize the remaining investment opportunities and list the items sorted by their profit in descending order.

``` r
# Refine investments
investments <- investments %>%
  # Filter out items more than 10000 away from maximum profit
  filter(profit >= sell_price - 10000) %>%
  # Filter out lower profit items
  filter(profit > 10000, sell_price < 1000000)
```

![](investments_files/figure-gfm/chart%204-1.png)<!-- -->

## Conclusion

##### We have our results! All of these items you should purchase and list at the recommended prices. Keep in mind that there is no garentee that all of the items will sell or be purchased as the market tends to flucuate. I am working on creating a historical database to calculate a fullfilment probability percentage.

    ## Thesis on Learned Malice  |  buy: 9264 - sell: 17896 - profit: 10019 
    ## Recipe: Harrier's Warbeast Tassets  |  buy: 10003 - sell: 19064 - profit: 10559 
    ## Mini Vigil Marksman  |  buy: 10548 - sell: 19400 - profit: 10432 
    ## Bringer's Pearl Rod  |  buy: 10211 - sell: 19500 - profit: 10818 
    ## Sunstone Gold Ring  |  buy: 10219 - sell: 19579 - profit: 10891 
    ## Recipe: Harrier's Warbeast Leggings  |  buy: 9901 - sell: 19678 - profit: 11260 
    ## Thesis on Basic Speed  |  buy: 10022 - sell: 19846 - profit: 11325 
    ## Berserker's Soft Wood Warhorn of Rage  |  buy: 11358 - sell: 19959 - profit: 10302 
    ## Berserker's Pearl Needler  |  buy: 11744 - sell: 19988 - profit: 10003 
    ## Mini Kodan Icehammer  |  buy: 10640 - sell: 20080 - profit: 11034 
    ## Mini Vigil Warmaster  |  buy: 11390 - sell: 20219 - profit: 10535 
    ## Dire Emblazoned Pants  |  buy: 10304 - sell: 20297 - profit: 11536 
    ## Rampager's Emblazoned Coat  |  buy: 11571 - sell: 20369 - profit: 10531 
    ## Assassin's Pearl Reaver  |  buy: 10567 - sell: 20509 - profit: 11525 
    ## Forged Bow  |  buy: 11283 - sell: 20867 - profit: 11274 
    ## Bringer's Pearl Bludgeoner  |  buy: 10973 - sell: 20973 - profit: 11644 
    ## Mini Holosmith Baraz Sharifi  |  buy: 11648 - sell: 21047 - profit: 11144 
    ## Carrion Emblazoned Coat  |  buy: 11596 - sell: 21243 - profit: 11384 
    ## Dire Emblazoned Coat  |  buy: 11046 - sell: 21488 - profit: 12097 
    ## Old Reliable  |  buy: 11696 - sell: 21794 - profit: 11850 
    ## Mini Toxic Hybrid  |  buy: 11114 - sell: 21977 - profit: 12528 
    ## Rampager's Soft Wood Focus of Ice  |  buy: 11762 - sell: 22994 - profit: 12994

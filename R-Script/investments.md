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

##### In this section, we all items in `investments`. We use a reference line to indicate the threshold at which items will instantly sell or buy (red). Then, we further refine the investment opportunities by filtering out items that have a sell price exceeding twice the buy price, with a reference line indicating 2x buy value (blue).

![](investments_files/figure-gfm/chart%202-1.png)<!-- -->

``` r
# Refine investments
investments <- investments %>%
  # Filter out items that have a sell price of more than 2x the buy price
  filter(sell_price <= buy_price * 2)
```

![](investments_files/figure-gfm/chart%203-1.png)<!-- -->

## Finalizing Investment Opportunities

##### In this section, we further refine the investment opportunities by filtering out lower-profit items that have a profit less than 30% of buy price. We also remove items with a buy price higher than 100 gold. Finally, we plot the data to visualize the remaining investment opportunities and list the items sorted by their profit in descending order.

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

    ## Polysaturating Reverberating Infusion (Purple)  |  sell:*189g90s12c* - buy:*95g0s28c* = profit:*66g41s31c*
    ## Wall of the Mists  |  sell:*179g0s0c* - buy:*90g1s6c* = profit:*62g13s93c*
    ## Polysaturating Reverberating Infusion (Red)  |  sell:*180g0s0c* - buy:*92g90s3c* = profit:*60g9s96c*
    ## Mainsail of the Lion's Champion  |  sell:*157g99s99c* - buy:*79g32s21c* = profit:*54g97s77c*
    ## Polysaturating Reverberating Infusion (Purple)  |  sell:*159g32s99c* - buy:*86g0s0c* = profit:*49g43s3c*
    ## Unspoken Curse  |  sell:*154g54s54c* - buy:*82g62s13c* = profit:*48g74s22c*
    ## Polysaturating Reverberating Infusion (Purple)  |  sell:*141g97s97c* - buy:*72g0s1c* = profit:*48g68s25c*
    ## Mini Copper Skyscale Hatchling  |  sell:*139g99s98c* - buy:*70g50s2c* = profit:*48g49s95c*
    ## Jormag's Needle  |  sell:*144g98s99c* - buy:*75g7s13c* = profit:*48g17s0c*
    ## Mini Silver Jackal Pup  |  sell:*129g99s88c* - buy:*65g1s21c* = profit:*45g48s67c*
    ## Might of the Lion's Champion  |  sell:*157g0s99c* - buy:*88g95s13c* = profit:*44g50s70c*
    ## Polysaturating Reverberating Infusion (Red)  |  sell:*146g98s97c* - buy:*81g0s2c* = profit:*43g94s9c*
    ## Kaiser Snake Warhorn Skin  |  sell:*149g58s45c* - buy:*84g2s37c* = profit:*43g12s30c*
    ## Mini Green Tigris Cub  |  sell:*143g98s96c* - buy:*80g2s35c* = profit:*42g36s75c*
    ## Bloodstone Sword Skin  |  sell:*125g12s69c* - buy:*64g12s76c* = profit:*42g23s1c*
    ## Polysaturating Reverberating Infusion (Purple)  |  sell:*137g99s99c* - buy:*76g0s15c* = profit:*41g29s83c*
    ## Boots of the Obsidian Path of the Cavalier  |  sell:*118g98s98c* - buy:*60g11s69c* = profit:*41g2s43c*
    ## Recipe: Zehtuka's Guise  |  sell:*105g95s93c* - buy:*54g0s1c* = profit:*36g6s52c*
    ## Recipe: Zehtuka's Pauldrons  |  sell:*99g98s87c* - buy:*51g0s3c* = profit:*33g99s0c*
    ## Recipe: Zehtuka's Striders  |  sell:*95g55s55c* - buy:*48g0s6c* = profit:*33g22s14c*

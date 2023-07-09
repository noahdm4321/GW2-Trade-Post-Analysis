from datetime import datetime
import requests
import json
import sqlite3

BATCH_SIZE = 25         ## API pages pulled before committing to database
USE_LISTINGS = True     ## Use listing data for prices instead of price data

ITEMS_URL = "https://api.guildwars2.com/v2/items"
PRICES_URL = "https://api.guildwars2.com/v2/commerce/prices"
RECIPES_URL = "https://api.guildwars2.com/v2/recipes"
LISTINGS_URL = "https://api.guildwars2.com/v2/commerce/listings"


def get_data(url, page):
    """
    Fetches data from the specified API endpoint.

    Args:
        url (str): The URL of the API endpoint.
        page (int): The page number of data to fetch.

    Returns:
        dict: The JSON response containing the data.
    """
    params = {"page": page, "page_size": 200}
    response = requests.get(url, params=params)

    try:
        data = response.json()
    except json.JSONDecodeError:
        # Handle JSON decoding error
        print("Error: Failed to decode JSON response")
        return {}
    
    return data


def update_prices_in_sql(cursor, prices):
    """
    Updates the prices table in data.db with prices data.

    Args:
        cursor (sqlite3.Cursor): The cursor object for executing SQL queries.
        prices (list): The list of items containing price data.
    """
    date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    rows = []

    for price in prices:
        item_id = price.get("id")
        buy = price.get("buys")
        sell = price.get("sells")

        buy_price = buy.get("unit_price") if buy else None
        buy_quantity = buy.get("quantity") if buy else None
        sell_price = sell.get("unit_price") if sell else None
        sell_quantity = sell.get("quantity") if sell else None

        rows.append(
            (
                item_id,
                date,
                buy_price,
                buy_quantity,
                sell_price,
                sell_quantity,
            )
        )

    cursor.executemany(
        """INSERT INTO prices (item_id, date_updated, buy_price, buy_quantity, sell_price, sell_quantity)
            VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(item_id) DO UPDATE SET
            date_updated = excluded.date_updated,
            buy_price = excluded.buy_price,
            buy_quantity = excluded.buy_quantity,
            sell_price = excluded.sell_price,
            sell_quantity = excluded.sell_quantity""",
        rows,
    )


def update_listings_in_sql(cursor, listings):
    """
    Updates the prices table in data.db with listing data.

    Args:
        cursor (sqlite3.Cursor): The cursor object for executing SQL queries.
        listing (list): The list of items containing listing data.
    """
    date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    rows = []

    for listing in listings:
        item_id = listing.get("id")
        buy = listing.get("buys")
        sell = listing.get("sells")

        buy_price = buy[0].get("unit_price") if buy else None
        buy_quantity = buy[0].get("quantity") if buy else None
        sell_price = sell[0].get("unit_price") if sell else None
        sell_quantity = sell[0].get("quantity") if sell else None

        rows.append((item_id, date, buy_price, buy_quantity, sell_price, sell_quantity))

    cursor.executemany(
        """INSERT INTO prices (item_id, date_updated, buy_price, buy_quantity, sell_price, sell_quantity)
            VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(item_id) DO UPDATE SET
            date_updated = excluded.date_updated,
            buy_price = excluded.buy_price,
            buy_quantity = excluded.buy_quantity,
            sell_price = excluded.sell_price,
            sell_quantity = excluded.sell_quantity""",
        rows
    )


def update_items_in_sql(cursor, items):
    """
    Updates the items table in data.db with items data.

    Args:
        cursor (sqlite3.Cursor): The cursor object for executing SQL queries.
        items (list): The list of items containing item data.
    """
    rows = []

    for item in items:
        id = item.get("id")
        name = item.get("name")
        item_type = item.get("type")
        level = item.get("level")
        flags = " ".join(item.get("flags")) if item.get("flags") else None
        rarity = item.get("rarity")
        value = item.get("vendor_value")
        icon = item.get("icon")

        rows.append((id, name, item_type, level, flags, value, rarity, icon))

    cursor.executemany(
        """INSERT INTO items (id, name, type, level, flags, value, rarity, icon)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)
           ON CONFLICT(id) DO NOTHING""",
        rows,
    )


def update_recipes_in_sql(cursor, recipes):
    """
    Updates the recipes table in data.db with recipes data.

    Args:
        cursor (sqlite3.Cursor): The cursor object for executing SQL queries.
        recipes (list): The list of recipes containing item data.
    """
    rows = []

    for recipe in recipes:
        input_id = []
        input_count = []

        id = recipe.get("id")
        type = recipe.get("type")
        output_id = recipe.get("output_item_id")
        output_count = recipe.get("output_item_count")
        for i in range(4):
            if i < len(recipe.get("ingredients")):
                input_id.append(recipe.get("ingredients")[i].get("item_id"))
                input_count.append(recipe.get("ingredients")[i].get("count"))
            else:
                input_id.append(None)
                input_count.append(None)
        disciplines = (
            " ".join(recipe.get("disciplines")) if recipe.get("disciplines") else None
        )
        time = recipe.get("time_to_craft_ms")
        min_rating = recipe.get("min_rating")
        auto_learn = True if recipe.get("flags") == ["AutoLearned"] else False

        rows.append(
            (
                id,
                type,
                output_id, 
                output_count,
                input_id[0],
                input_count[0],
                input_id[1],
                input_count[1],
                input_id[2],
                input_count[2],
                input_id[3],
                input_count[3],
                time,
                disciplines,
                min_rating,
                auto_learn,
            )
        )

    cursor.executemany(
        """INSERT INTO recipes (id, type, output_id, output_count, input1_id, input1_count, input2_id, input2_count, input3_id, input3_count, input4_id, input4_count, time, disciplines, min_rating, auto_learn)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
           ON CONFLICT(id) DO NOTHING""",
        rows,
    )


def main():
    # Connect to data.db
    connection = sqlite3.connect("data.db")
    cursor = connection.cursor()

    if USE_LISTINGS:
        # Fetch and update price data based on listings
        listing_page = 0
        while True:
            listings = get_data(LISTINGS_URL, listing_page)
            update_listings_in_sql(cursor, listings)
            if len(listings) < 200:
                break
            listing_page += 1

            # Commit changes in batches
            if listing_page % BATCH_SIZE == 0:
                print(f"Committed {listing_page*200} rows in price table.")
                connection.commit()

        connection.commit()
        cursor.execute("SELECT COUNT(item_id) FROM prices")
        prices_len = cursor.fetchone()[0]
        print(f"Updated {prices_len} prices!")

    else:
        # Fetch and update price data based on prices
        price_page = 0
        while True:
            prices = get_data(PRICES_URL, price_page)
            update_prices_in_sql(cursor, prices)
            if len(prices) < 200:
                break
            price_page += 1

            # Commit changes in batches
            if price_page % BATCH_SIZE == 0:
                print(f"Committed {price_page*200} rows in prices table.")
                connection.commit()

        connection.commit()
        cursor.execute("SELECT COUNT(item_id) FROM prices")
        prices_len = cursor.fetchone()[0]
        print(f"Updated {prices_len} prices!")


    # Fetch and update item data
    item_page = 0
    while True:
        items = get_data(ITEMS_URL, item_page)
        update_items_in_sql(cursor, items)
        if len(items) < 200:
            break
        item_page += 1

        # Commit changes in batches
        if item_page % BATCH_SIZE == 0:
            print(f"Committed {item_page*200} rows in items table.")
            connection.commit()

    connection.commit()
    cursor.execute("SELECT COUNT(id) FROM items")
    items_len = cursor.fetchone()[0]
    print(f"Updated {items_len} items!")


    # Fetch and update recipes data
    recipes_page = 0
    while True:
        recipes = get_data(RECIPES_URL, recipes_page)
        update_recipes_in_sql(cursor, recipes)
        if len(recipes) < 200:
            break
        recipes_page += 1

        # Commit changes in batches
        if recipes_page % BATCH_SIZE == 0:
            print(f"Committed {recipes_page*200} rows in recipes table.")
            connection.commit()

    connection.commit()
    cursor.execute("SELECT COUNT(id) FROM recipes")
    recipes_len = cursor.fetchone()[0]
    print(f"Updated {recipes_len} recipes, {prices_len} prices, and {items_len} items!")

    connection.close()


if __name__ == "__main__":
    main()

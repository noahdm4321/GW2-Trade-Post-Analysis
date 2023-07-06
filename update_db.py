from datetime import datetime
import requests
import json
import sqlite3

ITEMS_URL = "https://api.guildwars2.com/v2/items"
PRICES_URL = "https://api.guildwars2.com/v2/commerce/prices"

BATCH_SIZE = 25      ## API pages pulled before committing to database

def get_data(url, page):
    """
    Fetches data from the specified API endpoint.

    Args:
        url (str): The URL of the API endpoint.
        page (int): The page number of data to fetch.

    Returns:
        dict: The JSON response containing the data.
    """
    params = {
        "page": page,
        "page_size": 200
    }
    response = requests.get(url, params=params)
    return response.json()


def update_prices_in_sql(cursor, items):
    """
    Updates the prices table in item_data.db with items data.

    Args:
        cursor (sqlite3.Cursor): The cursor object for executing SQL queries.
        items (list): The list of items containing price data.
    """
    date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    for item in items:
        buy = item["buys"]
        sell = item["sells"]

        buy_price = buy["unit_price"] if buy else None
        buy_quantity = buy["quantity"] if buy else None
        sell_price = sell["unit_price"] if sell else None
        sell_quantity = sell["quantity"] if sell else None

        cursor.execute(
            """INSERT INTO prices (id, date_updated, buy_price, buy_quantity, sell_price, sell_quantity)
               VALUES (?, ?, ?, ?, ?, ?)
               ON CONFLICT(id) DO UPDATE SET
               date_updated = excluded.date_updated,
               buy_price = excluded.buy_price,
               buy_quantity = excluded.buy_quantity,
               sell_price = excluded.sell_price,
               sell_quantity = excluded.sell_quantity""",
            (str(item), date, buy_price, buy_quantity, sell_price, sell_quantity)
        )


def update_items_in_sql(cursor, items):
    """
    Updates the items table in item_data.db with items data.

    Args:
        cursor (sqlite3.Cursor): The cursor object for executing SQL queries.
        items (list): The list of items containing item data.
    """
    rows = []

    for item in items:
        name = item.get("name")
        item_type = item.get("type")
        level = item.get("level")
        flags = " ".join(item.get("flags")) if item.get("flags") else None
        rarity = item.get("rarity")
        icon = item.get("icon")

        rows.append((str(item), name, item_type, level, flags, rarity, icon))

    cursor.executemany(
        """INSERT INTO items (id, name, type, level, flags, rarity, icon)
           VALUES (?, ?, ?, ?, ?, ?, ?)
           ON CONFLICT DO NOTHING""",
        rows
    )


def main():
    # Connect to item_data.db
    connection = sqlite3.connect("item_data.db")
    cursor = connection.cursor()

    # Fetch and update price data
    price_page = 0
    while True:
        prices = get_data(PRICES_URL, price_page)
        if len(prices) < 200:
            break
        update_prices_in_sql(cursor, prices)
        price_page += 1

        # Commit changes in batches
        if price_page % BATCH_SIZE == 0:
            print(f"Committed {price_page*200} rows in prices table.")
            connection.commit()
    
    connection.commit()
    cursor.execute("SELECT COUNT(id) FROM prices")
    prices_len = cursor.fetchone()[0]
    print(f"Updated {prices_len} prices!")


    # Fetch and update item data
    item_page = 0
    while True:
        items = get_data(ITEMS_URL, item_page)
        if len(items) < 200:
            break
        update_items_in_sql(cursor, items)
        item_page += 1

        # Commit changes in batches
        if item_page % BATCH_SIZE == 0:
            print(f"Committed {item_page*200} rows in items table.")
            connection.commit()

    connection.commit()
    cursor.execute("SELECT COUNT(id) FROM items")
    items_len = cursor.fetchone()[0]
    print(f"Updated {prices_len} prices and {items_len} items details!")
    
    connection.close()
    


if __name__ == "__main__":
    main()

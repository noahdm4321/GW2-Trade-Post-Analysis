import time
import requests
import json
import sqlite3


def get_item_data(item_id):
    item_details_url = "https://api.guildwars2.com/v2/items/"
    item_url = item_details_url + str(item_id)
    item_response = requests.get(item_url)
    return item_response.json()


def get_commerce_data(item_id):
    commerce_prices_url = "https://api.guildwars2.com/v2/commerce/prices/"
    price_url = commerce_prices_url + str(item_id)
    price_response = requests.get(price_url)
    return price_response.json()


def update_data_in_sql(item_id):
    item_data = get_item_data(item_id)
    commerce_data = get_commerce_data(item_id)

    name = item_data.get("name")
    item_type = item_data.get("type")
    level = item_data.get("level")
    flags = " ".join(item_data.get("flags", []))
    rarity = item_data.get("rarity")
    icon = item_data.get("icon")

    buy_price = commerce_data["buys"]["unit_price"]
    buy_quantity = commerce_data["buys"]["quantity"]
    sell_price = commerce_data["sells"]["unit_price"]
    sell_quantity = commerce_data["sells"]["quantity"]

    # Check if the data in the SQL file is already aligned with the website data
    connection = sqlite3.connect("item_data.db")
    cursor = connection.cursor()
    cursor.execute(
        "SELECT name, type, level, flags, rarity, icon, buy_price, buy_quantity, sell_price, sell_quantity FROM items WHERE id=?",
        (item_id,),
    )
    row = cursor.fetchone()

    # If the data is not aligned, update it in the SQL file
    if not row or row != (
        name,
        item_type,
        level,
        flags,
        rarity,
        icon,
        buy_price,
        buy_quantity,
        sell_price,
        sell_quantity,
    ):
        cursor.execute(
            """INSERT OR REPLACE INTO items (id, name, type, level, flags, rarity, icon, buy_price, buy_quantity, sell_price, sell_quantity)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                item_id,
                name,
                item_type,
                level,
                flags,
                rarity,
                icon,
                buy_price,
                buy_quantity,
                sell_price,
                sell_quantity,
            ),
        )

    connection.commit()
    connection.close()


def format_time(seconds):
    minutes = int(seconds // 60)
    seconds = int(seconds % 60)
    return f"{minutes:02d} minutes {seconds:02d} seconds"


def main():
    commerce_prices_url = "https://api.guildwars2.com/v2/commerce/prices"
    response = requests.get(commerce_prices_url)
    item_ids = response.json()
    print(f"Updating {len(item_ids)} items...")

    count = 0
    start_time = time.time()
    for item_id in item_ids:
        update_data_in_sql(item_id)
        count += 1
        if count % 100 == 0:
            elapsed_time = time.time() - start_time
            print(
                f"Processed {count} of {len(item_ids)} items in {format_time(elapsed_time)}..."
            )

    print(f"Data update completed in {format_time(elapsed_time)}!")


if __name__ == "__main__":
    main()

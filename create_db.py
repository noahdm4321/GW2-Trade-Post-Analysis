import sqlite3

# Connect to the database (will create a new one if it doesn't exist)
conn = sqlite3.connect("data.db")
cursor = conn.cursor()

# Create tables if none exist
cursor.execute(
    """
    CREATE TABLE IF NOT EXISTS [items] (
        [id] MEDIUMINT PRIMARY KEY NOT NULL, 
        [name] VARCHAR(64) NOT NULL, 
        [type] VARCHAR(32) NOT NULL, 
        [level] TINYINT NOT NULL, 
        [flags] VARCHAR(256) NULL, 
        [value] BIGINT NULL, 
        [rarity] VARCHAR(16) NULL, 
        [icon] VARCHAR(128) NULL
    )"""
)

cursor.execute(
    """
    CREATE TABLE IF NOT EXISTS [prices] (
        [item_id] MEDIUMINT PRIMARY KEY NOT NULL, 
        [date_updated] DATETIME NOT NULL, 
        [whitelisted] BOOLEAN NOT NULL, 
        [buy_price] BIGINT NULL, 
        [buy_quantity] BIGINT NULL, 
        [sell_price] BIGINT NULL, 
        [sell_quantity] BIGINT NULL
    )"""
)

cursor.execute(
    """
    CREATE TABLE IF NOT EXISTS [recipes] (
        [id] SMALLINT PRIMARY KEY NOT NULL, 
        [type] VARCHAR(32) NOT NULL, 
        [output_id] MEDIUMINT NOT NULL, 
        [output_count] TINYINT NOT NULL, 
        [input1_id] MEDIUMINT NOT NULL, 
        [input1_count] TINYINT NOT NULL, 
        [input2_id] MEDIUMINT NULL, 
        [input2_count] TINYINT NULL, 
        [input3_id] MEDIUMINT NULL, 
        [input3_count] TINYINT NULL, 
        [input4_id] MEDIUMINT NULL, 
        [input4_count] TINYINT NULL, 
        [time] MEDIUMINT NULL, 
        [disciplines] VARCHAR(128) NULL, 
        [min_rating] SMALLINT NULL, 
        [auto_learn] BOOLEAN NOT NULL
    )"""
)

# Commit the changes and close the connection
conn.commit()
conn.close()

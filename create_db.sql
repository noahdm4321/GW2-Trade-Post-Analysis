CREATE TABLE [items] (
	[id] MEDIUMINT PRIMARY KEY NOT NULL, 
	[name] VARCHAR(64) NOT NULL, 
	[type] VARCHAR(32) NOT NULL, 
	[level] TINYINT NOT NULL, 
	[flags] VARCHAR(256) NULL, 
	[rarity] VARCHAR(16) NULL, 
	[icon] VARCHAR(128) NULL, 
);

CREATE TABLE [prices] (
	[id] MEDIUMINT PRIMARY KEY NOT NULL, 
	[date_updated] DATETIME NOT NULL, 
	[buy_price] BIGINT NULL, 
	[buy_quantity] BIGINT NULL, 
	[sell_price] BIGINT NULL, 
	[sell_quantity] BIGINT NULL, 
);

CREATE VIEW [filtered] AS 
	SELECT [items].[id], [date_updated], [name], [type], [level], [flags], [rarity], [buy_price], [buy_quantity], [sell_price], [sell_quantity] 
	FROM [items] 
		INNER JOIN [prices] ON prices.id = items.id 
	WHERE [type] IN ('Armor', 'Weapon') 
		AND [level] = 80 
		AND [rarity] = 'Exotic' 
		AND [buy_price] IS NOT NULL 
	ORDER BY [sell_price] DESC;

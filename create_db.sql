CREATE TABLE [items] (
	[id] MEDIUMINT PRIMARY KEY NOT NULL, 
	[name] VARCHAR(64) NOT NULL, 
	[type] VARCHAR(32) NOT NULL, 
	[level] TINYINT NOT NULL, 
	[flags] VARCHAR(256) NULL, 
	[rarity] VARCHAR(16) NULL, 
	[icon] VARCHAR(128) NULL
);

CREATE TABLE [prices] (
	[item_id] MEDIUMINT PRIMARY KEY NOT NULL, 
	[date_updated] DATETIME NOT NULL, 
	[whitelisted] BOOLEAN NOT NULL, 
	[buy_price] BIGINT NULL, 
	[buy_quantity] BIGINT NULL, 
	[sell_price] BIGINT NULL, 
	[sell_quantity] BIGINT NULL
);

CREATE TABLE [recipes] (
	[id] SMALLINT PRIMARY KEY NOT NULL, 
	[type] VARCHAR(32) NOT NULL, 
	[output_id] MEDIUMINT NOT NULL, 
	[output_count] TINYINT NOT NULL, 
	[input_id_1] MEDIUMINT NOT NULL, 
	[input_count_1] TINYINT NOT NULL, 
	[input_id_2] MEDIUMINT NULL, 
	[input_count_2] TINYINT NULL, 
	[input_id_3] MEDIUMINT NULL, 
	[input_count_3] TINYINT NULL, 
	[input_id_4] MEDIUMINT NULL, 
	[input_count_4] TINYINT NULL, 
	[time] MEDIUMINT NULL, 
	[disciplines] VARCHAR(128) NULL, 
	[min_rating] SMALLINT NULL, 
	[auto_learn] BOOLEAN NOT NULL
);

CREATE VIEW [items_data] AS 
	SELECT [id], [name], [type], [level], [flags], [rarity], [whitelisted], [buy_price], [buy_quantity], [sell_price], [sell_quantity] 
	FROM [items] 
		INNER JOIN [prices] ON prices.item_id = items.id 
	WHERE [buy_price] IS NOT NULL 
	ORDER BY [sell_price] DESC;

CREATE VIEW [recipes_data] AS 
	SELECT r.[type], 
		r.[output_id], output.[name] AS [output_name], r.[output_count],
		r.[input_id_1], input1.[name] AS input1_name, r.[input_count_1],
		r.[input_id_2], input2.[name] AS input2_name, r.[input_count_2],
		r.[input_id_3], input3.[name] AS input3_name, r.[input_count_3],
		r.[input_id_4], input4.[name] AS input4_name, r.[input_count_4], 
		r.[disciplines], r.[min_rating]
	FROM [recipes] r
	LEFT JOIN
		[items] output ON r.[output_id] = output.[id]
	LEFT JOIN
		[items] input1 ON r.[input_id_1] = input1.[id]
	LEFT JOIN
		[items] input2 ON r.[input_id_2] = input2.[id]
	LEFT JOIN
		[items] input3 ON r.[input_id_3] = input3.[id]
	LEFT JOIN
		[items] input4 ON r.[input_id_4] = input4.[id];

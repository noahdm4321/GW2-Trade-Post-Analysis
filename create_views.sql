--[
	Each block of code must be exicuted separaely! To do this, select the block of code you wish to exicute, right click, and select "Run Selected Query".
]--

-- Drop views if exists
DROP VIEW IF EXISTS [items_data]
DROP VIEW IF EXISTS [recipes_data]

-- Create new views
CREATE VIEW [items_data] AS 
	SELECT [id], [name], [type], [level], [flags], [rarity], [whitelisted], [buy_price], [sell_price]
	FROM [items] 
		INNER JOIN [prices] ON prices.item_id = items.id 
	ORDER BY [sell_price] DESC

CREATE VIEW [recipes_data] AS 
	SELECT 
		output.[name] AS output_name, r.[output_count],
		input1.[name] AS input1_name, r.[input1_count],
		input2.[name] AS input2_name, r.[input2_count],
		input3.[name] AS input3_name, r.[input3_count],
		input4.[name] AS input4_name, r.[input4_count], 
		r.[type], r.[auto_learn], r.[time], r.[disciplines], r.[min_rating]
	FROM [recipes] r
		LEFT JOIN [items] output ON r.[output_id] = output.[id]
		LEFT JOIN [items] input1 ON r.[input1_id] = input1.[id]
		LEFT JOIN [items] input2 ON r.[input1_id] = input2.[id]
		LEFT JOIN [items] input3 ON r.[input2_id] = input3.[id]
		LEFT JOIN [items] input4 ON r.[input3_id] = input4.[id]
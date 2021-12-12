import requests
import json

## Database functions to call in cogs ##


api = requests.get('https://api.guildwars2.com/v2/commerce/prices')
id = api.json() if api and api.status_code == 200 else None
price = dict()
for n in id:
	item = requests.get('https://api.guildwars2.com/v2/commerce/prices/'+str(n))
	price[n] = item.json() if item and item.status_code == 200 else None
	print(n)
	with open('db.json', 'w+') as file:
		json.dump(price, file)


## read database ##
def read(key, id):
	with open('database/db.json', "r") as json_file:
		data = json_file.read()
	data = json.loads(data)
	return data[key][id]

## write to database ##
def write(key, id, value):
	with open("database/db.json", "r") as json_file:
		data = json_file.read()
	data = json.loads(data)
	data[key][id] = value
	with open("database/db.json", "w") as json_file:
		json.dump(data, json_file)
	return True

## append to database list ##
def append(key, id, value):
	with open("database/db.json", "r") as json_file:
		data = json_file.read()
	data = json.loads(data)
	data[key][id] = data[key][id].append(value)
	with open("database/db.json", "w") as json_file:
		json.dump(data, json_file)
	return True
import requests
import json

## Update db.json ##

api = requests.get('https://api.guildwars2.com/v2/commerce/prices')
id = api.json() if api and api.status_code == 200 else None
price = dict()
for n in id:
	item = requests.get('https://api.guildwars2.com/v2/commerce/prices/'+str(n))
	price[n] = item.json() if item and item.status_code == 200 else None
	del price[n]['id']
	del price[n]['whitelisted']
	item = requests.get('https://api.guildwars2.com/v2/items/'+str(n))
	apple = item.json() if item and item.status_code == 200 else None
	price[n]['name'] = apple['name']
	print(n)
	with open('db.json', 'w+') as file:
		json.dump(price, file)

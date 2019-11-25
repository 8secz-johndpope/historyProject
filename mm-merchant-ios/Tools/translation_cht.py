import json
import requests
import sys
reload(sys)
sys.setdefaultencoding('utf-8')

api = "https://dev-plat.mymm.com/api/reference/translation?cc="

lang = "CHT"

r = requests.get(api+lang, verify=False)

jsonObject = json.loads(r.text)

translation = jsonObject["TranslationMap"]

strings = []

for key, value in translation.items():
	if value != None:
		strings.append('"' + key + '"' + " = " + '"' + value.replace("\n", "\\n").replace("\"", "\\\"") + '"' + ";")

print("\n".join(strings))
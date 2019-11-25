import xml.etree.ElementTree as ET
import os

xml = os.path.join(os.path.dirname(os.path.abspath(__file__)), '../merchant-ios/page_router.xml')
tree = ET.parse(xml)
root = tree.getroot()

list = []
for child in root:
	list.append("\t\tstatic let " + child.attrib['url'].replace('https://m.mymm.com/#/', '').replace('https://m.mymm.com/','').replace('#/', '_').replace('https://','').replace('{','').replace('}','').replace('/','_').replace(':','_').replace('.','_').replace('-','_') + ' = "' + child.attrib['url'] + '"')

# iOS	
print "extension Navigator {\n\tstruct mymm {\n" + "\n".join(list) + "\n\t}\n}"
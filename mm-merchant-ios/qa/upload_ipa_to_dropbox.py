#!/usr/bin/env python

import argparse
import datetime
import dropbox
import os
import plistlib
import re
import time

def upload(dbx, file, target):
  data = ''
  with open(file) as f:
    data = f.read()

  mode = dropbox.files.WriteMode.overwrite

  try:
    res = dbx.files_upload(data, '/ios' + target, dropbox.files.WriteMode.overwrite, client_modified=datetime.datetime(*time.gmtime(os.path.getmtime(file))[:6]), mute=True)
    return res
  except dropbox.exceptions.ApiError as err:
    print('*** API error', err)
    return None

def share(dbx, target):
  try:
    res = dbx.sharing_create_shared_link('/ios' + target)
    url = re.sub(r'www.dropbox.com', 'dl.dropboxusercontent.com', res.url)
    url = re.sub(r'\?dl=0', '', url)
    return url
  except dropbox.exceptions.ApiError as err:
    print('*** API error', err)
    return None

def delete_old_files(dbx, days):
  try:
    search_res = dbx.files_search('/ios', 'app-storefront-');
    for m in search_res.matches:
      client_modified = m.metadata.client_modified
      if client_modified < datetime.datetime.now() - datetime.timedelta(days = days):
        dbx.files_delete(m.metadata.path_lower)
    return search_res
  except dropbox.exceptions.ApiError as err:
    print('*** API error', err)
    return None

parser = argparse.ArgumentParser()
parser.add_argument('--appname', default='app-storefront-80-develop-6f8270e-device')
parser.add_argument('--token', default='3e1oGbExpbAAAAAAAAAALbCFYwh4tbTObL0el0q20_NdDfJJtxk6CVX4ucnGhu2C')
parser.add_argument('--days', default=2)
args = parser.parse_args()

# create dropbox
dbx = dropbox.Dropbox(args.token)

# delete 6 days old files
delete_old_files(dbx, args.days);

# upload .ipa
upload(dbx, '{0}.ipa'.format(args.appname), '/{0}.ipa'.format(args.appname))

# share .ipa
share_ipa_link = share(dbx, '/{0}.ipa'.format(args.appname))

# write plist
metadata = dict()
metadata['bundle-identifier'] = 'com.mm.storefront'
metadata['bundle-version'] = '1.0'
metadata['kind'] = 'software'
metadata['title'] = 'storefront-ios'

pl = dict(
  items = [
    dict(assets = [
      dict(kind = 'software-package', url = share_ipa_link),
      dict(kind = 'display-image', url = 'https://dl.dropboxusercontent.com/s/9ykit6hugbx7izb/AppIcon60x60%403x.png'),
      dict(kind = 'full-size-image', url = 'https://dl.dropboxusercontent.com/s/9ykit6hugbx7izb/AppIcon60x60%403x.png')
    ], metadata = metadata)
  ]
)

plistlib.writePlist(pl, '{0}.plist'.format(args.appname))

# upload .plist
upload(dbx, '{0}.plist'.format(args.appname), '/{0}.plist'.format(args.appname))

# share .plist
share_plist_link = share(dbx, '/{0}.plist'.format(args.appname))

# write html
with open(args.appname + '.html', 'w') as f:
  f.write('dummy')

# upload .html
upload(dbx, '{0}.html'.format(args.appname), '/{0}.html'.format(args.appname))

# share .html
share_html_link = share(dbx, '/{0}.html'.format(args.appname))

# re-write html
with open(args.appname + '.html', 'w') as f:
  s = '''<!DOCTYPE html>
<html>
<head>
  <title>''' + args.appname + '''</title>
</head>
<body>
  <h1>
    <a href="itms-services://?action=download-manifest&amp;url=''' + share_plist_link + '''">''' + args.appname + '''</a>
  </h1>
  <img src="https://api.qrserver.com/v1/create-qr-code/?data=''' + share_html_link + '''">
</body>
</html>'''
  f.write(s)

# re-upload .html
upload(dbx, '{0}.html'.format(args.appname), '/{0}.html'.format(args.appname))

# re-share .html
share_html_link = share(dbx, '/{0}.html'.format(args.appname))

print share_html_link

exit(0)

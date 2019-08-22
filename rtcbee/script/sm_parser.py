"""Parses provided JSON in first argument and outputs 0 or valid IP.

Usage:

$ python sm_parser.py $(curl -X GET -H "Content-type:application/json" "https://stream-manager.url/streammanager/api/2.0/event/live/todd?action=subscribe")

- outputs either:
    * '0' - error
    * 'xxx.xxx.xxx.xxx' - endpoint IP

"""

import json
import sys

try:
    jdata = sys.argv[1]
    data = json.loads(jdata)
except ValueError as e:
    print(0)
    sys.exit("Something went wrong: %s" % e.message)

if 'serverAddress' in data:
    print("%s" % data["serverAddress"])
elif 'errorMessage' in data:
    print(0)
else:
    print(0)


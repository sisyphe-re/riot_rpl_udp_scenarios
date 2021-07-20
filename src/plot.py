#!/usr/bin/env nix-shell
#! nix-shell -p "python3.withPackages(ps: with ps; [ pandas matplotlib sqlite ])"
#! nix-shell -i python3

import string
from datetime import datetime
from datetime import timedelta
from collections import defaultdict
import pandas as pd
import sqlite3 as sq
import itertools
import matplotlib.pyplot as plt
import sys

def extract_rank(node, timestamp):
    for obj in evolution[node]:
        if obj['start'] <= pd.Timestamp(timestamp) and pd.Timestamp(timestamp) <= obj['end']:
            return int(obj['value'])
        elif obj['start'] <= pd.Timestamp(timestamp) and 'end' not in obj.keys():
            return int(obj['value'])

if len(sys.argv)!=3:
    print(f"Usage: {sys.argv[0]} <data.db3> </path/to/output_directory>")
    exit(-1)

filename = sys.argv[1]
output_dir = sys.argv[2]
con = sq.connect(filename)
cur = con.cursor()

# Compute Latency between reception and transmission 
udp = pd.read_sql_query("select Node,Timestamp,Payload from udp;", con)
server = pd.read_sql_query("select * from server;", con)

server["payload"] = server["payload"].str.upper()
server["Timestamp"] = pd.to_datetime(server["Timestamp"], format='%Y-%m-%d %H:%M:%S.%f')
udp["Timestamp"] = pd.to_datetime(udp["Timestamp"], format='%Y-%m-%d %H:%M:%S.%f')

# Drop payload that have not been received
udp = udp.drop_duplicates(subset=['payload'], keep=False)
join = udp.set_index('payload').join(server.set_index('payload'), lsuffix='_udp', rsuffix='_server')
join["Delay"] = (join["Timestamp_server"] - join["Timestamp_udp"])
join["Delay"] = join.apply(lambda x: x["Delay"].total_seconds(), axis=1)

# Only consider packet with a positive delay
positive = join[join["Delay"]>0.0]

# Transform ranks (measured each second) into ranges of constant values
evolution = defaultdict(list)
for node in set(positive["Node"]):
    req = f"SELECT Timestamp,Rank from rpl_stats_dodag where Node='{node}'";
    start = None
    end = None
    val = None
    for timestamp, rank in con.execute(req):
        if start == None:
            start = pd.Timestamp(timestamp)
            val = rank
            end = pd.Timestamp(timestamp)
        if val == rank:
            end = pd.Timestamp(timestamp)
        else:
            evolution[node].append({'start': start, 'end': end, 'value': val})
            val = rank
            begin = pd.Timestamp(timestamp)
            end = pd.Timestamp(timestamp)
    evolution[node].append({'start': start, 'end': end, 'value': val})

positive['Rank']=positive.apply(lambda x: extract_rank(x[0], x['Timestamp_udp']), axis=1)
positive['color'] = positive['Rank'].apply(lambda x: 'red' if x <= 512 else 'green' if x <= 768 else  'blue' if x <= 1024  else 'yellow')
plt.scatter(x='Timestamp_udp', y='Delay', data=positive, color='color')
plt.xlabel("Date")
plt.ylabel("Latency (s)")
plt.savefig(f"{output_dir}/delay.svg")

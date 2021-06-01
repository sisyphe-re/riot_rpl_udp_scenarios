#!/usr/bin/env python3
import sys
import datetime
import socket

IP = "::"
PORT = 1337

sock = socket.socket(family=socket.AF_INET6, type=socket.SOCK_DGRAM)
sock.bind((IP, PORT))

print("Date,Address,Port,Data", flush=True)
while True:
    data, addr = sock.recvfrom(1024)
    now = datetime.datetime.now()
    print("%s,%s,%s,%s" % (now, addr[0], addr[1], data.hex()[:10]), flush=True)
import os
import sys
import time
import serial
import serial.tools.list_ports

print('Search...')
ports = serial.tools.list_ports.comports(include_links=False)
for port in ports :
    print('Find port '+ port.device)

# ser = serial.Serial(port.device)
# if ser.isOpen():
#     ser.close()

# ser = serial.Serial(port.device, 9600, timeout=1)
# ser.flushInput()
# ser.flushOutput()
# print('Connect ' + ser.name)
import os
import sys
import time
import serial
import serial.tools.list_ports
from logicAnalyzer import *


def getAvailableSerialPorts():
	ports = serial.tools.list_ports.comports(include_links=False)
	port_names = []
	for port in ports :
		port_names.append(port.device)

	return port_names

def configureLogicAnalyzer(las):

	ser = serial.Serial(port=las.port, baudrate=las.baud, timeout=None,xonxoff=False)
	ser.reset_input_buffer()
	ser.open
	# set scaler
	# MSB
	ser.write(SCALER_HEADER)
	ser.write(bytes([(las.scaler>>8) & 0xFF]))
	# LSB
	ser.write(SCALER_HEADER)
	ser.write(bytes([(las.scaler-1) & 0xFF]))
	# set precapture memory size
	# MSB
	ser.write(PRECAP_SIZE)
	ser.write(bytes([(las.precap_size>>8) & 0xFF]))
	# LSB
	ser.write(PRECAP_SIZE)
	ser.write(bytes([(las.precap_size) & 0xFF]))
	# set channel
	ser.write(CHANNEL_HEADER)
	ser.write(bytes([las.channel]))
	# trigger type
	ser.write(TRIG_TYPE_HEADER)
	ser.write(bytes([las.trigger_type]))

	ser.close

def enableLogicAnalyzer(las):

	ser = serial.Serial(port=las.port, baudrate=las.baud, timeout=None,xonxoff=False)
	ser.reset_input_buffer()
	ser.open

	ser.write(ENABLE_HEADER)
	ser.write(b'\x00')

	ser.write(ENABLE_HEADER)
	ser.write(b'\x01')

	ser.close

def readIncomingSerialData(las):
	ser = serial.Serial(port=las.port, baudrate=las.baud, timeout=None,xonxoff=False)
	ser.reset_input_buffer()
	ser.open
	bs = []
	total_bytes = 0
	# TODO add timer that cancels if limit is reached
	while True:
		bytesToRead = ser.inWaiting()
		if bytesToRead > 0:
			total_bytes += bytesToRead
			bs.append(ser.read(bytesToRead))
			if total_bytes == las.mem_depth*las.bytes_per_row:
				break

	ser.write(ENABLE_HEADER)
	ser.write(b'\x00')
	ser.close
	return convertByteLists(bs)

def convertByteLists(bs):
	combined = bs[0]
	for x in range(1, len(bs)):
		combined += bs[x]

	return combined

import os
import sys
import time
import serial
import serial.tools.list_ports
from threading import Thread

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

	# ser.write(ENABLE_HEADER)
	# ser.write(b'\x00')

	# ser.write(ENABLE_HEADER)
	# ser.write(b'\x01')

	ser.close

class AsyncReadSerial(Thread):
	def __init__(self, las):
		super().__init__()

		self.las = las
		self.kill = False

	def run(self):
		data = self.readIncomingSerialData()
		if data:
			readInputstream(data, self.las)

	def readIncomingSerialData(self):
		ser = serial.Serial(port=self.las.port, baudrate=self.las.baud, timeout=None,xonxoff=False)
		ser.reset_input_buffer()
		ser.open
		ser.write(ENABLE_HEADER)
		ser.write(b'\x00')

		ser.write(ENABLE_HEADER)
		ser.write(b'\x01')
		byte_chunks = []
		total_bytes = 0
		
		while not self.kill:
			bytesToRead = ser.inWaiting()
			if bytesToRead > 0:
				total_bytes += bytesToRead
				byte_chunks.append(ser.read(bytesToRead))
				if total_bytes == self.las.mem_depth*self.las.bytes_per_row:
					break

		if self.kill:
			ser.write(STOP_HEADER)
			ser.write(b'\x01')
			ser.write(STOP_HEADER)
			ser.write(b'\x00')

		ser.write(ENABLE_HEADER)
		ser.write(b'\x00')
		ser.close

		if total_bytes > 0:
			return self.convertByteLists(byte_chunks)
		else:
			return None

	def convertByteLists(self, byte_chunks):
		combined = byte_chunks[0]
		for x in range(1, len(byte_chunks)):
			combined += byte_chunks[x]

		return combined

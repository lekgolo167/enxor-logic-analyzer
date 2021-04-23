# Enxor Logic Analyzer
# Copyright (C) 2021  Matthew Crump

# 		This program is free software: you can redistribute it and/or modify
# 		it under the terms of the GNU General Public License as published by
# 		the Free Software Foundation, either version 3 of the License, or
# 		(at your option) any later version.

# 		This program is distributed in the hope that it will be useful,
# 		but WITHOUT ANY WARRANTY; without even the implied warranty of
# 		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 		GNU General Public License for more details.

# 		You should have received a copy of the GNU General Public License
# 		along with this program.  If not, see <https://www.gnu.org/licenses/>.

import os
import sys
import time
import serial
import serial.tools.list_ports
from threading import Thread

from logicAnalyzer import *


def get_available_serial_ports():
	ports = serial.tools.list_ports.comports(include_links=False)
	port_names = []
	for port in ports :
		port_names.append(port.device)

	return port_names

def configure_logic_analyzer(las):

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

	# ensure enable is off to start to reset the logic
	ser.write(ENABLE_HEADER)
	ser.write(b'\x00')
	# ensure start read is off
	ser.write(START_READ_HEADER)
	ser.write(b'\x00')

	ser.close


class AsyncReadSerial(Thread):
	def __init__(self, las):
		super().__init__()

		self.las = las
		self.kill = False
		self.full = False
		self.triggered = False
		self.start_read = False
		self.total_bytes = 0

	def run(self):
		data = self.read_incoming_serial_data()
		if data:
			read_input_stream(data, self.las)

	def read_incoming_serial_data(self):
		ser = serial.Serial(port=self.las.port, baudrate=self.las.baud, timeout=None,xonxoff=False)
		ser.reset_input_buffer()
		ser.open

		byte_chunks = []

		ser.write(ENABLE_HEADER)
		ser.write(b'\x01')

		while (not self.full or not self.triggered) and not self.kill:
			bytesToRead = ser.inWaiting()

			if bytesToRead >= 2:
				print("TRIGGERED & DONE")
				self.full = True
				self.triggered = True
				ser.read(bytesToRead)
				break

			elif bytesToRead == 1:
				b = ser.read(bytesToRead)

				if b == TRIGGERED_STATE_HEADER:
					print("TRIGGERED")
					self.triggered = True
				elif b == DONE_HEADER:
					print("DONE")
					self.done = True
					break
				else:
					print("ERROR -- RECEIVED UNEXPECTED BYTE")
					break

		if self.kill:
			print("STOPPING")
			ser.write(STOP_HEADER)
			ser.write(b'\x01')
			ser.write(STOP_HEADER)
			ser.write(b'\x00')
		
		max_time =  ((1 / self.las.baud) * self.las.mem_depth * self.las.bytes_per_row * 8) + 3.0
		timeout = time.time() + max_time

		if self.triggered:
			print("START READ")
			self.start_read = True
			ser.write(START_READ_HEADER)
			ser.write(b'\x01')
		else:
			ser.write(ENABLE_HEADER)
			ser.write(b'\x00')
			print("NO DATA")
			return None

		while timeout > time.time():
			bytesToRead = ser.inWaiting()
			if bytesToRead > 0:
				self.total_bytes += bytesToRead
				byte_chunks.append(ser.read(bytesToRead))
				if (self.total_bytes >= self.las.mem_depth*self.las.bytes_per_row):
					break

		ser.write(START_READ_HEADER)
		ser.write(b'\x00')

		ser.write(ENABLE_HEADER)
		ser.write(b'\x00')

		ser.close()

		if self.total_bytes > 0:
			return self.convert_byte_lists(byte_chunks)
		else:
			return None

	def convert_byte_lists(self, byte_chunks):
		combined = byte_chunks[0]
		for x in range(1, len(byte_chunks)):
			combined += byte_chunks[x]

		return combined

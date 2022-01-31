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

import math
import json

TRIGGER_DELAY_ENABLE_HEADER = b'\xF7'
TRIGGER_DELAY_HEADER = b'\xF8'
SCALER_HEADER = b'\xFA'
CHANNEL_HEADER = b'\xFB'
TRIG_TYPE_HEADER = b'\xFC'
ENABLE_HEADER = b'\xFD'
STOP_HEADER = b'\xFF'
PRECAP_SIZE = b'\xFE'
PRE_BUFFER_HEADER = b'\xA1'
POST_BUFFER_HEADER = b'\xA3'
START_READ_HEADER = b'\xF9'
TRIGGERED_STATE_HEADER = b'\xA7'
DONE_HEADER = b'\xAF'
TRIGGER_RISING_ENDGE = 1
TRIGGER_FALLING_ENDGE = 0
MAX_TIMER_COUNT = 255


class LogicAnalyzerModel():
	def __init__(self):
		self.port = ''
		self.baud = 115200
		self.scaler = 1
		self.channel = 0
		self.trigger_type = TRIGGER_RISING_ENDGE
		self.trigger_delay_enabled = 0
		self.trigger_delay = 0
		self.mem_depth = 0
		self.precap_size = 4
		self.pre_trigger_byte_count = 0
		self.post_trigger_byte_count = 0
		self.total_time_units = 0
		self.channel_data = []
		self.timestamps = []
		self.x_axis = []
		self.num_channels = 0
		self.bytes_per_row = 0
		self.clk_freq = 1

	def get_max_capture_time(self, divisor):
		return (MAX_TIMER_COUNT*self.mem_depth) / (self.clk_freq/divisor)

	def get_min_capture_time(self, divisor):
		return (self.mem_depth) / (self.clk_freq/divisor)

	def get_samples_interval_in_seconds(self, divisor):
		return 1 / (self.clk_freq / divisor)

	def get_min_max_string(self, divisor):
		_min = self.get_min_capture_time(divisor)
		_max = self.get_max_capture_time(divisor)
		_rate = self.get_samples_interval_in_seconds(divisor)

		return convert_sec_to_relavent_time(_rate) + " : " \
			   + convert_sec_to_relavent_time(_min) + " - " \
			   + convert_sec_to_relavent_time(_max)

	def get_trigger_delay_string(self, trigger_delay):
		delay_in_seconds = trigger_delay * self.get_samples_interval_in_seconds(self.scaler)
		return convert_sec_to_relavent_time(delay_in_seconds)
		
	def initialize_from_config_file(self, file_path):
		with open(file_path, 'r') as config_file:
			obj = json.loads(config_file.read())

			# if config file does not have a field, keep it the same
			self.baud = obj.get('baud_rate', self.baud)
			self.port = obj.get('port_name', self.port)
			self.precap_size = obj.get('precap_size', self.precap_size)
			self.scaler = obj.get('sample_rate', self.scaler)
			self.channel = obj.get('trig_channel', self.channel)
			self.trigger_type = obj.get('trig_type', self.trigger_type)
			# these fields are required
			try:
				self.mem_depth = obj['mem_depth']
				self.clk_freq = obj['clk_freq']
				self.num_channels = obj['num_channels']
				self.bytes_per_row = (self.num_channels // 8) + 2
			except Exception:
				return False

			return True

	def save_to_config_file(self, file_path):
		with open(file_path, 'w') as config_file:
			text = {
				"baud_rate" : self.baud,
				"port_name" : self.port,
				"clk_freq" : self.clk_freq,
				"mem_depth" : self.mem_depth,
				"precap_size" : self.precap_size,
				"sample_rate" : self.scaler,
				"trig_channel" : self.channel,
				"trig_type" : self.trigger_type,
				"num_channels" : self.num_channels
			}
			json.dump(text,config_file)
			

def write_logic_analyzer_data_to_file(file_path, la):

	with open(file_path, 'wb') as binary_file:
		# set 1st byte to number of channels
		binary_file.write(bytes([la.num_channels]))
		# set 2nd byte to trigger channel
		binary_file.write(bytes([la.channel]))
		# set 3rd byte to the memory depth
		binary_file.write(bytes([int(math.log2(la.mem_depth))]))
		# set bytes 4 - 7 to the clock frequency
		binary_file.write(la.clk_freq.to_bytes(4,byteorder='little'))
		# set bytes 8 and 9 to the sample rate
		binary_file.write(la.scaler.to_bytes(2,byteorder='little'))

		# format: <TYPE> <N_DATA_BYTES> <TIMESTAMP>
		for entry_num in range(la.pre_trigger_byte_count + la.post_trigger_byte_count):
			# set the data type
			if entry_num < la.pre_trigger_byte_count:
				binary_file.write(PRE_BUFFER_HEADER)
			else:
				binary_file.write(POST_BUFFER_HEADER)

			# runs for the number of bytes needed; 8 channels = once, 16 channels = twice
			for offset in range(0, la.num_channels,8):
				byte = 0
				for bit in range(8):
					# combine separate channel data lists into one byte for each index
					byte = byte | (la.channel_data[offset+bit][entry_num] << bit)

				binary_file.write(bytes([byte]))

			# set the timestamp
			binary_file.write(bytes([la.timestamps[entry_num]]))

def read_logic_analyzer_data_from_file(file_path):

	with open(file_path, 'rb') as binary_file:
		la = LogicAnalyzerModel()

		# read 1st byte to get number of channels
		la.num_channels = ord(binary_file.read(1))
		la.bytes_per_row = (la.num_channels // 8) + 2
		# read 2nd byte to get trigger channel
		la.channel = ord(binary_file.read(1))
		# read 3rd byte for the memory depth
		la.mem_depth = int(math.pow(2 ,ord(binary_file.read(1))))
		# read bytes 4 - 7 for the clock frequency
		la.clk_freq = int.from_bytes(binary_file.read(4), 'little')
		# read bytes 8 and 9 for the sample rate
		la.scaler = int.from_bytes(binary_file.read(2), 'little')

		for _ in range(la.num_channels):
			la.channel_data.append([])
		
		# if there are less bytes than the memory size, 'with open' just closes without crashing
		for _ in range(la.mem_depth):
			byte_header = binary_file.read(1)

			if not byte_header:
				break
			elif byte_header == PRE_BUFFER_HEADER:
				la.pre_trigger_byte_count += 1
			elif byte_header == POST_BUFFER_HEADER:
				la.post_trigger_byte_count += 1
			else:
				# This will realign the bytes to get correct offset
				continue

			# runs for the number of bytes needed; 8 channels = once, 16 channels = twice
			for offset in range(0, la.num_channels, 8):
				current_byte = binary_file.read(1)
				data = ord(current_byte)

				for bit in range(8):
					# separate the byte into each individual channel
					la.channel_data[bit+offset].append((data >> bit) & 1)

			timestamp = ord(binary_file.read(1))
			la.timestamps.append(timestamp)
			la.total_time_units += timestamp
			la.x_axis.append(la.total_time_units)

		return la

def read_input_stream(byte_arr, las):
	las.channel_data = []
	las.x_axis = []
	las.timestamps = []
	las.post_trigger_byte_count = 0
	las.pre_trigger_byte_count = 0
	las.total_time_units = 0

	for _ in range(las.num_channels):
		las.channel_data.append([])

	entry_num = 0
	while entry_num < len(byte_arr) - 2:
		byte_header = byte_arr[entry_num]
		entry_num += 1

		if not byte_header:
			break
		elif byte_header == ord(PRE_BUFFER_HEADER):
			las.pre_trigger_byte_count += 1
		elif byte_header == ord(POST_BUFFER_HEADER):
			las.post_trigger_byte_count += 1
		else:
			# This will realign the bytes to get correct offset
			continue

		for offset in range(0, las.num_channels, 8):
			current_byte = byte_arr[entry_num]
			entry_num += 1
			data = current_byte

			for bit in range(8):
				las.channel_data[bit+offset].append((data >> bit) & 1)

		timestamp = byte_arr[entry_num]
		entry_num += 1
		las.timestamps.append(timestamp)
		las.total_time_units += timestamp
		las.x_axis.append(las.total_time_units)

	print(las.pre_trigger_byte_count)
	print(las.post_trigger_byte_count)
	return las

def convert_sec_to_relavent_time(seconds):

	units = 0
	# last item is 's' to account for seconds == 0
	unit_names = ['s', 'ms', 'us', 'ns', 'ps', 's']

	while int(seconds) == 0 and units < (len(unit_names) - 1):
		seconds *= 1000
		units += 1

	return '{:.2f} '.format(seconds) + unit_names[units]
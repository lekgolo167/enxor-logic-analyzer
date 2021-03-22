import math
import json

SCALER_HEADER = b'\xFA'
CHANNEL_HEADER = b'\xFB'
TRIG_TYPE_HEADER = b'\xFC'
ENABLE_HEADER = b'\xFD'
PRECAP_SIZE = b'\xFE'
HOLD_HEADER = b'\xFF'
PRE_BUFFER_HEADER = b'\xA1'
POST_BUFFER_HEADER = b'\xA3'
TRIGGER_RISING_ENDGE = 1
TRIGGER_FALLING_ENDGE = 0
MAX_TIMER_COUNT = 256

class LogicAnalyzerModel():
	def __init__(self):
		self.port = ''
		self.baud = 0
		self.scaler = 1
		self.channel = 0
		self.trigger_type = 0
		self.mem_depth = 0
		self.precap_size = 0
		self.pre_trigger_byte_count = 0
		self.post_trigger_byte_count = 0
		self.total_time_units = 0
		self.channel_data = []
		self.timestamps = []
		self.x_axis = []
		self.num_channels = 0
		self.bytes_per_row = 0
		self.clk_freq = 1
		self.hold = 0

	def getMaxCaptureTime(self):
		return (MAX_TIMER_COUNT*self.mem_depth) / (self.clk_freq/self.scaler)

	def getSamplesIntervalInSeconds(self):
		return 1 / (self.clk_freq / self.scaler)

	def initializeFromConfigFile(self, file_path):
		with open(file_path, 'r') as config_file:
			obj = json.loads(config_file.read())
			self.baud = obj['baud_rate']
			self.port = obj['port_name']
			self.clk_freq = obj['clk_freq']
			self.mem_depth = obj['mem_depth']
			self.precap_size = obj['precap_size']
			self.scaler = obj['sample_rate']
			self.channel = obj['trig_channel']
			self.trigger_type = obj['trig_type']
			self.num_channels = obj['num_channels']
			self.hold = obj['hold']
			self.bytes_per_row = (self.num_channels // 8) + 2
			

def writeLogicAnalyzerDataToFile(file_path, la):

	with open(file_path, 'wb') as binary_file:
		# set 1st byte to number of channels
		binary_file.write(bytes([la.num_channels]))
		# set 2nd byte to the memory depth
		binary_file.write(bytes([int(math.log2(la.mem_depth))]))
		# set bytes 3 - 6 to the clock frequency
		binary_file.write(la.clk_freq.to_bytes(4,byteorder='little'))
		# set bytes 7 and 8 to the sample rate
		binary_file.write(la.scaler.to_bytes(2,byteorder='little'))

		for entry_num in range(la.mem_depth):
			if entry_num < la.pre_trigger_byte_count:
				binary_file.write(PRE_BUFFER_HEADER)
			else:
				binary_file.write(POST_BUFFER_HEADER)

			for offset in range(0, (la.num_channels // 8),8):
				byte = 0
				for bit in range(8):
					byte = byte | (la.channel_data[offset+bit][entry_num] << bit)

				binary_file.write(bytes([byte]))

			binary_file.write(bytes([la.timestamps[entry_num]]))

def readLogicAnalyzerDataFromFile(file_path):

	with open(file_path, 'rb') as binary_file:
		la = LogicAnalyzerModel()

		# read 1st byte to get number of channels
		la.num_channels = ord(binary_file.read(1))
		# read 2nd byte for the memory depth
		la.mem_depth = int(math.pow(2 ,ord(binary_file.read(1))))
		# read bytes 3 - 6 for the clock frequency
		la.clk_freq = int.from_bytes(binary_file.read(4), 'little')
		# read bytes 7 and 8 for the sample rate
		la.scaler = int.from_bytes(binary_file.read(2), 'little')

		for x in range(la.num_channels):
			la.channel_data.append([])
		
		for entry_num in range(la.mem_depth):
			byte_header = binary_file.read(1)

			if not byte_header:
				break
			elif byte_header == PRE_BUFFER_HEADER:
				la.pre_trigger_byte_count += 1
			elif byte_header == POST_BUFFER_HEADER:
				la.post_trigger_byte_count += 1

			for offset in range(0, (la.num_channels // 8), 8):
				current_byte = binary_file.read(1)
				data = ord(current_byte)

				for bit in range(8):
					la.channel_data[bit+offset].append((data >> bit) & 1)

			timestamp = ord(binary_file.read(1))
			la.timestamps.append(timestamp)
			la.total_time_units += timestamp
			la.x_axis.append(la.total_time_units)

		return la

def readInputstream(byte_arr, las):
	las.channel_data = []
	las.timestamps = []
	las.post_trigger_byte_count = 0
	las.pre_trigger_byte_count = 0
	las.total_time_units = 0

	for x in range(las.num_channels):
		las.channel_data.append([])
	
	entry_num = 0
	while entry_num < (las.mem_depth*las.bytes_per_row):
		byte_header = byte_arr[entry_num]
		entry_num += 1

		if not byte_header:
			break
		elif byte_header == ord(PRE_BUFFER_HEADER):
			las.pre_trigger_byte_count += 1
		elif byte_header == ord(POST_BUFFER_HEADER):
			las.post_trigger_byte_count += 1

		for offset in range(0, (las.num_channels // 8), 8):
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

	return las
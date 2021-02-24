import math

SCALER_HEADER = b'\xFA'
CHANNEL_HEADER = b'\xFB'
TRIG_TYPE_HEADER = b'\xFC'
ENABLE_HEADER = b'\xFD'
PRE_BUFFER_HEADER = b'\xA1'
POST_BUFFER_HEADER = b'\xA3'
BYTES_PER_ROW = 3
TRIGGER_RISING_ENDGE = 1
TRIGGER_FALLING_ENDGE = 0
MAX_TIMER_COUNT = 256
FPGA_FREQ = 100000000
MEMORY_DEPTH = 8192

class LogicAnalyzerModel():
	def __init__(self):
		self.port = ''
		self.baud = 115200
		self.scaler = 1
		self.channel = 0
		self.trigger_type = 1
		self.mem_depth = 0
		self.pre_trigger_byte_count = 0
		self.post_trigger_byte_count = 0
		self.total_time_units = 0
		self.channel_data = []
		self.timestamps = []
		self.num_channels = 0

	def getMaxCaptureTime(self):
		return (MAX_TIMER_COUNT*MEMORY_DEPTH) / (FPGA_FREQ/self.scaler)

	def initializeFromConfigFile(self, file_path):
		with open(file_path, 'r') as config_file:
			pass

def writeLogicAnalyzerDataToFile(file_path, la):

    with open(file_path, 'wb') as binary_file:
        # set 1st byte to number of channels
        binary_file.write(bytes([la.num_channels]))
        binary_file.write(bytes([int(math.log2(la.mem_depth))]))

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
        la.mem_depth = int(math.pow(2 ,ord(binary_file.read(1))))

        for x in range(la.num_channels):
            la.channel_data.append([])
        
        for entry_num in range(la.mem_depth):
            byte_header = binary_file.read(1)

            if not byte_header:
                break
            elif ord(byte_header) == 0xA1:
                la.pre_trigger_byte_count += 1
            elif ord(byte_header) == 0xA3:
                la.post_trigger_byte_count += 1

            for offset in range(0, (la.num_channels // 8), 8):
                current_byte = binary_file.read(1)
                data = ord(current_byte)

                for bit in range(8):
                    la.channel_data[bit+offset].append((data & (1 << bit)) >> bit)

            timestamp = ord(binary_file.read(1))
            la.timestamps.append(timestamp)
            la.total_time_units += timestamp

        return la
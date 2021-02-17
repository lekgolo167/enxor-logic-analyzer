class LogicAnalyzerDataModel():
    def __init__(self):
        self.pre_trigger_byte_count = 0
        self.post_trigger_byte_count = 0
        self.total_time_units = 0
        self.channel_data = []

def readLogicAnalyzerFile(file_path, num_of_channels):
    with open(file_path, 'rb') as binary_file:
        la = LogicAnalyzerDataModel()

        for x in range(0, num_of_channels):
            la.channel_data.append([])
        
        while True:
            byte_header = binary_file.read(1)

            if not byte_header:
                break
            elif ord(byte_header) == 0xA1:
                la.pre_trigger_byte_count += 1
            elif ord(byte_header) == 0xA3:
                la.post_trigger_byte_count += 1

            offset = 0
            for x in range(0, num_of_channels // 8):
                current_byte = binary_file.read(1)
                data = ord(current_byte)

                for y in range(0,8):
                    la.channel_data[y+offset].append(data & (1 << y))
                
                offset += 8

            timestamp_byte = ord(binary_file.read(1))
            la.total_time_units += timestamp_byte

        print(la.pre_trigger_byte_count + la.post_trigger_byte_count)
        return la

la = readLogicAnalyzerFile('./test_data/teraterm1.log', 8)

print(la.channel_data[0][0])
print(la.channel_data[1][0])
print(la.channel_data[2][0])
print(la.channel_data[3][0])
print(la.channel_data[4][0])
print(la.channel_data[5][0])
print(la.channel_data[6][0])
print(la.channel_data[7][0])
print(la.total_time_units)
import filecmp
from logicAnalyzer import *

def readWriteFileTest():
	for x in range(1,3):
		in_file = './test_data/test{}.bin'.format(x)
		out_file = './test_data/out{}.bin'.format(x)

		la = readLogicAnalyzerDataFromFile(in_file)
		writeLogicAnalyzerDataToFile(out_file, la)


		if filecmp.cmp(in_file, out_file, shallow=False):
			print('[Read write {} ... PASS]'.format(x))
		else:
			print('[Read write {} ... FAIL]'.format(x))

def testInitializeFromFile():
	la1 = LogicAnalyzerModel()
	la2 = LogicAnalyzerModel()

	la2.initializeFromConfigFile("./config.json")

	error = 0
	if la1.port == la2.port:
		error += 1
	if la1.baud == la2.baud:
		error += 1
	if la1.scaler == la2.scaler:
		error += 1
	if la1.channel == la2.channel:
		error += 1
	if la1.clk_freq == la2.clk_freq:
		error += 1
	if la1.mem_depth == la2.mem_depth:
		error += 1
	if la1.trigger_type == la2.trigger_type:
		error += 1
	if la1.num_channels == la2.num_channels:
		error += 1
	if la1.bytes_per_row == la2.bytes_per_row:
		error += 1
	if la1.precap_size == la2.precap_size:
		error += 1

	if error > 0:
		print('[Init from file ... FAIL]')
	else:
		print('[Init from file ... PASS]')

#testInitializeFromFile()
readWriteFileTest()
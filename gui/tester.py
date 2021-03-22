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

	if la1.clk_freq == la2.clk_freq:
		print('[Init from file ... FAIL]')
	else:
		print('[Init from file ... PASS]')

#testInitializeFromFile()
readWriteFileTest()
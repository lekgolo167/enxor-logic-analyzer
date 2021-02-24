import filecmp
from logicAnalyzer import *

for x in range(1,3):
	in_file = './test_data/test{}.bin'.format(x)
	out_file = './test_data/out{}.bin'.format(x)

	la = readLogicAnalyzerDataFromFile(in_file)
	writeLogicAnalyzerDataToFile(out_file, la)


	if filecmp.cmp(in_file, out_file, shallow=False):
		print('[TEST {} ... PASS]'.format(x))
	else:
		print('[TEST {} ... FAIL]'.format(x))


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

import filecmp
from logicAnalyzer import *

def read_write_file_test():
	for x in range(1,3):
		in_file = './test_data/test{}.bin'.format(x)
		out_file = './test_data/out{}.bin'.format(x)

		la = read_logic_analyzer_data_from_file(in_file)
		write_logic_analyzer_data_to_file(out_file, la)


		if filecmp.cmp(in_file, out_file, shallow=False):
			print('[Read write {} ... PASS]'.format(x))
		else:
			print('[Read write {} ... FAIL]'.format(x))

def test_initialize_from_file():
	la1 = LogicAnalyzerModel()
	la2 = LogicAnalyzerModel()

	la2.initialize_from_config_file("./config.json")

	if la1.clk_freq == la2.clk_freq:
		print('[Init from file ... FAIL]')
	else:
		print('[Init from file ... PASS]')

test_initialize_from_file()
read_write_file_test()

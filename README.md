# Enexor-Logic-Analyzer
### By: Matthew Crump
---
## Contents
1. Overview
2. FPGA Utilization
3. Installation
4. Run
5. Specifications
6. Customize
---
## Overview
---
## FPGA Utilization
---
## Installation
---
## Run
---
## Specifications
* Config Format
  | Field | Description |
  | --------- | --------- |
  | baud_rate   | the baud rate of the FPGA UART |
  | port_name   | the name of the serial port, i.e. ```COM4``` or ```ttyUSB0``` |
  | clk_freq | the clock frequency of the FPGA design in Hertz |
  | mem_depth | the depth of the memory buffer |
  | precap_size | number of rows in the buffer that will be used for data captured before a trigger condition |
  | sample_scaler | number to divide the clock frequency. Sample frequency in seconds is given by 1 / (clk_freq/sample_rate) |
  | trig_channel | the channel to watch for a trigger condition |
  | trig_type | specifies if the trigger condition is a rising ```1``` or falling ```0``` edge |
  | num_channels | the number of input channels to the FPGA |
* Saved Capture File Format
---
## Customize
---
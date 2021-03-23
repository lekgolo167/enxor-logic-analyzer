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
  | Manufacture | Family | Device | WNS | LUT | FF
  | --------- | --------- | --------- | --------- | --------- | --------- |
  | Xilinx | Artix-7 | xc7a35tcpg236-1 | 4.664 | 193 | 227
  | Altera | Cyclone IV | EP4CE10F17C8N | x | x | x
  | Lattice | iCE40 | LP8K | x | x | x
---
## Installation
---
## Run
---
## Specifications
* Config Format
  | Field | Description | Default | Required |
  | --------- | --------- | --------- | --------- |
  | baud_rate   | the baud rate of the FPGA UART | 115200 | N
  | port_name   | the name of the serial port, i.e. ```COM4``` or ```ttyUSB0``` | None | N
  | hold | if ```1``` then trigger conditions are ignored until the precapture portion of the buffer has be filled completely | 0 | N
  | precap_size | number of rows in the buffer that will be used for data captured before a trigger condition | 4 | N
  | sample_scaler | number to divide the clock frequency. Sample frequency in seconds is given by 1 / (clk_freq/sample_rate) | 1 | N
  | trig_channel | the channel to watch for a trigger condition | 0 | N
  | trig_type | specifies if the trigger condition is a rising ```1``` or falling ```0``` edge | 1 | N
  | clk_freq | the clock frequency of the FPGA design in Hertz | N/A | Y
  | mem_depth | the depth of the memory buffer | N/A | Y
  | num_channels | the number of input channels to the FPGA | N/A | Y

* Saved Capture File Format
Several logic anaylzer settings are saved along with the captured data to a bin file. 
  | Byte | Description | 
  | --------- | --------- |
  | 1 | number of input channels |
  | 2 | exponent for base 2 to get the memory buffer depth |
  | 3-6 | the FPGA clock frequency in Hertz, stored in little-endian |
  | 7-8 | the sample rate the data was captured at, stored in little-endian |
  The remaining bytes follow the next subsections format.

* Captured data Transmitted to host PC
  * First byte indicates if the following data is captured before or after the tigger condition. <br> Precapture = ```0xA``` <br> PostCapture = ```0xA3```
  * The next byte(s) is the captured data itself. The number of bytes is given by the number of channels divided by 8.
  * Last byte contains the count of sample clock ticks that the data remained at. The timestamps ranges are ```1-255```, if the max value has been reached and the inputs have not changed then the next continues the count from 1.

---
## Customize
---
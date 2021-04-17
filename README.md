# Enxor-Logic-Analyzer
### By: Matthew Crump
---
## Contents
1. Overview
2. FPGA Utilization
3. Installation
4. Run
5. Specifications
6. Customize
7. Potential Enhancements
8. Known Issues
---
## Overview
Electronic hobbyists, makers, and engineering students need low-cost and effective tools. One of these tools includes a logic analyzer for debugging digital designs. Unfortunately, there is a large gap in this market, professional grade logic analyzers start at a minimum of 400 dollars while the cheaper version is around 15 dollars but is extremely limited in functionality. There are no mid-tier options that meet the needs of the aforementioned. This project is an open-source design using FPGAs offering great performance. In addition, the design uses only Verilog source code, no IP cores or device specific features. This makes the design portable to any FPGA, you can adjust the number of input channels and memory depth very quickly. For the accompanying desktop application, Python is used to allow the GUI to work on most operating system.

This project consists of 5 major blocks to carry out a functional logic analyzer: a trigger controller, sample rate counter, memory buffer, control module, and UART communication.
* Trigger Controller<br>
  This module is set to wait for a trigger condition on a user configurable channel. That condition can be either a falling or rising edge and is set in the GUI. A sample rate signal is used to tell the trigger controller when to shift new data in. If the new data does not match the old data then an event signal is sent out to other blocks. Once the trigger condition occurs, a triggered state signal is sent to the memory buffer.
  ![Trigger Controller Waveform Image](./documentation/images/trigger_controller_1.png)
* Sample Rate Counter<br>
  This system takes in a 16-bit divisor that tells the logic analyzer what the sample frequency is. Another counter is incremented at every sample clock to keep track of the relative time between events. If an event occurs the counter is reset to 1 and resumes counting. If the counter overflows, then it signals the memory controller to fill in a new row.
* Memory Buffer<br>
  The memory buffer combines the timestamp and data storing it in RAM. Each time it receives a event or timestamp rollover signal a new row in the buffer is filled. Before a trigger condition occurs, this block behaves as a circular buffer, continually overwriting previous entries. Once a trigger condition occurs the buffer acts as a FIFO and fills all the way up. The buffer has a precapture size setting to control the ratio of data that is saved before and after a trigger condition. Once full, the controller module is signaled, and data is read out row by row.
* Controller<br>
  This block waits for commands to be received from the host computer and saves the commands to control registers. Once the enable command is received, the controller waits for the memory buffer to fill up. Then the data is read out of the buffer and converted from its original width to a width of one byte to be sent off to the UART block.
* UART Communication<br>
  This block simply waits for bytes to be sent from the host PC and relays the commands to the controller block. Once the controller sends the UART block data, it prepends  a header on the captured data indicating if it was captured before or after the trigger condition.
---
## FPGA Utilization
  | Manufacture | Family | Device | Frequency | WNS | LUT | FF | Channels | Memory Depth
  | --------- | --------- | --------- | --------- | --------- | --------- | --------- | --------- | --------- |
  | Xilinx | Artix-7 | xc7a35tcpg236-1 | 100MHz | 4.664 | 193 | 227 | 8 | 8192
  | Altera | Cyclone IV | EP4CE10F17C8N | 50MHz | 10.729 | 404 | 238 | 8 | 8192
  | Lattice | iCE40 | LP8K | 16MHz | x | 665 | 234 | 8 | 8192
  
---
## Installation
* Python 3.6 or higher is required to run the GUI. Required Python packages:
  * matplotlib
  * tkinter
* The FPGA development tools vary depending on the manufacture.
  * Xilinx -> Vivado
  * Altera -> Quartus Prime
  * Lattice -> icestudio or Icecube2
---
## Run
* Launch the GUI by running:
  * ```$ python3 gui.py```
* A guid on how to use and operate the GUI will be available once the code for it has been completed.
---
## Specifications
* Timming <br>
Data sent back to the host PC has a relative sample time count byte. Each time unit is equal to
  * time_unit_in_seconds = 1 / (clock_freq/sample_divisor)

  The minimum and maximun sample time in seconds can be found by the following equations.
  * min_sample_time = memory_depth / (clock_freq/sample_divisor)
  * max sample time = (255 * memory_depth) / (clock_freq/divisor)
* Config Format<br>
Current settings can be saved or loaded from a ```json``` file. The following table explains what each field is and if it is required.
  | Field | Description | Default | Required |
  | --------- | --------- | --------- | --------- |
  | baud_rate   | the baud rate of the FPGA UART | 115200 | N
  | port_name   | the name of the serial port, i.e. ```COM4``` or ```ttyUSB0``` | None | N
  | precap_size | number of rows in the buffer that will be used for data captured before a trigger condition | 4 | N
  | sample_scaler | number to divide the clock frequency. Sample frequency in seconds is given by 1 / (clk_freq/sample_rate) | 1 | N
  | trig_channel | the channel to watch for a trigger condition | 0 | N
  | trig_type | specifies if the trigger condition is a rising ```1``` or falling ```0``` edge | 1 | N
  | clk_freq | the clock frequency of the FPGA design in Hertz | N/A | Y
  | mem_depth | the depth of the memory buffer | N/A | Y
  | num_channels | the number of input channels to the FPGA | N/A | Y

* Saved Capture File Format<br>
  Several logic anaylzer settings are saved along with the captured data to a bin file. The following table shows the byte ordering.
  | Byte | Description | 
  | --------- | --------- |
  | 1 | number of input channels |
  | 2 | exponent for base 2 to get the memory buffer depth |
  | 3-6 | the FPGA clock frequency in Hertz, stored in little-endian |
  | 7-8 | the sample rate the data was captured at, stored in little-endian |
  The remaining bytes follow the next subsections format.

* Captured data transmitted to host PC from the FPGA.
  | Byte | Description | 
  | --------- | --------- |
  | 1 | indicates if the following data is captured before or after the tigger point <br> Precapture = ```0xA1``` <br> PostCapture = ```0xA3``` |
  | N | The next byte(s) is the captured data. The number of bytes is given by the number of channels divided by 8 |
  | 3 | Last byte contains the count of sample clock ticks that the data remained at. The timestamps ranges are ```1-255``` |

---
## Customize
* In the LogicAnalyzerTop moduler are parameters that allow easy customization of the design.
  * ```DATA_WIDTH``` This is the number of input channels to the FPGA
  * ```MEM_DEPTH``` This is the number of rows in the memory buffer. Total bytes in the buffer is ```MEM_DEPTH``` * (```DATA_WIDTH```/8 + 1)
* The UART requires a parameter called ```CLKS_PER_BIT```. To get the correct BAUD rate the following formula is used.
  * ```CLKS_PER_BIT``` = (Frequency of FPGA)/(Frequency of UART)
  * Example: <br>10 MHz Clock, 115200 baud UART <br> 10000000 / 115200 = 87

## Potenital enhancements
* Add a small soft-core processor to make communicating with the host PC easier and more flexible.

## Known Issues
* If a trigger condition occurs within microseconds after being enabled, the gui cannot get the serial port open intime to catch all the data.
  * Potential fix: have Enxor signal the host PC that the buffer is full then wait for a read command before sending captured data.
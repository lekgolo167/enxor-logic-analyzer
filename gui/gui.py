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

from pathlib import Path

import tkinter as tk
from tkinter import ttk
from tkinter import Checkbutton, messagebox
from tkinter import filedialog

import matplotlib
from matplotlib.backends.backend_tkagg import (FigureCanvasTkAgg,  NavigationToolbar2Tk) 
matplotlib.use('TkAgg') 

from logicAnalyzer import read_logic_analyzer_data_from_file, write_logic_analyzer_data_to_file, LogicAnalyzerModel
from serialInterface import AsyncReadSerial, get_available_serial_ports, configure_logic_analyzer
from multiplots import MultiPlot


class MenuBar(tk.Menu):
	def __init__(self, ws, time_measurement_strvar, enxor_status_strvar, la):

		self.logic_analyzer = la
		self.enxor_status_strvar = enxor_status_strvar
		self.canvas = None
		self.multi_p = MultiPlot(time_measurement_strvar)
		self.serial_thread = AsyncReadSerial(self.logic_analyzer)
		self.sel_port = tk.IntVar(value=-1)
		self.fmc = None
		self.is_set_enxor_state = False

		tk.Menu.__init__(self, ws)

		file = tk.Menu(self, tearoff=False)
		file.add_command(label="Configuration")
		file.add_separator()
		file.add_command(label="Open", command=self.open_configuration)
		file.add_command(label="Save As", command=self.save_configuration)
		file.add_separator()
		file.add_command(label="Exit", underline=1, command=self.quit)
		self.add_cascade(label="File",underline=0, menu=file)
		
		self.capture_menu = tk.Menu(self, tearoff=0)

		start_state = "normal"
		if self.logic_analyzer.port == "":
			start_state = 'disabled'

		self.capture_menu.add_command(label="Start",  command=self.start_capture, state=start_state)
		self.capture_menu.add_command(label="Stop", command=self.stop_capture)
		self.capture_menu.add_separator()
		self.capture_menu.add_command(label="Save As", command=self.save_capture)
		self.capture_menu.add_command(label="Open", command=self.open_capture)
		self.add_cascade(label="Capture", menu=self.capture_menu)

		settings = tk.Menu(self, tearoff=0)

		self.available_ports_menu = tk.Menu(self, tearoff=0, postcommand=lambda: self.refresh_serial_ports())
		settings.add_cascade(label='Serial Ports', menu=self.available_ports_menu)
		self.add_cascade(label='Settings', menu=settings)

		help = tk.Menu(self, tearoff=0)
		help.add_command(label="About", command=self.about)
		self.add_cascade(label="Help", menu=help)

	def exit(self):
		self.exit

	def about(self):
			messagebox.showinfo('Enxor Logic Analyzer', 'GitHub: https://github.com/lekgolo167/enxor-logic-analyzer')

	def refresh_serial_ports(self):
		self.available_ports_menu.delete(0, 100)
		port_num = 0
		for port_name in get_available_serial_ports():
				self.available_ports_menu.add_radiobutton(label=port_name, variable=self.sel_port, value=port_num,
														  command=lambda x=port_name: self.set_serial_port(x))
				port_num += 1
		try:
			self.sel_port.set(self.available_ports_menu.index(self.logic_analyzer.port))
		except:
			pass

	def set_serial_port(self, name):
		self.logic_analyzer.port = name
		if self.enxor_status_strvar.get() == "UNCONNECTED":
			self.enxor_status_strvar.set("READY")

	def save_configuration(self):
		filename = filedialog.asksaveasfilename(initialdir = "/", title = "Select file", 
												filetypes = (("json files","*.json"),("all files","*.*")))
		if filename != "":
			if not filename.endswith('.json'):
					filename = filename + '.json'
			self.logic_analyzer.save_to_config_file(filename)

	def open_configuration(self):
		filename = filedialog.askopenfilename(initialdir = "/", title = "Select file",
											  filetypes = (("json files","*.json"),("all files","*.*")))
		if filename != "":
			valid = self.logic_analyzer.initialize_from_config_file(filename)
			if not valid:
				self.capture_menu.entryconfig(0, state='disabled')
				messagebox.showinfo('Invalid Configuration',
									"The following fields are required: 'mem_depth', 'clk_freq', 'num_channels")
			else:
				self.capture_menu.entryconfig(0, state='normal')

	def save_capture(self):
		filename = filedialog.asksaveasfilename(initialdir = "/", title = "Select file",
												filetypes = (("Captures","*.xor"),("all files","*.*")))
		if filename != "":
			if self.logic_analyzer.total_time_units == 0:
				messagebox.showinfo('No Live Capture', 'There is no live caputred data to save.')
			else:
				if not filename.endswith('.xor'):
					filename = filename + '.xor'
				write_logic_analyzer_data_to_file(filename, self.logic_analyzer)

	def open_capture(self):
		filename = filedialog.askopenfilename(initialdir = "/", title = "Select file",
											  filetypes = (("Captures","*.xor"),("all files","*.*")))
		if filename != "":
			logic_analyzer = read_logic_analyzer_data_from_file(filename)
			self.add_plot_to_window(Path(filename).parts[-1], logic_analyzer)

	def monitor(self):

		if self.serial_thread.is_alive():
			if self.serial_thread.start_read:
				self.enxor_status_strvar.set("READING")
			elif self.serial_thread.triggered and not self.is_set_enxor_state:
				self.enxor_status_strvar.set("TRIGGERED")
				self.is_set_enxor_state = True
			self.after(500,self.monitor)
		else:
			self.is_set_enxor_state = False
			self.enxor_status_strvar.set("READY")
			if self.serial_thread.triggered:
				self.add_plot_to_window('Enxor', self.logic_analyzer)
			self.capture_menu.entryconfig(0, state='normal')

	def start_capture(self):
		self.capture_menu.entryconfig(0, state='disabled')

		configure_logic_analyzer(self.logic_analyzer)

		self.enxor_status_strvar.set("WAITING")
		
		self.serial_thread = AsyncReadSerial(self.logic_analyzer)
		self.serial_thread.start()
		self.monitor()

	def stop_capture(self):
		self.enxor_status_strvar.set("STOPPED")
		self.serial_thread.kill = True
	
		self.capture_menu.entryconfig(0, state='normal')

	def add_plot_to_window(self, name, logic_analyzer):
		if self.canvas != None:
			self.canvas.get_tk_widget().pack_forget()
			self.canvas = None

		self.canvas = self.multi_p.plot_captured_data(name, logic_analyzer, self.fmc)

		# placing the canvas on the Tkinter window 
		self.canvas.get_tk_widget().pack()

class EnxorGui(tk.Tk):
	def __init__(self):
		tk.Tk.__init__(self)

		self.logic_analyzer = LogicAnalyzerModel()
		self.logic_analyzer.initialize_from_config_file('./config.json')

		self.enxor_status = tk.StringVar(value='READY')
		if self.logic_analyzer.port == '':
			self.enxor_status.set("UNCONNECTED")

		self.time_measurement = tk.StringVar(value='---')
		self.samples = [1,2,5,10,50,100,250,500,1000]
		self.delays = [5,15,50,100,150,200,250]

		if self.logic_analyzer.scaler not in self.samples:
			self.samples.insert(0, self.logic_analyzer.scaler)

		self.sample_divisors = [self.logic_analyzer.get_min_max_string(x) for x in self.samples]
		self.sample_divisor = tk.StringVar(value=self.sample_divisors[0])
		self.sample_divisor.trace('w', self.sample_rate_dropdown)

		self.trigger_delays = [self.logic_analyzer.get_trigger_delay_string(x) for x in self.delays]
		self.trigger_delay = tk.StringVar(value=self.trigger_delays[0])
		self.trigger_delay.trace('w', self.trigger_delay_dropdown)

		self.precapture_percentages = [str(x)+" %" for x in range(10,100, 10)]
		self.precapture_size = tk.StringVar(value=self.precapture_percentages[0])
		self.precapture_size.trace('w', self.precapture_percentages_dropdown)

		self.trigger_channels = [x for x in range(1, self.logic_analyzer.num_channels+1)]
		self.trigger_channel = tk.IntVar(value=self.trigger_channels[self.logic_analyzer.channel])
		self.trigger_channel.trace('w', self.trigger_channel_dropdown)

		self.trigger_types = ['Falling', 'Rising']
		self.trigger_type = tk.StringVar(value=self.trigger_types[self.logic_analyzer.trigger_type])
		self.trigger_type.trace('w', self.trigger_type_dropdown)

		self.trigger_delay_enabled = tk.IntVar(value=0)
		self.trigger_delay_enabled.trace('w', self.trigger_delay_enable_click)

		self.menubar = MenuBar(self, self.time_measurement, self.enxor_status, self.logic_analyzer)
		self.config(menu=self.menubar)
		
		self.grid_rowconfigure(0, weight=1)
		self.grid_rowconfigure(1, weight=20)
		self.grid_rowconfigure(2, weight=1)
		self.grid_columnconfigure(0, weight=1)

		self.create_header_frame()
		self.create_waveform_window()
		self.create_footer_frame()

	def sample_rate_dropdown(self, *args):
		index = self.sample_divisors.index(self.sample_divisor.get())
		self.menubar.logic_analyzer.scaler = self.samples[index]
		self.trigger_delays = [self.logic_analyzer.get_trigger_delay_string(x) for x in self.delays]
		self.trigger_delay_entry['values'] = self.trigger_delays
		self.trigger_delay_entry.set(self.trigger_delays[0])
		self.trigger_delay_dropdown(None)

	def trigger_delay_dropdown(self, *args):
		self.menubar.logic_analyzer.trigger_delay = self.delays[self.trigger_delay_entry.current()]

	def precapture_percentages_dropdown(self, *args):
		percentage = (self.precapture_percentages.index(self.precapture_size.get()) + 1) * 0.1
		self.menubar.logic_analyzer.precap_size = int(self.menubar.logic_analyzer.mem_depth * percentage)

	def trigger_channel_dropdown(self, *args):
		self.menubar.logic_analyzer.channel = self.trigger_channels.index(self.trigger_channel.get())

	def trigger_type_dropdown(self, *args):
		self.menubar.logic_analyzer.trigger_type = self.trigger_types.index(self.trigger_type.get())

	def trigger_delay_enable_click(self, *args):
		self.menubar.logic_analyzer.trigger_delay_enabled = self.trigger_delay_enabled.get()

	def create_header_frame(self):
			
		header = tk.Frame(self)
		header.grid(sticky='new', row=0, column=0)

		trigger_channel_label = tk.Label(header, text="Trigger Channel")
		trigger_channel_label.grid(row=0, column=0, pady=(5, 0), sticky='nw')
		trigger_channel_entry = tk.OptionMenu(header, self.trigger_channel, *self.trigger_channels)
		trigger_channel_entry.grid(row=0, column=1)

		trigger_type_label = tk.Label(header, text="Trigger Type")
		trigger_type_label.grid(row=0, column=2, pady=(5, 0), sticky='nw')
		trigger_type_entry = tk.OptionMenu(header, self.trigger_type, *self.trigger_types)
		trigger_type_entry.grid(row=0, column=3)

		precapture_size_label = tk.Label(header, text="Precapture size")
		precapture_size_label.grid(row=0, column=4, pady=(5, 0), sticky='nw')
		precapture_size_entry = tk.OptionMenu(header, self.precapture_size, *self.precapture_percentages)
		precapture_size_entry.grid(row=0, column=5)

		sample_divisor_label = tk.Label(header, text="Sample Rate")
		sample_divisor_label.grid(row=0, column=6, pady=(5, 0), sticky='nw')
		sample_divisor_entry = tk.OptionMenu(header, self.sample_divisor, *self.sample_divisors)
		sample_divisor_entry.grid(row=0, column=7)

		trigger_delay_enable_checkbox = Checkbutton(header, text="Trigger Delay Enable", variable=self.trigger_delay_enabled)
		trigger_delay_enable_checkbox.grid(row=0, column=8, pady=(5,0), sticky='nw')

		trigger_delay_label = tk.Label(header, text="Delay")
		trigger_delay_label.grid(row=0, column=9, pady=(5, 0), sticky='nw')
		self.trigger_delay_entry = ttk.Combobox(header, values=self.trigger_delays, state='readonly')
		self.trigger_delay_entry.set(self.trigger_delays[0])
		self.trigger_delay_entry.bind("<<ComboboxSelected>>", self.trigger_delay_dropdown)
		self.trigger_delay_entry.grid(row=0, column=10)

	def create_waveform_window(self):

		body = tk.Frame(self, bg='white')

		waveform_frame = tk.Canvas(body, bg="grey")
		waveform_frame.pack(fill='both', expand=True)


		self.menubar.fmc = waveform_frame

		body.grid(row=1, column=0, sticky='nsew', padx=5, pady=5)

	def create_footer_frame(self):

		footer = tk.Frame(self)
		footer.grid(sticky='sew', row=2, column=0)

		state_label = tk.Label(footer, text="STATE:")
		state_label.grid(row=0, column=0, pady=5, padx=5, sticky='ne')
		enxor_status_label = tk.Label(footer, textvariable=self.enxor_status)
		enxor_status_label.grid(row=0, column=1, pady=5, padx=5, sticky='ne')
		time_label = tk.Label(footer, textvariable=self.time_measurement, font='Helvetica 18 bold')
		time_label.grid(row=0, column=2, pady=5, padx=5, sticky='nw')

if __name__ == "__main__":
	ws=EnxorGui()
	ws.title('Enxor Logic Analyzer')
	ws.geometry('1100x800')
	ws.mainloop()
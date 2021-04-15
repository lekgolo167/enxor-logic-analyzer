from pathlib import Path

import tkinter as tk
#from tkinter import *
from tkinter import messagebox
from tkinter import filedialog

import matplotlib.pyplot as plt
import matplotlib
from matplotlib.widgets import Slider
from matplotlib.figure import Figure 
from matplotlib.backends.backend_tkagg import (FigureCanvasTkAgg,  NavigationToolbar2Tk) 
matplotlib.use('TkAgg') 

from logicAnalyzer import *
from serialInterface import *
from multiplots import MultiPlot

class MenuBar(tk.Menu):
	def __init__(self, ws):

		self.logic_analyzer = LogicAnalyzerModel()
		self.logic_analyzer.initializeFromConfigFile('./config.json')
		self.canvas = None
		self.multi_p = MultiPlot()
		self.serial_thread = AsyncReadSerial(self.logic_analyzer)
		self.recent_configs = []
		self.sel_port = tk.IntVar()
		self.fmc = None

		tk.Menu.__init__(self, ws)

		file = tk.Menu(self, tearoff=False)
		file.add_command(label="Configuration")
		file.add_separator()
		file.add_command(label="Open", command=self.open_configuration)  
		file.add_command(label="Save As", command=self.save_configuration)  
		#file.add_command(label="Save")    
		file.add_separator()
		file.add_command(label="Exit", underline=1, command=self.quit)
		self.add_cascade(label="File",underline=0, menu=file)
		
		self.capture_menu = tk.Menu(self, tearoff=0)  
		self.capture_menu.add_command(label="Start",  command=self.start_capture)  #state='disabled',
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
		for port_name in getAvailableSerialPorts():
				self.available_ports_menu.add_radiobutton(label=port_name, variable=self.sel_port, value=port_num, command=lambda x=port_name: self.set_serial_port(x))
				port_num +=1
		try:
			self.sel_port.set(self.available_ports_menu.index(self.logic_analyzer.port))
		except:
			pass

	def set_serial_port(self, name):
		print("Selected port: "+name)
		self.logic_analyzer.port=name

	def save_configuration(self):
		filename =  filedialog.asksaveasfilename(initialdir = "/",title = "Select file",filetypes = (("json files","*.json"),("all files","*.*")))
		if filename != "":
			self.logic_analyzer.saveToConfigFile(filename)

	def open_configuration(self):
		filename =  filedialog.askopenfilename(initialdir = "/",title = "Select file",filetypes = (("json files","*.json"),("all files","*.*")))
		valid = None
		if filename != "":
			valid = self.logic_analyzer.initializeFromConfigFile(filename)
		if valid == False:
			self.capture_menu.entryconfig(0, state='disabled')
			messagebox.showinfo('Invalid Configuration', "The following fields are required: 'mem_depth', 'clk_freq', 'num_channels")
		elif valid == True:
			self.capture_menu.entryconfig(0, state='normal')

	def save_capture(self):
		filename =  filedialog.asksaveasfilename(initialdir = "/",title = "Select file",filetypes = (("binary files","*.bin"),("all files","*.*")))
		writeLogicAnalyzerDataToFile(filename, self.logic_analyzer)

	def open_capture(self):
		filename =  filedialog.askopenfilename(initialdir = "/",title = "Select file",filetypes = (("binary files","*.bin"),("all files","*.*")))
		self.logic_analyzer = readLogicAnalyzerDataFromFile(filename)

		self.add_plot_to_window(Path(filename).parts[-1])

	def monitor(self):

		if self.serial_thread.is_alive():
			self.after(1000,self.monitor)
		else:
			if not self.serial_thread.kill:
				self.add_plot_to_window('Enxor')
			self.capture_menu.entryconfig(0, state='normal')

	def start_capture(self):
		self.capture_menu.entryconfig(0, state='disabled')

		configureLogicAnalyzer(self.logic_analyzer)
		enableLogicAnalyzer(self.logic_analyzer)

		self.serial_thread = AsyncReadSerial(self.logic_analyzer)
		self.serial_thread.start()
		self.monitor()

	def stop_capture(self):
		#TODO properly shutdown serial terminal and read data if any
		self.serial_thread.kill = True
		self.capture_menu.entryconfig(0, state='normal')

	def add_plot_to_window(self, name):
		if self.canvas != None:
			self.canvas.get_tk_widget().pack_forget()
			self.canvas = None

		self.canvas = self.multi_p.plot_captured_data(name, self.logic_analyzer, self.fmc)

		# placing the canvas on the Tkinter window 
		self.canvas.get_tk_widget().pack()

class MenuDemo(tk.Tk):
	def __init__(self):
		tk.Tk.__init__(self)
		self.menubar = MenuBar(self)
		self.config(menu=self.menubar)
		
		self.grid_rowconfigure(0, weight=1)
		self.grid_rowconfigure(1, weight=20)
		self.grid_rowconfigure(2, weight=1)
		self.grid_columnconfigure(0, weight=1)

		self.create_header_frame()
		self.create_waveform_window()
		self.create_footer_frame()

	def create_header_frame(self):
			
		header = tk.Frame(self)
		header.grid(sticky='new', row=0, column=0)

		label1 = tk.Label(header, text="Label 1", fg="green")
		label1.grid(row=0, column=0, pady=(5, 0), sticky='nw')

		label2 = tk.Label(header, text="Label 2", fg="blue")
		label2.grid(row=0, column=1, pady=(5, 0), sticky='nw')

	def create_waveform_window(self):

		body = tk.Frame(self, bg='white')

		waveform_frame = tk.Canvas(body, bg="grey")
		waveform_frame.pack(fill='both', expand=True)


		self.menubar.fmc = waveform_frame

		body.grid(row=1, column=0, sticky='nsew', padx=5, pady=5)

	def create_footer_frame(self):

		footer = tk.Frame(self)
		footer.grid(sticky='sew', row=2, column=0)

		label3 = tk.Label(footer, text="Label 3", fg="red")
		label3.grid(row=0, column=0, pady=5, sticky='nw')

if __name__ == "__main__":
	ws=MenuDemo()
	ws.title('Enxor Logic Analyzer')
	ws.geometry('900x800')
	ws.mainloop()
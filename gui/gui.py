from pathlib import Path

from tkinter import *
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

class MenuBar(Menu):
	def __init__(self, ws):

		self.logic_analyzer = LogicAnalyzerModel()
		self.canvas = None
		self.multi_p = MultiPlot()
		self.serial_thread = None

		Menu.__init__(self, ws)

		file = Menu(self, tearoff=False)
		file.add_command(label="New")  
		file.add_command(label="Open", command=self.open_configuration)  
		file.add_command(label="Save As", command=self.save_configuration)  
		file.add_command(label="Save")    
		file.add_separator()
		file.add_command(label="Exit", underline=1, command=self.quit)
		self.add_cascade(label="File",underline=0, menu=file)
		
		self.capture_menu = Menu(self, tearoff=0)  
		self.capture_menu.add_command(label="Start", command=self.start_capture)  
		self.capture_menu.add_command(label="Stop", command=self.stop_capture)  
		self.capture_menu.add_separator()    
		self.capture_menu.add_command(label="Save As", command=self.save_capture)  
		self.capture_menu.add_command(label="Open", command=self.open_capture)  
		self.add_cascade(label="Capture", menu=self.capture_menu) 

		settings = Menu(self, tearoff=0)

		self.available_ports_menu = Menu(self, tearoff=0, postcommand=lambda: self.refresh_serial_ports())
		settings.add_cascade(label='Serial Ports', menu=self.available_ports_menu)
		self.add_cascade(label='Settings', menu=settings)

		help = Menu(self, tearoff=0)  
		help.add_command(label="About", command=self.about)  
		self.add_cascade(label="Help", menu=help)  

	def exit(self):
		self.exit

	def about(self):
			messagebox.showinfo('Enxor Logic Analyzer', 'GitHub: https://github.com/lekgolo167/enxor-logic-analyzer')

	def refresh_serial_ports(self):
		self.available_ports_menu.delete(0, 100)
		for port_name in getAvailableSerialPorts():
			self.available_ports_menu.add_command(label=port_name, command=lambda x=port_name: self.set_serial_port(x))

	def set_serial_port(self, name):
		print("Selected port: "+name)
		self.logic_analyzer.port=name

	def save_configuration(self):
		filename =  filedialog.asksaveasfilename(initialdir = "/",title = "Select file",filetypes = (("json files","*.json"),("all files","*.*")))

	def open_configuration(self):
		filename =  filedialog.askopenfilename(initialdir = "/",title = "Select file",filetypes = (("json files","*.json"),("all files","*.*")))
		self.logic_analyzer.initializeFromConfigFile(filename)

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

		self.logic_analyzer.initializeFromConfigFile('./config.json')
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

		self.canvas = self.multi_p.plot_captured_data(name, self.logic_analyzer, ws)

		# placing the canvas on the Tkinter window 
		self.canvas.get_tk_widget().pack()

class MenuDemo(Tk):
	def __init__(self):
		Tk.__init__(self)
		menubar = MenuBar(self)
		self.config(menu=menubar)

if __name__ == "__main__":
	ws=MenuDemo()
	ws.title('Enxor Logic Analyzer')
	ws.geometry('700x600')
	ws.mainloop()
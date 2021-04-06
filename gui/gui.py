from tkinter import *
from tkinter import messagebox
from tkinter import filedialog
from logicAnalyzer import *
from serialInterface import *

class MenuBar(Menu):
	def __init__(self, ws):

		self.logic_analyzer = LogicAnalyzerModel()

		Menu.__init__(self, ws)

		file = Menu(self, tearoff=False)
		file.add_command(label="New")  
		file.add_command(label="Open", command=self.open_configuration)  
		file.add_command(label="Save As", command=self.save_configuration)  
		file.add_command(label="Save")    
		file.add_separator()
		file.add_command(label="Exit", underline=1, command=self.quit)
		self.add_cascade(label="File",underline=0, menu=file)
		
		edit = Menu(self, tearoff=0)  
		edit.add_command(label="Start", command=self.start_capture)  
		edit.add_command(label="Stop", command=self.stop_capture)  
		edit.add_separator()    
		edit.add_command(label="Save As", command=self.save_capture)  
		edit.add_command(label="Open", command=self.open_capture)  
		self.add_cascade(label="Capture", menu=edit) 

		view = Menu(self, tearoff=0)

		ratio = Menu(self, tearoff=0, postcommand=lambda: self.refresh_serial_ports())
		self.available_ports_menu = ratio
		view.add_cascade(label='Ratio', menu=ratio)
		self.add_cascade(label='View', menu=view)
		#print(view.cget('child'))

		help = Menu(self, tearoff=0)  
		help.add_command(label="About", command=self.about)  
		self.add_cascade(label="Help", menu=help)  

	def exit(self):
		self.exit

	def about(self):
			messagebox.showinfo('PythonGuides', 'Python Guides aims at providing best practical tutorials')

	def refresh_serial_ports(self):
		self.available_ports_menu.delete(0, 100)
		for port_name in getAvailableSerialPorts():
			self.available_ports_menu.add_command(label=port_name, command=lambda x=port_name: self.set_serial_port(x))

	def set_serial_port(self, name):
		print("Selected port: "+name)
		self.logic_analyzer.port=name

	def save_configuration(self):
		filename =  filedialog.asksaveasfilename(initialdir = "/",title = "Select file",filetypes = (("json files","*.json"),("all files","*.*")))
		print (filename)

	def open_configuration(self):
		filename =  filedialog.askopenfilename(initialdir = "/",title = "Select file",filetypes = (("json files","*.json"),("all files","*.*")))
		print (filename)
		self.logic_analyzer.initializeFromConfigFile(filename)

	def save_capture(self):
		filename =  filedialog.asksaveasfilename(initialdir = "/",title = "Select file",filetypes = (("binary files","*.bin"),("all files","*.*")))
		print (filename)
		writeLogicAnalyzerDataToFile(filename, self.logic_analyzer)

	def open_capture(self):
		filename =  filedialog.askopenfilename(initialdir = "/",title = "Select file",filetypes = (("binary files","*.bin"),("all files","*.*")))
		print (filename)
		self.logic_analyzer = readLogicAnalyzerDataFromFile(filename)

	def start_capture(self):
		pass

	def stop_capture(self):
		pass

class MenuDemo(Tk):
	def __init__(self):
		Tk.__init__(self)
		menubar = MenuBar(self)
		self.config(menu=menubar)

if __name__ == "__main__":
	ws=MenuDemo()
	ws.title('Enxor Logic Analyzer')
	ws.geometry('300x200')
	ws.mainloop()
from tkinter import * 
import matplotlib.pyplot as plt
import matplotlib
from matplotlib.widgets import Slider
from matplotlib.figure import Figure 
from matplotlib.backends.backend_tkagg import (FigureCanvasTkAgg,  NavigationToolbar2Tk) 
matplotlib.use('TkAgg') 
from logicAnalyzer import *
from serialInterface import *


# plot function is created for  
# plotting the graph in  
# tkinter window 
def plot(): 

	las = LogicAnalyzerModel()
	las.initializeFromConfigFile('./config.json')

	configureLogicAnalyzer(las)
	enableLogicAnalyzer(las)
	data = readIncomingSerialData(las)
	readInputstream(data, las)

	fig, axs = plt.subplots(3, sharex=True, sharey=True)
	canvas = FigureCanvasTkAgg(fig, master = window)   
	
	canvas.get_tk_widget().pack( expand=1)
	fig.suptitle('Sharing both axes')
	axs[0].plot(las.x_axis, las.channel_data[0])
	axs[1].plot(las.x_axis,las.channel_data[1], 'o')
	axs[2].plot(las.x_axis, las.channel_data[2], '+')


	axpos = plt.axes([0.2, 0.03, 0.65, 0.03])
	spos = Slider(axpos, 'Pos', 0.1, 90.0)

	#plt.show()
	# creating the Tkinter canvas 
	# containing the Matplotlib figure 

	def update(val):
		pos = spos.val
		axs[0].axis([pos,pos+256,0,1])
		axs[1].axis([pos,pos+256,0,1])
		axs[2].axis([pos,pos+256,0,1])
		canvas.draw()
		fig.canvas.draw_idle()

	spos.on_changed(update)
  
	# placing the canvas on the Tkinter window 
	canvas.get_tk_widget().pack() 
  
	# creating the Matplotlib toolbar 
	toolbar = NavigationToolbar2Tk(canvas, 
								   window) 
	toolbar.update() 
  
	# placing the toolbar on the Tkinter window 
	canvas.get_tk_widget().pack() 
  
# the main Tkinter window 
window = Tk() 
mainframe = Frame(window)
mainframe.grid(column=0, row=0, sticky=(N,W,E,S))
mainframe.pack()

# setting the title  
window.title('Plotting in Tkinter') 
  
# dimensions of the main window 
window.geometry("500x500") 
  
# button that displays the plot 
plot_button = Button(master = window,  
					 command = plot, 
					 height = 2,  
					 width = 10, 
					 text = "Plot") 
  
# place the button  
# in main window 
plot_button.pack() 

com_ports = StringVar(window)
comPortMenu = OptionMenu(mainframe, com_ports, 'Select Serial Port')
comPortMenu.grid(row=0,column=0)
comPortMenu.configure(state='disabled')
def show_comports(*args):
	print(com_ports.get())
com_ports.trace('w', show_comports)
def show_available_com_ports(dropdown, var):

	dropdown.configure(state='normal')  # Enable drop down
	menu = dropdown['menu']

	# Clear the menu.
	menu.delete(0, 'end')
	for name in getAvailableSerialPorts():
		# Add menu items.
		menu.add_command(label=name, command=lambda name=name: var.set(name))
		# OR menu.add_command(label=name, command=partial(var.set, name))

	#print(var.get())


b = Button(mainframe, text='Refresh Serial Ports',
		   command=lambda: show_available_com_ports(comPortMenu, com_ports))
b.grid(column=1, row=0)
# run the gui 
window.mainloop() 
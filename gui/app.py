from tkinter import * 
import matplotlib.pyplot as plt
import numpy as np
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

	# the figure that will contain the plot 
	# fig = Figure(figsize = (5, 5), 
	#              dpi = 100) 
  
	# # list of squares 
	# y = [i**2 for i in range(101)] 
  
	# # adding the subplot 
	# plot1 = fig.add_subplot(111) 
  
	# # plotting the graph 
	# plot1.plot(y) 

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
  
# run the gui 
window.mainloop() 
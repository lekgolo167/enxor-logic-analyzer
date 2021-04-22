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

import matplotlib.pyplot as plt
from matplotlib.widgets import Slider
from matplotlib.backends.backend_tkagg import (FigureCanvasTkAgg,  NavigationToolbar2Tk) 

class MultiPlot():
	def __init__(self, time_measurement_strvar):
		self.zoom_level = 0
		self.is_first_coord = True
		self.x1 = 0.0
		self.x2 = 0.0
		self.to_Seconds = 0.0
		self.num_channels = 0
		self.total_time_units = 0
		self.fig = None
		self.axs = None
		self.spos = None
		self.time_measurement_strvar = time_measurement_strvar

	def update(self, val):
		try:
			pos = self.spos.val
			#print('val: {}, pos: {}, zoom: {}'.format(val, pos, zoom_level))
			for x in range(self.num_channels):
				self.axs[x].axis([pos,pos+self.zoom_level,-0.1,1.2])

			self.fig.canvas.draw_idle()

		except Exception as e:
			print(e)
			print('ERROR - failed to scroll')

	def zoom(self, event):
		if event.button == 'up': # IN
			self.zoom_level = self.zoom_level * 0.9
		elif event.button == 'down': # OUT
			self.zoom_level = self.zoom_level * 1.1
		else:
			self.zoom_level = self.total_time_units
		
		if self.zoom_level > self.total_time_units:
			self.zoom_level = self.total_time_units

		self.update(event.xdata)

	def onclick(self, event):
		if not event.inaxes:
			return
		try:
			if self.is_first_coord:
				self.is_first_coord = False
				self.x1 = event.xdata
			else:
				self.is_first_coord = True
				self.x2 = event.xdata
				seconds = abs(self.x1 - self.x2) * self.to_Seconds
				if seconds == 0:
					return
				units = 0
				unit_names = [' s', ' ms', ' us', ' ns']
				while int(seconds) == 0 or units >= len(unit_names):
					seconds *= 1000
					units += 1
				self.time_measurement_strvar.set('{:.2f}'.format(seconds) + unit_names[units])
		except Exception as e:
			print(e)
			print('ERROR - failed to convert time')
		# print('%s click: button=%d, x=%d, y=%d, xdata=%f, ydata=%f' %
		#       ('double' if event.dblclick else 'single', event.button,
		#        event.x, event.y, event.xdata, event.ydata))

	def plot_captured_data(self, name, las, ws):

		self.zoom_level = las.total_time_units
		self.to_Seconds = las.getSamplesIntervalInSeconds(las.scaler)
		self.num_channels = las.num_channels
		self.total_time_units = las.total_time_units

		fig, axs = plt.subplots(las.num_channels, sharex=True, sharey=True)
		self.fig = fig
		self.axs = axs
		trigger_point = las.x_axis[las.pre_trigger_byte_count-1]

		canvas = FigureCanvasTkAgg(fig, master=ws)
		canvas.get_tk_widget().pack(side='top',fill='both', expand=True)

		axs[las.channel].axvline(x=trigger_point, color='red', linestyle ="--", linewidth=4)
		fig.suptitle('Source: ' + name)

		for x in range(las.num_channels):
			axs[x].step(las.x_axis, las.channel_data[x],where='post')
			axs[x].set_ylabel('CH-'+str(x+1))

		axpos = plt.axes([0.2, 0.03, 0.65, 0.03])
		self.spos = Slider(axpos, 'Pos', 1, las.total_time_units)
	
		self.spos.on_changed(self.update)
		fig.canvas.mpl_connect('button_press_event', self.onclick)
		fig.canvas.mpl_connect('scroll_event', self.zoom)

		return canvas
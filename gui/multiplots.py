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

from logicAnalyzer import convert_sec_to_relavent_time

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

			for x in range(self.num_channels):
				# constants -0.1 and 1.2 lock the y-axis from moving
				self.axs[x].axis([pos,pos+self.zoom_level,-0.1,1.2])

			self.fig.canvas.draw_idle()

		except Exception as e:
			print(e)
			print('ERROR - failed to zoom')

	def zoom(self, event):
		if event.button == 'up': # IN
			self.zoom_level = self.zoom_level * 0.9
		elif event.button == 'down': # OUT
			self.zoom_level = self.zoom_level * 1.1
		else:
			self.zoom_level = self.total_time_units
		
		if self.zoom_level > self.total_time_units:
			# zoomed out further than the axis goes, reset
			self.zoom_level = self.total_time_units

		self.update(event.xdata)

	def on_click(self, event):
		if not event.inaxes:
			return

		if self.is_first_coord: # set x1
			self.is_first_coord = False
			self.x1 = event.xdata
		else: # set x2
			self.is_first_coord = True
			self.x2 = event.xdata

			# find the difference then multiply by the time scaler
			seconds = abs(self.x1 - self.x2) * self.to_Seconds

			time_measurement = convert_sec_to_relavent_time(seconds)

			self.time_measurement_strvar.set(time_measurement)

	def plot_captured_data(self, name, las, ws):

		self.zoom_level = las.total_time_units
		self.to_Seconds = las.get_samples_interval_in_seconds(las.scaler)
		self.num_channels = las.num_channels
		self.total_time_units = las.total_time_units

		fig, axs = plt.subplots(las.num_channels, sharex=True, sharey=True)
		self.fig = fig
		self.axs = axs
		trigger_point = las.x_axis[las.pre_trigger_byte_count-1]

		# add the figure to the master window
		canvas = FigureCanvasTkAgg(fig, master=ws)
		canvas.get_tk_widget().pack(side='top',fill='both', expand=True)

		# mark the trigger point
		axs[las.channel].axvline(x=trigger_point, color='red', linestyle ="--", linewidth=4)
		# show where the data came from
		fig.suptitle('Source: ' + name)

		# plot each channel
		for x in range(las.num_channels):
			axs[x].step(las.x_axis, las.channel_data[x],where='post')
			axs[x].set_ylabel('CH-'+str(x+1))

		# add the slider
		axpos = plt.axes([0.2, 0.03, 0.65, 0.03])
		self.spos = Slider(axpos, 'Pos', 1, las.total_time_units)
	
		# callbacks
		self.spos.on_changed(self.update)
		fig.canvas.mpl_connect('button_press_event', self.on_click)
		fig.canvas.mpl_connect('scroll_event', self.zoom)

		return canvas
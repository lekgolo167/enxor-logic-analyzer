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
from matplotlib.widgets import Slider, Button
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
		for x in range(self.num_channels):
			# constants -0.1 and 1.2 lock the y-axis from moving
			self.axs[x].axis([self.zoom_left, self.zoom_right,-0.1,1.2])

		self.fig.canvas.draw_idle()

	def find_nearest_transistion_point(self, chan, x_event_point):
		x_event_point = int(x_event_point)
		transition_point = 0
		t_click = self.x_axis[0]
		for i, tstamp in enumerate(self.x_axis):
			if x_event_point <= tstamp:
				transition_point = i
				t_click = tstamp
				break
		if abs(x_event_point-self.x_axis[transition_point-1]) < abs(t_click - x_event_point):
			transition_point -= 1
			t_click = self.x_axis[transition_point]
		click_value = self.channel_data[chan][transition_point]

		left = transition_point - 1
		right = transition_point + 1

		while left >= 0 and right < self.num_x_points:
			t_left = self.x_axis[left]
			t_right = self.x_axis[right]
			if abs(t_click - t_left) < abs(t_click - t_right):
				left_v = self.channel_data[chan][left]
				if left_v != click_value:
					transition_point = left + 1
					break
				left -= 1
			else:
				right_v = self.channel_data[chan][right]
				if right_v != click_value:
					transition_point = right
					break
				right += 1

		return self.x_axis[transition_point]

	def zoom(self, event):
		if event is None or event.xdata is None:
			return
		diff_left = abs(self.zoom_left - event.xdata)
		diff_right = abs(self.zoom_right - event.xdata)
		if event.button == 'up': # IN
			zoom = 0.9
		elif event.button == 'down': # OUT
			zoom = 1.1
		
		self.zoom_left = max(abs(event.xdata - (diff_left * zoom)), 0)
		self.zoom_right = min(abs(event.xdata + (diff_right * zoom)), self.total_time_units)

		self.update(event.xdata)

	def on_click(self, event):
		if not event.inaxes:
			return
		channel_num = event.inaxes.get_subplotspec().rowspan.start
		tp = self.find_nearest_transistion_point(channel_num, event.xdata)
		if self.is_first_coord: # set x1
			self.is_first_coord = False
			self.x1 = tp
			for chan in range(self.num_channels):
				for line in self.axs[chan].get_lines()[1:]:
					if line.get_color() == 'green':
						line.remove()
		else: # set x2
			self.is_first_coord = True
			self.x2 = tp

			# find the difference then multiply by the time scaler
			seconds = abs(self.x1 - self.x2) * self.to_Seconds
			time_measurement = convert_sec_to_relavent_time(seconds)
			self.time_measurement_strvar.set(time_measurement)

		self.axs[channel_num].axvline(x=tp, color='green', linestyle ="--", linewidth=2)
		self.fig.canvas.draw_idle()

	def reset(self, event):
		self.spos.reset()
		self.zoom_left = 0
		self.zoom_right = self.total_time_units

		for x in range(self.num_channels):
				# constants -0.1 and 1.2 lock the y-axis from moving
			self.axs[x].axis([self.zoom_left,self.zoom_right,-0.1,1.2])

		self.fig.canvas.draw_idle()

	def plot_captured_data(self, name, las, ws):

		self.zoom_left = 0
		self.zoom_right = las.total_time_units
		self.to_Seconds = las.get_samples_interval_in_seconds(las.scaler)
		self.num_channels = las.num_channels
		self.total_time_units = las.total_time_units
		self.x_axis = las.x_axis
		self.channel_data = []
		for channel in las.channel_data:
			self.channel_data.append(channel)
		self.num_x_points = len(las.x_axis)
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

		self.spos = Slider(plt.axes([0.2, 0.03, 0.65, 0.03]), 'Pos', 1, las.total_time_units, valinit=trigger_point)
		self.btn = Button(plt.axes([0.0, 0.00, 0.1, 0.03]), 'Reset View')
		# callbacks
		self.spos.on_changed(self.update)
		self.btn.on_clicked(self.reset)
		fig.canvas.mpl_connect('button_press_event', self.on_click)
		fig.canvas.mpl_connect('scroll_event', self.zoom)

		return canvas
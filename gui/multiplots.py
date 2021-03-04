import matplotlib.pyplot as plt
import numpy as np
from matplotlib.widgets import Slider

from logicAnalyzer import *
from serialInterface import *

las = LogicAnalyzerModel()
las.initializeFromConfigFile('./config.json')

configureLogicAnalyzer(las)
enableLogicAnalyzer(las)
data = readIncomingSerialData(las)
readInputstream(data, las)
print(las.pre_trigger_byte_count)
print(las.post_trigger_byte_count)
writeLogicAnalyzerDataToFile('./test_data/test4.bin',las)
fig, axs = plt.subplots(3, sharex=True, sharey=True)

fig.suptitle('Sharing both axes')
axs[0].plot(las.x_axis, las.channel_data[0])
axs[1].plot(las.x_axis,las.channel_data[1])
axs[2].plot(las.x_axis, las.channel_data[2])



axpos = plt.axes([0.2, 0.03, 0.65, 0.03])
spos = Slider(axpos, 'Pos', 1, las.total_time_units)

def update(val):
    pos = spos.val
    axs[0].axis([pos,pos+524288,0,1.1])
    axs[1].axis([pos,pos+524288,0,1.1])
    axs[2].axis([pos,pos+524288,0,1.1])
    fig.canvas.draw_idle()

spos.on_changed(update)

def onclick(event):
    print('%s click: button=%d, x=%d, y=%d, xdata=%f, ydata=%f' %
          ('double' if event.dblclick else 'single', event.button,
           event.x, event.y, event.xdata, event.ydata))

cid = fig.canvas.mpl_connect('button_press_event', onclick)

plt.show()
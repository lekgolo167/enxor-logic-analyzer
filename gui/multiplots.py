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
fig, axs = plt.subplots(las.num_channels, sharex=True, sharey=True)

fig.suptitle('Sharing both axes')
for x in range(las.num_channels):
    axs[x].plot(las.x_axis, las.channel_data[x])



axpos = plt.axes([0.2, 0.03, 0.65, 0.03])
spos = Slider(axpos, 'Pos', 1, las.total_time_units)
zoom_level = las.total_time_units
def update(val):
    global zoom_level

    try:
        pos = spos.val
        #print('val: {}, pos: {}, zoom: {}'.format(val, pos, zoom_level))
        for x in range(las.num_channels):
            axs[x].axis([pos,pos+zoom_level,-0.1,1.2])
        fig.canvas.draw_idle()
    except:
        print('ERROR - failed to scroll')

spos.on_changed(update)

x1 = 0.0
x2 = 0.0
firstCord = True
toSeconds = las.getSamplesIntervalInSeconds()

def onclick(event):
    global firstCord, x1, x2, toSeconds
    try:
        if firstCord:
            firstCord = False
            x1 = event.xdata
        else:
            firstCord = True
            x2 = event.xdata
            seconds = abs(x1-x2)*toSeconds
            if seconds == 0:
                return
            units = 0
            unit_names = [' s', ' ms', ' us', ' ns']
            while int(seconds) == 0 or units >= len(unit_names):
                seconds *= 1000
                units += 1
            print('{:.2f}'.format(seconds) + unit_names[units])
    except:
        print('ERROR - failed to convert time')
    # print('%s click: button=%d, x=%d, y=%d, xdata=%f, ydata=%f' %
    #       ('double' if event.dblclick else 'single', event.button,
    #        event.x, event.y, event.xdata, event.ydata))

cid = fig.canvas.mpl_connect('button_press_event', onclick)

def zoom(event):
    global zoom_level, las
    if event.button == 'up': # IN
        zoom_level = zoom_level * 0.8
    elif event.button == 'down': # OUT
        zoom_level = zoom_level * 1.2
    else:
        zoom_level = las.total_time_units

    update(event.xdata)
f = fig.canvas.mpl_connect('scroll_event', zoom)
plt.show()
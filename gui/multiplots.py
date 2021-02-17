import matplotlib.pyplot as plt
import numpy as np
from matplotlib.widgets import Slider

# Some example data to display
x = np.linspace(0, 2 * np.pi, 20000)
y = np.sin(x ** 2)

fig, axs = plt.subplots(3, sharex=True, sharey=True)
fig.suptitle('Sharing both axes')
axs[0].plot(x, y ** 2)
axs[1].plot(x, 0.3 * y, 'o')
axs[2].plot(x, y, '+')


axpos = plt.axes([0.2, 0.03, 0.65, 0.03])
spos = Slider(axpos, 'Pos', 0.1, 90.0)

def update(val):
    pos = spos.val
    axs[0].axis([pos,pos+2,0,1])
    axs[1].axis([pos,pos+2,0,1])
    axs[2].axis([pos,pos+2,0,1])
    fig.canvas.draw_idle()

spos.on_changed(update)

plt.show()
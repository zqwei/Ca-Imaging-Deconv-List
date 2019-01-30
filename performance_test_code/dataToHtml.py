from glob import glob
import pandas as pd
from bokeh.palettes import Category20
from bokeh.plotting import figure
from bokeh.resources import CDN
from bokeh.embed import file_html
colors= Category20.get(20)
names = ['dF/F', 'S2C Linear', 'S2C Hill', 'S2C Sigmoid', 'NWF', 'FOOPSI', 'FRI', 'AR1', 'AR2', 'AR3', 'MCMC', 'Peel']


for nFolder in glob('MV1*'):
    spkFiles = glob(nFolder + '/*_spk.csv')
    dffFiles = glob(nFolder + '/*_dff.csv')
    for nFile in range(len(spkFiles)):
        fileName = spkFiles[nFile][:-8]#[len(nFolder)+1:]
        outputFileName = fileName + '.html'
        spkdb = pd.read_csv(spkFiles[nFile])
        spkdb['spk'] = spkdb['spk'] * -1.0
        dffdb = pd.read_csv(dffFiles[nFile])
        p = figure(plot_width=1000, plot_height=400, x_axis_label="Time(sec)", y_axis_label="dF/F", x_range=(0, 240))
        p.circle(spkdb['spkTime'], spkdb['spk'], line_width=2, color=colors[0], legend='Spikes')
        for name, color in zip(names, range(1, len(names)+1)):
            p.line(dffdb['time'], dffdb[dffdb.columns[color]], line_width=2, color=colors[color], legend=name)
        p.legend.location = "top_left"
        p.legend.click_policy="hide"
        p.legend.orientation = "horizontal"
        html = file_html(p, CDN, "my plot")

        with open(outputFileName, 'w') as f:
            f.write(html)

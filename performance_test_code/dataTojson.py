from glob import glob
import json
import ipdb
#ipdb.set_trace()

for nFolder in glob('MV1*'):
    htmlFiles = glob(nFolder + '/*.html')
    for nfile in htmlFiles:
        fileName = nfile[:-5]#[len(nFolder)+1:]
        outputFileName = fileName + '.json'
        f = open(nfile)
        line_list = []
        lines = f.readlines()
        for line in lines:
            line_list.append(line)
        render_items = line_list[38]
        render_items = render_items[37:-2]
        render_items = json.loads(render_items)
        components =[]
        components.append(render_items)
        doc_json = line_list[37]
        doc_json = doc_json[34:-2]
        doc_json = json.loads(doc_json)
        components.append(doc_json)
        print(outputFileName)
        with open(outputFileName, 'wb') as outfile:
            json.dump(components, outfile)

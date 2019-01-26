from glob import glob
import json

for nFolder in glob('MV1*'):
    htmlFiles = glob(nFolder + '/*.html')
    for nfile in htmlFiles:
        fileName = nfile[:-5]#[len(nFolder)+1:]
        outputFileName = fileName + '.json'
        f = open(nfile)
        lines = f.readlines()
        for line in lines:
            if 'var render_items' in line:
                render_items = line
                ind = line.find('=')
                ind_end = line.find(';')
                render_items = render_items[ind+2:ind_end]
                render_items = json.loads(render_items)
            
            if 'var docs_json' in line:
                doc_json = line
                ind = line.find('=')
                ind_end = line.find(';')
                doc_json = doc_json[ind+2:ind_end]
                try:
                    doc_json = json.loads(doc_json)
                except:
                    m = len(lines)
                    for n, _ in enumerate(lines):
                        if m<n:
                            continue
                        if 'type="application/json"' in _:
                            m = n
                    doc_json = json.loads(lines[m+1])
                        
        components = [doc_json, render_items]
        print(outputFileName)
        with open(outputFileName, 'wb') as outfile:
            json.dump(components, outfile)

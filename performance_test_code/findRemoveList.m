load('../TempDat/ParamsFitCells_S2CModel_sigmoid_Fmfix.mat', 'paras');
S2C_Sigmoid_Function = paras;
load('../KS_dat_fit/DataListCells.mat');

for nCell = 1:length(S2C_Sigmoid_Function)
    FileList{nCell} = [S2C_Sigmoid_Function(nCell).cellName '_' num2str(S2C_Sigmoid_Function(nCell).nRep, '%03d')];
end

for nCell = 1:length(totCell)
    FileListNew{nCell} = [totCell(nCell).cellName '_' num2str(totCell(nCell).nRep, '%03d')];
end


removeList = [];

for nFile = 1:length(FileList)
    currFile = FileList{nFile};
    for mFile = 1:length(FileListNew)
        currFileNew = FileListNew{mFile};
        if strcmp(currFile, currFileNew)
            break;
        elseif mFile == length(FileListNew)
            removeList = [removeList;nFile];
            disp(currFile)
        end
    end
end

for nCell = removeList'
    disp([FileList{nCell} ';' S2C_Sigmoid_Function(nCell).expression ';' S2C_Sigmoid_Function(nCell).CaIndicator]);
end

save('removeList.mat', 'removeList');
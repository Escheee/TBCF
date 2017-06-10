function genPerfMat(seqs, trackers, evalType, nameTrkAll, perfMatPath, benchmark)

pathAnno = ['./anno/' benchmark '/'];
numTrk = length(trackers);

thresholdSetOverlap = 0:0.05:1;
thresholdSetError = 0:50;

switch evalType
    case 'SRE'
        rpAll=['.\results\results_SRE\'];
    case {'TRE'}
        rpAll=['.\results\results_TRE\'];
    case {'OPE'}
        rpAll=['.\results\results_OPE\'];
end

for idxSeq=1:length(seqs)
    s = seqs{idxSeq};
    
    s.len = s.endFrame - s.startFrame + 1;
    s.s_frames = cell(s.len,1);
    nz	= strcat('%0',num2str(s.nz),'d'); %number of zeros in the name of image
    for i=1:s.len
        image_no = s.startFrame + (i-1);
        id = sprintf(nz,image_no);
        s.s_frames{i} = strcat(s.path,id,'.',s.ext);
    end
    
    rect_anno = dlmread([pathAnno s.name '.txt']);
%     if ~isequal(s.name, 'david')
%         rect_anno = rect_anno(s.startFrame:s.endFrame,:);
%     end
    numSeg = 20;
    [subSeqs, subAnno]=splitSeqTRE(s,numSeg,rect_anno);
    
    nameAll=[];
    for idxTrk=1:numTrk
        
        t = trackers{idxTrk};
        
        load([rpAll s.name '_' t.name '.mat'])
        disp([s.name ' ' t.name]);
        
        aveCoverageAll=[];
        aveErrCenterAll=[];
        errCvgAccAvgAll = 0;
        errCntAccAvgAll = 0;
        errCoverageAll = 0;
        errCenterAll = 0;
        
        lenALL = 0;
        fps = 0;
        
        switch evalType
            case 'SRE'
                idxNum = length(results);
                anno=subAnno{1};
            case 'TRE'
                idxNum = length(results);
            case 'OPE'
                idxNum = 1;
                anno=subAnno{1};
        end
        
        successNumOverlap = zeros(idxNum,length(thresholdSetOverlap));
        successNumErr = zeros(idxNum,length(thresholdSetError));
        
        for idx = 1:idxNum
            res = results{idx};
            
            if strcmp(evalType, 'TRE')
                anno=subAnno{idx};
            end
            
            len = size(anno,1);
            
            if isempty(res)
                break;
            elseif isempty(res.res)
                break;
            end
            
            if ~isfield(res,'type')&&isfield(res,'transformType')
                res.type = res.transformType;
                res.res = res.res';
            end
            
            [aveCoverage, aveErrCenter, errCoverage, errCenter] = calcSeqErrRobust(res, anno);
            
            for tIdx=1:length(thresholdSetOverlap)
                successNumOverlap(idx,tIdx) = sum(errCoverage >thresholdSetOverlap(tIdx));
            end
            
            for tIdx=1:length(thresholdSetError)
                successNumErr(idx,tIdx) = sum(errCenter <= thresholdSetError(tIdx));
            end
            
            lenALL = lenALL + len;
                    
            if isfield(res,'fps')
                fps = res.fps;
            end
        end
        
        fpsTrkAll(idxTrk, idxSeq) = fps;
        
        if strcmp(evalType, 'OPE')
            aveSuccessRatePlot(idxTrk, idxSeq,:) = successNumOverlap/(lenALL+eps);
            aveSuccessRatePlotErr(idxTrk, idxSeq,:) = successNumErr/(lenALL+eps);
        else
            aveSuccessRatePlot(idxTrk, idxSeq,:) = sum(successNumOverlap)/(lenALL+eps);
            aveSuccessRatePlotErr(idxTrk, idxSeq,:) = sum(successNumErr)/(lenALL+eps);
        end
        
    end
end
%
fpsTrkAll = sum(fpsTrkAll,2)./sum((fpsTrkAll > 0),2);
dataName1=[perfMatPath 'aveSuccessRatePlot_' num2str(numTrk) 'alg_overlap_' evalType '_' benchmark '.mat'];
save(dataName1,'aveSuccessRatePlot','nameTrkAll','fpsTrkAll');

dataName2=[perfMatPath 'aveSuccessRatePlot_' num2str(numTrk) 'alg_error_' evalType '_' benchmark '.mat'];
aveSuccessRatePlot = aveSuccessRatePlotErr;
save(dataName2,'aveSuccessRatePlot','nameTrkAll','fpsTrkAll');

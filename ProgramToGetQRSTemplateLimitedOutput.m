function []=ECGAndIBIFromEDFWithQRSFilter(dest,subjects);
%load the file with ECG, ecg30-45 which is the cwt from 30 to 45 hz
slashtype='\';
if isunix;slashtype='/';end
subjectfolder=[cd slashtype];
%subjectfolder=dest %[cd slashtype dest ];

for i=1 :numel(subjects)
    edffullpath = dir(fullfile(subjects{i}, '*.edf'));
    edffilename =edffullpath(1).name;
    substring = split(edffullpath.folder, slashtype);
    editedpath=  [slashtype substring{2} slashtype substring{3} slashtype substring{4}...
        slashtype '02 Files to be Edited' slashtype substring{6}];
    if ~exist(editedpath)
        mkdir(editedpath)
    end
    if ~exist([editedpath slashtype 'JERFiles'])
        mkdir([editedpath slashtype 'JERFiles']);
    end
    if ~exist([editedpath slashtype 'JERFigures'])
        mkdir([editedpath slashtype 'JERFigures']);
    end
    % if isempty(dir(editedpath 'JERFiles'));
    % if isempty(dir('JERFigures'));mkdir('JERFigures');end
    filename=split(edffullpath.name,'.');
    filename= filename{1};
    tempobj=Bradshaw_ECGData;
    ecgdataname=[filename '_ecgdata.mat'];
    stringsplit=split(filename,{'_',' '});
    tempobj.participantnumber=str2num(stringsplit{1});
    tempobj.age=stringsplit{2};
    tempobj.filename=ecgdataname;
    tempobj.filedirectory=cd;
    tempobj.edffilename=filename;

    if exist([editedpath slashtype ecgdataname],'file')
        disp(['load ' ecgdataname]);
        load(ecgdataname);
    else
        disp(['save ' ecgdataname]);
        save([editedpath slashtype tempobj.filename],'tempobj');
    end;


    timelogtable=dir(fullfile(edffullpath.folder, '*Timelog.txt'));
    timelogtable=readtable([edffullpath.folder slashtype timelogtable.name]);
    if ~isunix
        header=JER_edfinfo(edffilename);
    else
        header=edfinfo([edffullpath.folder slashtype edffilename]);
    end


    if ~length(tempobj.ecg)
        disp(['read edf ' filename]);
        if ~isunix                              % Is changed to avoid 
            [hdr data]=edfread(edffilename);
            ecg=data(1,:);
        else
            data=edfread([edffullpath.folder slashtype edffilename]);
            ecgvar = data.Properties.VariableNames;
            ecgvar = ecgvar{contains(ecgvar,'ECG')};
            ecg=vertcat(data.(ecgvar){:});
            ecg=ecg';
        end
        samplerate=header.NumSamples(1);
        ecg=ecg-mean(ecg);
        ecg=ecg*128/(max(ecg)-min(ecg));
        tempobj.ecg=ecg;
        tempobj.samplerate=samplerate;
        splitstring=split(header.StartTime,'.');
        if splitstring{1} == '12';splitstring(1)='24';end;
        tempobj.edfstarttime=str2num(splitstring{1})*60*60 + str2num(splitstring{2})*60 + str2num(splitstring{3});
        save([editedpath slashtype ecgdataname],'tempobj');
    else
        ecg=tempobj.ecg;
        samplerate=tempobj.samplerate;
    end

    if ~length(tempobj.ecg_icwt)
        disp('do cwt');
        tempobj=tempobj.filterecg;
        save([edffullpath.folder slashtype tempobj.filename],'tempobj');
    else
        disp('ecg_icwt already exists');
    end

    ecg10_45=tempobj.ecg_icwt;
    ecg30_45=tempobj.ecg_icwt_30_45;
    ecg10_45=ecg10_45-mean(ecg10_45);
    ecg10_45=ecg10_45*128/(max(ecg10_45)-min(ecg10_45));
    ecg30_45=ecg30_45-mean(ecg30_45);
    ecg30_45=ecg30_45*128/(max(ecg30_45)-min(ecg30_45));

    if ~isunix;
        header1=edfheader('EDF+');
        header1.Patient=header.Patient;
        header1.Recording=header.Recording;
        header1.StartDate=header.StartDate;
        header1.StartTime=header.StartTime;
        header1.NumDataRecords=1;
        header1.DataRecordDuration=seconds(length(ecg)/samplerate);
        header1.NumSignals=1;
        header1.SignalLabels=header.SignalLabels{1};
        header1.TransducerTypes=header.TransducerTypes{1};
        header1.PhysicalDimensions=header.PhysicalDimensions{1};
        header1.PhysicalMax=max(ecg);
        header1.PhysicalMin=min(ecg);
        header1.DigitalMax=header.DigitalMax(1);
        header1.DigitalMin=header.DigitalMin(1);
        header1.Prefilter=header.Prefilter{1};
        header1.SignalReserved=header.SignalReserved{1};
    end %only do in windows

    if ~length(tempobj.ecg_icwt)
        disp('do cwt');
        tempobj=tempobj.filterecg;
        save([edffullpath.folder slashtype tempobj.filename],'tempobj');
    else
        disp('ecg_icwt already exists');
    end

    ecg10_45=tempobj.ecg_icwt;
    ecg30_45=tempobj.ecg_icwt_30_45;
    ecg10_45=ecg10_45-mean(ecg10_45);
    ecg10_45=ecg10_45*128/(max(ecg10_45)-min(ecg10_45));
    ecg30_45=ecg30_45-mean(ecg30_45);
    ecg30_45=ecg30_45*128/(max(ecg30_45)-min(ecg30_45));

    if ~isunix
        if ~exist(strrep(edffilename,'.edf','_10_45.edf'))
            disp(['write ' strrep(edffilename,'.edf','_10_45.edf')]);
            header1.PhysicalMax=max(ecg10_45);
            header1.PhysicalMin=min(ecg10_45);
            edfwrite(strrep(edffilename,'.edf','_10_45.edf'),header1,ecg10_45,'InputSampleType','physical');
        end
    end %end of unix

    %example displays
    [a b]=ismember('Baseline',timelogtable.Condition);
    if ~a
        [a b]=ismember('OIX',timelogtable.Condition);
    end

    plottimestart=int32(timelogtable.Start_min__Elapsed(b)*samplerate*60);
    plottimeend=int32(timelogtable.End_min__Elapsed(b)*samplerate*60);
    plottimestart10=plottimestart+10*samplerate;

    sessionstart=min(int32(timelogtable.Start_min__Elapsed(:)*samplerate*60));
    sessionstart=max(sessionstart-5*samplerate,10);
    sessionend=max(int32(timelogtable.End_min__Elapsed(:)*samplerate*60));
    sessionend=min(sessionend+5*samplerate,length(ecg));

    figure;
    subplot(1,3,1);
    hold on;
    plot(ecg(plottimestart:plottimeend));
    subplot(1,3,2);
    hold on;
    plot(ecg10_45(plottimestart:plottimeend));
    subplot(1,3,3);
    hold on;
    plot(ecg30_45(plottimestart:plottimeend));
    saveas(gcf,[editedpath slashtype 'JERFigures',filesep,'BaselineData.jpg']);

    figure;
    subplot(1,3,1);
    hold on;
    plot(ecg(plottimestart:plottimestart10));
    subplot(1,3,2);
    hold on;
    plot(ecg10_45(plottimestart:plottimestart10));
    subplot(1,3,3);
    hold on;
    plot(ecg30_45(plottimestart:plottimestart10));
    saveas(gcf,[editedpath slashtype 'JERFigures',filesep,'BaselineFirst10s.jpg']);

    minpeakheight=prctile(ecg30_45(plottimestart:plottimeend),95);
    [pk loc]=findpeaks(ecg30_45(plottimestart:plottimeend),'minpeakheight',minpeakheight,'minpeakdistance',samplerate*.1);
    loc=loc+double(plottimestart);
    figure;plot(plottimestart:plottimeend,ecg30_45(plottimestart:plottimeend))
    hold on
    plot(loc,ecg30_45(loc));
    saveas(gcf,[editedpath slashtype 'JERFigures',filesep,'BaselinePrelimFindPeaks.jpg']);

    figure;plot(plottimestart:plottimestart10,ecg30_45(plottimestart:plottimestart10))
    hold on
    k=find(loc >= plottimestart & loc <= plottimestart10);
    plot(loc(k),ecg30_45(loc(k)));
    saveas(gcf,[editedpath slashtype 'JERFigures',filesep,'BaselineFirst10sFindPeaks.jpg']);

    switch(samplerate)
        case 128
            lengthtemplate=13;
            sampleoffset=6;
        case 256
            lengthtemplate=13;
            sampleoffset=6;
        case 512
            lengthtemplate=25;
            sampleoffset=12;
        case 1024
            lengthtemplate=51;
            sampleoffset=25;
    end;
    sampleoffset=int32(sampleoffset);
    qrstemplate=zeros(1,lengthtemplate);

    if size(ecg,1) > size(ecg,2)
        ecg=ecg';
    end

    qrstemplate=zeros(1,lengthtemplate);

    figure;
    for i=1:length(loc);
        ecgstartloc=int32(loc(i)-sampleoffset);
        ecgendloc=int32(loc(i)+sampleoffset);
        qrstemplate=qrstemplate+ecg10_45(ecgstartloc:ecgendloc);
        subplot(3,2,1);hold on;
        plot(ecg30_45(ecgstartloc:ecgendloc));
    end
    title('ECG at current IBIs');
    qrstemplate=qrstemplate/(max(qrstemplate)-min(qrstemplate));

    subplot(3,2,2);plot(qrstemplate);
    title('qrstemplate')
    pause(1)


    ecgfilter=filtfilt(qrstemplate,1,ecg10_45);
    ecgfilter=ecgfilter-mean(ecgfilter);
    ecgfilter=128*ecgfilter/max(abs(ecgfilter));

    %ecgfilter=ecgfilter*128/(max(ecgfilter)-min(ecgfilter));


    subplot(3,2,3);
    plot(ecg(plottimestart:plottimestart10))
    hold on
    plot(ecg10_45(plottimestart:plottimestart10))
    title('ECG and 10-45 ECG');
    subplot(3,2,4);
    plot(ecg(plottimestart:plottimestart10))
    hold on
    plot(ecg30_45(plottimestart:plottimestart10))
    title('ECG and 30-45 ECG');
    subplot(3,2,5);
    plot(ecg(plottimestart:plottimestart10))
    hold on
    plot(ecgfilter(plottimestart:plottimestart10))
    title('ECG and QRS Filter ECG')

    if ~isunix & ~exist(strrep(edffilename,'.edf','_QRSfilter.edf'))
        disp(['save ' strrep(edffilename,'.edf','_QRSfilter.edf')]);
        header1.PhysicalMax=max(ecgfilter);
        header1.PhysicalMin=min(ecgfilter);
        edfwrite(strrep(edffilename,'.edf','_QRSFilter.edf'),header1,ecgfilter,'InputSampleType','physical');
    end

    sig=ecg30_45;
    sig(1:sessionstart)=0;
    sig(sessionend:length(sig))=0;
    sig=128*sig/max(abs(sig));



    %the script below uses level 4 and 5, but frequency assumes sample rate is 1024
    %interp1 to 1024, do proc, then interp back to samplerate.
    %need extract because from lower to higher rate has missing data
    %e.g, 128, 256, or 512
    if samplerate ~= 1024;
        sig=interp1(1/samplerate:1/samplerate:length(sig)/samplerate,sig,1/1024:1/1024:length(sig)/samplerate,'linear','extrap');
    end

    %use the modwt to get the sym4 breakdown
    %then create a QRS wave from the peaks
    %the modwt is the overlap of the sym4 wavlet and data.
    %this is probably sampling rate dependent
    %may need to set up a specific filterbank with sym4.
    wt = modwt(sig,5);
    wtrec = zeros(size(wt));
    wtrec(4:5,:) = wt(4:5,:);
    y = imodwt(wtrec,'sym4');
    y = abs(y).^2;
    %first derivative of y
    y=gradient(y)./gradient(1/samplerate:1/samplerate:length(ecg)/samplerate);
    y=gradient(y)./gradient(1/samplerate:1/samplerate:length(ecg)/samplerate);
    y = abs(y).^2;

    %if samplerate is not 1024, then interp back to samplerate
    %need extract because going from lower to higher rate has missing data
    %however, max sample rate is 1024 so this is probably not an issue
    if samplerate ~= 1024;
        y=interp1(1/1024:1/1024:length(y)/samplerate,y,1/samplerate:1/samplerate:length(sig)/samplerate,'linear','extrap');
    end


    minpeakheight=prctile(ecg10_45(plottimestart:plottimeend),90);
    [pk loc]=findpeaks(ecg10_45(plottimestart:plottimeend),'minpeakheight',minpeakheight,'minpeakdistance',samplerate*.1);
    meanpeakdistance=prctile(diff(loc),10)*.5;
    [pk loc]=findpeaks(ecg10_45,'minpeakheight',minpeakheight,'minpeakdistance',meanpeakdistance);
    figure;
    subplot(2,3,1);
    plot(plottimestart:plottimestart10,ecg10_45(plottimestart:plottimestart10));
    hold on
    k=find(loc > plottimestart & loc < plottimestart10);
    plot(loc(k),ecg10_45(loc(k)));
    title('qrs peaks on 10-45');
    k=find(loc >= sessionstart & loc <= sessionend);
    timeibi=loc(k)'/samplerate;timeibi(:,2)=timeibi(:,1)*0;
    save([editedpath slashtype 'JERFiles' filesep strrep(edffilename,'.edf','_10_45_HPER.mat')],'timeibi');
    minpeakheight=prctile(ecgfilter(plottimestart:plottimeend),95);
    [pk loc]=findpeaks(ecgfilter(plottimestart:plottimeend),'minpeakheight',minpeakheight,'minpeakdistance',samplerate*.1);
    meanpeakdistance=prctile(diff(loc),10)*.5;
    [pk loc]=findpeaks(ecgfilter,'minpeakheight',minpeakheight,'minpeakdistance',meanpeakdistance);
    subplot(2,3,2);
    plot(plottimestart:plottimestart10,ecg10_45(plottimestart:plottimestart10));
    hold on
    k=find(loc > plottimestart & loc < plottimestart10);
    plot(loc(k),ecg10_45(loc(k)));
    title('qrs peaks from ECG filter on ecg-10-45')
    k=find(loc >= sessionstart & loc <= sessionend);
    timeibi=loc(k)'/samplerate;timeibi(:,2)=timeibi(:,1)*0;
    save([editedpath slashtype 'JERFiles' filesep strrep(edffilename,'.edf','_10_45_qrsfilter_HPER.mat')],'timeibi');


    ecg=ecg10_45;
    save([editedpath slashtype 'JERFiles' filesep strrep(edffilename,'.edf','_10_45_ECG.mat')],'ecg');
    ecg=ecgfilter;
    save([editedpath slashtype 'JERFiles' filesep strrep(edffilename,'.edf','_10_45_qrsfilter_ECG.mat')],'ecg');

    %write the ECG in 250 hz, 10_45 only
    %create the output ecg even if cardio exist
    disp(['interpolate from ' num2str(samplerate) ' hz t0 250 hz']);
    ecg250hz=interp1((1/samplerate):(1/samplerate):(length(ecg10_45)/samplerate),ecg10_45,(1/250):(1/250):(length(ecg10_45)/samplerate));

    ecg250hz=ecg250hz-mean(ecg250hz);
    ecg250hz=ecg250hz*(2e+06)/(max(ecg250hz)-min(ecg250hz));

    outputecgfilename=strrep(edffilename,'.edf','_10_45_qrsfilter_250Hz.txt');
    ecg250output=zeros(length((1/250):(1/250):(length(ecg10_45)/samplerate)),4);
    ecg250output(:,1)=(1/250):(1/250):(length(ecg10_45)/samplerate)'; %from zero
    ecg250output(:,1)=ecg250output(:,1)+tempobj.edfstarttime;
    ecg250output(:,2)=(1/250):(1/250):(length(ecg10_45)/samplerate); %time from zero
    ecg250output(:,3)=(1/250):(1/250):(length(ecg10_45)/samplerate); %time from zero
    ecg250output(:,1:3)=ecg250output(:,1:3)-1/250; %from zero
    ecg250output(:,4)=ecg250hz';

    disp(['write the 250 hz ECG ' outputecgfilename]);
    writematrix(ecg250output,[editedpath slashtype 'JERFiles' filesep outputecgfilename],'delimiter','tab');

    %the following writes the IBIs to a file in CardioEdit format
    outputibifilename=strrep(edffilename,'.edf','_10_45_qrsfilter_IBI.txt');
    dirlist=dir(fullfile(edffullpath.folder, '*Timelog.txt'));
    %these select options
    opts=detectImportOptions([dirlist.folder slashtype dirlist.name]);
    opts=setvaropts(opts,'VisitDate','InputFormat','MM/dd/yyyy');
    timelogtable=readtable([dirlist.folder slashtype dirlist.name ],opts);
    if  exist([editedpath slashtype 'JERFiles' filesep outputibifilename])
        disp(['file already exists ' outputibifilename])
    else
        [a b]=sort(timelogtable.Start_min__Elapsed);
        timelogtable.Start_min__Elapsed=timelogtable.Start_min__Elapsed(b);
        timelogtable.End_min__Elapsed=timelogtable.End_min__Elapsed(b);
        k=find(timeibi(:,1) < timelogtable.Start_min__Elapsed(1)*60);
        timeibi(k,:)=[];
        k=find(timeibi(:,1) > timelogtable.End_min__Elapsed(end)*60);
        timeibi(k,:)=[];
        for i=1:height(timelogtable)-1;
            k=find(timeibi(:,1) > timelogtable.End_min__Elapsed(i)*60 & timeibi(:,1) < timelogtable.Start_min__Elapsed(i+1)*60);
            timeibi(k,:)=[];
        end;


        clear ibioutput;
        clear tempdiff;
        ibioutput(:,1)=timeibi(:,1)+tempobj.edfstarttime;
        ibioutput(:,2)=timeibi(:,1);
        ibioutput(:,3)=timeibi(:,1);
        tempdiff=diff(timeibi(:,1));
        tempdiff(end+1)=tempdiff(end);
        ibioutput(:,4)=tempdiff*1000;
        disp(['write the IBI file ' outputibifilename]);
        writematrix(ibioutput,[editedpath slashtype 'JERFiles' filesep outputibifilename],'delimiter','tab');
    end




end


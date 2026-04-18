

function TabbedGUI()

% main window


%iconPath = fullfile(pwd,'icon.png');


fig1 = uifigure( ...
    'Name', 'NEP', ...
    'Position', [500 300 900 700],'Resize','off');
%fig1.Icon = fullfile(pwd,'icon2.png');

uiimage(fig1,"ImageSource",'icon3.png',Position=[100,620,70,70])
uilabel(fig1,"Text",'NANO ECG Pipline',Position=[175,630,500,50],FontSize=40,FontName='Snap ITC');
uiimage(fig1,"ImageSource",'icon.png',Position=[630,620,70,70])
uiimage(fig1,"ImageSource",'icon3.png',Position=[700,620,70,70])


% tab group
tabgroup1 = uitabgroup(fig1,'Position', [10 10,870 600]);

tab11 = uitab(tabgroup1, 'Title', 'Processing');
tab12 = uitab(tabgroup1, 'Title', 'View');

tabgroup2 = uitabgroup(tab11,'Position', [10 20,840 540]);
tab21 = uitab(tabgroup2, 'Title', 'Prepare Raw Data');
tab22 = uitab(tabgroup2, 'Title', 'Feature Extraction');

tabgroup_view= uitabgroup(tab12, Position=[20,5,840,360]);
tab1_view = uitab(tabgroup_view, "Title","JER Figures");
tab2_view = uitab(tabgroup_view,"Title","JER Files");

tabgroup_featureExt= uitabgroup(tab22, Position=[10,5,810,330]);
tab1_fex= uitab(tabgroup_featureExt, "Title","JER Figures");
tab2_fex = uitab(tabgroup_featureExt,"Title","JER Files");

% TAB 1 Content

pathFieldsrc = uieditfield(tab21, 'text', ...
    'Position', [20 460 440 30], ...
    'Placeholder', 'Raw Data Path...');

browseBtnsrc = uibutton(tab21, ...
    'Text', 'Browse...', ...
    'Position', [470 460 100 30], ...
    'ButtonPushedFcn', @(btn,event) browseFile('src'));

pathFielddest = uieditfield(tab21, 'text', ...
    'Position', [20 370 440 30], ...
    'Placeholder', 'Destination Path...');

browseBtndest = uibutton(tab21, ...
    'Text', 'Browse...', ...
    'Position', [470, 370 100 30], ...
    'ButtonPushedFcn', @(btn,event) browseFile('dest'));

lstbx= uilistbox(tab22,Position=[10,390,810,100],FontColor='#1A873A',Items={},...
    ValueChangedFcn= @(src,event) getlstbxitem(src));


moveBtn = uibutton(tab21, ...
    'Text', 'Start...', ...
    'Position', [20 300 100 35], ...
    'ButtonPushedFcn', @(btn,event) moveFiles(pathFieldsrc.Value, pathFielddest.Value, ...
    tabgroup2, tab21, lstbx,fig1));


%% ------------------------
% TAB 2 Content


statusLabel = uilabel(tab22, ...
    'Text', 'List of Copied Raw Data Files',  ...
    'Position', [300 490 300 25],FontSize=16, FontName='Arial',FontWeight='bold');
% p = uipanel(tab22);
% p.Title = 'Image Editor';
% p.Position = [100,5,650,310];
% resimg= uiimage(p,"ImageSource",'BaselinePrelimFindPeaks.jpg', Position=[50,10,300,280]);
resimg= uiimage(tab1_fex,"ImageSource",'BaselinePrelimFindPeaks.jpg', Position=[300,5,240,230],Visible='off');

lstbx2= uilistbox(tab1_fex,Position=[10,240,795,65],FontColor='#1A873A',Items={},...
    ValueChangedFcn= @(src,event) showimage(src.Value, lstbx.Value ));
lstbx3= uilistbox(tab2_fex,Position=[10,240,795,65],FontColor='#1A873A',Items={},...
    ValueChangedFcn= @(src,event) showJERFiles1(src.Value, lstbx.Value ));

band1= uieditfield(tab22,'numeric', Position=[330,350,40,30], Enable='on',Value=10);
band1.ValueChangedFcn = @(src,event) disp(src.Value);
bnd1lbl = uilabel(tab22, ...
    'Text', 'Lower band',  ...
    'Position', [250 330 80 60],FontSize=12, FontName='Arial',FontWeight='bold');

band2= uieditfield(tab22,'numeric', Position=[460,350,40,30], Enable='on',Value=45);
band2.ValueChangedFcn = @(src,event) disp(src.Value);

bnd2lbl = uilabel(tab22, ...
    'Text', 'Upper band',  ...
    'Position', [380 330 80 60],FontSize=12, FontName='Arial',FontWeight='bold');
runBtn = uibutton(tab22, ...
    'Text', 'Run Filtering and IBI Extraction', ...
    'Position', [20 345 200 40], ...
    'ButtonPushedFcn', @(btn,event) runProgram(fig1, pathFielddest.Value, lstbx, [band1.Value, band2.Value]));

ax1 = uiaxes(tab2_fex, 'Position', [5, 10, 790, 210]);


%% Tab12  --------------------------------------
pathFieldsrc121 = uieditfield(tab12, 'text', ...
    'Position', [20 520 440 30], ...
    'Placeholder', 'Filtered Data Files Path...');

browseBtnsrc121 = uibutton(tab12, ...
    'Text', 'Browse...', ...
    'Position', [470 520 100 30], ...
    'ButtonPushedFcn', @(btn,event) browseFile('load'));

loadBtn = uibutton(tab12, ...
    'Text', 'Load', ...
    'Position', [20 480 80 30], ...
    'ButtonPushedFcn', @(btn,event) loadfiles(fig1, pathFieldsrc121.Value));

lstbx121= uilistbox(tab12,Position=[20,370,840,100],FontColor='#1A873A',Items={},...
    ValueChangedFcn= @(src,event) getlstbxitemloadtab(src));

uilabel(tab12, ...
    'Text', 'List of Filtered Data Files',  ...
    'Position', [300 470 300 25],FontSize=18, FontName='Arial',FontWeight='bold');
% p = uipanel(tab22);
% p.Title = 'Image Editor';
% p.Position = [100,5,650,310];
% resimg= uiimage(p,"ImageSource",'BaselinePrelimFindPeaks.jpg', Position=[50,10,300,280]);
resimg122= uiimage(tab1_view,"ImageSource",'BaselinePrelimFindPeaks.jpg', Position=[300,5,270,270],Visible='off');

uilabel(tab12,"Text",'Results',Position=[350,330,400,50],FontSize=20,FontName='Amasis MT Pro Black',...
    FontWeight = 'bold');
lstbx122= uilistbox(tab1_view,Position=[5,280,820,55],FontColor='#1A873A',Items={},...
    ValueChangedFcn= @(src,event) showimageloadtab(src.Value, lstbx121.Value ));
lstbx222= uilistbox(tab2_view,Position=[5,280,820,55],FontColor='#1A873A',Items={},...
    ValueChangedFcn= @(src,event) showJERFiles2(src.Value, lstbx121.Value ));


ax2 = uiaxes(tab2_view, 'Position', [5, 10, 790, 240]);



%% --------------------------------
% btnZoomIn = uibutton(p, 'Text', 'Zoom In X', ...
% 'Position', [20 20 100 30], ...
% 'ButtonPushedFcn', @(btn,event) zoomX(ax, 0.5));
%
% btnZoomOut = uibutton(p, 'Text', 'Zoom Out X', ...
% 'Position', [140 20 100 30], ...
% 'ButtonPushedFcn', @(btn,event) zoomX(ax, 2));

% ax = uiaxes(p, 'Position', [10, 10, 620, 280]);
% plot(ax, rand(1, 100)); % Placeholder for actual data plotting


%% ------------------------
    function showimage(imgname, path)
        slashtype='\';
        if isunix;slashtype='/';end

        imgname= imgname;

        substring = split(path, slashtype);
        editedpath= [slashtype substring{2} slashtype substring{3} slashtype substring{4}...
            slashtype substring{5} slashtype '02 Files to be Edited' slashtype substring{7} slashtype 'JERFigures' slashtype imgname];
       
        resimg.ImageSource=editedpath;
        resimg.Visible= 'on';
    end



    function getlstbxitem( selectedItem)
        slashtype='\';
        if isunix;slashtype='/';end


        substring = split(selectedItem.Value, slashtype);
        editedpathfig= [slashtype substring{2} slashtype substring{3} slashtype substring{4}...
            slashtype substring{5} slashtype '02 Files to be Edited' slashtype substring{7} slashtype 'JERFigures'];
        editedpathfile= [slashtype substring{2} slashtype substring{3} slashtype substring{4}...
            slashtype substring{5} slashtype '02 Files to be Edited' slashtype substring{7} slashtype 'JERFiles' ];

        jpgs = dir(fullfile(editedpathfig, '*.jpg'));
        jpgNames = {jpgs.name};
        lstbx2.Items = jpgNames;

        files= dir(fullfile(editedpathfile,'*.*'));
        files = files(~[files.isdir]);
        filenames= {files.name};
        lstbx3.Items = filenames;

    end
    function showJERFiles1(name, path)
        slashtype='\';
        if isunix;slashtype='/';end


        substring = split(path, slashtype);
        editedpath= [slashtype substring{2} slashtype substring{3} slashtype substring{4}...
            slashtype substring{5} slashtype '02 Files to be Edited' slashtype substring{7} slashtype 'JERFiles' slashtype name];
        [~,~,ext] = fileparts(name);

        switch ext
            case '.mat'
                data = load(editedpath);
                fn = fieldnames(data);
                signal = data.(fn{1});

            case '.txt'
                signal = readmatrix(editedpath);

        end

        plot(ax1, signal);

        %plot(ax, signal);
        xlabel(ax1,'Samples');
        ylabel(ax1,'Amplitude');
        title(ax1,'Signal');
        grid(ax1,'on');


    end

    function browseFile(btnid)

        path = uigetdir();

        if isempty(path)
        end

        if strcmp(btnid, 'src')
            pathFieldsrc.Value = path;
        elseif strcmp(btnid, 'dest')
            pathFielddest.Value = path;
        elseif strcmp(btnid,'load')
            pathFieldsrc121.Value= path;

        else
            return;
        end

    end


    function moveFiles(src, dest,tabgroup, tab2, lstbx,fig)
        %
        if isempty(src)
            msgbox('Select Raw Data Path.');
            return;

        elseif isempty(dest)
            msgbox('Select Destination Path.');
            return;
        end

        %d = uiprogressdlg(fig,'Title','Processing','Indeterminate','on');
        %drawnow

        lst = moveNewRawDataTo01(src, dest);
        if numel(lst) ==0
            uialert(fig,'No New Raw Files Found!','Message')
            return
        end
        lstbx.Items = lst;
        tabgroup.SelectedTab = tab22;
        %close(d)


    end
    function runProgram(fig, dest, lstbx, filterband)

        %filename = pathFieldsrc.Value;

        if isempty(lstbx.Items)
            uialert(fig, 'Files Not Found!', 'Message');
            return;
        end

        if isempty(pathFielddest)
            uialert(fig, 'Please select destination', 'Error');
            return;
        end

        ProgramToGetQRSTemplateLimitedOutput(dest,lstbx.Items, filterband);

        msgbox('Processing Completed Successfully.');

    end

    function loadfiles(fig, basePath)

        folderPaths = {};

        d = dir(basePath);
        d = d([d.isdir]);

        names = {d.name};
        names = names(~ismember(names, {'.', '..'}));

        for i = 1:length(names)
            currentFolder = fullfile(basePath, names{i});
            folderPaths{end+1} = currentFolder;

        end
        if isempty(folderPaths)
            uialert(fig1,'Files Not Found!','Message')
        else
            lstbx121.Items=folderPaths;
        end
    end

    function getlstbxitemloadtab( selectedItem)
        slashtype='\';
        if isunix;slashtype='/';end


        substring = split(selectedItem.Value, slashtype);
        editedpathfigs= [slashtype substring{2} slashtype substring{3} slashtype substring{4}...
            slashtype substring{5} slashtype substring{6} slashtype substring{7} slashtype 'JERFigures'];
        editedpathfiles= [slashtype substring{2} slashtype substring{3} slashtype substring{4}...
            slashtype substring{5} slashtype substring{6} slashtype substring{7} slashtype 'JERFiles'];
        jpgs = dir(fullfile(editedpathfigs, '*.jpg'));
        files= dir(fullfile(editedpathfiles,'*.*'));
        files = files(~[files.isdir]);

        jpgNames = {jpgs.name};
        filenames= {files.name};

        lstbx122.Items = jpgNames;
        lstbx222.Items = filenames;


    end

    function showimageloadtab(imgname, path)
        slashtype='\';
        if isunix;slashtype='/';end

        substring = split(path, slashtype);
        editedpath= [slashtype substring{2} slashtype substring{3} slashtype substring{4}...
            slashtype substring{5} slashtype substring{6} slashtype substring{7} slashtype 'JERFigures' slashtype imgname];

        resimg122.ImageSource=editedpath;
        resimg122.Visible='on';
    end

    function showJERFiles2(name, path)
        slashtype='\';
        if isunix;slashtype='/';end


        substring = split(path, slashtype);
        editedpath= [slashtype substring{2} slashtype substring{3} slashtype substring{4}...
            slashtype substring{5} slashtype substring{6} slashtype substring{7} slashtype 'JERFiles' slashtype name];
        [~,~,ext] = fileparts(name);

        switch ext
            case '.mat'
                data = load(editedpath);
                fn = fieldnames(data);
                signal = data.(fn{1});

            case '.txt'
                signal = readmatrix(editedpath);

        end

        plot(ax2, signal);

        %plot(ax, signal);
        xlabel(ax2,'Samples');
        ylabel(ax2,'Amplitude');
        title(ax2,'Signal');
        grid(ax2,'on');


    end
end
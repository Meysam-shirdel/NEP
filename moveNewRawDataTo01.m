%% Copy files from rawData into 01 if they are not already located somewhere in ECG Root
    % Save skipped files into two .csv files 
    function readytofilterlst= moveNewRawDataTo01(src, dest)
    tic;   % Start runtime timer

slashtype='\';
if isunix;slashtype='/';end

% Define folders
rawFolder = src;
ibiFolder = [dest slashtype '05 Final IBIs'];

% Get all EDF files 
rawFiles = dir(fullfile(rawFolder,'**','*.edf'));
ibiFiles = dir(fullfile(ibiFolder,'**','*.edf'));

% Extract file names
rawNames = {rawFiles.name};
ibiNames = {ibiFiles.name};

% Remove files that also exist in Final IBIs
remainingEDF = setdiff(rawNames, ibiNames);


readytofilterlst={};
rawRoot  = src;
ecgRoot  = dest; 
destRoot = fullfile(ecgRoot, '01 Files to be Filtered');
editfolder = fullfile(ecgRoot,'02 Files to be Edited');
finalIbiRoot = fullfile(ecgRoot, '05 Final IBIs');
finalIbiRootLower = lower(finalIbiRoot);

% ===== USER INPUT =====
maxToProcess =numel(remainingEDF);% input('Enter number of files to copy (e.g., 1, 10, or Inf for all): ');

if isempty(maxToProcess) || ~isnumeric(maxToProcess) || maxToProcess <= 0
    error('Invalid input. Please enter a positive number or Inf.');
end
% ======================

%% 1) List all Raw Data timelogs
rawTimelogs = dir(fullfile(rawRoot, '*_Timelog.txt'));
if isempty(rawTimelogs)
    fprintf('No *_Timelog.txt files found in Raw Data.\n');
    return;
end

rawNames = string({rawTimelogs.name})';  % column vector

%% 2) Index all ecgRoot timelogs ONCE (for fast membership checks)
fprintf('Indexing existing timelog files under ecgRoot (one-time scan)...\n');
ecgTimelogs = dir(fullfile(ecgRoot, '**', '*_Timelog.txt'));

% Map: lowercase filename -> cell array of full paths (handles duplicates)
timelogIndex = containers.Map('KeyType','char','ValueType','any');

for k = 1:numel(ecgTimelogs)
    nm = lower(ecgTimelogs(k).name);
    fp = fullfile(ecgTimelogs(k).folder, ecgTimelogs(k).name);

    if isKey(timelogIndex, nm)
        paths = timelogIndex(nm);     % get existing cell array
        paths{end+1} = fp;            % append
        timelogIndex(nm) = paths;     % set back
    else
        timelogIndex(nm) = {fp};      % initialize cell array
    end
end

fprintf('Indexed %d timelog file(s) under ecgRoot.\n\n', numel(ecgTimelogs));

%% 3) Create skippedFiles and filesToCopy (and collect ALL found paths for CSV export)

% skippedFiles: [timelogName, firstFoundPath] (quick view)
skippedFiles = strings(0,2);

% filesToCopy: timelogName only (in Raw, not in ecgRoot)
filesToCopy  = strings(0,1);

% foundPathsRows: one row per (timelogName, foundPath) for exporting
foundPathsRows = strings(0,2);  % [timelogName, foundPath]

for i = 1:numel(rawNames)
    tlName = rawNames(i);
    key = lower(char(tlName));

    if isKey(timelogIndex, key)
        paths = timelogIndex(key);  % cell array of full paths

        % for display list (first path only)
        skippedFiles(end+1,:) = [tlName, string(paths{1})]; 

        % for export (ALL paths)
        for p = 1:numel(paths)
            foundPathsRows(end+1,:) = [tlName, string(paths{p})]; 
        end
    else
        filesToCopy(end+1,1) = tlName; 
    end
end


%% 4) Export all found paths to CSV in 01 Files to be Filtered

if ~exist(destRoot, 'dir')
    mkdir(destRoot);
end
if ~exist(editfolder,'dir')
    mkdir(editfolder);
end

% foundPathsIn05Rows: one row per (timelogName, foundPath) where foundPath is inside 05 Final IBIs
foundPathsIn05Rows = strings(0,2);   % [timelogName, foundPath]

% foundPathsNot05Rows: one row per (timelogName, foundPath) where foundPath is in ecgRoot but NOT inside 05 Final IBIs
foundPathsNot05Rows = strings(0,2);  % [timelogName, foundPath]
lst=[];

for i = 1:numel(rawNames)
    tlName = rawNames(i);
    key = lower(char(tlName));
    
    if isKey(timelogIndex, key)
        paths = timelogIndex(key);  % cell array of full paths

        % quick view list (first path)
        skippedFiles(end+1,:) = [tlName, string(paths{1})]; 

        % export ALL paths, split into 05 vs not-05
        for p = 1:numel(paths)
            fp = string(paths{p});
            fpLower = lower(fp);

            if contains(fpLower, finalIbiRootLower)
                foundPathsIn05Rows(end+1,:) = [tlName, fp]; 
            else
                foundPathsNot05Rows(end+1,:) = [tlName, fp]; 
            end
        end
    else
        filesToCopy(end+1,1) = tlName; 
    end
end


%% Export found paths into two CSVs (in 05 Final IBIs vs elsewhere)

if ~exist(destRoot, 'dir')
    mkdir(destRoot);
end

timestamp = datestr(now, 'yyyymmdd_HHMMSS');

% 1) Found in 05 Final IBIs
T_in05 = table;
if ~isempty(foundPathsIn05Rows)
    T_in05 = table(foundPathsIn05Rows(:,1), foundPathsIn05Rows(:,2), ...
        'VariableNames', {'TimelogName','FoundPath'});
end
outCsv05 = fullfile(destRoot, sprintf('Timelog_FoundPaths_IN_05FinalIBIs_%s.csv', timestamp));
writetable(T_in05, outCsv05);
fprintf('Saved IN-05 CSV to:\n%s\n', outCsv05);

% 2) Found elsewhere in ecgRoot (not in 05)
T_not05 = table;
if ~isempty(foundPathsNot05Rows)
    T_not05 = table(foundPathsNot05Rows(:,1), foundPathsNot05Rows(:,2), ...
        'VariableNames', {'TimelogName','FoundPath'});
end
outCsvNot05 = fullfile(destRoot, sprintf('Timelog_FoundPaths_NOTin05_%s.csv', timestamp));
writetable(T_not05, outCsvNot05);
fprintf('Saved NOT-in-05 CSV to:\n%s\n\n', outCsvNot05);

fprintf('====================\n');
fprintf('filesToCopy (NOT found anywhere in ecgRoot): %d\n', numel(filesToCopy));
disp(filesToCopy);
fprintf('====================\n\n');

%% 5) Copy step: use first maxToProcess from filesToCopy
if isempty(filesToCopy)
    fprintf('No files to copy. Done.\n');
    return;
end

nToCopy = min(numel(filesToCopy), maxToProcess);
fprintf('Copying %d file(s) (maxToProcess=%g)...\n\n', nToCopy, maxToProcess);


h = waitbar(5,'Starting...','Position', [500 300 300 75]);
%set(h, 'Position', [500 300 300 75]);

filesToCopy= unique(filesToCopy);
N=numel(filesToCopy);
readytofilterlst={};
waitbar(5/100, h, sprintf('Remaining: %3.0f%%', 100*(1-5/100)));

for j = 1:numel(filesToCopy)  %nToCopy
    
    tlName = char(filesToCopy(j));
    fprintf('Now copying %s ...\n', tlName);

    parts = split(string(tlName), "_");
    if numel(parts) < 2
        fprintf('SKIP (unexpected filename format): %s\n\n', tlName);
        continue;
    end

    idStr    = char(parts(1));
    visitStr = char(parts(2));

    destFolderName = sprintf('%s %s ECG infant', idStr, visitStr);
    destFolderPath = fullfile(destRoot, destFolderName);
    readytofilterlst{end+1}=destFolderPath;

    if ~exist(destFolderPath, 'dir')
        mkdir(destFolderPath);
    end

    % Copy timelog from Raw Data
    copyfile(fullfile(rawRoot, tlName), fullfile(destFolderPath, tlName));

    % Copy matching EDF from Raw Data
    basePrefix = regexprep(tlName, '_Timelog\.txt$', '');
    edfName    = [basePrefix, '_infant.edf'];
    edfPath    = fullfile(rawRoot, edfName);

    if exist(edfPath, 'file') == 2
        copyfile(edfPath, fullfile(destFolderPath, edfName));
    else
        fprintf('NOTE: EDF not found in Raw Data: %s\n', edfName);
    end

    fprintf('%s\n', destFolderName);
    fprintf('this folder has been created and files copied\n\n');

    % Optional: update map so subsequent runs in same MATLAB session can skip faster
    timelogIndex(lower(tlName)) = {fullfile(destFolderPath, tlName)};

    waitbar(j/N, h, sprintf('Remaining: %3.0f%%', 100*(1-j/N)));
    
end
close(h);
elapsedTime = toc;
fprintf('\n====================\n');
fprintf('Done. Total runtime: %.2f seconds (%.2f minutes)\n', ...
        elapsedTime, elapsedTime/60);
fprintf('====================\n');

end


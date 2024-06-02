function [measureData] = getMeasureData(varargin)
%Read in measurement data. If path does not exist, instead
% directly from the folder.
%
%   INPUT   filepaths: Path of measurement Data (optinal) cell array
%   OUTPUT  measureData struct
% Adapted: Rexer 28.02.22

%% Reading the measurement data
if nargin==1
    filePaths=varargin{1};
else
    filePaths=[];
end

% get current path 
cd0=cd();

%Check for valid file paths
n = length(filePaths);
if n~=0
    for ii = 1:n
        pathExists = isfile(filePaths{ii});
        if pathExists == 0
            [filenames,dataPath] = selectData('DataPath',cd0,'MultiSelect','off');
        end
    end

else
    % select file if there are no preselected
    [filenames, dataPath, ~] = uigetfile( ...
    '.mat', 'Select MAT-files (*.mat)', ...
    cd0, ...
    'MultiSelect', 'on');
    for ii=1:length(filenames)
        filePaths{ii}=[dataPath,'/',filenames{ii}];
    end
end

nFiles = length(filePaths);


%% Reading Data
for ii =1:nFiles
    % Reading the data
    load(filePaths{ii});
    measureData(ii) = measurement_data_struct;
    clear measurement_data_struct
end

%% Reshape
measureData = reshape(measureData, nFiles, 1);

cd(cd0)
end
function value = getFluidProperty(p_ID,p,T,property)
% Lookuptable for substances
% p=6.7*100000;
% T=30+273;
% Extract UUID from PID and determine .h5-File

% if strcmp(property,'thermal_conductivity')||strcmp(property,'isentropic_exponent')
%     p_ID='https://w3id.org/fst/resource/018dba9b-f067-7d3e-8a4d-d60cebd70a8a';
% p_ID='https://w3id.org/fst/resource/1ed6cc2c-da26-661f-92f3-02c4bb63c743'
% end

% Get the directory path of the current file to be able to set a
% path relative to this file.
currentFilePath = mfilename('fullpath');
[fileDirPath, ~, ~] = fileparts(currentFilePath);

cd0=cd();
prt=split(p_ID,'/');
UUID=prt{6};
cd([fileDirPath, '\..\substances\', UUID])
fileNames=dir();
h5filepath=fileNames(3);

if strcmp(property,'specific_gas_constant')
    [temp1, temp2] = retrieveRDFDataset(p_ID, 'config_json_file_path', [fileDirPath, '\..\fst-rdf-utilities\EXAMPLE.config.json']);
    fluid=temp2.(temp1);
    clear temp1 temp2
    value = fluid.hasProperty.specific_gas_constant.value.literal;

else
    p_vec=h5read([h5filepath.folder,'\',h5filepath.name],'/substance/index_vectors/pressures');
    T_vec=h5read([h5filepath.folder,'\',h5filepath.name],'/substance/index_vectors/temperatures');
    % get matrix
    Mat=h5read([h5filepath.folder,'\',h5filepath.name],['/substance/n_dimensional_lookup_tables/',property]);
    value = interp2(T_vec,p_vec,Mat,T,p);
end
cd(cd0)
end
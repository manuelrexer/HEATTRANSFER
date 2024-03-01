function vlaue = getFluidProperty(p_ID,p,T,property)
% Lookuptable for substances
% p=6.7*100000;
% T=30+273;
% Extract UUID from PID and determine .h5-File

prt=split(p_ID,'/');
UUID=prt{6};

filenames=dir(['.\substances\',UUID]);
h5filepath=filenames(3);

p_vec=h5read([h5filepath.folder,'\',h5filepath.name],'/substance/index_vectors/pressures');
T_vec=h5read([h5filepath.folder,'\',h5filepath.name],'/substance/index_vectors/temperatures');
% get matrix
Mat=h5read([h5filepath.folder,'\',h5filepath.name],['/substance/n_dimensional_lookup_tables/',property]);

value = interp2(T_vec,p_vec,Mat,T,p);

end
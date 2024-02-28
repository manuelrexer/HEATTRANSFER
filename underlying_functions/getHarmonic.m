function [outputvalue,outputfrequency] = getHarmonic(value,frequency,omega,n)
% getHarmonic extracts from a frequency vector the harmonics of 0..n
%   Version 1.0 Manuel Rexer 31.01.2022

% index vector
nx=find(abs(frequency-omega)< 0.01*omega);
nx=nx(1)-1;
nmax=length(frequency);
if n+1>nmax/nx
    n=floor(nmax/nx)-1
end
ind = [1:nx:(n+1)*nx];

% extraction
outputfrequency=frequency(ind);
outputvalue=value(ind);


end
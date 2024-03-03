function [Heatflow] = getHeatFFT(volume,pressure,temperature_ambient,testSetup)
%getHeatFFT() Summary of this function goes here
%   Detailed explanation goes here
%
% Input: Volume (in m^3) and pressure (in bar) in Frequency domain
% Structure of in- and output
% variable.value (DFT Coeffitions vector)
% variable.frequency (Frequency vector)
%
% Created Rexer 01.2022

% Calculation of Heat Flow in Frequecy domain
for ii=length(volume):-1:1
    gamma=getFluidProperty(testSetup(ii).fluid_ID,...
        mean(pressure(ii).value)*1e5,mean(temperature_ambient(ii).value)+273.15,'isentropic_exponent');
    [Heatflow(ii).FFT.value,Heatflow(ii).FFT.frequencies] = convfft(...
        gamma*...
        pressure(ii).FFT.value*100000,...
        volume(ii).FFT.value,...
        pressure(ii).FFT.frequencies,...
        volume(ii).FFT.frequencies);
    Heatflow(ii).FFT.value = (1+gamma)/(gamma-1)...
        *1i*2*pi*Heatflow(ii).FFT.value.*Heatflow(ii).FFT.frequencies';
end

end
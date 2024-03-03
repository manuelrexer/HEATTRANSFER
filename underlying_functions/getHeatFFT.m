function [Heatflow] = getHeatFFT(volume,pressure,testSetup)
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
[Heatflow.value,Heatflow.frequency] = convfft(param.gamma.value*Pressure.value*100000,Volume.value,Pressure.frequency,Volume.frequency);
Heatflow.value = (1+param.gamma.value)/(param.gamma.value-1)*1i*2*pi*Heatflow.value.*Heatflow.frequency;
end

end
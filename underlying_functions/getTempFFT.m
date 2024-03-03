function [Temperature,initialMass] = getTempFFT(volume,pressure ,temperature_ambient , testSetup)
%getTempFFT Calculation of Temperature from pressure and Volume Data in
%frequency Domain
%
% Input: Volume (in m^3) and pressure (in bar) in Frequency domain
% Structure of in- and output
% variable.value (DFT Coeffitions vector)
% variable.frequency (Frequency vector)
%
% Created: Rexer 01.2022
for ii=length(volume):-1:1
% Evaluate ambiant Temperature
meanambtemp=mean(temperature_ambient(ii).value)+273.15;
% [temp1,temp2]=retrieveRDFDataset(testSetup(ii).fluid_ID,'config_json_file_path', "C:\Users\rexer\Documents\MATLAB\heattransfer\fst-rdf-utilities\EXAMPLE.config.json");
% gas=temp2.(temp1);
% Evaluate Gas Mass of the system
initialMass(ii).value= testSetup(ii).p0.value * 1e5 * testSetup(ii).V0.value/...
    (getFluidProperty(testSetup(ii).fluid_ID,testSetup(ii).p0.value*1e5,meanambtemp,'specific_gas_constant')*meanambtemp);

% Calculation of Temperature in Frequecy domain
[Temperature(ii).FFT.value,Temperature(ii).FFT.frequency] = convfft(...
    pressure(ii).FFT.value *1e5, volume(ii).FFT.value ,pressure(ii).FFT.frequencies, volume(ii).FFT.frequencies);
    Temperature(ii).FFT.value=Temperature(ii).FFT.value./...
        (initialMass(ii).value*getFluidProperty(testSetup(ii).fluid_ID,...
        mean(pressure(ii).value)*1e5,meanambtemp,'specific_gas_constant'));
%     disp(num2str( Temperature(ii).FFT.value))
end
end

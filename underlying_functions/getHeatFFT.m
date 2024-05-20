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
    [temp1,temp1f] = convfft(...
        pressure(ii).FFT.value*1e5*1i.*pressure(ii).FFT.frequencies,...
        volume(ii).FFT.value,...
        pressure(ii).FFT.frequencies,...
        volume(ii).FFT.frequencies);
      [temp2,temp2f] = convfft(...
        pressure(ii).FFT.value*1e5,...
        volume(ii).FFT.value*1i.*volume(ii).FFT.frequencies,...
        pressure(ii).FFT.frequencies,...
        volume(ii).FFT.frequencies);
    Heatflow(ii).FFT.value = 1/(gamma-1)*temp1+gamma /(gamma-1)*temp2;
    Heatflow(ii).FFT.frequencies=temp1f;

    if isfield(volume(ii).FFT,'harmonic')
        [temp1,temp1f] = convFFTMETAS(...
            pressure(ii).FFT.harmonic.metas*1e5*1i.*2*pi.*pressure(ii).FFT.harmonic.frequencies,...
            volume(ii).FFT.harmonic.metas,...
            pressure(ii).FFT.harmonic.frequencies,...
            volume(ii).FFT.harmonic.frequencies);
        [temp2,temp2f] = convFFTMETAS(...
            pressure(ii).FFT.harmonic.metas*1e5,...
            volume(ii).FFT.harmonic.metas*1i.*2.*pi.*volume(ii).FFT.harmonic.frequencies,...
            pressure(ii).FFT.harmonic.frequencies,...
            volume(ii).FFT.harmonic.frequencies);

         Heatflow(ii).FFT.harmonic.metas =  1/(gamma-1)*temp1 + gamma /(gamma-1)*temp2;
         Heatflow(ii).FFT.harmonic.frequencies = temp1f;
    end
end
% figure('Name','heatflow')
%     tiledlayout("flow","TileSpacing","compact")
%     for ii=length(Heatflow):-1:1
%         nexttile
% 
%         stem(Heatflow(ii).FFT.harmonic.frequencies,abs(Heatflow(ii).FFT.harmonic.metas.Value))
%         hold on
%         stem(Heatflow(ii).FFT.harmonic.frequencies*1.5,abs(Heatflow_test(ii,:)))
%         
%         box off
%         
%     end





end
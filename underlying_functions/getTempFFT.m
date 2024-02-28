function [Temperature,initialMass] = getTempFFT(Volume,Pressure ,AmbientTemperature ,PreloadPressure, Testrig, Gas)
%getTempFFT Calculation of Temperature from pressure and Volume Data in
%frequency Domain
%
% Input: Volume (in m^3) and pressure (in bar) in Frequency domain
% Structure of in- and output
% variable.value (DFT Coeffitions vector)
% variable.frequency (Frequency vector)
%
% Created: Rexer 01.2022

% Evaluate ambiant Temperature
meanambtemp=mean(AmbientTemperatrue)

% Evaluate Gas Mass of the system
initialMass= PreloadPressure.value * 100000 * Testrig.V0.value/...
    (Gas.R.value*meanambtemp);

% Calculation of Temperature in Frequecy domain
[Temperature.value,Temperature.frequency] = convfft(Pressure.value*100000,Volume.value,Pressure.frequency,Volume.frequency);
    Temperature.value=Temperature.value./(initialMass*Param.R.value);
end
function [Nu] = getNusseltFFT(heatflow,temperature,temperature_ambient,pressure,testSetup)
% Determination of Nusselt Number in frequency domain
% Analyzation for each frequency pair.
%
% Input: Heatflow (in W) and temperature (in K) in Frequency domain
% Structure of in- and output
% variable.value (DFT Coeffitions vector)
% variable.frequency (Frequency vector)
%
% Manuel Rexer 08.02.22 Version 1.0


% Check input data
for ii=length(heatflow):-1:1
if length(heatflow(ii).FFT.value)~=length(heatflow(ii).FFT.frequencies) ||...
        length(temperature(ii).FFT.value)~=length(temperature(ii).FFT.frequencies)
    error('Error: in the length of the frequency and value vectors!')
end
if heatflow(ii).FFT.frequencies(1)~=0 || temperature(ii).FFT.frequencies(1)~=0
    error('Error: Frequency does not start at 0!')
end


nheat=length(heatflow(ii).FFT.frequencies);
ntemp=length(temperature(ii).FFT.frequencies);
nNu=min([nheat,ntemp]);

if nheat<ntemp
    Nu(ii).FFT.frequencies = heatflow(ii).FFT.frequencies(1:nNu);
else
    Nu(ii).FFT.frequencies = temperature(ii).FFT.frequencies(1:nNu);
end

%Calculation of temperature difference
% Achtung muss das hier alles im Frequenzraum sein???
% Dann muss auch die Umgebungstemperatur im Frequenzraum vorliegen!!!
DeltaTemperature = - temperature_ambient(ii).FFT.value + temperature(ii).FFT.value;

for jj=1:nNu
    Nu(ii).FFT.value(jj)= heatflow(ii).FFT.value(jj)./DeltaTemperature(jj);
end
lambda = getFluidProperty(testSetup(ii).fluid_ID,...
        mean(pressure(ii).value)*1e5,mean(temperature_ambient(ii).value)+273.15,'thermal_conductivity');
Aw = testSetup(ii).Aw.value;
s = testSetup(ii).Aw.value/testSetup(ii).V1.value;
Nu(ii).FFT.value = Nu(ii).FFT.value./(Aw*s*lambda);

end

end
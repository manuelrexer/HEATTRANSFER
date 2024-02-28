function [Nu] = getNusseltFFT(Heatflow,Temperature,AmbiantTemperatrue,param)
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
if length(Heatflow.value)~=length(Heatflow.frequency) || length(Temperature.value)~=length(Temperature.frequency)
    error('Error: in the length of the frequency and value vectors!')
end
if Heatflow.frequency(1)~=0 || Temperature.frequency(1)~=0
    error('Error: Frequency does not start at 0!')
end


nheat=length(Heatflow.frequency);
ntemp=length(Temperature.frequency);
nNu=min([nheat,ntemp]);

if nheat<ntemp
    Nu.frequency = Heatflow.frequency(1:nNu);
else
    Nu.frequency = Temperature.frequency(1:nNu);
end

%Calculation of temperature differencce
Temperature.value = - AmbiantTemperatrue + Temperature.value;

for ii=1:nNu
    Nu.value(ii)= Heatflow.value(ii)./Temperature.value(ii);
end
Nu.value = Nu.value./(param.Aw.value*param.s.value*param.lambda.value);

end
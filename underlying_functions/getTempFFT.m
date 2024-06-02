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
% Last adaption 05.2024

%% Initiation
unc= @LinProp;
%% Calculation
for ii=length(volume):-1:1
    % Evaluate ambiant Temperature
    meanambtemp=unc(mean(temperature_ambient(ii).value)+273.15,std(temperature_ambient(ii).value));
    % Evaluate Gas Mass of the system
    if isfield(testSetup(ii),'p0')
        p = unc(testSetup(ii).p0.value,testSetup(ii).p0.accuracy);
    else
        p = unc(mean(pressure(ii).value), getSumOfSystematicUnc(pressure(ii).unc));
    end
    V0=unc(testSetup(ii).V0.value,testSetup(ii).V0.accuracy);
    R=unc(getFluidProperty(testSetup(ii).fluid_ID,p*1e5,meanambtemp,'specific_gas_constant'));
    initialMass(ii).metas= p * 1e5 * V0/(R*meanambtemp);
    initialMass(ii).value=initialMass(ii).metas.Value;

    % Calculation of Temperature in Frequecy domain
    [Temperature(ii).FFT.value,Temperature(ii).FFT.frequencies] = convfft(...
        pressure(ii).FFT.value *1e5, volume(ii).FFT.value ,pressure(ii).FFT.frequencies, volume(ii).FFT.frequencies);
    Temperature(ii).FFT.value=Temperature(ii).FFT.value./...
        (initialMass(ii).value*getFluidProperty(testSetup(ii).fluid_ID,...
             mean(pressure(ii).value)*1e5,meanambtemp,'specific_gas_constant'));
    Temperature(ii).FFT.value=Temperature(ii).FFT.value(1:length(volume(ii).FFT.value));
    Temperature(ii).FFT.frequencies=Temperature(ii).FFT.frequencies(1:length(volume(ii).FFT.value));
    
    % same calculation for harmonics with metas
    if isfield(volume(ii).FFT,'harmonic')
        [Temperature(ii).FFT.harmonic.metas,Temperature(ii).FFT.harmonic.frequencies] = convFFTMETAS(...
            pressure(ii).FFT.harmonic.metas *1e5, volume(ii).FFT.harmonic.metas ,...
            pressure(ii).FFT.harmonic.frequencies, volume(ii).FFT.harmonic.frequencies);

        Temperature(ii).FFT.harmonic.metas=Temperature(ii).FFT.harmonic.metas/...
            (initialMass(ii).metas*R);

        Temperature(ii).FFT.harmonic.metas=Temperature(ii).FFT.harmonic.metas(1:length(volume(ii).FFT.harmonic.value));
        Temperature(ii).FFT.harmonic.frequencies=Temperature(ii).FFT.frequencies(1:length(volume(ii).FFT.harmonic.value));
    end
end
end

function delta=getSumOfSystematicUnc (unc)

fields=fieldnames(unc);
delta=0;
for ii=length(fields):-1:1
    if ~isnumeric(unc.(fields{ii}))
        unc.(fields{ii})=0;
    end
    if ~strcmpi(fields{ii},'sensitivity')
        delta=delta+unc.(fields{ii});
    end
end
delta=sqrt(delta);

end

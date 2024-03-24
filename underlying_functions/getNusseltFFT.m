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
% +(temperature_ambient(ii).FFT.value) 
    DeltaTemperature =  - temperature(ii).FFT.value;
    DeltaTemperature(1)=0;

    lambda = getFluidProperty(testSetup(ii).fluid_ID,...
        mean(pressure(ii).value)*1e5,mean(temperature_ambient(ii).value)+273.15,'thermal_conductivity');
    Aw = testSetup(ii).Aw.value;
    s = testSetup(ii).Aw.value/testSetup(ii).V1.value;
    const=Aw*s*lambda;

    Nu(ii).FFT.value(1)=heatflow(ii).FFT.value(2)/DeltaTemperature(2)/const;
    Nu(ii).FFT.value(2)=(heatflow(ii).FFT.value(3)-DeltaTemperature(3)*Nu(ii).FFT.value(1))...
        /DeltaTemperature(2)/const;

%     Nu(ii).FFT.value(2)=(heatflow(ii).FFT.value(3))/DeltaTemperature(2)/const;

    if isfield(heatflow(ii).FFT,'harmonic')
        clear DeltaTemperature const
        unc=@LinProp;
        lambda = unc(getFluidProperty(testSetup(ii).fluid_ID,...
            mean(pressure(ii).value)*1e5,mean(temperature_ambient(ii).value)+273.15,'thermal_conductivity'));
        Aw = unc(testSetup(ii).Aw.value,testSetup(ii).Aw.accuracy);
        s = Aw/unc(testSetup(ii).V1.value,testSetup(ii).V1.accuracy);
        const=Aw*s*lambda;
        DeltaTemperatureharm =  - temperature(ii).FFT.harmonic.metas;
        DeltaTemperatureharm(1)=0;
        Nu(ii).FFT.metas(1)=heatflow(ii).FFT.harmonic.metas(2)/DeltaTemperatureharm(2)/const;
        
%         Nu(ii).FFT.metas(2)=(heatflow(ii).FFT.harmonic.metas(3)-DeltaTemperature(3)*Nu(ii).FFT.metas(1))/...
%             DeltaTemperature(2)/const;
        Nu(ii).FFT.metas(2)=(heatflow(ii).FFT.harmonic.metas(3))/DeltaTemperatureharm(2)/const;

% Nu(ii).FFT.metas=conj(Nu(ii).FFT.metas);

    end


    % for jj=1:nNu
    %     Nu(ii).FFT.value(jj)= heatflow(ii).FFT.value(jj)./DeltaTemperature(jj);
    % end
    %
    %
    %
    % lambda = getFluidProperty(testSetup(ii).fluid_ID,...
    %         mean(pressure(ii).value)*1e5,mean(temperature_ambient(ii).value)+273.15,'thermal_conductivity');
    % Aw = testSetup(ii).Aw.value;
    % s = testSetup(ii).Aw.value/testSetup(ii).V1.value;
    % Nu(ii).FFT.value = Nu(ii).FFT.value./(Aw*s*lambda);

end

end
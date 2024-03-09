function [volume,testSetup] = addVolumeData(deflection,pressure, testSetup)
% addVolume(measureData, param ,input) returns the volume signal vector for
% all MeasureData in m^3
% Input:    measureData, param ,input
% Output:   measureData, param, input
% area: in m^2
unc=@LinProp;

for ii=length(deflection):-1:1;
    % Calculation of Delta V form deflection in [m^3]
    % Check for Units
    if strcmpi(deflection(ii).unit,'MM')||strcmpi(deflection(ii).unit,'MILLIM')
        fact=1e-3;
    elseif strcmpi(deflection(ii).unit,'M')
        fact=1;
    else
        fact=1;
        disp('Attention: Unknwon Unit of deflection Vector')
    end
    %
    DeltaV.value = ((deflection(ii).value)*fact*...
        testSetup(ii).Ad.value);                 %[m * m^2] = [m^3]
    DeltaV.unit = 'M3';
    % DeltaV.unc.Accuracy = tbd
    % Calculation of Load volume

    if isfield(testSetup, 'V1')
        if ~isempty(testSetup(ii).V1)
            V1 = unc(testSetup(ii).V1.value,testSetup(ii).V1.accuracy);
            V1flag= false;
        else
            V1flag=true;
        end
    else
        V1flag=true;
    end

    if V1flag
        p0=unc(testSetup(ii).p0.value*1e5,testSetup(ii).p0.accuracy*1e5);
        V0=unc(testSetup(ii).V0.value,testSetup(ii).V0.accuracy);
        p1=unc(mean(pressure(ii).value*1e5),std(pressure(ii).value*1e5));
        % todo systematische Unsicherheit hinzufügen standardabweichung macht
        % absolut keinen Sinn das muss hier noch rausgenommen werden.
        V1 = p0*V0/p1;            %[Pa*m^3/Pa] = [m^3]

        testSetup(ii).V1.value = V1.Value;
        testSetup(ii).V1.accuracy = V1.StdUnc;
        testSetup(ii).V1.metas = V1;
        testSetup(ii).V1.unit = 'M3';
        testSetup(ii).V1.name = 'load volume';

    end
% V1.Value=
    % Calculation of Volume
    vol.value = V1.Value + DeltaV.value; %[m^3 + m^3]
    vol.accuracy = [];
    vol.unit = 'M3';
    volume(ii) = vol;
end


end
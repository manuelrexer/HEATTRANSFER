function [volume,testSetup] = addVolumeData(deflection,pressure, testSetup)
% addVolume(measureData, param ,input) returns the volume signal vector for
% all MeasureData in m^3
% Input:    measureData, param ,input
% Output:   measureData, param, input
% area: in m^2
unc=@LinProp;

for ii=length(deflection):-1:1
    % Calculation of Delta V form deflection in [m^3]
    % Check for Units
    if strcmpi(deflection(ii).unit,'MM')||strcmpi(deflection(ii).unit,'MILLIM')
        fact=1e-3;
    elseif strcmpi(deflection(ii).unit,'M')
        fact=1;
    else
        fact=1;
        warning('Unknwon unit of deflection vector')
    end
    %
    DeltaV.value = ((deflection(ii).value)*fact*...
        testSetup(ii).Ad.value);                 %[m * m^2] = [m^3]
    DeltaV.unit = 'M3';
    


    % Getting load volume
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
        p0=unc(testSetup(ii).p0.value*1e5,testSetup(ii).p0.accuracy*1e5/sqrt(3));
        V0=unc(testSetup(ii).V0.value,testSetup(ii).V0.accuracy/sqrt(3));
        
        p1=unc(mean(pressure(ii).value*1e5), getSumOfSystematicUnc(pressure(ii).unc,mean(pressure(ii).value*1e5))/sqrt(3));
        % ToDo: Include statistic Uncertainty    
        
        V1 = p0*V0/p1;            %[Pa*m^3/Pa] = [m^3]

        testSetup(ii).V1.value = V1.Value;
        testSetup(ii).V1.accuracy = V1.StdUnc*sqrt(3);
        testSetup(ii).V1.metas = V1;
        testSetup(ii).V1.unit = 'M3';
        testSetup(ii).V1.name = 'load volume';

    end
    


    % Calculation of acutal Volume
    vol.value = V1.Value + DeltaV.value; %[m^3 + m^3]
    
    % Mapping of systematic uncertainty
    vol.unc.bias = (deflection(ii).unc.bias * fact * abs(testSetup(ii).Ad.value))  +  testSetup(ii).V1.accuracy ;
    vol.unc.sensitivity = deflection(ii).unc.sensitivity + ...
        (testSetup(ii).Ad.accuracy / abs(testSetup(ii).Ad.value));
    vol.unc.linearity = deflection(ii).unc.linearity * fact * abs(testSetup(ii).Ad.value);
    vol.unc.hysteresis = deflection(ii).unc.hysteresis  * fact * abs(testSetup(ii).Ad.value);
    
    vol.unit = 'M3';
    volume(ii) = vol;
end


end
% figure()
% plot((deflection(ii).unc.sensitivity .* abs(deflection(ii).value) *fact * abs(testSetup(ii).Ad.value) + ...
%         testSetup(ii).Ad.accuracy * (abs(deflection(ii).value))*fact))
% plot(volume(ii).value)

function delta=getSumOfSystematicUnc (unc,mean)

fields=fieldnames(unc);
delta=0;
for ii=length(fields):-1:1
    if ~isnumeric(unc.(fields{ii}))
        unc.(fields{ii})=0;
    end
    if ~strcmpi(fields{ii},'sensitivity')
    delta=delta+unc.(fields{ii})^2;
    elseif strcmpi(fields{ii},'sensitivity')
        delta=delta+(unc.(fields{ii})*mean)^2;
    end
end
delta=sqrt(delta);

end

function [dataStruct] = extractMeasurements(measureData,dataField)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here
for ii=length(measureData):-1:1
    run=measureData(ii).(dataField);
    % collect measured data and their metadata
    data.quantity = run.physical_quantity_name;
    data.name = dataField;
    data.value = run.value;
    data.unit = run.unit;

    %read sensor data
    data.p_ID_Sensor=run.sensor_data.p_ID.URI;
    [temp1, temp2] = retrieveRDFDataset(data.p_ID_Sensor, 'config_json_file_path', "C:\Users\rexer\Documents\MATLAB\heattransfer\fst-rdf-utilities\EXAMPLE.config.json");
    sensor=temp2.(temp1);
    clear temp1 temp2
    data.sensor=sensor;


    % extract uncertainty values
    data.unc.bias = getUncValues(data,sensor,'Bias.hasProperty.BiasUncertainty',run);
    data.unc.sensitivity =getUncValues(data,sensor,'Sensitivity.hasProperty.SensitivityUncertainty',run);
    data.unc.linearity = getUncValues(data,sensor,'LinearityUncertainty',run);
    data.unc.hysteresis = getUncValues(data,sensor,'HysteresisUncertainty',run);


    % map data
    dataStruct(ii)=data;
    clear data
end

end

function res = getUncValues(data,sensor,uncfield,run)
try
    if contains(getValueInsideNestedStructWithPath(sensor,...
            ['hasSystemCapability.SensorCapability.hasProperty.',uncfield,'.keywords.literal']),'absolute')

        res = getValueInsideNestedStructWithPath(sensor,...
            ['hasSystemCapability.SensorCapability.hasProperty.',uncfield,'.value.literal']);
        % check if units are the same
        if all(contains(fieldnames(getValueInsideNestedStructWithPath(sensor,...
                ['hasSystemCapability.SensorCapability.hasProperty.',uncfield,'.unit'])),data.unit))
            warning('Units of uncertatnity Value and Measured Values are not machting!!!')
        end


        % check if the systematic uncertainty is a sensitivity uncertatinty
        % and if the value only depend on the Measurement value (MV)
    elseif strcmpi(getValueInsideNestedStructWithPath(sensor,...
            ['hasSystemCapability.SensorCapability.hasProperty.',uncfield,'.keywords.literal']),...
            'relative_MV') && contains(uncfield,'sensitivity','IgnoreCase',true)

        res = getValueInsideNestedStructWithPath(sensor,...
            ['hasSystemCapability.SensorCapability.hasProperty.',uncfield,'.value.literal']);
    elseif strcmpi(getValueInsideNestedStructWithPath(sensor,...
            ['hasSystemCapability.SensorCapability.hasProperty.',uncfield,'.keywords.literal']),...
            'relative_MV') && ~contains(uncfield,'sensitivity','IgnoreCase',true)

        res = getValueInsideNestedStructWithPath(sensor,...
            ['hasSystemCapability.SensorCapability.hasProperty.',uncfield,'.value.literal'])*...
            max(abs(run.value))/100;
        % TODO: Check if unit is %!!
    else
        % tbd
        warning('this uncertainty type is currently not supported.')
        res= 0;
    end
catch
    warning(['The the following uncertainty information is not given for this sensor: ',uncfield]);
    res = 0;
end
end

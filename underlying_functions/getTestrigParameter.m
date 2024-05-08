function setupParameter=getTestrigParameter(measureData)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


for ii=length(measureData):-1:1
    testobject_ID={};
    fluid_ID={};
    hardwaresetup=fieldnames(measureData(ii).METADATA.hardware);
    % determine test objects
    acc_setup=false;
    for jj=length(hardwaresetup):-1:1
        objtypes{jj}=measureData(ii).METADATA.hardware.(hardwaresetup{jj}).type;
        if strcmpi(objtypes{jj},"TestObject")
            testobject_ID{end+1}=measureData(ii).METADATA.hardware.(hardwaresetup{jj}).p_ID;
            fluid_ID{end+1}=measureData(ii).METADATA.hardware.(hardwaresetup{jj}).fluid.p_ID;
        end
        if hardwaresetup{jj}=="accumulator_testrig"
            acc_setup=true;
            acctestrig_IND=jj;
        end

    end
    % get test object data
    if length(testobject_ID)==1
        [temp1, temp2] = retrieveRDFDataset(testobject_ID{1}, 'config_json_file_path', "C:\Users\rexer\Documents\MATLAB\heattransfer\fst-rdf-utilities\EXAMPLE.config.json");
        testobject=temp2.(temp1);
        clear temp1 temp2
        importantParameter.testobject=testobject;
    else
        error('There are more then one objects of interests. This is not implemented yet.')
    end
    % if we use the accumulator testrig
    if acc_setup
        %         testrig_ID='https://w3id.org/fst/resource/018bb4b1-db4a-7bbd-a299-ee3b49b5d7f5';
        testrig_ID=measureData(ii).METADATA.hardware.(hardwaresetup{acctestrig_IND}).p_ID;
        [temp1, temp2] = retrieveRDFDataset(testrig_ID, 'config_json_file_path', "C:\Users\rexer\Documents\MATLAB\heattransfer\fst-rdf-utilities\EXAMPLE.config.json");
        testrig=temp2.(temp1);
        importantParameter.testrig=testrig;
        clear temp1 temp2
        importantParameter.V0 = simplyfyPropertyStruct(testobject.hasProperty.V0);
        
        if strcmp(importantParameter.V0.unit,'L')
            importantParameter.V0.value = importantParameter.V0.value/1000;
            importantParameter.V0.accuracy = importantParameter.V0.accuracy/1000;
            importantParameter.V0.unit = 'M3';
        end      

        importantParameter.Aw.value = 4*pi*(3/4/pi*importantParameter.V0.value)^(2/3);
        importantParameter.Aw.accuracy =abs(2/3*(3/4/pi)^(2/3)*(importantParameter.V0.value)^(-1/3)* importantParameter.V0.accuracy);
        importantParameter.Aw.unit='M2';
        importantParameter.Aw.symbol='A_w';
        importantParameter.Ad = simplyfyPropertyStruct(testrig.hasProperty.A_d);
        importantParameter.p0.value = measureData(ii).model_PARAMETERS.important_parameters_struct.cylinder.preload_pressure.value;
        importantParameter.p0.unit = 'BAR';
        importantParameter.p0.accuracy = 0.04;
        
        switch importantParameter.V0.value
            case 600e-6
                importantParameter.V0.value = importantParameter.V0.value - 16.e-6;
            case 100e-6
                importantParameter.V0.value = importantParameter.V0.value - 3e-6;
            case 1300e-6
                importantParameter.V0.value = importantParameter.V0.value - 50e-6;
        end
    else
        %all other testrigs
        importantParameter.V0 = simplyfyPropertyStruct(testobject.hasProperty.V0);
        if strcmp(importantParameter.V0.unit,'L')
            importantParameter.V0.value=importantParameter.V0.value/1000;
            importantParameter.V0.accuracy=importantParameter.V0.Accuracy/1000;
            importantParameter.V0.unit='M3';
        end
        if isfield(testobject.hasProperty,'V1')
            importantParameter.V1 = simplyfyPropertyStruct(testobject.hasProperty.V1);
            if strcmpi(testobject.label.literal,'air spring')
                importantParameter.V1.value =1*(importantParameter.V1.value + 70*1e-6);
                importantParameter.V0.value =1*(importantParameter.V0.value + 70*1e-6);
            end
            if strcmpi(testobject.label.literal,'gas cylinder')
                importantParameter.V1.value =importantParameter.V1.value + 8*1e-6;
                importantParameter.V0.value =importantParameter.V0.value + 8*1e-6;
            end
        end
        importantParameter.Ad = simplyfyPropertyStruct(testobject.hasProperty.A_d);
        importantParameter.Aw = simplyfyPropertyStruct(testobject.hasProperty.A_w);
        
    end


    f = fieldnames(importantParameter);
    for jj = 1:length(f)
        setupParameter(ii).(f{jj}) = importantParameter.(f{jj});
    end


    setupParameter(ii).fluid_ID= fluid_ID{1};
    clear importantParameter f
end

end

function [simple] = simplyfyPropertyStruct(input)
%implyfyPropertyStruct extracts important information from RDF Data
%structure
%   Author Manuel Rexer 01.03.2024
simple.value = input.value.literal;
unit=fieldnames(input.unit);
for ii=1:length(unit)
    if strcmp(unit{ii}, 'prefix')
        unit{ii}=[];
    end
end
unit=unit(~cellfun('isempty',unit));
if length(unit)==1
    simple.unit = unit{1};
else
    simple.unit = unit;
end
simple.accuracy = input.Accuracy.literal;
simple.symbol = input.symbol.literal;
end
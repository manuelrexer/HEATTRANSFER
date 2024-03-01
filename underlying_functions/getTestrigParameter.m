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
        if objtypes{jj}=="TestObject"||objtypes{jj}=="testObject" ||objtypes{jj}=="Testobject"||objtypes{jj}=="testobject"
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
        setupParameter(ii).testobject=testobject;
    else
        error('There are more then one objects of interests. This is not implemented yet.')
    end
    % if we use the accumulator testrig
    if acc_setup
%         testrig_ID='https://w3id.org/fst/resource/018bb4b1-db4a-7bbd-a299-ee3b49b5d7f5';
        testrig_ID=measureData(ii).METADATA.hardware.(hardwaresetup{acctestrig_IND}).p_ID;
        [temp1, temp2] = retrieveRDFDataset(testrig_ID, 'config_json_file_path', "C:\Users\rexer\Documents\MATLAB\heattransfer\fst-rdf-utilities\EXAMPLE.config.json");
        testrig=temp2.(temp1);
        setupParameter(ii).testrig=testrig;
        clear temp1 temp2
        importantParameter.V0 = simplyfyPropertyStruct(testobject.hasProperty.V0);
        if strcmp(importantParameter.V0.unit,'L')
            importantParameter.V0.value=importantParameter.V0.value/1000;
            importantParameter.V0.Accuracy=importantParameter.V0.Accuracy/1000;
            importantParameter.V0.unit='M3';
        end
        importantParameter.A_w.value = 4*pi*(3/4/pi*importantParameter.V0.value)^(2/3);
        importantParameter.A_w.Accuracy =abs(2/3*(3/4/pi)^(2/3)*(importantParameter.V0.value)^(-1/3)* importantParameter.V0.Accuracy);
        importantParameter.A_w.unit='M2';
        importantParameter.A_w.symbol='A_w';
        importantParameter.A_d = simplyfyPropertyStruct(testrig.hasProperty.A_d);
    else
    %all other testrigs
        importantParameter.V0 = simplyfyPropertyStruct(testobject.hasProperty.V0);
        if strcmp(importantParameter.V0.unit,'L')
            importantParameter.V0.value=importantParameter.V0.value/1000;
            importantParameter.V0.Accuracy=importantParameter.V0.Accuracy/1000;
            importantParameter.V0.unit='M3';
        end
        importantParameter.A_d = simplyfyPropertyStruct(testobject.hasProperty.A_d);
        importantParameter.A_w = simplyfyPropertyStruct(testobject.hasProperty.A_w);
    end

%     setupParameter(ii)=combineStructs(setupParameter(ii),importantParameter);
    setupParameter(ii).V0=importantParameter.V0;
    setupParameter(ii).Aw=importantParameter.A_w;
    setupParameter(ii).Ad=importantParameter.A_d;
    setupParameter(ii).fluid_ID= fluid_ID{1};
clear importantParameter
end

end
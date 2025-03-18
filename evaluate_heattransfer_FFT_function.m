function [data, plotopts, testObj] = evaluate_heattransfer_FFT_function(measureData)
    
    unc = @LinProp;

    % number of orders to bee evaluated (first order is neccesary)
    neval=1;

    % reading parameter
    testSetup=getTestrigParameter(measureData);
    
    %% Select data for analyzation
    % defelction Data
    if isfield(measureData, 'current_deflection')
        fieldname.deflection={'current_deflection'};
    elseif isfield(measureData, 'deflection')
        fieldname.deflection={'deflection'};
    else
        fieldname.deflection=getSelectedFields(measureData, 'Select defelction field');
    end
    deflection = extractMeasurements(measureData, fieldname.deflection{1});
    
    % pressure Data
    if isfield(measureData, 'pressure_gas')
        fieldname.pressure = {'pressure_gas'};
    else
        fieldname.pressure = getSelectedFields(measureData, 'select pressure:');
    end
    pressure = extractMeasurements(measureData, fieldname.pressure{1});
    
    % temperature Data
    if isfield(measureData, 'temperature_gas')
        fieldname.temperature = {'temperature_gas'};
    elseif isfield(measureData, 'gas_temperature')
        fieldname.temperature = {'gas_temperature'};
    else
        fieldname.temperature = getSelectedFields(measureData, 'select temperature');
    end
    temperature = extractMeasurements(measureData, fieldname.temperature{1});
    
    % ambient temperature data
    if isfield(measureData, 'temperature_ambient')
        fieldname.temperature_ambient={'temperature_ambient'};
    elseif isfield(measureData, 'ambient_temperature')
        fieldname.temperature_ambient={'ambient_temperature'};
    else
        fieldname.temperature_ambient=getSelectedFields(measureData, 'select ambient temperature ');
    end
    temperature_ambient = extractMeasurements(measureData, fieldname.temperature_ambient{1});
    
    % time data
    if isfield(measureData, 'measurement_TIME_VECTOR')
        fieldname.time={'measurement_TIME_VECTOR'};
    else
        fieldname.time=getSelectedFields(measureData, 'select time');
    end
    for ii=length(measureData):-1:1
        time(ii).value = measureData(ii).(fieldname.time{1}).value;
        time(ii).name = 'time';
        time(ii).variable = 't';
    end
    % extract sampletime
    sampletime = measureData(1).model_PARAMETERS.all_parameters_array(1).value;
    
    % Add volume in m�
    [volume, testSetup] = addVolumeData(deflection, pressure, testSetup);
    
    %% Evaluate measurement data
    % DFT of pressure and Volume including uncertainty propagation into
    % frequency domain
    for ii=length(measureData):-1:1
        excitationFrequency(ii) = measureData(ii).model_PARAMETERS.important_parameters_struct.excitation.frequency.value;
        % volume
        volume(ii).FFT = propagateSysUncToFreqDomain...
            (volume(ii).value-mean(volume(ii).value), time(ii).value, sampletime,...
            'excitation_frequency', excitationFrequency(ii), ...
            'bias', volume(ii).unc.bias,...
            'sensitivity', volume(ii).unc.sensitivity,...
            'linearity', volume(ii).unc.linearity,...
            'hysteresis', volume(ii).unc.hysteresis);
        volume(ii).FFT.value(1)=mean(volume(ii).value);
        % pressure
        pressure(ii).FFT = propagateSysUncToFreqDomain...
            (pressure(ii).value, time(ii).value, sampletime,...
            'excitation_frequency', excitationFrequency(ii), ...
            'bias', pressure(ii).unc.bias,...
            'sensitivity', pressure(ii).unc.sensitivity,...
            'linearity', pressure(ii).unc.linearity,...
            'hysteresis', pressure(ii).unc.hysteresis);
        % temperature
        temperature(ii).FFT = propagateSysUncToFreqDomain...
            ((temperature(ii).value+273.15), time(ii).value, sampletime,...
            'excitation_frequency', excitationFrequency(ii),...
            'bias', temperature(ii).unc.bias,...
            'sensitivity', temperature(ii).unc.sensitivity,...
            'linearity', temperature(ii).unc.linearity,...
            'hysteresis', temperature(ii).unc.hysteresis);
        % ambient temperature
        temperature_ambient(ii).FFT = propagateSysUncToFreqDomain...
            ((temperature_ambient(ii).value+273.15), time(ii).value, sampletime,...
            'excitation_frequency', excitationFrequency(ii),...
            'bias', temperature_ambient(ii).unc.bias,...
            'sensitivity', temperature_ambient(ii).unc.sensitivity,...
            'linearity', temperature_ambient(ii).unc.linearity,...
            'hysteresis', temperature_ambient(ii).unc.hysteresis);
    end
    
    
    % Adapt deadtime of keller pressure sensor
    for ii=length(pressure):-1:1
        % Adapt Gas Zylinder Sensor Deadtime 2ms
        if strcmpi(testSetup(ii).testobject.label.literal, 'gas cylinder')
            if strcmpi(pressure(ii).sensor.prefix, 'https://w3id.org/fst/resource//0184ebd9-988b-7bba-83a5-01cec15c9820')
                pressure(ii).FFT.value = pressure(ii).FFT.value.*exp(1i*2*pi*pressure(ii).FFT.frequencies*2e-3);
            end
            % Adapt Accumulator Sensor Deadtime 1ms
        elseif strcmpi(testSetup(ii).testobject.label.literal,'hydraulic accumulator')
            if strcmpi(pressure(ii).sensor.prefix,'https://w3id.org/fst/resource//0184ebd9-988b-7bba-8310-d3fc5137ddf6')
                pressure(ii).FFT.value = pressure(ii).FFT.value.*exp(-1i*2*pi*pressure(ii).FFT.frequencies*1e-3);
            end
        end
    end
    
    % Set Volume signal to zero phase dirfference and turn all other pointers
    % equivalent only necessary for ploting data
    for ii=length(measureData):-1:1
        [~,closestind(ii)]=min(abs(volume(ii).FFT.frequencies - volume(ii).FFT.excitation_frequency));
    
        %     phase0=angle(volume(ii).FFT.value(closestind(ii)));
        %     volume(ii).FFT.value(2:end)=turnComplex(volume(ii).FFT.value(2:end),-phase0);
        %     pressure(ii).FFT.value(2:end)=turnComplex(pressure(ii).FFT.value(2:end),-phase0);
        %     temperature(ii).FFT.value(2:end)=turnComplex(temperature(ii).FFT.value(2:end),-phase0);
        %     temperature_ambient(ii).FFT.value(2:end)=turnComplex(temperature_ambient(ii).FFT.value(2:end),-phase0);
        %
        %     clear phase0
    end
    
    
    % Evaluation Method
    
    % extract the relevant frequencies and add uncertainty to all relevant
    % values
    volume = getHarmonicWithUnc(volume, excitationFrequency, neval);
    pressure = getHarmonicWithUnc(pressure, excitationFrequency, neval);
    temperature = getHarmonicWithUnc(temperature, excitationFrequency, neval);
    temperature_ambient = getHarmonicWithUnc(temperature_ambient, excitationFrequency, neval);
    
    % Determination of temperature from pressure and Volume Data
    [temperature_pv, mass] = getTempFFT(volume, pressure , temperature_ambient , testSetup);
    % Determination of Heatflow from pressure and Volume Data
    heatflow = getHeatFFT(volume, pressure, temperature_ambient, testSetup);
    % Determination of Nuselt Number from Heatflow and Temperature Data
    Nu = getNusseltFFT(heatflow, temperature, temperature_ambient, pressure, testSetup);
    Nu_pv = getNusseltFFT(heatflow, temperature_pv, temperature_ambient, pressure, testSetup);
    
    
    % Some adaptions for plots
    for ii = length(Nu):-1:1
        % Determination of nusselt Number for each frequency // Sort for
        % plots
        for jj = 1:length(Nu(ii).FFT.value)
            plotNu(jj).res(ii) = Nu(ii).FFT.metas(jj);
            plotNu_pv(jj).res(ii) = Nu_pv(ii).FFT.metas(jj);
        end
    
        % Add Peclet number for comparison
        % Pe = 2pif*c_p*rho/(lambda*(A/V)^2)
        Pe(ii) = 2*pi*excitationFrequency(ii)*mass(ii).value*...
            getFluidProperty(testSetup(ii).fluid_ID,...
            mean(pressure(ii).value)*1e5,mean(temperature_ambient(ii).value)+273.15, 'c_p')/...
            (testSetup(ii).V1.value* ...
            getFluidProperty(testSetup(ii).fluid_ID,...
            mean(pressure(ii).value)*1e5,mean(temperature_ambient(ii).value)+273.15, 'thermal_conductivity')* ...
            (testSetup(ii).Aw.value/testSetup(ii).V1.value)^2);
    end
    
    %% Analysing stiffness
    for ii=length(pressure):-1:1
        plotVolume(ii) = volume(ii).FFT.harmonic.metas(2);
        plotPressure(ii) = pressure(ii).FFT.harmonic.metas(2);
       stiffness(ii) = - pressure(ii).FFT.harmonic.metas(2)/...
            volume(ii).FFT.harmonic.metas(2);
    
        V1 = unc(testSetup(ii).V1.value, testSetup(ii).V1.accuracy);
        stiffness_dimless(ii) = stiffness(ii) * ...
            volume(ii).FFT.harmonic.metas(1)/...
            pressure(ii).FFT.harmonic.metas(1);
    
    
        % get isentropic exponent
        gamma(ii) = getFluidProperty(testSetup(ii).fluid_ID,...
            mean(pressure(ii).value)*1e5, mean(temperature_ambient(ii).value)+273.15,'isentropic_exponent');
    
        % Models with complex Nusselt number
        Nusselt_Lee(ii) = sqrt(Pe(ii)/2).*((1+1i).*tanh(((1+1i).*sqrt(Pe(ii)/2))))./(1-tanh(((1+1i).*sqrt(Pe(ii)/2)))./((1+1i).*sqrt(Pe(ii)/2)));
        Nusselt_fit(ii) = 5.3221+1.1829*Pe(ii).^(0.5)+3.4594e-5*Pe(ii).^(1.8) + 1i*0.23197*Pe(ii).^(0.87616);
        stiffness_dimless_Lee(ii) = (1i*gamma(ii)*Nusselt_Lee(ii)/Pe(ii)- gamma(ii))/...
            (1i*gamma(ii)*Nusselt_Lee(ii)/Pe(ii)-1);
        stiffness_dimless_fit(ii) = (1i*gamma(ii)*Nusselt_fit(ii)/Pe(ii)- gamma(ii))/...
            (1i*gamma(ii)*Nusselt_fit(ii)/Pe(ii)-1);
        stiffness_dimless_Pelz(ii) = (1i*gamma(ii)*3/Pe(ii)- gamma(ii))/...
            (1i*gamma(ii)*3/Pe(ii)-1);
    end
    clear ii
    
    % get test stetups for marker settings
    switch testSetup(2).testobject.prefix
        case 'https://w3id.org/fst/resource//018bfcec-5049-7d0d-8ff2-9c53de333a8b'
            %accumulator 1,3l
            plotopts={'o','Markersize',5};
            testObj= 'Accumulator_1.3l';
        case 'https://w3id.org/fst/resource//018bfcec-504b-7ec8-9530-a42b1857e17c'
            %accumulator 0.6l
            plotopts={'o','Markersize',4};
            testObj= 'Accumulator_0.6l';
        case 'https://w3id.org/fst/resource//018bfcec-504e-733a-a819-e5c331404a73'
            %accumulator 0.1l
            plotopts={'o','Markersize',3};
            testObj= 'Accumulator_0.1l';
        case 'https://w3id.org/fst/resource//1ed6c2f8-282a-64b4-94d0-4ee51dfba10e'
            %airspring
            plotopts={'d'};
            testObj= 'airspring';
        case 'https://w3id.org/fst/resource//018bb4b1-db48-73b8-9d82-8a8ffb6ee225'
            %cylinder
            plotopts={'s'};
            testObj= 'cylinder';
        otherwise
            plotopts={'-'};
            testObj= '';
    end

    % Set the vraibles that should get returned
    data.pressure = pressure;
    data.volume = volume;
    data.excitationFrequency = excitationFrequency;
    data.plotNu_pv = plotNu_pv;
    data.gamma = gamma;
    data.Pe = Pe;
    data.stiffness = stiffness;
    data.stiffness_dimless = stiffness_dimless;
    data.stiffness_dimless_fit = stiffness_dimless_fit;
    data.stiffness_dimless_Lee = stiffness_dimless_Pelz;
    data.stiffness_dimless_Pelz = stiffness_dimless_Pelz;
end
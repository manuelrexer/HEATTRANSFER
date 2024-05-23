% code_230223_evaluate_heattransfer_FFT
% Code that determines the complex Nusselt number in the frequency domain
% from measurement data and  plot it afterwards
%
% created: Rexer 28.02.22
% last changes: 20.05.24
% Version: Disseration v1.0.1

%% clear workspace
clc
clearvars -except fig_Nu fig_NuPe fig_stiffness fig_stiffness_dimless fig_ReIm
unc = @LinProp;

%% Options and Preperation
% number of orders to bee evaluated (first order is neccesary)
neval=1;
% current directory
cd0=cd();
%% Reading the measurement data
try
    cd()
    measureData = getMeasureData();
    cd(cd0)
catch
    cd(cd0)
end
% select a run from the Dataset
runs=getMeasurementRuns(measureData);
selectedruns=selectRuns(runs);
% reading parameter
testSetup=getTestrigParameter(measureData);

%% Select data for analyzation

% defelction Data
if isfield(measureData, 'current_deflection')
    fieldname.deflection={'current_deflection'};
elseif isfield(measureData, 'deflection')
    fieldname.deflection={'deflection'};
else
    fieldname.deflection=getSelectedFields(measureData,'Select defelction field');
end
deflection=extractMeasurements(measureData,fieldname.deflection{1});

% pressure Data
if isfield(measureData, 'pressure_gas')
    fieldname.pressure={'pressure_gas'};
else
    fieldname.pressure=getSelectedFields(measureData, 'select pressure:');
end
pressure=extractMeasurements(measureData,fieldname.pressure{1});

% temperature Data
if isfield(measureData, 'temperature_gas')
    fieldname.temperature={'temperature_gas'};
elseif isfield(measureData, 'gas_temperature')
    fieldname.temperature={'gas_temperature'};
else
    fieldname.temperature=getSelectedFields(measureData, 'select temperature');
end
temperature=extractMeasurements(measureData,fieldname.temperature{1});

% ambient temperature data
if isfield(measureData, 'temperature_ambient')
    fieldname.temperature_ambient={'temperature_ambient'};
elseif isfield(measureData, 'ambient_temperature')
    fieldname.temperature_ambient={'ambient_temperature'};
else
    fieldname.temperature_ambient=getSelectedFields(measureData, 'select ambient temperature ');
end
temperature_ambient=extractMeasurements(measureData,fieldname.temperature_ambient{1});

% time data
if isfield(measureData, 'measurement_TIME_VECTOR')
    fieldname.time={'measurement_TIME_VECTOR'};
else
    fieldname.time=getSelectedFields(measureData, 'select time');
end
for ii=length(measureData):-1:1
    time(ii).value=measureData(ii).(fieldname.time{1}).value;
    time(ii).name='time';
    time(ii).variable='t';
end
% extract sampletime
sampletime = measureData(1).model_PARAMETERS.all_parameters_array(1).value;

% Add volume in m³
[volume,testSetup]=addVolumeData(deflection,pressure,testSetup);

%% Evaluate measurement data
% DFT of pressure and Volume including uncertainty propagation into
% frequency domain
for ii=length(measureData):-1:1
    excitationFrequency(ii) = measureData(ii).model_PARAMETERS.important_parameters_struct.excitation.frequency.value;
    % volume
    volume(ii).FFT = propagateSysUncToFreqDomain...
        (volume(ii).value-mean(volume(ii).value), time(ii).value, sampletime,...
        'excitation_frequency',excitationFrequency(ii), ...
        'bias', volume(ii).unc.bias,...
        'sensitivity',volume(ii).unc.sensitivity,...
        'linearity',volume(ii).unc.linearity,...
        'hysteresis',volume(ii).unc.hysteresis);
    volume(ii).FFT.value(1)=mean(volume(ii).value);
    % pressure
    pressure(ii).FFT = propagateSysUncToFreqDomain...
        (pressure(ii).value, time(ii).value, sampletime,...
        'excitation_frequency',excitationFrequency(ii), ...
        'bias', pressure(ii).unc.bias,...
        'sensitivity',pressure(ii).unc.sensitivity,...
        'linearity',pressure(ii).unc.linearity,...
        'hysteresis',pressure(ii).unc.hysteresis);
    % temperature
    temperature(ii).FFT = propagateSysUncToFreqDomain...
        ((temperature(ii).value+273.15), time(ii).value, sampletime,...
        'excitation_frequency',excitationFrequency(ii),...
        'bias', temperature(ii).unc.bias,...
        'sensitivity',temperature(ii).unc.sensitivity,...
        'linearity',temperature(ii).unc.linearity,...
        'hysteresis',temperature(ii).unc.hysteresis);
    % ambient temperature
    temperature_ambient(ii).FFT = propagateSysUncToFreqDomain...
        ((temperature_ambient(ii).value+273.15), time(ii).value, sampletime,...
        'excitation_frequency',excitationFrequency(ii),...
        'bias', temperature_ambient(ii).unc.bias,...
        'sensitivity',temperature_ambient(ii).unc.sensitivity,...
        'linearity',temperature_ambient(ii).unc.linearity,...
        'hysteresis',temperature_ambient(ii).unc.hysteresis);
end


% Adapt deadtime of keller pressure sensor
for ii=length(pressure):-1:1
    % Adapt Gas Zylinder Sensor Deadtime 2ms
    if strcmpi(testSetup(ii).testobject.label.literal,'gas cylinder')
        if strcmpi(pressure(ii).sensor.prefix,'https://w3id.org/fst/resource//0184ebd9-988b-7bba-83a5-01cec15c9820')
            pressure(ii).FFT.value=pressure(ii).FFT.value.*exp(1i*2*pi*pressure(ii).FFT.frequencies*2e-3);
        end
        % Adapt Accumulator Sensor Deadtime 1ms
    elseif strcmpi(testSetup(ii).testobject.label.literal,'hydraulic accumulator')
        if strcmpi(pressure(ii).sensor.prefix,'https://w3id.org/fst/resource//0184ebd9-988b-7bba-8310-d3fc5137ddf6')
            pressure(ii).FFT.value=pressure(ii).FFT.value.*exp(-1i*2*pi*pressure(ii).FFT.frequencies*1e-3);
        end
    end
end

% set Volume signal to zero phase dirfference and turn all other pointers
% equivalent only necessary for ploting data
for ii=length(measureData):-1:1
    [~,closestind(ii)]=min(abs(volume(ii).FFT.frequencies-volume(ii).FFT.excitation_frequency));

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
volume = getHarmonicWithUnc(volume,excitationFrequency,neval);
pressure = getHarmonicWithUnc(pressure,excitationFrequency,neval);
temperature = getHarmonicWithUnc(temperature,excitationFrequency,neval);
temperature_ambient = getHarmonicWithUnc(temperature_ambient,excitationFrequency,neval);

% Determination of temperature from pressure and Volume Data
[temperature_pv,mass] = getTempFFT(volume,pressure ,temperature_ambient , testSetup);
% Determination of Heatflow from pressure and Volume Data
heatflow = getHeatFFT(volume,pressure,temperature_ambient,testSetup);
% Determination of Nuselt Number from Heatflow and Temperature Data
Nu = getNusseltFFT(heatflow,temperature,temperature_ambient,pressure,testSetup);
Nu_pv = getNusseltFFT(heatflow,temperature_pv,temperature_ambient,pressure,testSetup);


% Some adaptions for plots
for ii=length(Nu):-1:1
    % Determination of nusselt Number for each frequency // Sort for
    % plots
    for jj=1:length(Nu(ii).FFT.value)
        plotNu(jj).res(ii)=Nu(ii).FFT.metas(jj);
        plotNu_pv(jj).res(ii)=Nu_pv(ii).FFT.metas(jj);
    end

    % Add Peclet number for comparison
    % Pe = 2pif*c_p*rho/(lambda*(A/V)^2)
    Pe(ii)=2*pi*excitationFrequency(ii)*mass(ii).value*...
        getFluidProperty(testSetup(ii).fluid_ID,...
        mean(pressure(ii).value)*1e5,mean(temperature_ambient(ii).value)+273.15,'c_p')/...
        (testSetup(ii).V1.value* ...
        getFluidProperty(testSetup(ii).fluid_ID,...
        mean(pressure(ii).value)*1e5,mean(temperature_ambient(ii).value)+273.15,'thermal_conductivity')* ...
        (testSetup(ii).Aw.value/testSetup(ii).V1.value)^2);
end

%% Analysing stiffness
for ii=length(pressure):-1:1
    plotVolume(ii) = volume(ii).FFT.harmonic.metas(2);
    plotPressure(ii) = pressure(ii).FFT.harmonic.metas(2);
    stiffness(ii) = - pressure(ii).FFT.harmonic.metas(2)/...
        volume(ii).FFT.harmonic.metas(2);

    V1=unc(testSetup(ii).V1.value,testSetup(ii).V1.accuracy);
    stiffness_dimless(ii) = stiffness(ii) * ...
        volume(ii).FFT.harmonic.metas(1)/...
        pressure(ii).FFT.harmonic.metas(1);


    % get isentropic exponent
    gamma(ii)=getFluidProperty(testSetup(ii).fluid_ID,...
        mean(pressure(ii).value)*1e5,mean(temperature_ambient(ii).value)+273.15,'isentropic_exponent');

    % Models with complex Nusselt number
    Nusselt_Lee(ii)=sqrt(Pe(ii)/2).*((1+1i).*tanh(((1+1i).*sqrt(Pe(ii)/2))))./(1-tanh(((1+1i).*sqrt(Pe(ii)/2)))./((1+1i).*sqrt(Pe(ii)/2)));
    Nusselt_fit(ii)=5.3221+1.1829*Pe(ii).^(0.5)+3.4594e-5*Pe(ii).^(1.8) + 1i*0.23197*Pe(ii).^(0.87616);
    stiffness_dimless_Lee(ii)=(1i*gamma(ii)*Nusselt_Lee(ii)/Pe(ii)-gamma(ii))/...
        (1i*gamma(ii)*Nusselt_Lee(ii)/Pe(ii)-1);
    stiffness_dimless_fit(ii)=(1i*gamma(ii)*Nusselt_fit(ii)/Pe(ii)-gamma(ii))/...
        (1i*gamma(ii)*Nusselt_fit(ii)/Pe(ii)-1);
    stiffness_dimless_Pelz(ii)=(1i*gamma(ii)*3/Pe(ii)-gamma(ii))/...
        (1i*gamma(ii)*3/Pe(ii)-1);
end
clear ii

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
end


%% Nusselt Plots
% Plot Nusselt Number in Bode Plots depending on frequency

% initiate figure
if exist ('fig_Nu', 'var')
    if isempty(fig_Nu.findobj)
        fig_Nu=figure('name','Nu(f)');
    end
else
    fig_Nu=figure('name','Nu(f)');
end

% plot selected runs
for jj =selectedruns.runs
    for ii=1
        fig_Nu = plotFreqResp(excitationFrequency(runs(jj).ind),plotNu_pv(ii).res(runs(jj).ind),fig_Nu,...
            'plottype','loglog', ...
            'ylabel','Nusselt', ...
            'phase',true, ...
            'plotOpts',plotopts);
    end
end
setfigpos(12.5,11.5,'m')


% Plot Nusselt Number in Bode Plots depending on Peclet number
% initiate figure
if exist('fig_NuPe', 'var')
    if isempty(fig_NuPe.findobj)
        fig_NuPe=figure('name','Nu(Pe)');
    end
else
    fig_NuPe=figure('name','Nu(Pe)');
end
% plot selected runs
for jj =selectedruns.runs
    for ii=1
        fig_NuPe = plotFreqResp(Pe(runs(jj).ind),plotNu_pv(ii).res(runs(jj).ind),fig_NuPe, ...
            'plottype','loglog', ...
            'ylabel','Nusselt', ...
            'ylim', [0.1,10^3],...
            'xlabel','Pe', ...
            'phase',true, ...
            'plotOpts',plotopts);
    end
end
setfigpos(12.5,11.5,'m')

% Plot Nusselt Number in real and imaginary part depending on peclet number
% initiate figure
if exist('fig_ReIm', 'var')
    if isempty(fig_ReIm.findobj)
        fig_ReIm=figure('name','Real- and imag Part of Nusseltnumber');
        tiledlayout(1,2,"Padding","tight","TileSpacing","tight")
        publishfig
    end
else
    fig_ReIm=figure('name','Nu(Pe)');
    tiledlayout(1,2,"Padding","tight","TileSpacing","tight")
    publishfig
end

% plot selected runs
for jj =selectedruns.runs
    figure(fig_ReIm)

    ax1=nexttile(1);
    plot(Pe(runs(jj).ind),real([plotNu_pv(1).res(runs(jj).ind)]))
    box off
    hold on
    ax1.XScale='log';
    ax1.YScale='log';
    xlabel('Pe')
    ylabel('Re(Nu)')
    ax2=nexttile(2);
    plot(Pe(runs(jj).ind),imag([plotNu_pv(1).res(runs(jj).ind)]))
    box off
    hold on
    ax2.XScale='log';
    ax2.YScale='log';
end
xlabel('Pe')
ylabel('Im(Nu)')




%% FFT Plots
% if you want to plot type true instead of false
if false
    % maginute volume
    % initiate figrue
    figure('Name','volume abs');
    % plots
    stem(volume(end).FFT.frequencies(1:end/2),abs(volume(end).FFT.value(1:end/2)),'Marker','none')
    hold on
    plot(volume(end).FFT.frequencies(1:end/2),abs(volume(end).FFT.value(1:end/2)),"o",'MarkerFaceColor','white','MarkerEdgeColor','black','MarkerSize',4)
    box off
    ylabel('MAGNITUDE VOLUMEN')
    xlabel('FREQUENZ')
    xlim([0,500])
    set(gca,'YScale', 'log')
    setfigpos(6.9,6.9,'m')
    publishfig

    % maginute pressure
    % initiate figrue
    figure('Name','pressure abs');
    % plots
    stem(pressure(end).FFT.frequencies(1:end/2),abs(pressure(end).FFT.value(1:end/2)),'Marker','none')
    hold on
    plot(pressure(end).FFT.frequencies(1:end/2),abs(pressure(end).FFT.value(1:end/2)),"o",'MarkerFaceColor','white','MarkerEdgeColor','black','MarkerSize',4)
    box off
    ylabel('MAGNITUDE DRUCK')
    xlabel('FREQUENZ')
    xlim([0,500])
    set(gca,'YScale', 'log')
    setfigpos(6.9,6.9,'m')
    publishfig
end

%% Uncertainty Plots
% if you want to plot type true instead of false
if false
    % staced uncertainty plots of pressure
    fig_unc_pressure=figure('name','Uncertainty Pressure');
    fig_unc_pressure=plotUncFFTStacked(pressure(runs(jj).ind),fig_unc_pressure)
    publishfig
    setfigpos(13.7,6.9,'m')
    % staced uncertatinty plot of volume
    fig_unc_volume=figure('name','Uncertainty volume');
    fig_unc_volume=plotUncFFTStacked(volume(runs(jj).ind),fig_unc_volume)
    publishfig
    setfigpos(13.7,6.9,'m')
end

%% Analyzing all uncertatinty of all runs of pressure and volume signal
% if you want to plot type true instead of false
if false
    % Volume
    % initiate figure
    figure('Name','volume abs');
    tiledlayout("flow","TileSpacing","compact")
    for ii=length(volume):-1:1
        nexttile

        stem(volume(ii).FFT.harmonic.frequencies,abs(volume(ii).FFT.harmonic.metas.Value))
        hold on
        errorbar(volume(ii).FFT.harmonic.frequencies,abs(volume(ii).FFT.harmonic.metas.Value),abs(volume(ii).FFT.harmonic.metas.StdUnc),'LineStyle','none')
        box off
        ylim([0,0.00002])
    end

    figure('Name','volume phase')
    tiledlayout("flow","TileSpacing","compact")
    for ii=length(volume):-1:1
        nexttile

        stem(volume(ii).FFT.harmonic.frequencies,phase(volume(ii).FFT.harmonic.metas.Value))
        hold on
        errorbar(volume(ii).FFT.harmonic.frequencies,phase(volume(ii).FFT.harmonic.metas.Value),phase(volume(ii).FFT.harmonic.metas.StdUnc),'LineStyle','none')
        box off
        ylim([-pi/2,pi/2])
    end
    % pressure
    % initiate figure
    figure('Name','pressure phase')
    tiledlayout("flow","TileSpacing","compact")
    for ii=length(pressure):-1:1
        nexttile

        stem(pressure(ii).FFT.harmonic.frequencies,phase(pressure(ii).FFT.harmonic.metas.Value))
        hold on
        errorbar(pressure(ii).FFT.harmonic.frequencies,phase(pressure(ii).FFT.harmonic.metas.Value),phase(pressure(ii).FFT.harmonic.metas.StdUnc),'LineStyle','none')
        box off
        % ylim([0,5])
    end

    figure('Name','pressure abs')
    tiledlayout("flow","TileSpacing","compact")
    for ii=length(pressure):-1:1
        nexttile
        stem(pressure(ii).FFT.harmonic.frequencies,abs(pressure(ii).FFT.harmonic.metas.Value))
        hold on
        errorbar(pressure(ii).FFT.harmonic.frequencies,abs(pressure(ii).FFT.harmonic.metas.Value),abs(pressure(ii).FFT.harmonic.metas.StdUnc),'LineStyle','none')
        box off
        ylim([0,5])
    end

end


%% Stiffness Plots
%plot abolute stiffness in bode plot depending on frequency
for jj =selectedruns.runs
    try
        fig_stiffness = plotFreqResp(excitationFrequency(runs(jj).ind),stiffness(runs(jj).ind),fig_stiffness, ...
            'plottype','absolute', ...
            'ylabel','STEIFIGKEIT in bar/m3', ...
            'phase',true, ...
            'plotOpts',plotopts);
    catch
        fig_stiffness=figure('name','Stiffness K');
        fig_stiffness = plotFreqResp(excitationFrequency(runs(jj).ind),stiffness(runs(jj).ind),fig_stiffness, ...
            'plottype','absolute', ...
            'ylabel','STEIFIGKEIT in bar/l', ...
            'phase',true, ...
            'plotOpts',plotopts);
    end
end
setfigpos(12.5,11.5,'m')

%plot dimensionless stiffness in bode plot depending on Peclet number
% inclunding models from Lee Pelz and Rexer
for jj =selectedruns.runs
    try
        fig_stiffness_dimless = plotFreqResp(Pe(runs(jj).ind),stiffness_dimless(runs(jj).ind),fig_stiffness_dimless, ...
            'plottype','absolute', ...
            'ylabel','STEIFIGKEIT K^+', ...
            'xlabel','PECLET', ...
            'phase',true, ...
            'plotOpts',plotopts);
    catch
        fig_stiffness_dimless=figure('name','Dim.less Stiffness K+');
        fig_stiffness_dimless = plotFreqResp(Pe(runs(jj).ind),stiffness_dimless(runs(jj).ind),fig_stiffness_dimless, ...
            'plottype','absolute', ...
            'ylabel','STEIFIGKEIT K^+', ...
            'xlabel','PECLET', ...
            'phase',true, ...
            'plotOpts',plotopts);
    end
    fig_stiffness_dimless = plotFreqResp(Pe(runs(jj).ind),stiffness_dimless_fit(runs(jj).ind),fig_stiffness_dimless,'plotOpts',{'-'},'plottype','absolute','ylabel','STEIFIGKEIT K^+','phase',true);
    fig_stiffness_dimless = plotFreqResp(Pe(runs(jj).ind),stiffness_dimless_Lee(runs(jj).ind),fig_stiffness_dimless,'plotOpts',{'-'},'plottype','absolute','ylabel','STEIFIGKEIT K^+','phase',true);
    fig_stiffness_dimless = plotFreqResp(Pe(runs(jj).ind),stiffness_dimless_Pelz(runs(jj).ind),fig_stiffness_dimless,'plotOpts',{'-'},'plottype','absolute','ylabel','STEIFIGKEIT K^+','phase',true);
end
setfigpos(12.5,11.5,'m')
%% Arange and save Data
for ii=length(measureData):-1:1
    % get measurement IDs
    % if it doesnt exist add a number
    if isfield(measureData(ii).METADATA,'measurement_UUID')
        measID{ii}=[measureData(ii).METADATA.measurement_UUID];
    else
        measID{ii}=num2str(ii);
    end
end

for jj=length(runs):-1:1
    % get Run name
    exp=table( excitationFrequency(runs(jj).ind).',...
        Pe(runs(jj).ind).',...
        plotNu_pv(1).res.Value(runs(jj).ind).', ...
        plotNu_pv(1).res.StdUnc(runs(jj).ind).', ...
        stiffness(runs(jj).ind).Value.',...
        stiffness(runs(jj).ind).StdUnc.',...
        stiffness_dimless(runs(jj).ind).Value.',...
        stiffness_dimless(runs(jj).ind).StdUnc.',...
        cellstr(measID(runs(jj).ind).'),...
        gamma(runs(jj).ind).');

    exp = addprop(exp,{'TestObject','zAmp','p0','p1','Ta'}, ...
        {'table','table','table','table','table'});

    exp.Properties.VariableNames(1)={'f0'};
    exp.Properties.VariableDescriptions(1)={'Ecxitation Frequency'};
    exp.Properties.VariableUnits(1)={'HZ'};
    exp.Properties.VariableNames(2)={'Pe'};
    exp.Properties.VariableDescriptions(2)={'Péclet Number'};
    exp.Properties.VariableUnits(2)={'UNITLESS'};
    exp.Properties.VariableNames(3)={'Nu'};
    exp.Properties.VariableDescriptions(3)={'Nusselt Number'};
    exp.Properties.VariableUnits(3)={'UNITLESS'};
    exp.Properties.VariableNames(4)={'Nu_StdUnc'};
    exp.Properties.VariableDescriptions(4)={'95-percent uncertainty of the Nusselt number'};
    exp.Properties.VariableUnits(4)={'UNITLESS'};
    exp.Properties.VariableNames(5)={'K'};
    exp.Properties.VariableDescriptions(5)={'Stiffness'};
    exp.Properties.VariableUnits(5)={'BAR-PER-M3'};
    exp.Properties.VariableNames(6)={'K_StdUnc'};
    exp.Properties.VariableDescriptions(6)={'95-percent uncertainty of the Stiffness'};
    exp.Properties.VariableUnits(6)={'BAR-PER-M3'};
    exp.Properties.VariableNames(7)={'K+'};
    exp.Properties.VariableDescriptions(7)={'Dimensionless Stiffness'};
    exp.Properties.VariableUnits(7)={'UNITLESS'};
    exp.Properties.VariableNames(8)={'K+_StdUnc'};
    exp.Properties.VariableDescriptions(8)={'95-percent uncertainty of the Dimensionless Stiffness'};
    exp.Properties.VariableUnits(8)={'UNITLESS'};
    exp.Properties.VariableNames(9)={'Measurement_UUID'};
    exp.Properties.VariableNames(10)={'gamma'};
    exp.Properties.VariableDescriptions(10)={'Isentropic Exponent'};
    exp.Properties.VariableUnits(10)={'UNITLESS'};

    exp.Properties.CustomProperties.TestObject = testObj;
    exp.Properties.CustomProperties.zAmp = runs(jj).amplitude;
    exp.Properties.CustomProperties.Ta = runs(jj).temperature;
    exp.Properties.CustomProperties.p0 = runs(jj).p0;
    exp.Properties.CustomProperties.p1 = runs(jj).p1;

    exp.Properties.Description = [testObj,'_',...
        num2str(runs(jj).amplitude),'_mm_',...
        num2str(runs(jj).temperature),'_C_p0_',...
        num2str(runs(jj).p0),'_bar_p1_',...
        num2str(runs(jj).p1),'_bar' ];


    save(['test_data\Results\',exp.Properties.Description,'.mat'],'exp')

end


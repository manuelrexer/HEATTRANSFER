
% code_230223_evaluate_heattransfer_FFT
% Code that determines the complex Nusselt number in the frequency domain
% from measurement data and  plot it afterwards
%
% created: Rexer 28.02.22
% Version: Disseration v1.0.1
% New Datamodel

%% clear
clc
clearvars -except fig_Nu fig_NuPe fig_stiffness fig_ReIm
unc = @LinProp;

%% Options and Preperation

% number of orders to bee evaluated (first order is neccesary)
neval=1;

%% Reading the measurement data
measureData = getMeasureData();
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
% ambient temperature Data
if isfield(measureData, 'temperature_ambient')
    fieldname.temperature_ambient={'temperature_ambient'};
elseif isfield(measureData, 'ambient_temperature')
    fieldname.temperature_ambient={'ambient_temperature'};
else
    fieldname.temperature_ambient=getSelectedFields(measureData, 'select ambient temperature ');
end
temperature_ambient=extractMeasurements(measureData,fieldname.temperature_ambient{1});
% time vector
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

sampletime = measureData(1).model_PARAMETERS.all_parameters_array(1).value;
% Add volume in m³
[volume,testSetup]=addVolumeData(deflection,pressure,testSetup);

%% Evaluate measurement data
% DFT of pressure and Volume
for ii=length(measureData):-1:1
    excitationFrequency(ii) = measureData(ii).model_PARAMETERS.important_parameters_struct.excitation.frequency.value;
    % volume
    volume(ii).FFT = propagateSysUncToFreqDomain...
        (volume(ii).value, time(ii).value, sampletime,...
        'excitation_frequency',excitationFrequency(ii), ...
        'bias', volume(ii).unc.bias,...
        'sensitivity',volume(ii).unc.sensitivity,...
        'linearity',volume(ii).unc.linearity,...
        'hysteresis',volume(ii).unc.hysteresis);
    % pressure
    pressure(ii).FFT = propagateSysUncToFreqDomain...
        (pressure(ii).value, time(ii).value, sampletime,...
        'excitation_frequency',excitationFrequency(ii),...
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
    if strcmpi(testSetup(ii).testobject.label.literal,'gas cylinder')
        if strcmpi(pressure(ii).sensor.prefix,'https://w3id.org/fst/resource//0184ebd9-988b-7bba-83a5-01cec15c9820')
            pressure(ii).FFT.value=pressure(ii).FFT.value.*exp(1i*2*pi*pressure(ii).FFT.frequencies*2e-3);
        end
    end
end

% set Volume signal to zero phase dirfference and turn al other pointers
% equivalent
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
[temperature_pv,mass,Nu_test] = getTempFFT(volume,pressure ,temperature_ambient , testSetup);
% Determination of Heatflow from pressure and Volume Data
heatflow = getHeatFFT(volume,pressure,temperature_ambient,testSetup);
% Determination of Nuselt Number from Heatflow and Temperature Data
Nu = getNusseltFFT(heatflow,temperature,temperature_ambient,pressure,testSetup);
Nu_pv = getNusseltFFT(heatflow,temperature_pv,temperature_ambient,pressure,testSetup);


% Detrmination of nusselt angle
for ii=length(Nu):-1:1
    % Determination of nusselt Number for each frequency // Sort for
    % plots
    for jj=1:length(Nu(ii).FFT.value)
        plotNu(jj).res(ii)=Nu(ii).FFT.metas(jj);
        plotNu_pv(jj).res(ii)=Nu_pv(ii).FFT.metas(jj);
    end
    % Phase between Heatflux and Temperature for validation
    %     angle(Nu_pv(ii).FFT.metas(1))
    %     angle(heatflow(ii).FFT.harmonic.metas(2)/-temperature(ii).FFT.harmonic.metas(2))
    Nu_angle(ii) = angle(heatflow(ii).FFT.harmonic.metas(2).Value)-angle(-temperature_pv(ii).FFT.harmonic.metas(2).Value);
    if Nu_angle(ii)<0
        Nu_angle(ii)=Nu_angle(ii)+2*pi;
    end

    % Add Peclet number for comparison
    Pe(ii)=2*pi*excitationFrequency(ii)*mass(ii).value*...
        getFluidProperty(testSetup(ii).fluid_ID,...
        mean(pressure(ii).value)*1e5,mean(temperature_ambient(ii).value)+273.15,'c_p')/...
        (testSetup(ii).V1.value* ...
        getFluidProperty(testSetup(ii).fluid_ID,...
        mean(pressure(ii).value)*1e5,mean(temperature_ambient(ii).value)+273.15,'thermal_conductivity')* ...
        (testSetup(ii).Aw.value/testSetup(ii).V1.value)^2);
end

% Determine the slope of the first order of nusselt number
[slope,offset]=polyfit(log10(excitationFrequency),log10(abs([plotNu_pv(1).res.Value])),1);
disp("Steigung: " + num2str(slope(1))+ " Offset: "+ num2str(offset.normr))

%% Analysing stiffness
for ii=length(pressure):-1:1
    plotVolume(ii) = volume(ii).FFT.harmonic.metas(2);
    plotPressure(ii) = pressure(ii).FFT.harmonic.metas(2);
    stiffness(ii) = pressure(ii).FFT.harmonic.metas(2)/...
        volume(ii).FFT.harmonic.metas(2);

    V1=unc(testSetup(ii).V1.value,testSetup(ii).V1.accuracy);
    stiffness_dimless(ii) = stiffness(ii) * V1 /  mean(pressure(ii).value);

    % Model with complex Nusselt number

    gamma=getFluidProperty(testSetup(ii).fluid_ID,...
        mean(pressure(ii).value)*1e5,mean(temperature_ambient(ii).value)+273.15,'isentropic_exponent');
    %     lambda = unc(getFluidProperty(testSetup(ii).fluid_ID,...
    %         mean(pressure(ii).value)*1e5,mean(temperature_ambient(ii).value)+273.15,'thermal_conductivity'));
    %     Aw = unc(testSetup(ii).Aw.value,testSetup(ii).Aw.accuracy);
    %     s = Aw/V1;
    %     m=mass(ii).metas;
    %     R=296;

    Nusselt_c(ii)=1*Pe(ii)^(0.5)+1  +1i*Pe(ii)^(0.5);
    stiffness_dimless_modell(ii)=-(1i*gamma*Nusselt_c(ii)/Pe(ii)-gamma)/...
        (1i*gamma*Nusselt_c(ii)/Pe(ii)-1);

    stiffness_dimless_Pelz(ii)=-(1i*gamma*3/Pe(ii)-gamma)/...
        (1i*gamma*3/Pe(ii)-1);
end
clear ii


%% Nusselt Plots

if exist ('fig_Nu', 'var')
    if isempty(fig_Nu.findobj)
        fig_Nu=figure('name','Nu(f)');
    end
else
    fig_Nu=figure('name','Nu(f)');
end
% publishfig
for jj =selectedruns.runs
    for ii=1;%1:length(plotNu)
        %         fig_Nu = plotFreqResp(excitationFrequency,plotNu(ii).res,fig_Nu,'plottype','loglog','ylabel','Nusselt','phase',true);
        fig_Nu = plotFreqResp(excitationFrequency(runs(jj).ind),plotNu_pv(ii).res(runs(jj).ind),fig_Nu,'plottype','loglog','ylabel','Nusselt','phase',true);
    end
end


if exist('fig_NuPe', 'var')
    if isempty(fig_NuPe.findobj)
        fig_NuPe=figure('name','Nu(Pe)');
    end
else
    fig_NuPe=figure('name','Nu(Pe)');
end
% publishfig
% fig_NuPe = plotFreqResp(Pe,[Nu_test.test],fig_NuPe,'plottype','loglog','ylabel','Nusselt','xlabel','Pe','phase',true);
for jj =selectedruns.runs
    for ii=1;%1:length(plotNu)
        %     fig_NuPe = plotFreqResp(Pe,plotNu(ii).res,fig_NuPe,'plottype','loglog','ylabel','Nusselt','xlabel','Pe','phase',true);
        fig_NuPe = plotFreqResp(Pe(runs(jj).ind),plotNu_pv(ii).res(runs(jj).ind),fig_NuPe,'plottype','loglog','ylabel','Nusselt','xlabel','Pe','phase',true);
    end
end
% figure('name','Phase Q/T')
% semilogx(Pe,rad2deg(Nu_angle))
if exist('fig_ReIm', 'var')
    if isempty(fig_ReIm.findobj)
        fig_ReIm=figure('name','Real- and imag Part of Nusseltnumber');
        publishfig
    end
else
    fig_ReIm=figure('name','Nu(Pe)');
    publishfig
end
for jj =selectedruns.runs
    figure(fig_ReIm)
    tiledlayout(1,2)
    ax1=nexttile;
    plot(Pe(runs(jj).ind),real([plotNu_pv(1).res(runs(jj).ind)]))
    box off
    ax1.XScale='log';
    ax1.YScale='log';
    xlabel('Pe')
    ylabel('Re(Nu)')
    ax2=nexttile;
    plot(Pe(runs(jj).ind),imag([plotNu_pv(1).res(runs(jj).ind)]))
    box off
    ax2.XScale='log';
    ax2.YScale='log';
end
xlabel('Pe')
ylabel('Im(Nu)')


%Comparison to Hartig

load MeanOscillatingPecletNumber4mm120bar40bar0_7L.mat
Pe120bar4mm = k;
load NusseltFit4mm120bar40bar0_7L.mat
Nu120bar4mm = resultsFitKornhauser;

% [fig_NuPe] = plotFreqResp([Pe120bar4mm],[Nu120bar4mm.complexNu],fig_NuPe,'plottype','loglog','phase',true);


%% FFT Plots
if false
    figure('Name','volume abs');

    stem(volume(end).FFT.frequencies(1:end/2),abs(volume(end).FFT.value(1:end/2)),'Marker','none')
    hold on
    plot(volume(end).FFT.frequencies(1:end/2),abs(volume(end).FFT.value(1:end/2)),"o",'MarkerFaceColor','white','MarkerEdgeColor','black','MarkerSize',4)
    box off
    ylabel('MAGNITUDE VOLUMEN')
    xlabel('FREQUENZ')
    xlim([0,500])
    setfigpos(6.7,6.7,'m')
    publishfig



    figure('Name','pressure abs');

    stem(pressure(end).FFT.frequencies(1:end/2),abs(pressure(end).FFT.value(1:end/2)),'Marker','none')
    hold on
    plot(pressure(end).FFT.frequencies(1:end/2),abs(pressure(end).FFT.value(1:end/2)),"o",'MarkerFaceColor','white','MarkerEdgeColor','black','MarkerSize',4)
    box off
    ylabel('MAGNITUDE DRUCK')
    xlabel('FREQUENZ')
    xlim([0,500])

    setfigpos(6.7,6.7,'m')
    publishfig



end

%% Unsicherheitsplots
if false
fig_unc_pressure=figure('name','Uncertainty Pressure');
fig_unc_pressure=plotUncFFTStacked(pressure,fig_unc_pressure)
publishfig
setfigpos(13.7,6.9,'m')

fig_unc_volume=figure('name','Uncertainty volume');
fig_unc_volume=plotUncFFTStacked(volume,fig_unc_volume)
publishfig
setfigpos(13.7,6.9,'m')

end

if false
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

    figure('Name','pressure phase')
    tiledlayout("flow","TileSpacing","compact")
    for ii=length(pressure):-1:1
        nexttile

        stem(pressure(ii).FFT.harmonic.frequencies,phase(pressure(ii).FFT.harmonic.metas.Value))
        hold on
        errorbar(pressure(ii).FFT.harmonic.frequencies,phase(pressure(ii).FFT.harmonic.metas.Value),phase(pressure(ii).FFT.harmonic.metas.StdUnc),'LineStyle','none')
        box off
        %         ylim([0,5])
    end

    figure('Name','pressure phase')
    tiledlayout("flow","TileSpacing","compact")
    for ii=length(pressure):-1:1
        nexttile

        stem(pressure(ii).FFT.frequencies,phase(pressure(ii).FFT.value))
        %         hold on
        %         errorbar(pressure(ii).FFT.frequencies,phase(pressure(ii).FFT.value),phase(pressure(ii).FFT.harmonic.metas.StdUnc),'LineStyle','none')
        box off
        %
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


%% Steifigkeitsplots
% try
%     fig_stiffness = plotFreqResp(excitationFrequency,stiffness,fig_stiffness,'plottype','absolute','ylabel','STEIFIGKEIT in bar/l','phase',true);
% catch
%     fig_stiffness=figure('name','Stiffness K');
%     fig_stiffness = plotFreqResp(excitationFrequency,stiffness,fig_stiffness,'plottype','absolute','ylabel','STEIFIGKEIT in bar/l','phase',true);
% end
for jj =selectedruns.runs
    try
        fig_stiffness_dimless = plotFreqResp(Pe(runs(jj).ind),stiffness_dimless(runs(jj).ind),fig_stiffness_dimless,'plottype','absolute','ylabel','STEIFIGKEIT K^+','phase',true);
    catch
        fig_stiffness_dimless=figure('name','Dim.less Stiffness K+');
        fig_stiffness_dimless = plotFreqResp(Pe(runs(jj).ind),stiffness_dimless(runs(jj).ind),fig_stiffness_dimless,'plottype','absolute','ylabel','STEIFIGKEIT K^+','phase',true);
    end
    fig_stiffness_dimless = plotFreqResp(Pe(runs(jj).ind),stiffness_dimless_modell(runs(jj).ind),fig_stiffness_dimless,'plottype','absolute','ylabel','STEIFIGKEIT K^+','phase',true);
    fig_stiffness_dimless = plotFreqResp(Pe(runs(jj).ind),stiffness_dimless_Pelz(runs(jj).ind),fig_stiffness_dimless,'plottype','absolute','ylabel','STEIFIGKEIT K^+','phase',true);
end
%% Test

% getFluidProperty('https://w3id.org/fst/resource/018dba9b-f067-7d3e-8a4d-d60cebd70a8a',1e5,293,'c_v')
% getFluidProperty('https://w3id.org/fst/resource/018dba9b-f067-7d3e-8a4d-d60cebd70a8a',1e5,293,'c_p')
% getFluidProperty('https://w3id.org/fst/resource/018dba9b-f067-7d3e-8a4d-d60cebd70a8a',1e5,293,'thermal_conductivity')
% getFluidProperty('https://w3id.org/fst/resource/018dba9b-f067-7d3e-8a4d-d60cebd70a8a',1e5,293,'specific_gas_constant')
% getFluidProperty('https://w3id.org/fst/resource/018dba9b-f067-7d3e-8a4d-d60cebd70a8a',1e5,293,'isentropic_exponent')

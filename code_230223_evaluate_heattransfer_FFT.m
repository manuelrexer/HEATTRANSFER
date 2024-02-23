% code_230223_evaluate_heattransfer_FFT
% Code that determines the complex Nusselt number in the frequency domain
% from measurement data and  plot it afterwards
%
% created: Rexer 28.02.22
% Version: Disseration v1.0.1
% New Datamodel

%% clear
clc
clearvars -except fig_NuPe
if exist('fig_NuPe')
    if isempty(fig_NuPe.findobj)
        clear fig_NuPe
    end
end
%% Options and Preperation

% number of orders to bee evaluated (first order is neccesary)
neval=4;

%% Reading the measurement data
measureData = getMeasureData(input);

                
% reading parameter and adapting gas parameters to load pressure
 getTestrigParameter

 getUncertaintyParameter
param.gamma.pressure=mean(measureData(1).druck_gas);
[param.gamma.value,~,param.cp.value]=getIsentropicExp(param.gamma.pressure*100000);
%% Adapt measurement data

% Add volume in m³
[measureData,param,input]=addVolume(measureData,param,input);

%% Select data for analyzation

% Volume Data
if isfield(measureData, 'Volume')
    input.eveluate(1).fieldname='Volume';
else
    input=getSelectedFields(input);
    input.eveluate(1).fieldname=input.selectedfields{end};
end
input.eveluate(1).name='volume';
input.eveluate(1).variable='V';

% pressure Data
if isfield(measureData, 'druck_gas')
    input.eveluate(2).fieldname='druck_gas';
else
    input=getSelectedFields(input);
    input.eveluate(2).fieldname=input.selectedfields{end};
end
input.eveluate(2).name='pressure';
input.eveluate(2).variable='p';

% temperature Data
if isfield(measureData, 'temperatur_gas')
    input.eveluate(3).fieldname='temperatur_gas';
else
    input=getSelectedFields(input);
    input.eveluate(3).fieldname=input.selectedfields{end};
end
input.eveluate(3).name='temperature';
input.eveluate(3).variable='T';


%% Evaluate measurement data
% DFT of pressure and Volume
for ii=1:input.nFiles
    for jj=1:length(input.eveluate)
        [EvalData(ii).(input.eveluate(jj).name).value,...
            EvalData(ii).(input.eveluate(jj).name).frequency,...
            EvalData(ii).(input.eveluate(jj).name).dftcoeff_omega,EvalData(ii).omega] =...
            getSpectrumOmega(measureData(ii).zeit,...
            measureData(ii).(input.eveluate(jj).fieldname),...
            measureData(ii).config.anregung_freq);
    end
end
clear ii jj



% set Volume signal to zero phase dirfference and turn al other pointers
% equivalent
for ii=1:input.nFiles
    %     EvalData(ii).volume=shiftComplex(EvalData(ii).volume,EvalData(ii).frequency,-0.00);
    phase0=angle(EvalData(ii).volume.dftcoeff_omega);
    EvalData(ii).volume.value(2:end)=turnComplex(EvalData(ii).volume.value(2:end),-phase0);
    %     EvalData(ii).volume.value(1)=abs(EvalData(ii).volume.value(1));
    %     phase0=angle(EvalData(ii).volume);
    EvalData(ii).pressure.value(2:end)=turnComplex(EvalData(ii).pressure.value(2:end),-phase0);
    %     EvalData(ii).pressure.value(1)=abs(EvalData(ii).pressure.value(1));
    %     EvalData(ii).pressure_=shiftComplex(EvalData(ii).pressure,EvalData(ii).frequency,0.01);
    EvalData(ii).temperature.value(2:end)=turnComplex(EvalData(ii).temperature.value(2:end),-phase0);
    %     EvalData(ii).temperature.value(1)=abs(EvalData(ii).temperature.value(1));
    clear phase 0
end
clear ii

% Evaluation Method
for ii=1:input.nFiles
    % Determination of temperature from pressure and Volume Data
    [EvalData(ii).temperature_pv,EvalData(ii).mass.value,EvalData(ii).ambiantTemperatrue.value] = getTempFFT...
        (EvalData(ii).volume, EvalData(ii).pressure, measureData(ii), param);
    % Determination of Heatflow from pressure and Volume Data
    [EvalData(ii).heatflow] = getHeatFFT...
        (EvalData(ii).volume, EvalData(ii).pressure, param);
    % Determination of Nuselt Number from Heatflow and Temperature Data
    [EvalData(ii).Nu] = getNusseltFFT...
        (EvalData(ii).heatflow, EvalData(ii).temperature,...
        EvalData(ii).ambiantTemperatrue.value,param);

    EvalData(ii).stiffness = EvalData(ii).pressure.dftcoeff_omega/EvalData(ii).volume.dftcoeff_omega;
end
clear ii jj

input.eveluate(3).name='Nu';
% Cutting out neval harmonics of the signal
for ii=1:input.nFiles
    for jj=1:length(input.eveluate)
        [EvalData(ii).(input.eveluate(jj).name).value,EvalData(ii).(input.eveluate(jj).name).frequency] = ...
            getHarmonic(EvalData(ii).(input.eveluate(jj).name).value,EvalData(ii).(input.eveluate(jj).name).frequency,...
            measureData(ii).config.anregung_freq,neval);
    end
end
clear ii jj



% Detrmination of nusselt angle
for ii=1:input.nFiles
    % Determination of nusselt Nuber for each frequency
    for jj=2:length(EvalData(ii).Nu.value)
        Nu(jj).res(ii)=EvalData(ii).Nu.value(find(...
            abs(EvalData(ii).Nu.frequency-EvalData(ii).omega*(jj-1))<0.03*EvalData(ii).omega));
    end

    Nu_angel(ii) = angle(EvalData(ii).heatflow.value(2))-angle(EvalData(ii).temperature.value(2));
    if Nu_angel(ii)<0
        Nu_angel(ii)=Nu_angel(ii)+2*pi;
    end
    % Add Peclet number
    EvalData(ii).Pe=2*pi*EvalData(ii).omega*param.cp.value*EvalData(ii).mass.value/...
        (measureData(ii).V1*param.lambda.value*param.s.value^2);
    % Determination of Stiffness
end


% Determine the lopfe of the first order of nusselt number
[slope,offset]=polyfit(log10([EvalData.omega]),log10(abs([Nu(2).res])),1);
disp("Steigung: " + num2str(slope(1))+ " Offset: "+ num2str(offset.normr))

%% Plots
% Plot Options
input.type = 'loglog';
input.decades_equal = false;
% input.xlimits=[1e-3,1e1];
% input.ylimits=[1e-2,1e4];
% [fig_Nu_pv] = plotFreqResp([EvalData.frequency],[EvalData.Nu_pv],input);
fig_Nu=figure();
publishfig
for ii=2:length(Nu)
    fig_Nu = plotFreqResp([EvalData.omega],[Nu(ii).res],input,fig_Nu);
end
clear ii

if ~exist("fig_NuPe")
    fig_NuPe=figure();
    publishfig
end
for ii=2 %:length(Nu)
    fig_NuPe = plotFreqResp([EvalData.Pe],[Nu(ii).res],input,fig_NuPe);
end
clear ii


load MeanOscillatingPecletNumber4mm120bar40bar0_7L.mat
Pe120bar4mm = k;
load NusseltFit4mm120bar40bar0_7L.mat
Nu120bar4mm = resultsFitKornhauser;
% [fig_Nu] = plotFreqResp([EvalData.frequency],[Nu],input);
% [fig_Nu] = plotFreqResp([EvalData.frequency],[Nu2],input,fig_Nu);
[fig_Nu] = plotFreqResp([Nu120bar4mm.freq],[Nu120bar4mm.complexNu],input,fig_Nu);
%  [fig_NuPe] = plotFreqResp([Pe120bar4mm],[Nu120bar4mm.complexNu],input,fig_NuPe);
% [fig_Nu] = plotFreqResp([EvalData.frequency],[Nu2+Nu],input,fig_Nu);

[fig_Stffness] = plotFreqResp([EvalData.omega],[EvalData.stiffness]/1000,input);


%% Temperaturauswertung
% for ii=1:input.nFiles
%     fig_temp{ii} = plotFreqResp([EvalData(ii).frequency_vek],[EvalData(ii).temperature_vek],input);
% end
% for ii=1:input.nFiles
%     fig_temp{ii} = plotFreqResp([EvalData(ii).frequency_vek],[EvalData(ii).pressure_vek],input);
% end
% for ii=1:input.nFiles
%     fig_temp{ii} = plotFreqResp([EvalData(ii).frequency_vek],[EvalData(ii).volume_vek],input);
% end
% fig_temp_vergleich= plotFreqResp([EvalData.frequency],[EvalData.temperature],input);
% fig_temp_vergleich= plotFreqResp([EvalData.frequency],[EvalData.temperature_pv],input,fig_temp_vergleich);
% fig_temp_vergleich= plotFreqResp([EvalData.frequency],[EvalData.t_pv],input,fig_temp_vergleich);


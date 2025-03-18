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

%% Options and Preperation

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


[data, plotopts, testObj] = evaluate_heattransfer_FFT_function(measureData);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
        fig_Nu = plotFreqResp(data.excitationFrequency(runs(jj).ind), data.plotNu_pv(ii).res(runs(jj).ind), fig_Nu,...
            'plottype', 'loglog', ...
            'ylabel', 'Nusselt', ...
            'phase', true, ...
            'plotOpts', plotopts);
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
        fig_NuPe = plotFreqResp(data.Pe(runs(jj).ind), data.plotNu_pv(ii).res(runs(jj).ind), fig_NuPe, ...
            'plottype', 'loglog', ...
            'ylabel', 'Nusselt', ...
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
    plot(data.Pe(runs(jj).ind), real([data.plotNu_pv(1).res(runs(jj).ind)]))
    box off
    hold on
    ax1.XScale='log';
    ax1.YScale='log';
    xlabel('Pe')
    ylabel('Re(Nu)')
    ax2=nexttile(2);
    plot(data.Pe(runs(jj).ind), imag([data.plotNu_pv(1).res(runs(jj).ind)]))
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
    stem(data.volume(end).FFT.frequencies(1:end/2), abs(data.volume(end).FFT.value(1:end/2)), 'Marker', 'none')
    hold on
    plot(data.volume(end).FFT.frequencies(1:end/2),abs(data.volume(end).FFT.value(1:end/2)), "o", 'MarkerFaceColor', 'white', 'MarkerEdgeColor', 'black', 'MarkerSize', 4)
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
    stem(data.pressure(end).FFT.frequencies(1:end/2), abs(data.pressure(end).FFT.value(1:end/2)),'Marker','none')
    hold on
    plot(data.pressure(end).FFT.frequencies(1:end/2), abs(data.pressure(end).FFT.value(1:end/2)),"o",'MarkerFaceColor','white','MarkerEdgeColor','black','MarkerSize',4)
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
    fig_unc_volume=plotUncFFTStacked(data.volume(runs(jj).ind), fig_unc_volume)
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

        stem(data.volume(ii).FFT.harmonic.frequencies, abs(data.volume(ii).FFT.harmonic.metas.Value))
        hold on
        errorbar(data.volume(ii).FFT.harmonic.frequencies, abs(data.volume(ii).FFT.harmonic.metas.Value), abs(data.volume(ii).FFT.harmonic.metas.StdUnc), 'LineStyle', 'none')
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

        stem(data.pressure(ii).FFT.harmonic.frequencies, phase(data.pressure(ii).FFT.harmonic.metas.Value))
        hold on
        errorbar(data.pressure(ii).FFT.harmonic.frequencies, phase(data.pressure(ii).FFT.harmonic.metas.Value), phase(data.pressure(ii).FFT.harmonic.metas.StdUnc), 'LineStyle', 'none')
        box off
        % ylim([0,5])
    end

    figure('Name','pressure abs')
    tiledlayout("flow","TileSpacing","compact")
    for ii=length(pressure):-1:1
        nexttile
        stem(data.pressure(ii).FFT.harmonic.frequencies, abs(data.pressure(ii).FFT.harmonic.metas.Value))
        hold on
        errorbar(data.pressure(ii).FFT.harmonic.frequencies, abs(data.pressure(ii).FFT.harmonic.metas.Value), abs(data.pressure(ii).FFT.harmonic.metas.StdUnc), 'LineStyle', 'none')
        box off
        ylim([0,5])
    end

end


%% Stiffness Plots
%plot abolute stiffness in bode plot depending on frequency
for jj =selectedruns.runs
    try
        fig_stiffness = plotFreqResp(data.excitationFrequency(runs(jj).ind), data.stiffness(runs(jj).ind), fig_stiffness, ...
            'plottype', 'absolute', ...
            'ylabel', 'STEIFIGKEIT in bar/m3', ...
            'phase', true, ...
            'plotOpts', plotopts);
    catch
        fig_stiffness = figure('name','Stiffness K');
        fig_stiffness = plotFreqResp(data.excitationFrequency(runs(jj).ind), data.stiffness(runs(jj).ind), fig_stiffness, ...
            'plottype', 'absolute', ...
            'ylabel', 'STEIFIGKEIT in bar/l', ...
            'phase', true, ...
            'plotOpts', plotopts);
    end
end
setfigpos(12.5,11.5,'m')

%plot dimensionless stiffness in bode plot depending on Peclet number
% inclunding models from Lee Pelz and Rexer
for jj =selectedruns.runs
    try
        fig_stiffness_dimless = plotFreqResp(data.Pe(runs(jj).ind), data.stiffness_dimless(runs(jj).ind), fig_stiffness_dimless, ...
            'plottype','absolute', ...
            'ylabel','STEIFIGKEIT K^+', ...
            'xlabel','PECLET', ...
            'phase',true, ...
            'plotOpts',plotopts);
    catch
        fig_stiffness_dimless=figure('name','Dim.less Stiffness K+');
        fig_stiffness_dimless = plotFreqResp(data.Pe(runs(jj).ind), data.stiffness_dimless(runs(jj).ind), fig_stiffness_dimless, ...
            'plottype','absolute', ...
            'ylabel','STEIFIGKEIT K^+', ...
            'xlabel','PECLET', ...
            'phase',true, ...
            'plotOpts',plotopts);
    end
    fig_stiffness_dimless = plotFreqResp(data.Pe(runs(jj).ind), data.stiffness_dimless_fit(runs(jj).ind), fig_stiffness_dimless, 'plotOpts', {'-'}, 'plottype', 'absolute', 'ylabel', 'STEIFIGKEIT K^+', 'phase', true);
    fig_stiffness_dimless = plotFreqResp(data.Pe(runs(jj).ind), data.stiffness_dimless_Lee(runs(jj).ind), fig_stiffness_dimless, 'plotOpts', {'-'}, 'plottype', 'absolute', 'ylabel', 'STEIFIGKEIT K^+', 'phase', true);
    fig_stiffness_dimless = plotFreqResp(data.Pe(runs(jj).ind), data.stiffness_dimless_Pelz(runs(jj).ind), fig_stiffness_dimless, 'plotOpts', {'-'}, 'plottype', 'absolute', 'ylabel', 'STEIFIGKEIT K^+', 'phase', true);
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
    exp=table(data.excitationFrequency(runs(jj).ind).',...
        data.Pe(runs(jj).ind).',...
        data.plotNu_pv(1).res.Value(runs(jj).ind).', ...
        data.plotNu_pv(1).res.StdUnc(runs(jj).ind).', ...
        data.stiffness(runs(jj).ind).Value.',...
        data.stiffness(runs(jj).ind).StdUnc.',...
        data.stiffness_dimless(runs(jj).ind).Value.',...
        data.stiffness_dimless(runs(jj).ind).StdUnc.',...
        cellstr(measID(runs(jj).ind).'),...
        data.gamma(runs(jj).ind).');

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


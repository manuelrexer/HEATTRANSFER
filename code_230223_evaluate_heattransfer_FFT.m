% code_230223_evaluate_heattransfer_FFT
% Code that determines the complex Nusselt number in the frequency domain
% from measurement data and  plot it afterwards
%
% created: Rexer 28.02.22
% last changes: 20.05.24
% Version: Disseration v1.0.1

%% clear workspace
clc
clearvars -except fig_Nu fig_NuPe fig_stiffness fig_stiffness_dimless fig_NuReIm

currentFileDir = fileparts(mfilename('fullpath'));
generated_files_path = [currentFileDir, '\', '_generated'];
generated_plots_path = [currentFileDir, '\', '_generated', '\', 'plots'];
generated_data_path = [currentFileDir, '\', '_generated', '\', 'data'];
generated_data_results_path = [currentFileDir, '\', '_generated', '\', 'data', '\', 'results'];


if ~exist(generated_files_path, 'dir')
    mkdir(generated_files_path);
end

if ~exist(generated_plots_path, 'dir')
    mkdir(generated_plots_path);
end

if ~exist(generated_data_path, 'dir')
    mkdir(generated_data_path);
end

if ~exist(generated_data_results_path, 'dir')
    mkdir(generated_data_results_path);
end

% __ FLAGS __
nusselt_plot_FLAG = true;
nusselt_bode_pecled_plot_FLAG = true;
nusselt_real_imag_peclet_plot_FLAG = true;

FFT_plot_FLAG = false;

stacked_uncertainty_plots_FLAG = false;
uncertainty_analyzation_plots_FLAG = false;

stiffness_plot_FLAG = true;
dimless_stiffness_plot_FLAG = true;
% Following flag only has an effect when the
% dimless_stiffness_plot_FLAG is turned on.
dimless_stiffness_plot__model_compare__FLAG = false; 

save_result_data_FLAG = false;
save_figures_FLAG = false;


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
runs = getMeasurementRuns(measureData);
selectedruns = selectRuns(runs);


[data, plotopts, testObj] = evaluate_heattransfer_FFT_function(measureData);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Nusselt Plots
% Plot Nusselt Number in Bode Plots depending on frequency.

% Initiate Nusselt figure.
if nusselt_plot_FLAG
    if exist ('fig_Nu', 'var')
        if isempty(fig_Nu.findobj)
            fig_Nu = figure('name','Nu(f)');
        end
    else
        fig_Nu = figure('name','Nu(f)');
    end
    
    % Plot selected runs in the Nusselt figure.
    for jj = selectedruns.runs
        % FIXME: Why that construct?
        for ii = 1
            fig_Nu = plotFreqResp(data.excitationFrequency(runs(jj).ind), data.plotNu_pv(ii).res(runs(jj).ind), fig_Nu,...
                'plottype', 'loglog', ...
                'ylabel', 'Nusselt', ...
                'phase', true, ...
                'plotOpts', plotopts);
        end
    end
    setfigpos(12.5,11.5,'m')
end


% Plot Nusselt Number in Bode Plots depending on Peclet number.
% Initiate Bode figure.
if nusselt_bode_pecled_plot_FLAG
    if exist('fig_NuPe', 'var')
        if isempty(fig_NuPe.findobj)
            fig_NuPe = figure('name','Nu(Pe)');
        end
    else
        fig_NuPe = figure('name','Nu(Pe)');
    end
    
    % Plot selected runs in the Bode figure.
    for jj = selectedruns.runs
        % FIXME: Why that construct?
        for ii = 1
            fig_NuPe = plotFreqResp(data.Pe(runs(jj).ind), data.plotNu_pv(ii).res(runs(jj).ind), fig_NuPe, ...
                'plottype', 'loglog', ...
                'ylabel', 'Nusselt', ...
                'ylim', [0.1,10^3],...
                'xlabel', 'Pe', ...
                'phase', true, ...
                'plotOpts', plotopts);
        end
    end
    setfigpos(12.5, 11.5, 'm')
end

% Plot Nusselt Number in real and imaginary part depending on peclet number
% Initiate peclet number figure.
if nusselt_real_imag_peclet_plot_FLAG
    if exist('fig_NuReIm', 'var')
        if isempty(fig_NuReIm.findobj)
            fig_NuReIm = figure('name','Real- and imag Part of Nusseltnumber');
            tiledlayout(1, 2, "Padding", "tight", "TileSpacing", "tight")
            publishfig
        end
    else
        fig_NuReIm = figure('name','Nu(Pe)');
        tiledlayout(1, 2, "Padding", "tight", "TileSpacing", "tight")
        publishfig
    end
    
    % Plot selected runs in the peclet number figure.
    for jj = selectedruns.runs
        figure(fig_NuReIm)
    
        ax1 = nexttile(1);
        plot(data.Pe(runs(jj).ind), real([data.plotNu_pv(1).res(runs(jj).ind)]))
        box off
        hold on
        ax1.XScale = 'log';
        ax1.YScale = 'log';
        xlabel('Pe')
        ylabel('Re(Nu)')
        ax2=nexttile(2);
        plot(data.Pe(runs(jj).ind), imag([data.plotNu_pv(1).res(runs(jj).ind)]))
        box off
        hold on
        ax2.XScale = 'log';
        ax2.YScale = 'log';
    end
    xlabel('Pe')
    ylabel('Im(Nu)')
end


%% FFT Plots
% Plots FFT plots of the volume and pressure into two new seperate figures.
if FFT_plot_FLAG
    % maginute volume
    % initiate figrue
    fig_FFT_volume = figure('Name','volume abs');
    % plots
    stem(data.volume(end).FFT.frequencies(1:end/2), abs(data.volume(end).FFT.value(1:end/2)), 'Marker', 'none')
    hold on
    plot(data.volume(end).FFT.frequencies(1:end/2), abs(data.volume(end).FFT.value(1:end/2)), "o", 'MarkerFaceColor', 'white', 'MarkerEdgeColor', 'black', 'MarkerSize', 4)
    box off
    ylabel('MAGNITUDE VOLUMEN')
    xlabel('FREQUENZ')
    xlim([0, 500])
    set(gca,'YScale', 'log')
    setfigpos(6.9, 6.9, 'm')

    % x = linspace(0, 2*pi, 100);
    % legend('sin(x)', 'cos(x)')

    publishfig

    % maginute pressure
    % initiate figrue
    fig_FFT_pressure = figure('Name','pressure abs');
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

%% Stacked Uncertainty Plots
% Plots the stacked uncertainty of the pressure and the volume into two new
% seperate figures.
if stacked_uncertainty_plots_FLAG
    % staced uncertainty plots of pressure
    fig_stacked_unc_pressure = figure('name','Uncertainty Pressure');
    fig_stacked_unc_pressure = plotUncFFTStacked(data.pressure(runs.ind), fig_stacked_unc_pressure);
    publishfig
    setfigpos(13.7,6.9,'m')
    % staced uncertatinty plot of volume
    fig_stacked_unc_volume = figure('name','Uncertainty volume');
    fig_stacked_unc_volume = plotUncFFTStacked(data.volume(runs.ind), fig_stacked_unc_volume);
    publishfig
    setfigpos(13.7,6.9,'m')
end

%% Analyzing all uncertatinty of all runs of pressure and volume signal.
% Plots 
if uncertainty_analyzation_plots_FLAG
    % Volume
    % initiate figure
    fig_unc_analyzation_volume_abs = figure('Name', 'volume abs');
    tiledlayout("flow", "TileSpacing", "compact")
    for ii = length(data.volume):-1:1
        nexttile

        stem(data.volume(ii).FFT.harmonic.frequencies, abs(data.volume(ii).FFT.harmonic.metas.Value))
        hold on
        errorbar(data.volume(ii).FFT.harmonic.frequencies, abs(data.volume(ii).FFT.harmonic.metas.Value), abs(data.volume(ii).FFT.harmonic.metas.StdUnc), 'LineStyle', 'none')
        box off
        ylim([0,0.00002])
    end

    fig_unc_analyzation_volume_phase = figure('Name','volume phase')
    tiledlayout("flow","TileSpacing","compact")
    for ii = length(data.volume):-1:1
        nexttile

        stem(data.volume(ii).FFT.harmonic.frequencies, phase(data.volume(ii).FFT.harmonic.metas.Value))
        hold on
        errorbar(data.volume(ii).FFT.harmonic.frequencies, phase(data.volume(ii).FFT.harmonic.metas.Value), phase(data.volume(ii).FFT.harmonic.metas.StdUnc),'LineStyle','none')
        box off
        ylim([-pi/2,pi/2])
    end

    % pressure
    fig_unc_analyzation_pressure_abs = figure('Name','pressure abs')
    tiledlayout("flow","TileSpacing","compact")
    for ii = length(data.pressure):-1:1
        nexttile
        stem(data.pressure(ii).FFT.harmonic.frequencies, abs(data.pressure(ii).FFT.harmonic.metas.Value))
        hold on
        errorbar(data.pressure(ii).FFT.harmonic.frequencies, abs(data.pressure(ii).FFT.harmonic.metas.Value), abs(data.pressure(ii).FFT.harmonic.metas.StdUnc), 'LineStyle', 'none')
        box off
        ylim([0,5])
    end

    % initiate figure
    fig_unc_analyzation_pressure_phase = figure('Name','pressure phase')
    tiledlayout("flow","TileSpacing","compact")
    for ii = length(data.pressure):-1:1
        nexttile
        stem(data.pressure(ii).FFT.harmonic.frequencies, phase(data.pressure(ii).FFT.harmonic.metas.Value))
        hold on
        errorbar(data.pressure(ii).FFT.harmonic.frequencies, phase(data.pressure(ii).FFT.harmonic.metas.Value), phase(data.pressure(ii).FFT.harmonic.metas.StdUnc), 'LineStyle', 'none')
        box off
        % ylim([0,5])
    end
end


%% Stiffness Plots
% Plot abolute stiffness in bode plot depending on frequency into its own
% figure.
if stiffness_plot_FLAG
    for jj = selectedruns.runs
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
    % legend('sin(x)', 'cos(x)')
    setfigpos(12.5,11.5,'m')
end

% Plot dimensionless stiffness in bode plot depending on Peclet number
% Inclunding models from Lee, Pelz and Rexer.
if dimless_stiffness_plot_FLAG
    for jj =selectedruns.runs
        try
            fig_stiffness_dimless = plotFreqResp(data.Pe(runs(jj).ind), data.stiffness_dimless(runs(jj).ind), fig_stiffness_dimless, ...
                'plottype', 'absolute', ...
                'ylabel', 'STEIFIGKEIT K^+', ...
                'xlabel', 'PECLET', ...
                'phase', true, ...
                'plotOpts', plotopts);
        catch
            fig_stiffness_dimless=figure('name','Dim.less Stiffness K+');
            fig_stiffness_dimless = plotFreqResp(data.Pe(runs(jj).ind), data.stiffness_dimless(runs(jj).ind), fig_stiffness_dimless, ...
                'plottype', 'absolute', ...
                'ylabel', 'STEIFIGKEIT K^+', ...
                'xlabel', 'PECLET', ...
                'phase', true, ...
                'plotOpts', plotopts);
        end

        % Include proposed models from Lee, Pelz and Rexer for comparison.
        if dimless_stiffness_plot__model_compare__FLAG
            fig_stiffness_dimless = plotFreqResp(data.Pe(runs(jj).ind), data.stiffness_dimless_fit(runs(jj).ind), fig_stiffness_dimless, 'plotOpts', {'-'}, 'plottype', 'absolute', 'ylabel', 'STEIFIGKEIT K^+', 'phase', true);
            fig_stiffness_dimless = plotFreqResp(data.Pe(runs(jj).ind), data.stiffness_dimless_Lee(runs(jj).ind), fig_stiffness_dimless, 'plotOpts', {'-'}, 'plottype', 'absolute', 'ylabel', 'STEIFIGKEIT K^+', 'phase', true);
            fig_stiffness_dimless = plotFreqResp(data.Pe(runs(jj).ind), data.stiffness_dimless_Pelz(runs(jj).ind), fig_stiffness_dimless, 'plotOpts', {'-'}, 'plottype', 'absolute', 'ylabel', 'STEIFIGKEIT K^+', 'phase', true);
        end
    end
    setfigpos(12.5, 11.5, 'm')
end

%% Save figures.
% Possible figures:
% fig_Nu
% fig_NuPe
% fig_NuReIm
% fig_FFT_volume
% fig_FFT_pressure
% fig_stacked_unc_pressure
% fig_stacked_unc_volume
% fig_unc_analyzation_volume_abs
% fig_unc_analyzation_volume_phase
% fig_unc_analyzation_pressure_abs
% fig_unc_analyzation_pressure_phase
% fig_stiffness
% fig_stiffness_dimless

% if save_figures_FLAG
%    if exist('fig_Nu', 'var')
%        saveas(fig_Nu, 'fig_Nu.pdf', 'pdf');
%    end
% 
% end

%% Arange and save Data
if save_result_data_FLAG
    for ii = length(measureData):-1:1
        % get measurement IDs
        % if it doesnt exist add a number
        if isfield(measureData(ii).METADATA, 'measurement_UUID')
            measID{ii} = [measureData(ii).METADATA.measurement_UUID];
        else
            measID{ii} = num2str(ii);
        end
    end
    
    for jj = length(runs):-1:1
        % get Run name
        exp = table(data.excitationFrequency(runs(jj).ind).',...
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
    
        exp.Properties.VariableNames(1) = {'f0'};
        exp.Properties.VariableDescriptions(1) = {'Ecxitation Frequency'};
        exp.Properties.VariableUnits(1) = {'HZ'};
        exp.Properties.VariableNames(2) = {'Pe'};
        exp.Properties.VariableDescriptions(2) = {'Pclet Number'};
        exp.Properties.VariableUnits(2) = {'UNITLESS'};
        exp.Properties.VariableNames(3) = {'Nu'};
        exp.Properties.VariableDescriptions(3) = {'Nusselt Number'};
        exp.Properties.VariableUnits(3) = {'UNITLESS'};
        exp.Properties.VariableNames(4) = {'Nu_StdUnc'};
        exp.Properties.VariableDescriptions(4) = {'95-percent uncertainty of the Nusselt number'};
        exp.Properties.VariableUnits(4) = {'UNITLESS'};
        exp.Properties.VariableNames(5) = {'K'};
        exp.Properties.VariableDescriptions(5) = {'Stiffness'};
        exp.Properties.VariableUnits(5) = {'BAR-PER-M3'};
        exp.Properties.VariableNames(6) = {'K_StdUnc'};
        exp.Properties.VariableDescriptions(6) = {'95-percent uncertainty of the Stiffness'};
        exp.Properties.VariableUnits(6) = {'BAR-PER-M3'};
        exp.Properties.VariableNames(7) = {'K+'};
        exp.Properties.VariableDescriptions(7) = {'Dimensionless Stiffness'};
        exp.Properties.VariableUnits(7) = {'UNITLESS'};
        exp.Properties.VariableNames(8) = {'K+_StdUnc'};
        exp.Properties.VariableDescriptions(8) = {'95-percent uncertainty of the Dimensionless Stiffness'};
        exp.Properties.VariableUnits(8) = {'UNITLESS'};
        exp.Properties.VariableNames(9) = {'Measurement_UUID'};
        exp.Properties.VariableNames(10) = {'gamma'};
        exp.Properties.VariableDescriptions(10) = {'Isentropic Exponent'};
        exp.Properties.VariableUnits(10) = {'UNITLESS'};
    
        exp.Properties.CustomProperties.TestObject = testObj;
        exp.Properties.CustomProperties.zAmp = runs(jj).amplitude;
        exp.Properties.CustomProperties.Ta = runs(jj).temperature;
        exp.Properties.CustomProperties.p0 = runs(jj).p0;
        exp.Properties.CustomProperties.p1 = runs(jj).p1;
    
        exp.Properties.Description = [testObj,'_',...
            num2str(runs(jj).amplitude), '_mm_',...
            num2str(runs(jj).temperature), '_C_p0_',...
            num2str(runs(jj).p0), '_bar_p1_',...
            num2str(runs(jj).p1), '_bar' ];
   
        % Save the results as .mat
        save([generated_data_results_path, exp.Properties.Description,'.mat'], 'exp')
    end
end


% code_230223_evaluate_heattransfer_FFT
% Code that determines the complex Nusselt number in the frequency domain
% from measurement data and  plot it afterwards
%
% created: Rexer 28.02.22
% last changes: 20.05.24
% Version: Disseration v1.0.1

%% clear workspace
clc
clearvars -except fig_Nu fig_NuPe fig_NuReIm fig_FFT_volume fig_FFT_pressure fig_stacked_unc_pressure fig_stacked_unc_volume fig_unc_analyzation_volume_abs fig_unc_analyzation_volume_phase fig_unc_analyzation_pressure_abs fig_unc_analyzation_pressure_phase fig_stiffness fig_stiffness_dimless

%% Read in the measurement data.
% current directory
cd0=cd();
try
    cd()
    measureData = getMeasureData();
    cd(cd0)
catch
    cd(cd0)
end
% Select a run from the Dataset.
runs = getMeasurementRuns(measureData);
selectedruns = selectRuns(runs);


%% Evaluate the selected data.
[data, plotopts, testObj] = evaluate_heattransfer_FFT_function(measureData);


%% Run the plotting script.
plot_evaluate_heattransfer_FFT


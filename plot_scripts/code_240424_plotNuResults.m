% Code that plots  measured Nusselt numbers
%
% created: Rexer 01.05.2024
% last changes: 20.05.24

%% Initiation
clear
cd0=cd();
unc=@LinProp;

%% Load Data
try
    [filenames, dataPath, ~] = uigetfile( ...
        '.mat', 'Select MAT-files (*.mat)', ...
        'C:\Users\rexer\Documents\MATLAB\heattransfer\test_data\Results', ...
        'MultiSelect', 'on');
     if ischar(filenames)
        filePaths{1}=[dataPath,'/',filenames];
    else
        for ii=1:length(filenames)
            filePaths{ii}=[dataPath,'/',filenames{ii}];
        end
    end
    nFiles = length(filePaths);
    for ii =1:nFiles
        % Reading the data
        res{ii}=load(filePaths{ii});
    end

    cd(cd0)
catch e
    cd(cd0)
    e.rethrow
end

%% Plot
% initiate figure
if exist('fig_NuPe', 'var')
    if isempty(fig_NuPe.findobj)
        fig_NuPe=figure('name','Nu(Pe)');
    end
else
    fig_NuPe=figure('name','Nu(Pe)');
end
% get marker information
for ii = length(res):-1:1
    switch res{ii}.exp.Properties.CustomProperties.TestObject
        case 'Accumulator_1.3l'
            %accumulator 1,3l
            plotopts={'.','Markersize',15};
        case 'Accumulator_0.6l'
            %accumulator 0.6l
            plotopts={'.','Markersize',12};
        case 'Accumulator_0.1l'
            %accumulator 0.1l
            plotopts={'.','Markersize',9};
        case 'airspring'
            %airspring
            plotopts={'d','Markersize',4};
        case 'cylinder'
            %cylinder
            plotopts={'s','Markersize',4};
        otherwise
            plotopts={'-'};
    end
    % generate uncertainty array
    for jj=length(res{ii}.exp.Nu_StdUnc):-1:1
    res{ii}.exp.Nu_metas(jj)=unc(res{ii}.exp.Nu(jj), ...
        diag([real(res{ii}.exp.Nu_StdUnc(jj)).^2,imag(res{ii}.exp.Nu_StdUnc(jj)).^2]));
    end
    % plot
    fig_NuPe = plotFreqResp( ...
        res{ii}.exp.Pe,res{ii}.exp.Nu_metas, ...
        fig_NuPe, ...
        'plottype','loglog', ...
        'ylabel','Nusselt', ...
        'ylimits', [0.1,10^4],...
        'flimits',[1,10^5],...
        'xlabel','Pe', ...
        'phase',true, ...
        'plotOpts',plotopts);

    % Plot real and imaginary part
% initiate figure
if exist('fig_ReIm', 'var')
    if isempty(fig_ReIm.findobj)
        fig_ReIm=figure('name','Real- and imag Part of Nusseltnumber');
        tiledlayout(1,2,'TileSpacing','tight','Padding','tight')
        publishfig
    end
else
    fig_ReIm=figure('name','Real- and imag Part of Nusseltnumber');
    tiledlayout(1,2,'TileSpacing','tight','Padding','tight')
    publishfig
end
% plot
    figure(fig_ReIm)
    
    ax1=nexttile(1);
    hold on
    plot(res{ii}.exp.Pe,real(res{ii}.exp.Nu), plotopts{:}, ...
        'MarkerFaceColor','white', ...
        'MarkerEdgeColor','black')
    box off
    ax1.XScale='log';
    ax1.YScale='log';
    xlabel('Pe')
    ylabel('Re(Nu)')
    decades_equal(gca,[1e0,1e5],[1e-1,1e4])
    ax2=nexttile(2);
    hold on
    plot(res{ii}.exp.Pe,imag(res{ii}.exp.Nu), plotopts{:}, ...
        'MarkerFaceColor','white', ...
        'MarkerEdgeColor','black')
    box off
    ax2.XScale='log';
    ax2.YScale='log';
    xlabel('Pe')
    ylabel('Im(Nu)')
    decades_equal(gca,[1e0,1e5],[1e-1,1e4])

% Plot Real and Imaginary Part with errorbars
% initiate figure
if exist('fig_ReIm_Unc', 'var')
    if isempty(fig_ReIm_Unc.findobj)
        fig_ReIm_Unc=figure('name','Real- and imag Part of Nusseltnumber');
        tiledlayout(1,2,'TileSpacing','tight','Padding','tight')
        publishfig
    end
else
    fig_ReIm_Unc=figure('name','Real- and imag Part of Nusseltnumber');
    tiledlayout(1,2,'TileSpacing','tight','Padding','tight')
    publishfig
end
clear ynegReal yposReal ynegImag yposImag
% plot
for jj=length(res{ii}.exp.Nu):-1:1
        if real(res{ii}.exp.Nu(jj))-real(res{ii}.exp.Nu_StdUnc(jj))<0.01
            ynegReal(jj)=real(res{ii}.exp.Nu(jj))-0.01;
        else
            ynegReal(jj) = real(res{ii}.exp.Nu_StdUnc(jj));
        end
        yposReal(jj) = real(res{ii}.exp.Nu_StdUnc(jj));
        if imag(res{ii}.exp.Nu(jj))-imag(res{ii}.exp.Nu_StdUnc(jj))<0.01
            ynegImag(jj)=imag(res{ii}.exp.Nu(jj))-0.01;
        else
            ynegImag(jj) = imag(res{ii}.exp.Nu_StdUnc(jj));
        end
        yposImag(jj) = imag(res{ii}.exp.Nu_StdUnc(jj));
end

    figure(fig_ReIm_Unc)
    
    ax1=nexttile(1);
    hold on
    errorbar(res{ii}.exp.Pe,real(res{ii}.exp.Nu),ynegReal,yposReal, plotopts{:}, ...
        'MarkerFaceColor','white')
    box off
    ax1.XScale='log';
    ax1.YScale='log';
    xlabel('Pe')
    ylabel('Re(Nu)')
    decades_equal(gca,[1e0,1e5],[1e-1,1e4])
    ax2=nexttile(2);
    hold on
    errorbar(res{ii}.exp.Pe,imag(res{ii}.exp.Nu),ynegImag,yposImag, plotopts{:}, ...
        'MarkerFaceColor','white'  )
    box off
    ax2.XScale='log';
    ax2.YScale='log';
    xlabel('Pe')
    ylabel('Im(Nu)')
    decades_equal(gca,[1e0,1e5],[1e-1,1e4])


end

figure(fig_ReIm)
setfigpos(13.7,6.9,'m')

%% Generate Models
% Peclet number
Pe= logspace(-3,5,100);

% Lee model
z=(1+1i).*sqrt(Pe/2);
Nu.Lee=sqrt(Pe/2).*((1+1i).*tanh(z))./(1-tanh(z)./z);

Pe=Pe*4;
% Kornhauser
Nu.Korn=(1+1i)*0.56*Pe.^(0.69);
%Lekic
Nu.Lekic=(1.33*Pe.^(0.56) + 5.36) + 1i*(2.04*Pe.^(0.46) - 1.46);
Pe=Pe/4;

fnames=fieldnames(Nu);
for ii=1:length(fnames)
    nexttile(1)
    loglog(Pe,real(Nu.(fnames{ii})))
    box off
    hold on
    nexttile(2)
    loglog(Pe,imag(Nu.(fnames{ii})))
    hold on
    box off
end
% resize figure
figure(fig_NuPe)
setfigpos(12.5,10.3,'m')
T=fig_NuPe.Children;
T=T(3);
T.Padding='tight';
T.TileSpacing='compact';

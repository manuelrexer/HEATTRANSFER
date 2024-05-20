
clear
cd0=cd();
unc=@LinProp;
Pe=[];
NuReal=[];
NuImag=[];
NuUncReal=[];
NuUncImag=[];
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

%         Pe=[Pe;res{ii}.exp.Pe];
%         NuReal=[NuReal;real(res{ii}.exp.Nu)];
%         NuImag=[NuImag;imag(res{ii}.exp.Nu)];
%         NuUncReal=[NuUncReal;real(res{ii}.exp.Nu_StdUnc)];
%         NuUncImag=[NuUncImag;imag(res{ii}.exp.Nu_StdUnc)];

        inds=[1:7 9 15 25 29];
        while inds(end)>length(res{ii}.exp.Pe)
            inds=inds(1:end-1);
        end
        Pe=[Pe;res{ii}.exp.Pe([inds])];
        NuReal=[NuReal;real(res{ii}.exp.Nu([inds]))];
        NuImag=[NuImag;imag(res{ii}.exp.Nu([inds]))];
        NuUncReal=[NuUncReal;real(res{ii}.exp.Nu_StdUnc([inds]))];
        NuUncImag=[NuUncImag;imag(res{ii}.exp.Nu_StdUnc([inds]))];
    end

    cd(cd0)
catch e
    cd(cd0)
    e.rethrow
end
%% Fit without clearance

inds=find(NuImag<=0);
NuImag_cleared=NuImag(NuImag>0);
PeImag=Pe;
PeImag(inds)=[];

[fitresult_all, gof_all] = createFits(Pe, NuReal, PeImag, NuImag_cleared);


%% Plots

for ii = length(res):-1:1
    switch res{ii}.exp.Properties.CustomProperties.TestObject
        case 'Accumulator_1.3l'
            %accumulator 1,3l
            plotopts={'.k','Markersize',15};
        case 'Accumulator_0.6l'
            %accumulator 0.6l
            plotopts={'.k','Markersize',12};
        case 'Accumulator_0.1l'
            %accumulator 0.1l
            plotopts={'.k','Markersize',9};
        case 'airspring'
            %airspring
            plotopts={'dk','Markersize',4};
        case 'cylinder'
            %cylinder
            plotopts={'sk','Markersize',4};
        otherwise
            plotopts={'-'};
    end

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

    decades_equal(gca,[1e0,1e5],[1e-1,1e4])

end

figure(fig_ReIm)
setfigpos(13.7,6.9,'m')
nexttile(1)
plot(fitresult_all{1})
box off
hold on
xlabel('Pe')
ylabel('Re(Nu)')
nexttile(2)
plot(fitresult_all{2})
xlabel('Pe')
ylabel('Im(Nu)')
hold on
box off

disp(['Realpart: a=',num2str(fitresult_all{1}.a),' b=',num2str(fitresult_all{1}.b),' c=',num2str(fitresult_all{1}.c),' d=',num2str(fitresult_all{1}.d),' e=',num2str(fitresult_all{1}.e)])
disp(['Imagpart: a=',num2str(fitresult_all{2}.a),' b=',num2str(fitresult_all{2}.b)])




inds=find(NuReal<NuUncReal);
NuRealCleared=NuReal;
NuRealCleared(inds)=[];
PeReal=Pe;
PeReal(inds)=[];
% inds=find(NuImag<=0);
% NuImag_cleared=NuImag(NuImag>0);
inds=find(NuImag<NuUncImag);
NuImag_cleared=NuImag;
NuImag_cleared(inds)=[];
PeImag=Pe;
PeImag(inds)=[];

[fitresult_cleared, gof_cleared] = createFits(PeReal, NuRealCleared, PeImag, NuImag_cleared);

if exist('fig_ReIm_clear', 'var')
    if isempty(fig_ReIm_clear.findobj)
        fig_ReIm_clear=figure('name','Model Cleared');
        tiledlayout(1,2,'TileSpacing','tight','Padding','tight')
        publishfig
    end
else
    fig_ReIm_clear=figure('name','Model Cleared');
    tiledlayout(1,2,'TileSpacing','tight','Padding','tight')
    publishfig
end

figure(fig_ReIm_clear)

ax1=nexttile(1);
hold on
plot(PeReal,NuRealCleared, '.k', ...
    'MarkerFaceColor','white', ...
    'MarkerEdgeColor','black', ...
    'MarkerSize',12)
box off
ax1.XScale='log';
ax1.YScale='log';
decades_equal(gca,[1e0,1e5],[1e-1,1e4])
ax2=nexttile(2);
hold on
plot(PeImag,NuImag_cleared, '.k', ...
    'MarkerFaceColor','white', ...
    'MarkerEdgeColor','black', ...
    'MarkerSize',12)
box off
ax2.XScale='log';
ax2.YScale='log';

decades_equal(gca,[1e0,1e5],[1e-1,1e4])

setfigpos(13.7,6.9,'m')
nexttile(1)
plot(fitresult_cleared{1})
box off
hold on
xlabel('Pe')
ylabel('Re(Nu)')
nexttile(2)
plot(fitresult_cleared{2})
xlabel('Pe')
ylabel('Im(Nu)')
hold on
box off

disp(['Realpart: a=',num2str(fitresult_cleared{1}.a),' b=',num2str(fitresult_cleared{1}.b),' c=',num2str(fitresult_cleared{1}.c),' d=',num2str(fitresult_cleared{1}.d),' e=',num2str(fitresult_cleared{1}.e)])
disp(['Imagpart: a=',num2str(fitresult_cleared{2}.a),' b=',num2str(fitresult_cleared{2}.b)])
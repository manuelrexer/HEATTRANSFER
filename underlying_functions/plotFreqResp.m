function [fig] = plotFreqResp(vFreqs,vH,fig,varargin)
% plots frequency response in a figure object
% author: Manuel Rexer
% last adaption: 21.05.24
%
% inputs:
% vFreqs: frequency array
% vH: complex value array also pasible as Metas array to plot uncertainty
% fig: figure object
% varargin: Plot options
%
% Outputs:
% fig: figure object

%% Input adaption
p = inputParser;
% addOptional(p, 'figure', figure());
addOptional(p, 'plottype', 'loglog');
addOptional(p,'decades_equal', false);
addOptional(p, 'phase', false );
addOptional(p, 'xlabel', 'FREQUENZ in Hz');
addOptional(p, 'ylabel', '|H|');
addOptional(p, 'flimits', []);
addOptional(p, 'ylimits', []);
addOptional(p, 'plotOpts',{'s-'})
parse(p, varargin{:})

type = p.Results.plottype;
% fig=p.Results.figure;
% pubflishfig
% name=['Übertragungsfunktion: ', input.inputname,' nach ' , input.outputname]
xlimits=p.Results.flimits;
ylimits=p.Results.ylimits;
fLabel=p.Results.xlabel;
yLabel=p.Results.ylabel;
plotOpts=p.Results.plotOpts;
decades_equ = p.Results.decades_equal;
plotphase=p.Results.phase;


% check if there are unc values
metas=isa(vH,'LinProp');
if metas
    for ii=length(vH):-1:1
        if abs(vH(ii).Value)-abs(vH(ii).StdUnc)<0.01
            yneg(ii)=abs(vH(ii).Value)-0.01;
        else
            yneg(ii) = abs(vH(ii).StdUnc);
        end
        ypos(ii) = abs(vH(ii).StdUnc);
    end
end
rows=1;
if plotphase
    rows=rows+1;
end

%% plot frequencies
% initiate figure
figure(fig)
ch=get(fig,'Children');
createTiles=true;
for ii=length(ch):-1:1
    if contains(class(ch(ii)),'TiledChartLayout')
        createTiles=false;
    end
end
if createTiles
    tiledlayout(rows,1,"TileSpacing","compact","Padding","tight")
end
ax=nexttile(1);
hold on
box off
% plot
if metas
    errorbar(vFreqs, abs(vH.Value), yneg , ypos,plotOpts{:},'MarkerFaceColor','white')
else
    plot(vFreqs, abs(vH), plotOpts{:},'MarkerFaceColor','white')
end
hold on
box off
ax.XScale='log';
% rescale
switch type
    case 'loglog'
        ax.YScale='log';
        if decades_equ
            decades_equal(gca)
        end
end
% labels
ylabel(yLabel)
if ~plotphase
    xlabel(fLabel)
end
publishfig


if ~isempty(xlimits) && ~isempty(ylimits)
    if decades_equ
        decades_equal(gca,xlimits,ylimits)
    else
        xlim(xlimits)
        ylim(ylimits)
    end
elseif ~isempty(xlimits)
    xlim(xlimits)
elseif ~isempty(ylimits)
    ylim(ylimits)
end

% plot phase if needed
if plotphase
    ax2=nexttile(2);
    hold on
    box off
    if metas
        deg=rad2deg(angle(vH.Value));
        errorbar(vFreqs, deg, rad2deg(angle(vH.StdUnc)),plotOpts{:},'MarkerFaceColor','white')
    else
        deg=rad2deg(angle(vH));
        plot(vFreqs, deg,plotOpts{:},'MarkerFaceColor','white')
    end
    hold on
    box off
    ax2.XScale='log';
    hold on
    box off
    ylabel('PHASENWINKEL in °');
    xlabel(fLabel);

    if ~isempty(xlimits)
        xlim(xlimits)
    end
end
end
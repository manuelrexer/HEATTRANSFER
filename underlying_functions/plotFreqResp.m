function [fig] = plotFreqResp(vFreqs,vH,fig,varargin)

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
parse(p, varargin{:})

type = p.Results.plottype;
% fig=p.Results.figure;
% pubflishfig
% name=['Übertragungsfunktion: ', input.inputname,' nach ' , input.outputname]
xlimits=p.Results.flimits;
ylimits=p.Results.ylimits;
fLabel=p.Results.xlabel;
yLabel=p.Results.ylabel;
decades_equ = p.Results.decades_equal;
plotphase=p.Results.phase;

%% Frequenzgang plotten

switch type

    case 'db'
        figure(fig)
        if plotphase
            subplot(2, 1, 1);
        end
        semilogx(vFreqs, db(abs(vH)), 's-');
        hold on
        box off
        ylabel('|H| in db');

        title(name);
        publishfig

    case 'loglog'
        figure(fig)

        if plotphase
            subplot(2, 1, 1);
        end

        loglog(vFreqs, abs(vH), 's-');
        hold on
        box off
        if decades_equ
            decades_equal(gca)
        end
        ylabel(yLabel)
        xlabel(fLabel)
        %         title(name);
        publishfig

    case 'absolute'

        figure(fig)
        box off
        if plotphase
            subplot(2, 1, 1);
        end
        semilogx(vFreqs, (abs(vH)), 's-');

        hold on

        ylabel(yLabel)
        xlabel(fLabel)
        %         title(name);
        box off
        publishfig


end

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
if plotphase
    deg=rad2deg(angle(vH));

    if deg<0
        deg=deg+360;
    end
    subplot(2, 1, 2);
    semilogx(vFreqs, deg, 's-');
    hold on
    box off
    ylabel('PHASENWINKEL in °');
    xlabel('FREQUENZ f in Hz');
    if ~isempty(xlimits)
        xlim(xlimits)
    end
end
end
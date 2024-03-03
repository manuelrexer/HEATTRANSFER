function [fig] = plotFreqResp(vFreqs,vH,input,fig)

% Benennung
if nargin>3 && isfield(input, 'inputname') && isfield(input, 'outputname')
    name=['Übertragungsfunktion: ', input.inputname,' nach ' , input.outputname];
else
    name=[];
end

% Plotart auswählen
if nargin>3 && isfield(input, 'type')
    type = input.type;
else
    type = 'loglog';
end

% loglog gleich skallieren
if nargin>3 && isfield(input, 'decades_equal')
    decades_equ = input.decades_equal;
else
    decades_equ = false;
end

if nargin>3 && isfield(input, 'flimits')
    xlimits=input.flimits;
end
if nargin>3 && isfield(input, 'ylimits')
    ylimits=input.ylimits;
end

if nargin <4
    fig=figure('name', ['Frequenzgang: ', type],'NumberTitle','off');
    publishfig
end
%% Frequenzgang plotten



switch type

    case 'db'
        figure(fig)

%         subplot(2, 1, 1);
        semilogx(vFreqs, db(abs(vH)), 's-');
        hold on
        box off
        ylabel('|H| in db');

        title(name);
        publishfig

    case 'loglog'
        figure(fig)

%         subplot(2, 1, 1);

        loglog(vFreqs, abs(vH), 's-');
        hold on
        box off
        if decades_equ
            decades_equal(gca)
        end
        ylabel('|H|');

        title(name);
        publishfig
        
    case 'absolute'

        figure(fig)
        box off
%         subplot(2, 1, 1);
        semilogx(vFreqs, (abs(vH)), 's-');
        
        hold on
        
        
        
        xlabel(input.xlabel);
        ylabel(input.ylabel);

        title(name);
        box off
        publishfig
        

end

if exist("xlimits") && exist("ylimits")
    if decades_equ
        decades_equal(gca,xlimits,ylimits)
    else
        xlim(xlimits)
        ylim(ylimits)
    end
elseif exist("xlimits")
    xlim(xlimits)
elseif exist("ylimits")
    ylim(ylimits)
end

% deg=rad2deg(angle(vH));
% 
% if deg<0
%     deg=deg+360;
% end
% subplot(2, 1, 2);
% semilogx(vFreqs, deg, 's-');
% hold on
% box off
% ylabel('PHASENWINKEL in °');
% xlabel('FREQUENZ f in Hz');
% if exist("xlimits")
%     xlim(xlimits)
% end

end
% Version vom 13/07/2016
function publishfig(typ)

if nargin==1 && strcmp(typ,'all')==1
    figHandles = get(0,'Children');
else
    figHandles=gcf;
end



for ii=1:length(figHandles)
    set(0, 'currentfigure', figHandles(ii));  %# for figures
   toolbar = findall(gcf,'Type','uitoolbar');
    
    if isempty(findall(gcf,'Label','Publish')) && ~isempty(toolbar)
        menuhandle = uimenu('Label','Publish');
        
        uimenu(menuhandle,'Label','Set size','Callback','setfiguresize','Separator','off');
        uimenu(menuhandle,'Label','Save as .pdf (.eps, .jpg, ...)','Callback','publishfigfunc(1,0,0,0,0)','Separator','on','Accelerator','E');
        uimenu(menuhandle,'Label','Save data as .mat','Callback','publishfigfunc(0,0,0,1,0)','Separator','off','Accelerator','D');
        uimenu(menuhandle,'Label','Save as .pdf (.eps, .jpg, ...) + open','Callback','publishfigfunc(1,1,0,0,0)','Separator','off','Accelerator','O');
        uimenu(menuhandle,'Label','Save as .fig. & .pdf (.eps, .jpg, ...) + open','Callback','publishfigfunc(1,1,1,0,0)','Separator','off','Accelerator','F');
        uimenu(menuhandle,'Label','Save as .fig & .mat & .pdf (.eps, .jpg, ...) + open','Callback','publishfigfunc(1,1,1,1,0)','Separator','off','Accelerator','A');
        uimenu(menuhandle,'Label','Save as .fig & .mat & .pdf (.eps, .jpg, ...) & Tex-File+ open','Callback','publishfigfunc(1,1,1,1,1)','Separator','off','Accelerator','B');
        uimenu(menuhandle,'Label','Copy Figure To PowerPoint','Callback','figtopptfunc','Separator','off','Accelerator','P');

        allAxesInFigure = findall(figHandles(ii),'type','axes');
        
        for jj=1:length(allAxesInFigure)
            hax=allAxesInFigure(jj);
            hcmenu = uicontextmenu;
            % Define callbacks for context menu items that change linestyle
            hcb1 = ['set(gco, ''LineStyle'', ''--'')'];
            hcb2 = ['set(gco, ''LineStyle'', '':'')'];
            hcb3 = ['set(gco, ''LineStyle'', ''-'')'];
            hcb4 = ['set(gco, ''Color'', [0 0 0])'];
            hcb5 = ['set(gco, ''Color'', [0.43 0.43 0.43])'];
            hcb6 = ['set(gco, ''Color'', [0.74 0.74 0.74])'];
            hcb7 = ['set(gco, ''XData'', [], ''YData'', []),drawnow()'];
            
            % set(hline, 'XData', [], 'YData', [])
            % Define the context menu items and install their callbacks
            item1 = uimenu(hcmenu, 'Label', 'gestrichelt', 'Callback', hcb1);
            item2 = uimenu(hcmenu, 'Label', 'gepunktet', 'Callback', hcb2);
            item3 = uimenu(hcmenu, 'Label', 'durchgezogen',  'Callback', hcb3);
            item4 = uimenu(hcmenu, 'Label', 'schwarz',  'Callback', hcb4,'Separator','on');
            item5 = uimenu(hcmenu, 'Label', 'dunkelgrau',  'Callback', hcb5);
            item6 = uimenu(hcmenu, 'Label', 'hellgrau',  'Callback', hcb6);
            item6 = uimenu(hcmenu, 'Label', 'LÖSCHEN',  'Callback', hcb7,'Separator','on');
            % Locate line objects
            % hax = axes;
            hlines = findall(hax,'Type','line');
            % Attach the context menu to each line
            for line = 1:length(hlines)
                set(hlines(line),'uicontextmenu',hcmenu)
            end
            
        end
        box off
        
    end
    
    
end

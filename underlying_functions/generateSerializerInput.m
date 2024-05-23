function [] = generateSerializerInput(t,path)
%generateSerializerInput 
%
% created by Manuel Rexer 05.2024

%% Generate .csv 
writetable(t,[path,'\plotData.csv'])

%% Generate general json
s.dcTermsCreator=["Rexer, Manuel","https://orcid.org/0000-0003-0559-1156"];
s.EvaluationSoftwareDOI="10.5281/zenodo.11237089";
s.Description=t.Properties.Description;

fid=fopen([path,'\mainInfo.json'],'w');
encodedJSON = jsonencode(s,"PrettyPrint",true); 
fprintf(fid, encodedJSON); 
fclose (fid);
%% Generate axis jsons
[~,colnum]=size(t);
for ii=1:colnum
ax.Name = t.Properties.VariableNames{ii};
ax.Description = t.Properties.VariableDescriptions{ii};
ax.Unit = t.Properties.VariableUnits{ii};

if contains(ax.Description,'%')
    ax.Description = strrep(ax.Description,'%','-Percent');
end
if contains(ax.Description,'é')
    ax.Description = strrep(ax.Description,'é','e');
end
fid=fopen([path,'\',ax.Name,'.json'],'w');
encodedJSON = jsonencode(ax,"PrettyPrint",true); 
fprintf(fid, encodedJSON); 
fclose (fid);
clear ax
end
end
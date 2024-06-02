function selectedfields = getSelectedFields(struct,varargin)
% Selection of the fields to be evaluated 
% 
% created: Rexer 01.2022

if nargin==2
    message=varargin{1};
else
    message='Select field to evaluate:';
end
fields=fieldnames(struct);
[indx,~] = listdlg('PromptString',message,'ListString',fields);
selectedfields=fields(indx);
end
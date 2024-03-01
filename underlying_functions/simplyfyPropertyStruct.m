function [simple] = simplyfyPropertyStruct(input)
%implyfyPropertyStruct extracts important information from RDF Data
%structure
%   Author Manuel Rexer 01.03.2024
simple.value = input.value.literal;
unit=fieldnames(input.unit);
for ii=1:length(unit)
    if strcmp(unit{ii}, 'prefix')
        unit{ii}=[];
    end
end
 unit=unit(~cellfun('isempty',unit));
 if length(unit)==1
    simple.unit = unit{1};
 else
     simple.unit = unit;
 end
simple.Accuracy = input.Accuracy.literal;
simple.symbol = input.symbol.literal;
end
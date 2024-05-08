
clear
cd0=cd();
unc=@LinProp;
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


Pe= logspace(-3,5,100);

Pe=Pe/4;

% Lee
z=(1+1i).*sqrt(Pe/8);
Nu.Lee=sqrt(Pe*2).*((1+1i).*tanh(z))./(1-tanh(z)./z);
% Kornhauser
Nu.Korn=(1+1i)*0.56*Pe.^(0.69);
%Lekic
Nu.Lekic=(1.33*Pe.^(0.56) + 5.36) + 1i*(2.04*Pe.^(0.46) - 1.46);
Pe=Pe*4;
Nu.Pelz=3

Nu.Rexer=0.001*Pe.^1.3+3+1i*0.08*Pe.^0.78;

%% Plots

for ii = length(res):-1:1
    switch res{ii}.exp.Properties.CustomProperties.TestObject
        case 'Accumulator_1.3l'
            %accumulator 1,3l
            plotopts={'o','Markersize',5};
        case 'Accumulator_0.6l'
            %accumulator 0.6l
            plotopts={'o','Markersize',4};
        case 'Accumulator_0.1l'
            %accumulator 0.1l
            plotopts={'o','Markersize',3};
        case 'airspring'
            %airspring
            plotopts={'d','Markersize',4};
        case 'cylinder'
            %cylinder
            plotopts={'s','Markersize',4};
        otherwise
            plotopts={'-'};
    end

    if exist('fig_stiffness', 'var')
        if isempty(fig_stiffness.findobj)
          fig_stiffness=figure('name','Real- and imag Part of Nusseltnumber');
          publishfig
        end
    else
        fig_stiffness=figure('name','Real- and imag Part of Nusseltnumber');
        publishfig
    end

    figure(fig_stiffness)
    hold on
    semilogx(res{ii}.exp.Pe,abs(res{ii}.exp.("K+")), plotopts{:})
    box off
       xlabel('Pe')
    ylabel('abs(K+)')
     
end

setfigpos(13.7,6.9,'m')

fnames=fieldnames(Nu);
gamma=1.4;
for ii = 1:length(fnames)
    Nutemp=Nu.(fnames{ii})
    K.(fnames{ii})=-(Pe*gamma-1i*Nutemp*gamma)./(Pe-1i*Nutemp*gamma);
end
semilogx(Pe,abs(K.Rexer))
set(gca,'XScale','log')

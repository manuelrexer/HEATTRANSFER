
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

        gamma(ii)=res{ii}.exp.gamma(1);
    end

    cd(cd0)
catch e
    cd(cd0)
    e.rethrow
end


Pe= logspace(-3,5,100);

% Lee
z=(1+1i).*sqrt(Pe/2);
Nu.Lee=sqrt(Pe/2).*((1+1i).*tanh(z))./(1-tanh(z)./z);

Pe=Pe*4;
% Kornhauser
Nu.Korn=(1+1i)*0.56*Pe.^(0.69);
%Lekic
Nu.Lekic=(1.33*Pe.^(0.56) + 5.36) + 1i*(2.04*Pe.^(0.46) - 1.46);
Pe=Pe/4;

Nu.Pelz=3;
%LAR
% Nu.Rexer=4.99+1.3145*Pe.^(0.46)+6.2845e-5*Pe.^(1.746) + 1i*0.1518*Pe.^(0.94);
% Nu.Rexer=1.854+5.25*Pe.^(0.227)+0.00017576*Pe.^(1.59) + 1i*0.26112*Pe.^(0.7586);
% No robust fitt
Nu.Rexer=5.3221+1.1829*Pe.^(0.5)+3.4594e-5*Pe.^(1.8) + 1i*0.23197*Pe.^(0.87616);
% Nu.Rexer=13.3+0.45*Pe.^(0.227)+9.23e-5*Pe.^(1.67) + 1i*0.23197*Pe.^(0.876);
%% Plots

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

    if exist('fig_stiffness', 'var')
        if isempty(fig_stiffness.findobj)
          fig_stiffness=figure('name','Real- and imag Part of Nusseltnumber');
          publishfig
        end
    else
        fig_stiffness=figure('name','Real- and imag Part of Nusseltnumber');
        publishfig
    end

    for jj=length(res{ii}.exp.Nu_StdUnc):-1:1
    res{ii}.exp.K_metas(jj)=unc(res{ii}.exp.("K+")(jj), ...
        diag([real(res{ii}.exp.("K+_StdUnc")(jj)).^2,imag(res{ii}.exp.("K+_StdUnc")(jj)).^2]));
    end
    fig_stiffness = plotFreqResp( ...
        res{ii}.exp.Pe,res{ii}.exp.K_metas, ...
        fig_stiffness, ...
        'plottype','semilogx', ...
        'ylabel','K+', ...
        'ylimits', [1,1.75],...
        'flimits',[10^-0,10^5],...
        'xlabel','Pe', ...
        'phase',true, ...
        'plotOpts',plotopts);
    box off

     
end

setfigpos(12.5,10.3,'m')
if false
fnames=fieldnames(Nu);
gamma=gamma(1);
for ii = 1:length(fnames)
    Nutemp=Nu.(fnames{ii});
    K.(fnames{ii})=-(Pe*gamma-1i*Nutemp*gamma)./(Pe-1i*Nutemp*gamma);
end
semilogx(Pe,abs(K.Rexer))
hold on
semilogx(Pe,abs(K.Lee))
semilogx(Pe,abs(K.Pelz))
set(gca,'XScale','log')

end

% xlim([1e-0,1e5])
% ylim([1,1.65])
%Plot_Nu_models generates plots of Nusselt Models and resulting
%dimensionless stiffness
%
%   created by Manuel Rexer 03.2024
%   last adaption 21.05.2024

%% Calculate Nusselt Numbers
% Definition of Peclet number
Pe= logspace(-3,5,100);

% Lee Model
z=(1+1i).*sqrt(Pe/2);
Nu.Lee=sqrt(Pe/2).*((1+1i).*tanh(z))./(1-tanh(z)./z);

Pe=Pe*4;
% Kornhauser
Nu.Korn=(1+1i)*0.56*Pe.^(0.69);
%Lekic
Nu.Lekic=(1.33*Pe.^(0.56) + 5.36) + 1i*(2.04*Pe.^(0.46) - 1.46);
Pe=Pe/4;
%% Plot Nusselt Numbers
% initiate figure
fnames=fieldnames(Nu);
fig_NuReIm=figure('name','Nusseltzahl Real und Imaginärteil');
publishfig
setfigpos(13.7,6.9,'m')
tiledlayout(1,2,"Padding","tight","TileSpacing","tight")
for ii=1:length(fnames)
    nexttile(1)
    loglog(Pe,real(Nu.(fnames{ii})))
    box off
    hold on
    nexttile(2)
    loglog(Pe,imag(Nu.(fnames{ii})))
    hold on
    box off
end

% add Measurements from Hartig
if false
    load MeanOscillatingPecletNumber4mm120bar40bar0_7L.mat
    Pe120bar4mm = k;
    load NusseltFit4mm120bar40bar0_7L.mat
    Nu120bar4mm = resultsFitKornhauser;
    nexttile(1)
    loglog(Pe120bar4mm,real([Nu120bar4mm.complexNu]),'s','MarkerFaceColor','white','MarkerEdgeColor','black')
    nexttile(2)
    loglog(Pe120bar4mm,real([Nu120bar4mm.complexNu]),'s','MarkerFaceColor','white','MarkerEdgeColor','black')
end
nexttile(1)
xlabel('Pe')
ylabel('Re(Nu)')
xlim([1e-3,1e5])
ylim([1e-2,1e4])
decades_equal(gca)
nexttile(2)
xlabel('Pe')
ylabel('Im(Nu)')
xlim([1e-3,1e5])
ylim([1e-2,1e4])
decades_equal(gca)

%% Calculate and plot dimensionless Stiffness
% Pelz Model
Nu.Pelz=3*ones(1,length(Pe));
fnames=fieldnames(Nu);
% isentropic exponent
gamma=1.4;
% initiate figure
fig_K=figure('name','Bodeplot der Steifigkeiten');
publishfig
setfigpos(13.7,10.3,'m')
tiledlayout(2,1,"Padding","tight","TileSpacing","tight")

for ii=1:length(fnames)
    % calculate stiffness
    K.(fnames{ii})=(1i*gamma*Nu.(fnames{ii})./Pe-gamma)./...
        (1i*gamma*Nu.(fnames{ii})./Pe-1);
    % plot magnitude
    nexttile(1)
    semilogx(Pe,abs(K.(fnames{ii})))
    box off
    hold on
    % plot phase
    nexttile(2)
    semilogx(Pe,rad2deg(angle(K.(fnames{ii}))))
    hold on
    box off
end

nexttile(1)
ylabel('|K|')
xlim([1e-3,1e5])
ylim([1,1.4])
nexttile(2)
xlabel('Pe')
ylabel('phase K')
xlim([1e-3,1e5])
% ylim([1e-2,1e4])

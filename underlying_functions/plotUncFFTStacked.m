function [fig] = plotUncFFTStacked(input,fig)
%plotUncFFTStacked(input,fig) plots uncertatinty information in fig as
%stacked bar plot
%  created by Manuel Rexer 04.2024
%  last adaption 21.05.2024

% fig=figure();
jj=0;
for ii= length(input):-4:1
    jj=jj+1;
    uncs(jj)=input(ii).FFT.uncertainty;
    [~,indx]=min(abs(input(ii).FFT.frequencies-input(ii).FFT.excitation_frequency));
    mag(jj,1)=uncs(jj).systematic.absolute(indx);
    mag(jj,2)=uncs(jj).deadtime.absolute(indx);
    mag(jj,3)=uncs(jj).statistical.absolute(indx);
    pha(jj,1)=rad2deg(uncs(jj).systematic.phase(indx));
    pha(jj,2)=rad2deg(uncs(jj).deadtime.phase(indx));
    pha(jj,3)=rad2deg(uncs(jj).statistical.phase(indx));
    freqs(jj)=input(ii).FFT.excitation_frequency;
end

figure(fig)
tiledlayout(1,2,"TileSpacing","tight","Padding","tight")

nexttile
b1=bar(log10(freqs),mag,'stacked','EdgeColor','none');
set(gca,'Xtick',0:4); %// adjust manually; values in log scale
set(gca,'Xticklabel',10.^get(gca,'Xtick')); %// use labels with linear values
box off
b1(1).FaceColor=0*[1 1 1];
b1(2).FaceColor=0.4*[1 1 1];
b1(3).FaceColor=0.8*[1 1 1];
xlabel('FREQUENZ')
ylabel('MAG')
nexttile
b2=bar(log10(freqs),pha,'stacked','EdgeColor','none');
set(gca,'Xtick',0:4); %// adjust manually; values in log scale
set(gca,'Xticklabel',10.^get(gca,'Xtick')); %// use labels with linear values
box off
b2(1).FaceColor=0*[1 1 1];
b2(2).FaceColor=0.4*[1 1 1];
b2(3).FaceColor=0.8*[1 1 1];
xlabel('FREQUENZ')
ylabel('PHASE')

end
function [datastr] = getHarmonicWithUnc(datastr,excitationFrequency,neval)
% getHarmonic extracts from a frequency vector the harmonics of
% 0,omega,...,n*omega
%
% created by Manuel Rexer 10.03.2024
% Last adaption: 21.05.2024

%% clculation
unc=@LinProp;
for ii=length(datastr):-1:1
    % determine harmonics
    [values,frequencies]=getHarmonic(...
        datastr(ii).FFT.value,...
        datastr(ii).FFT.frequencies,...
        excitationFrequency(ii),neval);
    % get uncertatinty values
    [uncvalues,~]=getHarmonic(...
        datastr(ii).FFT.uncertainty.complex,...
        datastr(ii).FFT.frequencies,...
        excitationFrequency(ii),neval);
    % get magnitude values
    [uncmag,~]=getHarmonic(...
        datastr(ii).FFT.uncertainty.absolute,...
        datastr(ii).FFT.frequencies,...
        excitationFrequency(ii),neval);
    % get phase values
    [uncphase,~]=getHarmonic(...
        datastr(ii).FFT.uncertainty.phase,...
        datastr(ii).FFT.frequencies,...
        excitationFrequency(ii),neval);

    datastr(ii).FFT.harmonic.value=values;
    datastr(ii).FFT.harmonic.frequencies=frequencies;
    datastr(ii).FFT.harmonic.uncertainty.complex=uncvalues;
    datastr(ii).FFT.harmonic.uncertainty.absolute= uncmag;
    datastr(ii).FFT.harmonic.uncertainty.phase=uncphase;
    % determine uncertaintyvalues
    % all frequencies
    % Propagate frequency
    for jj=length(values):-1:1
        mag=unc(abs(values(jj)),uncmag(jj));
        pha=unc(phase(values(jj)),uncphase(jj));
        datastr(ii).FFT.harmonic.metas(jj) = mag*cos(pha)+1i*mag*sin(pha);
    end
    % TODO:adapt omega=0
end
end
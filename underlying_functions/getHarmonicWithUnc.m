function [datastr] = getHarmonicWithUnc(datastr,excitationFrequency,neval)
% getHarmonic extracts from a frequency vector the harmonics of
% 0,omega,...,n*omega
%   Version 1.1 Manuel Rexer 10.03.2024
unc=@LinProp;
for ii=length(datastr):-1:1
    % determine harmonics
    [values,frequencies]=getHarmonic(...
        datastr(ii).FFT.value,...
        datastr(ii).FFT.frequencies,...
        excitationFrequency(ii),neval);
    
    [uncvalues,~]=getHarmonic(...
        datastr(ii).FFT.uncertainty.complex,...
        datastr(ii).FFT.frequencies,...
        excitationFrequency(ii),neval);

    [uncmag,~]=getHarmonic(...
        datastr(ii).FFT.uncertainty.absolute,...
        datastr(ii).FFT.frequencies,...
        excitationFrequency(ii),neval);
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
    for jj=length(values):-1:1
        %         datastr(ii).FFT.harmonic.metas(jj) = unc(complex(values(jj)),...
        %             diag([real(uncvalues(jj))^2,imag(uncvalues(jj))^2]));
        mag=unc(abs(values(jj)),uncmag(jj));
        pha=unc(phase(values(jj)),uncphase(jj));
        datastr(ii).FFT.harmonic.metas(jj) = mag*cos(pha)+1i*mag*sin(pha);
    end
    % adapt omega=0
    % TODO

    % pressure(ii).FFT.harmonic.metas(1)=

end

end
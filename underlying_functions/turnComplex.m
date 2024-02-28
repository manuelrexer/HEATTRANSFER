function [output] = turnComplex(complex,phase0)
% turnComplex turns a complex number around an angle
% complex: complex number or 1D Vector
% Phase0: angle in rad
[nrow,ncolum]=size(complex);
for ii=1:nrow
    for jj=1:ncolum
        phase=angle(complex(ii,jj));
        mag=abs(complex(ii,jj));
        output(ii,jj)=mag*cos(phase+phase0)+1i*mag*sin(phase+phase0);
    end
end
end
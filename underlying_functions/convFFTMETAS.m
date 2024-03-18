function [y,varargout] =convFFTMETAS(u,v,u_f,v_f)


if nargin==4
    fumin = min(u_f);
    Ku = length(u);
    fvmin = min(v_f);
    Kv = length(v);


    % Calculation of frequency vektor f
    kmin = fvmin + fumin;
    K = Ku + Kv - 1;
    if length(u_f)>1
        df=u_f(2)-u_f(1);
    elseif length(v_f)>1
        df=v_f(2)-v_f(1);
    else
        df=1;
    end
    f = kmin : 1 : kmin + K - 1;
    f=f*df;
    varargout{1}=f';
end

% calculation of convolution
% y=conv(u,v); %1/(2*pi)

unc=@LinProp;
L = length(u)+length(v)-1;
y = unc(zeros(1,L));
a1=[u,unc(zeros(1,L-length(u)))]; % define a new vector of a
b1=[v,unc(zeros(1,L-length(v)))];
for i=1:L
    c = 0;
    for j=1:i
        c = c + a1(j)*b1(i-j+1);
    end
      y(i) = c;
end

end
% y=u*v;


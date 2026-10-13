function Smm = s4p_to_mixedmode(S)
%S4P_TO_MIXEDMODE Convert 4-port single-ended S-parameters to mixed mode.
%
% Single-ended port order:
%   [1 2 3 4]
%
% Mixed-mode order:
%   [d1 c1 d2 c2]
%
% Differential pairs:
%   Pair 1: port 1 (+), port 2 (-)
%   Pair 2: port 3 (+), port 4 (-)

    T = (1/sqrt(2))*[ ...
         1 -1  0  0;   % d1
         1  1  0  0;   % c1
         0  0  1 -1;   % d2
         0  0  1  1];  % c2

    Nf = size(S,3);
    Smm = zeros(4,4,Nf, 'like', S);

    for k = 1:Nf
        Smm(:,:,k) = T * S(:,:,k) * T.';
    end
end

function Y = extract_mm_parameter(Smm, parameterName)
%EXTRACT_MM_PARAMETER Extract one response from a mixed-mode 4-port matrix.
%
% Mixed-mode ordering:
%   [d1 c1 d2 c2]
%
% Supported parameters:
%   Sdd11 : differential reflection at mixed-mode port 1
%   Sdd21 : differential transmission from port 1 to port 2
%   Scc21 : common-mode transmission from port 1 to port 2
%   Scd21 : differential-to-common forward mode conversion
%   Sdc21 : common-to-differential forward mode conversion

    if ndims(Smm) ~= 3 || size(Smm,1) ~= 4 || size(Smm,2) ~= 4
        error('Smm must be a 4x4xN mixed-mode S-parameter array.');
    end

    switch parameterName
        case 'Sdd11'
            Y = squeeze(Smm(1,1,:));

        case 'Sdd21'
            Y = squeeze(Smm(3,1,:));

        case 'Scc21'
            Y = squeeze(Smm(4,2,:));

        case 'Scd21'
            Y = squeeze(Smm(4,1,:));

        case 'Sdc21'
            Y = squeeze(Smm(3,2,:));

        otherwise
            error('Unknown mixed-mode parameter: %s', parameterName);
    end
end

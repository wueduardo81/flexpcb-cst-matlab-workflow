function runs = parse_parameter_sweep_log(logFile)
%PARSE_PARAMETER_SWEEP_LOG Parse CST parameter-sweep text log.

    if nargin < 1 || isempty(logFile)
        error('A logfile path must be provided.');
    end

    if ~isfile(logFile)
        error('Logfile not found: %s', logFile);
    end

    txt = fileread(logFile);
    txt = regexprep(txt, '\r\n|\r', newline);

    blocks = regexp(txt, ...
        'Parameter Values:\s*(.*?)(?=Structure update:)', ...
        'tokens');

    nRuns = numel(blocks);

    if nRuns == 0
        warning('No "Parameter Values" blocks were found in logfile: %s', logFile);
        runs = table();
        return;
    end

    runStructs = repmat(struct(), nRuns, 1);

    for i = 1:nRuns
        runStructs(i).RunID = i;
        blockText = blocks{i}{1};
        lines = regexp(blockText, '\n', 'split');

        for k = 1:numel(lines)
            line = strtrim(lines{k});
            line = regexprep(line, ...
                '^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s+', '');

            tok = regexp(line, ...
                '^([A-Za-z_]\w*)\s*=\s*([-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)', ...
                'tokens', 'once');

            if isempty(tok)
                continue;
            end

            rawName = tok{1};
            value = str2double(tok{2});
            cleanName = normalize_parameter_name(rawName);
            runStructs(i).(cleanName) = value;
        end
    end

    runs = struct_array_to_table_with_missing(runStructs);
end

function name = normalize_parameter_name(rawName)
    switch lower(rawName)
        case {'gap', 'g', 's'}
            name = 'Gap_mm';
        case {'w', 'width'}
            name = 'W_mm';
        case {'l', 'length'}
            name = 'L_mm';
        case {'h', 'height'}
            name = 'H_mm';
        case {'t', 'thickness'}
            name = 'T_mm';
        otherwise
            name = matlab.lang.makeValidName(rawName);
    end
end

function T = struct_array_to_table_with_missing(S)
    allFields = {};

    for i = 1:numel(S)
        allFields = union(allFields, fieldnames(S(i)));
    end

    n = numel(S);
    T = table();

    for f = 1:numel(allFields)
        fieldName = allFields{f};
        values = NaN(n, 1);
        isNumericField = true;

        for i = 1:n
            if isfield(S(i), fieldName)
                if isnumeric(S(i).(fieldName))
                    values(i) = S(i).(fieldName);
                else
                    isNumericField = false;
                    break;
                end
            end
        end

        if isNumericField
            T.(fieldName) = values;
        else
            c = cell(n, 1);
            for i = 1:n
                if isfield(S(i), fieldName)
                    c{i} = S(i).(fieldName);
                else
                    c{i} = '';
                end
            end
            T.(fieldName) = c;
        end
    end

    if ismember('RunID', T.Properties.VariableNames)
        T = movevars(T, 'RunID', 'Before', 1);
    end
end

% Evan Weinberg: 2016-04-14
% Load column 'column' of a file named 'fname'. Each configuration contributes 'parse_Nt' data points. 
% To do: load a full tensor structure. 
function correlator = load_data(fname, column, parse_Nt)
	raw_data = importdata(fname);
    num_data = floor(size(raw_data, 1)/(parse_Nt));
    correlator = reshape(raw_data(:,column), [parse_Nt, num_data]);
end
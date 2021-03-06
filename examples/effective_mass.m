function [ timeslice, roots, roots_err, masses, masses_err, amps, amps_err ] = effective_mass
    % Try this multi-state effective mass idea.
	time = 0;
	roots = 0;
	roots_err = 0;
	masses = 0;
	masses_err = 0;
	amps = 0;
	amps_err = 0;
	
	% Load the path with routines to load, bin, etc data.
	addpath('../series-tools', '-end');
	addpath('../correlator-tools', '-end');
	
	% Ask for a filename. 
	[filename, pathname] = uigetfile('*');
	
	if (filename == 0) % if user clicked cancel
		return; 
	end
	
	while (exist(strcat([pathname, filename]), 'file') == 0) % if file doesn't exist...
		msgbox('File does not exist.', 'Error', 'error');
		[filename, pathname] = uigetfile('*');
		
		if (filename == 0) % if user clicked cancel
			return; 
		end
	end
	
	% concatenate to get file.
	fname = strcat([pathname, filename]);
    
    % Ask for Nt. 
    get_nt = inputdlg({'What is Nt?'}, 'Input', 1, {'64'});
    
    % Make sure the user didn't cancel.
    if (size(get_nt, 1) == 0)
        return;
    end
    
    parse_Nt = str2num(get_nt{1});
		
    % Load the data! The value of the correlator is in column 3. 
	correlator = load_data(fname, 3, parse_Nt);
    
	% Ask about binning. 
    get_bin = inputdlg({'What bin size should we use? (Unbinned is 1)'}, 'Input', 1, {'1'}); 
    
    if (size(get_bin,1) == 0)
        return;
    end
    
    % Add an option to suggest a binsize using the autocorr from UWerr. 
    
    binsize = str2num(get_bin{1});
    
	% Fold it!
	%if (fold == 1)
	%	connected = fold_data(connected, is_baryon);
	%end

	% Bin data!
	[correlator_bins, num_bins] = bin_data(correlator, 2, binsize);
	
    % Get mean, jackknife blocks. Second arg is what column to bin. (Third
    % for jack---just set to 1. Might be buggy...
	correlator_sum = mean(correlator_bins, 2);
	correlator_jack = jackknife_bins(correlator_bins, 2, 1); 
    
    % Not essential for effective masses, but...
    % Get covariance and errors from mean and jackknife blocks.
    %[correlator_cov_mat, correlator_err] = errors_jackknife(correlator_sum, correlator_jack); 
	
	% Ask for number of states (K), how many data pts to use (N), and
	% SVD cuts (just use 0) (C). 
    
    new_effmass = inputdlg({'Number of states (1 to 6)', 'Values to use (2*N_states to N_t/2)', 'States to SVD Cut (0 to N_states)'}, ...
										'Input', 1, {num2str(2), num2str(4), num2str(0)});
                                    
    if (size(get_bin,1) == 0)
        return;
    end
    
    tmpeffK = str2num(new_effmass{1});
    if (~(size(tmpeffK, 1) == 0))
        if (tmpeffK > 0 && tmpeffK < 6)
            eff_K = tmpeffK;
        else
            eff_K = 1;
        end
    end

    tmpeffN = str2num(new_effmass{2});
    if (~(size(tmpeffN, 1) == 0))
        if (tmpeffN >= (2*eff_K) && tmpeffN <= (parse_Nt/2))
            eff_N = tmpeffN;
        else
            are_valid = eff_K*2;
        end
    end

    tmpeffC = str2num(new_effmass{3});
    if (~(size(tmpeffC, 1) == 0))
        if (tmpeffC >= 0 && tmpeffC < eff_K)
            eff_C = tmpeffC;
        else
            eff_C = 0;
        end
    end

	% Get the central value effective masses using the effective mass
	% utility. 
	[ masses_center, roots_center, amps_center ] = effective_mass_utility(correlator_sum, parse_Nt, eff_K, eff_N, eff_C);
	
	
				
	
    % Prepare for blocks!
    masses_jack = zeros([size(masses_center) num_bins]);
    roots_jack = zeros([size(roots_center) num_bins]);
    amps_jack = zeros([size(amps_center) num_bins]);

    % Use the effective mass utility to 
    for b=1:num_bins
        [ masses_jack(:,:,b), roots_jack(:,:,b), amps_jack(:,:,b)] = effective_mass_utility(correlator_jack(:,b), parse_Nt, eff_K, eff_N, eff_C);
    end

    % Get a jackknife error! I should do all of this with the
    % error_jackknife function. That's on the to do. 
    masses_rep = repmat(masses_center, [1 1 num_bins]);
    roots_rep = repmat(roots_center, [1 1 num_bins]);
    amps_rep = repmat(amps_center, [1 1 num_bins]);

    masses_err = sqrt(sum((masses_rep-masses_jack).^2, 3).*(num_bins-1)/(num_bins));
    roots_err = sqrt(sum((roots_rep-roots_jack).^2, 3).*(num_bins-1)/(num_bins));
    amps_err = sqrt(sum((amps_rep-amps_jack).^2, 3).*(num_bins-1)/(num_bins));
		
	roots = roots_center;
	masses = masses_center;
	amps = amps_center; 
    
    % get some times
    timeslice = zeros([size(masses_center)]); 
    for j=1:(size(masses_err,1))
        timeslice(j) = j-1+((eff_N-1)/2);
    end
	
	% Plotting routines!
	% Build plots strings as needed.
	plot_str{1} = '+r';
	plot_str{2} = 'og';
	plot_str{3} = 'xb';
	plot_str{4} = 'sc';
	plot_str{5} = 'dm';
	plot_str{6} = 'pk';
	
	h_svd = figure();
	set(h_svd, 'Name', 'Effective mass visualization');
	errorbar(timeslice(:,1)-0.2, masses(:,1), masses_err(:,1), plot_str{1}); hold on;
	if (eff_K > 1)
		for b=2:eff_K
			errorbar(timeslice(:,1)+(0.4/(eff_K-1))*(b-1)-0.2, masses(:,b), masses_err(:,b), plot_str{b}); 
		end
	end
	axis([-inf, inf, 0.000001, 1]);
	waitfor(h_svd);
	hold off;

end

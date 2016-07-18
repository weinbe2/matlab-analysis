-- ADG 06-14-2016
-- Measure I=2 scattering amplitude using even-odd wall sources

-- BASED ON EVAN's "my_connected_meas.lua"
-- -- ESW 09-24-2014
-- -- This standalone file gauge fixes a configuration to coulomb gauge, 
-- -- then measure various spectral quantities.

require 'common'
require 'smear'
require 'run'

-- Parameters we need to set.
local nx = :L: -- Lattice spatial dimension
local nt = :T: -- Lattice temporal dimension
local mass = 0.:MASS: -- Light quark mass.
local inlat = "../config/config.:CONFIG:.lime" -- Input configuration
local gfix_prec = 1e-7 -- Max residual of gauge fixing.
local gfix_max = 4000 -- Maximum number of gauge fixing steps.
local cg_prec = 1e-7 -- Max residual of CG.
local cg_max = 4000 -- Maximum number of CG steps.
local src_start = 2 -- Where to put the first source.
local src_num = math.floor(nt/8) -- How many sources to place. (From this, a uniform spacing is derived)
                  -- math.floor(nt/8) Our convention has been 6 for 24^3x48, 8 for 32^3x64.
local gfix_or = 1.75 -- The overrelaxation parameter for gauge fixing.

-- note, when I turn on gauge fixing the code hangs for a really long time on the gauge fixing part.
-- not sure if that's a problem or if gauge fixing just takes a really long time
-- ESW: gauge fixing, as I implemented it in FUEL, just takes a really long time.
-- I use a separate code to do it now.
local dogaugefix = 0; -- intentionally don't gauge fix! 

printf("inlat = %s\n", inlat)

-- These parameters matter!
local prec = prec or 1

-- Start preparing to load the gauge field, spit out basic info.
local latsize = { nx, nx, nx, nt }
local vol = 1
local spatvol = nx*nx*nx;
local seed = seed or qopqdp.dtime();
printf("latsize =")
for k,v in ipairs(latsize) do vol=vol*v; printf(" %i",v); end
printf("\nvolume = %i\n", vol)
printf("mass = %g\n", mass)
printf("seed = %i\n", seed)
printf("gfix_prec = %g\n", gfix_prec)
printf("cg_prec = %g\n", cg_prec)
printf("src_num = %i\n", src_num)

-- Set up qopqdp.
L = qopqdp.lattice(latsize) --need L to make lattice color matrices
qopqdp.profile(profile or 0);
qopqdp.verbosity(0);
qopqdp.seed(seed);

-- Start a timer.
totaltime = qopqdp.dtime()

-- Load the gauge field.
g = qopqdp.gauge();
if inlat then g:load(inlat)
else
	printf("No input configuration specified.  Using unit gauge.\n");
	g:unit();
end

-- Reunitarize, just to be safe.
do
  local devavg,devmax = g:checkSU()
  printf("unitarity deviation avg: %g  max: %g\n", devavg, devmax)
  g:makeSU()
  devavg,devmax = g:checkSU()
  printf("new unitarity deviation avg: %g  max: %g\n", devavg, devmax)
end

-- Print some basic information about the configuration.
function getplaq(g)
  local ps,pt = g:action{plaq=1}
  local lat = qopqdp.lattice()
  local nd,vol = #lat,1
  for i=1,nd do vol=vol*lat[i] end
  local s = 0.25*nd*(nd-1)*vol
  printf("plaq ss: %-8g  st: %-8g  tot: %-8g\n", ps/s, pt/s, 0.5*(ps+pt)/s)
end
getplaq(g);


-- First, we need to gauge fix!
if dogaugefix == 1 then
    local t0 = qopqdp.dtime();

    -- coulomb(j_decay, error, max iterations, overrelaxation param)
    -- note that here 0->x, ..., 3->t
    g:coulomb(3, gfix_prec, gfix_max, gfix_or);

    t0 = qopqdp.dtime() - t0
    printf("Coulgauge meas time: %g\n", t0)
end

-- Prepare a smearing setting. This has been verified to be consistent
-- with MILC. Then smear the gauge field!
local smear = {}
smear[#smear+1] = { type="hyp", alpha={0.4,0.5,0.5} }
myprint("smear = ", smear, "\n")

printf("Start smearing.\n");

-- We need to do this because 'smearGauge' expects an action object.
local sg = smearGauge({g = g}, smear);
printf("Smearing done.\n");

-- Set the ASQTAD coefficients. This corresponds to just simple
-- Staggered fermions (supplemented with nHYP smearing)
coeffs = { one_link=1 }

-- Create an asqtad object, set coefficients, etc.
w = qopqdp.asqtad();
w:coeffs(coeffs);
w:set(sg, prec); 

-- By the way...
local Nc = qopqdp.defaultNc();

-- Now we can prepare to measure things! Measurements are
-- set up to output in a form similar to MILC's measurements.

-- Set up a function which does an inversion and prints
-- out timing information. Based on actmt.set in asqtadact.lua
function solve_printinfo(w, dest, src, m, res, sub, opts)
	local t0 = qopqdp.dtime();
	w:solve({dest}, src, {m}, res, sub, opts);
	local cgtime = qopqdp.dtime() - t0;
	local flops = w:flops();
	local its = w:its();
	
	printf("inversion its: %g  secs: %g  Mflops: %g\n", its, cgtime, flops*1e-6/cgtime);
end

-- Set up a function which adds a correlator to an existing
-- correlator array, properly shifting, normalizing, and 
-- compensating for mesonic/baryonic source.
-- corr: What we're adding a new piece of data to.
-- new_data: the new correlator we're adding in.
-- t_shift: the 't' value of the source.
-- norm: the normalization to multiply new_data by before adding it.
function add_correlator_meson(corr, new_data, t_shift, norm)

	for j=1,#new_data do
		-- Compensate for shifted wall source.
		j_real = (j+t_shift-1)%(#new_data)+1 
		corr[j] = new_data[j_real]*norm + (corr[j] or 0)
	end

end

-- Pull the real part from a complex array.
function add_correlator_meson_real(corr, new_data, t_shift, norm)

	for j=1,#new_data do
		-- Compensate for shifted wall source.
		j_real = (j+t_shift-1)%(#new_data)+1 
		corr[j] = new_data[j_real].r*norm + (corr[j] or 0)
	end

end

-- Same deal, but for baryons we have to be careful about
-- going around the T end of the lattice.

function add_correlator_baryon(corr, new_data, t_shift, norm)

	for j=1,#new_data do
		-- Compensate for shifted wall source.
		j_real = (j+t_shift-1)%(#new_data)+1 
		if (((math.floor((j+t_shift-1)/(#new_data))-math.floor((t_shift-1)/(#new_data)))%2) == 0) then -- count the number of times we wrap.
			corr[j] = -new_data[j_real]*norm + (corr[j] or 0)
		else
			corr[j] = new_data[j_real]*norm + (corr[j] or 0)
		end
	end

end

-- Set up a function to build staggered phases.
-- Use 0 for no phase, 1 for phase.
function make_phase_term(xsign,ysign,zsign,tsign)
  return xsign + 2*ysign + 4*zsign + 8*tsign
end

---- Helper functions by ADG ("Look for the helpers" -- Fred Rogers) --------
--complex algebra!
function adg_add(num1,num2)
	return {r = num1.r + num2.r, i = num1.i + num2.i};
end
function adg_sub(num1,num2)
	return {r = num1.r - num2.r, i = num1.i - num2.i};
end
function adg_mul(num1,num2)
	return {r = num1.r*num2.r - num1.i*num2.i, i = num1.r*num2.i + num1.i*num2.r}
end
--complex conjuate
function adg_conj(num)
	return {r=num.r,i= -num.i}
end

--Color matrix multiply
function cmat_multiply(Amat,Bmat)
	result = {};
	for i=1,Nc do
		result[i] = {};
		for j=1,Nc do 
			result[i][j] = {r = 0.0,i = 0.0};
			for k=1,Nc do
				result[i][j] = adg_add(result[i][j],adg_mul(Amat[i][k],Bmat[k][j]));
			end
		end
	end
	return result
end
--Color matrix trace
function cmat_trace(A)
	result = {r = 0.0,i = 0.0};
	for i=1,Nc do 
		result = adg_add(result,A[i][i]);
	end
	return result
end
--Color matrix dagger
function cmat_dagger(A)
	result = {};
	for i=1,Nc do
		result[i] = {};
		for j=1,Nc do 
			result[i][j] = adg_conj(A[j][i]);
		end
	end
	return result;
end		

-- First, set up where we put sources. Evenly space src_num sources
-- starting at t=src_start.
local time_sources = {};
for i=1,src_num do
	time_sources[i] = (src_start+(i-1)*math.floor(nt/src_num))%nt;
end


-- Next, prepare wall source solves.
-- We need a lot more quarks. Let's create these here!

-- allocate lattice color vectors for t1 and t2 sources, even and odd
even_src1 = w:quark(); even_src1:zero();
even_src2 = w:quark(); even_src2:zero();
odd_src1 = w:quark(); odd_src1:zero();
odd_src2 = w:quark(); odd_src2:zero();
-- allocate lattice color vectors for holding solutions
even_soln1 = {};
even_soln2 = {};
odd_soln1 = {};
odd_soln2 = {};
for i=1,Nc do
	even_soln1[i] = w:quark(); even_soln1[i]:zero();
	even_soln2[i] = w:quark(); even_soln2[i]:zero();
	odd_soln1[i] = w:quark(); odd_soln1[i]:zero();
	odd_soln2[i] = w:quark(); odd_soln2[i]:zero();
end
--allocate lattice color matrices for holding solutions
even_soln1_mat = L:colorMatrix();
even_soln1_mat:zero();
even_soln2_mat = L:colorMatrix();
even_soln2_mat:zero();
odd_soln1_mat = L:colorMatrix();
odd_soln1_mat:zero();
odd_soln2_mat = L:colorMatrix();
odd_soln2_mat:zero();


-- places for contractions to go
-- ESW on a per-timeslice basis. 
direct_even1 = {};
direct_odd1 = {};
direct_even2 = {};
direct_odd2 = {};
Cdirect1324 = {};
Cdirect1423 = {};

cross_amp = {};
cross_tmp = {};
Ccrossed1423 = {};
Ccrossed1324 = {};
for ii=1,2 do 
    cross_tmp[ii] = {};
    for jj=1,2 do 
        cross_tmp[ii][jj] = {};
    end
end
for ii=1,2 do 
    cross_amp[ii] = {};
    for jj=1,2 do 
        cross_amp[ii][jj] = {};
        for tt=1,nt do
            cross_amp[ii][jj][tt] = {}
            for i=1,Nc do 
                cross_amp[ii][jj][tt][i] = {};
                for j=1,Nc do
                    cross_amp[ii][jj][tt][i][j] = {};
                end
            end
        end
    end
end
C_i2 = {};

-- ESW: Where we store the final result.
-- These get shifted so we can add multiple source locations
-- together meaningfully.

D_1324_all = {};
D_1423_all = {};
C_1423_all = {};
C_1324_all = {};
C_i2_all = {};
--two more correlators to hold the pion propagator coming from t1 and from t2
C_pi_t1 = {};
C_pi_t2 = {};
C_pi_t1_all = {};
C_pi_t2_all = {};
		
-- Let's go go go!
do
	-- Loop over all time sources.
	for srcnum=1,#time_sources do
		printf("Start wall source %i at t=%i.\n", srcnum, time_sources[srcnum]);
		
		-- Loop over all colors. This is for meson measurements,
		-- and preparing for nucleon measurements.
		
		--note, indexing convention changed in newest FUEL.  --ADG 6/15
		for i=0,Nc-1 do
			printf("Start color %i.\n", i);
			io.stdout:flush();
			
			-- Prepare the even source. Even wall, Norm matches milc.
			-- note: last argument is the value put at each nonzero site on the wall.
			-- -- I guess -0.125 is some MILC convention   -- ADG 6/15
			-- -- ALSO I GUESS THE WALL FUNCTION STILL USES THE CONVENTION OF COLOR LABELS going from 1...Nc
			even_src1:zero();
			even_src1:wall(time_sources[srcnum], 0, i+1, -0.125); 
			printf("even_src1 norm2: %g\n", even_src1:norm2());
			even_src2:zero();
			even_src2:wall((time_sources[srcnum]+1)%nt, 0, i+1, -0.125); 
			printf("even_src2 norm2: %g\n", even_src2:norm2());
			-- Prepare the odd source. Odd wall, Norm matches milc.
			odd_src1:zero();
			odd_src1:wall(time_sources[srcnum], 1, i+1, -0.125);
			printf("odd_src1 norm2: %g\n", odd_src1:norm2());
			odd_src2:zero();
			odd_src2:wall((time_sources[srcnum]+1)%nt, 1, i+1, -0.125);
			printf("odd_src2 norm2: %g\n", odd_src2:norm2());
			
			-- Invert on the even source. 
			even_soln1[i+1]:zero();
			solve_printinfo(w, even_soln1[i+1], even_src1, mass, cg_prec, "all", {prec = prec, restart = cg_max});
			even_soln2[i+1]:zero();
			solve_printinfo(w, even_soln2[i+1], even_src2, mass, cg_prec, "all", {prec = prec, restart = cg_max});
			-- Invert on the odd source.
			odd_soln1[i+1]:zero();
			solve_printinfo(w, odd_soln1[i+1], odd_src1, mass, cg_prec, "all", {prec = prec, restart = cg_max});
			odd_soln2[i+1]:zero();
			solve_printinfo(w, odd_soln2[i+1], odd_src2, mass, cg_prec, "all", {prec = prec, restart = cg_max});
			
		end --loop over colors
		
		printf("\nDone with Inversions\n");
		
		--store in color matrices
		even_soln1_mat:zero();
		even_soln1_mat:combineColor(even_soln1);
		even_soln2_mat:zero();
		even_soln2_mat:combineColor(even_soln2);
		odd_soln1_mat:zero();
		odd_soln1_mat:combineColor(odd_soln1);
		odd_soln2_mat:zero();
		odd_soln2_mat:combineColor(odd_soln2);
		
		--Direct Diagram Contractions
		--note, these will be arrays of complex!
		direct_even1 = even_soln1_mat:dot(even_soln1_mat,"timeslices");
		direct_odd1 = odd_soln1_mat:dot(odd_soln1_mat,"timeslices");
		direct_even2 = even_soln2_mat:dot(even_soln2_mat,"timeslices");
		direct_odd2 = odd_soln2_mat:dot(odd_soln2_mat,"timeslices");

		--Crossed "partial amplitudes", or whatever
		for i=1,Nc do
			for j=1,Nc do
				
				--2x2 temporary array of time series.  
				cross_tmp[1][1] = even_soln2[j]:dot(even_soln1[i],"timeslices"); --first cvec is the one that gets daggered
				cross_tmp[2][1] = even_soln2[j]:dot(odd_soln1[i],"timeslices");
				cross_tmp[1][2] = odd_soln2[j]:dot(even_soln1[i],"timeslices");
				cross_tmp[2][2] = odd_soln2[j]:dot(odd_soln1[i],"timeslices");
				--save in convenient format
				for tt = 1,nt do
					cross_amp[1][1][tt][i][j] = cross_tmp[1][1][tt];
					cross_amp[2][1][tt][i][j] = cross_tmp[2][1][tt];
					cross_amp[1][2][tt][i][j] = cross_tmp[1][2][tt];
					cross_amp[2][2][tt][i][j] = cross_tmp[2][2][tt];
				end
			end
		end
		
		--build the final amplitudes
		for tt=1,nt do
			--tt \equiv t3
			--ttp \equiv t4
			
			--shifted times (assume periodic BC)
			ttp = tt+1;
			if ttp > nt then ttp = ttp-nt end
			ttm = tt-1;
			if ttm<1 then ttm=ttm+nt end
			
			Cdirect1324[tt] = adg_add(adg_add(adg_add(adg_mul(direct_even1[tt],direct_even2[ttp]),adg_mul(direct_even1[tt],direct_odd2[ttp])),adg_mul(direct_odd1[tt],direct_even2[ttp])),adg_mul(direct_odd1[tt],direct_odd2[ttp]));
			Cdirect1423[tt] = adg_add(adg_add(adg_add(adg_mul(direct_even1[ttp],direct_even2[tt]),adg_mul(direct_even1[ttp],direct_odd2[tt])),adg_mul(direct_odd1[ttp],direct_even2[tt])),adg_mul(direct_odd1[ttp],direct_odd2[tt]));
		
			Ccrossed1423[tt] = cmat_trace( cmat_multiply( cross_amp[1][1][ttp], cmat_dagger(cross_amp[1][1][tt]) ) );
			Ccrossed1423[tt] = adg_add(Ccrossed1423[tt],cmat_trace( cmat_multiply( cross_amp[2][1][ttp], cmat_dagger(cross_amp[2][1][tt]))));
			Ccrossed1423[tt] = adg_add(Ccrossed1423[tt],cmat_trace( cmat_multiply( cross_amp[1][2][ttp], cmat_dagger(cross_amp[1][2][tt]))));
			Ccrossed1423[tt] = adg_add(Ccrossed1423[tt],cmat_trace( cmat_multiply( cross_amp[2][2][ttp], cmat_dagger(cross_amp[2][2][tt]))));
			
			Ccrossed1324[tt] = cmat_trace( cmat_multiply( cross_amp[1][1][tt], cmat_dagger(cross_amp[1][1][ttp]) ) );
			Ccrossed1324[tt] = adg_add(Ccrossed1324[tt],cmat_trace( cmat_multiply( cross_amp[2][1][tt], cmat_dagger(cross_amp[2][1][ttp]))));
			Ccrossed1324[tt] = adg_add(Ccrossed1324[tt],cmat_trace( cmat_multiply( cross_amp[1][2][tt], cmat_dagger(cross_amp[1][2][ttp]))));
			Ccrossed1324[tt] = adg_add(Ccrossed1324[tt],cmat_trace( cmat_multiply( cross_amp[2][2][tt], cmat_dagger(cross_amp[2][2][ttp]))));
			
			tmpz = {r=4.0,i=0.0};
			C_i2[tt] = adg_sub(adg_sub(adg_add(Cdirect1324[tt],Cdirect1423[tt]),adg_mul(Ccrossed1324[tt],tmpz) ),adg_mul(Ccrossed1423[tt],tmpz));
		
		end
			
        -- Accumulate into final storage.
        add_correlator_meson_real(D_1324_all, Cdirect1324, time_sources[srcnum], 1.0/(#time_sources));
        add_correlator_meson_real(D_1423_all, Cdirect1423, time_sources[srcnum], 1.0/(#time_sources));
        add_correlator_meson_real(C_1324_all, Ccrossed1324, time_sources[srcnum], 1.0/(#time_sources));
        add_correlator_meson_real(C_1423_all, Ccrossed1423, time_sources[srcnum], 1.0/(#time_sources));
        add_correlator_meson_real(C_i2_all, C_i2, time_sources[srcnum], 1.0/(#time_sources));
	add_correlator_meson_real(C_pi_t1_all, direct_even1, time_sources[srcnum],1.0/(#time_sources));
	add_correlator_meson_real(C_pi_t1_all, direct_odd1,  time_sources[srcnum],1.0/(#time_sources));
	add_correlator_meson_real(C_pi_t2_all, direct_even2, time_sources[srcnum],1.0/(#time_sources));
	add_correlator_meson_real(C_pi_t2_all, direct_odd2,  time_sources[srcnum],1.0/(#time_sources));
	
	printf("End wall source.\n");
	end -- number of sources

end


--Print to files
printf("\n\n\n");

printf("MASSES:\t%.6e\t%.6e\n",mass, mass);
printf("SOURCE: WALL_EVEN_AND_ODD\n");
printf("SINKS: POINT\n");
printf("I2_ALL D1324 D1423 C1324 C1423\n");
printf("BEGIN_I2PIPI\n");

for i = 1,#(C_i2_all) do
	printf("%i %.12e %f %.12e %f %.12e %f %.12e %f %.12e %f\n", i-1, C_i2_all[i], 0.0, D_1324_all[i], 0.0, D_1423_all[i], 0.0, C_1324_all[i], 0.0, C_1423_all[i], 0.0);
end
printf("END_I2PIPI\n");
		
printf("PS_T1 PS_T2\n");
printf("BEGIN_PS\n");
for i = 1,#(C_pi_t1_all) do
	printf("%i %.12e %f %.12e %f\n",i-1,C_pi_t1_all[i],0.0,C_pi_t2_all[i],0.0);
end
printf("END_PS\n");

totaltime = qopqdp.dtime() - totaltime;

printf("Total time: %f seconds.\n", totaltime);

io.stdout:flush()

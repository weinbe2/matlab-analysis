-- ESW 2015-06-20
-- This standalone file computes propagators relevant for decay constant calculations.

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
local cg_prec = 1e-6 -- Max residual of CG.
local cg_max = 4000 -- Maximum number of CG steps.
local src_start = 2 -- Where to put the first source.
local src_num = math.floor(nt/8) -- How many sources to place. (From this, a uniform spacing is derived)
local gfix_or = 1.75 -- The overrelaxation parameter for gauge fixing.

printf("inlat = %s\n", inlat)

-- These parameters matter!
local prec = 2 -- Use a multi-precision inverter. Default.

-- Unit test? No
local do_unit = 0;

-- These parameters matter!
local prec = 2 -- Use a multi-precision inverter. Default.

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
qopqdp.lattice(latsize);
qopqdp.profile(profile or 0);
qopqdp.verbosity(0);
qopqdp.seed(seed);

-- Start a timer.
totaltime = qopqdp.dtime()

-- Load the gauge field.
g = qopqdp.gauge();
if (do_unit == 0) then
	if inlat then g:load(inlat)
	else
		printf("No input configuration specified!\n");
		return 400;
	end
else
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

-- Prepare a smearing setting. This has been verified to be consistent
-- with MILC. Then smear the gauge field!
local smear = {}
smear[#smear+1] = { type="hyp", alpha={0.4,0.5,0.5} }
myprint("smear = ", smear, "\n")

printf("Start smearing.\n");

-- We need to do this because 'smearGauge' expects an action object.
local sg;
if (do_unit == 0) then
	sg = smearGauge({g = g}, smear);
else
	sg = g;
end
printf("Smearing done.\n");

-- Make an antiperiodic copy of gauge field.
sg_aperiodic = sg:copy();
sg_aperiodic(4):combine({sg_aperiodic(4)},{-1},"timeslice"..(nt-1))

-- Set the ASQTAD coefficients. This corresponds to just simple
-- Staggered fermions (supplemented with nHYP smearing)
coeffs = { one_link=1 }

-- Create an asqtad object, set coefficients, etc.
w = qopqdp.asqtad();
w:coeffs(coeffs);
w:set(sg, prec); 

-- By the way...
local Nc = 3;

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

-- First, set up where we put sources. Evenly space src_num sources
-- starting at t=src_start.
local time_sources = {};
for i=1,src_num do
	time_sources[i] = (src_start+(i-1)*math.floor(nt/src_num))%nt;
end

-- We need two quark objects---one to put the source in,
-- the other the sink.
src = w:quark();
src:zero();
src_shift = w:quark();
src_shift:zero();
dest = w:quark();
dest:zero();
dest_phase = w:quark();
dest_phase:zero();
dest_shift = w:quark();
dest_shift:zero();
temp1 = w:quark(); temp1:zero();
temp2 = w:quark(); temp2:zero();

-- A place for correlator output to temporarily go.

t = {}; 

-- First, get the local operators.

pion_ll = {}; -- Get the local-local pion.
pion_lc = {}; -- Get the local-conserved pion.
pion_cc = {}; -- Get the conserved-conserved pion.

rho_ll = {}; -- Where the local-local rho goes. Averaged over 3 polarizations.
rho_ll_x = {};
rho_ll_y = {};
rho_ll_z = {};
axial_ll = {}; -- Where the local-local axial goes. Averaged over 3 polarizations.
axial_ll_x = {};
axial_ll_y = {};
axial_ll_z = {};

rho_cc = {}; -- Where the conserved-conserved rho goes. Averaged over 3 polarizations.
rho_cc_x = {};
rho_cc_y = {};
rho_cc_z = {};
axial_cc = {}; -- Where the conserved-conserved rho goes. Averaged
axial_cc_x = {};
axial_cc_y = {};
axial_cc_z = {};



--rho_cc = {}; -- Where the conserved-conserved rho goes. 
do
	-- Loop over all timeslices.
	for srcnum=1,#time_sources do
		printf("Begin t = %d.\n", time_sources[srcnum]);
		-- Loop over all colors.
		for i=0,Nc-1 do
			printf("Begin color = %d.\n", i);
			
			-- Build a point source.
			src:zero();
			src:point({0,0,0,time_sources[srcnum]}, i, complex(1.0,0.0)); -- Drop a 1 on the unit corner.
			
			-- Invert, print out CG info.
			solve_printinfo(w, dest, src, mass, cg_prec, "all", {prec = prec, restart = cg_max});
			
			printf("Begin l-l correlators.\n");
			
			-- Pion l-l
			-- gamma_5 x gamma_5 pion.
			t = dest:norm2("timeslices");
			add_correlator_meson(pion_ll, t, time_sources[srcnum], 1.0/(#time_sources*spatvol));
			
			-- Rho l-l
			-- gamma_x x gamma_x rho.
			dest_phase:set(dest);
			dest_phase:rephase(make_phase_term(1,0,0,0), {0,0,0,time_sources[srcnum]});
			t = dest:Re_dot(dest_phase, "timeslices");
			add_correlator_meson(rho_ll, t, time_sources[srcnum], 1.0/(#time_sources*spatvol*3)); -- factor of 3 for 3 polarizations.
			add_correlator_meson(rho_ll_x, t, time_sources[srcnum], 1.0/(#time_sources*spatvol)); 
			
			-- gamma_y x gamma_y rho.
			dest_phase:set(dest);
			dest_phase:rephase(make_phase_term(0,1,0,0), {0,0,0,time_sources[srcnum]});
			t = dest:Re_dot(dest_phase, "timeslices");
			add_correlator_meson(rho_ll, t, time_sources[srcnum], 1.0/(#time_sources*spatvol*3)); -- factor of 3 for 3 polarizations.
			add_correlator_meson(rho_ll_y, t, time_sources[srcnum], 1.0/(#time_sources*spatvol)); 
			
			-- gamma_z x gamma_z rho.
			dest_phase:set(dest);
			dest_phase:rephase(make_phase_term(0,0,1,0), {0,0,0,time_sources[srcnum]});
			t = dest:Re_dot(dest_phase, "timeslices");
			add_correlator_meson(rho_ll, t, time_sources[srcnum], 1.0/(#time_sources*spatvol*3)); -- factor of 3 for 3 polarizations.
			add_correlator_meson(rho_ll_z, t, time_sources[srcnum], 1.0/(#time_sources*spatvol)); 
			
			-- Axial l-l
			-- gamma_x gamma_5 x gamma_x gamma_5 axial.
			dest_phase:set(dest);
			dest_phase:rephase(make_phase_term(0,1,1,1), {0,0,0,time_sources[srcnum]});
			t = dest:Re_dot(dest_phase, "timeslices");
			add_correlator_meson(axial_ll, t, time_sources[srcnum], 1.0/(#time_sources*spatvol*3)); -- factor of 3 for 3 polarizations.
			add_correlator_meson(axial_ll_x, t, time_sources[srcnum], 1.0/(#time_sources*spatvol)); 
			
			-- gamma_y gamma_5 x gamma_y gamma_5 axial.
			dest_phase:set(dest);
			dest_phase:rephase(make_phase_term(1,0,1,1), {0,0,0,time_sources[srcnum]});
			t = dest:Re_dot(dest_phase, "timeslices");
			add_correlator_meson(axial_ll, t, time_sources[srcnum], 1.0/(#time_sources*spatvol*3)); -- factor of 3 for 3 polarizations.
			add_correlator_meson(axial_ll_y, t, time_sources[srcnum], 1.0/(#time_sources*spatvol)); 
			
			-- gamma_z gamma_5 x gamma_z gamma_5 axial.
			dest_phase:set(dest);
			dest_phase:rephase(make_phase_term(1,1,0,1), {0,0,0,time_sources[srcnum]});
			t = dest:Re_dot(dest_phase, "timeslices");
			add_correlator_meson(axial_ll, t, time_sources[srcnum], 1.0/(#time_sources*spatvol*3)); -- factor of 3 for 3 polarizations.
			add_correlator_meson(axial_ll_z, t, time_sources[srcnum], 1.0/(#time_sources*spatvol)); 
			
			printf("Begin c-c correlators.\n");
			-- Rho c-c, Axial c-c.
			-- gamma_x x 1 rho. D_x.
			
			src_shift:symshift(src, sg, 1) -- shift in the x direction.
			-- Invert, print out CG info.
			solve_printinfo(w, dest_shift, src_shift, mass, cg_prec, "all", {prec = prec, restart = cg_max});
			dest_phase:symshift(dest_shift, sg, 1) -- shift in the x direction, again.
			dest_phase:rephase(make_phase_term(1,1,1,0), {0,0,0,time_sources[srcnum]});
			
			
			t = dest:Re_dot(dest_phase, "timeslices");
			add_correlator_meson(rho_cc, t, time_sources[srcnum], 1.0/(#time_sources*spatvol*3)); -- factor of 3 for 3 polarizations.
			add_correlator_meson(rho_cc_x, t, time_sources[srcnum], 1.0/(#time_sources*spatvol)); -- phase herm
			
			-- gamma_x gamma_5 x gamma_5 axial.  (-1)^(x+y+z+t) D_x
			dest_phase:rephase(make_phase_term(1,1,1,1), {0,0,0,time_sources[srcnum]});
			t = dest:Re_dot(dest_phase, "timeslices");
			-- The minus reflects the fact there should be a eps(x)*eta_y on the source.
			add_correlator_meson(axial_cc, t, time_sources[srcnum], -1.0/(#time_sources*spatvol*3)); -- factor of 3 for 3 polarizations.
			add_correlator_meson(axial_cc_x, t, time_sources[srcnum], -1.0/(#time_sources*spatvol)); -- phase herm
			
			-- gamma_y x 1 rho. (-1)^x D_y.
			
			src_shift:symshift(src, sg, 2) -- shift in y direction.
			src_shift:rephase(make_phase_term(1,0,0,0), {0,0,0,time_sources[srcnum]}); -- eta_y
			-- Invert, print out CG info.
			solve_printinfo(w, dest_shift, src_shift, mass, cg_prec, "all", {prec = prec, restart = cg_max});
			dest_phase:symshift(dest_shift, sg, 2); -- shift in y direction, again.
			dest_phase:rephase(make_phase_term(1,0,0,0), {0,0,0,time_sources[srcnum]}); -- eta_y
			dest_phase:rephase(make_phase_term(1,1,1,0), {0,0,0,time_sources[srcnum]}); -- phase herm
			
			t = dest:Re_dot(dest_phase, "timeslices");
			add_correlator_meson(rho_cc, t, time_sources[srcnum], 1.0/(#time_sources*spatvol*3)); -- factor of 3 for 3 polarizations.
			add_correlator_meson(rho_cc_y, t, time_sources[srcnum], 1.0/(#time_sources*spatvol));
			
			-- gamma_y gamma_5 x gamma_5 axial.  (-1)^(y+z+t) D_y
			dest_phase:rephase(make_phase_term(1,1,1,1), {0,0,0,time_sources[srcnum]});
			t = dest:Re_dot(dest_phase, "timeslices");
			-- The minus reflects the fact there should be a eps(x)*eta_y on the source.
			add_correlator_meson(axial_cc, t, time_sources[srcnum], -1.0/(#time_sources*spatvol*3)); -- factor of 3 for 3 polarizations.
			add_correlator_meson(axial_cc_y, t, time_sources[srcnum], -1.0/(#time_sources*spatvol)); -- phase herm
			
			-- gamma_z x 1 rho. (-1)^(x+y) D_z.
			
			src_shift:symshift(src, sg, 3) -- shift in z direction.
			src_shift:rephase(make_phase_term(1,1,0,0), {0,0,0,time_sources[srcnum]}); -- eta_z
			-- Invert, print out CG info.
			solve_printinfo(w, dest_shift, src_shift, mass, cg_prec, "all", {prec = prec, restart = cg_max});
			dest_phase:symshift(dest_shift, sg, 3); -- shift in z direction, again.
			dest_phase:rephase(make_phase_term(1,1,0,0), {0,0,0,time_sources[srcnum]}); -- eta_z
			dest_phase:rephase(make_phase_term(1,1,1,0), {0,0,0,time_sources[srcnum]}); -- phase herm
			
			t = dest:Re_dot(dest_phase, "timeslices");
			add_correlator_meson(rho_cc, t, time_sources[srcnum], 1.0/(#time_sources*spatvol*3)); -- factor of 3 for 3 polarizations.
			add_correlator_meson(rho_cc_z, t, time_sources[srcnum], 1.0/(#time_sources*spatvol));
			
			-- gamma_z gamma_5 x gamma_5 axial.  (-1)^(z+t) D_z
			dest_phase:rephase(make_phase_term(1,1,1,1), {0,0,0,time_sources[srcnum]});
			t = dest:Re_dot(dest_phase, "timeslices");
			-- The minus reflects the fact there should be a eps(x)*eta_z on the source.
			add_correlator_meson(axial_cc, t, time_sources[srcnum], -1.0/(#time_sources*spatvol*3)); -- factor of 3 for 3 polarizations.
			add_correlator_meson(axial_cc_z, t, time_sources[srcnum], -1.0/(#time_sources*spatvol)); -- phase herm
			
			-- pion l-c, c-c.
			src_shift:symshift(src, sg_aperiodic, 4) -- shift in the t direction.
			src_shift:rephase(make_phase_term(1,1,1,0), {0, 0, 0, time_sources[srcnum]}); -- eta_t.
			-- Invert, print out CG info.
			solve_printinfo(w, dest_shift, src_shift, mass, cg_prec, "all", {prec = prec, restart = cg_max});
			
			-- First, get c-c.
			dest_phase:symshift(dest_shift, sg_aperiodic, 4) -- safely shift in the t direction.
			--dest_phase:symshift_bc(dest_shift, sg, 4, {0,0,0,0}, {1,1,1,-1}, {0,0,0,0}); -- shift in z direction, again.
			dest_phase:rephase(make_phase_term(1,1,1,0), {0,0,0,time_sources[srcnum]}); -- eta_t*eps(x)*eps(x).
			
			t = dest:Re_dot(dest_phase, "timeslices");
			add_correlator_meson(pion_cc, t, time_sources[srcnum], 1.0/(#time_sources*spatvol));
			
			-- Next, get l-c.
			t = dest:Re_dot(dest_shift, "timeslices");
			add_correlator_meson(pion_lc, t, time_sources[srcnum], 1.0/(#time_sources*spatvol));
			
			
		end -- for i=1,Nc
	end -- for srcnum=1,#time_sources
end -- do


		
		
-- Print it out!
printf("BEGIN_SPECTRUM\n");

--This is all to reproduce what MILC does.
printf("STARTPROP\n");
printf("MASSES:\t%.6e\t%.6e\n",mass, mass);
printf("SOURCE: POINT\n");
printf("SINKS: PION_LL PION_LC PION_CC\n");

for i = 1,#(pion_ll) do
	printf("%i %.12e %f %.12e %f %.12e %f\n", i-1, pion_ll[i], 0.0, pion_lc[i], 0.0, pion_cc[i], 0.0);
end
printf("ENDPROP\n");


--This is all to reproduce what MILC does.
printf("STARTPROP\n");
printf("MASSES:\t%.6e\t%.6e\n",mass, mass);
printf("SOURCE: POINT_LL\n");
printf("SINKS: RHO_LL RHO_LL_X RHO_LL_Y RHO_LL_Z AXIAL_LL AXIAL_LL_X AXIAL_LL_Y AXIAL_LL_Z\n");

for i = 1,#(pion_ll) do
	printf("%i %.12e %f %.12e %f %.12e %f %.12e %f %.12e %f %.12e %f %.12e %f %.12e %f\n", i-1, rho_ll[i], 0.0, rho_ll_x[i], 0.0, rho_ll_y[i], 0.0, rho_ll_z[i], 0.0, axial_ll[i], 0.0, axial_ll_x[i], 0.0, axial_ll_y[i], 0.0, axial_ll_z[i], 0.0);
end
printf("ENDPROP\n");

-- This is all to reproduce what MILC does.
printf("STARTPROP\n");
printf("MASSES:\t%.6e\t%.6e\n",mass, mass);
printf("SOURCE: POINT_CC\n");
printf("SINKS: RHO_CC RHO_CC_X RHO_CC_Y RHO_CC_Z AXIAL_CC AXIAL_CC_X AXIAL_CC_Y AXIAL_CC_Z\n");

for i = 1,#(pion_ll) do
	printf("%i %.12e %f %.12e %f %.12e %f %.12e %f %.12e %f %.12e %f %.12e %f %.12e %f\n", i-1, rho_cc[i], 0.0, rho_cc_x[i], 0.0, rho_cc_y[i], 0.0, rho_cc_z[i], 0.0, axial_cc[i], 0.0, axial_cc_x[i], 0.0, axial_cc_y[i], 0.0, axial_cc_z[i], 0.0);
end
printf("ENDPROP\n");

--------------------------- End decay constant calculation ------------
printf("END_SPECTRUM\n");

totaltime = qopqdp.dtime() - totaltime;

printf("Total time: %f seconds.\n", totaltime);

io.stdout:flush()

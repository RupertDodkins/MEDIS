% make_sine_rgd.m
% R. Dekany
%
% reads in an existing hodm map into 'flat'
% adds a sine wave to this map, depending on PHARO speckle position
% writes out a new (loadable) map to p3k/tables/hodm_map/hodm_sine
% and finally loads hodm_sine onto the HODM with a call to AO

% issues (3/13/15)
% 1
% currently, is not iterative; used to demonstrate single speckle pair creation
% (can be made so be reading in and writing out the same hodm map)
% 2
% does not take individual DM actuator gains into account
% (can be made so by using the hodm_gain.mat data)

function[] = make_sine_rgd(x,y,amp,phase)

% given a speckle at pharo location x,y
% generate and load a sine wave on the hodm
% make_sine(5.2,-18,-100,0);

dim 	= 1024;
t	= 1:dim;
sine 	= zeros(dim);
ld	= 2.145e-6/16.667e-3/18e-6;		% pharo's 1 lambda/d in pixels (assuming Ksh)
xcycles	= x/ld;					% in lambda/d units
ycycles = y/ld;					% in lambda/d units

flat 	= convert_hodm_telem(load('/p3k/tables/hodm_map/hodm_flatmap_wl'));
flat 	= cat_crop_opd(flat);
flat 	= pad(flat,64);
mask 	= (flat ~= 0);

xsine 	= amp*sin(2*pi*t*xcycles/dim-pi*phase/180);
ysine 	= amp*sin(2*pi*t*ycycles/dim-pi*phase/180);
xsine 	= imresize(xsine,[64 64]);
ysine 	= imresize(ysine,[64 64]);
ysine	= rot90(ysine);
sine	= xsine+ysine;

new 	= sine+flat;
new 	= new.*mask;
new 	= pad(new,66);

figure(1),subplot(2,2,1),rim(flat)
figure(1),subplot(2,2,2),rim(mask)
figure(1),subplot(2,2,3),rim(sine)
figure(1),subplot(2,2,4),rim(new,[-300 300])

new = convert_hodm_telem(new);
file = '/p3k/tables/hodm_map/hodm_sine';
make_hmap(file,new);
poke_cmd = sprintf('ao hwfp hodm_map=%s',file);
system(poke_cmd);

end

function [with_waffle ] = add_waffle_to_flatmap( newflatmapfile, flatmapfile, waffle_amplitude )


fm = load(flatmapfile);
h=convert_hodm_telem(fm);
ww = add_waffle(waffle_amplitude, h);
map=convert_hodm_telem(ww);
make_hmap(newflatmapfile,map);
%load the saved map again
m2=load(newflatmapfile);
with_waffle=convert_hodm_telem(m2);
end


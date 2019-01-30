function []=make_hmap(fname,map)

% load hodm_flatmap_wl
% h=convert_hodm_telem(hodm_flatmap_wl);
% z=zernike_map;
% map=convert_hodm_telem(h+z);
% make_hmap('test',map);

fid = fopen([fname], 'w');
fprintf(fid, '%4d\n',map(1:3388));
fclose(fid);

return

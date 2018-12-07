function WF = add_waffle(eps, flatmap)
    %usage q = add_waffle(0.1, your_flatmap)
    if (~exist('flatmap', 'var'))
        flatmap = zeros(64, 64);
    end
    s=size(flatmap);
    wffl = waffle(eps, max(s));
    wffl2 = wffl(1:s(1), 1:s(2));
    WF = flatmap+wffl2;
end

function W = waffle(eps, N)
    %example: waffle(0.1, 5) 
    %to generate 5x5 pattern
    if (~exist('N', 'var'))
        N = 64;
    end
  row = mod(1 : N, 2);
  C = bsxfun(@xor, row', row); 
  W = (1-2*C)*eps;
end
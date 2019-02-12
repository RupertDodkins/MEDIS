
function W = waffle(eps, N)
    %example: waffle(0.1, 
    if (~exist('N', 'var'))
        N = 64;
    end
  row = mod(1 : N, 2);
  C = bsxfun(@xor, row', row); 
  W = (1-2*C)*eps
  
end
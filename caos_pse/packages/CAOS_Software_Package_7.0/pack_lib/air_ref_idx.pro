; $Id: air_ref_idx.pro,v 1.1.1.1 2003/03/07 10:46:32 marcel Exp $
;
function air_ref_idx, lambda

dummy = lambda*1D6
ref_idx = 1D + ( 6.43D-5 +                    $
               2.95D-2/(146D - dummy^(-2)) +  $
               2.55D-4/(41.D - dummy^(-2))    $
               )

return, ref_idx
end

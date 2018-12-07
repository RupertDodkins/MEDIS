pro ownscreen, file_in, file_out

screen=readfits(file_in)

dim_x         = (size(screen))[1]
dim_y         = (size(screen))[2]

header = psg_empty_header()                    ; initialize screens' file header
header.n_screens = 1                           ; and define its different fields
header.dim_x     = dim_x
header.dim_y     = dim_y
header.method    = 0
header.model     = 0
header.sha       = 0
header.L0        = !VALUES.F_INFINITY
header.seed1     = 0
header.seed2     = 0
header.double    = 0B

openw, unit, file_out, /GET_LUN, /XDR, ERROR=error
                                               ; open file location
writeu, unit, header                           ; write header first
writeu, unit, screen

if keyword_set(get_lun) then free_lun, unit else close, unit
                                               ; close file location
end

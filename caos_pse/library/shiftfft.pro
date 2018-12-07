; function for the ATM module
; june 1998: written (Marcel Carbillet, OAA,
;                     Simone Esposito, OAA,
;                     Armando Riccardi, OAA)
; input_fft is the fft of the array to be shifted
; delta is the shift in pixels in x and y: delta = [delta_x, delta_y]
; out_screen is the shifted array
; used as: out_screen = shiftfft(input_fft, delta)

function shiftfft, input_fft, delta

; parameters

np      = (size(input_fft))[1]
error   = 0L

; program

freq_x = rebin(shift(findgen(np) - np/2, -np/2), np, np)
freq_y = rotate(freq_x, 1)
fatt   = exp( -complex(0,1)*2*!pi/np * (freq_x*delta[0]+freq_y*delta[1]) )

out_screen = float(fft(input_fft * fatt, /inverse))

return, out_screen
end

;+
;TELL_TYPE
;result = tell_type(n_type, F_TYPE=format_type)
;
; returns the name of the type code
;
;n_type: type codes return by the size function.
;
;KEYWORDS 
;
; F_TYPE: return the format type associated to the n_type.
;
; HISTORY
; written by D.Zanotti(DZ)
; Osservatorio Astrofisico di Arcetri, ITALY
; zanotti@arcetri.astro.it
; 
;
;-

function tell_type, n_type, F_TYPE=format_type
case n_type of
      0:  begin
            type_name = "undefined"
            format_type =""  
          end  
      1:  begin
            type_name = "byte"
            format_type = "I"
          end
      2:  begin
            type_name = "int"
            format_type="I"  
          end  
      3:  begin
            type_name = "long"
            format_type = "I12"  
          end
      4:  begin
            type_name = "float"
            format_type ="G15.8"  
          end  
      5:  begin
            type_name = "double"
            format_type = "D25.16"  
          end
      6:  begin
            type_name = "complex"
            format_type = "G"
          end  
      7:  begin
            type_name = "string"
            format_type = "A"
          end  
      8:  begin
            type_name = "struct"
            format_type =""
          end  
      9:  begin
            type_name = "dcomplex"
            format_type = "D"
          end
      10: begin
            type_name = "pointer"
            format_type =""
          end  
      11: begin
            type_name = "objref"
            format_type =""
         end   
      12: begin 
            type_name = "uint"
            format_type = "I7"
          end  
      13: begin  
            type_name = "ulong"
            format_type = "I12"
          end
      14: begin
            type_name = "long64"
            format_type = "I22"
          end
      15: begin
            type_name = "ulong64"
            format_type = "I22"
          end
      else: message, "Not supported data type"
 endcase

;=============
return, type_name
end


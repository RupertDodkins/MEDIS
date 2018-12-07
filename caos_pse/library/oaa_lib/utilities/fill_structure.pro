; $Id: fill_structure.pro,v 1.1 2004/12/15 19:02:40 riccardi Exp $

pro fill_structure, data, struc

    n_bit = type2nbits(data[0])
    if n_bit lt 8 then message, "Unexpected input data type!"

    n_byte_tot = n_elements(data)*(n_bit/8)
    buf = byte(data, 0, n_byte_tot)

    nt = n_tags(struc)
    ns = n_elements(struc)
    count = 0UL
    for j=0,ns-1 do begin
        for i=0,nt-1 do begin
            n_bit = type2nbits(struc[j].(i), TYPE=type)
            if n_bit lt 8 then message, "Unexpected tag type in passed structure!"
            n_el_tag = n_elements(struc[j].(i))
            n_byte_tag = n_bit/8
            count1 = count+n_el_tag*n_byte_tag-1
            if count1 ge n_byte_tot then message, "Input data buffer does not contain enough data to fill the structure!"
            struc[j].(i) = fix(buf[count:count1],0,n_el_tag,TYPE=type)
            count = count1+1
        endfor
    endfor

    if count lt n_byte_tot then message, "Input data buffer containes unused data.", /INFO
end
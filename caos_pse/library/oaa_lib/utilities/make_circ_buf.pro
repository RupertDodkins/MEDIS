Function empty_circ_buf, circ_buf

    return, (circ_buf.header.curr_id eq -1)

End


Function push_circ_buf, data, circ_buf
    
    if (n_elements(data) eq 0) or (n_elements(circ_buf) eq 0 ) then begin
        print, "No complete input provided. Returning."
        return, -1
    endif
    ;if (n_tags(data) eq 0) or (n_tags(circ_buf) eq 0 ) then begin
    ;    print, "Invalid input. No push done."
    ;    return, -1
    ;endif
    
    names = tag_names(circ_buf)
    dummy = where(strmatch(names, 'queue', /FOLD_CASE) EQ 1, cc)
    if cc ne 1 then begin
        print, "Invalid input circular buffer. No push done."
        return, -1
    endif

    if total(size(circ_buf.header.template) ne size(data)) then begin
        print, "Invalid input data. No push done."
        return, -1
    endif

    if test_type(data, /STRUCT) then begin
        print, "Input data must be a structure as the template. No push done."
        return, -1
    endif
        v1 = tag_names(data)
        v2 = tag_names(circ_buf.header.template)
        if (total(size(circ_buf.header.template) ne size(data)) ne 0) or (total((v1[sort(v1)]) eq v2(sort(v2))) ne n_elements(v2)) then begin
            print, "Invalid input data. No push done."
            return, -1
        endif

    ;end checks
    
    new_curr_id = (circ_buf.header.curr_id + 1) mod circ_buf.header.length
    circ_buf.header.curr_id = new_curr_id
    circ_buf.queue[circ_buf.header.curr_id] = data
    struct_name = tag_names(circ_buf, /STRUCT)
    if struct_name eq "" then struct_name = "Unspecified."
    if keyword_set(verbose) then print, "PUSH done on circ_buf "+struct_name
    return, 0
    

End

Function read_circ_buf, circ_buf, pos

    if (n_elements(circ_buf) eq 0 ) then begin
        print, "No complete input provided. Returning."
        return, -1
    endif
    if (n_tags(circ_buf) eq 0 ) then begin
        print, "Invalid input. No read done."
        return, -1
    endif
    
    names = tag_names(circ_buf)

    v1 = tag_names(circ_buf)
    v2 = ['HEADER', 'QUEUE']
    if total((v1[sort(v1)]) eq v2(sort(v2))) ne n_elements(v2) then begin
stop
        print, "Invalid input data. No read done."
        return, -1
    endif

    ;end checks
    
    struct_name = tag_names(circ_buf, /STRUCT)
    if struct_name eq "" then struct_name = "Unspecified."
    if keyword_set(verbose) then print, "READ done on circ_buf "+struct_name
    
    if n_elements(pos) eq 0 then id = circ_buf.header.curr_id else id = abs(fix(pos)) mod circ_buf.header.length
    return, circ_buf.queue[id]
 


End

;template must be a structure
Function make_circ_buf, template, length, NAME=name

    if n_elements(length) eq 0 then length=3
    if test_type(template, /STRUCT) then begin
        print, "Input template must be a structure. No circular buffer created."
        return, -1
    endif

    queue = replicate(template, length)
    header = { $
        curr_id   : -1L,       $
        length    : length,   $
        template  : template  $
    }    


    return, create_struct("header", header, "queue", queue , NAME=name)

End

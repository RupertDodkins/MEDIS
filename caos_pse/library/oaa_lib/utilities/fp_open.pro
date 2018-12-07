; $Id: fp_open.pro,v 1.2 2004/04/08 11:23:28 marco Exp $
;
;+
; NAME:
;	FP_OPEN
;
; PURPOSE:
;	Open the communication with a field point device.
;
; CATEGORY:
;	Communication initialization.
;
; CALLING SEQUENCE:
;	err =  fp_open(com_port_str, fp_config, VERBOSE=verb, PORT_ID=port_id)
;
; INPUTS:
;	com_port_str: input structure.
;					If the device is driven by socket, it needs two fields:
;								- ip_address: 	ipaddress of the device
;								- port:			port number
;					If the device is a COM port, it's need only the string name of the port.
; OUTPUT:
;	fp_config: 	configuration structure
;
; KEYWORDS:
;	VERBOSE: prints more informations.
;	PORT_ID: return the port_id opened.
;
; PROCEDURE:
;	The procedure collects the configuration data of the field point device and return all in the structure fp_config.
; 	 To close a open connection with the field point, just have a "free_lun" of port_id.
; 	 If there is no port_id keyword specified, the connection is closed at the and of the routine automatically.
;
; MODIFICATION HISTORY:
;
;	Created by Armando Riccardi on 2003

;	Modified 2003/07/16 busoni
;	 Added control if Empty Base is present
;	 Added section for FP-AI-100
;
;	Modified 2004/01/16 riccardi
;	 Socket communication is now supported thru serial<->TCP/IP converter
; 	 Added VERBOSE and PORT_ID keywords
; 	 Changes in case of trapped error (an error code is returned without stopping)
; 	08 Apr 2004 M.Xompero
; 	 Arg_present test fixed
;-

function fp_open, com_port_str, fp_config, VERBOSE=verb, PORT_ID=port_id

;;					 WARNING
;;
;; The communication module is supposed to be channel 00

	 close_port = not ( arg_present(port_id) or n_elements(port_id)) 
    ;; Clear the Power Up flag of the communication module
    err = fp_send_command(com_port_str, '00A', ERROR=err_resp, VERB=verb, PORT_ID=dummy)
    if err ne 0L then begin
    	if n_elements(dummy) ne 0 then free_lun, dummy
        return, err
    endif
    port_id = dummy
	;; Reads all Module IDs
    err = fp_send_command(com_port_str, '00!B', resp, ERROR=err_resp, VERB=verb, PORT_ID=port_id)
    if err ne 0L then begin
        free_lun, port_id
        return, err
    endif

    ;; extract the number of modules
    reads, strmid(resp, 0, 2), n_modules, FORMAT="(Z2.2)"

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; ONLY systems with just one communication module and   ;;
    ;; signal conditioning modules with 8 channels per module;;
    ;; are implemented at the moment. At least one signal    ;;
    ;; conditioning module must be present.                  ;;
    ;; The communication module is supposed to be channel 00 ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;; allocate memory for the configuration structure
    ;;
    channel_struc =               $
        {                         $
            attrib_name:    ''  , $
            attrib_setting: ''  , $
            attrib_entry:   '00', $
            range_name:     ''  , $
            range_entry:    '00'  $
        }

    module_struc =          $
        {                   $
            ID:     '0000', $
            name:   ''    , $
            addr:   '00'  , $
            ch: replicate(channel_struc, 8) $
        }

    comm_module =           $
        {                   $
            ID:     '0000', $
            name:   ''    , $
            addr:   '00'    $
        }

    fp_config =                                          $
        {                                                $
            com_port_str:    com_port_str,                           $
            comm_module: comm_module,                    $
            n_modules: n_modules-1,                      $
            module: replicate(module_struc, n_modules-1) $
        }


    i_mod = 0

;*******************************************************************************************
;
; Starts loop on the detected modules in order to clear the power up flag of the module and
; to get the attributes of all channels of the module
;

    for i=0,n_modules-1 do begin

        ;; extract the module ID
        mod_ID = strmid(resp, 2+i*4, 4)

        ;; set the channel number (2-digit HEX string)
        addr = string(i, FORMAT="(Z2.2)")

        ;; Clear the Power Up flag of the module

		if mod_ID ne 'FFFF' then begin
        	err = fp_send_command(com_port_str, addr+'A', ERROR=err_resp, VERB=verb, PORT_ID=port_id)
        	if err ne 0L then begin
       	    	free_lun, port_id
  	    	      return, err
  		    endif
		endif

        case mod_ID of
            '0001': begin
                ;; FP-1000, RS-232 communication module
                fp_config.comm_module.addr = addr
                fp_config.comm_module.name = "FP-1000"
                fp_config.comm_module.ID   = mod_ID
            end


            '0002': begin
                ;; FP-1001, RS-485 communication module
                fp_config.comm_module.addr = addr
                fp_config.comm_module.name = "FP-1001"
                fp_config.comm_module.ID   = mod_ID
            end


            '0101': begin
			    ;; FP-AI-110, 16bit analog inputs
			                fp_config.module[i_mod].addr = addr
			                fp_config.module[i_mod].name = "FP-AI-110"
			                fp_config.module[i_mod].ID   = mod_ID

			                position = '00FF'    ;; all the 8 channels
			                attr_mask = '0001' ;; get the attribute: Filter setting
			                range_mask= '1'    ;; get the range

			                dummy = position
			                dummy1= attr_mask + range_mask

			                for j=0,7 do dummy = dummy + dummy1

			                command_ch = addr + "!E" + dummy
			                ;; get the attributes for all the channels in the module
			                err = fp_send_command(com_port_str, command_ch, resp_ch $
			                                     , ERROR=err_resp, VERB=verb, PORT_ID=port_id)
			                if err ne 0L then begin
			                    free_lun, port_id
			                    fp_config.com_port_str = ""
			                    return, err
			                endif

			                for j=0,7 do begin
			                    attrib_entry = strmid(resp_ch, j*4  , 2)
			                    range_entry  = strmid(resp_ch, j*4+2, 2)
			                    j_ch = 7-j
			                    fp_config.module[i_mod].ch[j_ch].attrib_entry = attrib_entry
			                    fp_config.module[i_mod].ch[j_ch].attrib_name = "Filter setting"
			                    fp_config.module[i_mod].ch[j_ch].range_entry  = range_entry

			                    case attrib_entry of
			                        '00': $
			                            fp_config.module[i_mod].ch[j_ch].attrib_setting = '60 Hz Filter'

			                        '01': $
			                            fp_config.module[i_mod].ch[j_ch].attrib_setting = '50 Hz Filter'

			                        '02': $
			                            fp_config.module[i_mod].ch[j_ch].attrib_setting = '500 Hz Filter'

			                        else: begin
			                            free_lun, port_id
			                            fp_config.com_port_str = ""
			                            message, "Not supported attribute for module " $
			                                   + fp_config.module[i_mod].name, /CONT
			                            return, -4000L
			                        end
			                    endcase

			                    case range_entry of
			                        '00': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '0-21 mA'

			                        '01': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '3.5-21 mA'

			                        '02': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '+/-21 mA'

			                        '03': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '+/-10.4 V'

			                        '04': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '0-10.4 V'

			                        '05': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '+/-5.2 V'

			                        '06': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '0-5.2 V'

			                        '07': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '+/-1.04 V'

			                        '08': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '0-1.04 V'

			                        '09': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '+/-325 mV'

			                        '0A': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '+/-65 mV'

			                        else: begin
			                            free_lun, port_id
			                            fp_config.com_port_str = ""
			                            message, "Not supported range for module " $
			                                   + fp_config.module[i_mod].name, /CONT
			                            return, -4001L
			                        end
			                    endcase
			                endfor
			                i_mod = i_mod+1
            end ;; '0101':


            '010B': begin
                ;; FP-RTD-122, RTD inputs
			                fp_config.module[i_mod].addr = addr
			                fp_config.module[i_mod].name = "FP-RTD-122"
			                fp_config.module[i_mod].ID   = mod_ID

			                position = '00FF'    ;; all the 8 channels
			                attr_mask = '0001' ;; get the attribute: RTD Type
			                range_mask= '1'    ;; get the range

			                dummy = position
			                dummy1= attr_mask + range_mask

			                for j=0,7 do dummy = dummy + dummy1

			                command_ch = addr + "!E" + dummy
			                ;; get the attributes for all the channels in the module
			                err = fp_send_command(com_port_str, command_ch, resp_ch $
			                                     , ERROR=err_resp, VERB=verb, PORT_ID=port_id)
			                if err ne 0L then begin
			                    free_lun, port_id
			                    fp_config.com_port_str = ""
			                    return, err
			                endif

			                for j=0,7 do begin
			                    attrib_entry = strmid(resp_ch, j*4  , 2)
			                    range_entry  = strmid(resp_ch, j*4+2, 2)
			                    j_ch = 7-j
			                    fp_config.module[i_mod].ch[j_ch].attrib_entry = attrib_entry
			                    fp_config.module[i_mod].ch[j_ch].attrib_name = "RTD Type"
			                    fp_config.module[i_mod].ch[j_ch].range_entry  = range_entry

			                    case attrib_entry of
			                        '00': $
			                            fp_config.module[i_mod].ch[j_ch].attrib_setting = 'Pt100, a=0.00375'

			                        '01': $
			                            fp_config.module[i_mod].ch[j_ch].attrib_setting = 'Pt100, a=0.00385'

			                        '02': $
			                            fp_config.module[i_mod].ch[j_ch].attrib_setting = 'Pt100, a=0.003911'

			                        '03': $
			                            fp_config.module[i_mod].ch[j_ch].attrib_setting = 'Pt100, a=0.003916'

			                        '04': $
			                            fp_config.module[i_mod].ch[j_ch].attrib_setting = 'Pt100, a=0.003920'

			                        '05': $
			                            fp_config.module[i_mod].ch[j_ch].attrib_setting = 'Pt100, a=0.003926'

			                        '06': $
			                            fp_config.module[i_mod].ch[j_ch].attrib_setting = 'Pt1000, a=0.00375'

			                        '07': $
			                            fp_config.module[i_mod].ch[j_ch].attrib_setting = 'Pt1000, a=0.00385'

			                        '08': $
			                            fp_config.module[i_mod].ch[j_ch].attrib_setting = 'Pt1000, a=0.003911'

			                        '09': $
			                            fp_config.module[i_mod].ch[j_ch].attrib_setting = 'Pt1000, a=0.003916'

			                        '0A': $
			                            fp_config.module[i_mod].ch[j_ch].attrib_setting = 'Pt1000, a=0.003920'

			                        '0B': $
			                            fp_config.module[i_mod].ch[j_ch].attrib_setting = 'Pt1000, a=0.003926'

			                        else: begin
			                            free_lun, port_id
			                            fp_config.com_port_str = ""
			                            message, "Not supported attribute for module " $
			                                   + fp_config.module[i_mod].name, /CONT
			                            return, -4000L
			                        end
			                    endcase

			                    case range_entry of
			                        '26': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '73-1123 K'

			                        '27': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '-200, +850 C'

			                        '28': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '-328, +1562 F'

			                        '30': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '0-400 Ohm'

			                        '31': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '0-4000 Ohm'

			                        else: begin
			                            free_lun, port_id
			                            fp_config.com_port_str = ""
			                            message, "Not supported range for module " $
			                                   + fp_config.module[i_mod].name, /CONT
			                            return, -4001L
			                        end
			                    endcase
			                endfor
			                i_mod = i_mod +1
            end ;; '010B': RTD-122, RTD inputs



			'010A': begin
			 	;; FP-AI-100, 8 Channel, 12-Bit Analog Input Module
			                fp_config.module[i_mod].addr = addr
			                fp_config.module[i_mod].name = "FP-AI-100"
			                fp_config.module[i_mod].ID   = mod_ID

			                position = '00FF'    ;; all the 8 channels
			                attr_mask = '0000' ;; get the attribute:
			                range_mask= '1'    ;; get the range

			                dummy = position
			                dummy1= attr_mask + range_mask

			                for j=0,7 do dummy = dummy + dummy1

			                command_ch = addr + "!E" + dummy
			                ;; get the attributes for all the channels in the module
			                err = fp_send_command(com_port_str, command_ch, resp_ch $
			                                     , ERROR=err_resp, VERB=verb, PORT_ID=port_id)
			                if err ne 0L then begin
			                    free_lun, port_id
			                    fp_config.com_port_str = ""
			                    return, err
			                endif

			                for j=0,7 do begin
			                    range_entry  = strmid(resp_ch, j*2, 2)
			                    j_ch = 7-j
			                    fp_config.module[i_mod].ch[j_ch].range_entry  = range_entry


			                    case range_entry of
			                        '00': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '0-24 mA'

			                        '01': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '3.5-24 mA'

			                        '02': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '+/-24 mA'

			                        '05': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '+/-6.0 V'

			                        '06': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '0-6.0 V'

			                        '07': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '+/-1.2 V'

			                        '08': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '0-1.2 V'

			                        '0E': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '0-18 V'

			                        '0F': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '+/-30 V'

			                        '11': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '0-30 V'

			                        '12': $
			                            fp_config.module[i_mod].ch[j_ch].range_name = '+/-15 V'

			                        else: begin
			                            free_lun, port_id
			                            fp_config.com_port_str = ""
			                            message, "Not supported range for module " $
			                                   + fp_config.module[i_mod].name, /CONT
			                            return, -4001L
			                        end
			                    endcase
			                endfor
			                i_mod = i_mod +1
			 end ;; '010A': FP-AI-100



			'FFFF': begin
                ;; Empty base
                BEEP
				message, "WARNING!!!! EMPTY BASE PRESENT", /INFO
                fp_config.comm_module.addr = addr
                fp_config.comm_module.name = "EMPTY BASE"
                fp_config.comm_module.ID   = mod_ID


            end


            else: begin
                free_lun, port_id
                fp_config.com_port_str = ""
                message, "Not supported module ID " + mod_ID, /CONT
                return, -4002L
            end
        endcase
    endfor

	if close_port then free_lun, port_id
    return, 0L
end


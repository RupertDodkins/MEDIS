; $Id: fp_adc2meas.pro,v 1.1 2004/02/24 12:24:18 riccardi Exp $

function fp_adc2meas, adc_val, module_ID, range_entry, UNIT=unit

    case module_ID of

        '010B': begin ;; FP-RTD-122
            case range_entry of
                '26': begin
                    unit = 'K'
                    min_scale = 73.0
                    max_scale = 1123.0
                end

                '27': begin
                    unit = 'C'
                    min_scale = -200.0
                    max_scale = 850.0
                end

                '28': begin
                    unit = 'F'
                    min_scale = -328.0
                    max_scale = 1562.0
                end

                '30': begin
                    unit = 'Ohm'
                    min_scale = 0.0
                    max_scale = 400.0
                end

                '31': begin
                    unit = 'Ohm'
                    min_scale = 0.0
                    max_scale = 4000.0
                end

                else: message, 'Not supported range type for module '+module_ID
            endcase
        end ;; FP-RTD-122


'010A': begin ;; FP-AI-100
            case range_entry of
                '00': begin
                    unit = 'mA'
                    min_scale = 0.0
                    max_scale = 24.0
                end

                '01': begin
                    unit = 'mA'
                    min_scale = 3.5
                    max_scale = 24.0
                end

                '02': begin
                    unit = 'mA'
                    min_scale = -24.0
                    max_scale = 24.0
                end


				'05': begin
                    unit = 'V'
                    min_scale = -6.0
                    max_scale = 6.0
                end

                '06': begin
                    unit = 'V'
                    min_scale = 0.0
                    max_scale = 6.0
                end

                '07': begin
                    unit = 'V'
                    min_scale = -1.2
                    max_scale = 1.2
                end

                '08': begin
                    unit = 'V'
                    min_scale = 0.0
                    max_scale = 1.2
                end

                '0E': begin
                    unit = 'V'
                    min_scale = 0.0
                    max_scale = 18.0
                end

				'0F': begin				;!!!!!ERROR ON MANUAL ! We must use +/- 36 V instead of +/- 30 V
                    unit = 'V'
                    min_scale = -36.0
                    max_scale = 36.0
                end

                '11': begin
                    unit = 'V'
                    min_scale = 0.0
                    max_scale = 30.0
                end

				'12': begin
                    unit = 'V'
                    min_scale = -15.0
                    max_scale = 15.0
                end

                else: message, 'Not supported range type for module '+module_ID
            endcase
        end ;; FP-AI-100


        '0101': begin ;; FP-AI-110
            case range_entry of
                '00': begin
                    unit = 'mA'
                    min_scale = 0.0
                    max_scale = 21.0
                end

                '01': begin
                    unit = 'mA'
                    min_scale = 3.5
                    max_scale = 21.0
                end

                '02': begin
                    unit = 'mA'
                    min_scale = -21.0
                    max_scale = 21.0
                end

                '03': begin
                    unit = 'V'
                    min_scale = -10.4
                    max_scale = 10.4
                end

                '04': begin
                    unit = 'V'
                    min_scale = 0.0
                    max_scale = 10.4
                end

				'05': begin
                    unit = 'V'
                    min_scale = -5.2
                    max_scale = 5.2
                end

                '06': begin
                    unit = 'V'
                    min_scale = 0.0
                    max_scale = 5.2
                end

                '07': begin
                    unit = 'V'
                    min_scale = -1.4
                    max_scale = 1.4
                end

                '08': begin
                    unit = 'V'
                    min_scale = 0.0
                    max_scale = 1.4
                end

                '09': begin
                    unit = 'mV'
                    min_scale = -325.0
                    max_scale = 325.0
                end

				'0A': begin
                    unit = 'mV'
                    min_scale = -65.0
                    max_scale = 65.0
                end

                else: message, 'Not supported range type for module '+module_ID
            endcase
        end ;; FP-AI-110


        else: message, 'Not supported module '+module_ID
    endcase


   	return, adc_val/(65535.0)*(max_scale-min_scale) + min_scale


end


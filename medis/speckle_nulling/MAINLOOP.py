import speckle_killer_fullaperture
import define_control_annulus_auto
import add_waffle_simple
import DM_registration as DMR

if __name__ == "__main__":
    configfilename = 'speckle_null_config.ini'
    configspecfile = 'speckle_null_config.spec'
    
    add_waffle_simple.run(configfilename, configspecfile)
    #initial image registration
    DMR.run(configfilename_configspecfile)  
    
    while True:
    
        define_control_annulus_auto.run( configfilename, configspecfile)
        
        
        DMR.run(configfilename_configspecfile)  

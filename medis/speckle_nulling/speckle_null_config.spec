[IM_PARAMS]
    centerx = float
    centery = float
    angle = float
    lambdaoverd = float

[CONTROLREGION]
    verticesx = float_list
    verticesy = float_list
    filename = string
    innerannulus = float
    outerannulus = float

[CALSPOTS]
    waffleamp = float
    wafflekvec = float
    spot10oclock = float_list
    spot1oclock = float_list
    spot4oclock = float_list
    spot7oclock = float_list

[AOSYS]
    dmcyclesperap = integer

[BACKGROUNDS_CAL]
    dir = string
    N   = integer
    bgdtime = int
    flattime = int

[INTENSITY_CAL]
    auto = boolean
    #stepsize in l/d units
    exptime = int
    stepsize = float
    min      = float
    max      = float
    default_dm_amplitude = float
    aperture_radius = float
    [[abc]]    
    a = float
    b = float
    c = float

[DETECTION]
    max_speckles = integer
    method = string
    window = integer
    offset = integer

[NULLING]
    null_gain = boolean
    referenceval = float
    phases = float_list
    amplitudegains = float_list
    exclusionzone = float
    default_flatmap_gain = float
    outputdir = string
    cent_off = boolean

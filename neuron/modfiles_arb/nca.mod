TITLE nca.mod  
 
: konduktivitas valtozas hatasa- somaban 
 
UNITS {
    (mA) =(milliamp)
    (mV) =(millivolt)
    (uF) = (microfarad)
    (molar) = (1/liter)
    (nA) = (nanoamp)
    (mM) = (millimolar)
    (um) = (micron)
}
 
: interface 
NEURON { 
    THREADSAFE
    SUFFIX nca
    USEION nca READ enca WRITE inca VALENCE 2
    RANGE  gnca
    RANGE gncabar
    RANGE cinf, ctau, dinf, dtau
    GLOBAL q10

    RANGE inca : NEURON
}
 
PARAMETER {
    v (mV)
    celsius = 6.3 (degC)
    dt (ms)
    gncabar (mho/cm2)
}
 
STATE {
    c
    d
}
 
ASSIGNED {
    gnca (mho/cm2)
    cinf dinf
    ctau (ms)
    dtau (ms)
    cexp
    dexp
    q10

    enca : NEURON
    inca : NEURON
} 

: currents
BREAKPOINT {
    SOLVE states METHOD cnexp
    gnca = gncabar*c*c*d
    inca = gnca*(v-enca)
}

INITIAL {
    trates(v, celsius)
    c = cinf
    d = dinf
}

: states
DERIVATIVE states {	:Computes state variables m, h, and n 
    trates(v, celsius)	:      at the current v and dt.
    c' = (cinf - c)/ctau
    d' = (dinf - d)/dtau
}

: rates
PROCEDURE rates(v, celsius) {  :Computes rate and other constants at current v.
                      :Call once from HOC to initialize inf at resting v.
    LOCAL  alpha, beta, sum
    q10 = 3^((celsius - 6.3)/10)
                :"c" NCa activation system
    alpha = -0.19*vtrap(v-19.88,-10)
    beta = 0.046*exp(-v/20.73)
    sum = alpha+beta
    ctau = 1/sum
    cinf = alpha/sum
                :"d" NCa inactivation system
    alpha = 0.00016*exp(-v/48.4)
    beta = 1/(exp((-v+39)/10)+1)
    sum = alpha+beta
    dtau = 1/sum
    dinf = alpha/sum
}
 
PROCEDURE trates(v, celsius) {  :Computes rate and other constants at current v.
                      :Call once from HOC to initialize inf at resting v.
    LOCAL tinc

    rates(v, celsius)	: not consistently executed from here if usetable_hh == 1
                        : so don't expect the tau values to be tracking along with
                        : the inf values in hoc
    tinc = -dt * q10
    cexp = 1 - exp(tinc/ctau)
    dexp = 1 - exp(tinc/dtau)
}
 
FUNCTION vtrap(x,y) {  :Traps for 0 in denominator of rate eqns.
    vtrap = y*efun(x/y) : NEURON
}

FUNCTION efun(z) { : NEURON
	if (fabs(z) < 1e-4) {
		efun = 1 - z/2
	}else{
		efun = z/(exp(z) - 1)
	}
}

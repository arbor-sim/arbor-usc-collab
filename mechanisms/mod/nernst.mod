: Compute reversal potential for generic ion using Nernst equation.
:
: TODO: support global derived parameters via e.g. GLOBAL + ASSIGNED,
: so that we don't need to store a copy of coeff at every CV.

NEURON {
    SUFFIX nernst
    USEION x READ xi, xo WRITE ex VALENCE zx
    GLOBAL R, F
    RANGE coeff
}

PARAMETER {
    R = 8.3144598 (joule/kelvin/mole) : gas constant
    F = 96485.33289 (coulomb/mole) : Faraday's constant
    celsius : temperature in °C (set externally)
}

ASSIGNED {
    coeff
}

INITIAL {
    coeff = R*(celsius+273.15)/(zx*F)*1000
}

STATE {
}

BREAKPOINT  {
    ex = coeff*log(xo/xi)
}


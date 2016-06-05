import pysynphot as S
import os

def get_fl(system='kic1255',renormBand='Kmag'):
    """ Get the fluxes"""
    if system == 'kic1255':
        ## From Rappapor et al. 2012
        sp = S.Icat('phoenix', 4400, 0.0, 4.63)
        Jmag = 14.021
        Kmag = 13.319
        
    elif system == 'k2-22':
        ## From Sanchis-Ojeda 2016
        sp = S.Icat('phoenix', 3830, 0.0, 4.65)
        Jmag = 12.726
        Kmag = 11.924
        
    else:
        print 'No Valid System specified'
    
    ## Get the 2MASS bandpasses
    tmassdir = os.path.join(os.environ['TEL_DATA'],'2mass')
    bpK = S.FileBandpass(os.path.join(tmassdir,'2mass_k_ang.txt'))
    bpJ = S.FileBandpass(os.path.join(tmassdir,'2mass_j_ang.txt'))
    
    # Get the IRAC bandpasses
    iracdir = os.path.join(os.environ['TEL_DATA'],'irac')
    irac45 = S.FileBandpass(os.path.join(iracdir,'irac_45_ang.txt'))
    
    # Renormalize spectrum
    if renormBand == 'Kmag':
        renormBandpass = bpK
        renormMag = Kmag
    else:
        renormBandpass = bpJ
        renormMag = Jmag
    
    sp_norm = sp.renorm(renormMag,'vegamag',renormBandpass)
    obs = S.Observation(sp_norm,irac45)
    
    ## Get the flux at the wavelegnth
    stim = obs.effstim('uJy')
    print "Flux at 4.5um is "+str(stim)+" uJy"
    
    
    
    
    
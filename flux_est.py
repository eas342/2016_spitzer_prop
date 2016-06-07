import pysynphot as S
import os
import matplotlib.pyplot as plt
from astropy.io import ascii
import pdb

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
    irac36 = S.FileBandpass(os.path.join(iracdir,'irac_36_ang.txt'))
    iracnames = ['IRAC 3.6um', 'IRAC 4.5um']
    
    # Renormalize spectrum
    if renormBand == 'Kmag':
        renormBandpass = bpK
        renormMag = Kmag
    else:
        renormBandpass = bpJ
        renormMag = Jmag
    
    sp_norm = sp.renorm(renormMag,'vegamag',renormBandpass)
    
    for iracInd, iracBP in enumerate([irac36,irac45]):
        obs = S.Observation(sp_norm,iracBP)    
        ## Get the flux at the wavelegnth
        stim = obs.effstim('uJy')
        print "Flux for "+iracnames[iracInd]+" is "+str(stim)+" uJy"
    
def make_phasep():
    
    filel = ['kic1255_phased_transit.txt','k2-22_phased_transit.txt']
    fxrange = [[0,1],[0]]
    plt.close()
    fig, ax = plt.subplots(1,2)
    for ind, onef in enumerate(filel):
        dat = ascii.read(onef,names=['phase','flux','error','junk'],delimiter=' ',data_start=0)
        dat['phase'] = dat['phase'] - 0.5 ## I like phase 0 as mid-"transit"
        ax[ind].plot(dat['phase'],dat['flux'])
        ax[ind].set_ylim(0.993,1.002)
        ax[ind].set_xlim(-0.5,0.5)
        ax[ind].set_xlabel('Orbital Phase')
        ax[ind].set_ylabel('Normalized Flux')
    
    #plt.show()
    
    
    
    
    
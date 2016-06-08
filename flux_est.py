import pysynphot as S
import os
import matplotlib.pyplot as plt
from astropy.io import ascii
import pdb
import numpy as np
from numpy.random import RandomState

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
    
def make_phasep(dosim=False):
    """
    Plots the light curves either for Phased Kepler data or simulated Spitzer data
    """
    filel = ['kic1255_phased_transit.txt','k2-22_phased_transit.txt']
    pname = ['KIC 1255','K2-22']

    randomseeds = [232,110]
    repErrBar = [0.0005,0.0002  ]
    PPeriod = [0.6535538 * 24.,9.145872] ## hours, VanWerkhoven 2015, Sanchis-Ojeda 2015
    samTime = 0.17 ## sampling time for Error bar
    obsTimes= [[-3,2.5],[-2.4,1.9]] ## Start and end times in hr
    plt.close()
    fig, ax = plt.subplots(1,2,figsize=(9,3))
    #fig.set_size_inches(10, 6)
    for ind, onef in enumerate(filel):
        dat = ascii.read(onef,names=['phase','flux','error','junk'],delimiter=' ',data_start=0)
        
        dat['phase'] = dat['phase'] - 0.5 ## I like phase 0 as mid-"transit"
        
        if dosim == True:
            pcolor, ptype = 'blue', '-'
        else:
            pcolor, ptype = 'black', '-'
        ax[ind].plot(dat['phase'],dat['flux'],color=pcolor,linestyle=ptype)
        ax[ind].set_ylim(0.993,1.002)
        ax[ind].set_xlim(-0.5,0.5)
        ax[ind].set_xlabel('Orbital Phase')
        if ind == 0:
            ax[ind].set_ylabel('Normalized Flux')
        ax[ind].text(0.18, 0.997, pname[ind],fontweight='bold')

        ## Show the normalization
        ax[ind].plot([-0.5,0.5],[1,1],linestyle='--',color='green')

        if dosim == True:
            prng = RandomState(randomseeds[ind])
            timeArr = np.arange(obsTimes[ind][0]/PPeriod[ind],obsTimes[ind][1]/PPeriod[ind],
                                samTime / PPeriod[ind])
            npoint = timeArr.shape[0]
            error = repErrBar[ind] * np.ones(npoint)
            simdata = (np.interp(timeArr,dat['phase'],dat['flux']) + 
                       prng.randn(npoint) * repErrBar[ind])
            ax[ind].errorbar(timeArr,simdata,error,fmt='o',alpha=0.4,color='red',
                             markersize=4)
            
    plt.tight_layout()
    outname = 'transit_profiles.pdf'
    fig.savefig(outname)
    #plt.show()
    
    
    
    
    
;+
; NAME:
;	SNIRAC_WARM
;
; PURPOSE:
;	Calculates S/N for IRAC, including the Poisson noise
;       contirbution of the target for warm IRAC observations.
;
; CATEGORY:
;       Spitzer Space Telescope
;
; CALLING SEQUENCE:
;	SNIRAC
;
; OUTPUTS:
;	None.
;
; COMMON BLOCKS:
;	block1.
;
; RESTRICTIONS:
;	None.
;
; ASSUMPTIONS:
;   Signal-to-noise calculation is made using a 3 pixel radius aperture and a 
;   3-7 pixel background annulus.  This will produce noise values which are less
;   than optimal extractions by ~10% but residual pixel-phase errors can 
;   introduce greater noise if the optimal extraction uses inexact approximation
;   for PRF or source position.
;
; MODIFICATION HISTORY:
;       V1.0 - written by DWH, Spitzer SUST, March 2007
;       V1.1 - fixes for bugs found by Seppo (f_ch should not be changed 
;              in snirac_calc) and Sean (resolve_all calls obsolete program 
;              setlog under IDL 6.2-Mac).
;       V1.2 - as requested by Sean, removed 1.5x scaling of total noise 
;              (sigma), replaced with info in Help file telling users that 
;              S/N is an optimistic estimate and should be scaled by 
;              0.9-0.5x; also note this in the results window when a S/N 
;              value is returned. 
;       V2.0 - removed extraneous 200 and 400 second frametimes, corrected time 
;              used for determining signal and Poisson noise (exposure time is
;              more correct than frametime due to the Fowler sampling).  
;              Modified function and procedure names so that they will not 
;              conflict with cryo version of SNIRAC.  Removed background 
;              aperture settings and use a fixed aperture of 3 pixels and 3-7 
;              pixels background annulus in calculation
;       V2.1 - fixed passing of parameters in common block by removing a 
;              reinitialization. SJC
;       V2.2 - fixed gain values to 3.7 (April 19,2010)
;       V2.3 - adjusted Poisson noise to more appropriately account for Fowler 
;              sampling SJC 27 Sep 2010
;       V2.4 - corrected read noises used for both channels in full array 
;              frametimes SJC 17 July 2013
;                
;
;-
;***********************************************
;*** DON'T FORGET TO UPDATE THE VERSION NUMBER
;***********************************************

pro snirac_warm_event, ev

 forward_function snirac_warm_calc
 resolve_routine, 'snirac_warm_calc', /is_function, /no_recompile
 resolve_routine, ['snirac_warm', 'snirac_warm_event', 'snirac_warm_help', $
                   'snirac_warm_help_event'], /no_recompile

 common block1, VERSION, ch, frametime, arraymod, nexp, fd, background_sb;, rin, rout

 widget_control, ev.id, get_uvalue=uval
 if (n_elements(uval) eq 0) then uval = ''
 name = strmid(tag_names(ev, /structure_name), 7, 4)
 case (name) of
  'BUTT' : begin
            if (uval eq 'DONE') then begin
             widget_control, /destroy, ev.top
             return
            endif
            if (uval eq 'HELP') then begin
             snirac_warm_help
             return
            endif
            if (uval eq 'CALC') then begin
             if (fd lt 0.0 or background_sb lt 0.0) then begin
              out_text=' '
              widget_control, widget_info(ev.top, find_by_uname='info_window'), set_value=out_text, /append
              out_text='Enter values for at least Target Flux Density and Background Surface Brightness'
              widget_control, widget_info(ev.top, find_by_uname='info_window'), set_value=out_text, /append
              out_text=' '
              widget_control, widget_info(ev.top, find_by_uname='info_window'), set_value=out_text, /append
              return
             endif else begin
              ;***DEBUG print, ch, frametime, nexp, fd, background_sb, rin, rout=
              sn_out = snirac_warm_calc(ch, frametime, arraymod, nexp, fd, background_sb)
              out_text=' '
              widget_control, widget_info(ev.top, find_by_uname='info_window'), set_value=out_text, /append
              out_text='**********************************************************************'
              widget_control, widget_info(ev.top, find_by_uname='info_window'), set_value=out_text, /append
              out_text='Optimistic S/N = '+sn_out+' (scale by 0.9-0.5x -- see Help for more info)'
              widget_control, widget_info(ev.top, find_by_uname='info_window'), set_value=out_text, /append
              out_text='**********************************************************************'
              widget_control, widget_info(ev.top, find_by_uname='info_window'), set_value=out_text, /append
              out_text=' '
              widget_control, widget_info(ev.top, find_by_uname='info_window'), set_value=out_text, /append
              return
             endelse
            endif
           endcase
  'TEXT' : begin
            widget_control, ev.id, get_value=val
            case uval of
             'w_nexp' : begin
                         nexp = float(val)
                         out_text = 'Selected Total Number of Exposures: '+val
                        endcase
             'w_fd'   : begin
                         fd = float(val)
                         out_text = 'Selected Target Flux Density: '+val+' micro-Jy'
                        endcase
             'w_background_sb' : begin
                                  background_sb = float(val)
                                  out_text = 'Selected Background Surface Brightness: '+val+' (MJy/sr)'
                                 endcase
;             'w_rin'  : begin
;                          rin = float(val)
;                          out_text = 'Selected Inner Radius of Background Annulus: '+val+' pixels'
;                        endcase
;             'w_rout' : begin
;                          rout = float(val)
;                          out_text = 'Selected Outer Radius of Background Annulus: '+val+' pixels'
 ;                        endcase
            endcase
           endcase
  'LIST' : begin
            uval=uval[ev.index]
;            ch=1
;            frametime=30.0 
;            arraymod = 0

            case uval of 
             '1 (3.6 microns)' : begin
                                  ch=1
                                  out_text = 'Selected Channel: '+uval
                                 end
             '2 (4.5 microns)' : begin
                                  ch=2
                                  out_text = 'Selected Channel: '+uval
                                 end
 
              '0.02s sub'           : begin
             	                  arraymod = 1
                                  frametime=0.02
                                  out_text = 'Selected Frame Time: '+uval
                                  end
             '0.1s sub'           : begin
             	                  arraymod = 1
                                  frametime=0.1
                                  out_text = 'Selected Frame Time: '+uval
                                 end
             '0.4s sub'           : begin
             	                  arraymod = 1
                                  frametime=0.4
                                  out_text = 'Selected Frame Time: '+uval   
                                 end
             '2s sub'           : begin
             	                  arraymod = 1
                                  frametime=2.
                                  out_text = 'Selected Frame Time: '+uval                                 
			                     end
             '0.4s full'           : begin
                                   arraymod = 0
                                  frametime=0.4
                                  out_text = 'Selected Frame Time: '+uval
                                 end
             '0.6s full'           : begin
                                   arraymod = 0
                                  frametime=0.6
                                  out_text = 'Selected Frame Time: '+uval
                                 end
             '1.2s full'           : begin
                                   arraymod = 0
                                  frametime=1.2
                                  out_text = 'Selected Frame Time: '+uval
                                 end
             '2s full'             : begin
                                  arraymod = 0
                                  frametime=2.
                                  out_text = 'Selected Frame Time: '+uval
                                 end
             '6s full'             : begin
                                  arraymod = 0
                                  frametime=6.0
                                  out_text = 'Selected Frame Time: '+uval
                                 end
             '12s full'            : begin
                                  arraymod = 0
                                  frametime=12.0
                                  out_text = 'Selected Frame Time: '+uval
                                 end
             '30s full'            : begin
                                  arraymod = 0
                                  frametime=30.0
                                  out_text = 'Selected Frame Time: '+uval
                                 end
             '100s full'           : begin
                                  arraymod = 0
                                  frametime=100.0
                                  out_text = 'Selected Frame Time: '+uval
                                 end
            endcase
           endcase
 else:
 endcase

 widget_control, widget_info(ev.top, find_by_uname='info_window'), set_value=out_text, /append
end


; Code that does the noise calculation
function snirac_warm_calc, f_ch, f_frametime, f_arraymod, f_nexp, f_fd, $
                           f_background_sb
;+
; NAME:
;	SNIRAC_WARM_CALC
;
; PURPOSE:
;	Function to calculate estimate of signal-to-noise for an aperture 
;   photometry measurement of a source.  The function includes noise due to the
;   Poisson noise of the source, the Poisson noise contribution of the 
;   background to the uncertainty of the the background estimate determined from
;   the reference annulus
;
; CATEGORY:
;       Spitzer Space Telescope
;
; CALLING SEQUENCE:
;	snr = SNIRAC_WARM_CALC(channel, frametime, arraymode, nexp, flux, $
;                              background_sb)
;
;-


; adjust channel number to array subscript
 f_ch_int = fix(f_ch) - 1

; determine frametime index
 case 1 of
  f_frametime eq   0.02 : fr = 0
  f_frametime eq   0.1 : fr = 1
  f_frametime eq   0.4 and f_arraymod eq 1 : fr = 2
  f_frametime eq   2. and f_arraymod eq 1 : fr = 3
  f_frametime eq   0.4 and f_arraymod eq 0 : fr = 4
  f_frametime eq   0.6  : fr = 5
  f_frametime eq   1.2  : fr = 6  
  f_frametime eq   2. and f_arraymod eq 0 : fr = 7
  f_frametime eq   6.  : fr = 8
  f_frametime eq  12.  : fr = 9
  f_frametime eq  30.  : fr = 10
  f_frametime eq 100.  : fr = 11
  f_frametime eq 200.  : fr = 12
  f_frametime eq 400.  : fr = 13
 endcase

; Use a three pixel radius aperture in the calculation as this is more typical  
; of what observers might use and is large enough that it is not overly  
; sensitive to centroiding errors and effect of those on pixel-phase 
; calculations.
npix = !DPI * 3. * 3.
npix3 = !DPI * 10. * 10.

noisepix = [7.0, 7.2]

; and background annulus of 3-7 pixels
nback = !DPI * (7. * 7. - 3. * 3.)
nback3 = !DPI *(20. * 20. - 12. * 12.)

; scaling factor accounting for flux in source aperture (aperture correction)
apcorr = [1.124, 1.127]
apcorr2 = [1.3587, 1.39665]  ; An underestimate of the aperture correction, need the actual numbers from Jason

; readnoise updated for warm frame times
; readnoise revised 17 July 2013 based on in-flight noise values measured from
; dark field, and understanding that increase in readnoise is due to increased 
; 1/f noise at the warmer operating temperature.  Channel 1 has the more 
; significant increase. SJC 17 July 2013
; times are 0.02s, 0.1s, 0.4s, 2.s, 0.4f, 0.6f, 1.2f, 2f, 6f,  
;           12f, 30f, 100f, 200f, 400f
 sigma_readnoise = [[25.4, 13.4, 10.8, 10.8, 22.4, 22.4, 22.4, 16.0, 16.0, $
                     15.0, 14.6, 21.0, -8.1, -8.1], $ ; channel 1
                    [23.7, 12.1, 9.4, 9.4, 23.7, 23.7, 23.7, 12.1, 10.0,  $
                     10.4, 10.4, 16.0, -6.8, -6.8]]   ; channel 2
; sigma_readnoise = [[22.4, 11.8, 9.4, 9.4, 22.4, 22.4, 22.4, 11.8, 9.4, 9.4, 7.8, 8.4, 8.1, 8.1], $
;                    [23.7, 12.1, 9.4, 9.4, 23.7, 23.7, 23.7, 12.1, 9.4, 9.4, 7.5, 7.9, 6.8, 6.8]] old values
                    
; Warm fowler numbers
fowler_number = [[1, 2, 4, 8, 1, 1, 1, 4, 8, 8, 32, 32, 99, 99], $
                 [1, 2, 4, 8, 1, 1, 1, 4, 8, 8, 16, 16, 99, 99]]
                 
; Readout timing of array
clock_tick = [0.2, 0.01]

; Determine the integration time
f_inttime = f_frametime - clock_tick[f_arraymod] * fowler_number[fr, f_ch_int]

; For determining the photon noise the signal in electrons needs to take into 
; account the Fowler sampling explicitly.  We do this by scaling the f_inttime 
; by a factor related to the Fowler sampling, the scaling numbers for the 200 
; and 400 second frametimes are not used.
tscale = [[1., 1.064615615, 1.037002778, 1.013029179, 1., 1., 1., 1.263827693, 1.134864699, $
	       1.053407848, 1.099087659, 1.023286464, 1., 1.], $
	      [1., 1.064615615, 1.037002778, 1.013029179, 1., 1., 1., 1.263827693, 1.134864699, $
           1.053407848, 1.04136959, 1.011006847, 1.,  1.]]

; Adjust integration time to account for Fowler averaging.          
f_inttime = f_inttime * tscale[fr, f_ch_int]

; scaling for warm readnoise from estimate based on ground test
  sigma_readnoise_scale = [1.05, 1.0]

; detector read noise, electrons
 sigma_rn = sqrt( npix * $
                     (sigma_readnoise[fr,f_ch_int] * sigma_readnoise_scale[f_ch_int])^2. )
 sigma_rn2 = sqrt( noisepix[f_ch_int] * $
                     (sigma_readnoise[fr,f_ch_int] * sigma_readnoise_scale[f_ch_int])^2. )
 sigma_rn3 = sqrt( npix3 * $
                     (sigma_readnoise[fr,f_ch_int] * sigma_readnoise_scale[f_ch_int])^2. )                     
;***DEBUG print, 'Detector read noise in electrons, sigma_rn = ', strtrim(string(sigma_rn),2)

; convert micro-Jy to equivalent MJy/sr
 scale = 34.98

; detector gain, electrons/DN 

 GAIN = [3.7, 3.7]

; convert from MJy/sr to DN/s (Table 4.1 in the IRAC Instrument Handbook, v1.0)
; selected via FLUXCONV[f_ch_int]
; Post-cryo values as of 12 Apr 2010 these apply to all observations after 18 
; Sep 2009
FLUXCONV = [0.1198, 0.1443, 0.5952, 0.2021]

; signal of the source in electrons
; First conversion factor from uJy / s to electrons
fd_to_e = GAIN[f_ch_int] / (scale * FLUXCONV[f_ch_int] * apcorr[f_ch_int])
fd_to_e2 = GAIN[f_ch_int] / (scale * FLUXCONV[f_ch_int] * apcorr2[f_ch_int])
fd_to_e3 = GAIN[f_ch_int] / (scale * FLUXCONV[f_ch_int])
 e_s = f_fd * fd_to_e * f_inttime 
 e_s2 = f_fd * fd_to_e2 * f_inttime
 e_s3 = f_fd * fd_to_e3 * f_inttime 
; Roughly account for extended scattering by increasing background by 40% 
; (actually should increase by 30-40%
 if (f_ch_int eq 2 or f_ch_int eq 3) then f_background_sb = f_background_sb * 1.4

; scaling between surface brightness and electrons, electrons/(MJy/sr * sec)
; selected via sb_to_e[f_ch_int]
sb_to_e = GAIN[f_ch_int] / FLUXCONV[f_ch_int]

; number of electrons contributed by the background
 e_bg = npix * f_background_sb * f_inttime * sb_to_e
 e_bg2 = noisepix[f_ch_int] * f_background_sb * f_inttime * sb_to_e
 e_bg3 = npix3 * f_background_sb * f_inttime * sb_to_e
;***DEBUG print, 'background signal in electrons, e_bg = ', strtrim(string(e_bg),2)

; Poisson noise of the source + background
 sigma_s = sqrt( e_s + e_bg )
 sigma_s2 = sqrt( e_s2 + e_bg2 )
 sigma_s3 = sqrt( e_s3 + e_bg3 )
;***DEBUG print, 'Poisson noise of the source + background in electrons, sigma_s = ', strtrim(string(sigma_s),2)

; Poisson noise of the subtracted background alone
 sigma_bg = sqrt( e_bg / nback )
 sigma_bg2 = sqrt( e_bg2 / nback )
 sigma_bg3 = sqrt( e_bg2 / nback3 )
;***DEBUG print, 'Poisson noise of the background alone in electrons, sigma_bg = ', strtrim(string(sigma_bg),2)

; any systematic/confusion error
 sigma_sys = 0.0

; noise with representative aperture, noise pixel aperture and larger aperture
 sigma = sqrt(sigma_rn^2. + sigma_s^2. + sigma_bg^2. + sigma_sys^2.)
 sigma2 = sqrt(sigma_rn2^2. + sigma_s2^2. + sigma_bg2^2. + sigma_sys^2.)
 sigma3 = sqrt(sigma_rn3^2. + sigma_s3^2. + sigma_bg3^2. + sigma_sys^2.)
;***DEBUG print, 'sigma = ', strtrim(string(sigma),2)

; Remove factor of 1.5
;; sigma = sqrt(sigma_rn^2. + f_inttime*(f_fd*fd_to_e + $
;; npix*f_background_sb*sb_to_e + $
;;  npix*f_background_sb*sb_to_e / nback))

;;***DEBUG print, 'sigma2 = ', strtrim(string(sigma2),2)

;;***DEBUG print, 'sigma3 = ', strtrim(string(sigma3),2)

; Account for subarray exposures if that mode is being used
if (f_arraymod eq 1) then nexp = f_nexp * 64. else nexp = f_nexp

; Calculate signal to noise for source
; Signal-to-noise with representative aperture, noise pixel aperture and larger 
; standard calibration aperture
 sn = sqrt(nexp) * f_fd * fd_to_e * f_inttime / sigma
 sn2 = sqrt(nexp) * f_fd * fd_to_e2 * f_inttime / sigma2
 sn3 = sqrt(nexp) * f_fd * fd_to_e3 * f_inttime / sigma3 

;***DEBUG print, ' '
;***DEBUG print, 'S/N = ', strtrim(string(sn,format='(f12.2)'),2)
;***DEBUG print, 'S/N(2) = ', strtrim(string(sn2,format='(f12.2)'),2)
;***DEBUG print, 'S/N(3) = ', strtrim(string(sn3,format='(f12.2)'),2)
;***DEBUG print, ' '

 return, strtrim(string(sn,format='(f12.2)'),2)

end


pro snirac_warm_help_event, ev

  widget_control, ev.id, get_uvalue=uval
  if (n_elements(uval) eq 0) then uval = ''
  name = strmid(tag_names(ev, /structure_name), 7, 4)
  case (name) of
   'BUTT' : begin
             if (uval eq 'DONE') then begin
              widget_control, /destroy, ev.top
              return
             endif
            endcase
  endcase
end


pro snirac_warm_help

 common block1, VERSION, ch, frametime, arraymod, nexp, fd, background_sb;, rin, rout

 helpbase = widget_base(title='Help Window - IRAC S/N Calculator v'+VERSION, row=2)
 widget_control, /managed, helpbase

 hb1 = widget_base(helpbase, /frame, /row)
 ht1 = widget_text(hb1, xsize=80, ysize=40, /scroll, /wrap, $
        uname='help_window', $
        value=[ 'IRAC S/N Calculator v'+VERSION, $
	        '', $
	        '', $
'This tool calculates IRAC S/N based on the memo "Estimating Signal-To-Noise Ratio of a Point Source Measurement for IRAC" (issued by the SSC on 12 Feb 2007; see http://ssc.spitzer.caltech.edu/warmmission/propkit/som/irac_memo.txt - the memo is also reproduced below as modified for the warm mission).', $
'', $
'The following assumptions (based on those in the memo) were made during the calculation:', $
'', $
'1) Systematic and/or confusion error noise (sigma_sys) = 0.0.', $
'', $
'2) A 3 pixel radius aperture and 3-7 pixel radii background annulus are assumed in this calculation, which is a good compromise between a larger aperture which minimizes photon noise but can have bad backgrounds and smaller apertures which minimze read noise but are most affected by pixel-phase and photon noise.  Realized S/N can vary by 10% depending on aperture size and source brightness.', $
'', $
'3) Correlated fluctuations such as pixel-phase are not accounted for in this estimate and it is assumed that the noise decreases as sqrt(Nexposures).', $
'', $
'Note that the returned S/N value is an upper (i.e. optimistic) estimate.  In practice, the calculated total noise (sigma) value should be scaled up by 20-40% to conservatively account for systematic effects (e.g., resulting from bright source photometry or confusion) and/or the importance of obtaining a high precision measurement.  These factors are best evaluated by the observer; the S/N value reported by the Calculator should be correspondingly scaled down by a factor of 0.8-0.6x to account for these effects.  The current best signal-to-noise achieved is ~85% of ideal.', $
'', $
'', $
'-----------------------------------------------------------------------', $
'Estimating Signal-To-Noise Ratio of a Point Source Measurement for IRAC', $
'-----------------------------------------------------------------------', $
'',$ 
'When planning observations that need to measure the flux density or variations in the flux density of a point source to a certain precision, it is important to include the Poisson noise of the source in the estimation of the signal-to-noise ratio.  The online sensitivity estimator, SENS-PET, that determines the detection signal-to-noise ratio (how significant a source is compared to the background) only includes the read noise of the instrument and the Poisson noise of the background in the calculation of the uncertainty.  This memo discusses in detail how to estimate the uncertainty in a measurement of the source flux density for the benefit of observers who are interested in variations in source brightness (as in observations of extrasolar planet transits, etc).', $
'',$  
'The uncertainty in the measured flux density of a point source in a single exposure is', $
'',$  
'sigma^2 = sigma_rn^2 + sigma_s^2 + ap_fac * sigma_bg^2 + sigma_sys^2',$
'',$  
'where sigma_rn is the read noise of the detector, sigma_s is the Poisson noise of the source + background, sigma_bg is the Poisson noise of the subtracted background alone, ap_fac is a scaling factor accounting for the noise in the annulus used to estimate the background to subtract, and sigma_sys is any systematic/confusion error.  In this memo, sigma is calculated for a single exposure and in the limit where sigma_sys = 0; therefore, sigma decreases as the square-root of the number of exposures.', $
'', $  
'The number of pixels (npix) contributing to the source is the size of the aperture used (~28.3 pixels for a 3 pixel radius circular aperture).  Then the read noise for the source is', $
'', $  
'sigma_rn^2 = npix * sigma_readnoise^2,', $
'', $      
'where sigma_readnoise is the read noise in electrons for the desired frametime (see Table 6.4 of the SOM).'  , $
'', $  
'The term sigma_s^2 is the Poisson noise of the source plus the background in the aperture used.  Then, sigma_s^2 = e_s + npix * e_bg, where e_s is the signal of the source in electrons and e_bg is the signal of the background per pixel in electrons.', $
'', $  
'Typically, the source flux density (fd) is given in micro-Jy.  To convert to electrons detected, use', $
'', $  
'e_s = fd(micro-Jy) * GAIN * EFFTIME / (scale * FLUXCONV * apcorr)', $
'', $  
'where scale (34.98) converts from micro-Jy to equivalent MJy/sr, so that the the correct number of electrons are determined when using the FLUXCONV and GAIN values supplied; FLUXCONV converts from MJy/sr to DN/s; GAIN converts from DN to electrons; and, EFFTIME is the effective exposure time used.  EFFTIME is different from the exposure time, EXPTIME, for observations taking with multiple Fowler samples due to the increased signal as multiple samples are taken. EFFTIME is related to EXPTIME as described in Garnett and Forrest (1993, SPIE Vol. 1946, 395).  Note that GAIN, EXPTIME and FLUXCONV can all be found in the headers of a BCD image.  EFFTIME is calculated by this procedure using EXPTIME and the Fowler number for the channel and frametime.  EFFTIME equals EXPTIME for Fowler=1 observations with a maximum increase of 26% over EXPTIME for 6 second (Fowler=4) full array data. GAIN and FLUXCONV are constants for a given IRAC channel. 1./apcorr is the fraction of source flux enclosed in the default aperture', $
'', $  
'Simplifying the expression,', $
'', $  
'e_s = fd * EFFTIME * fd_to_e', $
'', $  
'where fd_to_e = 0.700, 0.580 electrons / (uJy * s) for channels 1&2, respectively.', $
'', $  
'Likewise, the number of electrons contributed by the background is given by', $
'', $  
'e_bg = background_sb * EFFTIME * sb_to_e', $
'', $  
'where the background_sb is an estimate of the surface brightness of the background in MJy/sr (such as the estimate given by Spot) and sb_to_e is the scaling between surface brightness and electrons.  Note that for channels 3 and 4, the Spot estimates of the background surface brightness should be scaled up by ~1.5, to account for extra background signal due to internal scattering in the arrays.', $
'', $  
'The term sb_to_e = 27.546, 22.869 electrons / (MJy/sr * s) for channels 1&2, respectively.', $
'', $  
'To be conservative, assume that the background subtraction used in either aperture photometry or PSF fitting contributes noise from the background summed over the number of noise pixels for the source.  Then, ap_fac = npix and', $
'', $  
'sigma_bg^2 = e_bg  / nback = background_sb * EFFTIME * sb_to_e / nback', $
'', $  
'where nback is the number of pixels used in a reasonably-sized background annulus.', $
'', $  
'A reasonable estimate of the noise (in electron units) in a single exposure is then', $
'', $  
'sigma^2 = sigma_rn^2 + EFFTIME * (fd * fd_to_e + npix * background_sb * sb_to_e + npix * background_sb * sb_to_e / nback).', $
'', $  
'To be conservative, scale the noise upward by 30%-50% to account for systematics, etc.', $
'', $  
'The signal-to-noise ratio for one exposure is simply', $
'', $  
'fd * fd_to_e * EFFTIME / sigma.', $
'' ])


 hb4 = widget_base(helpbase, /frame, /row, space=30)
 ht1 = widget_button(hb4, value='Dismiss', uvalue='DONE')

 widget_control, helpbase, /realize

 xmanager, 'SNIRAC_WARM_HELP', helpbase, /no_block
end


pro snirac_warm

 forward_function snirac_warm_calc
 resolve_routine, 'snirac_warm_calc', /is_function, /no_recompile
 resolve_routine, ['snirac_warm', 'snirac_warm_event', 'snirac_warm_help', $
                      'snirac_warm_help_event'], /no_recompile

 common block1, VERSION, ch, frametime, arraymod, nexp, fd, background_sb;, rin, rout

;***********************************************
;*** DON'T FORGET TO UPDATE THE VERSION NUMBER
 VERSION = '1.0'   ; original code
 VERSION = '1.1'   ; fixes for bugs found by Seppo and Sean
 VERSION = '1.2'   ; removed 1.5x scaling of total noise, requested by Sean
 VERSION = '1.3'   ; warm IRAC version
 VERSION = '2.0'   ; warm IRAC version use updated constanst, standard aperture, corrected readnoise estimate
 VERSION = '2.1'   ; fixed initial handling of channels  
 VERSION = '2.2'   ; fixed gain values to be 3.7
 VERSION = '2.3'   ; adjusted effective integration times based on Garnett & Forrest (1993)
 VERSION = '2.4'   ; updated full array readnoises for channels 1 and 2
;***********************************************
;*** Set default values
 fd=-999.999
 background_sb=-999.999
 ch=1
 frametime=30.
 arraymod = 0
 nexp=1.
;; rin = 10.
;; rout = 20.

 swin = !d.window   ;Previous window

 base = widget_base(title='IRAC S/N Calculator v'+VERSION, row=3)
 widget_control, /managed, base

 b0 = widget_base(base, /frame, column=1)
 widget_control, base, set_uvalue=t1

 b1 = widget_base(base, /frame, /row)
 t1 = widget_text(b1, xsize=80, ysize=10, /scroll, uname='info_window', $
       value=[ 'IRAC S/N Calculator v'+VERSION, $
	       '', $
	       '', $
               'Default IRAC Channel: 1 (3.6 microns)', $
               'Default IRAC Frame Time: 30 s', $
               'Default Total Number of Exposures: 1', $
;;               'Default Inner Radius of Background Aperture: 10 pixels', $
;;               'Default Inner Radius of Background Aperture: 20 pixels', $
	       '' ])


 b2 = widget_base(base, /frame, /column, space=30)
 t2 = widget_base(b2, /column)
 t1 = widget_label(t2, value='IRAC Channel')
 ch_list = [ '1 (3.6 microns)', '2 (4.5 microns)']
 t1 = widget_list(t2, ysize=4, uvalue=ch_list, value=ch_list, tab_mode=1)

 t1 = widget_label(t2, value='IRAC Frame Time')
 frametime_list = [ '0.02s sub', '0.1s sub', '0.4s sub', '2s sub', '0.4s full', $
                    '0.6s full', '1.2s full', '2s full', '6s full', '12s full', $
                    '30s full', '100s full']
 t1 = widget_list(t2, ysize=5, uvalue=frametime_list, value=frametime_list, tab_mode=1)


 b3 = widget_base(base, /frame, /column, space=30)
 t2 = widget_base(b3, /row)
 t1 = widget_label(t2, value = 'Total Number of Exposures:')
 t1 = widget_text(t2, /editable, /all_events, xsize=10, ysize=1, value='1', uvalue='w_nexp')

 t2 = widget_base(b3, /row)
 t1 = widget_label(t2, value = 'Target Flux Density (micro-Jy):')
 t1 = widget_text(t2, /editable, /all_events, xsize=10, ysize=1, uvalue='w_fd')

 t2 = widget_base(b3, /row)
 t1 = widget_label(t2, value = 'Background Surface Brightness (MJy/sr):')
 t1 = widget_text(t2, /editable, /all_events, xsize=10, ysize=1, uvalue='w_background_sb')

; Aperture is now considered fixed, so these dialogs are commented out
;; t2 = widget_base(b3, /row)
;; t1 = widget_label(t2, value = 'Inner Radius of Background Annulus (pixels):')
;; t1 = widget_text(t2, /editable, /all_events, xsize=10, ysize=1, value='10', uvalue='w_rin')

;; t2 = widget_base(b3, /row)
;; t1 = widget_label(t2, value = 'Outer Radius of Background Annulus (pixels):')
;; t1 = widget_text(t2, /editable, /all_events, xsize=10, ysize=1, value='20', uvalue='w_rout')


 b4 = widget_base(base, /frame, /row, space=30)
 t1 = widget_button(b4, value='Calculate', uvalue='CALC')
 t1 = widget_button(b4, value='Help', uvalue='HELP')
 t1 = widget_button(b4, value='Exit', uvalue='DONE')

 widget_control, base, /realize

 xmanager, 'SNIRAC_WARM', base, /no_block
end


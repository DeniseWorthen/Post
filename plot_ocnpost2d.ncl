;************************************************
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 

  load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"
;************************************************
begin

  hemi="NH"
  ;hemi="SH"

  minlat = 66.0
  ;minlat = 76.0
  ;minlat = 88.0
  ;minlat = 80.0

  ;minlat =  88.0
  ;maxlat =  88.0
  ;minlon =  140.0
  ;maxlon =  270.0

  RT1 = "/scratch3/NCEPDEV/stmp1/Denise.Worthen/"
  RT2 = "/scratch3/NCEPDEV/stmp2/Denise.Worthen/"
  RT3 = "/scratch4/NCEPDEV/stmp3/Denise.Worthen/"
  RT4 = "/scratch4/NCEPDEV/stmp4/Denise.Worthen/"

;************************************************
; read in netCDF file
;************************************************

   idate = "20120101"

   ; post files
   dirsrc  = "/scratch3/NCEPDEV/marine/noscrub/Denise.Worthen/POST/tools/post/"
   dstgrds = (/"0p25", "0p5", "1p0"/)
    outres = "_"+dstgrds+"x"+dstgrds+"_MOM6"

   ; model output files
   rtsrc = RT2+"BM1_ocn/"+"gfs."+idate+"/00/"
    
    postlist = dirsrc+"test"+outres+".nc"
   postfiles = addfiles(postlist,"r")
   ;print(postfiles)
      fmodel = addfile(rtsrc+"ocn2012010106.01.2012010100.nc","r")

   nplots = 1 + dimsizes(postfiles)

   plotlabs = (/"Native Model grid", "1/4 degree", \
                "1/2 degree", "1 deg"/)

;************************************************
; model field
;************************************************

  lstep=1-1

  ; ocn field
  ;varname="SST"
  ;levs=(/-1.8,4.0,.2/)
  ;levs=(/-1.8,-1.0,.02/)
  varname="latent"
  ;levs=(/-10.0,0.0,0.1/)
  levs=(/-2.0,0.0,0.02/)
  ;varname="LW"
  ;levs=(/-100.0,100.0,2./)

;************************************************
; add a poly line showing the polar seem along
; great circle path from (lon1,lat1) to (lon2,lat2)
;************************************************

  lon1=  60.00
  lon2=-120.00
  lat1 = 60.00
  lat2 = 60.00

;************************************************
; define the map
;************************************************
  wkstype="X11"
  ;wkstype="png"
  wkstype@wkWidth=800
  wkstype@wkHeight=800
  wks   = gsn_open_wks (wkstype,"OcnPost")              ; send graphics to X11 window

  plot = new(4,graphic)
   dum = new(4,graphic)

  res                      = True        ; plot mods desired
  res@gsnDraw              = False       ; do not draw until the end
  res@gsnFrame             = False       ; do not automatically advance 'frame'

  ;res@cnFillMode = "MeshFill"
  res@cnFillMode = "RasterFill"
  res@mpFillOn   = False
  res@mpOutlineOn   = False
  ;res@cnMissingValFillColor    = "gray70"

  res@gsnStringFontHeightF = 0.05

  res@gsnPolar   =  hemi                         ; specify the hemisphere
  if(hemi .eq. "NH")then
   res@mpMinLatF    =  minlat                          ; minimum lat to plot
   res@mpCenterLonF = -45
  end if
  if(hemi .eq. "SH")then
   res@mpMaxLatF    = -50                            ; minimum lat to plot
   res@mpCenterLonF = 0.0
  end if

  res@cnFillDrawOrder   = "PreDraw"             ; draw contours first
  res@cnFillOn          = True                  ; color fill
  res@cnLinesOn         = False                 ; no contour lines
  res@cnLineLabelsOn    = False
  res@lbLabelBarOn      = False
  
  ;res@cnFillOn          = False                  ; color fill

  res@cnLevelSelectionMode = "ManualLevels"     ; set the contour levels with the following 3 resources
  res@cnMinLevelValF  = levs(0)                      ; set the minimum contour level
  res@cnMaxLevelValF  = levs(1)                      ; set the maximum contour level
  res@cnLevelSpacingF = levs(2)                      ; set the interval between contours

  res@cnFillPalette        = "MPL_rainbow"              ; choose colormap

  res@tiMainFontHeightF = .10

  ;res@gsnCenterStringOrthogonalPosF = .15	    ; raise the CenterString slightly
  res@gsnStringFontHeightF = 0.020
  res@gsnLeftStringFontHeightF = 0.01
  res@gsnRightStringFontHeightF = 0.01

;************************************************
; Resources for the polyline
;************************************************

  res@mpGreatCircleLinesOn = True
  pres                  = True           ; polyline mods desired
  pres@gsLineThicknessF = 2.0            ; line thickness
  pres@gsLineColor      = "black"         ; color of lines
  pres@gsLineDashPattern =  1            ; dashes
  ;pres@tfPolyDrawOrder = "postDraw"

;************************************************
;
;************************************************

  ; native model field
  ii = 0
  ocnvar = fmodel->$varname$(lstep,:,:)
  ocnvar@lat2d = fmodel->geolat
  ocnvar@lon2d = fmodel->geolon
  res@gsnCenterString = plotlabs(ii)
  plot(ii) = gsn_csm_contour_map_polar(wks,ocnvar,res)    ; create the plot
 ;  dum(ii) = gsn_add_polyline(wks,plot(ii),(/lon1, lon2/) , (/lat1, lat2/) ,pres)
  delete(ocnvar)

  do ii = 1,3
     ocnvar = postfiles[ii-1]->$varname$(lstep,:,:)
  res@gsnCenterString = plotlabs(ii)
   plot(ii) = gsn_csm_contour_map_polar(wks,ocnvar,res)    ; create the plot
  ;  dum(ii) = gsn_add_polyline(wks,plot(ii),(/lon1, lon2/) , (/lat1, lat2/) ,pres)
   delete(ocnvar)
  end do

;************************************************
;
;************************************************

  resP                     = True                ; modify the panel plot
                                                 ; new resource added in NCL V6.4.0
  resP@gsnPanelLabelBar    = True                ; add common colorbar
  resP@lbLabelFontHeightF  = 0.010               ; make labels smaller

  resP@gsnPanelMainFontHeightF = 0.025            ; new resource added in NCL V6.4.0
  resP@gsnPanelMainString = idate
  resP@gsnPanelYWhiteSpacePercent = 5
  resP@gsnPanelXWhiteSpacePercent = 5

  gsn_panel(wks,plot,(/2,2/),resP)               ; now draw as one plot

exit
end

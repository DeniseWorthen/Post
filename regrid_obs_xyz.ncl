;************************************************
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 

  load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"
;************************************************
begin

;************************************************
; read in netCDF file
;************************************************

   dirsrc  = "/scratch2/NCEPDEV/climate/Jiande.Wang/Z-work4/for-Denise/"

   ; obs files
   ofile = "EN.4.2.1.f.analysis.g10.201104.nc"
    obsf = addfile(dirsrc+ofile,"r")
   obslatname = "lat"
   obslonname = "lon"
   obsdptname = "depth"
    obstname = "temperature"
    obssname = "salinity"

   ; model output
   mfile = "ocnr20110401.01.2011040100_0p25x0p25.nc"
    modf = addfile(dirsrc+mfile,"r")
   modlatname = "lat"
   modlonname = "lon"
   moddptname = "z_l"
   
   olons = obsf->$obslonname$
   olats = obsf->$obslatname$
   odpts = obsf->$obsdptname$

    time = modf->time
   mlons = modf->$modlonname$
   mlats = modf->$modlatname$
   mdpts = modf->$moddptname$
     z_l = modf->z_l
     z_i = modf->z_i
   nlevs = dimsizes(z_l)
    nlat = dimsizes(mlats)
    nlon = dimsizes(mlons)

   ;print(odpts)
   ;print(mdpts)
;----------------------------------------------------------------------
; set up the output netcdf file
;----------------------------------------------------------------------
    
    outfile = "rgobs.nc"
    system("/bin/rm -f " + outfile)    ; remove if exists
    outcdf  = addfile (outfile, "c")  ; open output file

    ; explicitly declare file definition mode. Improve efficiency.
    setfileoption(outcdf,"DefineMode",True)

    ; create global attributes of the file
    fAtt               = True            ; assign file attributes
    fAtt@creation_date = systemfunc ("date")
    fAtt@source_file   = ofile
    fileattdef( outcdf, fAtt )           ; copy file attributes

    ; predefine the coordinate variables and their dimensionality
    dimNames = (/"time", "z_l",   "z_i",   "lat", "lon"/)
    dimSizes = (/ -1   , nlevs, nlevs+1,    nlat,  nlon/)
    dimUnlim = (/ True , False,   False,   False, False/)
    filedimdef(outcdf,dimNames,dimSizes,dimUnlim)

    ; predefine the the dimensionality of the variables to be written out
    filevardef(outcdf,  "time", typeof(time),    getvardims(time))
    filevardef(outcdf,   "z_l",  typeof(z_l),    getvardims(z_l))
    filevardef(outcdf,   "z_i",  typeof(z_i),    getvardims(z_i))
    filevardef(outcdf,   "lat",  typeof(mlats),  getvardims(mlats))
    filevardef(outcdf,   "lon",  typeof(mlons),  getvardims(mlons))

    ; Copy attributes associated with each variable to the file
    filevarattdef(outcdf, "time",   time)
    filevarattdef(outcdf,  "z_l",    z_l)
    filevarattdef(outcdf,  "z_i",    z_i)
    filevarattdef(outcdf,  "lat",  mlats)
    filevarattdef(outcdf,  "lon",  mlons)

    ; predefine variables
     odims = (/"time", "z_l", "lat", "lon"/)
     filevardef(outcdf, obstname, "float", odims)
     filevardef(outcdf, obssname, "float", odims)
     delete(odims)

    ; explicitly exit file definition mode.
    setfileoption(outcdf,"DefineMode",False)

    ; write the dimensions to the file
    outcdf->time   = (/time/)
    outcdf->z_l    = (/z_l/)
    outcdf->z_i    = (/z_i/)
    outcdf->lat    = (/mlats/)
    outcdf->lon    = (/mlons/)

;************************************************
;
;************************************************

  otemp = obsf->$obstname$
  osalt = obsf->$obssname$

 ; regrid obs to model spatially
   rgt = linint2_Wrap(olons,olats,otemp,True,mlons,mlats,0)
   rgs = linint2_Wrap(olons,olats,osalt,True,mlons,mlats,0)
 ; printVarSummary(rgt)
 ; regrid vertically
   rgtz = linint1_n_Wrap(odpts,rgt,False,mdpts,0,1)
   rgsz = linint1_n_Wrap(odpts,rgs,False,mdpts,0,1)
  ; printVarSummary(rgtz)
  ; patch k=1
  rgtz(:,0,:,:) = (/rgt(:,0,:,:)/)
  rgsz(:,0,:,:) = (/rgs(:,0,:,:)/)

  ; enter file definition mode to add variable attributes
  setfileoption(outcdf,"DefineMode",True)
  filevarattdef(outcdf, obstname, rgtz)
  filevarattdef(outcdf, obssname, rgsz)
  setfileoption(outcdf,"DefineMode",False)

 outcdf->$obstname$   = (/rgtz/)
 outcdf->$obssname$   = (/rgsz/)
exit
end

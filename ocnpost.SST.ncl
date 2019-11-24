;------------------------------------------------------------------
; Denise.Worthen@noaa.gov (Feb 2019)
;
; This is a version of ocnpost.ncl which remaps only the 
; daily SST files
;
  load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

;----------------------------------------------------------------------
begin

   ; specify a location to use
       nemsrc     = "/scratch4/NCEPDEV/ocean/save/Denise.Worthen/NEMS_INPUT0.1/ocnicepost/"
   ; interpolation methods
   methods        = (/"bilinear" ,"conserve"/)
   ; ocean model output location 
           dirsrc = "/scratch3/NCEPDEV/stmp2/Denise.Worthen/BM1_ocn/"

   ; destination grid sizes and name
      dsttype     = (/"rect."/)
      dstgrds     = (/"1p0", "0p5", "0p25"/)

   ; variables to be regridded with the native tripole stagger location
   ; and dimensionality 
   
   varlist = (/ (/ "sst", "Ct", "bilinear", "2"/) \
             /)
   ;print(varlist)

     dims = dimsizes(varlist)
    nvars = dims(0)
   delete(dims)

   begTime = get_cpu_time()
;----------------------------------------------------------------------
; make a list of the directories and files from the run 
;----------------------------------------------------------------------

   idate = "20120101"

   ocnfilelist = systemfunc("ls "+dirsrc+"gfs."+idate+"/00/"+"SST*.nc") 
          ocnf = addfiles(ocnfilelist,"r")
        nfiles = dimsizes(ocnfilelist)

  ; get a 2 dimensional field for creating the interpolation masks
  ; the mask2d contains 1's on land and 0's at valid points.
  mask2d = where(ismissing(ocnf[0]->sst),  1.0, 0.0)
  ;printVarSummary(mask2d)

;----------------------------------------------------------------------
; loop over the output resolutions 
;----------------------------------------------------------------------

      jj = 1
      ii = 0

   do jj = 0,dimsizes(dstgrds)-1
    outres = "_"+dstgrds(jj)+"x"+dstgrds(jj)
   outgrid = dstgrds(jj)

   ; regrid a field to obtain the output xy dimensions
    wgtsfile = nemsrc+"tripole.mx025.Ct.to."+dsttype+dstgrds(jj)+".bilinear.nc"
          tt = ESMF_regrid_with_weights(mask2d(0,:,:),wgtsfile,False)
        tt!0 = "lat"
        tt!1 = "lon"
         lat = tt&lat
         lon = tt&lon
        dims = dimsizes(tt)
        nlat = dims(0)
        nlon = dims(1)
     print("fields will be remapped to destination grid size "\
           +nlon+"  "+nlat)
  
     delete(tt)
     delete(dims)

    ; regrid the masks to obtain the interpolation masks. 
    ; the mask2d contain 1's on land and 0's at valid points.
    ; when remapped any mask value > 0, identifies land values that 
    ; have crept into the field. remapped model fields are then
    ; masked with this interpolation mask

    wgtsfile = nemsrc+"tripole.mx025.Ct.to."+dsttype+dstgrds(jj)+".bilinear.nc"
    rgmask2d = ESMF_regrid_with_weights(mask2d, wgtsfile,False)

    ; create the interpolation mask
    rgmask2d = where(rgmask2d .gt. 0.0, rgmask2d@_FillValue, 1.0)

;----------------------------------------------------------------------
; loop over each file in the ocnfilelist
;----------------------------------------------------------------------

   do ii = 0,2
   ;do ii = 0,nfiles-1
     infile = ocnfilelist(ii)
    print("working on "+infile)
    ; create the output file name
    outfile = infile
    ; find the index where the actual filename begins
     indstr = str_index_of_substr(outfile, "/", -1)
    ; insert a sub-directory name
    outfile = str_insert(outfile,outgrid+"/",indstr+1)
    ; insert a string indicating regridding resolution
    outfile = str_insert(outfile,outres,-4)
    ; find the index where the actual filename begins
     indstr = str_index_of_substr(outfile, "SST", -1)
    ; insert an 'r' after the leading occurence of 'SST' 
    ; to indicate regular grid
    outfile = str_insert(outfile,"r",indstr+3)
    ; check if the outgrid directory exists and create
    ; it if it does not
    ret = systemfunc("test -d "+dirsrc+"gfs."+idate+"/00/"+outgrid+"; echo $?")
    if(ret .eq. 1)then
     system("mkdir "+dirsrc+"gfs."+idate+"/00/"+outgrid)
    end if

    ; retrieve the time stamp
       time = ocnf[0]->time
    delete(time@bounds)

;----------------------------------------------------------------------
; set up the output netcdf file
;----------------------------------------------------------------------
 
    system("/bin/rm -f " + outfile)    ; remove if exists
    outcdf  = addfile (outfile, "c")  ; open output file

    ; explicitly declare file definition mode. Improve efficiency.
    setfileoption(outcdf,"DefineMode",True)

    ; create global attributes of the file
    fAtt               = True            ; assign file attributes
    fAtt@creation_date = systemfunc ("date")
    fAtt@source_file   = infile
    fileattdef( outcdf, fAtt )           ; copy file attributes    

    ; predefine the coordinate variables and their dimensionality
    dimNames = (/"time", "lat", "lon"/)  
    dimSizes = (/ -1   ,  nlat,  nlon/) 
    dimUnlim = (/ True , False, False/)   
    filedimdef(outcdf,dimNames,dimSizes,dimUnlim)

    ; predefine the the dimensionality of the variables to be written out
    filevardef(outcdf, "time", typeof(time), getvardims(time)) 
    filevardef(outcdf,  "lat",  typeof(lat),  getvardims(lat))                          
    filevardef(outcdf,  "lon",  typeof(lon),  getvardims(lon))                          

    ; Copy attributes associated with each variable to the file
    filevarattdef(outcdf, "time", time)                 
    filevarattdef(outcdf,  "lat",  lat)             
    filevarattdef(outcdf,  "lon",  lon)            

    ; there is only 1 variable 
     varname = varlist(0)
     vardims = varlist(3)
      odims = (/"time", "lat", "lon"/)
     ;print("creating variable "+varname+" in file")
     filevardef(outcdf, varname, "float", odims)
     delete(odims)

    ; explicitly exit file definition mode.
    setfileoption(outcdf,"DefineMode",False)

    ; write the dimensions to the file
    outcdf->time   = (/time/)     
    outcdf->lat    = (/lat/)
    outcdf->lon    = (/lon/) 

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------

     varname = varlist(0)
     vargrid = varlist(1)
     varmeth = varlist(2)
     vardims = varlist(3)
     ;print(varname+"  "+vargrid+"  "+varmeth)
    
    ocnvar = ocnf[ii]->$varname$
     ndims = dimsizes(dimsizes(ocnvar))
     ;print(ndims+"   "+dimsizes(ocnvar))

     if(vargrid .ne. "Ct")then
      ; print error if the variable is not on the Ct grid
      print("Variable is not on Ct grid")
      exit
     end if

     ; regrid to dsttype+dstgrd with method
     ;print("remapping "+varname+" to grid "+dsttype+dstgrds(jj))
     wgtsfile = nemsrc+"tripole.mx025.Ct.to."+dsttype+dstgrds(jj)+"."+varmeth+".nc"

     rgtt = ESMF_regrid_with_weights(ocnvar,wgtsfile,False)
     rgtt = where(ismissing(rgmask2d),ocnvar@_FillValue,rgtt)

     ; enter file definition mode to add variable attributes
     setfileoption(outcdf,"DefineMode",True)
     filevarattdef(outcdf, varname, rgtt)                 
     setfileoption(outcdf,"DefineMode",False)

     outcdf->$varname$   = (/rgtt/)

     delete(ocnvar)
     delete(rgtt) 
    
;----------------------------------------------------------------------
; close the outcdf and continue through filelist
;----------------------------------------------------------------------

   delete(outcdf)

   ; ii, loop over files
   end do
   ;jj, loop over destination grids
   delete([/lat,lon,nlon,nlat/])
   delete([/rgmask2d/])
  end do
  print("One complete SST file in " + (get_cpu_time() - begTime) + " seconds")
exit
end

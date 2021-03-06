
undef("soda_chazhi")
  ;;;************************************************************
  ;; 差值soda数据,将水平上的精度插值到1度乘1度
  ;; infilepath : absolute path of soda data interpolated 
  ;; OUTPUT variable
  ;; linshuheng 2020.02.22
  ;;;*********************************************************
  function soda_chazhi(infilepath,outfilepath,var_need)
  begin
 ;;数据
    print("*******处理变量"+var_need)
    fils1 = infilepath
    f1 = addfile(fils1, "r")
    vNames = getfilevarnames(f1) ; get names of all variables on file
   
    id_var_want = get1Dindex(vNames,var_need)

    
    var_2d =(/"salt","mlp","mlt","taux","tauy"/)
    var_3d = (/"prho","temp","u","v","wt"/)
    ; var_other = (/"salt","prho"/)

    if any(var_2d.eq.vNames(id_var_want)) then       
      if vNames(id_var_want).eq."salt"  then
      data = f1->$vNames(id_var_want)$(:,0,:,:)                     ; say "T" is (lat,lev,lon)  
      else
      data = f1->$vNames(id_var_want)$(:,:,:)                     ; say "T" is (lat,lev,lon)  
      end if
    else
      data = f1->$vNames(id_var_want)$(:,0:29,:,:)                     ; say "T" is (lat,lev,lon)
      ; depth = f1->sw_ocean
      depth = f1->st_ocean
    end if
     

      lat = f1->yt_ocean
      lon = f1->xt_ocean
      time = f1->time

    printVarSummary(data)

    
    
    ;;------------------将soda数据进行差值---------------------------------
     print("**********开始插值***********")
     xi = data&xt_ocean
     yi = data&yt_ocean
     xo = fspan(0.5,359.5,360)
     yo = fspan(-74.5,89.5,165)
     

     data_chazhi = linint2_Wrap(xi, yi, data, True, xo, yo, 0)


    if any(var_2d.eq.vNames(id_var_want)) then 

       data_chazhi!1 = "lat"
       data_chazhi!2= "lon"
       data_chazhi&lat@units = "North_degree"
       data_chazhi&lon@units = "East_degree"
    else 
      data_chazhi!1  = "depth"
      data_chazhi!2 = "lat"
      data_chazhi!3= "lon"
      data_chazhi&lat@units = "m"
      data_chazhi&lat@units = "North_degree"
      data_chazhi&lon@units = "East_degree"
      data_chazhi&depth = depth(0:29)
    end if

     data_chazhi&lat = yo
     data_chazhi&lon = xo
     copy_VarAtts(data, data_chazhi)
     printVarSummary(data_chazhi)

    
     dim = dimsizes(data_chazhi)
    if any(var_2d.eq.vNames(id_var_want)) then
       ntime = dim(0)
       nlat = dim(1)
       nlon = dim(2)
    else
       ntime = dim(0)
       ndep = dim(1)
       nlat = dim(2)
       nlon = dim(3)
    end if


   ;;;写入nc文件

    print("******开始写入NC文件********")

    outpath = outfilepath
       ;;-----------------------写入nc文件---------------------------
    system("rm " + outpath)   ; remove any pre-existing file
    setfileoption("nc","Format","LargeFile")
    fout = addfile(outpath ,"c")  ; open output netCDF file
    setfileoption(fout,"DefineMode",True)

   ;===================================================================
    ; create global attributes of the file (optional)
    ;===================================================================

    fAtt               = True            ; assign file attributes
    fAtt@title         = "1979-2013，精度为1乘1"    
    fAtt@creation_date = systemfunc("date")
    fileattdef( fout, fAtt)            ; copy file attributes    
    ;----------------------------坐标变量的定义

    if any(var_2d.eq.vNames(id_var_want)) then 
      dimnames=(/"time","lat","lon"/)
      dimsize=(/-1,nlat,nlon/)
      dimunlim=(/True,False,False/)
    else
      dimnames=(/"time","depth","lat","lon"/)
      dimsize=(/-1,ndep,nlat,nlon/)
      dimunlim=(/True,False,False,False/)
    end if

    filedimdef(fout, dimnames, dimsize, dimunlim)
    filevardef(fout, "lat", typeof(data_chazhi&lat),(/"lat"/))
    filevardef(fout, "lon", typeof(data_chazhi&lon),(/"lon"/))
    filevardef(fout, "time", typeof(data_chazhi&time),(/"time"/))

    if any(var_3d.eq.vNames(id_var_want)) then
    filevardef(fout, "depth", typeof(data_chazhi&depth),(/"depth"/))
    end if
    ;-----------------------------定义变量名，类型和维数

    if any(var_2d.eq.vNames(id_var_want)) then
     filevardef(fout,vNames(id_var_want),typeof(data_chazhi),(/"time","lat","lon"/))
    else
     filevardef(fout,vNames(id_var_want),typeof(data_chazhi),(/"time","depth","lat","lon"/))
    end if


    ;;属性
    filevarattdef(fout, vNames(id_var_want), data_chazhi)
    filevarattdef(fout, "lon", data_chazhi&lon)
    filevarattdef(fout, "lat", data_chazhi&lat)
    filevarattdef(fout, "time", data_chazhi&time)

    if any(var_3d.eq.vNames(id_var_want)) then
    filevarattdef(fout, "depth", data_chazhi&depth)
    end if


    ;;
      fout->lon=(/data_chazhi&lon/)
      fout->lat=(/data_chazhi&lat/)
      fout->time=(/data_chazhi&time/)

      if any(var_3d.eq.vNames(id_var_want)) then
        fout->depth = (/data_chazhi&depth/)
      end if

      fout->$vNames(id_var_want)$ = (/data_chazhi/)
      print("=====finish NC write==========")
    ;;;

    k= "插值处理完成"
    print("插值处理完成")
    return(k)
  end 

;;***************************************************************************
;;main program 
;;*************************************************************************

begin 
   ; inpath = "~/lsh/CESM-data/f19_f19_FAMIP_rmindian/f19_f19_FAMIP_rmindian.cam.h0.197901-200611.nc"
   ; outpath = "~/lsh/CESM-data/f19_f19_FAMIP_rmindian/f19_f19_FAMIP_rmindian.cam.h0.197901-200611_chazhi.nc"
   inpath = "/home/yangsong3/data-observation/SODA/3.4.2/soda3.4.2_prho_mn_1980-2015.nc"
   outpath = "/home/yangsong3/data-observation/SODA/3.4.2/soda3.4.2_prho_mn_1980-2015_chazhi.nc"
   var_need = "prho"
   m = soda_chazhi(inpath,outpath,var_need)
end 



    





    ;;
 

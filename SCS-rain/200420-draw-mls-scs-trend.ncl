;;********************************************************
;;计算SODA数据中的平流项和垂直项
;;soda数据的精度是0.5×0.5°
;;NCEP-NCAR的精度为1.87×1.9
;;
;;                                         lnshuheng 2020.02.21
;**********************************************************
function chazhi(data)
 begin
   xi = data&lon
   yi = data&lat
   xo = fspan(0.5,359.5,360)
   yo = fspan(-89.5,89.5,180)
 
   data_chazhi = linint2_Wrap(xi, yi, data, True, xo, yo, 0)
  
   data_chazhi!1 = "lat"
   data_chazhi!2= "lon"
   
   data_chazhi&lat = yo
   data_chazhi&lon = xo
   copy_VarAtts(data, data_chazhi)
 
   return data_chazhi
end 
function  rc_test(ssta_rc)
begin
  tval = onedtond(ssta_rc@tval , dimsizes(ssta_rc))
   df   = onedtond(ssta_rc@nptxy, dimsizes(ssta_rc)) - 2
   b = tval    ; b must be same size as tval (and df)
   b = 0.5
   prob = betainc(df/(df+tval^2),df/2.0,b)    ; prob(nlat,nlon)
   copy_VarCoords(ssta_rc, prob)

return prob
end
;;**************************************************************
;;;main program
;;***************************************************************
begin
 ;;;time span
    startmon =198001
    endmon = 201312

    startyear_r = str_split_by_length(startmon, 4)  ;; 将时间string分解成年和月
    endyear_r = str_split_by_length(endmon, 4 )

    startyear = stringtoint(startyear_r(0))
    endyear = stringtoint(endyear_r(0))

    yearnum = endyear - startyear +1
  ;;
;;;region
   lat1 = -20
   lat2 = 10
   lon1 = 100
   lon2 = 160
 

;;;读入HadiSST海温数据
    fils1="/home/ys17-19/lsh/Project/SCS-rain/SODA3.4.2_mld_density_criterion_0.8.nc"
    f1=addfile(fils1, "r")
    
    mlp = f1->mld
    mlp&lat@units = "degrees_north"
    mlp&lon@units = "degrees_east"
    printVarSummary(mlp)

  
    mlp_clm = dim_avg_n_Wrap(mlp, 0)

    mlp_clm_region = mlp_clm({lat1:lat2},{lon1:lon2})

    mlp_rc = regCoef_n(ispan(1, 408, 1), mlp, 0, 0)
    mlp_rc = (/yearnum*mlp_rc/)

  
    copy_VarCoords(mlp(1,:,:), mlp_rc)






  
;;**************************************************************
;画图
;;***************************************************************
  wks   = gsn_open_wks("pdf", "scs-mlp的分布趋势-soda.3.4.2")

  res=True
  res@gsnFrame=False
  res@gsnDraw=False
  res@gsnLeftStringFontHeightF=20.0
  res@cnFillPalette="cmocean_deep"
  res@cnFillOn=True
  res@cnLinesOn=False
  res@gsnAddCyclic = False

  res@cnLineLabelsOn=False
  res@lbLabelBarOn=True
  res@lbLabelStride=2
  res@lbOrientation="Vertical"
  res@mpLimitMode           = "LatLon"
  res@mpMinLatF             = 0
  res@mpMaxLatF             = 15
  res@mpMinLonF             = 110
  res@mpMaxLonF             = 155


  res@mpCenterLonF          = (res@mpMinLonF+res@mpMaxLonF)/2.0

  res@tmXTOn=False
  res@tmYROn=False
  res@tmXBOn=True
  res@tmYROn=False
  res@tmXBMode="Explicit"
  res@tmYLMode="Explicit"

  res@tmXBLabelFontHeightF=0.015
  res@tmYLLabelFontHeightF=0.015
  res@tmXBMajorThicknessF=3.0
  res@tmYLMajorThicknessF=3.0
  res@tmBorderThicknessF=4.0

  res@cnLevelSelectionMode = "ManualLevels"      ; set manual contour level
  res@cnMinLevelValF       =   0
  res@cnMaxLevelValF       =   10
  res@cnLevelSpacingF      =  1
 

  plot = new(1,graphic)
  
  plot(0) = gsn_csm_contour_map(wks, mlp_rc, res)
  
  
  


  ; ;;;添加赤道直线
  ;   pgx=ispan(30,390,10)
  ;   pgy=new(dimsizes(pgx),typeof(pgx))
  ;   pgy=0

    pgres=True
    pgres@gsLineColor="black"
    pgres@gsLineThicknessF=1.0
    pgres@gsLineDashPattern=1
  
  ;   str = "" + ispan(1,2,1)

  ;  do i = 0,1
  ;    plot@$str(i)$ = gsn_add_polyline(wks, plot(i), pgx, pgy, pgres)
  ;  end do


  ;;;添加indo-pacific warm pool
    ; ;;添加区域
   ;;warm pool
   pgres@gsLineThicknessF=2.0
   pgres@gsLineDashPattern=0
   str3=unique_string("dum3")
   str4=unique_string("dum4")
   
   ;;;画box
   lat1 = 0
   lat2 = 15
   lon1 = 110
   lon2 = 155

   pgx_pool=(/lon1,lon2,lon2,lon1,lon1/)
   pgy_pool=(/lat1,lat1,lat2,lat2,lat1/)
   ;;;
   str2 = "0" + ispan(1,2,1)
   i = 0
     plot@$str2(i)$ = gsn_add_polyline(wks, plot(i), pgx_pool, pgy_pool, pgres)
   

   draw(plot)
   frame(wks)

end
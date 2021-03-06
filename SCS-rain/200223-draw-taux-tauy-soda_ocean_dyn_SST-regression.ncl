;;********************************************************
;;计算海洋动力过程项,SST倾向以及SST值.
;;的相关系数场，
;;NCEP-NCAR的精度为1.87×1.9,soda数据已经插值到1°乘1°
;;
;;                                         lnshuheng 2020.02.18
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
   lat1 = -5
   lat2 = 45
   lon1 = 90
   lon2 = 160
 

;;;读入HadiSST海温数据
    diri="/home/ys17-19/lsh/data/sst/"
    fils1=systemfunc("ls "+diri+"HadISST_sst.nc")
    f1=addfile(fils1, "r")
    date:=cd_calendar(f1->time, 1)

    timeind:=ind(date.le.201312.and.date.ge.198001)

    sst=lonFlip(f1->sst(timeind,:,:))
    printVarSummary(sst)

    ssta=(/rmMonAnnCycTLL(sst)/)
    copy_VarCoords(sst, ssta)


    ssta_annual = month_to_annual(ssta(:,{lat1:lat2},{lon1:lon2}), 1)
    printVarSummary(ssta_annual)

   
    ssta_annual =  (/dtrend_msg_n(ispan(1,yearnum,1),ssta_annual,False,True,0)/)
    ;;;sst 倾向值
     dsst = center_finite_diff_n(ssta, 1, False, 0, 0) 
     copy_VarCoords(ssta, dsst)
     dsst_annual = month_to_annual(dsst(:,{lat1:lat2},{lon1:lon2}), 1)
     dsst_annual =  (/dtrend_msg_n(ispan(1,yearnum,1),dsst_annual,False,True,0)/)

    ;;;
    delete(date)
    delete(timeind)
;;;

;;get region mean as index     
   ; lat1 = 0
   ; lat2 = 15
   ; lon1 = 110
   ; lon2 = 155

   ssta_index = dim_avg_n_Wrap(ssta_annual(:,{0:15},{110:155}), (/1,2/))
   dsst_index = dim_avg_n_Wrap(dsst_annual(:,{0:15},{110:155}), (/1,2/))

   ;;;normalized 
   
   ssta_index = (/dim_standardize_n(ssta_index, 1, 0)/)
   dsst_index = (/dim_standardize_n(dsst_index, 1, 0)/)
;;;



;;;read soda data and then calculate ocean dynamic : bar(v*σT)， bar(w*σT)，bar denotes 
;;;averaged in mixed layer
    
    f2=addfile("/home/yangsong3/data-observation/SODA/3.3.1/soda3.3.1_taux_mn_1980-2015_chazhi.nc", "r")   
    f3=addfile("/home/yangsong3/data-observation/SODA/3.3.1/soda3.3.1_tauy_mn_1980-2015_chazhi.nc", "r")   
    f4=addfile("/home/yangsong3/data-observation/SODA/3.3.1/soda3.3.1_wt_mn_1980-2015_chazhi.nc", "r")   
    f5=addfile("/home/yangsong3/data-observation/SODA/3.3.1/soda3.3.1_mlt_mn_1980-2015_chazhi.nc", "r") 


    indyear = (2013-1980+1)*12-1
    u_mean = f2->taux(0:indyear,{lat1:lat2},{lon1:lon2})
    v_mean = f3->tauy(0:indyear,{lat1:lat2},{lon1:lon2})
    wt = f4->wt(0:indyear,:,{lat1:lat2},{lon1:lon2})
    mlt = f5->mlt(0:indyear,{lat1:lat2},{lon1:lon2})

   
   

  

    ;;;;垂直积分平均，在混合层内进行
    mlt_clm = dim_avg_n_Wrap(mlt, 0)

    z =  wt&depth
    z&depth = z
    print(z)    
    dz = dpres_plevel(z, dim_avg_n_Wrap(mlt, 0), 0, 0)
    copy_VarCoords(wt(1,:,:,:), dz)
     
    dz_4d = conform_dims(dimsizes(wt), dz, (/1,2,3/))
  
    ;;;
    wt_mean = dim_sum_n_Wrap(wt*dz_4d,1)/sum(dz)
    copy_VarCoords(wt(:,1,:,:), wt_mean)

    ;;;年平均
       u_mean = (/rmMonAnnCycTLL(u_mean)/)
       v_mean = (/rmMonAnnCycTLL(v_mean)/)
       wt_mean = (/rmMonAnnCycTLL(wt_mean)/)
       
       u_mean_annual = month_to_annual(u_mean, 1) 
       v_mean_annual = month_to_annual(v_mean, 1)
       wt_mean_annual = month_to_annual(wt_mean, 1)
      
       u_mean_annual = (/dtrend_msg_n(ispan(1,yearnum,1),u_mean_annual,False,True,0)/)
       v_mean_annual = (/dtrend_msg_n(ispan(1,yearnum,1),v_mean_annual,False,True,0)/)
       wt_mean_annual = (/dtrend_msg_n(ispan(1,yearnum,1),wt_mean_annual,False,True,0)/)


    ;;;



  
 
print("*******计算回归系数*****************")
;;;calculate correlation coef
     

     ;;;u correlation with sst
    r_sst_u =   regCoef_n(ssta_index, u_mean_annual, 0, 0)
    r_dsst_u =   regCoef_n(dsst_index, u_mean_annual, 0, 0)
      
    copy_VarCoords(ssta_annual(0,:,:), r_sst_u)
    copy_VarCoords(dsst_annual(0,:,:), r_dsst_u)

    ;;;v correlation with sst
    r_sst_v =   regCoef_n(ssta_index, v_mean_annual, 0, 0)
    r_dsst_v =   regCoef_n(dsst_index, v_mean_annual, 0, 0)
      
    copy_VarCoords(ssta_annual(0,:,:), r_sst_v)
    copy_VarCoords(dsst_annual(0,:,:), r_dsst_v)

    
    ;;;wt correlation with sst
    r_sst_wt =   regCoef_n(ssta_index, wt_mean_annual, 0, 0)
    r_dsst_wt =   regCoef_n(dsst_index, wt_mean_annual, 0, 0)
      
    copy_VarCoords(ssta_annual(0,:,:), r_sst_wt)
    copy_VarCoords(dsst_annual(0,:,:), r_dsst_wt)
    ;;;

    r_sst_wt = r_sst_wt*10^10
    r_sst_u = r_sst_u*10^5
    r_sst_v = r_sst_v*10^5

    r_dsst_wt = r_dsst_wt*10^10
    r_dsst_u = r_dsst_u*10^5
    r_dsst_v = r_dsst_v*10^5
       


;;;;

print("*******显著性检验*****************")

;;;t test 
  prob_p1= rc_test(r_sst_u)
  prob_p2= rc_test(r_dsst_u)

  copy_VarCoords(r_sst_u, prob_p1)
  copy_VarCoords(r_dsst_u, prob_p2)
  
  printVarSummary(prob_p1)

  prob_p3= rc_test(r_sst_v)
  prob_p4= rc_test(r_dsst_v)

  copy_VarCoords(r_sst_v, prob_p3)
  copy_VarCoords(r_dsst_v, prob_p4)

  prob_p5= rc_test(r_sst_wt)
  prob_p6= rc_test(r_dsst_wt)

  copy_VarCoords(r_sst_wt, prob_p5)
  copy_VarCoords(r_dsst_wt, prob_p6)

  


print("*********开始画图********")

    
;;**************************************************************
;画图
;;***************************************************************
  wks   = gsn_open_wks("pdf", "风应力以及w与DSST及SST的回归系数")

  res=True
  res@gsnFrame=False
  res@gsnDraw=False
  res@gsnLeftStringFontHeightF=20.0
  res@cnFillPalette="BlRe"
  res@cnFillOn=True
  res@cnLinesOn=False
  res@gsnAddCyclic = False

  res@cnLineLabelsOn=False
  res@lbLabelBarOn=False
  res@lbLabelStride=2
  res@lbOrientation="Vertical"
  res@mpLimitMode           = "LatLon"
  res@mpMinLatF             = -5
  res@mpMaxLatF             = 45
  res@mpMinLonF             =90
  res@mpMaxLonF             = 160


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
  res@cnMinLevelValF       =   -12
  res@cnMaxLevelValF       =   12
  res@cnLevelSpacingF      =  1
   
   ;;;

  res@gsnScalarContour        = True

  ;;;;;;;LineArrow
  res@vcGlyphStyle             = "LineArrow"      ; turn on curly vectors
  ; res@vcGlyphStyle="CurlyVector"

  res@vcMinDistanceF           = 0.02           ; thin vectors
  ; res@vcMinMagnitudeF          =0.04
  ; res@vcRefMagnitudeF          = 4.0

  res@vcRefLengthF             = 0.08     ; define length of v
  res@vcRefAnnoOrthogonalPosF  = -1.0              ; move ref vector down -1.0在图的右上
  res@vcLineArrowThicknessF=1.0
  res@vcLineArrowHeadMaxSizeF=0.008
  res@vcLineArrowHeadMinSizeF=0.008
  res@vcVectorDrawOrder="PostDraw"
  ; res@mpFillOn =stZeroFLabelSide

  plot = new(2,graphic)
  res@gsnLeftString = "SST&Horizontal advction"
  plot(0) = gsn_csm_vector_scalar_map(wks,r_sst_u,r_sst_v,r_sst_wt ,res)         
  res@gsnLeftString = "DSST&Horizontal advction"
  plot(1) = gsn_csm_vector_scalar_map(wks,r_dsst_u,r_dsst_v,r_dsst_wt ,res)
  


  ;;;添加赤道直线
    pgx=ispan(30,390,10)
    pgy=new(dimsizes(pgx),typeof(pgx))
    pgy=0

    pgres=True
    pgres@gsLineColor="black"
    pgres@gsLineThicknessF=1.0
    pgres@gsLineDashPattern=1
  
    str = "" + ispan(1,4,1)

   do i = 0,1
     plot@$str(i)$ = gsn_add_polyline(wks, plot(i), pgx, pgy, pgres)
   end do


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
   str2 = "0" + ispan(1,4,1)
   do i = 0,1
     plot@$str2(i)$ = gsn_add_polyline(wks, plot(i), pgx_pool, pgy_pool, pgres)
   end do

    ;;;打点
    res_pro=True
    res_pro@gsnDraw=False
    res_pro@gsnFrame=False
    res_pro@cnLevelSelectionMode = "ExplicitLevels"
    res_pro@cnLinesOn=False
    res_pro@cnLevelSelectionMode = "ManualLevels" ; set manual contour levels
    res_pro@cnMinLevelValF      = 0.00        ; set min contour level
    res_pro@cnMaxLevelValF      = 1.00        ; set max contour level
    res_pro@cnLevelSpacingF     = 0.1       ; set contour spacing

    res_pro@cnLineLabelsOn=False
    res_pro@tmYRMode = "Automatic"
    res_pro@cnInfoLabelOn=False

    iplot=new(2,graphic)

    
      iplot(0) = gsn_csm_contour(wks,prob_p5,res_pro)
      iplot(1) = gsn_csm_contour(wks,prob_p6,res_pro)
  

    opt                      = True
    opt@gsnShadeFillType     = "pattern"
    opt@gsnShadeMid     = 6         ; stipple
    ; opt@gsnShadeFillDotSizeF =  0.0025
    ; opt@gsnShadeHigh   = "green"
    opt@gsnShadeFillScaleF   = 0.5         ; add extra density ,越大越係數


    do i = 0,1
     iplot(i) = gsn_contour_shade(iplot(i) , 0,0.1,opt)
    end do

    ;;;  
    do i = 0,1
      overlay(plot(i), iplot(i))
    end do 

  pres = True
  pres@gsnPanelLabelBar  = True

  gsn_panel(wks, plot, (/2,1/), pres)
 


end
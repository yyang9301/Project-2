;;********************************************************
;;计算ERA的10-m风趋势
;;
;;lnshuheng 2020.03.17
;**********************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/crop.ncl"
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
begin

;==========================================================
;;;read data
;;==========================================================
    ;;;read data
    diri="/home/ys17-19/lsh/data/sst/"
    fils1=systemfunc("ls "+diri+"HadISST_sst.nc")
    f1=addfile(fils1, "r")
    date:=cd_calendar(f1->time, 1)

    timeind:=ind(date.le.201312.and.date.ge.198001)

    sst=lonFlip(f1->sst(timeind,{-90:90},{-180:180}))
    printVarSummary(sst)
 exit()

      ; ;;;region 
      ;   lat1 = -10
      ;   lat2 = 90
      ;   lon1 = 0
      ;   lon2 = 360
      ; ;;;
      
     ;;;region
     lat1 = 0
     lat2 = 15
     lon1 = 110
     lon2 = 155
     ;;;


    ;;;time span
    startmon =198001
    endmon = 201312

    startyear_r = str_split_by_length(startmon, 4)  ;; 将时间string分解成年和月
    endyear_r = str_split_by_length(endmon, 4 )

    startyear = stringtoint(startyear_r(0))
    endyear = stringtoint(endyear_r(0))

    yearnum = endyear - startyear +1
    ;;

    ;;;;Ta - Ts的趋势
    path_t = "/home/yangsong3/data-observation/ERA-interim/monthly/2_metre_temperature.mon.mean.nc"
    f1 = addfile(path_t,"r")

    date:=cd_calendar(f1->time, 1)
    timeind:=ind(date.ge.startmon.and.date.le.endmon)

    t_r = short2flt(f1->t2m(timeind,{-90:90},{0:360}))


    print("*****************开始水平插值************************")  
    xo  =  sst&longitude
    yo  =  sst&latitude
    t = linint2_Wrap(t_r&longitude, t_r&latitude, t_r, \
                  True, xo, yo, 0)
    printVarSummary(t)
    delete(t_r)
    
    t_diff = t
    t_diff = sst+273.6 - t
    t_diff_scs = dim_avg_n_Wrap(t_diff(:,{0:15},{110:155}), 0)

    

   ;;;处理成年数据 
     t_annual = month_to_annual(t_diff, 1)
   ;;;


   ;;回归
    t_rc = regCoef_n(ispan(1, yearnum, 1), t_annual, 0, 0)
    copy_VarCoords(t_annual(1,:,:), t_rc)
    t_rc = (/t_rc*yearnum/)
   ;;;

 

   ;;;;相对湿度

     ;;;读入NCEP_DOE的数据
     ;  path_wind = "/home/yangsong3/data-observation/NCEP_DOE/monthly/shum.2m.mon.mean.nc"
     ;  f1 = addfile(path_wind,"r")

     ;  date:=cd_calendar(f1->time, 1)
     ;  timeind:=ind(date.ge.startmon.and.date.le.endmon)

     ;  shum_r = short2flt(f1->shum(timeind,0,{-90:90},:))


     ;  print("=====finish read data==========")

      

     ;  print("*****************开始水平插值************************")  
     ;  xo  =  sst&longitude
     ;  yo  =  sst&latitude
     ;  shum = linint2_Wrap(shum_r&lon, shum_r&lat, shum_r, \
     ;                True, xo, yo, 0)

      
     ;  printVarSummary(shum)
   ; ;;;

    yearin  = ispan(1980, 2013, 1)
    fils3 = "/home/yangsong3/data-observation/ERA-interim/monthly/2m_dew_tem/2m_dew_temp_monthly_" + yearin + ".nc"
    f3 = addfiles(fils3, "r")

    date:=cd_calendar(f3[:]->time, 1)
    timeind:=ind(date.ge.startmon.and.date.le.endmon)
    time = f3[:]->time(timeind)
    lat = f3[1]->latitude
    lon = f3[1]->longitude
  

      d2m_r = new((/dimsizes(time),dimsizes(lat),dimsizes(lon)/),float)
   
    do i = 0,dimsizes(timeind)/12-1
      d2m_r(i*12:(i+1)*12-1,:,:) = short2flt(f3[i]->d2m(:,{-90:90},{0:360}))
    end do


    print("*****************开始水平插值************************")  
    xo  =  sst&longitude
    yo  =  sst&latitude
    d2m = linint2_Wrap(d2m_r&longitude, d2m_r&latitude, d2m_r, \
                  True, xo, yo, 0)
    printVarSummary(t)
    delete(d2m_r)

    ;;;通过露点温度计算实际水气压
    actvpr = satvpr_tdew_fao56(d2m,(/1,2/))
    ;;实际比湿
     shum = actvpr
     shum =   0.622*actvpr/(100 - 0.378*actvpr)
     printVarSummary(shum)
    
   

  ;;;计算海洋的饱和比湿
     es = sst
     es =satvpr_temp_fao56(sst,(/0,2/))             ;;;先计算饱和水气压,输出的单位是kpa
     p = 100 ;; 100kpa,地面气压
     qs = es
   
     qs =   0.622*es/(p - 0.378*es)
     printVarSummary(qs)
      

      ;;;
     q_diff = shum
     printVarSummary(shum)
     q_diff = (/qs - shum/)
     
    

   ;;;处理成年数据 
       q_diff_annual = month_to_annual(q_diff(:,{lat1:lat2},{lon1:lon2}), 1)
       q_diff_scs = dim_avg_n_Wrap(q_diff(:,{0:15},{110:155}), 0)
   ;;;

    
   ;;趋势
       q_rc = regCoef_n(ispan(1, yearnum, 1), q_diff_annual, 0, 0)
       copy_VarCoords(q_diff_annual(1,:,:), q_rc)
       q_rc = (/q_rc*yearnum/)
   ;;;
       delete(shum)



   ;;;云量的数据以及趋势
    ; f4=addfile("/home/ys17-19/lsh/data/ICOADS/ssta.mean.nc", "r")
    ; f4=addfile("/home/yangsong3/data-observation/ICOADS2/Enhanced/ssta.mean.nc", "r")

    ; date:=cd_calendar(f4->time, 1)
    ; timeind:=ind(date.ge.198001.and.date.le.201312)
    ; ssta = short2flt(f4->ssta(timeind,:,:))
    ; delete(ssta&time)
    ; ssta&time=date(timeind)
    ; printVarSummary(ssta)

    
    yearin  = ispan(1980, 2013, 1)
    fils4 = "/home/yangsong3/data-observation/ERA-interim/monthly/cloud/cloud_monthly_" + yearin + ".nc"
    f4 = addfiles(fils4, "r")

    date:=cd_calendar(f4[:]->time, 1)
    timeind:=ind(date.ge.startmon.and.date.le.endmon)
    time = f4[:]->time(timeind)
    lat = f4[1]->latitude
    lon = f4[1]->longitude
  

      ssta = new((/dimsizes(time),dimsizes(lat),dimsizes(lon)/),float)
   
    do i = 0,dimsizes(timeind)/12-1
      ssta(i*12:(i+1)*12-1,:,:) = short2flt(f4[i]->tcc(:,:,:))
    end do
    ; ;;;插值，missing value值给去掉，只能限制longitude的5点和纬向的1点
    ; opt=(/0,5/)
    ; ;;先插值lon方向的
    ; ssta=(/linmsg_n(ssta, opt, 2)/)
    ; ;;插值lat方向的
    ; opt=(/0,1/)
    ; ssta=(/linmsg_n(ssta, opt, 1)/)
    ; delete(opt)
    ssta_annual  = month_to_annual(ssta(:,{lat1:lat2},{lon1:lon2}), 1)
    ;;;



    ssta_annual&year = ispan(1, 34, 1)
    printVarSummary(ssta_annual)

    ssta_annual_tropical=dim_avg_n_Wrap(month_to_annual(ssta(:,{-30:30},:),1), (/1,2/))
    do i=0,dimsizes(ssta_annual&year)-1
        ssta_annual(i,:,:)=(/ssta_annual(i,:,:)-ssta_annual_tropical(i)/)
    end do
    ;;

    ssta_rc = regCoef_n(ispan(1, yearnum, 1), ssta_annual, 0, 0)
    copy_VarCoords(ssta_annual(1,:,:), ssta_rc)
    ssta_rc = (/ssta_rc*yearnum/)
    



  ;;;;风速的趋势
    path_wind = "/home/yangsong3/data-observation/ERA-interim/monthly/ERA_interim_10m_wind_speed.nc"
    f1 = addfile(path_wind,"r")

    date:=cd_calendar(f1->time, 1)
    timeind:=ind(date.ge.startmon.and.date.le.endmon)

    ; u = short2flt(f1->si10(timeind,{lat1:lat2},{lon1:lon2}))
    u = short2flt(f1->si10(timeind,{-90:90},{0:360}))
    ;  print("*****************开始水平插值************************")  
    ; xo  =  sst&longitude
    ; yo  =  sst&latitude
    ; u = linint2_Wrap(u_r&longitude, u_r&latitude, u_r, \
    ;               True, xo, yo, 0)
    ; printVarSummary(u)
    ; delete(u_r)
    


    

   ;;;处理成年数据 
     u_annual = month_to_annual(u, 1)
   ;;;

   ;;回归
    u_rc = regCoef_n(ispan(1, yearnum, 1), u_annual, 0, 0)
    copy_VarCoords(u_annual(1,:,:), u_rc)
    u_rc = (/u_rc*yearnum/)
   ;;;

  
   ;;;显著性检验
    prob_q = rc_test(q_rc)
    prob_u = rc_test(u_rc)
    prob_t = rc_test(t_rc)
    prob_ssta = rc_test(ssta_rc)
   ;;;

 
   ;;; 
   ; d_rc = where(prob_d.le.0.1, d_rc, d_rc@_FillValue)
   ; sta_s_rc = where(prob_sta_s.le.0.1, sta_s_rc, sta_s_rc@_FillValue)
   ; u_rc = where(prob_u.le.0.1.or.prob_v.le.0.1, u_rc, u_rc@_FillValue)

;==============================================================
; Mission 4. draw plot
; ==============================================================
  wks   = gsn_open_wks("pdf", "云量,湿度,风速,温差在南海区域的趋势-era云量数据-露点温度计算的ERA湿度")

  res=True
  res@gsnFrame=False
  res@gsnDraw=False
  res@gsnAddCyclic = False
  
  res@cnFillPalette="BlRe"

  res@cnFillOn=True
  res@cnLinesOn=False

  res@cnLevelSelectionMode = "ManualLevels"      ; set manual contour level
  ; res@cnMinLevelValF       =   -1.0
  ; res@cnMaxLevelValF       =   1.0
  ; res@cnLevelSpacingF      =  0.2
  res@cnMinLevelValF       =   -0.05
  res@cnMaxLevelValF       =   0.05
  res@cnLevelSpacingF      =  0.01
  ; res@cnLevelSelectionMode = "ManualLevels"      ; set manual contour level
  ; res@cnMinLevelValF       =   -0.03
  ; res@cnMaxLevelValF       =   0.03
  ; res@cnLevelSpacingF      =  0.01


  res@cnLineLabelsOn=False
  res@lbLabelBarOn=True
  res@lbLabelStride=2
  res@lbOrientation="Vertical"
  res@mpLimitMode           = "LatLon"
  res@mpMinLatF             = lat1
  res@mpMaxLatF             = lat2
  res@mpMinLonF             = lon1
  res@mpMaxLonF             = lon2
  res@mpCenterLonF          = (res@mpMinLonF+res@mpMaxLonF)/2.0

  res@tmXTOn=False
  res@tmYROn=False
  res@tmXBOn=True
  res@tmYROn=False

  res@tmXBLabelFontHeightF=0.015
  res@tmYLLabelFontHeightF=0.015
  res@tmXBMajorThicknessF=3.0
  res@tmYLMajorThicknessF=3.0
  res@tmBorderThicknessF=4.0
  res@gsnLeftString  = "Total Cloud Cover"
  res@mpFillOn =False

  ; res@mpShapeMode="FreeAspect"
  ; res@vpHeightF=0.3
  ; res@vpWidthF=0.8
  plot = new(4, graphic)
  
  plot(0) = gsn_csm_contour_map(wks,ssta_rc,res)
  res@gsnLeftString  = "Ts - Ta"
  res@cnMinLevelValF       =   -1.0
  res@cnMaxLevelValF       =   1.0
  res@cnLevelSpacingF      =  0.2
  plot(1) = gsn_csm_contour_map(wks,t_rc,res)
   res@cnMinLevelValF       =   -1.0
  res@cnMaxLevelValF       =   1.0
  res@cnLevelSpacingF      =  0.2
    res@gsnLeftString  = "10-m Wind Speed"
  plot(2) = gsn_csm_contour_map(wks,u_rc,res)
  res@gsnLeftString  = "qs - qa"
  res@cnMinLevelValF       =   -0.001
  res@cnMaxLevelValF       =   0.001
  res@cnLevelSpacingF      =  0.0002
  ; res@lbAutoManage = False
  ; res@lbLabelAutoStride = False
  ; res@lbLabelStride = 2
  ; res@lbLabelStrings =  sprintf("%2.1e", fspan(res@cnMinLevelValF,res@cnMaxLevelValF,11))



  plot(3) = gsn_csm_contour_map(wks,q_rc,res)


  ; ;;添加区域
   ;;warm pool
   pgres = True
   pgres@gsLineThicknessF=2.0
   pgres@gsLineDashPattern=0
  
   str = (/"1","2","3","4"/)
   
   ;;;画box
   lat1 = 0
   lat2 = 15
   lon1 = 110
   lon2 = 155

   pgx_pool=(/lon1,lon2,lon2,lon1,lon1/)
   pgy_pool=(/lat1,lat1,lat2,lat2,lat1/)
   ;;;

   do  i =0,3
   plot@$str(i)$ = gsn_add_polyline(wks, plot(i), pgx_pool, pgy_pool, pgres)
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
    res_pro@cnLevelSpacingF     = 0.1      ; set contour spacing

    res_pro@cnLineLabelsOn=False
    res_pro@tmYRMode = "Automatic"
    res_pro@cnInfoLabelOn=False

    iplot = new(4,graphic)
  
  
    iplot(0) = gsn_csm_contour(wks,prob_ssta,res_pro)
    iplot(1) = gsn_csm_contour(wks,prob_t,res_pro)
    iplot(2) = gsn_csm_contour(wks,prob_u,res_pro)
    iplot(3) = gsn_csm_contour(wks,prob_q,res_pro)

    opt                      = True
    opt@gsnShadeFillType     = "pattern"
    opt@gsnShadeMid     = 6         ; stipple
    ; opt@gsnShadeFillDotSizeF =  0.0025
    ; opt@gsnShadeHigh   = "green"
    opt@gsnShadeFillScaleF   = 0.5         ; add extra density ,越大越係數


    do i = 0,3
     iplot(i) = gsn_contour_shade(iplot(i) , 0,0.1,opt)
    end do


    do i =0,3
    overlay(plot(i), iplot(i))
    end do 
    
   pres = True
   pres@gsnPanelFigureStrings = (/"a","b","c","d"/)
   gsn_panel(wks, plot, (/2,2/), pres)

end
    
  







    
   
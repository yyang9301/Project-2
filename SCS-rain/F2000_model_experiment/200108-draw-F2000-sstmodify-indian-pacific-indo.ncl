;;********************************************************
;;将模式的海温数据的印度洋地区的海温增加，增加的幅度是通过计算sst_HadOIBl_bc_1.9x2.5_1978_2012_c130411.nc这个文件的趋势
;;得到一个新的海温数据，注意在文件中的其他数据要保留不能变化
;;用来跑F2000实验
;;lnshuheng 2019.12.07 
;**********************************************************
;test
begin
;;;---------------读入变化的海温数据----------------------------
    fils1 = "/home/ys17-19/lsh/CESM-data/modsst/sst_HadOIBl_bc_1.9x2.5_clim_c061031.nc"
    f1 = addfile(fils1, "r")
    lon = f1->lon
    lat = f1->lat

    SST_cpl = f1->SST_cpl(:,:,:)
   

    fils2 = "/home/ys17-19/lsh/CESM-data/modsst/sst_HadOIBl_bc_1.9x2.5_clim_c061031_addindianwarming.nc"
    f2 = addfile(fils2, "r")
    
    SST_cpl_indian= f2->SST_cpl(:,:,:)
    
    fils3 = "/home/ys17-19/lsh/CESM-data/modsst/sst_HadOIBl_bc_1.9x2.5_clim_c061031_addpacificwarming.nc"
    f3 = addfile(fils3, "r")
    
    SST_cpl_pacific= f3->SST_cpl(:,:,:)

    fils4 = "/home/ys17-19/lsh/CESM-data/modsst/sst_HadOIBl_bc_1.9x2.5_clim_c061031_addindopacific.nc"
    f4 = addfile(fils4, "r")
    
    SST_cpl_indopacific= f4->SST_cpl(:,:,:)
    

;;;---------------
     
;;diff 
  sst_cpl_diff_indian = dim_avg_n_Wrap(SST_cpl_indian,0) - dim_avg_n_Wrap(SST_cpl, 0)
  copy_VarCoords(SST_cpl(1,:,:), sst_cpl_diff_indian)

  sst_cpl_diff_pacific = dim_avg_n_Wrap(SST_cpl_pacific,0) - dim_avg_n_Wrap(SST_cpl, 0)
  copy_VarCoords(SST_cpl_pacific(1,:,:), sst_cpl_diff_pacific)

  sst_cpl_diff_indopacific = dim_avg_n_Wrap(SST_cpl_indopacific,0) - dim_avg_n_Wrap(SST_cpl, 0)
  copy_VarCoords(SST_cpl_indopacific(1,:,:), sst_cpl_diff_indopacific)


;;;


;;; draw 
   wks=gsn_open_wks("pdf", "diff-cesmsstdata2modify-Pacific-indian-Indo-Pacific")
    
    res=True
    res@gsnDraw=False
    res@gsnFrame=False
    res@gsnAddCyclic=True

    res@cnLineColors="Transparent"  ;
    res@lbLabelBarOn=False
    res@cnFillOn = True 
    res@cnLinesOn =False
    res@cnLineLabelsOn=False
    res@cnRasterSmoothingOn=True

    res@cnFillPalette = "BlueWhiteOrangeRed"

    res@cnLevelSelectionMode = "ManualLevels"      ; set manual contour levels

    res@cnMinLevelValF       =   -0.9
    res@cnMaxLevelValF       =   0.9
    res@cnLevelSpacingF      =  0.1


    res@tmXTOn=False
    res@tmYROn=False

    res@mpLimitMode           = "LatLon"
    res@mpMinLatF             = -90.0
    res@mpMaxLatF             = 90.0
    res@mpMinLonF             = 0.0
    res@mpMaxLonF             = 360.0
    res@mpCenterLonF          = 180.0
    res@mpFillOn   = True
    res@mpFillColor = "gray"
    res@mpFillDrawOrder = "PostDraw"
  

    plot=new(3,graphic)
    
    plot(0) =gsn_csm_contour_map(wks, sst_cpl_diff_indian, res)
    plot(1) =gsn_csm_contour_map(wks, sst_cpl_diff_pacific({-20:30},:), res)
    plot(2) =gsn_csm_contour_map(wks, sst_cpl_diff_indopacific({-20:30},:), res)
    
    

    pres = True
    pres@gsnPanelLabelBar = True
    gsn_panel(wks, plot, (/3,1/), pres)




end 

     







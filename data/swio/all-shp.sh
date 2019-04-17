for file in $(find . -name 'SWIO_*_LOSS_AAL_ADM_2.shp' ) 
do  
	~/bin/import-loss-shp.sh $file; 
done

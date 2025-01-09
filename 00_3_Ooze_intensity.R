####################################################################################################
#### Ooze intensity into developed
#### Author: Ben Gannon (benjamin.gannon@usda.gov)
#### Date Created: 08/31/2024
#### Last Modified: 12/31/2024
####################################################################################################
# Creates set of conditional flame length probability rasters with values spread into developed
# areas for assessing wildfire risk to assets.
# Filter number and size consistent with latest Wildfire Risk to Communities (2024, v2) data.
####################################################################################################
#-> Set directory and file paths
setwd('E:/QWRA')
fil_paths <- paste0('E:/QWRA/INPUT/Hazard/',
                    c('nvc_flp_0_2.tif','nvc_flp_2_4.tif','nvc_flp_4_6.tif','nvc_flp_6_8.tif',
					  'nvc_flp_8_12.tif','nvc_flp_gt12.tif'))
fm40_path <- './INPUT/Fuel/FM40_u2023.tif'
out_path <- './INPUT/Hazard/Oozed'
####################################################################################################

###########################################START MESSAGE############################################
cat('Ooze intensity into developed\n',sep='')
cat('Started at: ',as.character(Sys.time()),'\n\n',sep='')
cat('Messages, Errors, and Warnings (if they exist):\n')
####################################################################################################

############################################START SET UP############################################

#-> Load packages
pd <- .libPaths()[1]
packages <- c('terra','readxl')
for(package in packages){
	if(suppressMessages(!require(package,lib.loc=pd,character.only=T))){
		install.packages(package,lib=pd,repos='https://mirror.las.iastate.edu/CRAN/')
		suppressMessages(library(package,lib.loc=pd,character.only=T))
	}
}

#-> Read in intensity rasters
fil.l <- list() # List to store fire intensity level probability rasters
for(i in 1:6){
	fil.l[[i]] <- rast(fil_paths[i])
}

#-> Read in fire behavior fuel model 40 raster
fm40 <- rast(fm40_path)

#############################################END SET UP#############################################

###########################################START ANALYSIS###########################################

#-> Define oozing fill zone
# Pick relevant non-burnable fuel models, choice depends on context
# 91 Urban/Developed, 92 Snow/Ice, 93 Agricultural, 98 Open Water, 99 Bare Ground
ofzone <- ifel(fm40 %in% c(91,93),1,NA)
#writeRaster(ofzone,paste0(out_path,'/oozing_fill_zone.tif'),overwrite=T)

#-> Identify fueled sources and non-sources based on patch size threshold
fueled <- ifel(fm40 > 100,1,NA)
th <- ceiling(500/(prod(res(fueled))/10000))
fpatches <- patches(fueled,directions=8)
fpcnts <- freq(fpatches)
fpcnts$lpatch <- ifelse(fpcnts$count >= th,1,NA)
fpcnts$spatch <- ifelse(fpcnts$count < th,1,NA)
fueled_la <- classify(fpatches,rcl=fpcnts[,c('value','lpatch')])
#writeRaster(fueled_la,paste0(out_path,'/oozing_fueled_large.tif'),overwrite=T)
fueled_sm <- classify(fpatches,rcl=fpcnts[,c('value','spatch')])
#writeRaster(fueled_sm,paste0(out_path,'/oozing_fueled_small.tif'),overwrite=T)

#-> Loop through fils to ooze intensity values into developed areas
# Note that this is done independently for each fil, potentially creating situations in which the
# oozed values do not sum to one - this will be corrected in a subsequent reweighting step.
ofil.l <- list() # List to store oozed fil rasters
for(i in 1:length(fil.l)){	
	
	#-> Subset to single raster
	fil <- fil.l[[i]]
	
	#-> Set fil source to NA outside of large fueled patches
	fil <- ifel(!is.na(fueled_la),fil,NA)
	
	#-> Apply three focal means
	# Use mean instead of weighted sum because NAs are considered zero with sum function
	fwm <- focalMat(fil,d=510,type='circle',fillNA=F) # Focal weights matrix
	fm1 <- focal(fil,w=fwm,fun='mean',na.rm=T)
	fm2 <- focal(fm1,w=fwm,fun='mean',na.rm=T)
	fm3 <- focal(fm2,w=fwm,fun='mean',na.rm=T)
	
	#-> Save to list
	ofil.l[[i]] <- fm3
	
}

#-> Reweight oozed values, mosiac with original outside oozing zone
osum <- sum(rast(ofil.l),na.rm=T)
mfil.l <- list() # List to store mosaic fil rasters
for(i in 1:length(fil.l)){

	#-> Reweight single raster
	rwfil <- ifel((osum > 0) & !is.na(osum),ofil.l[[i]]/osum,0)
	
	#-> Assemble filled fil
	fil_fueled <- ifel(!is.na(fueled_la) | !is.na(fueled_sm),fil.l[[i]],NA)
	fil_base <- ifel(is.na(ofzone),fil.l[[i]],NA)
	fil_ofzone <- ifel(!is.na(ofzone) & !is.na(rwfil),rwfil,NA)
	mfil.l[[i]] <- sum(fil_base,fil_ofzone,na.rm=T,
	                   filename=paste0(out_path,'/fil',i,'.tif'),overwrite=T)
	
}

#-> Save raster of unassessed area
ozone_unass <- ifel(!is.na(ofzone) & (fm40 < 100) & is.na(osum),1,NA)
writeRaster(ozone_unass,paste0(out_path,'/unassessed.tif'),overwrite=T)	

#-> Save raster of oozed area
oozed <- ifel((osum > 0) & !is.na(osum) & (ofzone==1),1,NA)
writeRaster(oozed,paste0(out_path,'/oozed_areas.tif'),overwrite=T)	

############################################END ANALYSIS############################################

####################################################################################################
cat('\nFinished at: ',as.character(Sys.time()),'\n\n',sep='')
############################################END MESSAGE#############################################

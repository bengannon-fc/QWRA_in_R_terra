####################################################################################################
#### Create landscape value raster
#### Author: Ben Gannon (benjamin.gannon@usda.gov)
#### Date Created: 10/19/2022
#### Last Modified: 08/29/2024
####################################################################################################
# Creates weighted map of "landscape value" based on HVRA extent and Relative Importance Per Pixel 
# (RIPP).
####################################################################################################
#-> Set directory and file paths
setwd('E:/QWRA')
ri_path <- 'QWRA_Workbook.xlsx'
data_path <- './INPUT/HVRA'
####################################################################################################

###########################################START MESSAGE############################################
cat('Create landscape value raster\n',sep='')
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

#-> Read in relative importance per pixel table
ripp <- data.frame(read_excel(ri_path,sheet='CalcTable'))
ripp <- ripp[,c('Raster','Raster.value','RIPP')]
colnames(ripp) <- c('Raster','Value','RIPP')
ripp <- ripp[!is.na(ripp$Raster),]

#############################################END SET UP#############################################

###########################################START ANALYSIS###########################################

#-> Get list of tiffs to process
TIFFs <- unique(ripp$Raster)

#-> Loop through tiffs
for(i in 1:length(TIFFs)){	
	inrast <- rast(paste0(data_path,'/',TIFFs[i],'.tif'))
	rcl <- ripp[ripp$Raster==TIFFs[i],][,c('Value','RIPP')]
	lvi <- classify(inrast,rcl)
	lvi[is.na(lvi)] <- 0
	if(exists('lv')){
		lv <- lv + lvi
	}else{
		lv <- lvi
	}
}
writeRaster(lv,'./OUTPUT/Pre_landscape_value.tif',overwrite=T)

############################################END ANALYSIS############################################

####################################################################################################
cat('\nFinished at: ',as.character(Sys.time()),'\n\n',sep='')
############################################END MESSAGE#############################################

####################################################################################################
#### Get count of pixels in each HVRA class
#### Author: Ben Gannon (benjamin.gannon@usda.gov)
#### Date Created: 10/13/2022
#### Last Modified: 08/28/2024
####################################################################################################
# Get count of pixels in each HVRA class. Providing a vector mask is optional.
####################################################################################################
#-> Set user inputs
setwd('E:/QWRA')
data_path <- './INPUT/HVRA'
# vmask <- './INPUT/analysis_extent.shp'
####################################################################################################

###########################################START MESSAGE############################################
cat('Get count of pixels in each HVRA class\n',sep='')
cat('Started at: ',as.character(Sys.time()),'\n\n',sep='')
cat('Messages, Errors, and Warnings (if they exist):\n')
####################################################################################################

############################################START SET UP############################################

#-> Load packages
pd <- .libPaths()[1]
packages <- c('terra')
for(package in packages){
	if(suppressMessages(!require(package,lib.loc=pd,character.only=T))){
		install.packages(package,lib=pd,repos='https://mirror.las.iastate.edu/CRAN/')
		suppressMessages(library(package,lib.loc=pd,character.only=T))
	}
}

#-> Read in filter if used
if(exists('vmask')){
	vmask <- vect(vmask)
}

#############################################END SET UP#############################################

###########################################START ANALYSIS###########################################

#-> Get list of tiffs in folder
TIFFs <- list.files(path=data_path,pattern='\\.tif$')

#-> Loop through tiffs
et.l <- list()
for(i in 1:length(TIFFs)){	
	inrast <- rast(paste0(data_path,'/',TIFFs[i]))
	if(exists('vmask')){
		inrast <- mask(inrast,vmask)
	}
	pcdf <- freq(inrast)
	pcdf$layer <- unlist(strsplit(TIFFs[i],'[.]'))[1]
	et.l[[i]] <- pcdf
}
etdf <- do.call('rbind',et.l)
write.csv(etdf,'HVRA_extents.csv',row.names=F)

############################################END ANALYSIS############################################

####################################################################################################
cat('\nFinished at: ',as.character(Sys.time()),'\n\n',sep='')
############################################END MESSAGE#############################################

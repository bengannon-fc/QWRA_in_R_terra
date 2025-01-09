####################################################################################################
#### Calculate conditional and expected Net Value Change with BIG DATA
#### Author: Ben Gannon (benjamin.gannon@usda.gov)
#### Date Created: 11/08/2022
#### Last Modified: 08/30/2024
####################################################################################################
# This is a generic workflow designed to complete QWRA calculations from:
# 1) a set of fire hazard modeling results (BP, FIL1-6)
# 2) a set of HVRA rasters
# 3) a table specifying the HVRAs, sub-HVRAs, and associated response functions
#
# This version is structured to work with big data. The temp directory is placed within the
# output folder, so make sure you have 50-100 GB of free space on the drive. The temp directory
# for the terra package is reset and deleted several times to keep temporary files from filling 
# the entire drive. If possible, use the standard script - the calculations are the same and the
# run time is faster. In general, this script will be required for regional QWRAs if input data
# are 30-m resolution. BE VERY CAREFUL modifying this code to make sure you don't accidentally 
# delete files/folders by misdirecting the unlink() operations!!!
#
# Notes:
# 1) only cNVC rasters are created for sub-HVRAs
# 2) cNVC and eNVC rasters are created for HVRAs and totals
####################################################################################################
#-> Set user inputs
setwd('E:/QWRA')
QWRAwb <- 'QWRA_Workbook.xlsx' # QWRA workbook
HVRArp <- './INPUT/HVRA' # HVRA raster folder
OUTp <- './OUTPUT' # Output folder
# vmask <- './INPUT/test_mask.shp' # Optional mask
####################################################################################################

###########################################START MESSAGE############################################
cat('Calculate conditional and expected Net Value Change with BIG DATA\n',sep='')
cat('Started at: ',as.character(Sys.time()),'\n\n',sep='')
cat('Messages, Errors, and Warnings (if they exist):\n')
####################################################################################################

############################################START SET UP############################################

#-> Load packages (or install if you don't have them)
pd <- .libPaths()[1]
packages <- c('terra','plyr','readxl')
for(package in packages){
	if(suppressMessages(!require(package,lib.loc=pd,character.only=T))){
		install.packages(package,lib=pd,repos='https://mirror.las.iastate.edu/CRAN/')
		suppressMessages(library(package,lib.loc=pd,character.only=T))
	}
}

#-> Adjust terra settings
tdir_l1 <- paste0(OUTp,'/temp') # Create temporary directory within output folder
dir.create(paste0(OUTp,'/temp'))
terraOptions(progress=0,tempdir=tdir_l1)

#-> Load in tabular data
ct <- data.frame(read_excel(QWRAwb,sheet='CalcTable')) # Calculations table
ct <- ct[!is.na(ct$Primary.HVRA.Code),] # Drop null rows
ct$Sub.HVRA.Code[is.na(ct$Sub.HVRA.Code)] <- 'None' # Assign non to any blank sub-HVRA fields
hps <- data.frame(read_excel(QWRAwb,sheet='HazardPaths')) # Hazard paths

#-> Select first HVRA raster as template for extent
trast <- rast(paste0(HVRArp,'/',ct$Raster[1],'.tif'))

#-> Load in hazard modeling
bp <- crop(rast(hps[hps$Name=='BP','Path']),trast)
fil.l <- list() # List to store fire intensity level probability rasters
for(i in 1:6){
	fil.l[[i]] <- crop(rast(hps[hps$Name==paste0('FIL',i),'Path']),trast)
}

#############################################END SET UP#############################################

###########################################START ANALYSIS###########################################

#-> Create raster for mask if provided
if(exists('vmask')){
	vmask <- project(vect(vmask),trast)
	rmask <- rasterize(vmask,trast,field=1)
}

#-> Get vector of HVRA categories
HVRAs <- unique(ct$Primary.HVRA.Code)

cNVC.l <- list() # List to store HVRA cNVC results
for(i in 1:length(HVRAs)){ # Loop through HVRAs
	
	cat('#-> Processing',HVRAs[i],'HVRA\n')
	
	#-> Subset processing into another temp directory for memory management
	tdir_l2 <- paste0(OUTp,'/temp/l2') 
	dir.create(paste0(OUTp,'/temp/l2') )
		
	#-> Get vector of sub-HVRA categories
	sHVRAs <- unique(ct[ct$Primary.HVRA.Code==HVRAs[i],'Sub.HVRA.Code'])

	cNVC_s.l <- list() # List to store sub-HVRA results
	for(j in 1:length(sHVRAs)){
		
		cat('Processing sub-HVRA',sHVRAs[j],j,'of',length(sHVRAs),'\n')
			
		#-> Subset calculations table
		ct_s <- ct[ct$Primary.HVRA.Code==HVRAs[i] & ct$Sub.HVRA.Code==sHVRAs[j],]
		
		cNVC_sc.l <- list() # List to store covariate results
		for(k in 1:nrow(ct_s)){
			
			#-> Subset processing into another temp directory for memory management
			tdir_l3 <- paste0(OUTp,'/temp/l2/l3') 
			dir.create(paste0(OUTp,'/temp/l2/l3'))
			terraOptions(tempdir=tdir_l3)
			
			#-> Read in HVRA raster
			HVRA_s <- rast(paste0(HVRArp,'/',ct_s$Raster[k],'.tif'))
			
			#-> Make binary raster for HVRA value
			HVRA_bin <- ifel(HVRA_s==ct_s$Raster.value[k],1,NA)
			
			#-> Calculate cNVC
			cNVC_sc <- sum(c(fil.l[[1]]*ct_s$FIL1[k],fil.l[[2]]*ct_s$FIL2[k],
			                 fil.l[[3]]*ct_s$FIL3[k],fil.l[[4]]*ct_s$FIL4[k],
							 fil.l[[5]]*ct_s$FIL5[k],fil.l[[6]]*ct_s$FIL6[k]),
							 na.rm=T)
			
			#-> Save weighted cNVC to list
			if(exists('vmask')){
				writeRaster(cNVC_sc*ct_s$RIPP[k]*HVRA_bin*rmask,
				            paste0(tdir_l2,'/wcNVC_',j,'_',k,'.tif'))
			}else{
				writeRaster(cNVC_sc*ct_s$RIPP[k]*HVRA_bin,paste0(tdir_l2,'/wcNVC_',j,'_',k,'.tif'))
			}
			cNVC_sc.l[[k]] <- rast(paste0(tdir_l2,'/wcNVC_',j,'_',k,'.tif'))
			
			#-> Save RIPP weight to total landscape value raster
			if(exists('tlr')){
				tlr <- sum(c(tlr,HVRA_bin*ct_s$RIPP[k]),na.rm=T,
				           filename=paste0(tdir_l1,'/tlr_n.tif'),overwrite=T)
				unlink(paste0(tdir_l1,'/tlr.tif'))
				g <- file.rename(paste0(tdir_l1,'/tlr_n.tif'),paste0(tdir_l1,'/tlr.tif'))
				tlr <- rast(paste0(tdir_l1,'/tlr.tif'))
			}else{
				tlr <- ifel(!is.na(HVRA_bin),ct_s$RIPP[k],NA,filename=paste0(tdir_l1,'/tlr.tif'),
				            overwrite=T)
			}
			
			#-> Delete temporary files
			terraOptions(tempdir=tdir_l2)
			unlink(tdir_l3,recursive=T) # Delete covariate temp files
			g <- gc() # Clean up RAM
			
		}
		
		#-> Create sub-HVRA cNVC raster
		if(sHVRAs[j] != 'None'){
			cNVC_s.l[[j]] <- sum(rast(cNVC_sc.l),na.rm=T,filename=paste0(OUTp,'/',HVRAs[i],'_',
			                     sHVRAs[j],'_cNVC.tif'))
		}else{
			cNVC_s.l[[j]] <- sum(rast(cNVC_sc.l),na.rm=T,filename=paste0(tdir_l1,'/',HVRAs[i],'_',
			                     sHVRAs[j],'_cNVC.tif'))
		}
	}
	
	#-> Create HVRA cNVC raster
	cNVC.l[[i]] <- sum(rast(cNVC_s.l),na.rm=T,filename=paste0(OUTp,'/',HVRAs[i],'_cNVC.tif'))
	
	#-> Create HVRA eNVC raster
	writeRaster(cNVC.l[[i]]*bp,paste0(OUTp,'/',HVRAs[i],'_eNVC.tif'))
	
	#-> Delete temporary files
	terraOptions(tempdir=tdir_l1)
	unlink(tdir_l2,recursive=T) # Delete sub-HVRA temp files
	g <- gc() # Clean up RAM
	
	cat('\n')
	
}

#-> Calculate total cNVC
cat('Calculating total cNVC\n')
cNVC <- sum(rast(cNVC.l),na.rm=T)
#cNVC[is.na(cNVC)] <- 0 # Can optionally fill background with zero
writeRaster(cNVC,paste0(OUTp,'/','Total_cNVC.tif'),overwrite=T)

#-> Calculate total eNVC
cat('Calculating total eNVC\n')
writeRaster(cNVC*bp,paste0(OUTp,'/','Total_eNVC.tif'),overwrite=T)

#-> Save total landscape value raster
if(exists('vmask')){
	tlr <- tlr*rmask
}
writeRaster(tlr,paste0(OUTp,'/','Total_landscape_value.tif'),overwrite=T)

#-> Delete temporary files
# Can comment the next line out for testing
unlink(tdir_l1,recursive=T) # Delete full temp file folder

############################################END ANALYSIS############################################

####################################################################################################
cat('\nFinished at: ',as.character(Sys.time()),'\n\n',sep='')
#############################################END MESSAGE############################################

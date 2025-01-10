# QWRA_in_R_terra
This is a workflow to complete a Quantitative Wildfire Risk Assessment (QWRA) using the R terra package. It follows the methods described in Scott et al. (2013) "A wildfire risk assessment framework for land and resource management" (https://www.fs.usda.gov/rm/pubs_series/rmrs/gtr/rmrs_gtr315.pdf). Users are encouraged to read this document before attempting the QWRA workflow to learn the theory, terminology, and the general GIS input data types and processes.

Wildfire risk assessment seeks to quantify and map the interaction among highly valued resources and assets (HVRAs), wildfire hazard, and the vulnerability of HVRAs to fire. Hazard is a physical situation with the potential to cause harm. In wildfire risk assessment, hazard is estimated spatially in terms of both fire likelihood and fire intensity. Risk refers to the potential consequences considering both HVRA exposure and susceptibility to fire. This framework measures risk using relative units of Net Value Change (NVC) ranging from -100 for a total loss to +100 for a radical gain. Risk measures include conditional NVC (cNVC), accounting for HVRA extent and response to fire intensity, and expected NVC (eNVC), accounting for HVRA extent, response to fire intensity, and wildfire likelihood. In other words, cNVC assumes exposure to fire and eNVC accounts for the uncertainty in fire occurrence across space and time. Pre-fire mitigation planning should use eNVC.

Mention cNVC and eNVC

Inputs
1) Raster of burn probability
2) Rasters of conditional likelihood of burning under different fire intensity or flame length ranges,
3) Rasters of HVRA extents
4) Table with fire effects response functions and importance weights

Raster input data should have 

Outputs
1) Total landscape value
2) cNVC total and by HVRA/sub-HVRA
3) eNVC total andby HVRA/sub-HVRA

Scripts
4) 

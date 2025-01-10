# QWRA_in_R_terra
This is a workflow to complete a Quantitative Wildfire Risk Assessment (QWRA) using the R terra package. It follows the methods described in Scott et al. (2013) "A wildfire risk assessment framework for land and resource management" (https://www.fs.usda.gov/rm/pubs_series/rmrs/gtr/rmrs_gtr315.pdf). Users are encouraged to read this document before attempting the QWRA workflow to learn the theory, terminology, and the general GIS input data types and processes.

Wildfire risk assessment seeks to quantify and map the interaction among highly valued resources and assets (HVRAs), wildfire hazard, and the vulnerability of HVRAs to fire. Hazard is a physical situation with the potential to cause harm. In wildfire risk assessment, hazard is estimated spatially in terms of both fire likelihood (burn probability raster) and fire intensity (conditional flame length probability rasters). Risk refers to the potential consequences considering both HVRA exposure and susceptibility to fire. This framework measures risk using relative units of Net Value Change (NVC) ranging from -100 for a total loss to +100 for a radical gain. Quantitative response functions are assigned to each HVRA to translate between fire intensity and NVC over six discrete flame length bins (0-2', 2-4', 4-6', 6-8', 8-12', >12'). Risk measures include conditional NVC (cNVC), accounting for HVRA extent and response to fire intensity, and expected NVC (eNVC), accounting for HVRA extent, response to fire intensity, and wildfire likelihood. In other words, cNVC assumes exposure to fire and eNVC accounts for the uncertainty in fire occurrence across space and time. Most wildfire risk assessments examine multiple HVRAs (e.g., people and property, critical infrastructure, drinking water, etc.). Relative importance weights are assigned to HVRAs (and sometimes sub-HVRAs) in order to calculate "total" or "integrated" NVC measures. 

Inputs
1) Raster of burn probability
2) Rasters of conditional likelihood of burning under different fire intensity or flame length ranges
3) Rasters of HVRA extents
4) Table with fire effects response functions and importance weights

*Raster input data should all have the same extent, coordinate system, spatial resolution, and cell alignment. This workflow does not include instructions on wildfire hazard modeling or HVRA raster developement. 

Outputs
1) Total landscape value showing the importance assigned to each raster cell
2) cNVC total and by HVRA/sub-HVRA
3) eNVC total and by HVRA/sub-HVRA

QWRA Workbook

The "MasterTable" and "Relative Importance" worksheets demonstrate a common workflow to assign quantitative response functions and importance weights. HVRAs are ranked and assigned relative importance values in the "Relative Importance" worksheet that can be visualized with a pie chart. Each row in the master table refers to an HVRA or sub-HVRA that is mapped in one of the input HVRA rasters. HVRAs can be divided into sub-HVRAs where multiple resource or asset types contribute to a theme in the risk assessment, for example, critical infrastructure may include both communication sites and electric power transmission lines. Sub-HVRAs can be assigned different relative importance weights. This worksheet uses a technique where the sub-HVRAs are assigned Relative Importance Per Pixel (RIPP) Weights on a scale from 0 to 100 that are combined with the HVRA relative importance weights and the extent information to calculate a final RIPP for the risk assessment. HVRAs and sub-HVRAs can also be divided using co-variates to represent how different factors alter the response to fire, e.g., slope and vegetation type alter how watersheds respond to wildfire. Data from the "MasterTable" worksheet is copied over to the simpler "CalcTable" worksheet as input to the QWRA calculation scripts. 

Scripts
1) 00_1_HVRA_extents.R - used to calculate HVRA and sub-HVRA extents to inform relative importance weighting
2) 00_2_Landscape_value_map.R - optional pre-QWRA calculations to map the spatial distribution of importance across the landscape to evaluate the relative importance weighting
3) 00_3_Ooze_intensity.R - optional pre-QWRA calculations to estimate fire intensity in non-burnable areas adjacent to wildland fuels such as the fringes of developed or agricultural areas
4) 01_QWRA_calcs.R - performs QWRA calculations, suitable for large landscapes (e.g., National Forest or BLM District) on most computers
5) 01_QWRA_calcs_manage_memory.R - performs QWRA calculations with more sophisticated memory management to accomodate regional or national scale analyses

*Scripts were developed and tested using R version 4.3.1 and terra version 1.7-46.

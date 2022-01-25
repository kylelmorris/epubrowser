# epubrowser

## Quick start

Open the EPU browser
$ epu.browser.py

Browse and select a star file from a Relion refinement

Browse and select an EPU directory at its top level
This should contain 'Images-disc', 'Metadata' and 'EpuSession.dm'

Enter the Relion star file Micrograph column name
Normally: '_rlnMicrographName'

Enter the Data Suffix which is added due to image processing
Normally: '_Fractions'
Original image name: FoilHole_5871221_Data_5860229_5860231_20210808_185028
As found in the star file: FoilHole_5871221_Data_5860229_5860231_20210808_185028_Fractions.mrc

Run the analysis by clicking Run
Note the first time you run this epu.browser will call a shell script to find each microgrpah and associated hole and square image, this runs line by line and can take some time.

Click Inpsect EPU Images
This will open a new window in whcih you can interactively explore what the micrograph, foil hole and square images looked like for data that was used in the star file versus data that ultimately was not used.

## Demo

Watch the video EPU_browser.mp4 for a quick visual representation of what you might expect to find. Note this is performed on a subset of data in a Relion star file for speed.

## Description

Python and shell scripts for analysing EPU directories based on a Relion format particle star file. The analysis will allow you to visualise which micrographs were ultimately utilised in Relion processing and further to inspect what the foilhole and grid square looked like from which useful particles were identified. If particle coordinates are present in the star file then they can be shown on the micrograph for further understanding on trends in the data.

## Motivation

I would expect the develops of EPU are writing this functionality but it was necessary to write this code to troubleshoot a data set where 99% of the particles were being thrown away, without an obvious reason.

This framework can find and display square images that led to productive 3D reconstruction in SPA and as such holds the potential to be able to guide SPA set up on new targets, based on the output of real time SPA analyses.

## FAQ

Please watch the short movie 'EPU_browser.mp4' to familiarise yourself with the functionality of this software.
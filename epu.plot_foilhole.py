#!/usr/bin/env python
#

# This code is adapted from a python script kindly shared by T.J.Ragen - University of Leciester, 2019

import os
import sys
import xml.etree.ElementTree as ET

import matplotlib
import matplotlib.pyplot as plt

# FEI EPU xml stuff
ns = {'p': 'http://schemas.datacontract.org/2004/07/Applications.Epu.Persistence'}  # TODO: versioning
ns['system'] = 'http://schemas.datacontract.org/2004/07/System'
ns['so'] = 'http://schemas.datacontract.org/2004/07/Fei.SharedObjects'
ns['g'] = 'http://schemas.datacontract.org/2004/07/System.Collections.Generic'
ns['s'] = 'http://schemas.datacontract.org/2004/07/Fei.Applications.Common.Services'
ns['a'] = 'http://schemas.datacontract.org/2004/07/System.Drawing'

# Define functions
def xmlParse(filein):
    # Read xml file for square
    tree = ET.parse(filein)
    root = tree.getroot()
    # Find stage positions in xml file
    stagePositionX = root.find('so:microscopeData/so:stage/so:Position/so:X', ns).text
    stagePositionY = root.find('so:microscopeData/so:stage/so:Position/so:Y', ns).text
    pixelSize = root.find('so:SpatialScale/so:pixelSize/so:x/so:numericValue', ns).text
    # Return variables from function
    # Remember variables cease to exist outside of function
    return float(stagePositionX)*1e6, float(stagePositionY)*1e6, float(pixelSize)*1e6

################################################################################

# Crude input variables for xml file
xmlSq=str(sys.argv[1])
xmlFoilHole=str(sys.argv[2])

# Get variables from xml file
sqMicronX,sqMicronY,sqMicronPix = xmlParse(xmlSq)
fhMicronX,fhMicronY,fhMicronPix = xmlParse(xmlFoilHole)

# Calculate FoilHole location on Square in microns
fhLocMicronX = sqMicronX-fhMicronX
fhLocMicronY = sqMicronY-fhMicronY
# Convert to pixels
fhLocPxX = fhLocMicronX/sqMicronPix
fhLocPxY = fhLocMicronY/sqMicronPix
# Convert to pixel coordinates based on detector size
fhPlotPxX = 2048+fhLocPxX
fhPlotPxY = 2048-fhLocPxY

print(fhPlotPxX)
print(fhPlotPxY)

################################################################################

# Plot coordinate to file to display as overlay on square image
fig = plt.figure(figsize=(1024/100.,1024/100.), dpi=100)
ax = fig.add_axes([0,0,1,1])
ax.set_xlim([0,4096])
ax.set_ylim([0,4096])
ax.axis('off')

ax.scatter(fhPlotPxX, fhPlotPxY, facecolors='none', edgecolors='r', s=300)
plt.savefig("FoilHole.png", bbox_inches=0, transparent='True')

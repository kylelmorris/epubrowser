#!/usr/bin/env python
#

############################################################################
#
# Author: "Kyle L. Morris"
# eBIC Diamond Light Source 2022
#
# This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
############################################################################

# This code is adapted from a python script kindly shared by T.J.Ragen - University of Leciester, 2019

import os
import sys
import xml.etree.ElementTree as ET

# Crude input variables for xml file
arg=str(sys.argv[1])
#file=os.path.splitext(arg)[0]

# Read xml file
tree = ET.parse(arg)
root = tree.getroot()

# FEI EPU xml stuff
ns = {'p': 'http://schemas.datacontract.org/2004/07/Applications.Epu.Persistence'}  # TODO: versioning
ns['system'] = 'http://schemas.datacontract.org/2004/07/System'
ns['so'] = 'http://schemas.datacontract.org/2004/07/Fei.SharedObjects'
ns['g'] = 'http://schemas.datacontract.org/2004/07/System.Collections.Generic'
ns['s'] = 'http://schemas.datacontract.org/2004/07/Fei.Applications.Common.Services'
ns['a'] = 'http://schemas.datacontract.org/2004/07/System.Drawing'

# Find beam diameter in xml file
beamDiameter = root.find('so:microscopeData/so:optics/so:BeamDiameter', ns).text
stagePositionA = root.find('so:microscopeData/so:stage/so:Position/so:A', ns).text
stagePositionB = root.find('so:microscopeData/so:stage/so:Position/so:B', ns).text
stagePositionX = root.find('so:microscopeData/so:stage/so:Position/so:X', ns).text
stagePositionY = root.find('so:microscopeData/so:stage/so:Position/so:Y', ns).text
stagePositionZ = root.find('so:microscopeData/so:stage/so:Position/so:Z', ns).text
pixelSize = root.find('so:SpatialScale/so:pixelSize/so:x/so:numericValue', ns).text

#filterSlit = root.find('so:microscopeData/so:EnergyFilter/so:EnergySelectionSlitWidth', ns).text

micronPix = float(pixelSize)*1e6
micronX = float(stagePositionX)*1e6
micronY = float(stagePositionY)*1e6

print('stagePosX: '+str(micronX))
print('stagePosY: '+str(micronY))

print('micronPix: '+str(micronPix))

#print('Filter width: '+str(filterSlit))

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


https://realpython.com/python-xml-parser/

Exposure xml:
/Users/vtn87135/Dropbox/-WORK/eBIC/Science/Collaborations/Rueda/20210806_krios_3_data_collection/bubble_em/data/nt21004-559/EPU_demo/EPU_analysis/squares_all/GridSquare_20210806_123453_Data/FoilHole_5862071_Data_5860229_5860231_20210806_123912.xml

Squares xml:
/Users/vtn87135/Dropbox/-WORK/eBIC/Science/Collaborations/Rueda/20210806_krios_3_data_collection/bubble_em/data/nt21004-559/EPU_demo/EPU_analysis/squares_all/GridSquare_20210806_123453.xml

import xml.etree.ElementTree as ET

# Read xml
doc = ET.parse("/Users/vtn87135/Dropbox/-WORK/eBIC/Science/Collaborations/Rueda/20210806_krios_3_data_collection/bubble_em/data/nt21004-559/EPU_demo/EPU_analysis/squares_all/GridSquare_20210806_123453_Data/FoilHole_5862071_Data_5860229_5860231_20210806_123912.xml")

# Show roots of xml
root = doc.getroot()

# Show element's children
for child in root:
	print(child.tag)

	{http://schemas.datacontract.org/2004/07/Fei.SharedObjects}name
	{http://schemas.datacontract.org/2004/07/Fei.SharedObjects}uniqueID
	{http://schemas.datacontract.org/2004/07/Fei.SharedObjects}CustomData
	{http://schemas.datacontract.org/2004/07/Fei.SharedObjects}IntensityScale
	{http://schemas.datacontract.org/2004/07/Fei.SharedObjects}ReferenceTransformation
	{http://schemas.datacontract.org/2004/07/Fei.SharedObjects}SpatialScale
	{http://schemas.datacontract.org/2004/07/Fei.SharedObjects}microscopeData

# Get element in a root and pull out tag and text
element = root[2]
element.tag

	'{http://schemas.datacontract.org/2004/07/Fei.SharedObjects}CustomData'

element.text

# Get descendants in element
for descendant in root.iter():
	print(descendant.tag)

# Get a specific descendant in an element
tag_name = "{http://schemas.datacontract.org/2004/07/Fei.SharedObjects}BeamDiameter"
for descendant in root.iter(tag_name):
	print(descendant)

	<Element '{http://schemas.datacontract.org/2004/07/Fei.SharedObjects}BeamDiameter' at 0x7f94e80c4400>

# Get the tag and text in an element
tag_name = "{http://schemas.datacontract.org/2004/07/Fei.SharedObjects}BeamDiameter"
for descendant in root.iter(tag_name):
	print(descendant.tag, "=", descendant.text)

	{http://schemas.datacontract.org/2004/07/Fei.SharedObjects}GunLens = 4



tag_name = "{http://schemas.datacontract.org/2004/07/Fei.SharedObjects}CustomData"

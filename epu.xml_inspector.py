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

import os
import sys
import platform
import tkinter as tk
from tkinter import *
from tkinter import ttk
from tkinter import filedialog
from tkinter.ttk import Progressbar
import subprocess

from PIL import ImageTk, Image

import glob

import xml.etree.ElementTree as ET

# This scripts location
exe = sys.argv[0]
exedir = os.path.dirname(sys.argv[0])

###############################################################################

### Defines button functions

def browsexml():
    # Browse to dir
    main_frame.filename =  filedialog.askopenfilename(initialdir = "~",title = "Select EPU xml file")
    xmlin = main_frame.filename
    # Update xml file path in GUI
    box_xml.delete(0, tk.END)
    box_xml.insert(0, xmlin)
    # Get data from xml file and load corresponding micrograph
    parsexml()
    loadmic()
    getNames()

# Use this function to load a default xml for testing
def testxml():
    box_xml.insert(0, str(exedir)+"/data/test.xml")
    parsexml()
    loadmic()
    getNames()

def loadxml():
    # Read file containing selected jpg from epu browser GUI
    # This should really be done with passing over a variable
    # https://www.code4example.com/python/tkinter/tkinter-passing-variables-between-windows/
    with open('.micrograph.dat', 'r') as f:
        for line in f:
            pass
        last_line = line
    print(last_line)
    # Turn jpg path into xml path
    xmlpath = os.path.splitext(last_line)[0]
    imgpath = xmlpath+".xml"
    # Populate GUI with xml file path
    box_xml.insert(0, imgpath)
    parsexml()
    loadmic()
    getNames()

### Define GUI behaviours

def RBGAImage(path):
    return Image.open(path).convert("RGBA")

def loadmic():
    # Read xml
    xmlfile = box_xml.get()
    # File name
    xmlpath = os.path.splitext(xmlfile)[0]
    imgpath = xmlpath+".jpg"
    # Load micrograph
    load = RBGAImage(imgpath)
    width, height = load.size
    print(width, height)
    ratio = width/height
    print(ratio)
    load = load.resize((400,int(400/ratio)), Image.ANTIALIAS)
    micRender = ImageTk.PhotoImage(load)
    imgMic = Label(main_frame, image=micRender)
    imgMic.image = micRender
    imgMic.place(x=3, y=380)

def getNames():
    # Show file names in GUI
    xmlFileName=os.path.basename(box_xml.get())
    box_xmlFile.delete(0, tk.END)
    box_xmlFile.insert(0, xmlFileName)
    imgFileName=os.path.splitext(os.path.basename(box_xml.get()))[0]+".jpg"
    box_imgFile.delete(0, tk.END)
    box_imgFile.insert(0, imgFileName)

### Define xml parsing functions
# Adapted from code from T. J. Raegen, University of Leicester

def parsexml():
    # FEI EPU xml stuff
    ns = {'p': 'http://schemas.datacontract.org/2004/07/Applications.Epu.Persistence'}
    ns['system'] = 'http://schemas.datacontract.org/2004/07/System'
    ns['so'] = 'http://schemas.datacontract.org/2004/07/Fei.SharedObjects'
    ns['g'] = 'http://schemas.datacontract.org/2004/07/System.Collections.Generic'
    ns['s'] = 'http://schemas.datacontract.org/2004/07/Fei.Applications.Common.Services'
    ns['a'] = 'http://schemas.datacontract.org/2004/07/System.Drawing'

    # Read xml
    xmlfile = box_xml.get()
    tree = ET.parse(xmlfile)
    root = tree.getroot()

    ## Find data
    # Defocus
    defocus = root.find('so:microscopeData/so:optics/so:Defocus', ns).text
    micronDF = float(defocus)*1e6
    df=str(micronDF)
    # Exposure time
    time = root.find('so:microscopeData/so:acquisition/so:camera/so:ExposureTime', ns).text
    # Beam shift
    #beamShiftA = root.find('so:microscopeData/so:optics/so:BeamShift/so:a:_x', ns).text
    # Optics
    spot = root.find('so:microscopeData/so:optics/so:SpotIndex', ns).text
    mag = root.find('so:microscopeData/so:optics/so:TemMagnification/so:NominalMagnification', ns).text
    beam = root.find('so:microscopeData/so:optics/so:BeamDiameter', ns).text
    micronBeamD = float(beam)*1e9
    beamD=str(micronBeamD)

    # Stage
    stagePositionA = root.find('so:microscopeData/so:stage/so:Position/so:A', ns).text
    stagePositionB = root.find('so:microscopeData/so:stage/so:Position/so:B', ns).text
    stagePositionX = root.find('so:microscopeData/so:stage/so:Position/so:X', ns).text
    stagePositionY = root.find('so:microscopeData/so:stage/so:Position/so:Y', ns).text
    stagePositionZ = root.find('so:microscopeData/so:stage/so:Position/so:Z', ns).text
    micronX = float(stagePositionX)*1e6
    micronY = float(stagePositionY)*1e6
    micronZ = float(stagePositionZ)*1e6

    # Report data
    box_xmlDF.insert(0, df)
    box_time.insert(0, time)
    box_spot.insert(0, spot)
    box_mag.insert(0, mag)
    box_beam.insert(0, beamD)
    box_stageX.insert(0, micronX)
    box_stageY.insert(0, micronY)
    box_stageZ.insert(0, micronZ)

###############################################################################

### Create GUI
main_frame = tk.Tk()

main_frame.title("XML data inspector for EPU image")
main_frame.geometry('700x800')

## Text and button entry
row = 0

## File browser
row += 1
buttonxml = tk.Button(main_frame, text="Browse xml", command=browsexml)
buttonxml.grid(column=0, row=row)
entry_xml = tk.StringVar()
box_xml = tk.Entry(main_frame, width=60,textvariable=entry_xml)
box_xml.grid(column=1, row=row)

## File Information
# xml name
row += 1
lbl = Label(main_frame, text='xml file:', anchor=W, justify=RIGHT)
lbl.grid(sticky="e",column=0, row=row)
entry_xmlFile = tk.StringVar()
box_xmlFile = tk.Entry(main_frame, width=60,textvariable=entry_xmlFile)
box_xmlFile.grid(column=1, row=row)

# jpg name
row += 1
lbl = Label(main_frame, text='img file:', anchor=W, justify=RIGHT)
lbl.grid(sticky="e",column=0, row=row)
entry_imgFile = tk.StringVar()
box_imgFile = tk.Entry(main_frame, width=60,textvariable=entry_imgFile)
box_imgFile.grid(column=1, row=row)

## XML report
row += 1
lbl = Label(main_frame, text='Data read from EPU xml file:', anchor=W, justify=LEFT)
lbl.grid(sticky="w",column=1, row=row)

# Exposure time
row += 1
lbl = Label(main_frame, text='Exposure (sec):', anchor=W, justify=RIGHT)
lbl.grid(sticky="e",column=0, row=row)
entry_time = tk.StringVar()
box_time = tk.Entry(main_frame, width=60,textvariable=entry_time)
box_time.grid(column=1, row=row)

row += 1
lbl = Label(main_frame, text='Stage:', anchor=W, justify=LEFT)
lbl.grid(sticky="w",column=1, row=row)

# Stage position
row += 1
lbl = Label(main_frame, text='Stage X (um):', anchor=W, justify=RIGHT)
lbl.grid(sticky="e",column=0, row=row)
entry_stageX = tk.StringVar()
box_stageX = tk.Entry(main_frame, width=60,textvariable=entry_stageX)
box_stageX.grid(column=1, row=row)

row += 1
lbl = Label(main_frame, text='Stage Y (um):', anchor=W, justify=RIGHT)
lbl.grid(sticky="e",column=0, row=row)
entry_stageY = tk.StringVar()
box_stageY = tk.Entry(main_frame, width=60,textvariable=entry_stageY)
box_stageY.grid(column=1, row=row)

row += 1
lbl = Label(main_frame, text='Stage Z (um):', anchor=W, justify=RIGHT)
lbl.grid(sticky="e",column=0, row=row)
entry_stageZ = tk.StringVar()
box_stageZ = tk.Entry(main_frame, width=60,textvariable=entry_stageZ)
box_stageZ.grid(column=1, row=row)

row += 1
lbl = Label(main_frame, text='Optics:', anchor=W, justify=LEFT)
lbl.grid(sticky="w",column=1, row=row)

# Spot, mag, beam
row += 1
lbl = Label(main_frame, text='Spot:', anchor=W, justify=RIGHT)
lbl.grid(sticky="e",column=0, row=row)
entry_spot = tk.StringVar()
box_spot = tk.Entry(main_frame, width=60,textvariable=entry_spot)
box_spot.grid(column=1, row=row)

row += 1
lbl = Label(main_frame, text='Mag:', anchor=W, justify=RIGHT)
lbl.grid(sticky="e",column=0, row=row)
entry_mag = tk.StringVar()
box_mag = tk.Entry(main_frame, width=60,textvariable=entry_mag)
box_mag.grid(column=1, row=row)

row += 1
lbl = Label(main_frame, text='Beam (nm):', anchor=W, justify=RIGHT)
lbl.grid(sticky="e",column=0, row=row)
entry_beam = tk.StringVar()
box_beam = tk.Entry(main_frame, width=60,textvariable=entry_beam)
box_beam.grid(column=1, row=row)

# Defocus
row += 1
lbl = Label(main_frame, text='Defocus (µm):', anchor=W, justify=RIGHT)
lbl.grid(sticky="e",column=0, row=row)
entry_xmlDF = tk.StringVar()
box_xmlDF = tk.Entry(main_frame, width=60,textvariable=entry_xmlDF)
box_xmlDF.grid(column=1, row=row)

## Micrograph image
micLoad = Image.open(str(exedir)+"/data/testMic.jpeg")
micLoad = micLoad.resize((400,400), Image.ANTIALIAS)
micRender = ImageTk.PhotoImage(micLoad)
imgMic = Label(main_frame, image=micRender)
imgMic.image = micRender
imgMic.place(x=3, y=380)

# Use this for testing gui quickly, comment out when you're done
#testxml()

# Use this to load from the EPU browser GUI
loadxml()

main_frame.mainloop()

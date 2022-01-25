#!/bin/bash
#

############################################################################
#
# Author: "Kyle L. Morris"
# eBIC Diamond Light Source 2022
# MRC London Institute of Medical Sciences 2019
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

################################################################################

function clearLastLine() {
        tput cuu 1 && tput el
}

flagcheck=0

while getopts ':-i:-s:-e:-c:' flag; do
  case "${flag}" in
    i) starin=$OPTARG
    flagcheck=1 ;;
    s) suffix=$OPTARG
    flagcheck=1 ;;
    e) epu=$OPTARG
    flagcheck=1 ;;
    c) columnname=$OPTARG
    flagcheck=1 ;;
    \?)
      echo ""
      echo "Invalid option, please read initial program instructions..."
      echo ""
      exit 1 ;;
  esac
done

if [ $flagcheck = 0 ] ; then
  echo "------------------------------------------------------------------"
  echo $(basename $0)
  echo "------------------------------------------------------------------"
  echo "-i - input star file (required)"
  echo "-s - suffix to remove"
  echo "-e - EPU directory"
  echo "-c - star column name"
  echo ""
  echo "------------------------------------------------------------------"
  exit 1
fi

#Get input star file basename
file=$(basename $starin .star)

# Output directory
mkdir -p EPU_analysis

# Out files settings
settings='./EPU_analysis/settings.dat'
EPU_OUT='./EPU_analysis'
star_dir='./EPU_analysis/star'

# Remove any existing analysis
echo ""
echo "Removing existing EPU analysis..."
rm -rf EPU_analysis/squares_all
rm -rf EPU_analysis/squares_used
rm -rf EPU_analysis/squares_not_used
rm -rf EPU_analysis/star

################################################################################
################################################################################

#Save settings to a file
echo "$(basename $0) settings" > ${settings}
echo "" >> ${settings}
echo "Star: $starin" >> ${settings}
echo "EPU: ${epu}" >> ${settings}
echo "Column: ${columnname}" >> ${settings}
echo "Suffix: ${suffix}" >> ${settings}

################################################################################
# Parse input star file (dependent on bashEM github) and assuming > relion 3
################################################################################

# Process relion 3 star file
mkdir EPU_analysis/star
rsync ${starin} $star_dir
epu.star_data_extract.sh ${starin} $star_dir

#Get column number in sar file
echo ''
echo 'star file in:                ' $starin
echo 'Column name to plot:         ' $columnname
echo ''
column=$(grep ${columnname} $star_dir/.mainDataHeader.dat | awk '{print $2}' | sed 's/#//g')
columnname=$(grep ${columnname} $star_dir/.mainDataHeader.dat | awk '{print $1}' | sed 's/#//g')
echo "Column number:                #${column}"
echo ''

#Extract column data without path
awk -v col=$column '{print $col}' $star_dir/.mainDataLines.dat | awk -F"/" '{print $NF}' > ${columnname}.dat
#Report how many particles
echo 'Number of particles in star file:     ' $(wc -l ${columnname}.dat | awk '{print $1}')
#Get the unique micrographs from the particles
cat ${columnname}.dat | sort -u | sed "s/${suffix}//g" > ${columnname}_mics.dat
#cat ${columnname}.dat | uniq -d | sed "s/${suffix}//g" > ${columnname}_mics.dat
lines=$(wc -l ${columnname}_mics.dat | awk '{print $1}')
echo "Number of unique micrograph entries in star file: ${lines}"
echo ''

################################################################################
# Find all squares and their associated square images
################################################################################

# Get all square images using find in epu directory, ignores file path with basename
find ${epu}/* -maxdepth 1 -mindepth 1 -type d | awk -F"/" '{print $NF}' | sort > ${EPU_OUT}/squares_all.dat
sqnoall=$(wc -l ${EPU_OUT}/squares_all.dat | awk '{print $1}')

# Get the image name for that square, excludes file path
## NOTE AGAIN that multiple gridsquare images are sometimes found and the most recent is taken
## NOTE that find requires xargs ls -tlr to get files in date order
while read p ; do
  #find ${epu}/Images-Disc1/${p} -maxdepth 1 -mindepth 1 -type f -exec basename {} \; | grep jpg | grep ^GridSquare | head -n 1
  img=$(find ${epu}/Images-Disc1/${p} -maxdepth 1 -mindepth 1 -type f -print0 | xargs -0 ls -tlr | grep jpg | tail -n 1 | awk -F"/" '{print $NF}')
  q=$(echo "${p},${img}")
  # To work on both Linux (GNU) and OS (BSD) have to manually write out files
  sed "s/${p}/${q}/g" ${EPU_OUT}/squares_all.dat > .sed.tmp && mv .sed.tmp ${EPU_OUT}/squares_all.dat
done < ${EPU_OUT}/squares_all.dat

################################################################################
# Find used squares -
# Look for unique micrograph name
# Search and find which square unique micrographs come from
################################################################################

#Create a file detailing entire EPU directory structure file for all square, foil, exposures
find ${epu}/* -name "*.jpg" > "${EPU_OUT}/EPU_structure.dat"

#Get unique micrograph reference and then column for where GridSquare reference is in file path
#Get a micrograph name
p=$(sed -n 2p ${columnname}_mics.dat)
#Find that micrograph in the directory structure
q=$(grep ${p} "${EPU_OUT}/EPU_structure.dat")
#Find the GridSquare for that micrograph and the column number in the file path
col=$(echo $q | grep "GridSquare" | awk -F"/" '{for(i=1;i<=NF;i++){if ($i ~ /GridSquare/){print i}}}')
#foilRef=$(echo $p | awk -F'_' '{print $2}')

#Create *_mics_sq_used.dat data file
echo '' > ${EPU_OUT}/squares_used.dat

i=1
#Read lines of unique entires and find the grid square images for these
while read p ; do
  #Do line counting and update progress
  echo -e "Processing entry ${i}/${lines}"

  #Reduce micrograph name into FoilHole reference
  foilRef=$(echo $p | awk -F'_' '{print $2}')

  #Get GridSquare names
  grep ${p} "${EPU_OUT}/EPU_structure.dat" | awk -F"/" -v col=$col '{print $col}' >> ${EPU_OUT}/squares_used.dat

  i=$((i+1))
  clearLastLine
done < ${EPU_OUT}/${columnname}_mics.dat

#Remove white space from *_mics_sq_used.dat data file
sed '1d' ${EPU_OUT}/squares_used.dat > .sed.tmp && mv .sed.tmp ${EPU_OUT}/squares_used.dat

#Find the unique GridSquare references and report
#cat ${EPU_OUT}/squares_used.dat | uniq -d > .tmp.dat
cat ${EPU_OUT}/squares_used.dat | sort -u > .tmp.dat
mv .tmp.dat ${EPU_OUT}/squares_used.dat

#Report
echo "Found all unique GridSquare references from star file"
sqnoused=$(wc -l ${EPU_OUT}/squares_used.dat | awk '{print $1}')
echo "Number of unique GridSquares used in star file: ${sqnoused}"
echo ""

################################################################################
# Populate data directories for display by GUI
################################################################################

echo "###############################################################################"
echo ""

mkdir -p EPU_analysis
mkdir -p EPU_analysis/squares_all
mkdir -p EPU_analysis/squares_used
mkdir -p EPU_analysis/squares_not_used

################################################################################
## Copy all square images
################################################################################
echo "Populating all GridSquare images to local EPU_analysis/squares_all directory."
echo ""
while read p ; do
  sqname=$(echo ${p} | awk -F',' '{print $1}')
  sqimg=$(echo ${p} | awk -F',' '{print $2}')
  sqimgname=$(basename ${sqimg} .jpg)
  #cp -r ${epu}/Images*/*/*.mrc EPU_analysis/squares_all
  ln -s ${epu}/Images*/${sqname}/${sqimgname}.jpg EPU_analysis/squares_all
  ln -s ${epu}/Images*/${sqname}/${sqimgname}.xml EPU_analysis/squares_all
done < ${EPU_OUT}/squares_all.dat

################################################################################
## Copy used square images
################################################################################
echo "Populating GridSquare images used in star file to local EPU_analysis/squares_used directory."
echo ""
i=1
#Read lines of unique GridSquares and find the grid square image for these
while read p ; do
  #Do line coutning and update progress
  echo -e "Finding used GridSquare images: ${i}/${sqnoused}"

  # Copy square image from EPU directory to local for inspection, note use of ls to deal with multiple squares images
  dir=$(find ${epu}/* -name ${p} | grep Images)

  file=$(ls -tlrd $dir/*jpg | tail -n 1 | awk '{print $NF}')
  ln -s $file ./EPU_analysis/squares_used
  file=$(ls -tlrd $dir/*xml | tail -n 1 | awk '{print $NF}')
  ln -s $file ./EPU_analysis/squares_used

  i=$((i+1))
  clearLastLine
done < ${EPU_OUT}/squares_used.dat

################################################################################
## Copy not used square images
################################################################################
echo "Populating GridSquare images not used in star file to local EPU_analysis/squares_not_used directory."
echo ""

#Make a copy of all GridSquare images before filtering out squares that were used
rsync -l EPU_analysis/squares_all/* EPU_analysis/squares_not_used/

#Find squares that weren't used in final star file
used=$(ls EPU_analysis/squares_used/*)
for i in ${used} ; do
  name=$(basename ${i})
  rm -rf EPU_analysis/squares_not_used/${name}
done

################################################################################
## Report some final sanity statistics on square usage
################################################################################

echo "###############################################################################"
echo ""

#Total
all=$(ls EPU_analysis/squares_all/*jpg | wc -l)
echo "Number of unique GridSquares found in EPU directory: ${all}"
echo ""
#Used
used=$(ls EPU_analysis/squares_used/*jpg | wc -l)
echo "Number of unique GridSquares used in star file:      ${used}"
echo ""
#Not used
notused=$(ls EPU_analysis/squares_not_used/*jpg | wc -l)
echo "Number of unique GridSquares not used in star file:  ${notused}"
echo ""

echo "###############################################################################"
echo ""

################################################################################
# Copy all Foil hole and Data images in square directories
################################################################################

i=1
#Read lines of unique GridSquares and find the foil hole images for these
while read p ; do
  #Do line counting and update progress
  echo -e "Populating FoilHole and Data images for all GridSquare(s): ${i}/${sqnoall}"

  ## Copy FoilHole images into directory associated with GridSquare image
  # GridSquare reference is different to the GridSquare image name thus
  # Locate the GridSquare image and its name, note use of awk
  j=$(echo ${p} | awk -F',' '{print $1}')
  dir=$(find ${epu}/* -name ${j} | grep Images)

  # sometimes there's more than one square image.... take the last/most recent... this needs investigation as to whether appropriate
  k=$(ls -ltr $dir/*.jpg | tail -n 1 | awk '{print $NF}')
  imname=$(basename $k .jpg)

  echo "Working on ${imname}"
  # Make a directory for this GridSquare image name
  mkdir EPU_analysis/squares_all/${imname}_FoilHoles
  mkdir EPU_analysis/squares_all/${imname}_Data
  # Copy the FoilHole and data images to this directory
  ln -s ${dir}/FoilHoles/*jpg EPU_analysis/squares_all/${imname}_FoilHoles
  ln -s ${dir}/Data/*jpg EPU_analysis/squares_all/${imname}_Data
  # Copy the FoilHole and data metadata to this directory
  ln -s ${dir}/FoilHoles/*xml EPU_analysis/squares_all/${imname}_FoilHoles
  ln -s ${dir}/Data/*xml EPU_analysis/squares_all/${imname}_Data
  #cp -r ${dir}/FoilHoles/*xml EPU_analysis/squares_used/${imname}_FoilHoles
  # Make a file listing those foil hole names for tkinter GUI
  ls EPU_analysis/squares_all/${imname}_FoilHoles/*jpg > EPU_analysis/squares_all/${imname}_FoilHoles.dat

  i=$((i+1))
  clearLastLine
  clearLastLine
done < ${EPU_OUT}/squares_all.dat

echo "Populated FoilHole and Data images for all GridSquare(s)."
echo ''

################################################################################
# Copy used Foil hole and Data images in square directories
################################################################################

#Get the image name for used squares and make unique
uniq ${EPU_OUT}/squares_used.dat > tmp.dat
mv tmp.dat ${EPU_OUT}/squares_used.dat
while read p ; do
  gridSq=$(echo ${p} | awk -F',' '{print $1}')
  img=$(grep ${gridSq} ${EPU_OUT}/squares_all.dat)
  sed "s/${p}/${img}/g" ${EPU_OUT}/squares_used.dat > .sed.tmp && mv .sed.tmp ${EPU_OUT}/squares_used.dat
done < ${EPU_OUT}/squares_used.dat

sqnoused=$(wc -l ${EPU_OUT}/squares_used.dat | awk '{print $1}')

i=1
#Read lines of unique used GridSquares and find the foil hole images for these
while read p ; do
  #Do line counting and update progress
  echo -e "Copying FoilHole and data images on used GridSquare(s): ${i}/${sqnoused}"

  # Get image name associated with Square name
  gridsquare=$(echo ${p} | awk -F',' '{print $1}')
  q=$(grep ${gridsquare} ${EPU_OUT}/squares_all.dat)
	r=$(echo ${q} | awk -F',' '{print $NF}')
	imname=$(basename ${r} .jpg)
	echo "Working on ${imname}"
  # Copy those FoilHoles and data
  rsync -lr EPU_analysis/squares_all/${imname}_FoilHoles EPU_analysis/squares_used
  rsync -lr EPU_analysis/squares_all/${imname}_Data EPU_analysis/squares_used

  # Make a file listing those foil hole names for tkinter GUI
  ls EPU_analysis/squares_used/${imname}_FoilHoles/*jpg > EPU_analysis/squares_used/${imname}_FoilHoles.dat

  i=$((i+1))
  clearLastLine
  clearLastLine
done < ${EPU_OUT}/squares_used.dat

echo "Populated FoilHole and Data images for GridSquare(s) used in star file."
echo ''

################################################################################
# Copy not used Foil hole and Data images in square directories
################################################################################

#Get the image name for notused squares
grep -Fvxf ${EPU_OUT}/squares_used.dat ${EPU_OUT}/squares_all.dat > ${EPU_OUT}/squares_not_used.dat

sqnonot=$(wc -l ${EPU_OUT}/squares_not_used.dat | awk '{print $1}')

i=1
#Read lines of unique used GridSquares and find the foil hole images for these
while read p ; do
  #Do line counting and update progress
  echo -e "Copying FoilHole and data images on not used GridSquare(s): ${i}/${sqnonot}"

  # Get image name associated with Square name
  q=$(grep ${p} ${EPU_OUT}/squares_all.dat)
  r=$(echo ${q} | awk -F',' '{print $2}')
  imname=$(basename ${r} .jpg)
  echo "Working on ${imname}"
  # Copy those FoilHoles
  rsync -lr EPU_analysis/squares_all/${imname}_FoilHoles EPU_analysis/squares_not_used
  rsync -lr EPU_analysis/squares_all/${imname}_Data EPU_analysis/squares_not_used

  # Make a file listing those foil hole names for tkinter GUI
  ls EPU_analysis/squares_not_used/${imname}_FoilHoles/*jpg > EPU_analysis/squares_not_used/${imname}_FoilHoles.dat

  i=$((i+1))
  clearLastLine
  clearLastLine
done < ${EPU_OUT}/squares_not_used.dat

echo "Populated FoilHole and Data images for GridSquare(s) not used in star file."
echo ''

################################################################################
################################################################################

#Report statistics
all=$(ls EPU_analysis/squares_all/*FoilHoles.dat | wc -l | awk '{print $1}')
used=$(ls EPU_analysis/squares_used/*FoilHoles.dat | wc -l | awk '{print $1}')
not=$(ls EPU_analysis/squares_not_used/*FoilHoles.dat | wc -l | awk '{print $1}')
echo ""
echo "Total squares found: ${all}"
echo "Total squares used: ${used}"
echo "Total squares not used: ${not}"
echo ""

#Update results in settings files
echo "Total: ${all}" >> ${settings}
echo "Used: ${used}" >> ${settings}
echo "Not: ${not}" >> ${settings}
echo "" >> ${settings}

#Save epu data to files for tkinter GUI populating
ls ./EPU_analysis/squares_all/*jpg > ${EPU_OUT}/.squares_all.dat
ls ./EPU_analysis/squares_used/*jpg > ${EPU_OUT}/.squares_used.dat
ls ./EPU_analysis/squares_not_used/*jpg > ${EPU_OUT}/.squares_not.dat

#Tidy up
mv ${columnname}*.dat EPU_analysis

echo ""
echo "Done!"
echo "Script written by Kyle Morris"
echo ""
echo "Check the ./EPU_analysis directory..."
echo ""
echo "##########################################################################"

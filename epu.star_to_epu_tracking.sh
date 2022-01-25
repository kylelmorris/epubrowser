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

# settings
settings='settings.dat'

# Remove any existing analysis
echo ""
echo "Removing existing EPU analysis..."
rm -rf EPU_analysis

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
################################################################################

#Get column number in sar file
echo ''
echo 'star file in:                ' $starin
echo 'Column name to plot:         ' $columnname
echo ''
column=$(grep ${columnname} ${starin} | awk '{print $2}' | sed 's/#//g')
columnname=$(grep ${columnname} ${starin} | awk '{print $1}' | sed 's/#//g')
echo "Column number:                #${column}"
echo ''

#Send column data to file, filter out empty lines and remove any file path or particle numbering
awk -v column=$column -v starin=$starin {'print $column'} $starin | grep -v '^$' | sed 's!.*/!!' > .${columnname}.dat
#Report how many particles
echo 'Number of particles in star file:     ' $(wc -l .${columnname}.dat | awk '{print $1}')
#Get the unique micrographs from the particles
cat .${columnname}.dat | uniq -d | sed 's/.mrc//g' | sed "s/${suffix}//g" > .${columnname}_mics.dat
lines=$(wc -l .${columnname}_mics.dat | awk '{print $1}')
echo "Number of unique entries in star file: ${lines}"
echo ''

################################################################################
# Find all squares and their associated square images
################################################################################

# Get all square images using find in epu directory, ignores file path with basename
find ${epu}/Images-Disc1 -maxdepth 1 -mindepth 1 -type d  -exec basename {} \; > .${columnname}_mics_sq_all.dat
sqnoall=$(wc -l .${columnname}_mics_sq_all.dat | awk '{print $1}')

# Get the image name for that square, excludes file path
## NOTE AGAIN that multiple gridsquare images are sometimes found and the last (tail -n 1) is taken, this could be a problem!!!
while read p ; do
  img=$(find ${epu}/Images-Disc1/${p} -maxdepth 1 -mindepth 1 -type f -exec basename {} \; | grep jpg | grep ^GridSquare | tail -n 1)
  q=$(echo "${p},${img}")
  # To work on both Linux (GNU) and OS (BSD) have to manually write out files
  sed "s/${p}/${q}/g" .${columnname}_mics_sq_all.dat > .sed.tmp && mv .sed.tmp .${columnname}_mics_sq_all.dat
done < .${columnname}_mics_sq_all.dat

################################################################################
# Find used squares -
# Reduce particle star file to unique micrographs
# Search and find which square those micrographs come from
################################################################################

#Get unique FoilHole reference and then column for where GridSquare name is in file path
p=$(sed -n 2p .${columnname}_mics.dat)
foilRef=$(echo $p | awk -F'_' '{print $2}')
col=$(find ${epu} -name *${foilRef}* | grep "GridSquare" | awk -F"/" '{for(i=1;i<=NF;i++){if ($i ~ /GridSquare/){print i}}}' | uniq -d)

echo '' > .${columnname}_mics_sq_used.dat

i=1
#Read lines of unique entires and find the grid square images for these
while read p ; do
  #Do line counting and update progress
  echo -e "Processing entry ${i}/${lines}"

  #Reduce micrograph name into FoilHole reference
  foilRef=$(echo $p | awk -F'_' '{print $2}')

  #Get GridSquare names
  find ${epu} -name *${foilRef}* | grep "GridSquare" | awk -F"/" -v col=$col '{print $col}' | uniq -d >> .${columnname}_mics_sq_used.dat

  i=$((i+1))
  clearLastLine
done < .${columnname}_mics.dat

#echo '' > test.dat

#i=1
#for f in $(cat .${columnname}_mics.dat); do
  #echo $i
  #gridRef=$(echo $f | awk -F"_" 'NR==1{print $2}')
  #find ${epu} -name "*${gridRef}*jpg" -type f | awk -F"/" -v col=$col 'NR==1{print $col}' >> test.dat
  #i=$((i+1))
#done

#Find the unique GridSquare references and report
cat .${columnname}_mics_sq_used.dat | uniq -d > .tmp.dat
mv .tmp.dat .${columnname}_mics_sq_used.dat

#Get the image names for those squares
#while read p ; do
#  img=$(grep $p .${columnname}_mics_sq_all.dat | awk -F',' '{print $2}')
#  sed -i "s/${p}/${p},${img}/g" .${columnname}_mics_sq_used.dat
#done < .${columnname}_mics_sq_used.dat

#Report
echo "Found all unique GridSquare references from star file"
sqnoused=$(wc -l .${columnname}_mics_sq_used.dat | awk '{print $1}')
echo "Number of unique GridSquares used in star file: ${sqnoused}"
echo ""

################################################################################
################################################################################

#Save data
mkdir -p EPU_analysis
mkdir -p EPU_analysis/squares_all
mkdir -p EPU_analysis/squares_used
mkdir -p EPU_analysis/squares_not_used

echo "Copying all GridSquare images to local EPU_analysis directory..."
echo ""
while read p ; do
  sqname=$(echo ${p} | awk -F',' '{print $1}')
  sqimg=$(echo ${p} | awk -F',' '{print $2}')
  sqimgname=$(basename ${sqimg} .jpg)
  #cp -r ${epu}/Images*/*/*.mrc EPU_analysis/squares_all
  ln -s ${epu}/Images*/${sqname}/${sqimgname}.jpg EPU_analysis/squares_all
  ln -s ${epu}/Images*/${sqname}/${sqimgname}.xml EPU_analysis/squares_all
done < .${columnname}_mics_sq_all.dat

i=1
#Read lines of unique GridSquares and find the grid square image for these
while read p ; do
  #Do line coutning and update progress
  echo -e "Finding used GridSquare images: ${i}/${sqnoused}"

  # Copy square image from EPU directory to local for inspection
  dir=$(find ${epu} -name ${p} | grep Images)
  #cp -r $dir*/*.mrc EPU_analysis/squares_used
  ln -s $dir*/*.jpg EPU_analysis/squares_used
  ln -s $dir*/*.xml EPU_analysis/squares_used

  i=$((i+1))
  clearLastLine
done < .${columnname}_mics_sq_used.dat

################################################################################
################################################################################

#Make a copy of all GridSquare images before filtering out squares that were used
scp -r EPU_analysis/squares_all/* EPU_analysis/squares_not_used/

echo "Populating EPU_analysis/squares_not_used directory..."
echo ""

#Find squares that weren't used in final star file
used=$(ls EPU_analysis/squares_used/*)
for i in ${used} ; do
  name=$(basename ${i})
  rm -rf EPU_analysis/squares_not_used/${name}
done

################################################################################
# Copy all squares
################################################################################

i=1
#Read lines of unique GridSquares and find the foil hole images for these
while read p ; do
  #Do line counting and update progress
  echo -e "Copying FoilHole and data images for all GridSquare(s): ${i}/${sqnoall}"

  ## Copy FoilHole images into directory associated with GridSquare image
  # GridSquare reference is different to the GridSquare image name thus
  # Locate the GridSquare image and its name, note use of awk
  j=$(echo ${p} | awk -F',' '{print $1}')
  dir=$(find ${epu} -name ${j} | grep Images)

  # sometimes there's more than one square image.... take the last/most recent... this needs investigation as to whether appropriate
  k=$(ls $dir/*.xml | tail -n 1)
  imname=$(basename $k .xml)

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

done < .${columnname}_mics_sq_all.dat

echo ""

################################################################################
# Copy used squares
################################################################################

#Get the image name for used squares and make unique
uniq .${columnname}_mics_sq_used.dat > tmp.dat
mv tmp.dat .${columnname}_mics_sq_used.dat
while read p ; do
  gridSq=$(echo ${p} | awk -F',' '{print $1}')
  img=$(grep ${gridSq} .${columnname}_mics_sq_all.dat)
  sed "s/${p}/${img}/g" .${columnname}_mics_sq_used.dat > .sed.tmp && mv .sed.tmp .${columnname}_mics_sq_used.dat
done < .${columnname}_mics_sq_used.dat

sqnoused=$(wc -l .${columnname}_mics_sq_used.dat | awk '{print $1}')

i=1
#Read lines of unique used GridSquares and find the foil hole images for these
while read p ; do
  #Do line counting and update progress
  echo -e "Copying FoilHole and data images on used GridSquare(s): ${i}/${sqnoused}"

  # Get image name associated with Square name
  gridsquare=$(echo ${p} | awk -F',' '{print $1}')
  q=$(grep ${gridsquare} .${columnname}_mics_sq_all.dat)
	r=$(echo ${q} | awk -F',' '{print $NF}')
	imname=$(basename ${r} .jpg)
	echo $imname
  # Copy those FoilHoles and data
  cp -r EPU_analysis/squares_all/${imname}_FoilHoles EPU_analysis/squares_used
  cp -r EPU_analysis/squares_all/${imname}_Data EPU_analysis/squares_used

  # Make a file listing those foil hole names for tkinter GUI
  ls EPU_analysis/squares_used/${imname}_FoilHoles/*jpg > EPU_analysis/squares_used/${imname}_FoilHoles.dat

  i=$((i+1))
  clearLastLine
done < .${columnname}_mics_sq_used.dat

echo ""

################################################################################
# Copy not used squares
################################################################################

#Get the image name for notused squares
grep -Fvxf .${columnname}_mics_sq_used.dat .${columnname}_mics_sq_all.dat > .${columnname}_mics_sq_notused.dat

sqnonot=$(wc -l .${columnname}_mics_sq_notused.dat | awk '{print $1}')

i=1
#Read lines of unique used GridSquares and find the foil hole images for these
while read p ; do
  #Do line counting and update progress
  echo -e "Copying FoilHole and data images on not used GridSquare(s): ${i}/${sqnonot}"

  # Get image name associated with Square name
  q=$(grep ${p} .${columnname}_mics_sq_all.dat)
  r=$(echo ${q} | awk -F',' '{print $2}')
  imname=$(basename ${r} .jpg)
  echo $imname
  # Copy those FoilHoles
  cp -r EPU_analysis/squares_all/${imname}_FoilHoles EPU_analysis/squares_not_used
  cp -r EPU_analysis/squares_all/${imname}_Data EPU_analysis/squares_not_used

  # Make a file listing those foil hole names for tkinter GUI
  ls EPU_analysis/squares_not_used/${imname}_FoilHoles/*jpg > EPU_analysis/squares_not_used/${imname}_FoilHoles.dat

  i=$((i+1))
  clearLastLine
done < .${columnname}_mics_sq_notused.dat

echo ""

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

#Save settings to files
echo "Total: ${all}" >> ${settings}
echo "Used: ${used}" >> ${settings}
echo "Not: ${not}" >> ${settings}
echo "" >> ${settings}

#Save epu data to files for tkinter GUI populating
ls ./EPU_analysis/squares_all/*jpg > .squares_all.dat
ls ./EPU_analysis/squares_used/*jpg > .squares_used.dat
ls ./EPU_analysis/squares_not_used/*jpg > .squares_not.dat

#Tidy up
mv .${columnname}*.dat EPU_analysis
mv settings.dat EPU_analysis

echo ""
echo "Done!"
echo "Script written by Kyle Morris"
echo ""
echo "Check the ./EPU_analysis directory..."
echo ""
echo "##########################################################################"

#!/bin/bash
#

############################################################################
#
# Author: "Kyle L. Morris"
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

# Variables
if [[ -z $1 ]] || [[ -z $2 ]] ; then

  echo ""
  echo "Variables empty, usage is ${0} (1) (2)"
  echo ""
  echo "(1) = Square xml"
  echo "(2) = FoilHole xml"
  exit

fi

sqxml=$1
fhxml=$2
x=4096
y=4096


#Report important inputs
echo "Detector size input as (px): ${x} x ${y}"
echo ""



# Plot data
gnuplot <<- EOF
set xrange [0:${x}]
set yrange [0:${y}] reverse
set term png transparent truecolor
set term png size 1024,1024
set autoscale xfix
set autoscale yfix
set margins 0,0,0,0
unset xtics
unset ytics
unset border
unset key
set output "particles.png"
plot ".coordinates.dat" using 1:2:(${d}) with circles lc rgb "green" lw 3
EOF

# Finish
echo ""
echo "Done!"
echo "Script written by Kyle Morris"
echo ""

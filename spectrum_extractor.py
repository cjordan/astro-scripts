#!/usr/bin/env python2

import os
import argparse
import numpy as np
import astropy
from astropy.io import fits as pyfits
import matplotlib
from matplotlib import pyplot as plt


parser = argparse.ArgumentParser()
parser.add_argument('ARGV2', type=str)
parser.add_argument('ARGV3', type=str)
parser.add_argument('--verbosity', '-v', action='count', dest='verbosity')
parser.add_argument('--plotting', '-p', action='store_true', dest='plotting')
args = parser.parse_args()

coords = args.ARGV2
inputCube = args.ARGV3


cube = pyfits.open(inputCube, memmap=True)
if args.verbosity > 0: print str(cube.info())+"\n"
for x in str(cube[0].header).split('/'):
    if "HISTORY" not in x:
        line = x.strip()

        if "CRVAL1" in line: x_centre = float(line.split()[-1])
        if "CRVAL2" in line: y_centre = float(line.split()[-1])
        if "CRVAL3" in line: z_centre = float(line.split()[-1])

        if "CDELT1" in line: x_pixel_delta = float(line.split()[-1])
        if "CDELT2" in line: y_pixel_delta = float(line.split()[-1])
        if "CDELT3" in line: z_pixel_delta = float(line.split()[-1])

        if "NAXIS1" in line: x_pixel_num = int(line.split()[-1])
        if "NAXIS2" in line: y_pixel_num = int(line.split()[-1])
        if "NAXIS3" in line: z_pixel_num = int(line.split()[-1])

# Make the "SPECTRA" directory if it doesn't exist
if not os.path.exists("SPECTRA"):
    os.mkdir("SPECTRA")

# Load coordinates (formatted: <GLong> <GLat>)
coordsArray = np.loadtxt(coords)
# Load the cube data. Transpose is necessary so that the third axis is the frequency axis
cubePixels = cube[0].data.transpose((2,1,0))

# Build a vector containing the velocities of the cube
vel_min = -z_pixel_num/2*z_pixel_delta + z_centre
vel_max =  z_pixel_num/2*z_pixel_delta + z_centre
velocity = np.linspace(vel_min/1000, vel_max/1000, num=z_pixel_num)

# For each coordinate pair...
for x, y in coordsArray:
    # Determine the pixel for this coordinate
    xPixel = int( (x-x_centre)/x_pixel_delta + x_pixel_num/2 )
    yPixel = int( (y-y_centre)/y_pixel_delta + y_pixel_num/2 )

    # Pull the frequency axis from this pixel
    spectrum = cubePixels[xPixel, yPixel]
    # Make NANs 0 instead
    spectrum[np.isnan(spectrum)] = 0

    # If the latitude is positive, bring in a "+" for labelling
    if y > 0:
        sign = "+"
    else:
        sign = ""

    # Save spectrum
    np.savetxt("SPECTRA/G"+str(x)+sign+str(y), np.column_stack((np.asarray(velocity), spectrum)), delimiter=" ", fmt="%s")
    print "Saved file: SPECTRA/G"+str(x)+sign+str(y)

    # Display the pixel value used for this spectrum
    if args.verbosity > 0:
        print "Pixel: "+str(xPixel)+","+str(yPixel)+"\n"

    # Plot the spectrum extracted
    if args.plotting:
        fig = plt.figure()
        data = fig.add_subplot(111)
        data.plot(velocity,spectrum)

        plt.xlim(min(velocity),max(velocity))

        plt.suptitle("G"+str(x)+sign+str(y)+"\nPixel: "+str(xPixel)+","+str(yPixel))
        plt.xlabel("V$_{LSR}$ (km/s)")
        plt.ylabel("Flux density (Jy)")

        plt.show()

cube.close()

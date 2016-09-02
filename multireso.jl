using EMPIRE10, Images, ImageMagick, NRIRHOPM
using Pyramids

@windows_only rawData = EMPIRE10.load("C:\\Users\\qyp\\Dropbox\\CTdata\\01_Fixed.raw")#, cropping=true)
@osx_only rawData = EMPIRE10.load("/Users/gnimuc/Documents/4DCTdata/scans/01_Fixed.raw")#, cropping=true)

axial, coronal, sagittal = EMPIRE10.loadimages(rawData, 100, 250, 100, normalized=true)
axial2, coronal2, sagittal2 = EMPIRE10.loadimages(rawData, 100, 260, 100, normalized=true)

fixed = axial
moving = axial2

separate


a = ImagePyramid(fixed.data, GaussianPyramid())



a = Pyramids.generate_gaussian_pyramid(fixed; min_size=15, max_levels=23, filter=[0.0625; 0.25; 0.375; 0.25; 0.0625])

a[1][1]

grayim(a[1][5])

a.pyramid_bands[]

subband(a, 0)

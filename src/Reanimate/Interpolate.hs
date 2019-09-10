{-# LANGUAGE RecordWildCards #-}
module Reanimate.Interpolate where

import Codec.Picture
import Data.Colour
import Data.Colour.CIE
import Data.Colour.CIE.Illuminant
import Data.Colour.SRGB
import Data.Colour.RGBSpace.HSV
import Data.Colour.RGBSpace
import Data.Fixed

data ColorComponents = ColorComponents
  { colorUnpack :: Colour Double -> (Double, Double, Double)
  , colorPack :: Double -> Double -> Double -> Colour Double }

rgbComponents :: ColorComponents
rgbComponents = ColorComponents rgbUnpack sRGB
  where
    rgbUnpack :: Colour Double -> (Double, Double, Double)
    rgbUnpack c =
      case toSRGB c of
        RGB r g b -> (r,g,b)

hsvComponents :: ColorComponents
hsvComponents = ColorComponents unpack pack
  where
    unpack = hsvView.toSRGB
    pack a b c = uncurryRGB sRGB $ hsv a b c

labComponents :: ColorComponents
labComponents = ColorComponents unpack pack
  where
    unpack = cieLABView d65
    pack = cieLAB d65

xyzComponents :: ColorComponents
xyzComponents = ColorComponents cieXYZView cieXYZ

lchComponents :: ColorComponents
lchComponents = ColorComponents unpack pack
  where
    toDeg,toRad :: Double -> Double
    toRad deg = deg/180 * pi
    toDeg rad = rad/pi * 180
    unpack :: Colour Double -> (Double, Double, Double)
    unpack color =
      let (l,a,b) = cieLABView d65 color
          c = sqrt (a*a + b*b)
          h :: Double
          h = (toDeg(atan2 b a) + 360) `mod'` 360
          isZero = round (c*10000) == 0
      in (l, c, if isZero then 0/0 else h)
    pack l c h =
      cieLAB d65 l (cos (toRad h) * c) (sin (toRad h) * c)

interpolate :: ColorComponents -> Colour Double -> Colour Double -> (Double -> Colour Double)
interpolate ColorComponents{..} from to = \d ->
    colorPack (a1 + (a2-a1)*d) (b1 + (b2-b1)*d) (c1 + (c2-c1)*d)
  where
    (a1,b1,c1) = colorUnpack from
    (a2,b2,c2) = colorUnpack to

interpolateRGB8 :: ColorComponents -> PixelRGB8 -> PixelRGB8 -> (Double -> PixelRGB8)
interpolateRGB8 comps from to = toRGB8 . interpolate comps (fromRGB8 from) (fromRGB8 to)

toRGB8 :: Colour Double -> PixelRGB8
toRGB8 c = PixelRGB8 r g b
  where
    RGB r g b = toSRGBBounded c

fromRGB8 :: PixelRGB8 -> Colour Double
fromRGB8 (PixelRGB8 r g b) = sRGB24 r g b
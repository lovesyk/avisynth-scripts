# Multiple experimental functions to try fix epilepsy-prevention screen darkening found on many Japanese TV broadcasts.

function EpilepsyFade(clip c, int start, int end, float gain)
{
    c.trim(start, end)
	animate(-1, framecount - 1, "EpilepsyFade_Levels", 1.0, gain)
    c.trim(0, start-1)+last+c.trim(end+1, 0)
}
function Epilepsy(clip c, int start, int end, float gain)
{
    c.trim(start, end)
	EpilepsyFade_Levels(gain)
    c.trim(0, start-1)+last+c.trim(end+1, 0)
}
function EpilepsyFade_Levels(clip c, float gain)
{
	c.SmoothTweak16(contrast=gain, saturation=gain, TVrange=false, limitSTR=0, dither=-1, HQ=true)
}


function EpilepsyFade2(clip c, int start, int end, float gainCS, float gainSS, float gainCE, float gainSE)
{
    c.trim(start, end)
	animate(0, framecount - 1, "EpilepsyFade_Levels2", gainCS, gainSS, gainCE, gainSE)
    c.trim(0, start-1)+last+c.trim(end+1, 0)
}
function EpilepsyFade_Levels2(clip c, float gainC, float gainS)
{
	c.SmoothTweak16(contrast=gainC, saturation=gainS, TVrange=true, limitSTR=0, dither=-1, HQ=true)
}

function EpilepsyFade3(clip c, int start, int end, float gainCS, float gainSS, float gainCE, float gainSE)
{
    c.trim(start-1, end+1)
	animate(0, framecount - 1, "EpilepsyFade_Levels3", gainCS, gainSS, gainCE, gainSE)
	trim(1,framecount-2)
    c.trim(0, start-1)+last+c.trim(end+1, 0)
}
function EpilepsyFade_Levels3(clip c, float gainC, float gainS)
{
	c.SmoothTweak16(contrast=gainC, saturation=gainS, TVrange=true, limitSTR=0, dither=-1, HQ=true)
}

function SeizureFade_Levels(clip c, float "contrast", float "saturation", int "brightness", bool "TVrange")
{
	c.SmoothTweak16(brightness=brightness, contrast=contrast, saturation=saturation, TVrange=TVrange, limitSTR=0, dither=-1, HQ=true)
}

function SeizureFade(clip c, int "start", int "end", float "contrast_start", float "contrast_end", float "saturation_start", float "saturation_end", int "brightness_start", int "brightness_end", bool "TVrange")
{
  start = default(start, 0)
  end = default(end, framecount(c)-1)
  contrast_start = default(contrast_start, 1.0)
  saturation_start = default(saturation_start, 1.0)
  brightness_start = default(brightness_start, 0)
  ontrast_end = default(contrast_end, 1.0)
  saturation_end = default(saturation_end, 1.0)
  brightness_end = default(brightness_end, 0)
  TVrange = default(TVrange, false)
  
  Trim(c, start-1, end+1)
  Animate(0, FrameCount() - 1, "SeizureFade_Levels", contrast_start, saturation_start, brightness_start, TVrange, contrast_end, saturation_end, brightness_end, TVrange)
	trim(1, FrameCount()-2)
  Trim(c, 0, start-1) + last + Trim(c, end+1, 0)
}

function SeizureFade_LevelsBanDre(clip c, float "ratio", bool "TVrange")
{
  TVrange ? c.SmoothLevels(preset="tv2pc", dither=-1, HQ=true) : c
  Dither_lut16("x 32768 - " + string(ratio) + " * 32768 +")
	SmoothTweak16(saturation=ratio, TVrange=TVrange, limitSTR=0, dither=-1, HQ=true)
  return TVrange ? SmoothLevels(preset="pc2tv", dither=-1, HQ=true) : last
}

function SeizureFadeBanDre(clip c, int "start", int "end", float "ratio_start", float "ratio_end", bool "TVrange")
{
  start = default(start, 0)
  end = default(end, framecount(c)-1)
  ratio_start = default(ratio_start, 1.0)
  ratio_end = default(ratio_end, 1.0)
  TVrange = default(TVrange, false)
  
  Trim(c, start-1, end+1)
  Animate(0, FrameCount() - 1, "SeizureFade_LevelsBanDre", ratio_start, TVrange, ratio_end, TVrange)
	trim(1, FrameCount()-2)
  Trim(c, 0, start-1) + last + Trim(c, end+1, 0)
}
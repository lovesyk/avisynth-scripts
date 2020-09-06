# detectSC 0.2
# Motion-based scene change detection.
#
# Changelog:
# 0.1: 
# - initial beta release
# 0.2 (27.02.13): 
# - merged detectSC2
# - changed default for "thr"
# 0.3 (11.07.13):
# - changed MRecalculate to work on a second, non-luma-mirrored super clip (better detection for black<->white scene changes)
#
# Dependency: MVTools
#
# int	thr (1000):		Threshold for scene change detection. Good values are 500-1500 (500: almost no misses - 1000: quite accurate - 1500: almost no false positives)
# bool	fast (true): 	If enabled, activates motion recalculation (MRecalculate) to increase accuracy
function detectSC(clip c, int "thr", bool "fast")
{
	thr		= default(thr, 1000)
	fast	= default(fast, false)
	
	sup1	= c.mt_lut("x 125 - abs 255 110 / *",U=1,V=1).MSuper(rfilter=4)
	sup2	= c.ColorYUV(levels="TV->PC").MSuper(rfilter=4)
	vec		= sup1.MAnalyse(overlap=4, blksize=16)
	vec		= fast ? vec : sup2.MRecalculate(vec, blksize=8, overlap=2)
	c.MSCDetection(vec, thSCD1=thr)
}

# WriteKey 0.2
# Aegisub keyframe file exporter
#
# Changelog:
# 0.1: 
# - initial beta release
# 0.2 (27.02.13): 
# - replaced with WriteKey2
# - set custom default for "thr"
#
# Dependency: detectSC
#
# For the descriptions of "thr" and "fast" take a look at detectSC's documentation
# string filename ("keyframes.txt"): Path where the keyframes should be saved
# Look at the documentation of detectSC for a description of "thr"
function WriteKey(clip c, int "thr", string "filename")
{
	thr		= default(thr, 500)

	filename = default(filename, "keyframes.txt")
	WriteFileStart(c, filename, """ "# keyframe format v1" """, "Chr(13)Chr(10)",""" "fps " """, "FrameRate(c)")
	global sc = detectSC(c, thr=thr)
	WriteFileIf(last, filename, "AverageChromaU(sc) > 123", "current_frame")
}
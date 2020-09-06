# OverlayInter 0.1 (06.09.2012)
# Converts 60i overlays (like scrolling credits) on top of telecined 24p video to 24p using motion interpolation.
# Required: MVTools2, QTGMC (if not using a custom bobber)
# int		pattern:			First frame of a clean-combed-combed-clean-clean sequence
# int		pos (0):			Overlay position: 0: whole screen - 1: left - 2: top - 3: right - 4: bottom
# int		size (0):			Overlay size in px from the corresponding position
# bool		show (false):		Enable this to show the area selected by "pos" and "size"
# bool		draft (false):		Enable this to speed up processing by using low-quality bobbing and motion interpolation
# string	bobber:				A custom bobber if you do not wish to use "QTGMC(Preset="Very Slow", SourceMatch=2, Lossless=2)"
# string	ivtc:				A custom IVTC if you do not wish to use simple IVTC based on "pattern"
# Based on ivtc_txt60mc 1.1 by Firesledge
function OverlayInter(clip c, int pattern, int "pos", int "size", bool "show", bool "draft", bool "telecine", string "bobber", string "ivtc")
{
	draft		= default(draft, false)
	int_bob		= draft ? "bob()" : """QTGMC(Preset="Very Slow", SourceMatch=2, Lossless=2)"""
	bobber		= default(bobber, int_bob)
	pos			= default(pos, 0)
	size		= default(size, 0)
	show		= default(show, false)
	field_ref	= pattern * 2
	field_ref	= field_ref % 5
	invpos		= (5 - field_ref) % 5
	tc_ref		= pattern % 5
	
	# defining IVTC area
	keep	=	pos == 1 ? c.crop(size, 0, 0, 0) : \
				pos == 2 ? c.crop(0, size, 0, 0) : \
				pos == 3 ? c.crop(0, 0, -size, 0) : \
				c.crop(0, 0, 0, -size)
				
	# defining bob area and bobbing it								  
	bobbed	=	pos == 1 ? Eval("c.crop(0, 0, " + String(size) + "+ 4, 0)." + bobber) : \
				pos == 2 ? Eval("c.crop(0, 0, 0, " + String(size) + " + 4)." + bobber) : \
				pos == 3 ? Eval("c.crop(width(c) - " + String(size) + " - 4, 0, 0, 0)." + bobber) : \
				pos == 4 ? Eval("c.crop(0, height(c) - " + String(size) + " - 4, 0, 0)." + bobber) : Eval("c." + bobber)
	
	# IVTC optimized to reduce telecine artifacts sometimes present on Japanese TV
	ivtc	=	!Defined(ivtc) ? tc_ref==0 ? keep.DoubleWeave().SelectEvery(10,0,3,6,8) : \
								 tc_ref==1 ? keep.DoubleWeave().SelectEvery(10,0,2,5,8) : \
								 tc_ref==2 ? keep.DoubleWeave().SelectEvery(10,0,2,4,7) : \
								 tc_ref==3 ? keep.DoubleWeave().SelectEvery(10,2,4,6,9) : \
								 keep.DoubleWeave().SelectEvery(10,1,4,6,8) : Eval("keep." + ivtc)

	# processing
	bobbed
	clean	= SelectEvery(5, 1 - invpos)
	jitter	= SelectEvery(5, 3 - invpos, 4 - invpos)
	j_sup	= jitter.MSuper()
	vec_sup	= jitter.ColorYUV(levels="TV->PC").MSuper(rfilter=4)
	vect_b	= draft ? j_sup.MAnalyse(overlap=0, blksize=16, isb=true) : vec_sup.MAnalyse(overlap=4, blksize=16, isb=true)
	vect_b	= draft ? vect_b : vec_sup.MRecalculate(vect_b, blksize=8, overlap=2)
	vect_f	= draft ? j_sup.MAnalyse(overlap=0, blksize=16, isb=false) : vec_sup.MAnalyse(overlap=4, blksize=16, isb=false)
	vect_f	= draft ? vect_f : vec_sup.MRecalculate(vect_f, blksize=8, overlap=2)
	comp	= jitter.MFlowInter(j_sup, vect_b, vect_f)
	fixed	= comp.SelectEvery (2, 0)
	Interleave(clean, fixed)
	Trim(invpos / 2, 0)
	
	show ? ColorYUV(off_u=32) : NOP()
	
	# putting everything back together
	pos == 1 ? StackHorizontal(crop(0, 0, -4, 0), ivtc) : \
	pos == 2 ? StackVertical(crop(0, 0, 0, -4), ivtc) : \
	pos == 3 ? StackHorizontal(ivtc, crop(4, 0, 0, 0)) : \
	pos == 4 ? StackVertical(ivtc, crop(0, 4, 0, 0)) : last
}
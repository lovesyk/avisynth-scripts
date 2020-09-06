# TV Telecine Fix (nnIVTC) 0.2
# Tries to remove artifacts induced by bad telecine often found on Japanese TV broadcasts by inversing telecine and then applying BBTFix only on possibly bad frames.
#
# Changelog:
# 0.1: 
# - initial beta release
# 0.2 (27.02.13): 
# - replaced with nnIVTC2
# - fixed error when running without specifying "filter"
#
# Dependencies: BBTFix
#
# int	pattern:	First frame of any clean-combed-combed-clean-clean sequence
# Look at the documentation of BBTFix for a description of the other arguments.
function nnIVTC(clip c, int pattern, float "Cthr", int "SCthr", string "filter", bool "show")
{
	pattern = pattern % 5
	    
	c
	pattern==0 ? DoubleWeave().SelectEvery(10,0,3,6,8) : \
	pattern==1 ? DoubleWeave().SelectEvery(10,0,2,5,8) : \
	pattern==2 ? DoubleWeave().SelectEvery(10,0,2,4,7) : \
	pattern==3 ? DoubleWeave().SelectEvery(10,2,4,6,9) : \
				 DoubleWeave().SelectEvery(10,1,4,6,8)
				 
	Interleave(last, BBTFix(Cthr=Cthr, SCthr=SCthr, filter=filter, safe=false, show=show))
	
	pattern==0 ? SelectEvery(8,0,3,4,6) : \
	pattern==1 ? SelectEvery(8,0,2,5,6) : \
	pattern==2 ? SelectEvery(8,0,2,4,7) : \
	pattern==3 ? SelectEvery(8,0,2,4,7) : \
	SelectEvery(8,1,2,4,6) 
}

# Blind Bad Telecine Fix (BBTFix) 0.2
# Tries to remove artifacts induced by bad telecine often found on Japanese TV broadcasts by freezeframing on scene changes and filtering otherwise.
#
# Changelog:
# 0.1: 
# - initial beta release
# 0.2 (05.03.13): 
# - replaced with BBTFix2
# - fixed global variables overwriting themselves when running multiple instances (adds GRunT as dependency)
# - adjusted "filter" parameter for consistency with nnIVTC
# - new default for SCthr
#
# Dependencies: GRunT, MVTools, RemoveGrain, detectSC
#
# nnIVTC should always be preferred if possible.
# float		Cthr (1):					Chroma threshold for recognizing frames with artifacts
# string	filter (RemoveGrain(3)):	Filter to use when artifacts are detected but freezeframing is not possible
# bool		safe (true):				Disabling this will skip the check whether a freezeframed frame should be filtered or not
# bool		show (false):				Enable to display current Cthr values as well as to append blocks to show whether a scene change is currently detected
# Look at the documentation of detectSC for a description of SCthr.
function BBTFix(clip c, float "Cthr", int "SCthr", string "filter", bool "safe", bool "show")
{
	Cthr		= default(Cthr, 1)
	SCthr		= default(SCthr, 1500)
	filter		= default(filter, "RemoveGrain(3)")
	safe		= default(show, true)
	show		= default(show, false)
	
	c
	filterc		= Eval(filter)
	
	
	ScriptClip("""
	pc			= RemoveGrain(c, 0, 3, 3)
	sc			= detectSC(c, thr=SCthr)
	bsc			= SelectEvery(sc, 1, 1)
	input		= safe ? ConditionalFilter(c, filterc, c, "ChromaUDifference(c, pc)+ChromaVDifference(c, pc)", ">", String(Cthr)) : c
	proc2		= mt_merge(filterc, SelectEvery(input, 1, -1), bsc, luma=true)
	proc		= mt_merge(proc2, SelectEvery(input, 1, 1), sc, luma=true)
	out			= ConditionalFilter(c, show ? c : proc, c, "ChromaUDifference(c, pc)+ChromaVDifference(c, pc)", ">", String(Cthr), show=show)
	show ? out.Overlay(sc.Crop(0, 0, 36, 0)).Overlay(bsc.Crop(0, 0, 36, 0), x=width(out) - 30) : out
	""", args="c, Cthr, SCthr, filterc, safe, show")
}
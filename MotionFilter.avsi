# Applies a filter to motion.
function MotionFilter16(clip c, clip filter, float "maskmod", bool "show", bool "adaptive")
{
	maskmod		= Default(maskmod, 0.1)
	show		= Default(show, false)
	adaptive    = Default(adaptive, true)

    down8   = DitherPost(c, mode=-1)
	next		= SelectEvery(down8, 1, 1)
	prev		= SelectEvery(down8, 1, -1)
	nextdiff	= mt_makediff(down8, next, U=3, V=3)
	prevdiff	= mt_makediff(down8, prev, U=3, V=3)
	#mask		= mt_lutxy(nextdiff, prevdiff, "x 128 - abs y 128 - abs * " + String(maskmod) + " *", U=3, V=3).RemoveGrain(12)
	mask		= mt_lutxy(nextdiff, prevdiff, "x 128 - abs y 128 - abs * " + String(maskmod) + " ^", U=3, V=3).RemoveGrain(12)
	mask    = adaptive ? mask : mt_lutf(mask, mask, "med", "x", u=3, v=3)
	show ? Dither_convert_8_to_16(mask) : Dither_merge16_8(c, filter, mask, U=3, V=3)
}

# Applies a filter to fades.
function FadeFilter16(clip c, clip filter, int "idlethr", int "fadethr", bool "show")
{
	idlethr		= Default(idlethr, 2)
	fadethr		= Default(fadethr, 2)
	show		= Default(show, false)

	expandc		= c.Dither_Luma_Rebuild(s0=1, lsb_in=true, lsb=true, lsb_out=false)
	next		= SelectEvery(expandc, 1, 1)
	nextdiff	= mt_makediff(expandc, next, U=1, V=1)
	nextmed		= mt_lutf(nextdiff, nextdiff, "med", "x", U=1, V=1)
	motionmask	= mt_lutxy(nextmed.SelectEvery(1, -1), nextmed, "x 128 - abs " + String(idlethr) + " < y 128 - abs " + String(idlethr) + " < 0 255 ? 255 ?", U=1, V=1)
	fademask	= mt_lutxy(nextmed.SelectEvery(1, -1), nextmed, "x y - abs " + String(fadethr) + " < 255 0 ?", U=1, V=1)
	finalmask	= mt_merge(mt_lut(expandc, "0", U=1, V=1), fademask, motionmask, U=1, V=1)

	show ? Grayscale(finalmask.Dither_convert_8_to_16()) : Dither_merge16_8(c, filter, finalmask, luma=true)
}

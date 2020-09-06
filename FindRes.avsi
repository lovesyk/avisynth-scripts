# Pre-encoding functions to manually try to find the source resolution of a clip.
# Input the parameters you think might result in the source resolution and try adjusting them until you see the least difference displayed.

function FindRes(clip clp, int target_height, string kernel, float "ar", float "b", float "c")
{
	ar					= Default(ar, float(width(clp))/height(clp))
	target_width_int	= int(target_height*ar)
	target_width		= target_width_int%2 == 0 ? target_width_int : target_width_int + 1

	clp16	= Dither_convert_8_to_16(clp)
	down16	= kernel == "bilinear" ? Debilinear(clp16, target_width, target_height, lsb_inout=true).Dither_resize16(width(clp), height(clp), kernel="bilinear") : \
			  kernel == "bicubic" ? Debicubic(clp16, target_width, target_height, b=b, c=c, lsb_inout=true).Dither_resize16(width(clp), height(clp), a1=b, a2=c, kernel="bicubic") : NOP()
	down8	= DitherPost(down16, mode=-1)

	mt_lutxy(clp, down8, "x y - abs exp", U=1, V=1)
	ScriptClip("Subtitle(String(AverageLuma()))")
	Subtitle(String(target_width) + "x" + String(target_height), align=8)
	mt_lut("x 16 +", U=128, V=128)
}

function FindResRGB(clip clp, int target_height, string kernel, float "ar", float "b", float "c")
{
	ar					= Default(ar, float(width(clp))/height(clp))
	target_width_int	= int(target_height*ar)
	target_width		= target_width_int%2 == 0 ? target_width_int : target_width_int + 1

    clprgb = clp.converttorgb()

	down8	= kernel == "bilinear" ? Debilinear(clprgb, target_width, target_height).bilinearresize(width(clp), height(clp)) : \
			  kernel == "bicubic" ? Debicubic(clprgb, target_width, target_height, b=b, c=c).bicubicresize(width(clp), height(clp), b=b, c=c) : NOP()
    down8 = down8.converttoyv12()

	mt_lutxy(clp, down8, "x y - abs exp", U=1, V=1)
	ScriptClip("Subtitle(String(AverageLuma()))")
	Subtitle(String(target_width) + "x" + String(target_height), align=8)
	mt_lut("x 16 +", U=128, V=128)
}
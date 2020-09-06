function YUVMask(clip c, int y, int u, int v, int threshold, int "mode")
{
	mode		= Default(mode, 0)
	Assert(mode>=0 && mode <=3, "Valid modes are 0-3.")

	ymask		= mt_lut(c, "x " + String(y - threshold) + " > x " + String(y + threshold) + " < 255 0 ? 0 ?", U=1, V=1)
	umask		= mt_lut(UToY(c).GaussResize(width(c),height(c),p=100), "x " + String(u - threshold) + " > x " + String(u + threshold) + " < 255 0 ? 0 ?", U=1, V=1)
	vmask		= mt_lut(VToY(c).GaussResize(width(c),height(c),p=100), "x " + String(v - threshold) + " > x " + String(v + threshold) + " < 255 0 ? 0 ?", U=1, V=1)
	uvmerge		= mt_average(umask, vmask, U=1, V=1)
	yuvmerge	= mt_average(ymask, uvmerge, U=1, V=1)
	mode == 0 ? mt_binarize(yuvmerge, threshold=254, upper=false, U=1, V=1) : \
	mode == 1 ? ymask.Grayscale() : \
	mode == 2 ? umask.Grayscale() : \
	mode == 3 ? vmask.Grayscale() : NOP()
}
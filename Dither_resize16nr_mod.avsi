# Modified version of Dither_resize16nr from Dither Tools v1.27.2 by Firesledge.
# Uses Debilinear and Debicubic in case those are specified by the kernel parameter instead of Dither_resize16.
# Otherwise identical to the original version.
Function Dither_resize16nrmod (clip src, int width, int height,
\	float  "src_left",
\	float  "src_top",
\	float  "src_width",
\	float  "src_height",
\	string "kernel",
\	float  "fh",
\	float  "fv",
\	int    "taps",
\	float  "a1",
\	float  "a2",
\	float  "a3",
\	int    "kovrspl",
\	bool   "cnorm",
\	bool   "center",
\	string "cplace",
\	int    "y",
\	int    "u",
\	int    "v",
\	string "kernelh",
\	string "kernelv",
\	float  "totalh",
\	float  "totalv",
\	bool   "invks",
\	bool   "invksh",
\	bool   "invksv",
\	int    "invkstaps",
\	string "cplaces",
\	string "cplaced",
\	string "csp",
\	bool   "noring")
{
	noring = Default (noring, true)

	Assert (width > 0 && height > 0, "Dither_resize16nr: width and height must be > 0.")

	sr_h  = Float (width ) / Float (src.width () )
	sr_v  = Float (height) / Float (src.height ())
	sr_up =       Dither_max (sr_h, sr_v)
	sr_dw = 1.0 / Dither_min (sr_h, sr_v)
	sr    = Dither_max (sr_up, sr_dw)
	Assert (sr >= 1.0)

	# Depending on the scale ratio, we may blend or totally disable
	# the ringing cancellation
	thr = 2.5
	nrb = (sr > thr)
	nrf = (sr < thr + 1.0 && noring)
	nrr = (nrb) ? Dither_min (sr - thr, 1.0) : 1.0
	nrv = (nrb) ? Round ((1.0 - nrr) * 255) * $010101 : 0

	main = Defined(kernel) && kernel == "debilinear" ? src.Debilinear(width, height, src_left=src_left, src_top=src_top, src_width=src_width, src_height=src_height, lsb_inout=true) : \
           Defined(kernel) && kernel == "debicubic" ?  src.Debicubic(width, height, src_left=src_left, src_top=src_top, src_width=src_width, src_height=src_height, lsb_inout=true, b=a1, c=a2) : \
           src.Dither_resize16 (width, height,
\		src_left  =src_left,
\		src_top   =src_top,
\		src_width =src_width,
\		src_height=src_height,
\		kernel    =kernel,
\		fh        =fh,
\		fv        =fv,
\		taps      =taps,
\		a1        =a1,
\		a2        =a2,
\		a3        =a3,
\		kovrspl   =kovrspl,
\		cnorm     =cnorm,
\		center    =center,
\		cplace    =cplace,
\		y         =y,
\		u         =u,
\		v         =v,
\		kernelh   =kernelh,
\		kernelv   =kernelv,
\		totalh    =totalh,
\		totalv    =totalv,
\		invks     =invks,
\		invksh    =invksh,
\		invksv    =invksv,
\		invkstaps =invkstaps,
\		cplaces   =cplaces,
\		cplaced   =cplaced,
\		csp       =csp
\	)

	nrng = (nrf) ? src.Dither_resize16 (width, height,
\		src_left  =src_left,
\		src_top   =src_top,
\		src_width =src_width,
\		src_height=src_height,
\		kernel    ="gauss",
\		a1        =100,
\		center    =center,
\		cplace    =cplace,
\		cplaces   =cplaces,
\		cplaced   =cplaced,
\		csp       =csp,
\		y         =y,
\		u         =u,
\		v         =v
\	) : main

	nrm = (nrb && nrf) ? main.BlankClip (color_yuv=nrv, height=main.Height()/2) : main

	# To do: use a simple frame blending instead of Dither_merge16
	rgm = 1
	rgc = (nrb) ? -1 : 0
	rgy = Defined (y) ? ((y == 3) ? rgm : rgc) : rgm
	rgu = Defined (u) ? ((u == 3) ? rgm : rgc) : rgm
	rgv = Defined (v) ? ((v == 3) ? rgm : rgc) : rgm
	rguv = Dither_max (rgu, rgv)
	(nrf       ) ? main.Dither_repair16 (nrng, rgy, rguv)            : main
	(nrf && nrb) ? Dither_merge16_8 (main, last, nrm, y=y, u=u, v=v) : last
}
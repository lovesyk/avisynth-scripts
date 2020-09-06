# Expands one of the fields of a frame and completely removes the other one.
function EF(clip c, int frame, bool "top")
{
	top = Default(top, true)
    c.Trim(frame, -1)
    GetParity(0) ? last : ComplementParity()
    SeparateFields()
    top ? Trim(0, -1) :  Trim(1, -1)
    nnedi3(dh=true)
    AssumeFrameBased()
	Interleave(c, last)
	FreezeFrame(frame*2, frame*2, frame*2+1)
	SelectEven()
}
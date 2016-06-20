# JIVTC applies inverse telecine in a way to minimize artifacts often seen on Japanese
# TV broadcasts # followed by recalculating the fields that might still contain some.
#
# Dependencies: MaskTools2, yadifmod, nnedi3
#
# int    pattern:        First frame of any clean-combed-combed-clean-clean sequence.
# int    threshold (10): This setting controls with how much probability one field has to
#                        look better than the other to recalculate the other one using it.
#                        Since there is no point dropping a field on a still (detail loss)
#                        or an action (both results will look bad) scene, keep this above 0.
# bool   draft (false):  If set to true, skip recalculate step (which means keep 50% of bad fields).
# clip   ivtced:         Can be used to supply a custom IVTCed clip.
#                        Keep in mind that the default IVTC process gets rid of 50% of
#                        bad fields which might be "restored" depending on your supplied clip.
# string bobber:         Can be used to supply a custom bobber.
#                        The less information the bobber uses from the other field,
#                        the better the result will be.

function JIVTC(clip c, int pattern, int "thr", bool "draft", clip "ivtced", string "bobber")
{
  pattern = pattern % 5
  thr     = Default(thr, 10)
  draft   = Default(draft, false)

  defivtc = DoubleWeave(c)
  defivtc = pattern==0 ? SelectEvery(defivtc, 10,0,3,6,8) : \
            pattern==1 ? SelectEvery(defivtc, 10,0,2,5,8) : \
            pattern==2 ? SelectEvery(defivtc, 10,0,2,4,7) : \
            pattern==3 ? SelectEvery(defivtc, 10,2,4,6,9) : \
            SelectEvery(defivtc, 10,1,4,6,8) # IVTC by dropping 2 out of the 4 possibly broken fields
  
  ivtced = Default(ivtced, defivtc)
  ivtced = AssumeTFF(ivtced)
  bobbed = Defined(bobber) ? Eval("ivtced." + bobber) : yadifmod(ivtced, order=0, mode=1, edeint=nnedi3(ivtced, 2))
  
  Assert(FrameRate(c)==30000.0/1001, "This filter can only be used with 60i clips.")
  Assert(FrameRate(bobbed)==48000.0/1001, "The bobber you specified does not double the frame rate.")

  sep       = SeparateFields(ivtced)
  even      = SelectEven(sep)
  odd       = SelectOdd(sep)
  # average top field difference to previous frame
  diffprev  = mt_lutxy(even, SelectEvery(even, 1, -1), "x y - abs", U=1, V=1).mt_lutf(ivtced, "avg", "x", U=1, V=1)
  # average bottom field difference to next frame
  diffnext  = mt_lutxy(odd, SelectEvery(odd, 1, 1), "x y - abs", U=1, V=1).mt_lutf(ivtced, "avg", "x", U=1, V=1)
  # diffnext > diffprev ? true : false
  diffmask  = mt_lutxy(diffprev, diffnext, "x y - 0 < 255 0 ?", U=1, V=1)
  # merge recalculated fields according to mask
  prerecalc = mt_merge(SelectOdd(bobbed), SelectEven(bobbed), StackVertical(diffmask, diffmask), luma=true)
  # abs(diffprev - diffnext) < thr ? false : true
  thrmask   = mt_lutxy(diffprev, diffnext, "x y - abs " + String(thr) + " < 0 255 ?", U=1, V=1)
  # restore original IVTCed clip according to mask
  recalc    = mt_merge(ivtced, prerecalc, StackVertical(thrmask, thrmask), luma=true)

  inter = Interleave(ivtced, recalc)
  final = pattern==0 ? SelectEvery(inter, 8, 0, 3, 4, 6) : \
          pattern==1 ? SelectEvery(inter, 8, 0, 2, 5, 6) : \
          pattern==2 ? SelectEvery(inter, 8, 0, 2, 4, 7) : \
          pattern==3 ? SelectEvery(inter, 8, 0, 2, 4, 7) : \
          SelectEvery(inter, 8, 1, 2, 4, 6) # replace possibly broken frames in IVTCed clip with recalculated ones

  draft ? ivtced : final
}
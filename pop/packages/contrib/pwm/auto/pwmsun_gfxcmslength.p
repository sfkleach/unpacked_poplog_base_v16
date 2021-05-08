
section $-library => pwmsun_gfxcmslength;
section $-library$-pwmlib => pwmsun_gfxcmslength;

define global pwmsun_gfxcmslength(cms);
    lvars cms len;
    if cms.islivepwmsuncms then
        pwmidinfo(cms) -> len;
        allbutlast(#_< length(' entries') >_# ,len) -> len;
        strnumber(len);
    else
        false
    endif;
enddefine;

endsection;
endsection;

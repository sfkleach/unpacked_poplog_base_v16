
section $-library => pwm_gfxpagesize;
section $-library$-pwmlib => pwm_gfxpagesize;

define global pwm_gfxpagesize(page) ;
    lvars x size page;
    if page.islivepwm_id then
        pwmidinfo(page) -> size;
        locchar(`x`,1,size) -> x;
        {%
            strnumber(substring(1,x-1,size));
            strnumber(allbutfirst(x,size));
        %}
    else
        false
    endif;
enddefine;

endsection;
endsection;

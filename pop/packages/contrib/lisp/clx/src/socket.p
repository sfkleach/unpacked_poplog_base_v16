
section $-lisp;

uses unix_sockets;

vars (Xsocket, Xstream);


define Read_xsocket();
    lconstant Buff = writeable inits(1);
    if sysread(Xsocket, 1, Buff, 1) == 0 then
        termin
    else
        subscrs(1, Buff)
    endif
enddefine;


define Write_xsocket() with_nargs 1;
    lconstant Buff = writeable inits(1);
    -> subscrs(1, Buff);
    syswrite(Xsocket, 1, Buff, 1)
enddefine;


define open_x_stream(host, display, protocol);
    lvars host, display, protocol, i, j, h;

    get_simple_string(host) -> host;

    /* Get _______display. Explicit mention of display in ____host (between : and .)
        takes priority of _______display passed as parameter.
    */

    if (locchar(`:`, 1, host) ->> i)
    and (locchar(`.`, i, host) ->> j)
    then
        strnumber(substring(i + 1, j - i - 1, host)) -> display
    endif;
    unless pop_true(display) do
        0 -> display
    endunless;

    /* Get ____host. If an empty string, use $DISPLAY if set, and "unix"
        otherwise.
    */

    if i then
        substring(1, i - 1, host) -> host
    endif;
    if host = nullstring
    and (systranslate('DISPLAY') ->> h) then
        if (locchar(`:`, 1, h) ->> i) then
            substring(1, i - 1, h)
        else
            h
        endif -> host
    endif;
    if host = nullstring then
        'unix' -> host
    endif;
/*
    nprintf('Opening X stream: host = %p, display = %p, protocol = %p',
            [% host, display, protocol %]);
*/
    /* Now create socket */

    if host = 'unix' or host = 'localhost' then
        '/tmp/.X11-unix/X' sys_>< display -> host;
        sys_socket(`u`, `S`, true) -> Xsocket;
        host -> sys_socket_peername(Xsocket)
    else
        sys_socket(`i`, `S`, true) -> Xsocket;
        [% host, 6000 + display %] -> sys_socket_peername(Xsocket);
    endif;

    consstream(Read_xsocket, Write_xsocket, Xsocket, Xsocket)
        ->> Xstream
enddefine;


lisp_export(open_x_stream, @SYS:OPEN-X-STREAM, [3 3 1]);

lispsynonym(@SYS:*XSTREAM*, "Xstream");


endsection;

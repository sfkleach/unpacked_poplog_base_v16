
section $-lisp;

vars Io_buffer = writeable inits(4096);


define Check_io_buffer_size(start, End) -> len;
    lvars start, End, len;
    End - start -> len;
    if len fi_> fast_vector_length(Io_buffer) then
        inits(len) -> Io_buffer
    endif
enddefine;


define buffer_read(stream, vector, start, End);
    lvars stream, vector, start, End, dev, len, n;
    if isdevice(stream_source(stream) ->> dev) then
        Check_io_buffer_size(start, End) -> len;
        fast_sysread(dev, 1, Io_buffer, len) -> n;
        move_subvector(1, Io_buffer, start + 1, vector, n)
    else
        lisp_error('Buffer io not supported for this stream', [^stream])
    endif;
    if n == len then nil else true endif
enddefine;


lisp_export(buffer_read, @SYS:BUFFER-READ, [4 4 1]);


define buffer_write(stream, vector, start, End);
    lvars stream, vector, start, End, dev, len, n;
    if isdevice(stream_dest(stream) ->> dev) then
        Check_io_buffer_size(start, End) -> len;
        move_subvector(start + 1, vector, 1, Io_buffer, len);
        fast_syswrite(dev, 1, Io_buffer, len);
        sysflush(dev)
    else
        lisp_error('Buffer io not supported for this stream', [^stream])
    endif;
    nil
enddefine;


lisp_export(buffer_write, @SYS:BUFFER-WRITE, [4 4 1]);


endsection;

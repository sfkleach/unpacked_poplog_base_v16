/***********************************************************************
  The pattern matching parser and meaning generator described in chapter
  5 of Computers and Thought. To use the answer procedure you will first
  need to load the ROUTE library             
************************************************************************/



    add([[the national gallery] isa [gallery]]);
    add([[the tate gallery] isa [gallery]]);
    add([[the national gallery] in [trafalgar square]]);
    add([[trafalgar square] isa [square]]);
    add([[hyde park] isa [park]]);
    add([[hyde park] containing [the serpentine lake]]);
    add([[the serpentine lake] isa [lake]]);
    add([[trafalgar square] containing [nelsons column]]);
    add([[nelsons column] isa [monument]]);
    add([[hyde park] underground [marble arch]]);
    add([[the tate gallery] underground [pimlico]]);
    add([[trafalgar square] underground [charing cross]]);
    add([[nelsons column] underground [charing cross]]);
    add([[the national gallery] underground [charing cross]]);
    add([[the serpentine lake] underground [marble arch]]);


define reply(list) -> response;

    ;;;
    ;;; Convert route list into English description of form:
    ;;;
    ;;;   travelling by underground, take the ... line to ...
    ;;;       then change and take the ... line to ...
    ;;;       then change and take the ... line to ...
    ;;;                             ...
    ;;;

    vars line, station, line1, response;

    list --> [[[?line ??station] ==] ??list];
    [travelling by underground, take the ^line line to]
                                                -> response;
    while list matches [[[?line1 ??station] ==] ??list] do
        if line1 /= line then
            [^^response ^^station then change and
                take the ^line1 line to] -> response;
            line1 -> line;
        endif;
    endwhile;
    [^^response ^^station] -> response;
enddefine;

define answer(question) -> response;
    vars meaning destination routelist;

       ;;; parse and semantically analyse sentence
    S(question) -> meaning;

    if meaning then
        if which("destination", meaning) matches
                                [?destination ==] then
            route([victoria], destination) -> routelist;
            if not(routelist) then
                [route not found] -> response
            else
                reply(routelist) -> response
            endif
        else
            [I do not know where that place is] -> response;
        endif;
    else

        ;;; cannot handle this question

        [Sorry I do not understand.
            Try rewording your question] -> response

    endif;
enddefine;

define S(list) -> meaning;
    vars np sym;
    if list matches [how do i get to ??np:NP] or
       list matches
             [can you tell me how to get to ??np:NP]
    then
        if np matches [[= ?sym isa =] ==] then
            ;;; meaning of noun-phrase is
            ;;; a list of patterns
            [ [? ^sym underground ? destination] ^^np ]
                                             -> meaning
        else
            ;;; meaning of noun-phrase is a proper name
            [ [^np underground ? destination] ]
                                             -> meaning
        endif
    else
        ;;; unknown sentence form
        false -> meaning
    endif;
enddefine;


define NP(list) -> meaning;
    vars pn d n p np sym1 sym2;
    if list matches [??pn:PROPN] then
        pn -> meaning
    elseif list matches [?d:DET ??n:NOUN]  then
        gensym("v") -> sym1;
        [ [ ? ^sym1 isa ^n] ] -> meaning
    elseif list matches [?d:DET ??n:NOUN ?p:PREP ??np:NP]
       then
        gensym("v") -> sym1;
        if np matches [[= ?sym2 isa =] ==] then
            ;;; meaning of noun-phrase is
            ;;; a list of patterns
            [ [? ^sym1 isa ^n] [? ^sym1 ^p ? ^sym2] ^^np]
                                            -> meaning
        else
            ;;; meaning of noun-phrase is proper name
            [ [? ^sym1 isa ^n] [? ^sym1 ^p ^np] ]
                                            -> meaning
        endif;
    else
        ;;; unknown noun-phrase form
        false -> meaning
    endif;
enddefine;

define NOUN(list) -> found;
    member(list, [[gallery] [square] [monument] [lake]
                  [park]]) -> found;
enddefine;

define PROPN(list) -> found;
    member(list,
        [[trafalgar square] [the national gallery]
         [nelsons column] [hyde park]
         [the serpentine lake] [the tate gallery]
        ] ) -> found;
enddefine;

define DET(word) -> found;
    member(word, [a the]) -> found;
enddefine;

define PREP(word) -> found;
    member(word, [in containing]) -> found
enddefine;

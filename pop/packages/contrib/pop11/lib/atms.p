/*

<<<<<<<  atms.p: An implementation of de Kleer's Assumption-based TMS  >>>>>>>
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  Roger Sinnhuber  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  and Jasper Taylor  >>>>>>>>>>>>>>>>>>>>>>>>>>>>

Copywrite University of Sussex (@(#)atms.p Version 2.0 10/3/92)


Important Data structures:

`node' is a record of 3 fields:
    `datum'             - string identifying node
    `label'             - List of environments (bit vectors)
    `justifications'    - List of lists of node names
    `affects'           - List of nodes with justifications including this


`nogoods'       - list of no good environments
`#'             - the special node falsity
`nodes'         - vector of node names
`atms'          - Set to true the ATMS is loaded
`atmsversion'   - version number of the ATMS
*/

recordclass node datum label justifications affects;
vars nogoods # nodes add_label;

constant atms atmsversion;
'2.0' -> atmsversion;


/*
checkname: make sure a new name is not already in use as a node name
*/
define checkname (name);
    lvars a_name name;
    for a_name in nodes using_subscriptor subscrv do
        if name == a_name
        then mishap ('The name "' >< name >< '" is already in use.', []);
        endif;
    endfor;
enddefine;


/*
newnode: create a new node (with no initial justifications)
*/
define newnode (name);
    lvars name;
    checkname (name);  ;;; mishaps if name already in use
    [vars ^name;] .popval;
    consnode (name, [], [], []) -> valof (name);
    nodes <> {^name} -> nodes;
enddefine;


/*
newnodes: create several new nodes named in list `names'
*/
define newnodes (names);
    lvars name names;
    for name in names do
        newnode (name)
    endfor;
enddefine;


/*
newpremise: create a new premise (with no initial justifications)
*/
define newpremise (name);
    lvars name;
    checkname (name);  ;;; mishaps if name already in use
    [vars ^name;] .popval;
    consnode (name, [0], [[]], []) -> valof (name);
    nodes <> {^name} -> nodes;
enddefine;


/*
newpremises: create several new premises named in list `names'
*/
define newpremises (names);
    lvars name names;
    for name in names do
        newpremise (name)
    endfor;
enddefine;


/*
newassumption: create a new assumption.
*/
define newassumption (name);
    lvars name;
    checkname (name);  ;;; mishaps if name already in use
    [vars ^name;] .popval;
    consnode (name, [% 2 ** nodes.length %], [[^name]], []) -> valof (name);
    nodes <> {^name} -> nodes;
enddefine;


/*
newassumptions: create several new assumptions named in list `names'
*/
define newassumptions (names);
    lvars name names;
    for name in names do
        newassumption (name)
    endfor;
enddefine;


/*
initialise: initial setup, can be used to re-initialise state of ATMS
*/
define initialise();
    consnode ("#", [], [], []) -> #;  ;;; special node: falsity
    [] -> nogoods;
    {} -> nodes;
enddefine;
initialise();

/*
issuperset: is environment (`env1') a super set of any environment in the list
of environments (`list')
*/
define issuperset (env1, list);
    lvars env1 env2 list;
    for env2 in list do
        if (env2 &&~~ env1) == 0  ;;; is env1 a superset of env2
        then return (true);
        endif;
    endfor;
    return (false);
enddefine;


/*
rm_envs: remove environments `envs' from a vector of node names `names'
*/
define rm_envs (envs, names);
    lvars env name n envs names;
    for name in names using_subscriptor subscrv do
        name.valof -> n;
        [% for env in n.label do
                 unless issuperset (env, envs) then env endunless
             endfor %] -> n.label;
    endfor;
enddefine;

/*
rm_supersets: remove superset env's from old and new parts of label
    (new part is first element of old part). If identical envs are
    present in new and old labels, it will be removed from new. This
    assumes there are no supersets in the old label.
*/
define rm_supersets (oldnew, oldold) -> newnew -> newold;
    lvars label1 label2 label3 oldlabel newlabel env;
    [] ->> newnew -> newold;
    while (oldnew /= []) do
        dest (oldnew) -> oldnew -> env;
        unless issuperset (env, oldnew <> oldold <> newnew)
        then env :: newnew -> newnew;
        endunless;
    endwhile;
    while (oldold /= []) do
        dest (oldold) -> oldold -> env;
        unless issuperset (env, newnew)
        then env :: newold -> newold;
        endunless;
    endwhile;
enddefine;

/*
mix_labels: combines labels from two nodes
*/
define mix_labels(label1, label2) -> compound;
lvars env1 env2 env3 label1 label2 compound spare;
    rm_supersets(
        [% for env1 in label1 do
            for env2 in label2 do
                env1 || env2 -> env3;
                unless issuperset(env3, nogoods) then env3;
                endunless;
            endfor;
        endfor %], []) -> compound -> spare;
enddefine;


/*
sublabelof: find the label of a single justification `j'
*/
define sublabelof (j);
    lvars env1 env2 j label1 label2;
    if j == [] then /* it's universally justified */
        [0]
    elseif (j.dest -> j, .valof.label -> label1; j == []) then /* 1 term j */
        label1
    else /* multi-term justification j */
        sublabelof (j) -> label2;
        mix_labels(label1, label2);
    endif;
enddefine;

/*
rm_nogoods: remove nogood environments from a label (list of environments)
*/
define rm_nogoods (label) -> label;
    lvars env label;
    [%   for env in label do
             unless issuperset (env, nogoods) then env endunless;
         endfor %] -> label;
enddefine;

/*
join_label: takes extra label that has been found for a node and
continues the process
*/
define join_label(nlabel, snode);
lvars nlabel snode remlabel xlabel nnode;
    rm_supersets(nlabel, snode.label) -> xlabel -> remlabel;
    unless xlabel = [] then
        xlabel <> remlabel -> snode.label;
        if snode = # then
            snode.label -> nogoods;
            rm_envs(xlabel, nodes)
        else
            for nnode in snode.affects do
                add_label(xlabel, snode, nnode);
            endfor;
        endif;
    endunless;
enddefine;

/*
takefrom: removes an item from a list
*/
define takefrom(item1, list1) -> list2 -> found;
lvars item1 list1 item2 list2 plist1 plist2 found;
    found = list1 matches [??plist1 ^item1 ??plist2];
    plist1 <> plist2 -> list2;
enddefine;

/*
add_label: updates the label of a node affected by an addition to
    the label of another node
*/
define add_label(alabel, snode, dnode);
lvars alabel snode dnode just sjust slabel nlabel env;
    [] -> nlabel;
    for just in dnode.justifications do
        if takefrom(snode, just) -> sjust then
            sublabelof(sjust) -> slabel;
            mix_labels(slabel, alabel) <> nlabel -> nlabel;
        endif;
    endfor;
    join_label(nlabel, dnode);
enddefine;

/*
add_just: Adds a new justification to a node.
*/
define add_just(j, node);
lvars j node node2 xlabel;
    j :: node.justifications -> node.justifications;
    for node2 in j do
        unless member(node, node2.valof.affects) then
            node :: node2.valof.affects -> node2.valof.affects
        endunless;
    endfor;
    sublabelof(j) -> xlabel;
    join_label(xlabel, node);
enddefine;

/*
>>>  operator to add a new justification to a node and propagate
the consequences, (read as "implies")
*/
define 8 >>> (j, n);  /* j implies n */
    lvars j n node;
    if j.isnode then [% j.datum %] -> j endif;  /* put into standard form */
    if n.isnode then [% n.datum %] -> n endif;
    for node in n do
        node.valof -> node;
        add_just(j, node);
    endfor;
enddefine;


/*
envof: get a list containing the numerical version of a list of
nodes: a one environment label.
*/
define envof (alist);
    lvars i env alist;
    0 -> env;
    for i to length (nodes) do
        if member (nodes(i), alist) then env + 2**(i-1) -> env endif;
    endfor;
    if env == 0 then return([]) else return ([^env]) endif;
enddefine;


/*
impliedby: what, if anything, is implied by belief in a the nodes in `alist'.
Returns a list of node names, or if belief is impossible, an empty list.
*/
define impliedby (alist);
    lvars env n alist lab;
    envof (alist) .rm_nogoods -> lab;
    if lab == []
    then
        []
    else
        [%
             lab.hd -> env;
             for n in nodes using_subscriptor subscrv do
                 if issuperset (env, n.valof.label) then n endif;
             endfor;
             %];
    endif;
enddefine;

/*
mx: declare list of nodes as mutually exclusive
Could be made faster if recording of justifications of `#' is not required
*/
define mx (list);
    lvars n1 n2;
    while list /== [] do
        dest (list) -> list -> n1;
        for n2 in list do
            [%n1, n2%] >>> #
        endfor;
    endwhile;
enddefine;


/*
incom: node `n1' is incompatible with all nodes in `list'
*/
define incom (n1, list);
    lvars n1 n2 list;
    n1.datum -> n1;
    for n2 in list do
        [%n1, n2%] >>> #
    endfor;
enddefine;


/*
absent: declare each of a list of nodes to be absent (each one is no good)
*/
define absent (list);
    lvars list n;
    for n in list do
        [^n] >>> #;
    endfor;
enddefine;


/*
prenv: print environment (integer) `env' in readable form using
node names
*/
define prenv (env);
    lvars env i first;
    true -> first;
    pr ('{');
    for i to length (nodes) do
        if (env // 2 -> env) == 1 then
            unless first then pr (',') endunless;
            false -> first;
            pr ( nodes(i) )
        endif;
    endfor;
    pr ('}');
enddefine;


/*
prlabel: print a label (list of numbers) in readable form, ie as sets
of node names.
*/
define prlabel (label);
    lvars label env first;
    true -> first;
    pr ('{');
    for env in label do
        unless first then pr (',') endunless;
        false -> first;
        prenv (env);
    endfor;
    pr ('}');
enddefine;


/*
prjust: print a justification `j' in readable form using de Kleer's notation
*/
define prjust (j);
    lvars j item first;
    true -> first;
    pr ('(');
    for item in j do
        unless first then pr (',') endunless;
        false -> first;
        pr (item);
    endfor;
    pr (')');
enddefine;


/*
prjusts: print a list of justifications `js' using de Kleer's notation
*/
define prjusts (js);
    lvars j js first;
    true -> first;
    pr ('{');
    for j in js do
        unless first then pr (',') endunless;
        false -> first;
        prjust (j);
    endfor;
    pr ('}');
enddefine;


/*
prnode: print out a node using de Kleer's notation.
*/
define prnode (n); ;;; print a node `n' in readable form
    lvars n;
    unless n.isnode then n.valof -> n endunless;
    pr ('<' >< n.datum >< ',');
    prlabel (n.label);
    pr (',');
    prjusts (n.justifications);
    pr ('>');
enddefine;
;;; make `prnode' the default print routine for nodes
prnode -> class_print (datakey (consnode (false, [], [], [])));


/*
prnodes: print out the nodes in vector `nodes'
*/
define prnodes (nodes);
    lvars n nodes;
    for n in nodes using_subscriptor subscrv do
        prnode (n);
        nl (1);
    endfor;
enddefine;


/*
prstate: print out the state of the ATMS
*/
define prstate();
    prnodes (nodes);
    pr ('nogoods = ');
    prlabel (nogoods);
    nl (1);
enddefine;


true -> atms;  ;;; ATMS ready

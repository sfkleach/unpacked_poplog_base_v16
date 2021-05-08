/*
The demonstration of Roger Sinnhuber's implementation of de Kleer's ATMS
*/

uses atms;

initialise();
newassumptions([A B C D E F]);
newnodes ([a b c d e f]);
A >>> a; B >>> b; C >>> c; D >>> d; E >>> e; F >>> f;
newnodes ([xy1 x1 y0]);
[a b e] >>> #;
[a b] >>> xy1;
[b c d] >>> xy1;
[a c] >>> x1;
[d e] >>> x1;
/* incom (F, [A B C D E]);
The above makes a nogood of each pair of F and one other */
/* mx([C D E]);
The above makes a nogood of each pair of beliefs in the list */
/* absent([C F]);
This merely removed the self-justification from the nodes and
added them to the NOGOODS */
pr ('\nOriginal state:\n');
prstate();

define macro show; ;;; show state of the ATMS
    pr ('\nCurrent State:\n');
    prstate();
enddefine;
[xy1 x1] >>> y0;
show;
impliedby([A B D]) =>

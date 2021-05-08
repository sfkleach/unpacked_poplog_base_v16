
/*  --- Copyright University of Sussex 1986.  All rights reserved. ---------
 *  File:           $usepop/master/C.all/lib/lib/elizaprog.p
 *  Purpose:        Sussex Mini ELIZA programme
 *  Author:         Mostly A.Sloman 1978 (see revisions)
 *  Documentation:  TEACH * ELIZA
 *  Related Files:  LIB * ELIZA and the saved image.
 */

;;; the function changeperson is called before any tests are carried out,
;;; so that "you" always refers to the user, "I" to the computer, etc.,
;;; in the transformed sentence, which is then analysed by other procedures
;;; trying to react to it.
;;; The variable "sentence" is local to eliza, and used non-
;;; locally by other procedures. Thus, general purpose matching procedures
;;; can be defined which simply take a pattern as argument. Examples are
;;; the procedures:  itmatches, itcontains, ithasoneof, itslikeoneof,
;;;   and itsaquestion,
;;; which are used by lots of other procedures to test the current sentence.
;;; occasions.

true -> popconstruct;

uses random;
pr('Please wait, Eliza takes a minute or two to get ready\n');

vars inchar;   ;;; reassigned in eliza.

vars eliza;

define Bye();
   unless interrupt == sysexit then setpop -> interrupt endunless;
   pr('Bye for now.\n');
   exitfrom(eliza);
enddefine;

define delete(item,list);
	if member(item,list) then
		if item = hd(list) then
			delete(item,tl(list))
		else
			hd(list) :: delete(item,tl(list))
		endif
	else
		list
	endif
enddefine;

vars sentence;

;;; a table, and some procedures for transforming the input sentence
;;; so that "I" becomes "you", etc. A minor problem is coping with
;;; "are". "you are" should become "i am", whereas in "we are", "they are"
;;; "are" should be left unaltered.
;;; a further difficulty is deciding whether "you" should become "I" or "me".
;;; This program uses the simple test that I at the end of the sentence is
;;; unacceptable.
;;; The transformation goes in three stages.
;;;   first find second person occurrences of "are" and mark them.
;;;   then transform according to the table below,
;;;   then replace final "I" with "me".

vars wordtable;
   [[i you]
   [you i]
   [my your]
   [yourself myself]
   [myself yourself]
   [your my]
   [me you]
   [mine yours]
   [yours mine]
   [am are]
   [Are am]
   [id you had]
   [youd i had]
   [theyre they are]
   [youre  i am]
   [im you are]
   [we you]    ;;; not always safe!
   [ive you have]
   [doesnt does not]
   [youve i have]
   [isnt is not]
   [arent are not]
   [dont do not]
   [werent were not]
   [mustnt must not]
   [shouldnt should not]
   [wouldnt would not]
   [shant shall not]
   [cant cannot]
   [couldnt could not]
   [wont will not]
   ]  -> wordtable;

define lookup(word, table);
	;;; Return the original word if there isn't an entry in the table.
	if table == [] then
		word
	elseif word == hd(hd(table)) then
		dl(tl(hd(table)))
	else
		lookup(word, tl(table))
	endif
enddefine;

vars itcontains itmatches itslikeoneof;      ;;; defined below: used in changeperson.

define changeperson(sentence) => sentence;
	vars L1 L2;
	;;; first distinguish second person versions of "are"
	if not(itcontains("you")) then
		sentence
	elseif itmatches([??L1 you are ??L2]) then
		[^^L1 you Are ^^L2]
	elseif itmatches([??L1 are you ??L2]) then
		[^^L1 Are you ^^L2]
	else
		sentence
	endif
		-> sentence;

	;;; now transform according to wordtable, defined above.
	maplist(sentence, lookup(%wordtable%)) -> sentence;

	;;; Now change "I" at the end to "me".
	if itmatches([??L1 i]) then [^^L1 me] ->sentence endif;
	while itmatches([??L1 .]) do L1 ->sentence endwhile;
enddefine;

;;;   ****  READING IN A SENTENCE    ****

;;; The function readsentence below is derived from the library program readline.
;;; it ignores string quotes, e.g. as typed in "don't", "isn't", etc.
;;; it also asks you to type something if you type a blank line.
;;; It uses function changeperson to transform the sentence.
;;; It also strips off "well" and other redundant leading words.
;;; finally it checks if you wish to restore normal error handling (which is
;;;   switched off in eliza) or wish to stop.


vars cucharin; charin -> cucharin;     ;;; used in readsentence
				  ;;; re-assigned in Eliza


vars Uptolow;
`a` - `A` -> Uptolow;   ;;; Used in function lowercase.

define lowercase char => char;
	;;; Used to transform upper to lower case in function readsentence.
	if `A` <= char and char <= `Z` then char + Uptolow -> char endif
enddefine;



vars gtrl getline ithasoneof; ;;; defined below

define readsentence()->sentence;
	vars proglist item char sentenceread popprompt;
	define repeater();
		cucharin() -> char;
		while char == 0 or char == `'` do cucharin() -> char endwhile;
		if char == `\n` then
			termin
		elseif char == termin then
			Bye()
		elseif char == `;` or char == `.` then
			` `      ;;; return space character.
		else
			lowercase(char)
		endif
	enddefine;
	pdtolist(incharitem(repeater)) -> proglist;
	false -> sentenceread;
	'? ' -> popprompt;
	until sentenceread do
		[%until (readitem() -> item, item == termin) do item enduntil%]
			-> sentence;
		if sentence == [] then
			pr('please type something\n');
		pdtolist(incharitem(repeater)) -> proglist;
		else
			true -> sentenceread
		endif
	enduntil;

	;;; get rid of "well"  and similar redundant starting words
	while length(sentence) >  1
		and member(hd(sentence),[well but however and then also yes no ,])
	do
		tl(sentence) -> sentence;
	endwhile;

	changeperson(sentence) -> sentence;
	unless ithasoneof([? ??]) then
		if sentence = [debug] then
			pr('changing prmishap\n');
			sysprmishap -> prmishap;
			setpop -> interrupt;
			readsentence() -> sentence;
		elseif itslikeoneof([[newrule][new rule]]) then
			gtrl();         ;;; user defines new rule
			getline('Please type something now\n') -> sentence
		elseif itslikeoneof([[pop] [pop11]]) then
			setpop()
		elseif itslikeoneof([[bye][good bye][goodbye]]) then
			Bye()
		endif
	endunless
enddefine;

define getline(mess);
	;;; Used in gtrl - reads in a line, translating "i" to "you", etc.
	;;; Hence uses readsentence, not readline
	ppr(mess);
	readsentence()
enddefine;

vars rules;

define gtrl;
	;;; I.e. GeTRuLe.
	;;; added 19 sept 1979
	;;; enables user to define a new rule interactively, by
	;;; typing NEWRULE or NEW RULE to eliza.
	;;; produces a dialogue, which results in a new rule.
	define interrupt;
		setpop -> interrupt;
		pr('abandoning new rule');
		exitfrom(gtrl)
	enddefine;
	vars input response Name gtrl list;
	until length(getline('Please type name of new rule\n') ->> Name) == 1 do
		pr('One word please\n')
	enduntil;
	hd(Name) -> Name;
	;;;make sure the name doesn't clash with anything in the system
	consword('-' >< Name) -> Name;
	if member(Name,rules) then
		ppr(['redefining rule called: ' ^Name ^newline])
	endif;
	getline('what sort of input should trigger the rule?\n') -> input;
	;;; remove trailing "?"
	if hd(rev(input)) = "?" then rev(tl(rev(input))) -> input endif;
	input -> list;
	;;; find the pattern variables
	[%until  atom(list) do
		if member(hd(list),[? ??]) then
			dest(tl(list)) -> list;
		else
			tl(list) -> list
		endif
	  enduntil%]
		-> list;
	;;; list now contains all variables which need to be declared as local
	;;; in the new rule.
	(if input(1) == "??" then [] else [==] endif) <> input
		<>  (if length(input) > 1 and input(length(input) - 1) == "??"
					then [] else [==] endif)
		 -> input;
	;;; input now has [==] or a variable at both ends.
	getline('How should I respond to input containing that pattern\n')
		-> response;
	changeperson(response) -> response;
	;;; it will have been changed inside readsentence - change it back.
	[newrule ^Name ;
		vars ^^list;
		if itmatches(^input) then % "[", dl(response), "]" % endif
	 endnewrule;]
		-> Name;
	popval(Name);
	pr('thank you - new rule defined\n')
enddefine;

;;;   **** CIRCULATING LISTS OF POSSIBILITIES ****

;;; The next function is used to get the first element of a list, then
;;; put it on the end of the list, so that next time a different element
;;; will be the first one. This enables a stock of standard replies to
;;; be used in certain contexts without it being too obvious.
;;; an alternative would be to use function oneof, but it cannot be
;;; relied on not to be repetitive!

define firstolast(list);
	;;; use original list links, to minimise garbage collection.
	vars L1 prev,first;
	hd(list) -> first;
	list -> L1;
	tl(list) ->> list ->prev;
	[] -> tl(L1);
	until tl(prev) == [] do tl(prev) ->prev enduntil;
	L1 ->tl(prev);
	first,list
enddefine;

;;;   ***** A COLLECTION OF MATCHING AND RECOGNISING FUNCTIONS   ****

define itmatches(L);
	;;; use capital L to prevent clash of variables inside match.
	match(L,sentence)
enddefine;

define itcontains(x);
	if atom(x) then
		member(x,sentence)
	else
		match([== ^^x ==], sentence)
	endif
enddefine;

;;; the function ithasoneof takes a list of words or patterns and checks whether
;;; the current sentence contains one of them

define ithasoneof(L);
	if L ==[] then
		false
	else
		itcontains(hd(L)) or ithasoneof(tl(L))
	endif
enddefine;

define itslikeoneof(L);
	until atom(L) do
		if match(dest(L) -> L, sentence) then return(true) endif
	enduntil;
	false
enddefine;

;;;   ****  RULES FOR REACTING TO THE SENTENCE ****

;;; First we define a macro called newrule.
;;; It works exactly like "function", i.e. it defines a function.
;;; The only difference is that it makes sure the name of the function is
;;; added to the global list rules.
;;; This list of function names is repeatedly shuffled by eliza and then the
;;; corresponding functions tried in order, to see if one of them can
;;; produce a response to the sentence.
;;; If it produces a response other than false, then the response will be
;;; used in replyto. If there is no response then the result of the function TRY
;;; defined below, will be false, so replyto will try something else.

[] -> rules;

define macro newrule;
	vars name x;
	readitem() -> name;
	if identprops(name) = "syntax" then
		mishap(name,1,'missing name in newrule')
	endif;
	itemread() -> x;
	if x = "(" then
		erase(itemread())
	elseif x /= ";" then
		mishap(x, 1, 'bad syntax in newrule')
	endif;
	unless member(name, rules) then name :: rules -> rules endunless;
	"define", name, "(", ")", ";"
enddefine;

define macro endnewrule;
	"enddefine"
enddefine;

vars problem newproblem;
   ;;; used to remember something said earlier,
   ;;; to be repeated when short of something to say
   ;;; Altered in some of the rules, below.

newrule need;
	if ithasoneof([want need desire crave love like]) then
		oneof(['beware of addictions' 'can you do without?'
					'do you ever suffer from withdrawal symptoms?'])
	endif
endnewrule;

newrule money;
	if ithasoneof([money cash broke grant rent pay job cost]) then
		oneof(['Have you talked to Margaret Thatcher about that?'
				'What do you think about monetarist policies?'
				'Why not consult an accountant?'
				'If you had more money you could buy a computer'
				'Computing can make you rich'
				'All except the very rich have financial problems nowadays'
				'Are you an economist?'])
	endif
endnewrule;

newrule think;
	vars L1;
	if itmatches([== i think ==]) or itcontains("eliza") or itcontains("myself")
	then
		oneof(['we were discussing you not me' 'I\'d rather talk about you'])
	elseif itmatches([you think ??L1]) then
		oneof([['why do you think' ^^L1 ?]['does anyone else think' ^^L1 ?]
			['I am not sure I agree that' ^^L1]])
	endif;
	sentence -> newproblem;
endnewrule;

newrule you;
	vars L1;
	if itmatches([your ??L1]) then
		['do you know anyone else whose' ^^L1 ?]
	elseif random(100) < 25 and ithasoneof([you your myself my]) then
		oneof(['does anyone else have that problem'
				'Are you using yourself as a scape-goat?'
					'do you think you are unique?'])
	endif
endnewrule;

vars questionlist;
   ['perhaps you already know the answer to that?'
   'is that question important to you?'
   'first tell me why you have come here?'
   'have you ever asked anyone else?'
   'why exactly do you ask?'
   'is that question rhetorical?'
   'do you really want to know?'
   'why are you talking to me about that?'
   'what makes you think I know the answer?'
   'why do people ask so many questions?'
   'tell me something about your personal life'
   'I can\'t help if you ask too many questions'
   'perhaps you ask questions to cover something up?'] ->questionlist;

define itsaquestion;
   if member(hd(sentence), [did do does were will would could
								is are am should shall can cannot
								which why where who what when how])
		or hd(rev(sentence)) == "?"
   then
		firstolast(questionlist) -> questionlist;
		;;; leaves first element of questionlist on the stack.
   else
		false
	endif
endnewrule;

newrule question;
	if random(10) < 8 then itsaquestion() endif;
endnewrule;

newrule family;
	if ithasoneof([mother father brother sister daughter wife
										husband son aunt uncle cousin])
	then
		oneof(['tell me more about your family'
				'do you approve of large families?'
				'family life is full of tensions'
					'do you like your relatives?'])
	endif
endnewrule;

vars shortlist;
   ['you are being somewhat short with me'
   'perhaps you dont feel very talkative today?'
   'could you be more informative?'
   'are you prepared to elaborate?'
   'why are you so unforthcoming?'
   'I dont think you really trust me'
   'to help you, I need more information'
   'please dont get upset, I\'m sorry I said that'
   'what is your real problem?'
   'you are very privileged to talk to me'
   'why are you here?'
   'you dont like me do you?'
   'this is ridiculous'
   'well?'] ->shortlist;

newrule short;
	if length(sentence) < 3 and not(itsaquestion()) then
		firstolast(shortlist) -> shortlist;
	endif
endnewrule;

newrule because;
	if itcontains("because") then
		oneof(['is that the real reason?'
			   'Could there be any other reason?'
				'Perhaps the real reason is hard to talk about?'])
	endif
endnewrule;

newrule to_;
	vars L1;
	if itmatches([to ??L1]) then
		[^(oneof(['how would you like to' 'do you think I want to'
			'could a machine'
			'would a normal person want to'])) ^^L1 ?]
	endif
endnewrule;

newrule suppnot;
	vars L1 L2 sentence;
	if hd(sentence) == "because" then
		if random(10) < 4 then return endif;
		tl(sentence) ->sentence
	endif;
	;;; That prevents some awkwardness in replies.

	if itsaquestion() or random(100) < 40 then
		false
	elseif itslikeoneof([[??L1 is not ??L2]
									[??L1 are not ??L2] [??L1 am not ??L2]])
	then
		oneof([[suppose ^^L1 were ^^L2]
				['Can you always expect' ^^L1 to be ^^L2 ?]])
	elseif random(100) > 30 and itmatches([you are ??L1]) then
		oneof([['how does it feel to be' ^^L1 ?]
					  ['are you sure you really are' ^^L1 ?]
					  ['is this the first time you\'ve been' ^^L1 ?]
					  ['does anyone else know you are' ^^L1?]
					  'is that connected with your reason for talking to me?'
					  ['would you prefer not to be' ^^L1 ?]
					  'do you know anyone else who is?'])
	elseif itslikeoneof([[??L1 is ??L2] [??L1 are ??L2] [??L1 am ??L2]]) then
		oneof([[suppose ^^L1 'were not' ^^L2] [sometimes ^^L1 aint ^^L2]
				['are you' ^^L2] [what if I were ^^L2]])
	elseif itslikeoneof([[??L1 can ??L2] [??L1 could ??L2]]) then
		[suppose ^^L1 'couldn\'t' ^^L2]
	elseif itslikeoneof([[??L1 do not ??L2] [??L1 does not ??L2]]) then
		oneof([[suppose ^^L1 did ^^L2] ['Perhaps you really' ^^L2]])
	elseif itslikeoneof([[??L1 do ??L2] [??L1 does ??L2]]) then
		oneof([[suppose ^^L1 did not ^^L2]['Perhaps you really don\'t' ^^L2]])
	elseif itmatches([??L1 did not ??L2]) then
		[suppose ^^L1 had ^^L2?]
	elseif itmatches([??L1 did ??L2]) then
		oneof([[suppose ^^L1 had not ^^L2 ?] ['did' ^^L1 'always ?']])
	endif
endnewrule;

vars complist;
['do machines worry you?'
'how would you react if machines took over?'
'most computers are as stupid as their programmers'
'Do you like talking to computers?'
'Can computers really think?'
'How can schools improve attitudes to computers?'
'what do you really think of computers?'] -> complist;

newrule computer;
	if ithasoneof([micro eliza vax program computer computers machine machines robots]) then
		firstolast(complist) -> complist
	endif
endnewrule;

newrule emphatic;
	if random(100) < 40 then
		if itmatches([== of course == ]) then
			'would everyone find that obvious?'
		elseif ithasoneof([indeed very extremely])
			and not(itsaquestion())
			and random(100) > 50
		then
			'are you sure you are not being dogmatic?'
		endif
	endif
endnewrule;

newrule sayitback;
	if random(100) < 6 and not(itsaquestion()) then sentence endif
endnewrule;

newrule youarenot;
	if itmatches([you are not ??list]) then
		oneof([['would you be happier if you were' ^^list]
			['Perhaps you are lucky not to be' ^^list]])
	endif
endnewrule;

newrule notsomething;
	if itmatches([not ??list]) then
		oneof([['why not' ^^list]
				['Do you have negative feelings about' ^^list]])
	endif
endnewrule;

vars earlycount;

newrule earlier;
	if random(100) < 12 and earlycount > 10 then
		oneof(['earlier you said'
				 'I recall your saying'
				 'what did you mean by saying'])
		:: if hd(problem)=="because" then tl(problem) else problem endif;
		newproblem -> problem;
		1 -> earlycount;
		sentence -> newproblem
	endif
endnewrule;

newrule every;
	vars list sentence;
	if itmatches([because ??list]) then
		list -> sentence
	endif;
	if itslikeoneof([[everybody ??list][everyone ??list]]) then
		'who in particular' :: list
	elseif ithasoneof([everyone everybody]) then
		'anyone in particular?'
	elseif itmatches([nobody ??list]) then
		'are you sure there isnt anyone who' :: list
	elseif itcontains("every") then
		'can you be more specific?'
	elseif itslikeoneof([[== someone ==] [== somebody ==]
									[== some one ==] [== some people ==]
									[== some men ==] [== some women ==]])
	then
		'who in particular?'
	elseif itcontains("some") then
		'what in particular?'
	elseif itcontains("everything") then
		'anything in particular?'
	endif;
endnewrule;

newrule mood;
	if ithasoneof([ suffer advice depressed miserable sad
							guilt guilty unhappy lonely confused ill unwell])
	then
		oneof(['do you think the health centre might be able to help?'
				'machines can make people happier'
				'maybe things will get better'
				'think how much worse things might be'
				'everyone feels guilty about something'])
	elseif ithasoneof([happy happier enjoy enjoyment
							joy pleasure pleased delighted])
	then
		oneof(['do you think pleasures should be shared?'
				'Can machines be happy?'
				'What makes you happy?'])
	elseif ithasoneof([like feel hate love hates loves]) then
		'do strong feelings disturb you?'
	endif
endnewrule;

newrule fantasy;
	vars list;
	if itslikeoneof([[you are ??list me] [i am ??list you]]) then
		oneof([['perhaps in your fantasy we are' ^^list 'each other?']
						['do you think we should be' ^^list 'each other?']
						['do you know many people who are' ^^list 'each other?']])
	elseif itslikeoneof([[you ??list me][i ??list you]]) then
		oneof([['perhaps in your fantasy we' ^^list 'each other?']
						['do you think its wrong for people to' ^^list 'each other?']
						'do you think our relationship is too complicated?'
						['is it good that people should' ^^list 'each other?']])
	endif
endnewrule;

newrule health;
	if itcontains([health centre])
			or itcontains([health center])
			or ithasoneof([ill sick medicine drugs drug doctor psychiatrist therapist therapy])
	then
		oneof(['do you think doctors are helpful?' 'do you trust doctors?'])
	elseif ithasoneof([smoke smokes smoking smoker smokers
												cigarette cigarettes ])
	then
		'smoking can damage your health'
	elseif ithasoneof([drink drinks pub booze beer]) then
		oneof(['drinking damages brain cells' 'machines dont often get drunk'])
	endif
endnewrule;

newrule should;
	vars L1 L2 sentence;
	if member(hd(sentence),[because then so]) then
		tl(sentence) -> sentence
	elseif itsaquestion() then
		return
	endif;
	if itmatches([??L1 should not ??L2]) then
		['why shouldnt' ^^L1 ^^L2 ?]
	elseif itmatches([??L1 should ??L2]) then
		['why should' ^^L1 ^^L2?]
	elseif itmatches([??L1 would ??L2]) and random(100) <50 then
		[would ^^L1 really ^^L2]
	endif
endnewrule;

newrule looks;
	if ithasoneof([seems seem appears looks apparently]) then
		'appearances can be deceptive'
	endif
endnewrule;

newrule unsure;
	if ithasoneof([perhaps maybe probably possibly]) then
		'you dont sound very certain about that'
	endif
endnewrule;

vars lengthlist;
['did you really expect me to understand that?'
'could you rephrase that please'
'my, that sounded impressive'
'could you express that more simply please?'
'hmmm'
] -> lengthlist;

newrule toolong;
	vars wd;
	if length(sentence) > 10 then
		firstolast(lengthlist) -> lengthlist
	else
		vars longword;
		false -> longword;
		for wd in sentence do
			(isword(wd) and datalength(wd) > 10) -> longword
		endfor;
		if longword then
			oneof(['some people use long words to impress others'
						'do you like using long words?'
						'why do academics use jargon?'
						'why such long words?'])
		endif
	endif
endnewrule;

newrule givehelp;
	if ithasoneof([please help advise advice recommend helpful]) then
		oneof(['most people don\'t really listen to advice'
						'perhaps you need more help than you think?'
						'do you have friends who can help you?'
						'would you trust a machine to help?'])
	endif
endnewrule;

newrule mean;
	if ithasoneof([mean meaning means meant]) then
		'what do you mean by mean?'
	endif
endnewrule;

newrule verynasty;
	;;; occasionally use what is typed in to add to eliza's "associative memory"
	vars list name;
	define filter(sentence);
		;;; get rid of short words
		vars wd;
		[%for wd in sentence do
			if isword(wd) and datalength(wd) > 4 then wd endif
		  endfor%]
	enddefine;

	unless random(100) > 60 then
		filter(sentence) -> list;
		if random(1 + length(list)) >= 3 then
			;;; compile a new rule
			gensym("rule") -> name;
			popval([newrule ^name;
				if random(10) > 3 and ithasoneof(^list) and earlycount > 4 then
					'that reminds me,\n\tdidnt you previously'
						:: (^(if itsaquestion() then 'ask' else 'say' close)
														:: ^sentence);
					delete(" ^name ", rules) -> rules;
					;;; make sure the new rule is only used once.
				endif
				endnewrule;])
		endif
	endunless
endnewrule;

;;;   ****  THE CONTROLLING PROCEDURES   ****

uses shuffle;

;;; eliza, once called, retains control until you type CTRL-Z,
;;; or say "bye", "goodbye", etc.
;;; It redefines the function prmishap to ensure that the user never gets pop11
;;; error messages, but simply has a chance to try again.
;;; Since this can make debugging difficult, it can be undone inside readsentence, by typing debug.

;;; Eliza repeatedly calls the function readsentence and then asks the function
;;; replyto to try the rules to see if one of them produces a
;;; response (i.e. something other than false).

;;; However, the very first utterance by the user is treated differently.

vars level;
3 -> level;    ;;; controls recursion in replyto

vars desperatelist;
	  [
	  'Tell me more about yourself'
	  'do go on'
	  'what does that suggest to you?'
	  'what do you really think about me?'
	  'your problems may be too difficult for me to help'
	  'computer demonstrations often go wrong'
	  'Are you doing the computers and thought course?'
	  'have you discussed your problems previously?'
	  'do you really think I can help you?'
	  'Maybe you dont think a computer can really be your friend'
	  'How do you feel about the micro-revolution?'
	  'How can computers help people instead of threatening them?'
	  'Please explain so that a stupid computer can follow you'
	  'sorry I dont understand'
	  'this sort of discussion can lead to misunderstandings']-> desperatelist;


define desperateanswer();
	;;; used to produce a reply when all else fails
	firstolast(desperatelist) -> desperatelist;
	sentence -> newproblem;
enddefine;

define try(word);
	;;; this is used in replyto to see if executing the value of the word
	;;; leaves anything on the stack. If so it will be used as the answer.
	;;; if not, the answer is false
	vars sl;
	stacklength() ->sl;
	apply(valof(word));
	if stacklength() = sl then false endif
enddefine;

vars defines;

define replyto(sentence, rles);
	vars answer level l;
	rles -> l;     ;;; save for recursive call
	until rles == [] do
		if (try(hd(rles)) ->> answer) then
			return(answer)
		else
			tl(rles) -> rles
		endif
	enduntil;
	;;; got to end of functions. try again if level > 0
	if (level - 1 ->> level) > 0 then
		replyto(sentence,l)
	else
		desperateanswer()
	endif
enddefine;

define eliza();
	vars problem sentence answer inchar cucharin earlycount;
	if popheader then pr(popheader >< newline); false -> popheader endif;
	1 -> earlycount;
	Bye -> interrupt;
	(poppid + systime()) && 2:11111111 -> ranseed;
;;;   popmess(Cucharin) ->inchar;
	charin -> inchar;
	inchar -> cucharin;
   define prmishap x;
	  repeat stacklength() times
		 erase()
	  endrepeat;
	  pr('somethings gone wrong please try again\n');
	  readsentence();
   end;
	vars output; cucharout -> output;
	define cucharout(c);
		if c >= `a` and c <= `z` then c + `A` - `a` -> c endif;
		output(c);
	enddefine;
	pr('\n\nELIZA HERE!\n\n');
	pr('This program simulates a non-directive psychotherapist.\n');
	pr('It will appear to engage you in conversation about your problems.\n');
	pr('However, it doesn\'t really understand, as you will eventually discover.\n');
	pr('\nWhenever the computer prompts you with a question mark, thus:\n');
	pr('   ?\n');
	pr('you should type in a one line response.\n');
	pr('To correct mistakes use the "DEL" button.\n');
	pr('At the end of each of your responses, please press the RETURN button.\n');
	pr('When you have finished (or are cured?) type BYE and press the RETURN button.\n');
	pr('\n');
	pr('\nGood day what is your problem\n');
	readsentence() ->> problem -> sentence;
	while true do
		earlycount + 1 -> earlycount;
		ppr(replyto(sentence,shuffle(rules) ->> rules));
		pr(newline);
		readsentence() -> sentence;
	endwhile
enddefine;

/*  --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 28 1986 fixed author, tabified
--- A.Sloman Oct 1981 - modified for VAXPOP.  Newrule "verynasty"
	inserted to illustrate use of popval
--- Aaron Sloman, May 17 1978 - modified and expanded. Based on simple
	version by S.Hardy
 */

/*


        Computers and Thought: Chapter 2 - Performance without Knowledge

        A very simplified version of Weizenbaum's ELIZA program

        This is not the program that generated the dialogue on pages 34
        to 36 of Computers and Thought, but a much simplified version to
        show the basic structure of an Eliza-like program

*/

/*A typical interaction with the program:

        : converse();
        ** [This is mini - Eliza]
        ** [Tell me about yourself .]
        ** [Type : bye to stop]
        ? i hate people
        ** [Thats a very strong emotion]
        ? i feel strong emotions
        ** [What ?]
        ? i said i feel stong emotions
        ** [I would like to hear more about you]
        ? i am talking about myself
        ** [Are you talking about yourself ?]
        ? yes
        ** [Why do you think that ?]
        ? i think you do not understand me
        ** [We were talking about you not me]
        ? i am unhappy

*/
vars answer change_i_to_me  changeperson introduction longword contains_one_of;


/* MAIN PROCEDURE - the procecure CONVERSE  is the procedure to
 *  control the conversation. It prints out an intoduction and then
 *  repeatedly reads in a line of words typed by the user and calls
 *  the procedure ANSWER to give a reply */


    define converse();
        vars question;
       [This is mini-Eliza] =>
       [Tell me about yourself.]=>
       [Type: bye   to stop] =>
        repeat
           readline() -> question;
           quitif(question = [bye]);
           answer(question) =>
        endrepeat;
        [bye - have a nice day!!!]=>
    enddefine;


/* ANSWER is the procedure that does most of the work. It first calls
 * the procedure CONVERT which
 * converts the user's line of words into a standard form, by changing
 * all capital letters to small etc. It then calls the procedure CHANGEPERSON
 * to alter the sentence to the computer's point of view (changing "I" to
 * "you" etc. Then it deals with the special case of an "i" at the end
 * of a sentence. Next is a series of "if" statements. If the condition of
 * one of the "if" statements matches the sentence, then the sentence
 * is transformed and returned as the result of ANSWER
*/


    define answer(sentence)->response;
    vars x y;
       changeperson(sentence)->sentence;
       change_i_to_me(sentence)->sentence;
       if sentence matches [yes ==] then
            oneof([[You seem very positive]
                   [Are you really sure?]
                   [Why do you think that?]])->response
       elseif sentence matches [no ==] then
            oneof([[Arent you being a little negative?]
                   [Why not?]])->response
       elseif length(sentence)<3 then
            oneof([[You are being sometwhat short with me]
                   [Could you be more informative?]
                   [Please tell me some more]])->response
       elseif contains_one_of([mother father brother sister],sentence) then
            oneof([[Tell me more about your family]
                 [Do you feel the same way about anyone else in your family?]])->response
       elseif contains_one_of([computer machine computers],sentence) then
            oneof([[Do machines worry you?]
                  [Would you like to own a computer?]])->response
       elseif contains_one_of([Eliza eliza myself],sentence) then
            oneof([[We were talking about you not me]
                   [I would like to hear about you]])->response
       elseif contains_one_of([want need desire crave love],sentence) then
            oneof([[Beware of addictions]
                   [Can you do without?]
                   [Do you get withdrawal symptoms?]])->response
       elseif contains_one_of([indeed very extremely],sentence) then
            oneof([[Are you sure you are not being dogmatic]
                   [You seem very sure of yourself]])->response
       elseif contains_one_of([ suffer advice depressed miserable sad
               guilt guilty unhappy lonely confused ill unwell],sentence) then
          oneof([[Machines can make people happier]
                 [Maybe things will get better]
                 [Think how much worse things might be]
                 [Everyone feels guilty about something]])->response
        elseif contains_one_of([happy happier enjoy enjoyment joy pleasure
                    love pleased delighted],sentence) then
            oneof([[Do you think pleasures should be shared?]
                   [Can machines be happy?]
                   [What makes you happy?]])->response
        elseif contains_one_of([hate dislike detest],sentence) then
             oneof([[Do strong feelings disturb you?]
                    [Do you always feel this way?]
                    [Do you feel so strongly about anything else]
                    [Thats a very strong emotion]])->response
       elseif contains_one_of([because reason],sentence) then
            oneof([[Is that the real reason?]
                   [Could there be another reason?]
                   [Perhaps the real reason is hard to talk about?]])->response
       elseif sentence matches [??x is not ??y] or
              sentence matches [??x are not ??y] or
              sentence matches [??x am not ??y]  then
             oneof([[Suppose ^^x were ^^y]
                    [Can you always expect ^^x to be ^^y]])->response
       elseif sentence matches [to ??x] then
             oneof([[How would you like to ^^x ?]
                    [Could a machine ^^x ?]
                    [Do people really need to ^^x ?]])->response
       elseif sentence matches [why ==] or
              sentence matches [who ==] or
              sentence matches [what ==] or
              sentence matches [which ==] then
            oneof([[What do you think?]
                   [I think you know the answer]
                   [Do you think the answer will help you]])->response
       elseif sentence matches [== you ??x me ==] then
            oneof([[Why do you think you ^^x me?]
                   [Do you really ^^x me?]
                   [Perhaps we ^^x each other]])->response
       elseif sentence matches [== i ??x you ==] then
            oneof([[We were talking about you not me]
                   [Do you think I ^^x you?]
                   [Would it help if I said I ^^x you?]])->response
       elseif sentence matches [??x is ??y] or
              sentence matches [??x are ??y] or
              sentence matches [??x am ??y] then
            oneof([[Suppose ^^x were not ^^y]
                   [Are you ^^y ?]
                   [What if I were ^^y ?]])->response
       elseif sentence matches [??x can ??y] or
              sentence matches [??x could ?yy] then
            [What if ^^x couldnt ^^y]->response
       elseif longword(sentence) then
            oneof([[Some people use long words to impress others]
                   [Do you like using long words?]
                   [Why do academics use jargon?]
                   [Why such long words?]])->response
       else
            oneof([[Please go on]
                   [Please tell me about yourself]
                   [What?]
                   [I would like to hear more about you]])->response

       endif;
   enddefine;


;;; The procedure CHANGEPERSON is called before any tests are carried out,
;;; so that "you" always refers to the user, "I" to the computer, etc.,
;;; in the transformed sentence, which is then analysed by other procedures
;;; trying to react to it.
;;; It also puts words like "dont" into a standard form.
;;; Thus the is the user types: "I think you like me" then CHANGEPERSON
;;; will change it to "You think I like you"



vars wordtable;
  [[[i]         [you ]]
   [[you are]   [i am]]
   [[you]       [i]]
   [[my]        [your]]
   [[yourself]  [myself]]
   [[myself]    [yourself]]
   [[your]      [my]]
   [[me]        [you]]
   [[mine]      [yours]]
   [[yours]     [mine]]
   [[am]        [are]]
   [[id]        [you had]]
   [[youd]      [i had]]
   [[theyre]    [they are]]
   [[youre]     [i am]]
   [[im]        [you are]]
   [[we]        [you]]    ;;; not always safe!
   [[ive]       [you have]]
   [[doesnt]    [does not]]
   [[youve]     [i have]]
   [[isnt]      [is not]]
   [[arent]     [are not]]
   [[dont]      [do not]]
   [[werent]    [were not]]
   [[mustnt]    [must not]]
   [[shouldnt]  [should not]]
   [[wouldnt]   [would not]]
   [[shant]     [shall not]]
   [[can not]   [cannot]]
   [[cant]      [cannot]]
   [[couldnt]   [could not]]
   [[wont]      [will not]]
   ]  -> wordtable;



define changeperson (sentence)->new_sentence;
 vars item first rest old new remainder;
  undef->remainder;
  if sentence matches [?first ??rest] then
     for item in wordtable do
       quitif (item matches [?old ?new]
               and sentence matches [^^old ??remainder]);
     endfor;
     if remainder=undef then
        [^first ^^(changeperson(rest))]->new_sentence
     else
        [^^new ^^(changeperson(remainder))]->new_sentence
     endif
  else
     nil->new_sentence;
  endif
enddefine;

;;; One problem with changeperson is the way it deals with the word "you"
;;; "you" needs to be changed into "i" if its the subject of the sentence
;;; and "me" if its the object: thus "You like people" should be changed
;;; to "i like people" but "people like you" should be changed to "people
;;; like me". The procedure below is a dodge - normally "you" is changed
;;; to "i" but CHANGE_TO_ME changes "i" to "me" if it is the last word
;;; in a sentence

define change_i_to_me(sentence)->new_sentence;
  vars any_words;
  if sentence matches [??any_words i] then
    [^^any_words me]->new_sentence
  else
    sentence->new_sentence
  endif;
enddefine;

define longword(sentence);
  vars word;
  for word in sentence do
    if length(word)> 10 then
      return(true)
    endif;
  endfor;
  return(false);
enddefine;

;;; Returns TRUE if the sentence contains any item in the list, false otherwise



define contains_one_of(list,sentence);
  vars item;
   for item in list do
     if member(item,sentence) then
         return(true);
     endif;
   endfor;
   return(false);
enddefine;

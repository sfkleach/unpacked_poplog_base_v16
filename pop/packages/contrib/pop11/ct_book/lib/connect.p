/**********************************************************************
  A simple connectionist rule learning system based on pp. 228-233 of
McCleland and Rumelhart, Parallel Distributed Processing, Vol 2.

Commands:

reset()  - reset the nestwork
learn() - learn a sequence of input and associated output patterns. You will
         be prompted for patterns, and then for the number of trials, eg:

    : learn();
    Input pattern? 1 4 7
    Output pattern? 1 4 7
    Input pattern? 2 5 8
    Output pattern? 2 5 7
    Input pattern?
    How many trials: 60

rule78()  - learns the "rule of 78" - ie input patterns consist of one from
    each set: [1 2 3] [4 5 6] [7 8] . A correct output pattern consists of
    the same item as input from sets 1 and 2, and the opposite item from set
    3. ie, given 2 4 7 as input a correct response would be 2 4 8 (see
    p 229 in  McCleland and Rumelhart).

show() - show the current state of the network

probability() - given an input pattern and an intended output patters, gives
    the probability that the particular output pattern would occur, eg:
    : probability();
    Input pattern? 1 4 7
    Intended output pattern? 1 4 7
    Probability: 0.478105

test() - asks for input patterns, and responds with an output patter:
    : test();
    Input pattern? 1 4 7
    [1 4 7]

*************************************************************************/


vars network input_lines output_lines;
vars temperature=15;
constant size=8;    ;;; the size of the network array
constant increment=1; ;;; The amount by which an element is adjested in learning
newarray([1 ^size 1 ^size],0)->network;

/* Read in the patterns */
define get_patterns()->input->output;
  vars item inp outp;
  vars item;
  pr('Input pattern');
  readline()->input;
  if input/=nil then
     input->inp;
     newarray([1 ^size],0)->input;
     newarray([1 ^size],0)->output;
     pr('Output pattern');
     readline()->outp;
      for item in inp do
         1->input(item);
      endfor;
      for item in outp do
         1->output(item);
      endfor;
  endif;
enddefine;

/* Given an input pattern, generate the output */
define fire(input)->output;
 vars net i j probability;
 newarray([1 ^size],0)->output;
 for i to size do
    0->net;
    for j to size do
       net+input(j)*network(i,j)->net;
    endfor;
   1.0/(1.0+exp(-net/temperature))->probability;
    if random(1.0)<= probability then
      1->output(i);
    endif;
  endfor;
enddefine;

/* Given an input pattern, generate the output */
define get_probability(input,intended_output)->probability;
 vars net i j prob;
 1->probability;
 for i to size do
    0->net;
    for j to size do
       net+input(j)*network(i,j)->net;
    endfor;
   1.0/(1.0+exp(-net/temperature))->prob;
   if intended_output(i)=1 then
      probability*prob->probability
   else
      probability*(1-prob)->probability
   endif;
  endfor;
enddefine;

/* Ask for an input pattern and show the corresponding outpyut */
define test();
  vars inp item input output outp;
  repeat
       nil->outp;
      newarray([1 ^size],0)->input;
       pr('Input pattern');
       readline()->inp;
       quitif(inp=nil);
       for item in inp do
          1->input(item);
       endfor;
       fire(input)->output;
       for item to size do
          if output(item)=1 then
              item::outp->outp
          endif;
       endfor;
       pr(rev(outp)); nl(1);
  endrepeat;
enddefine;

/* Print the probability of a given input producing a given output */
define probability();
  vars inp item input output outp probability;
   nil->outp;
  newarray([1 ^size],0)->input;
  newarray([1 ^size],0)->output;
   pr('Input pattern');
   readline()->inp;
   for item in inp do
      1->input(item);
   endfor;
   pr('Intended output pattern');
   readline()->outp;
   for item in outp do
      1->output(item);
   endfor;
   get_probability(input,output)->probability;
   pr('Probability: '); pr(probability); nl(1);
enddefine;

/* Given a list of patterns, carry out the learning trials */
define learnbit(patterns);
   vars input_lines output_lines correct_output trials input output;
   until patterns=nil do
      patterns-->[[?input_lines ?correct_output] ??patterns];
      fire(input_lines)->output_lines;
      for output to size do
            if output_lines(output)=0 and correct_output(output)=1 then
               for input to size do
                 if input_lines(input)=1 then
                    network(output,input)+increment->network(output,input);
                 endif
               endfor
            elseif output_lines(output)=1 and correct_output(output)=0 then
              for input to size do
                 if input_lines(input)=1 then
                   network(output,input)-increment->network(output,input);
                 endif
               endfor
            endif;
         endfor;
   enduntil;
enddefine;

/* Learn input-output pairs for a given number of trials */
define learn();
  vars input output patterns;
   nil->patterns;
   repeat
     get_patterns()->input->output;
     quitif(input=nil);
     [[^input ^output] ^^patterns] ->patterns;
   endrepeat;
   pr('How many trials');
   repeat itemread() times
     learnbit(patterns);
   endrepeat
enddefine;

define rule78();
  vars patterns i j k inp outp;
   nil->patterns;
   for i to 3 do
      for j from 4 to 6 do
        for k from 7 to 8 do
          newarray([1 ^size],0)->inp;
          newarray([1 ^size],0)->outp;
           1->>inp(i)->>inp(j)->inp(k);
           if i=1 and j=4 and k=7 then
             1->>outp(1)->>outp(4)->outp(7)
           else
             1->>outp(i)->>outp(j)->outp(7+(8 mod k))
           endif;
           [[^inp ^outp] ^^patterns]->patterns;
        endfor;
      endfor;
   endfor;
   pr('How many trials');
   repeat itemread() times
     learnbit(patterns);
   endrepeat
enddefine;



/* Show the current state of the network */
define show();
 vars i j no;
   for i to size do
      for j to size do
       network(i,j)->no;
       if no=0 then
         pr('.')
       elseif no>0 then
         pr(' '); pr(no);
       else
         pr(no);
       endif;
      tabs(1);
      endfor;
      nl(1);
   endfor;
enddefine;


/* Reinitialise the network */
define reset();
   newarray([1 ^size 1 ^size],0)->network;
enddefine;

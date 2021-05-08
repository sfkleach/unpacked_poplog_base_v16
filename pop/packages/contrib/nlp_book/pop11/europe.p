;;; % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
;;; %   Example code from the book "Natural Language Processing in POP-11"  %
;;; %                      published by Addison Wesley                      %
;;; %        Copyright (c) 1989, Gerald Gazdar & Christopher Mellish.       %
;;; % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
;;;
;;; europe.p [Chapter  9] Example database for question-answering

;;; [border COUNTRY1 COUNTRY2]
;;; [country COUNTRY POPULATION CAPITAL]

vars database;
[
   [border portugal spain]
   [border spain portugal]
   [border spain andorra]
   [border andorra spain]
   [border spain france]
   [border france spain]
   [border andorra france]
   [border france andorra]
   [border france luxembourg]
   [border luxembourg france]
   [border france belgium]
   [border belgium france]
   [border france germany]
   [border germany france]
   [border france switzerland]
   [border switzerland france]
   [border france italy]
   [border italy france]
   [border belgium netherlands]
   [border netherlands belgium]
   [border luxembourg belgium]
   [border belgium luxembourg]
   [border belgium germany]
   [border germany belgium]
   [border luxembourg germany]
   [border germany luxembourg]
   [border germany switzerland]
   [border switzerland germany]
   [border germany austria]
   [border austria germany]
   [border switzerland austria]
   [border austria switzerland]
   [border switzerland italy]
   [border italy switzerland]
   [border austria italy]
   [border italy austria]
   [country portugal 92 lisbon]
   [country spain 505 madrid]
   [country andorra 1 andorra]
   [country france 547 paris]
   [country belgium 31 brussels]
   [country luxembourg 1 luxembourg]
   [country netherlands 41 amsterdam]
   [country germany 249 bonn]
   [country switzerland 41 berne]
   [country austria 84 vienna]
   [country italy 301 rome]
] -> database;

vars europe; true -> europe;
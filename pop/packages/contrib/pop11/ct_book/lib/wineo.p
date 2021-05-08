/* --- Copyright University of Sussex 1989. All rights reserved. ----------
 > File:            $poplocal/local/lib/wineo.p
 > Purpose:         Production system (LIB PRODSYS) Demo
 > Author:          Mike Sharples, Feb  7 1989
 > Documentation:
 > Related Files:   LIB PRODSYS
 */

/**************************************************************************
   A production rule wine advisor (data taken from a Teknowledge tutorial
   on production systems).
***************************************************************************/

        uses prodsys;
        vars suggestions insert_item colour1 colour2;
        nil->suggestions;
        nil->rulebase;


         define respond;
           vars response;
           nl(1); readline()->response;
           if response = nil then
                [unknown]
           elseif response matches [== certainty ==] then
                response
           else
              response<>[certainty 1.0]
           endif;
        enddefine;

        define insert(item);
           insert_item(last(item),item,[],suggestions)->suggestions;
        enddefine;

        define insert_item(item_value,item,seen,list);
           if list=nil then
                rev(item::seen)
           elseif item_value>= last(front(list)) then
               rev(seen)<>item::list
           else
               insert_item(item_value,item,front(list)::seen,back(list))
           endif
        enddefine;

        define suggest();
          vars type cert used;
          []->used;
          until suggestions=nil do
            front(suggestions)-->[wine select ??type certainty ?cert];
            if not(member(type,used)) then
               nl(1); ppr([I would suggest a ^^type (certainty ^cert)]); nl(2);
               pr('Would you like another suggestion (y/n)');
               quitif (readline()/=[y]);
               type::used->used;
            endif;
            tl(suggestions)->suggestions;
          enduntil;
       enddefine;


       define start;
          [[wine  main_dish unknown ]
           [wine  preferred_colour unknown ]
           [wine preferred_sweetness unknown]
           [wine preferred_body unknown]
           [wine body unknown]
           [wine  colour unknown]
           [wine sweetness unknown]]->database;
          nil->suggestions;
          run();
          suggest();
          nl(2); pr('Consultation finished'); nl(2);
          pr('For another consultation type: start();'); nl(1);
          pr('and then press <RETURN>');   nl(1);
       enddefine;


        /* Determine the type of dish */

        rule get_dish [wine  main_dish unknown];
            vars dish;
            pr('Is the main dish fish, meat, or poultry');
            respond()->dish;
            remove([wine  main_dish unknown]);
            add([wine  main_dish ^^dish]);
            add([wine  main_dish sauce unknown]);
            add([wine main_dish tastiness unknown]);
        endrule;

        rule poultry_dish [wine  main_dish poultry ==];
            vars contents;
            pr('What type of poultry: chicken, turkey etc');
            respond()->contents;
            add([wine  main_dish contains ^^contents]);
        endrule;

        rule meat_dish [wine  main_dish meat ==];
            vars contents;
            pr('What type of meat: pork, veal, lamb, etc');
            respond()->contents;
            add([wine  main_dish contains ^^contents]);
        endrule;

/* Determine the type of sauce */

        rule sauce_type [wine  main_dish sauce unknown]
                        [not [wine  main_dish fish ==]];
            vars sauce sweetness;
       pr('What type of sauce is with the main dish: tomato, creamy, spicy');
            respond()->sauce;
            pr('Is the sauce sweet or sour:');
            respond()->sweetness;
            remove([wine  main_dish sauce unknown]);
            add([wine  main_dish sauce ^^sauce]);
            add([wine  main_dish sauce_sweetness ^^sweetness]);
        endrule;


        /* Rules for determining the colour */

       rule colour1 [wine  colour unknown ]
                    [wine  main_dish meat ==]
                    [not [wine  main_dish contains veal ==]];
               remove([wine  colour unknown ]);
               add([wine  colour red certainty 0.9]);
       endrule;



        rule colour2 [wine  colour unknown]
                     [wine  main_dish fish ==];
            remove([wine  colour unknown]);
            add([wine  colour white certainty 1.0]);
        endrule;

        rule colour3 [wine  colour unknown]
                     [not [wine  main_dish fish ==]]
                     [wine  main_dish sauce tomato certainty ?cert];
            remove([wine  colour unknown] );
            add([wine  colour red certainty ^cert]);
        endrule;



        rule colour4 [wine  colour unknown ]
                     [wine  main_dish contains turkey ==];
             remove([wine  colour  unknown]);
             add([wine  colour red certainty 0.8]);
             add([wine  colour white certainty 0.5]);
        endrule;

        rule colour5 [wine  colour  unknown]
                     [wine  main_dish poultry ==]
                     [not [wine  main_dish contains turkey ==]];
            remove([wine  colour unknown ]);
            add([wine  colour white certainty 0.9]);
            add([wine  colour red certainty 0.3]);
        endrule;

        rule colour6 [wine  colour unknown ]
                     [wine  main_dish sauce creamy certainty ?cert];
            remove([wine  colour unknown ]);
            add([wine  colour white certainty ^(cert*0.4)]);
       endrule;


        /* Discover which colour of wine the user prefers */

        rule find_colour [wine  preferred_colour unknown ];
            vars preference;
            pr('Do you prefer red or white wine');
            respond()->preference;
            remove([wine  preferred_colour unknown ]);
            add([wine  preferred_colour ^^preference]);
        endrule;


        /* This rule is fired if the user does not express a preference */

        rule no_preference
                [wine  preferred_colour  unknown ];
            remove([wine preferred_colour unknown ]);
            add([wine  preferred_colour red certainty 0.5]);
            add([wine  preferred_colour white certainty 0.5]);
        endrule;

        /* If the system has not been able to determine a colour for the
           wine and the user has a preference then take the user's
           preference */

        rule no_chosen1 [wine  colour unknown ]
                  [wine  preferred_colour ?colour1 certainty ?cert1]
                  [wine  preferred_colour ?colour2 certainty ?cert2]
                  where colour1 /= colour2;
           remove([wine colour unknown]);
           add([wine  colour ^colour1 certainty ^cert1]);
           add([wine colour  ^colour2 certainty ^cert2]);
        endrule;

        rule no_chosen2 [wine  colour unknown ]
                  [wine  preferred_colour ?colour certainty ?cert];
           remove([wine colour unknown]);
           add([wine colour  ^colour certainty ^cert]);
        endrule;




        /* The next two rules merge the user's preference with the program's
        *  choice of colour (based on the type of dish)
        */

        rule merge1 [wine  colour ?colour1 certainty ?cert1]
                [wine  preferred_colour ?colour1 certainty ?cert2];
            remove([wine colour ^colour1 certainty ^cert1]);
            add([wine  colour ^colour1 certainty
                    ^(cert1 + (0.3 * cert2 * (1 - cert1)))]);
        endrule;


;;; RULES FOR DETERMINING THE SWEETNESS

        rule sweet1 [ wine main_dish sauce_sweetness sweet certainty ?cert];
              remove([wine sweetness unknown ]);
              add([wine sweetness sweet certainty ^(cert*0.9)]);
              add([wine sweetness medium certainty ^(cert*0.4)]);
        endrule;

        rule sweet2 [wine preferred_sweetness unknown ];
              vars sweetness;
              pr('How sweet do you like your wine: dry, medium, sweet');
              respond()->sweetness;
              remove([wine preferred_sweetness unknown]);
              add([wine preferred_sweetness ^^sweetness]);
        endrule;

        rule sweet3 [wine sweetness unknown]
                    [wine preferred_sweetness unknown];
              remove ([wine sweetness unknown]);
              remove ([wine preferred_sweetness unknown]);
              add([wine sweetness medium certainty 1.0]);
        endrule;

/*If the user expressed a preference for sweetness and the systems was able
  to come to a conclusion about the sweetness then add the users preference
   with a .2 * cert certainty
 */

        rule sweet4 [wine sweetness ==]
                    [wine preferred_sweetness ?sweetness certainty ?cert];
              add([wine sweetness ^sweetness certainty ^(0.2 * cert) ]);
        endrule;

        rule sweet5 [wine preferred_sweetness dry certainty ?cert1]
                     [wine sweetness sweet certainty ?cert2];
              add([wine sweetness medium certainty ^(min(cert1,cert2))]);
        endrule;

        rule sweet6 [wine preferred_sweetness sweet certainty ?cert1]
                    [wine sweetness dry certainty ?cert2];
              add([wine sweetness medium certainty ^(min(cert1,cert2))]);
        endrule;


/* The system had no preference for sweetness */

        rule sweet7 [wine sweetness unknown]
                    [wine preferred_sweetness ?sweetness certainty ?cert];
             remove([wine sweetness unknown]);
             add([wine sweetness ^sweetness certainty ^cert]);
        endrule;


/* Remove repeated entries for a particular sweetness */

        rule sweet8 [wine sweetness ?sweetness certainty ?cert1]
                    [wine sweetness ?sweetness certainty ?cert2]
                    where cert1 > cert2 ;
              remove([wine sweetness ^sweetness certainty ^cert2]);
        endrule;


/*  Rules for determining the Body of the wine */

        rule body1 [wine main_dish tastiness unknown];
          vars tastiness;
             pr('How strong tasting is the meal: delicate, average, strong');
             respond()->  tastiness;
             remove([wine main_dish tastiness unknown]);
             add([wine main_dish tastiness ^^tastiness]);
        endrule;

        rule body2 [wine main_dish tastiness delicate certainty ?cert]
                   [wine body unknown];
             remove([wine body unknown]);
             add([wine body light certainty ^(cert*0.8)]);
        endrule;

        rule body3 [wine main_dish tastiness average certainty ?cert]
                   [wine body unknown];
             remove([wine body unknown]);
             add([wine body light certainty ^(cert*0.3)]);
             add([wine body medium certainty ^(cert*0.6)]);
             add([wine body full certainty ^(cert*0.3)]);
        endrule;

        rule body4 [wine main_dish tastiness strong certainty ?cert]
                   [wine body unknown];
             remove([wine body unknown]);
             add([wine body medium certainty ^(cert*0.4)]);
             add([wine body full certainty ^(cert*0.8)]);
        endrule;

        rule body5 [wine main_dish sauce spicy certainty ?cert]
                   [wine body unknown];
             remove([wine body unknown]);
             add([wine body medium certainty ^(cert*0.4)]);
             add([wine body full certainty ^(cert*0.8)]);
        endrule;


/* Reconciliation rules for the wine body */

        rule body6 [wine preferred_body unknown];
           vars body;
  pr('What kind of body would you like the wine to have: light, medium, full');
           respond()->body;
           remove([wine preferred_body unknown]);
           add([wine preferred_body ^^body]);
        endrule;

        rule body7 [wine body unknown]
                   [wine preferred_body unknown];
           remove([wine body unknown]);
           add([wine body medium certainty 1]);
        endrule;

        rule body8 [wine body full certainty ?cert1]
                   [wine preferred_body light certainty ?cert2];
           remove([wine body full ==]);
           add([wine body medium certainty ^(min(cert1,cert2))]);
        endrule;

        rule body9 [wine body light certainty ?cert1]
                   [wine preferred_body full certainty ?cert2];
            remove([wine body light ==]);
            add([wine body medium certainty ^(min(cert1,cert2))]);
        endrule;

        rule body10 [wine body = certainty =]
                    [wine preferred_body ?body certainty ?cert];
            add([wine body ^body certainty ^cert]);
        endrule;

        rule body11 [wine body unknown]
                    [wine preferred_body ?body certainty ?cert];
            remove([wine body unknown]);
            add([wine body ^body certainty ^cert]);
        endrule;

/* Rules for selecting the wines */

        rule select1 [wine colour red certainty ?cert1]
                     [wine body medium certainty ?cert2]
                     [wine sweetness medium certainty ?cert3];
            insert([wine select Gamay certainty ^(min(min(cert1,cert2),cert3))]);
        endrule;

        rule select2 [wine colour red certainty ?cert1]
                     [wine body medium certainty ?cert2]
                     [wine sweetness sweet certainty ?cert3];
            insert([wine select Gamay certainty ^(min(min(cert1,cert2),cert3))]);
        endrule;

        rule select3 [wine colour white certainty ?cert1]
                     [wine body light certainty ?cert2]
                     [wine sweetness dry certainty ?cert3];
          insert([wine select Chablis certainty ^(min(min(cert1,cert2),cert3))]);
        endrule;

        rule select4 [wine colour white certainty ?cert1]
                     [wine body medium certainty ?cert2]
                     [wine sweetness dry certainty ?cert3];
 insert([wine select Sauvignon Blanc certainty ^(min(min(cert1,cert2),cert3))]);
        endrule;



        rule select6 [wine colour white certainty ?cert1]
                     [wine body full certainty ?cert2]
                     [wine sweetness dry certainty ?cert3];
       insert([wine select Chardonnay certainty ^(min(min(cert1,cert2),cert3))]);
        endrule;

        rule select7 [wine colour white certainty ?cert1]
                     [wine body medium certainty ?cert2]
                     [wine sweetness medium certainty ?cert3];
       insert([wine select Chardonnay certainty ^(min(min(cert1,cert2),cert3))]);
        endrule;

        rule select8 [wine colour white certainty ?cert1]
                     [wine body full certainty ?cert2]
                     [wine sweetness medium certainty ?cert3];
       insert([wine select Chardonnay certainty ^(min(min(cert1,cert2),cert3))]);
        endrule;

        rule select9 [wine colour white certainty ?cert1]
                     [wine body light certainty ?cert2]
                     [wine sweetness dry certainty ?cert3];
            insert([wine select Soave certainty ^(min(min(cert1,cert2),cert3))]);
        endrule;

        rule select10 [wine colour white certainty ?cert1]
                     [wine body light certainty ?cert2]
                     [wine sweetness medium certainty ?cert3];
            insert([wine select Soave certainty ^(min(min(cert1,cert2),cert3))]);
        endrule;

        rule select11 [wine colour white certainty ?cert1]
                      [wine body light certainty ?cert2]
                      [wine sweetness medium certainty ?cert3];
     insert([wine select Riesling certainty ^(min(min(cert1,cert2),cert3))]);
        endrule;

        rule select12 [wine colour white certainty ?cert1]
                      [wine body medium certainty ?cert2]
                      [wine sweetness medium certainty ?cert3];
     insert([wine select Riesling certainty ^(min(min(cert1,cert2),cert3))]);
        endrule;

        rule select13 [wine colour white certainty ?cert1]
                      [wine body light certainty ?cert2]
                      [wine sweetness sweet certainty ?cert3];
     insert([wine select Riesling certainty ^(min(min(cert1,cert2),cert3))]);
        endrule;

        rule select14 [wine colour white certainty ?cert1]
                      [wine body medium certainty ?cert2]
                      [wine sweetness sweet certainty ?cert3];
     insert([wine select Riesling certainty ^(min(min(cert1,cert2),cert3))]);
        endrule;

        rule select15 [wine colour white certainty ?cert1]
                      [wine body full certainty ?cert2]
                      [wine main_dish sauce spicy certainty ?cert3];
   insert([wine select Geverztraiminer certainty ^(min(min(cert1,cert2),cert3))]);
        endrule;

        rule select16 [wine colour white certainty ?cert1]
                      [wine body full certainty ?cert2]
                      [wine sweetness medium certainty ?cert3];
     insert([wine select Chenin Blanc certainty ^(min(min(cert1,cert2),cert3))]);
        endrule;

        rule select17 [wine colour white certainty ?cert1]
                      [wine body full certainty ?cert2]
                      [wine sweetness sweet certainty ?cert3];
     insert([wine select Chenin Blanc certainty ^(min(min(cert1,cert2),cert3))]);
        endrule;

        rule select18 [wine colour red certainty ?cert1]
                      [wine body light certainty ?cert2];
           insert([wine select Valpolicella certainty ^(min(cert1,cert2))]);
        endrule;

        rule select19 [wine colour red certainty ?cert1]
                      [wine sweetness dry certainty ?cert2];
         insert([wine select Cabernet Sauvignon certainty ^(min(cert1,cert2))]);
        endrule;

        rule select20 [wine colour red certainty ?cert1]
                      [wine sweetness medium certainty ?cert2];
         insert([wine select Cabernet Sauvignon certainty ^(min(cert1,cert2))]);
        endrule;

        rule select21 [wine colour red certainty ?cert1]
                      [wine body medium certainty ?cert2]
                      [wine sweetness medium certainty ?cert3];
          insert([wine select Pinot Noir certainty ^(min(min(cert1,cert2),cert3))]);
        endrule;

        rule select22 [wine colour red certainty ?cert1]
                      [wine body full certainty ?cert2];
          insert([wine select Burgundy certainty ^(min(cert1,cert2))]);
        endrule;



false->repeating;
false->walk;
false->chatty;

pr('Welcome to the Wine Advisor.\n');
pr('I can help you choose the best wine for your meal\n');
pr('When you are asked a question you can either reply with\n');
pr('a word from the choices offered, or a word plus a certainty\n');
pr('e.g.: red certainty 0.5   or if you have no preference then\n');
pr('just press <RETURN>\n');
pr('To start the consultation, type: start();\n');

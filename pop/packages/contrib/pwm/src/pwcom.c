/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 * File:		$usepop/master/C.sun/pwm/pwcom.c
 * Purpose:		additional code for interactive debugging versions
 * Author:		Ben Rubinstein, Feb 20 1987
 * $Header: /popv13.5/pop/pwm/RCS/pwcom.c,v 1.2 89/08/23 16:16:43 pop Exp $
 */

/*--------------------------------------------------------------------
*/
handle_control_input()
{
	char comcode;
	int w_num, i;

	conch = getc(stdin);

	if	(conch == '!')
	{
		comcode = getc(stdin);

		switch (comcode)
		{
			case 'K':
				if	 ((w_num = get_win_arg("kill")) != WT_NOWIN)
				{
					printf("killing window #%d\n", w_num);
					really_kill_window(w_num);
				}
				break;
			case 'J':
				scanf("%d", &i);
				current_in = i;
				break;
			case 'P':
				scanf("%d", &i);
				if	(i < 0 || i > 9)
				 	printf("private commands only 0-9 (%d)\n", i);
				else
				{
					com_charargs[0] = i + '0';
					various_command();
				}
				break;
			case 'I':
				scanf("%d", &i);
				printf("faking input of %c (%d)\n", i, i);
				parse_escape_sequence(i);
				break;
			case 'S':
				scanf("%d", &i);
				printf("faking output of %c (%d)\n", i, i);
				send_to_poplog(i);
				break;
			case 'M':
				scanf("%d", &i);
				printf("setting mmaction to %d\n", i);
				ci_mmaction = i;
				break;
			case 'V':
				clear_page();
				break;
            case 'C':
                describe_colourmap();
                break;
			case 'E':
				print_escape_seq(com_seq_len);
			case 'A':
				printf("VVV Char-args: %d\n", com_ecargs);
				if (com_ecargs > 0)
					for (i =0; i < com_ecargs; i++)
						printf("   %d: '%c' (%d/%d)\n", i, com_charargs[i],
									com_charargs[i], com_charargs[i] - 32);
				printf("VVV Num-args: %d\n", com_nargs);
				if (com_nargs > 0)
					for (i =0; i < com_nargs; i++)
						printf("   %d: %d\n", i, com_numargs[i]);
				break;
			case 'G':
				printf("cGraf=%d", current_graf);
				if (cg_winisframe)
				{
					printf(" - frame, %dx%dx%d\n",
						gfx_frames[current_graf - FT_FIRSTFRAME]->pr_width,
						gfx_frames[current_graf - FT_FIRSTFRAME]->pr_height,
						gfx_frames[current_graf - FT_FIRSTFRAME]->pr_depth);
				}
				else
				{
					printf(" - normal, %dx%dx%d\n",
						cg_pixwinp->pw_prretained->pr_width,
						cg_pixwinp->pw_prretained->pr_height,
						cg_pixwinp->pw_prretained->pr_depth);
				}
				break;
			case '?':
				printf("CI=%d, CO=%d, CG=%d, inesc=%d,\
\nComSeqlen=%d, ComBuflen=%d, ComTerm=%d,\
\nWrap=%d, Grf=%d, ShEsc=%d,\
\nSEL=(%d,%d)-(%d,%d),\
\nPC=%d, PL=%d, BC=%d, VC=%d, CWC=%d\
\nci_md=%d, ci_ma=%d\n",
					current_in, current_out, current_graf, in_escape,
					com_seq_len, com_buflen, com_termin,
					co_winiswrap, term_grafmode, shift_escape,
                    selectstart.x, selectstart.y, selectend.x, selectend.y,
					poplog_connected, poplog_listening,
					base_cooked, ved_cooked, co_winiscooked,
					ci_mousedown, ci_mmaction
					);
				break;
			default:
				printf("command codes are:\n\
\tKill <number>\n\
\tInput <number>\n\
\tV - clear page\n\
\tE - print last escape sequence\n\
\tA - print last arg set\n\
\tP - various <number>\n\
\tG - print graphic win details\n\
\t? - details\n\
(syntax is '!'<Initial of command> <args>.)\n");
				break;
		}
	consume_chars_to('\n');
	}
	else
		printf("command lines start with '!'\n");

   	consume_chars_to('\n');
}

/*--------------------------------------------------------------------
*/
get_win_arg(com)
char *com;
{
	int i;

	scanf("%d", &i);

	if	((i >= WT_FIRSTWIN) && (i <= WT_LASTWIN))
	{
		if	(wt_active[i] >= WT_ACTIVE)
			return(i);
		else
			printf("can't %s window #%d: not active\n", com, i);
	}
	else
		printf("can't %s window #%d: no such window\n", com, i);
	return(WT_NOWIN);
}

/*--------------------------------------------------------------------
*/
consume_chars_to(closer)
char closer;
{
	int  i;

 	i = 0;

	if	(conch == 0)
		conch = getc(stdin);

	while ( conch != closer)
	{
		buf[i] = conch;
		i++;
		conch = getc(stdin);
	}
	buf[i] = 0;
}


/* ::::::::::::::::::: Index :::::::::::::::::::::::
::
:: ----1---Copyright University of Sussex 1987.  All rights reserved. ------
::     9:  handle_control_input()
::   133:  get_win_arg(com)
::   154:  consume_chars_to(closer)
::
::::::::::::::::::::::::::::::::::::::::::::::::::::: */
/*
$Log:	pwcom.c,v $
 * Revision 1.2  89/08/23  16:16:43  pop
 * *** empty log message ***
 * 
 * Revision 1.1  89/08/23  13:19:41  pop
 * Initial revision
 * 
*/

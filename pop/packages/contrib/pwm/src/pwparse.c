/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 * File:		$usepop/master/C.sun/pwm/pwparse.c
 * Purpose:		parse command sequences and call appropriate routine
 * Author:		Ben Rubinstein, Feb 20 1987 (see revisions)
 * Related Files: tables to drive parser are in PWCOMSEQ.H
 * $Header: /popv13.5/pop/pwm/RCS/pwparse.c,v 1.1 89/08/23 13:20:55 pop Exp $
 */

#include "pwdec.h"
#include "pwcomseq.h"

static char com_num_sign;

/*--------------------------------------------------------------------
* 	called directly the character is read in, if we're in escape mode
*/
parse_escape_sequence(code)
char code;
{
	switch (++com_seq_len)
	{
	case 1:
		com_header = code;
		read_eseq_two();
		break;
	case 2:
		com_code1 = code;
		break;
	case 3:
		com_code2 = code;
		read_eseq_four();
		break;
	default:
		if	(com_seq_len < (COMBUFSIZE - 1))
		{
			com_read_proc(code);
		}
		else
		{
			int i;
#ifdef DeBug
			printf("PWM: escape sequence too long, abandoning it\n");
			printf("iii com_nargs=%d, com_enargs=%d, com_stringlen=%d\n",
										com_nargs, com_enargs, com_stringlen);
			for (i= 0; i <= com_nargs; i++)
				printf("iii 	com_numargs[%d]=%d\n", i, com_numargs[i]);

			com_stringarg[com_stringlen] = 0;
			printf(com_stringarg);
#endif
			abandon_command();
		}

		break;
	}
}


/* ------------------
* 	called with the character following the leading escape
*/
read_eseq_two()
{
	register int i;

	for (i = 0; i < V2exelen; i++) if (V2exechars[i] == com_header) break;
	if (i < V2exelen)
	{
		((v2exeprocs[i]).proc)();
		com_seq_len = in_escape = 0;
	}
	else
	{
		for (i = 0; i < Fourc_seclen; i++) if (Fourc_second[i] == com_header) break;
		if (i < Fourc_seclen)
		{
			com_termin = VW_NOTERM;
		}
		else
		{
			for (i = 0; i < V2ignlen; i++) if (V2ignore[i] == com_header) break;
			if	(i < V2ignlen)
			{
#ifdef DeBug
				printf("--- ignoring unsupported v200 command %c (%d)\n", com_header, com_header);
#endif;
				com_seq_len = in_escape = 0;
			}
			else
			{
#ifdef DeBug
				printf("||| bad escape sequence: %c (%d)\n", com_header, com_header);
#endif
				abandon_command();
			}
		}
	}
}

/* ------------------
* 	called when third character after the leading escape has been
*		read and stuck in the buffer
*/
read_eseq_four()
{
	switch (com_header)
    {
		case 'Y':
			cursor_address();
			com_seq_len = in_escape = FALSE;
			break;
		case '{':
			stringcom = FALSE;
			find_com_sequence(0, Cocb_len);
			break;
		case '}':
			stringcom = TRUE;
			find_com_sequence(Cocb_len, Cocb_len + Cccb_len);
			break;
		case '[':
			com_numargs[0]  = com_nargs = 0;
			com_ansixy_read(com_code1);
			if (in_escape == TRUE) com_ansixy_read(com_code2);
			if (in_escape == TRUE) com_read_proc = com_ansixy_read;
			return;
			break;
		default:
#ifdef DeBug
			printf("PWM: parser error, my mistake: got to here with %c (%d)\n",
												com_header);
#endif
			abandon_command();
			break;
	}
	if (in_escape == 1)
	{
		cursornotneeded = FALSE;
		Paint_cursor;		/* IMPORTANT! anything other than the terminal *
							 * emulation functions must do this 		   */

		if (com_ecargs != 0)
			com_read_proc = com_char_read;
		else if (com_enargs != 0)
		{
			com_numargs[0]  = com_nargs = 0;
			com_num_sign = 1;
			com_read_proc = com_num_read;
		}
		else if (stringcom != 0)
		{
			com_stringlen = 0;
			com_read_proc = com_string_read;
		}
		else
			com_read_proc = com_char_read;
	}
}

/* -- readers------------------------------------------------------- */

/*--------------------------------------------------------------------
*	read character ("small-int") arguments.  By definition these always
*	precede any other arguments; and there will always be exactly the
*	defined number of them (com_ecargs = expected char. args).  Note that
*	they are stored in the array in reverse order: thus if a function takes
*	two character arguments,  the first one send will be 1, the second 0.
*/
com_char_read(c)
char c;
{
	if (com_ecargs == 0)
	{
		if (com_enargs != 0)
		{
			com_numargs[0]  = com_nargs = 0;
			com_num_sign = 1;
			com_read_proc = com_num_read;
			com_num_read(c);
		}
		else if (stringcom != 0)
		{
			com_stringlen = 0;
			com_read_proc = com_string_read;
			com_string_read(c);
		}
		else if	(c == COMpwmnumterm)
		{
			com_doit_proc();
			com_seq_len = in_escape = 0;
		}
		else
		{
#ifdef DeBug
			printf("||| bad char looking for num-term esc-%c: '%c' (%d) at %d\n",
										com_header, c, c, com_seq_len);
			print_escape_seq();
#endif
		abandon_command();
		}
	}
	else
		com_charargs[--com_ecargs] = c;
}

/*--------------------------------------------------------------------
*	read up to 'com_enargs' numbers, separated by COMnumdelim. if the flag
*	'stringcom' is true (1), then read another COMnumdelim and effectively
*	chain to string read: otherwise read COMpwmnumterm and call the doit proc.
*/
com_num_read(c)
char c;
{
	if (isdigit(c))
		com_numargs[com_nargs] = com_numargs[com_nargs] * 10 + c - '0';
	else if ((c == '-') && (com_numargs[com_nargs] == 0))
		 com_num_sign = -1;
	else
	{
		com_numargs[com_nargs] *= com_num_sign;
		com_numargs[++com_nargs] = 0;
		com_num_sign = 1;

		if (c == COMnumdelim)
		{
			if (com_nargs == com_enargs)
				if (stringcom == TRUE)
				{
					com_stringlen = 0;
					com_read_proc = com_string_read;
				}
				else
				{
#ifdef DeBug
					printf("||| badly term'ed number sequence (e=%d, n=%d)\n", com_enargs, com_nargs);
#endif
					abandon_command();
				}
		}
		else if (c == COMpwmnumterm)
		{
			com_doit_proc();
			com_seq_len = in_escape = 0;
		}
		else
		{
#ifdef DeBug
			printf("||| bad char making %dth number (e=%d): %c (%d) at %d\n",
						com_nargs, com_enargs, c, c, com_seq_len);
			print_escape_seq(com_seq_len);
#endif
			abandon_command();
		}
	}
}

com_ansixy_read(c)
char c;
{
	if (isdigit(c))
		com_numargs[com_nargs] = com_numargs[com_nargs] * 10 + c - '0';
	else
	{
		com_numargs[++com_nargs] = 0;

		if ((com_nargs == 1) && (c == COMnumdelim))
			{} /* nothing */
		else if ((com_nargs == 2) && (c == COMansixyterm))
		{
			register int x, y;

			if ((com_numargs[0] > 0) && ((y = com_numargs[0] - 1) < co_heightc)
			&&	(com_numargs[1] > 0) && ((x = com_numargs[1] - 1) < co_widthc))
				jump_cursor(x, y);

			com_seq_len = in_escape = 0;
		}
		else
		{
#ifdef DeBug
			printf("||| bad char for number #%d in ansi xy: '%c' (%d) at %d\n",
						com_nargs, c, c, com_seq_len);
			print_escape_seq(com_seq_len);
#endif
			abandon_command();
		}
	}
}

/*--------------------------------------------------------------------
*	read a string up to the terminating characters
*/
com_string_read(c)
char c;
{
	if ((c == COMstrterm)
		&& (com_stringlen != 0)
		&& (com_stringarg[com_stringlen - 1] == VW_ESCAPE))
	{
		com_stringarg[com_stringlen - 1] = 0;
		com_doit_proc();
		com_seq_len = in_escape = 0;
	}
	else
	{
		if (com_stringlen >= ARGSTRSIZE) com_stringlen = ARGSTRSIZE - 1;
		com_stringarg[com_stringlen++] = c;
	}
}

/* -- utilities----------------------------------------------------- */

/*--------------------------------------------------------------------
*	sequence does not appear to be a valid one - treat everything following
*	the escape as new text, and start again
*/
abandon_command()
{
		in_escape = com_termin = com_seq_len = 0;
		if (com_bufnext > com_seq_add) com_bufnext = com_seq_add + 1;
}

find_com_sequence(table_start, table_end)
int table_start, table_end;
{
	register int i;
	struct seq_rec rec;
	char *seq;

	i = table_start;

	while (i < table_end)
	{
		rec = com_table[i];
		seq = rec.seq;

		if ((seq[0] == com_code1) && ((seq[1] == com_code2) || (seq[1] == 0)))
		{
			com_doit_proc = rec.proc;
			com_ecargs = rec.cnargs;
			com_enargs = rec.nnargs;
			break;
		}
		else
			i++;
	}
	if	(i == table_end)
	{
#ifdef DeBug
		printf("||| bad escape sequence (can't find it): '%c%c' (%d, %d)\n",
							com_code1, com_code2, com_code1, com_code2);
		print_escape_seq(4);
#endif
		abandon_command();
	}
}

#ifdef DeBug
print_escape_seq(n)
int n;
{
	int d;
	char c;
	unsigned int i;

	printf("vvv escape: n=%d, buflen=%d, seqadd=%d, bufnxt=%d, seqlen=%d, term=%d\n",
			n, com_buflen, com_seq_add, com_bufnext, com_seq_len, com_termin);
	for (i = com_seq_add; i < com_bufnext; i++)
	{
		d = c = com_buffer[i];
		if	(c > 127)
			c = c - 128;

		if (c == 127)
			printf("   %d: '<del>' ", i);
		else if (c > 31)
			printf("   %d: '%c'    ", i, c);
		else
			printf("   %d: '^%c'    ", i, c + 64);

		printf("(%d)\n", d);
	}
}
#endif


/* ::::::::::::::::::: Index :::::::::::::::::::::::
::
::    16:  parse_escape_sequence(code)
::    61:  read_eseq_two()
::   103:  read_eseq_four()
:: --158---readers------
::   167:  com_char_read(c)
::   209:  com_num_read(c)
::   255:  com_ansixy_read(c)
::   291:  com_string_read(c)
:: --306---utilities------
::   312:  abandon_command()
::   318:  find_com_sequence(table_start, table_end)
::   354:  print_escape_seq(n)
::
::::::::::::::::::::::::::::::::::::::::::::::::::::: */

/* --- Revision History ---------------------------------------------------
--- John Williams, Jun  5 1987 - fixed bug in com_string_read
$Log:	pwparse.c,v $
 * Revision 1.1  89/08/23  13:20:55  pop
 * Initial revision
 * 
 */

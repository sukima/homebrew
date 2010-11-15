require 'formula'

class Sc <Formula
  url 'http://www.ibiblio.org/pub/linux/apps/financial/spreadsheet/sc-7.16.tar.gz'
  homepage 'http://www.ibiblio.org/pub/linux/apps/financial/spreadsheet/sc-7.16.lsm'
  md5 '1db636e9b2dc7cd73c40aeece6852d47'

  skip_clean 'share/sc/plugins'

  def install
    inreplace 'Makefile' do |s|
      s.change_make_var! 'prefix', prefix
      s.change_make_var! 'EXDIR', bin
      s.change_make_var! 'MANDIR', man1
      s.change_make_var! 'LIBDIR', "#{share}/sc"
    end
    system "make install"
  end

  def patches
    # The Makefile for sc 7.16 doesn't work well with dirs like Homebrew uses;
    # also, it looks unmaintained, so these changes are unlikely to be applied
    # The original code base had issues with syntax errors. The ubuntu team has
    # been maintaining patches for this. ~Devin
    # (see https://launchpad.net/ubuntu/+source/sc/7.16-3 for ubuntu patch info)
    DATA
  end

end

__END__

diff --git a/Makefile b/Makefile
index f3007b4..2e3a73c 100644
--- a/Makefile
+++ b/Makefile
@@ -499,14 +499,17 @@ install: $(EXDIR)/$(name) $(EXDIR)/$(name)qref $(EXDIR)/p$(name) \
 	 $(MANDIR)/p$(name).$(MANEXT)
 
 $(EXDIR)/$(name): $(name)
+	-mkdir -p $(EXDIR)
 	cp $(name) $(EXDIR)
 	strip $(EXDIR)/$(name)
 
 $(EXDIR)/$(name)qref: $(name)qref
+	-mkdir -p $(EXDIR)
 	cp $(name)qref $(EXDIR)
 	strip $(EXDIR)/$(name)qref
 
 $(EXDIR)/p$(name): p$(name)
+	-mkdir -p $(EXDIR)
 	cp p$(name) $(EXDIR)
 	strip $(EXDIR)/p$(name)
 
@@ -516,9 +519,10 @@ $(LIBDIR)/tutorial: tutorial.sc $(LIBDIR)
 	chmod $(MANMODE) $(LIBDIR)/tutorial.$(name)
 
 $(LIBDIR):
-	mkdir $(LIBDIR)
+	-mkdir -p $(LIBDIR)
 
 $(MANDIR)/$(name).$(MANEXT): $(name).1
+	-mkdir -p $(MANDIR)
 	cp $(name).1 $(MANDIR)/$(name).$(MANEXT)
 	chmod $(MANMODE) $(MANDIR)/$(name).$(MANEXT)
 
diff --git a/Makefile b/Makefile
index 2e3a73c..b42601d 100644
--- a/Makefile
+++ b/Makefile
@@ -32,7 +32,7 @@ MANMODE=644
 
 # This is where the library file (tutorial) goes.
 #LIBDIR=/usr/local/share/$(name) # reno
-LIBDIR=${prefix}/lib/$(name)
+LIBDIR=${prefix}/share/doc/$(name)
 LIBRARY=-DLIBDIR=\"${LIBDIR}\"
 
 # Set SIMPLE for lex.c if you don't want arrow keys or lex.c blows up
diff --git a/abbrev.c b/abbrev.c
index a1c07ef..3bd3e89 100644
--- a/abbrev.c
+++ b/abbrev.c
@@ -19,10 +19,15 @@
 #include <stdio.h>
 #include <stdlib.h>
 #include <ctype.h>
+#include <curses.h>
+#include <unistd.h>
 #include "sc.h"
 
 static	struct abbrev *abbr_base;
 
+int are_abbrevs(void);
+
+
 void
 add_abbr(char *string)
 {
@@ -87,7 +92,7 @@ add_abbr(char *string)
 	    }
     }
     
-    if (expansion == NULL)
+    if (expansion == NULL){
 	if ((a = find_abbr(string, strlen(string), &prev))) {
 	    error("abbrev \"%s %s\"", a->abbr, a->exp);
 	    return;
@@ -95,6 +100,7 @@ add_abbr(char *string)
 	    error("abreviation \"%s\" doesn't exist", string);
 	    return;
 	}
+    }
  
     if (find_abbr(string, strlen(string), &prev))
 	del_abbr(string);
@@ -122,7 +128,7 @@ void
 del_abbr(char *abbrev)
 {
     struct abbrev *a;
-    struct abbrev **prev;
+    struct abbrev **prev=0;
 
     if (!(a = find_abbr(abbrev, strlen(abbrev), prev))) 
 	return;
diff --git a/cmds.c b/cmds.c
index d72469d..fdb591f 100644
--- a/cmds.c
+++ b/cmds.c
@@ -478,7 +478,7 @@ yankrow(int arg)
     int i, qtmp;
     char buf[50];
     struct frange *fr;
-    struct ent *obuf;
+    struct ent *obuf=0;
 
     if ((fr = find_frange(currow, curcol)))
 	rs = fr->or_right->row - currow + 1;
@@ -535,7 +535,7 @@ yankcol(int arg)
     int cs = maxcol - curcol + 1;
     int i, qtmp;
     char buf[50];
-    struct ent *obuf;
+    struct ent *obuf=0;
 
     if (cs - arg < 0) {
     	cs = cs > 0 ? cs : 0;
@@ -810,7 +810,7 @@ pullcells(int to_insert)
 
     if (to_insert == 'r') {
 	insertrow(numrows, 0);
-	if (fr = find_frange(currow, curcol))
+	if ((fr = find_frange(currow, curcol)))
 	    deltac = fr->or_left->col - mincol;
 	else {
 	    for (i = 0; i < numrows; i++)
@@ -2279,7 +2279,7 @@ copye(register struct enode *e, int Rdelta, int Cdelta, int r1, int c1,
 	ret->e.r.right.vp = lookat(newrow, newcol);
 	ret->e.r.right.vf = e->e.r.right.vf;
     } else {
-	struct enode *temprange;
+	struct enode *temprange=0;
 
 	if (freeenodes) {
 	    ret = freeenodes;
@@ -2337,8 +2337,7 @@ copye(register struct enode *e, int Rdelta, int Cdelta, int r1, int c1,
 		break;
 	    case 'f':
 	    case 'F':
-		if (range && ret->op == 'F' ||
-			!range && ret->op == 'f')
+		if ((range && ret->op == 'F') || (!range && ret->op == 'f'))
 		    Rdelta = Cdelta = 0;
 		ret->e.o.left = copye(e->e.o.left, Rdelta, Cdelta,
 			r1, c1, r2, c2, transpose);
@@ -2798,7 +2797,7 @@ void
 write_cells(register FILE *f, int r0, int c0, int rn, int cn, int dr, int dc)
 {
     register struct ent **pp;
-    int r, c, rs, cs, mf;
+    int r, c, rs=0, cs=0, mf;
     char *dpointptr;
 
     mf = modflg;
@@ -2861,12 +2860,12 @@ writefile(char *fname, int r0, int c0, int rn, int cn)
 	if ((plugin = findplugin(p+1, 'w')) != NULL) {
 	    if (!plugin_exists(plugin, strlen(plugin), save + 1)) {
 		error("plugin not found");
-		return;
+		return -1;
 	    }
 	    *save = '|';
 	    if ((strlen(save) + strlen(fname) + 20) > PATHLEN) {
 		error("Path too long");
-		return;
+		return -1;
 	    }
 	    sprintf(save + strlen(save), " %s%d:", coltoa(c0), r0);
 	    sprintf(save + strlen(save), "%s%d \"%s\"", coltoa(cn), rn, fname);
@@ -2883,13 +2882,14 @@ writefile(char *fname, int r0, int c0, int rn, int cn)
     }
 #endif /* VMS */
 
-    if (*fname == '\0')
+    if (*fname == '\0'){
 	if (isatty(STDOUT_FILENO) || *curfile != '\0')
 	    fname = curfile;
 	else {
 	    write_fd(stdout, r0, c0, rn, cn);
 	    return (0);
 	}
+    }
 
 #ifdef MSDOS
     namelen = 12;
@@ -2981,12 +2981,12 @@ readfile(char *fname, int eraseflg)
 	if ((plugin = findplugin(p+1, 'r')) != NULL) {
 	    if (!(plugin_exists(plugin, strlen(plugin), save + 1))) {
 		error("plugin not found");
-		return;
+		return -1;
 	    }
 	    *save = '|';
 	    if ((strlen(save) + strlen(fname) + 2) > PATHLEN) {
 		error("Path too long");
-		return;
+		return -1;
 	    }
 	    sprintf(save + strlen(save), " \"%s\"", fname);
 	    eraseflg = 0;
diff --git a/color.c b/color.c
index ee229fb..2a99a7d 100644
--- a/color.c
+++ b/color.c
@@ -19,6 +19,7 @@
 
 #include <curses.h>
 #include <ctype.h>
+#include <unistd.h>
 #include "sc.h"
 
 /* a linked list of free [struct ent]'s, uses .next as the pointer */
@@ -30,6 +31,8 @@ static struct crange	*color_base;
 void
 initcolor(int colornum)
 {
+    use_default_colors();
+
     if (!colornum) {
 	int i;
 
diff --git a/frame.c b/frame.c
index 8a226d7..ac5e995 100644
--- a/frame.c
+++ b/frame.c
@@ -18,6 +18,9 @@
 
 #include <stdio.h>
 #include <ctype.h>
+#include <stdlib.h>
+#include <curses.h>
+#include <unistd.h>
 #include "sc.h"
 
 static struct frange *frame_base;
diff --git a/help.c b/help.c
index 60767c3..727a484 100644
--- a/help.c
+++ b/help.c
@@ -11,6 +11,7 @@ char	*header = " Quick Reference";
 char	*revision = "$Revision: 7.16 $";
 #else
 #include <curses.h>
+#include <unistd.h>
 #include "sc.h"
 #endif /* QREF */
 
diff --git a/interp.c b/interp.c
index ec9fd53..978d049 100644
--- a/interp.c
+++ b/interp.c
@@ -1572,12 +1572,12 @@ void
 copy(struct ent *dv1, struct ent *dv2, struct ent *v1, struct ent *v2)
 {
     struct ent *p;
-    struct ent *n;
+/*    struct ent *n;*/
     static int minsr = -1, minsc = -1;
     static int maxsr = -1, maxsc = -1;
     int mindr, mindc;
     int maxdr, maxdc;
-    int vr, vc;
+/*    int vr, vc;*/
     int r, c;
     int deltar, deltac;
 
@@ -2066,7 +2066,7 @@ str_search(char *s, int firstrow, int firstcol, int lastrow, int lastcol,
 		    *line = '\0';
 	    }
 	}
-	if (!col_hidden[c])
+	if (!col_hidden[c]){
 	    if (gs.g_type == G_STR) {
 		if (p && p->label
 #if defined(REGCOMP)
@@ -2099,6 +2099,7 @@ str_search(char *s, int firstrow, int firstcol, int lastrow, int lastcol,
 #endif
 #endif
 		    break;
+	}
 	if (r == endr && c == endc) {
 	    error("String not found");
 #if defined(REGCOMP)
@@ -2471,13 +2472,11 @@ clearent(struct ent *v)
 int
 constant(register struct enode *e)
 {
-    return (
-	 e == NULL
+    return e == NULL
 	 || e->op == O_CONST
 	 || e->op == O_SCONST
-	 || e->op == 'm' && constant(e->e.o.left)
-	 || (
-	     e->op != O_VAR
+	 || (e->op == 'm' && constant(e->e.o.left))
+	 || (e->op != O_VAR
 	     && !(e->op & REDUCE)
 	     && constant(e->e.o.left)
 	     && constant(e->e.o.right)
@@ -2491,9 +2490,7 @@ constant(register struct enode *e)
 	     && e->op != LASTCOL
 	     && e->op != NUMITER
 	     && e->op != FILENAME
-             && optimize
-	)
-    );
+             && optimize );
 }
 
 void
diff --git a/lex.c b/lex.c
index c184fca..af18dce 100644
--- a/lex.c
+++ b/lex.c
@@ -34,6 +34,8 @@
 #include <signal.h>
 #include <setjmp.h>
 #include <ctype.h>
+#include <unistd.h>
+#include <math.h>
 #include "sc.h"
 
 #ifdef NONOTIMEOUT
@@ -107,7 +109,7 @@ int
 yylex()
 {
     char *p = line + linelim;
-    int ret;
+    int ret=0;
     static int isfunc = 0;
     static bool isgoto = 0;
     static bool colstate = 0;
@@ -326,7 +328,7 @@ plugin_exists(char *name, int len, char *path)
 	strcpy((char *)path, HomeDir);
 	strcat((char *)path, "/.sc/plugins/");
 	strncat((char *)path, name, len);
-	if (fp = fopen((char *)path, "r")) {
+	if ((fp = fopen((char *)path, "r"))) {
 	    fclose(fp);
 	    return 1;
 	}
@@ -334,7 +336,7 @@ plugin_exists(char *name, int len, char *path)
     strcpy((char *)path, LIBDIR);
     strcat((char *)path, "/plugins/");
     strncat((char *)path, name, len);
-    if (fp = fopen((char *)path, "r")) {
+    if ((fp = fopen((char *)path, "r"))) {
 	fclose(fp);
 	return 1;
     }
diff --git a/range.c b/range.c
index ee2c16e..da4bdc8 100644
--- a/range.c
+++ b/range.c
@@ -18,6 +18,8 @@
 
 #include <stdio.h>
 #include <ctype.h>
+#include <unistd.h>
+#include <curses.h>
 #include "sc.h"
 
 static	struct range *rng_base;
diff --git a/sc.c b/sc.c
index 34e575f..62c8a6e 100644
--- a/sc.c
+++ b/sc.c
@@ -212,7 +212,7 @@ flush_saved()
 
     if (dbidx < 0)
 	return;
-    if (p = delbuf[dbidx]) {
+    if ((p = delbuf[dbidx])) {
 	scxfree(delbuffmt[dbidx]);
 	delbuffmt[dbidx] = NULL;
     }
@@ -845,7 +845,7 @@ main (int argc, char  **argv)
 			    break;
 			case 'C':
 			    color = !color;
-			    if (has_colors())
+			    if (has_colors()){
 				if (color) {
 				    attron(COLOR_PAIR(1));
 				    bkgd(COLOR_PAIR(1) | ' ');
@@ -853,6 +853,7 @@ main (int argc, char  **argv)
 				    attron(COLOR_PAIR(0));
 				    bkgd(COLOR_PAIR(0) | ' ');
 				}
+			    }
 			    error("Color %sabled.", color ? "en" : "dis");
 			    break;
 			case 'N':
diff --git a/sc.h b/sc.h
index 7522e20..0c08f32 100644
--- a/sc.h
+++ b/sc.h
@@ -612,6 +612,9 @@ extern	int  pagesize;	/* If nonzero, use instead of 1/2 screen height */
 extern	int rowlimit;
 extern	int collimit;
 
+void yankr(struct ent *v1, struct ent *v2);
+
+
 #if BSD42 || SYSIII
 
 #ifndef cbreak
diff --git a/screen.c b/screen.c
index 3f950ea..a53a18a 100644
--- a/screen.c
+++ b/screen.c
@@ -234,11 +234,12 @@ update(int anychanged)		/* did any cell really change in value? */
 	    i = stcol;
 	    lcols = 0;
 	    col = rescol + frcols;
-	    if (fr && stcol >= fr->or_left->col)
+	    if (fr && stcol >= fr->or_left->col){
 		if (stcol < fr->ir_left->col)
 		    i = fr->or_left->col;
 		else
 		    col += flcols;
+	    }
 	    for (; (col + fwidth[i] < cols-1 || col_hidden[i] || i < curcol) &&
 		    i < maxcols; i++) {
 		lcols++;
@@ -328,11 +329,12 @@ update(int anychanged)		/* did any cell really change in value? */
 	    i = stcol;
 	    lcols = 0;
 	    col = rescol + frcols;
-	    if (fr && stcol >= fr->or_left->col)
+	    if (fr && stcol >= fr->or_left->col){
 		if (stcol < fr->ir_left->col)
 		    i = fr->or_left->col;
 		else
 		    col += flcols;
+	    }
 	    for (; (col + fwidth[i] < cols-1 || col_hidden[i] || i < curcol) &&
 		    i < maxcols; i++) {
 		lcols++;
@@ -377,11 +379,12 @@ update(int anychanged)		/* did any cell really change in value? */
 	    i = strow;
 	    rows = 0;
 	    row = RESROW + fbrows;
-	    if (fr && strow >= fr->or_left->row)
+	    if (fr && strow >= fr->or_left->row){
 		if (strow < fr->ir_left->row)
 		    i = fr->or_left->row;
 		else
 		    row += ftrows;
+	    }
 	    for (; (row < lines || row_hidden[i] || i < currow) && i < maxrows;
 		    i++) {
 		rows++;
@@ -460,11 +463,12 @@ update(int anychanged)		/* did any cell really change in value? */
 	    i = strow;
 	    rows = 0;
 	    row = RESROW + fbrows;
-	    if (fr && strow >= fr->or_left->row)
+	    if (fr && strow >= fr->or_left->row){
 		if (strow < fr->ir_left->row)
 		    i = fr->or_left->row;
 		else
 		    row += ftrows;
+	    }
 	    for (; (row < lines || row_hidden[i] || i < currow) && i < maxrows;
 		    i++) {
 		rows++;
diff --git a/sort.c b/sort.c
index 61c8a1b..db49136 100644
--- a/sort.c
+++ b/sort.c
@@ -19,6 +19,8 @@
 #include <stdio.h>
 #include <ctype.h>
 #include <stdlib.h>
+#include <unistd.h>
+#include <curses.h>
 #include "sc.h"
 
 int compare(const void *row1, const void *row2);
diff --git a/vi.c b/vi.c
index 7963bcc..ba34b64 100644
--- a/vi.c
+++ b/vi.c
@@ -17,6 +17,8 @@
 #include <curses.h>
 #include <ctype.h>
 #include <stdlib.h>
+#include <unistd.h>
+#include <sys/wait.h>
 #include "sc.h"
 
 #if defined(REGCOMP)
@@ -40,7 +42,7 @@ void gotobottom();
 
 #define istext(a) (isalnum(a) || ((a) == '_'))
 
-#define bool	int
+/*#define bool	int*/
 #define true	1
 #define false	0
 
@@ -667,8 +669,10 @@ dotab()
     static struct range *nextmatch;
     int len;
 
-    if (linelim > 0 && isalnum(line[linelim-1]) || line[linelim-1] == '_' ||
-	    (completethis && line[linelim-1] == ' ')) {
+    if ((linelim > 0 && isalnum(line[linelim-1])) || 
+    	line[linelim-1] == '_' ||
+	(completethis && line[linelim-1] == ' ')) {
+
 	if (!completethis) {
 	    for (completethis = line + linelim - 1; isalnum(*completethis) ||
 		    *completethis == '_'; completethis--) /* */;
@@ -715,7 +719,7 @@ void
 showdr()
 {
     int			minsr, minsc, maxsr, maxsc;
-    char		*p;
+    /*char		*p;*/
     char		r[12];
     struct frange	*fr = find_frange(currow, curcol);
 
@@ -1566,7 +1570,7 @@ static void
 search_again(bool reverse)
 {
     int prev_match;
-    int found_it;
+    int found_it=0;
 #if !defined(REGCOMP) && !defined(RE_COMP) && !defined(REGCMP)
     char *look_here;
     int do_next;
@@ -1777,7 +1781,7 @@ to_char(int arg, int n)
 static void
 match_paren()
 {
-    register int i;
+    /*register int i;*/
     int nest = 1;
     int tmp = linelim;
 
diff --git a/vmtbl.c b/vmtbl.c
index 8fb6b90..6b556a3 100644
--- a/vmtbl.c
+++ b/vmtbl.c
@@ -16,6 +16,7 @@
 # include <curses.h>
 #endif /* PSC */
 
+#include <unistd.h>
 #include "sc.h"
 
 /*
diff --git a/xmalloc.c b/xmalloc.c
index 9889e43..0faf7ef 100644
--- a/xmalloc.c
+++ b/xmalloc.c
@@ -4,11 +4,12 @@
  */
 
 #include <curses.h>
+#include <stdlib.h>
 #include "sc.h"
 
-extern char	*malloc();
+/* extern char	*malloc();
 extern char	*realloc();
-extern void	free();
+extern void	free(); */
 void		fatal();
 
 #ifdef SYSV3

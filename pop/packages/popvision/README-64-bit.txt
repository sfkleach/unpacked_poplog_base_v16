Instructions kindly provided by Waldek Hebisch 6 Jul 2019, for converting
libraries for popvision and popneural for use on 64 bit poplog.

POPVISION

The directory 'packages/popvision/lib/bin/linux/' contains 32-bit
libraries which are not going to work on 64-bit machines.

As a quick workaround one can remove everything from

'packages/popvision/lib/bin/linux/' and from 'packages/popvision/lib' do
(using bash):

for A in *.c ; do gcc -O2 -fPIC -shared $A -o bin/linux/${A%c}so; done

to create libraries appropriate for current machine.

A better approach would use per architecture subdirectories like 'arm',
'i386' and 'x86_64', or maybe 'arm-linux', 'i386-linux' and 'x86_64-linux'
if we want to support more operating systems.  But that would require some
work to propagate information about architecture and use it when needed...

-------------------------------------------------------------------------------

POPNEURAL

Similarly, 'packages/neural/bin/pclinux' contains 32-bit libraries.
Again one needs to remove them.  Then after changing directory
to 'packages/neural/src/c' the following

for A in *.c ; do gcc -O2 -fPIC -shared $A -o ../../bin/pclinux/${A%c}so; done

will create libraries for current machine.

To load 'mlp' I also needed the diff below (poplog_base
defines 'bytevec' and 'ushortvec').  But results
still look wrong...

--- packages/popvision/lib/array_random.p   1998-08-13 13:46:41.000000000 +0000
+++ packages/popvision/lib/array_random.p   2019-07-06 23:23:38.859218572 +0000
@@ -47,7 +47,7 @@
     (seed >> shift) /* -> s3 */;
 enddefine;

-defclass lconstant ushortvec :ushort;
+;;; defclass lconstant ushortvec :ushort;
 lconstant seedvec = initushortvec(3),
     shortbits = 2**SIZEOFTYPE(:ushort,:1) - 1;

--- packages/popvision/lib/mlp.p    2000-03-02 10:50:55.000000000 +0000
+++ packages/popvision/lib/mlp.p    2019-07-06 23:25:32.099069863 +0000
@@ -89,7 +89,7 @@
     (seed >> shift) /* -> s3 */;
 enddefine;

-defclass lconstant ushortvec :ushort;
+;;; defclass lconstant ushortvec :ushort;
 lconstant seedvec = initushortvec(3),
     shortbits = 2**SIZEOFTYPE(:ushort,:1) - 1;

--- packages/popvision/lib/newbytearray.p   2003-07-15 08:36:48.000000000 +0000
+++ packages/popvision/lib/newbytearray.p   2019-07-06 23:22:05.831409167 +0000
@@ -12,7 +12,7 @@
 uses popvision
 uses oldarray

-defclass bytevec :byte;
+;;; defclass bytevec :byte;

 define newbytearray = newanyarray(% bytevec_key %); enddefine;

--
                              Waldek Hebisch
Steve Leach adds:
I needed this further one before I could run mkpopvision.


--- lib/arraylookup.p-  2018-04-21 09:10:06.000000000 -0400
+++ lib/arraylookup.p   2019-07-11 15:05:25.188191118 -0400
@@ -64,9 +64,9 @@
     .arrayvector.issfloatvec
 enddefine;

-define lconstant isbytevec(/* v */) /* -> result */ with_nargs 1;
-    .datakey.class_spec == 8
-enddefine;
+;;; define lconstant isbytevec(/* v */) /* -> result */ with_nargs 1;
+;;;     .datakey.class_spec == 8
+;;; enddefine;

 define lconstant isbytearr(/* arr */) /* -> result */ with_nargs 1;
     .arrayvector.isbytevec

# nim-sophia

Wrapper for [Sophia 2.1](http://sophia.systems/) generated via c2nim.

The sophia.h is slightly modified, you can regenerate via makenim.sh.

Run "nim c -r testit.nim" to make sure the binding works.

Remember to enable --threads:on for your Nim program, otherwise it will fail
to load libsophia.

If you decide to not link dynamically (Sophia is not available yet in easy
packages AFAICT) then just copy libsophia.a to your project and compile like:

nim c --dynlibOverride:libsophia --passL:libsophia.a testit.nim


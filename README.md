# text-icu-static-example

Examples of static linking with [icu][icu].

## C example

Directory `test` contains example C program that converts input string to UTF-16
ICU representation and prints it.

[How to use ICU][how-to-use-icu] manual page suggests to use `pkg-config` for
configuration options. The command should look like:

``` bash
gcc -static -pthread test.c -o test $(pkg-config --static --cflags --libs icu-io)
```

But it fails with multiple errors about the undefined references:

```
/nix/store/2h1il2pyfh20kc5rh7vnp5a564alxr21-icu4c-59.1-static/lib/libicuuc.a(putil.ao): In function `uprv
_dl_open_59':
(.text+0x1c52): warning: Using 'dlopen' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/nix/store/2h1il2pyfh20kc5rh7vnp5a564alxr21-icu4c-59.1-static/lib/libicui18n.a(coll.ao): In function `icu_59::initAvailableLocaleList(UErrorCode&)':
(.text+0x1626): undefined reference to `__cxa_throw_bad_array_new_length'
/nix/store/2h1il2pyfh20kc5rh7vnp5a564alxr21-icu4c-59.1-static/lib/libicui18n.a(coll.ao):(.data.rel.ro._ZTIN6icu_598CollatorE[_ZTIN6icu_598CollatorE]+0x0): undefined reference to `vtable for __cxxabiv1::__si_class_type_info'
/nix/store/2h1il2pyfh20kc5rh7vnp5a564alxr21-icu4c-59.1-static/lib/libicui18n.a(coll.ao):(.data.rel.ro._ZTIN6icu_5915CollatorFactoryE[_ZTIN6icu_5915CollatorFactoryE]+0x0):
undefined reference to `vtable for __cxxabiv1::__si_class_type_info'
...
```

The problem is with the ICU pkg-config configuration. It lacks the `-lstdc++`
c++ runtime, as it was found on the [buildroot mailing list][buildroot-mailing-list].

 ``` bash
$ pkg-config --static --cflags --libs icu-io
-licuio -licui18n -licuuc -licudata -lpthread -ldl -lm
 ```

For the final command we will use `nix-shell` to put static glibc and icu
components on the linker path:

``` bash
$ nix-shell test.nix --command 'gcc -static -pthread test.c -o test $(pkg-config
--static --cflags --libs icu-io) -lstdc++'
test.c: In function ‘main’:
test.c:12:5: warning: ignoring return value of ‘fgets’, declared with attribute warn_unused_result [-Wunused-result]
     fgets(buffer, BUFFERSIZE, stdin);
     ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/nix/store/2h1il2pyfh20kc5rh7vnp5a564alxr21-icu4c-59.1-static/lib/libicuuc.a(putil.ao): In function `uprv_dl_open_59':
(.text+0x1c52): warning: Using 'dlopen' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking

$ ldd test
	not a dynamic executable
```

There is also CMake build that can be invoked with:

``` bash
$ nix-bulid test.nix
```

## Haskell text-icu

In the previous section we were able to build a static C executable. The same
approach should work with Haskell.

### Cabal

File `default.nix` describes a build for the static `Normalize.hs` executable
with Cabal.

```
$ nix-build .
...
[1 of 1] Compiling Main             ( Normalize.hs, dist/build/text-icu-normalize/text-icu-normalize-tmp/Main.o )
Linking dist/build/text-icu-normalize/text-icu-normalize ...
/nix/store/dpd9k7q08wvb6d1a67h66amcazv5sy39-ghc-8.4.3/lib/ghc-8.4.3/rts/libHSrts.a(Linker.o): In function `internal_dlopen':
Linker.c:(.text.internal_dlopen+0x7): warning: Using 'dlopen' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/nix/store/2h1il2pyfh20kc5rh7vnp5a564alxr21-icu4c-59.1-static/lib/libicuuc.a(uniset_props.ao): In function `icu_59::UnicodeSet::applyPattern(icu_59::RuleCharacterIterator&, icu_59::SymbolTable const*, icu_59::UnicodeString&, unsigned int, icu_59::UnicodeSet& (icu_59::UnicodeSet::*)(int), UErrorCode&)':
(.text+0x1792): undefined reference to `__dynamic_cast'
/nix/store/2h1il2pyfh20kc5rh7vnp5a564alxr21-icu4c-59.1-static/lib/libicui18n.a(coll.ao): In function `icu_59::Collator::makeInstance(icu_59::Locale const&, UErrorCode&)':
(.text+0x903): undefined reference to `icu_59::SharedObject::removeRef(signed char) const'
/nix/store/2h1il2pyfh20kc5rh7vnp5a564alxr21-icu4c-59.1-static/lib/libicui18n.a(coll.ao): In function `icu_59::initAvailableLocaleList(UErrorCode&)':
(.text+0x1626): undefined reference to `__cxa_throw_bad_array_new_length'
.
.
.
collect2: error: ld returned 1 exit status
`cc' failed in phase `Linker'. (Exit code: 1)
builder for '/nix/store/ix8h8clyj8q3v6dq416v5j7yp5igipf3-text-icu-static-example-0.1.0.0.drv' failed with exit code 1
error: build of '/nix/store/ix8h8clyj8q3v6dq416v5j7yp5igipf3-text-icu-static-example-0.1.0.0.drv' failed
```

The error looks very similar to the one with the C example before we passed
`-lstdc++`.

### GHC

It's hard to say what's going on under the hood of Cabal build, so we'll try to
build a static `Normalize.hs` executable using `ghc` only.

First we need to build the `Normalize.o` object file and then link it with the
dependencies.

#### Build Normalize.o

To build the object file we need to pass `-c` option to `ghc`:

``` bash
ghc --help | grep 'stop after'
    -E		stop after generating preprocessed, de-litted Haskell
    -C		stop after generating C (.hc output)
    -S		stop after generating assembler (.s output)
    -c		stop after generating object files (.o output)
```

the command should look like this:

``` bash
$ ghc -c Normalize.hs

Normalize.hs:3:1: error:
    Could not find module ‘Data.Text.ICU.Normalize’
    Use -v to see a list of the files searched for.
  |
3 | import qualified Data.Text.ICU.Normalize

```

We also need a haskell dependencies. We can use package-db from the
unsuccessful `nix-build --keep-failed .` run.

``` bash
$ nix-build --keep-failed .
...
note: keeping build directory '/tmp/nix-build-text-icu-static-example-0.1.0.0.drv-0'
builder for '/nix/store/9vgc3m7jd3wssyfnacgrxddw70rpdy77-text-icu-static-example-0.1.0.0.drv' failed with exit code 1
error: build of '/nix/store/9vgc3m7jd3wssyfnacgrxddw70rpdy77-text-icu-static-example-0.1.0.0.drv' failed
```

!! Note that directory `/tmp/nix-build-text-icu-static-example-0.1.0.0.drv-0`
contains package-db with `text-icu` built against a static `icu`
library. Ordinary package-db from i.e. `$HOME/.cabal` won't work in this case.

``` bash
ghc
-package-db=/tmp/nix-build-text-icu-static-example-0.1.0.0.drv-0/package.conf.d
-c Normalize.hs
```

We got the object file `Normalize.o`.

#### Build static executable

Now we should link everything together.

Roughly, the command to link `Normalize.o` into a static executable should look
like this:

``` bash
ghc -optl=-static -optl=-pthread Normalize.o -licuio -licui18n -licuuc -licudata
-lpthread -ldl -lm -lstdc++ -lHStext-1.2.3.0 -lHStext-icu-0.7.0.1
```

The command above links together `Normalize.o`, static components of `icu`
library, `text` and `text-icu` haskell libraries.

In the real world we need to find the exact names and pathes in
`/tmp/nix-build-text-icu-static-example-0.1.0.0.drv-0/cabal-configure.log`
log file, and pass them with the extra lib dirs to the command above.

I was able to build a static `a.out` executable with the following command:

``` bash
$ /nix/store/dpd9k7q08wvb6d1a67h66amcazv5sy39-ghc-8.4.3/bin/ghc -optl=-pthread -optl=-static -L/nix/store/m9qzh7zv0pvkarprpda5zy68myq43iqs-glibc-2.26-131-static/lib -L/nix/store/2h1il2pyfh20kc5rh7vnp5a564alxr21-icu4c-59.1-static/lib -L/nix/store/p5b8ashcchqzwlv1vcbzq98cqmfmvfky-gmp-6.1.2/lib -L/nix/store/dpd9k7q08wvb6d1a67h66amcazv5sy39-ghc-8.4.3/lib/ghc-8.4.3/text-1.2.3.0 Normalize.o /nix/store/jvw92vblnrsqhfm3ik5lj47jq1yp625q-text-icu-0.7.0.1/lib/ghc-8.4.3/text-icu-0.7.0.1/libHStext-icu-0.7.0.1-GQ0DM6OBTErByT1EmU06SY.a  -licuio -licui18n -licuuc -licudata -lpthread -ldl -lm -lstdc++ -lHStext-1.2.3.0
/nix/store/2h1il2pyfh20kc5rh7vnp5a564alxr21-icu4c-59.1-static/lib/libicuuc.a(putil.ao): In function `uprv_dl_open_59':
(.text+0x1c52): warning: Using 'dlopen' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
$ ldd a.out
	not a dynamic executable
$ ./a.out
привет
привет
```

#### Back to Cabal

To see what's going on inside the Cabal build, we can add `--ghc-option=-v` to
configure options. File `nix-bulid-verbose.log` contains verbose output.


> Linking dist/build/text-icu-normalize/text-icu-normalize ...
> Created temporary directory: /tmp/nix-build-text-icu-static-example-0.1.0.0.drv-1/ghc13939_0
> *** C Compiler:
> /nix/store/9y2f87qb1djmpjs1gxl6smfkpl581waa-gcc-wrapper-7.3.0/bin/cc -fno-stack-protector -DTABLES_NEXT_TO_CODE -c /tmp/nix-build-text-icu-static-example-0.1.0.0.drv-1/ghc13939_0/ghc_1.c -o /tmp/nix-build-text-icu-static-example-0.1.0.0.drv-1/ghc13939_0/ghc_2.o -no-pie -I/nix/store/dpd9k7q08wvb6d1a67h66amcazv5sy39-ghc-8.4.3/lib/ghc-8.4.3/include
> *** C Compiler:
> /nix/store/9y2f87qb1djmpjs1gxl6smfkpl581waa-gcc-wrapper-7.3.0/bin/cc -fno-stack-protector -DTABLES_NEXT_TO_CODE -c /tmp/nix-build-text-icu-static-example-0.1.0.0.drv-1/ghc13939_0/ghc_4.s -o /tmp/nix-build-text-icu-static-example-0.1.0.0.drv-1/ghc13939_0/ghc_5.o
> *** Linker:
> /nix/store/9y2f87qb1djmpjs1gxl6smfkpl581waa-gcc-wrapper-7.3.0/bin/cc -fno-stack-protector -DTABLES_NEXT_TO_CODE '-Wl,--hash-size=31' -Wl,--reduce-memory-overheads -Wl,--no-as-needed -static -pthread -L/nix/store/m9qzh7zv0pvkarprpda5zy68myq43iqs-glibc-2.26-131-static/lib -L/nix/store/p5b8ashcchqzwlv1vcbzq98cqmfmvfky-gmp-6.1.2/lib -L/nix/store/2h1il2pyfh20kc5rh7vnp5a564alxr21-icu4c-59.1-static/lib -licui18n -licuio -licuuc -licudata -ldl -lm '-lstdc++' -o dist/build/text-icu-normalize/text-icu-normalize -lm -no-pie -Wl,--gc-sections dist/build/text-icu-normalize/text-icu-normalize-tmp/Main.o -L/nix/store/54cwjh1lsmjpk2cbs43gw89w4zhk3ybb-ncurses-6.0-20171125/lib -L/nix/store/wc2ll61lypsv9yig6mvy73c0lw1dp15a-gmp-6.1.2/lib -licui18n -licuio -licuuc -licudata -ldl -lm '-lstdc++' -L/nix/store/0yrad0gmb1840r77scxn4gikpbjgyabv-text-icu-0.7.0.1/lib/ghc-8.4.3/text-icu-0.7.0.1 -L/nix/store/54cwjh1lsmjpk2cbs43gw89w4zhk3ybb-ncurses-6.0-20171125/lib -L/nix/store/wc2ll61lypsv9yig6mvy73c0lw1dp15a-gmp-6.1.2/lib -L/nix/store/0al5181s03bylmsvrwj2lnvvlsqvdbcl-icu4c-59.1-dev/lib -L/nix/store/zvm4zywflp9x8q2zrs2506c8jcjp6xvr-icu4c-59.1/lib -L/nix/store/2h1il2pyfh20kc5rh7vnp5a564alxr21-icu4c-59.1-static/lib -L/nix/store/dpd9k7q08wvb6d1a67h66amcazv5sy39-ghc-8.4.3/lib/ghc-8.4.3/text-1.2.3.0 -L/nix/store/dpd9k7q08wvb6d1a67h66amcazv5sy39-ghc-8.4.3/lib/ghc-8.4.3/binary-0.8.5.1 -L/nix/store/dpd9k7q08wvb6d1a67h66amcazv5sy39-ghc-8.4.3/lib/ghc-8.4.3/containers-0.5.11.0 -L/nix/store/dpd9k7q08wvb6d1a67h66amcazv5sy39-ghc-8.4.3/lib/ghc-8.4.3/bytestring-0.10.8.2 -L/nix/store/dpd9k7q08wvb6d1a67h66amcazv5sy39-ghc-8.4.3/lib/ghc-8.4.3/deepseq-1.4.3.0 -L/nix/store/dpd9k7q08wvb6d1a67h66amcazv5sy39-ghc-8.4.3/lib/ghc-8.4.3/array-0.5.2.0 -L/nix/store/dpd9k7q08wvb6d1a67h66amcazv5sy39-ghc-8.4.3/lib/ghc-8.4.3/base-4.11.1.0 -L/nix/store/dpd9k7q08wvb6d1a67h66amcazv5sy39-ghc-8.4.3/lib/ghc-8.4.3/integer-gmp-1.0.2.0 -L/nix/store/dpd9k7q08wvb6d1a67h66amcazv5sy39-ghc-8.4.3/lib/ghc-8.4.3/ghc-prim-0.5.2.0 -L/nix/store/dpd9k7q08wvb6d1a67h66amcazv5sy39-ghc-8.4.3/lib/ghc-8.4.3/rts /tmp/nix-build-text-icu-static-example-0.1.0.0.drv-1/ghc13939_0/ghc_2.o /tmp/nix-build-text-icu-static-example-0.1.0.0.drv-1/ghc13939_0/ghc_5.o -Wl,-u,base_GHCziTopHandler_runIO_closure -Wl,-u,base_GHCziTopHandler_runNonIO_closure -Wl,-u,ghczmprim_GHCziTuple_Z0T_closure -Wl,-u,ghczmprim_GHCziTypes_True_closure -Wl,-u,ghczmprim_GHCziTypes_False_closure -Wl,-u,base_GHCziPack_unpackCString_closure -Wl,-u,base_GHCziWeak_runFinalizzerBatch_closure -Wl,-u,base_GHCziIOziException_stackOverflow_closure -Wl,-u,base_GHCziIOziException_heapOverflow_closure -Wl,-u,base_GHCziIOziException_allocationLimitExceeded_closure -Wl,-u,base_GHCziIOziException_blockedIndefinitelyOnMVar_closure -Wl,-u,base_GHCziIOziException_blockedIndefinitelyOnSTM_closure -Wl,-u,base_GHCziIOziException_cannotCompactFunction_closure -Wl,-u,base_GHCziIOziException_cannotCompactPinned_closure -Wl,-u,base_GHCziIOziException_cannotCompactMutable_closure -Wl,-u,base_ControlziExceptionziBase_absentSumFieldError_closure -Wl,-u,base_ControlziExceptionziBase_nonTermination_closure -Wl,-u,base_ControlziExceptionziBase_nestedAtomically_closure -Wl,-u,base_GHCziEventziThread_blockedOnBadFD_closure -Wl,-u,base_GHCziConcziSync_runSparks_closure -Wl,-u,base_GHCziConcziIO_ensureIOManagerIsRunning_closure -Wl,-u,base_GHCziConcziIO_ioManagerCapabilitiesChanged_closure -Wl,-u,base_GHCziConcziSignal_runHandlersPtr_closure -Wl,-u,base_GHCziTopHandler_flushStdHandles_closure -Wl,-u,base_GHCziTopHandler_runMainIO_closure -Wl,-u,ghczmprim_GHCziTypes_Czh_con_info -Wl,-u,ghczmprim_GHCziTypes_Izh_con_info -Wl,-u,ghczmprim_GHCziTypes_Fzh_con_info -Wl,-u,ghczmprim_GHCziTypes_Dzh_con_info -Wl,-u,ghczmprim_GHCziTypes_Wzh_con_info -Wl,-u,base_GHCziPtr_Ptr_con_info -Wl,-u,base_GHCziPtr_FunPtr_con_info -Wl,-u,base_GHCziInt_I8zh_con_info -Wl,-u,base_GHCziInt_I16zh_con_info -Wl,-u,base_GHCziInt_I32zh_con_info -Wl,-u,base_GHCziInt_I64zh_con_info -Wl,-u,base_GHCziWord_W8zh_con_info -Wl,-u,base_GHCziWord_W16zh_con_info -Wl,-u,base_GHCziWord_W32zh_con_info -Wl,-u,base_GHCziWord_W64zh_con_info -Wl,-u,base_GHCziStable_StablePtr_con_info -Wl,-u,hs_atomic_add8 -Wl,-u,hs_atomic_add16 -Wl,-u,hs_atomic_add32 -Wl,-u,hs_atomic_add64 -Wl,-u,hs_atomic_sub8 -Wl,-u,hs_atomic_sub16 -Wl,-u,hs_atomic_sub32 -Wl,-u,hs_atomic_sub64 -Wl,-u,hs_atomic_and8 -Wl,-u,hs_atomic_and16 -Wl,-u,hs_atomic_and32 -Wl,-u,hs_atomic_and64 -Wl,-u,hs_atomic_nand8 -Wl,-u,hs_atomic_nand16 -Wl,-u,hs_atomic_nand32 -Wl,-u,hs_atomic_nand64 -Wl,-u,hs_atomic_or8 -Wl,-u,hs_atomic_or16 -Wl,-u,hs_atomic_or32 -Wl,-u,hs_atomic_or64 -Wl,-u,hs_atomic_xor8 -Wl,-u,hs_atomic_xor16 -Wl,-u,hs_atomic_xor32 -Wl,-u,hs_atomic_xor64 -Wl,-u,hs_cmpxchg8 -Wl,-u,hs_cmpxchg16 -Wl,-u,hs_cmpxchg32 -Wl,-u,hs_cmpxchg64 -Wl,-u,hs_atomicread8 -Wl,-u,hs_atomicread16 -Wl,-u,hs_atomicread32 -Wl,-u,hs_atomicread64 -Wl,-u,hs_atomicwrite8 -Wl,-u,hs_atomicwrite16 -Wl,-u,hs_atomicwrite32 -Wl,-u,hs_atomicwrite64 -lHStext-icu-0.7.0.1-GQ0DM6OBTErByT1EmU06SY -lHStext-1.2.3.0 -lHSbinary-0.8.5.1 -lHScontainers-0.5.11.0 -lHSbytestring-0.10.8.2 -lHSdeepseq-1.4.3.0 -lHSarray-0.5.2.0 -lHSbase-4.11.1.0 -lHSitneger-gmp-1.0.2.0 -lHSghc-prim-0.5.2.0 -lHSrts -lCffi -licuuc -licui18n -licudata -lgmp -lm -lrt -ldl

The linking is performed in several steps in the temporary directory which gets
deleted after the failure, so I was not able to reproduce these steps
locally.

At least we can see that all the flags including `-lstdc++` are passed to
linker.


[icu]: http://site.icu-project.org/
[how-to-use-icu]: http://userguide.icu-project.org/howtouseicu
[buildroot-mailing-list]: http://lists.busybox.net/pipermail/buildroot/2015-May/128867.html

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

Build with nix:

```
nix-build .
```


[icu]: http://site.icu-project.org/
[how-to-use-icu]: http://userguide.icu-project.org/howtouseicu
[buildroot-mailing-list]: http://lists.busybox.net/pipermail/buildroot/2015-May/128867.html

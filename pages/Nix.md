- > [Nix Pills](https://nixos.org/guides/nix-pills/)
- # Cheat sheet
	- **Find absolutely every dependency, recursively** to use that derivation:
		- ```sh
		  # See dependency list of whichever `man` is in PATH
		  $ nix-store -qR `which man`
		  $ nix-store -q --tree `which man`
		  $ nix-store -q --tree ~/.nix-profile
		  ```
- # [[Nix language]]
- # [[nix-shell]]
	- At the core of Nix is nix-shell, which wraps other shell (e.g. bash) with reproducible Nix environment
	- ## Ad-hoc shell
	  id:: 66099b33-641d-42b4-9bcd-1745273827bc
		- We can use nix-shell like other shell, but it comes with package management feature:
		- ```sh
		  # Enter a new shell environment with jq
		  $ nix-shell -p jq
		  ```
		- The shell command above installs `jq` if host system doesn't have one, and returns to a new shell environment with `jq`
		- Note that `jq` is not installed to your host system. It was only downloaded to nixstore and linked to some paths that allows it to be used in the nix-shell session
		- You can use `--run <shell_cmd>` to immediately execute a command in nix-shell without having to manually enter and exit the environment.
		- ```sh
		  # Use the new shell (with bat and ripgrep) and runs 'bat ... | ripgrep ..'
		  $ nix-shell -p bat ripgrep --run bat 'foo.txt' | ripgrep 'bar'
		  ```
		- We can specify exactly what will be available in the nix-shell environment, and even specify package versions explicitly with `-I`:
		- ```sh
		  # Enter a new shell, with specific git package (-I),
		  # Flag `--` pure also discards most current envs
		  # set on the system when running the command.
		  
		  $ nix-shell \
		  	-p git\                # Package(s) to include
		      --run "git --version"\ # Command to run
		      --pure\                # Discard most of host environment
		      -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/2a601aafdc5605a5133a2ca506a34a3a73377247.tar.gz
		      
		  # git version: 2.33.1
		  ```
	- ## Reproducible script
		- Let's say we have a normal shell script:
			- ```sh
			  #! /usr/bin/env bash
			  
			  curl https://github.com/NixOS/nixpkgs/releases.atom | xml2json | jq .
			  ```
			- This script has some pitfalls - it assumes the host has `curl`, `xml2json`, and `jq` installed
			- To fix that, we can make use of `nix-shell` compatibility with UNIX shebang:
			- ```sh
			  #!/usr/bin/env nix-shell
			  #! nix-shell -i bash --pure
			  #! nix-shell -p bash cacert curl jq python3Packages.xmljson
			  #! nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/2a601aafdc5605a5133a2ca506a34a3a73377247.tar.gz
			  
			  # Note The command `xml2json` is provided by the package
			  # `python3Packages.xmljson`
			  
			  curl https://github.com/NixOS/nixpkgs/releases.atom | xml2json | jq .
			  ```
			- `-i` defines the program to be used as interpreter of this script file
			- `-I` refers to a specific Git commit of the Nixpkgs repository. Explore packages at https://search.nixos.org
			- This means that the `nix-shell`-enabled version of script will always execute with the same package versions, everywhere, and the host system's environment will not pollute the script's executing
	- ## Declarative shell
		- Unlike [ad-hoc shell](((66099b33-641d-42b4-9bcd-1745273827bc))), which is great for running a command quickly but not permanently, Nix also allows us to compose/declare specification for shells.
		- If ad-hoc shell is "reproducible" command execution, declarative shell is instead a reproducible and mostly persistent shell environment
		- We declare the shell in a Nix file `shell.nix`. Sharing this Nix file allows everyone to reproduce our shell environment.
		- By default, nix-shell looks for `shell.nix` at CWD, and builds a new shell based on expression in that file
		- ### Quick intro to `shell.nix`
			- Let's create a simple Nix file for our declarative shell `shell.nix`:
			- ```nix
			  # File shell.nix
			  
			  let
			  
			    # We use a version of Nixpkgs pinned to a release branch,
			    # and explicitly set configuration options and overlays to
			    # avoid them being inadvertently overridden by global configuration.
			    
			    nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-23.11";
			    pkgs = import nixpkgs { config = {}; overlays = []; };
			  in
			  
			  # mkShellNoCC is a function that produces such an environment,
			  # but without a compiler toolchain.
			  
			  pkgs.mkShellNoCC {
			    packages = with pkgs; [
			      cowsay
			      lolcat
			    ];
			    
			    # Set environment in mkShellNoCC
			    SOME_ENV = "FOONIX";
			  }
			  ```
			- We can use `shellHook` to run a command before entering the interactive shell of our `shell.nix` environment:
			- ```nix
			  let
			   	nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-23.11";
			  	pkgs = import nixpkgs { config = {}; overlays = []; };
			  in
			  
			  pkgs.mkShellNoCC {
			   	packages = with pkgs; [
			  		cowsay
			  		lolcat
			  	];
			  
			  	GREETING = "Hello, Nix!";
			  
			  	shellHook = ''
			  	echo $GREETING | cowsay | lolcat
			  	'';
			  }
			  ```
		- ### Pinning Nixpkgs
			- Sometimes we may see the following:
			- ```nix
			  { pkgs ? import <nixpkgs> {}
			  
			  }:
			  
			  {
			  	# Some expression
			  }
			  ```
			- Here, `<nixpkgs>` are used to represent "some" Nix packages
			- However, using`<nixpkgs>` are not reproducible, because we did not pinpoint the exact version of Nixpkgs
			- The simplest way to pin Nixpkgs s to fetch the required Nixpkgs version as a tarball specified via the relevant Git commit hash:
			- ```nix
			  { pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/06278c77b5d162e62df170fec307e83f1812d94b.tar.gz") {}
			  
			  }:
			  
			  {
			  	# Some expression
			  }
			  ```
			- Normally, we pick Nixpkgs from the following sources:
				- Stable Nixpkgs, e.g. `nixos-21.05`, `nixos-23.11`, etc.
				- `nixos-unstable`
- # Nix profiles
	- `nix-env` is used to manage profiles and generations
	- Each user has their own profile, stored in `$HOME/.nix-profile` dir
	- Like `go.mod` or `package.json`, Nix profiles also have declarative *manifest* at `$HOME/.nix-profile/manifest.nix`
	- We can install a new *drv* to the user's profile by running `nix-env` as the user:
		- id:: 660c4eff-edb4-4cc2-952b-decace41fe13
		  ```sh
		  $ nix-env -i hello
		  installing 'hello-2.10'
		  building '/nix/store/0vqw0ssmh6y5zj48yg34gc6macr883xk-user-environment.drv'...
		  created 36 symlinks in user environment
		  ```
		- This generates a new *generation* of our user profile
	- Each user profile has their own "home Nix store", which is `$HOME/.nix_profile/bin`
		- e.g. the [installation of drv `hello-2.10`](((660c4eff-edb4-4cc2-952b-decace41fe13)))
		- The drv will first be installed to global Nix store, at `/nix/store/0vqw0ssmh6y5zj48yg34gc6macr883xk-user-environment.drv`
		- Nix then links the environment back from the Nix store to our home directory
	- We can list all generations of user profile with `nix-env --list-generations`
		- ```sh
		  $ nix-env --list-generations
		  1   2014-07-24 09:23:30
		  2   2014-07-25 08:45:01   (current)
		  ```
	- And we can see (query) what derivations are enabled in the profile with `nix-env -q`:
		- ```sh
		  $ nix-env -q
		  nix-2.1.3
		  hello-2.10
		  ```
		- Each of these drvs can be found in `$HOME/.nix_profile`
		- They all point to some where in Nix store
			- To list the drv store path, use `nix-env -q --out-path`
	- Usually, user profile drvs have greater priority than system drvs, that is the user profile drv of a *name* (like `man-db` or `firefox`) will be used, and not the system drv with the same name
	- Profile generations can be rolled back with `nix-env --rollback`
		- ```sh
		  $ nix-env --rollback
		  switching from generation 3 to 2
		  ```
		- Or we can use `-G` to specify target rollback generation:
		- ```sh
		  $ nix-env --rollback -G 3
		  switching from generation 2 to 3
		  ```
- # [[Nix modules]]
- # Packaging with Nix
	- Packages in this sense can be either:
		- A collection of files (like with other package managers)
		- A Nix expression that evaluates to such a collection of files
	- Nixpkgs Standard Environment (`stdenv`) provides functions to create derivations (or *packages*)
	- ## Simple GNU hello from FTP
	  id:: 660d068e-e0b8-48a4-977f-0b0ed5a3641b
		- Let's start with a skeleton code which produces nothing:
		- ```nix
		  { stdenv }:
		  stdenv.mkDerivation { };
		  ```
		- To make it build anything, we must assign attrs in the argument to `stdenv.mkDerivation`:
			- We need `pname` and `version` at minimum
			- We also tell `mkDerivation` to fetch source archive from some FTP mirrror
				- But Nix requires checksums when fetching
				- So we supply the fake one (`lib.fakeSha256`, which is zeroed bytes)
				- After the 1st run, Nix will report checksum mismatch errors (actual checksum vs `lib.fakeSha256`)
				- We can then copy the actual checksum from the error message and replace the fake one with the actual checksum
		- ```nix
		  # hello.nix
		  {
		    lib,
		    stdenv,
		    fetchzip,
		  }:
		  
		  stdenv.mkDerivation {
		    pname = "hello";
		    version = "2.12.1";
		  
		    src = fetchzip {
		      url = "https://ftp.gnu.org/gnu/hello/hello-2.12.1.tar.gz";
		      sha256 = lib.fakeSha256;
		    };
		  }
		  ```
		- Now run `nix-build` on `hello.nix`, which will err
		- ```sh
		  $ nix-build hello.nix
		  error: cannot evaluate a function that has an argument without a value ('lib')
		         Nix attempted to evaluate a function as a top level expression; in
		         this case it must have its arguments supplied either by default
		         values, or passed explicitly with '--arg' or '--argstr'. See
		         https://nix.dev/manual/nix/2.18/language/constructs.html#functions.
		  
		         at /home/nix-user/hello.nix:2:3:
		  
		              1| # hello.nix
		              2| { lib
		               |   ^
		              3| , stdenv
		  ```
		- This is because Nix expr in `hello.nix` is a function, so we must give it some arguments
		- This is because `hello.nix` needs utilities `lib`, `stdenv`, and `fetchzip`, which are provided by Nixpkgs.
		- The conventional way to do this is to instead create another `default.nix` that wraps `hello.nix` with setup code (import Nixpkgs and function call to `hello.nix`)
		- ```nix
		  # default.nix
		  let
		    nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-22.11";
		    pkgs = import nixpkgs { config = {}; overlays = []; };
		  in
		  {
		  
		    # callPackage automatically passes attributes from pkgs to the given function,
		    # if they match attributes required by that function’s argument attribute set.
		    #
		    # In this case, callPackage will supply lib, stdenv, and fetchzip to the function
		    # defined in hello.nix.
		    
		    hello = pkgs.callPackage ./hello.nix { };
		  }
		  ```
		- Now we can run `nix-build` at the CWD, and Nix will start evaluating `default.nix` which imports `hello.nix`
		- Nix will then downloads the source archive, and will complain about invalid checksum (due to the fake checksum we supplied earlier)
		- ```sh
		  nix-build -A hello
		  error:
		  ...
		         … while evaluating attribute 'src' of derivation 'hello'
		           at /home/nix-user/hello.nix:9:3:
		              8|
		              9|   src = fetchzip {
		               |   ^
		             10|     url = "https://ftp.gnu.org/gnu/hello/hello-2.12.1.tar.gz";
		         error: hash mismatch in file downloaded from 'https://ftp.gnu.org/gnu/hello/hello-2.12.1.tar.gz':
		           specified: sha256:0000000000000000000000000000000000000000000000000000
		           got:       sha256:0xw6cr5jgi1ir13q6apvrivwmmpr5j8vbymp0x6ll0kcv6366hnn
		  ```
		- Now we can copy the correct checksum from `got`, and replace the fake one with it in `hello.nix`
		- ```nix
		  # hello.nix
		  {
		    lib,
		    stdenv,
		    fetchzip,
		  }:
		  
		  stdenv.mkDerivation {
		    pname = "hello";
		    version = "2.12.1";
		  
		    src = fetchzip {
		      url = "https://ftp.gnu.org/gnu/hello/hello-2.12.1.tar.gz";
		      sha256 = "0xw6cr5jgi1ir13q6apvrivwmmpr5j8vbymp0x6ll0kcv6366hnn";
		    };
		  }
		  ```
		- Our last `nix-build` run only downloads the archive, but Nix did not progress to build due to checksum error. Now that we have good checksum, we'll have to rerun `nix-build`
		- ```sh
		  nix-build -A hello
		  this derivation will be built:
		    /nix/store/rbq37s3r76rr77c7d8x8px7z04kw2mk7-hello.drv
		  building '/nix/store/rbq37s3r76rr77c7d8x8px7z04kw2mk7-hello.drv'...
		  ...
		  configuring
		  ...
		  configure: creating ./config.status
		  config.status: creating Makefile
		  ...
		  building
		  ```
		- Nix will write build result to Nix store and symlink it to `./result`
		- So our hello program in `./result/bin/hello` is just another symlink to Nix store.
	- ## Package from GitHub with Nixpkgs dependencies
		- > This example continues from [previous GNU hello example](((660d068e-e0b8-48a4-977f-0b0ed5a3641b)))
		- This time we'll package `icat` from GitHub with expression in `icat.nix`
		- First, let's update our `default.nix` to import our (not-yet-existent) `icat.nix`
		- ```nix
		  # default.nix
		  
		  let
		    nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-22.11";
		    pkgs = import nixpkgs { config = {}; overlays = []; };
		  in
		  {
		    hello = pkgs.callPackage ./hello.nix { };
		    icat = pkgs.callPackage ./icat.nix { };
		  }
		  ```
		- And populate `icat.nix`
			- We know that `icat` is from GitHub, so we use `fetchFromGitHub`
			- `fetchFromGitHub { owner = "soyart"; repo = "logseq-notes"; }` points to `github.com/soyart/logseq-notes`
			- We must specify a revision (`rev`), like a tag or a specific commit, e.g. `rev = "v0.5";`
			- We must also specify hash ahead of time
				- This time, instead of using `lib.fakeSha256`, we'll instead use `nix-prefetch-url`
				- We'll fetch a `tar.gz` archive from GitHub Archive, and supply `--unpack` because we need hash of the content of the tarball, not the tarball itself
				- ```sh
				  nix-prefetch-url --unpack https://github.com/atextor/icat/archive/refs/tags/v0.5.tar.gz --type sha256
				  path is '/nix/store/p8jl1jlqxcsc7ryiazbpm7c1mqb6848b-v0.5.tar.gz'
				  0wyy2ksxp95vnh71ybj1bbmqd5ggp13x3mk37pzr99ljs9awy8ka
				  ```
				- Now we can use hash `"0wyy2ksxp95vnh71ybj1bbmqd5ggp13x3mk37pzr99ljs9awy8ka"` for `fetchFromGitHub`
		- ```nix
		  # icat.nix
		  {
		    lib,
		    stdenv,
		    fetchFromGitHub,
		  }:
		  
		  stdenv.mkDerivation {
		    pname = "icat";
		    version = "v0.5";
		  
		    src = fetchFromGitHub {
		      owner = "atextor";
		      repo = "icat";
		      rev = "v0.5";
		      sha256 = "0wyy2ksxp95vnh71ybj1bbmqd5ggp13x3mk37pzr99ljs9awy8ka";
		    };
		  }
		  ```
		- Now run `nix-build -A icat`, and we'll get compile error due to missing dependencies
			- ```sh
			  nix-build -A icat
			  these 2 derivations will be built:
			    /nix/store/86q9x927hsyyzfr4lcqirmsbimysi6mb-source.drv
			    /nix/store/l5wz9inkvkf0qhl8kpl39vpg2xfm2qpy-icat.drv
			  ...
			  error: builder for '/nix/store/l5wz9inkvkf0qhl8kpl39vpg2xfm2qpy-icat.drv' failed with exit code 2;
			         last 10 log lines:
			         >                  from /nix/store/hkj250rjsvxcbr31fr1v81cv88cdfp4l-glibc-2.37-8-dev/include/stdio.h:27,
			         >                  from icat.c:31:
			         > /nix/store/hkj250rjsvxcbr31fr1v81cv88cdfp4l-glibc-2.37-8-dev/include/features.h:195:3: warning: #warning "_BSD_SOURCE and _SVID_SOURCE are deprecated, use _DEFAULT_SOURCE" [8;;https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html#index-Wcpp-Wcpp8;;]
			         >   195 | # warning "_BSD_SOURCE and _SVID_SOURCE are deprecated, use _DEFAULT_SOURCE"
			         >       |   ^~~~~~~
			         > icat.c:39:10: fatal error: Imlib2.h: No such file or directory
			         >    39 | #include <Imlib2.h>
			         >       |          ^~~~~~~~~~
			         > compilation terminated.
			         > make: *** [Makefile:16: icat.o] Error 1
			         For full logs, run 'nix log /nix/store/l5wz9inkvkf0qhl8kpl39vpg2xfm2qpy-icat.drv'.
			  ```
			- But we know [`imlib2` is in Nixpkgs](https://search.nixos.org/packages?query=imlib2), so we fix this with `buildInputs` attr:
			- ```nix
			  # icat.nix
			  {
			    lib,
			    stdenv,
			    fetchFromGitHub,
			    imlib2,
			  }:
			  
			  stdenv.mkDerivation {
			    pname = "icat";
			    version = "v0.5";
			  
			    src = fetchFromGitHub {
			      owner = "atextor";
			      repo = "icat";
			      rev = "v0.5";
			      sha256 = "0wyy2ksxp95vnh71ybj1bbmqd5ggp13x3mk37pzr99ljs9awy8ka";
			    };
			  
			    buildInputs = [ imlib2 ];
			  }
			  ```
			- But if we build it again, it also fails to compile due to **another missing dependency from Xorg**
			- ```sh
			  nix-build -A icat
			  this derivation will be built:
			    /nix/store/bw2d4rp2k1l5rg49hds199ma2mz36x47-icat.drv
			  ...
			  error: builder for '/nix/store/bw2d4rp2k1l5rg49hds199ma2mz36x47-icat.drv' failed with exit code 2;
			         last 10 log lines:
			         >                  from icat.c:31:
			         > /nix/store/hkj250rjsvxcbr31fr1v81cv88cdfp4l-glibc-2.37-8-dev/include/features.h:195:3: warning: #warning "_BSD_SOURCE and _SVID_SOURCE are deprecated, use _DEFAULT_SOURCE" [8;;https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html#index-Wcpp-Wcpp8;;]
			         >   195 | # warning "_BSD_SOURCE and _SVID_SOURCE are deprecated, use _DEFAULT_SOURCE"
			         >       |   ^~~~~~~
			         > In file included from icat.c:39:
			         > /nix/store/4fvrh0sjc8sbkbqda7dfsh7q0gxmnh9p-imlib2-1.11.1-dev/include/Imlib2.h:45:10: fatal error: X11/Xlib.h: No such file or directory
			         >    45 | #include <X11/Xlib.h>
			         >       |          ^~~~~~~~~~~~
			         > compilation terminated.
			         > make: *** [Makefile:16: icat.o] Error 1
			         For full logs, run 'nix log /nix/store/bw2d4rp2k1l5rg49hds199ma2mz36x47-icat.drv'.
			  ```
			- We don't know what X11 derivation is, but we can figure that out by using `rg` to grep all the references to something like `x11 =` or `libx11 =`
			- ```sh
			  $ git clone https://github.com/NixOS/nixpkgs --depth 1
			  
			  $ rg "x11 =" pkgs
			  pkgs/tools/X11/primus/default.nix
			  21:  primus = if useNvidia then primusLib_ else primusLib_.override { nvidia_x11 = null; };
			  22:  primus_i686 = if useNvidia then primusLib_i686_ else primusLib_i686_.override { nvidia_x11 = null; };
			  pkgs/applications/graphics/imv/default.nix
			  38:    x11 = [ libGLU xorg.libxcb xorg.libX11 ];
			  pkgs/tools/X11/primus/lib.nix
			  14:    if nvidia_x11 == null then libGL
			  pkgs/top-level/linux-kernels.nix
			  573:    ati_drivers_x11 = throw "ati drivers are no longer supported by any kernel >=4.1"; # added 2021-05-18;
			  ... <a lot more results>
			  
			  $ # Search case-insensitive
			  $ rg -i "libx11 =" pkgs
			  pkgs/applications/version-management/monotone-viz/graphviz-2.0.nix
			  55:    ++ lib.optional (libX11 == null) "--without-x";
			  pkgs/top-level/all-packages.nix
			  14191:    libX11 = xorg.libX11;
			  pkgs/servers/x11/xorg/default.nix
			  1119:  libX11 = callPackage ({ stdenv, pkg-config, fetchurl, xorgproto, libpthreadstubs, libxcb, xtrans, testers }: stdenv.mkDerivation (finalAttrs: {
			  pkgs/servers/x11/xorg/overrides.nix
			  147:  libX11 = super.libX11.overrideAttrs (attrs: {
			  ```
		- So we fix this by supplying `buildInputs` with build dependencies
		- ```nux
		  # icat.nix
		  {
		    lib,
		    stdenv,
		    fetchFromGitHub,
		    imlib2,
		    xorg,
		  }:
		  
		  stdenv.mkDerivation {
		    pname = "icat";
		    version = "v0.5";
		  
		    src = fetchFromGitHub {
		      owner = "atextor";
		      repo = "icat";
		      rev = "v0.5";
		      sha256 = "0wyy2ksxp95vnh71ybj1bbmqd5ggp13x3mk37pzr99ljs9awy8ka";
		    };
		  
		    buildInputs = [ imlib2 xorg.libX11 ];
		  }
		  ```
		- Now we can run `nix-build` again, and are greeted with yet another error: `make: *** No rule to make target 'install'.  Stop.`
			- By default, Nixpkgs `stdenv` works with Makefile
			- So when we run `nix-build -A icat`, Nix actually follows the instruction in icat's Makefile
		- The error happens during `make install`, because icat Makefile from GitHub did not have `install` directive
		- This step corresponds to `installPhase` attr arg of `stdenv.mkDerivation`, so we fix this by adding shell commands copying built binary to `$out/bin` in `installPhase`:
			- In Nix, the output directory is assigned to env variable `$out`
		- ```nix
		  # icat.nix
		  {
		    lib,
		    stdenv,
		    fetchFromGitHub,
		    imlib2,
		    xorg,
		  }:
		  
		  stdenv.mkDerivation {
		    pname = "icat";
		    version = "v0.5";
		  
		    src = fetchFromGitHub {
		      owner = "atextor";
		      repo = "icat";
		      rev = "v0.5";
		      sha256 = "0wyy2ksxp95vnh71ybj1bbmqd5ggp13x3mk37pzr99ljs9awy8ka";
		    };
		  
		    buildInputs = [ imlib2 xorg.libX11.dev ];
		  
		    # $out points to output directory
		    installPhase = ''
		      mkdir -p $out/bin
		      cp icat $out/bin
		    '';
		  }
		  ```
		- When we override [a phase](https://nixos.org/manual/nixpkgs/stable/#sec-stdenv-phases) (as with `installPhase`), we should start with `runHook preInstall` and `runHook postInstall` even if we don't use the hooks, so that our drv will actually run those hooks when other people provide their own `preInstall`/`postInstall` hooks
		- ```nix
		  # icat.nix
		  {
		    lib,
		    stdenv,
		    fetchFromGitHub,
		    imlib2,
		    xorg,
		  }:
		  
		  stdenv.mkDerivation {
		    pname = "icat";
		    version = "v0.5";
		  
		    src = fetchFromGitHub {
		      owner = "atextor";
		      repo = "icat";
		      rev = "v0.5";
		      sha256 = "0wyy2ksxp95vnh71ybj1bbmqd5ggp13x3mk37pzr99ljs9awy8ka";
		    };
		  
		    buildInputs = [ imlib2 xorg.libX11.dev ];
		  
		    # $out points to output directory
		    installPhase = ''
		    	runHook preInstall
		      mkdir -p $out/bin
		      cp icat $out/bin
		      runHook postInstall
		    '';
		  }
		  ```
	- ## Parameterized builds With `callPackage`
		- `callPackage` [helps with auto assigning attrs to argument](((660d1a12-4c9b-4bbb-a1ea-de865fd5c4f8)))
		- Let's say we have this recipe for package `hello`:
		- ```nix
		  # hello.nix
		  { writeShellScriptBin }:
		  
		  writeShellScriptBin "hello" ''
		    echo "Hello, World!"
		  ''
		  ```
		- This recipe expects an attrset with attr `writeShellScriptBin` as argument, so the caller (i.e. `default.nix`) must provide that for it:
		- Here, `callPackage` will provide `writeShellScriptBin` from `pkgs` to `hello.nix`
		- ```nix
		  # default.nix
		  let
		    pkgs = import <nixpkgs> { };
		  in
		  pkgs.callPackage ./hello.nix { }
		  ```
		- And if `hello.nix` expects some more arguments not available in `pkgs`:
		- ```nix
		  # hello.nix
		  {
		  	writeShellScriptBin,
		      someString ? "World!"
		  }:
		  
		  writeShellScriptBin "hello" ''
		    echo "Hello, ${someString}!"
		  ''
		  ```
		- Then we can give `someString` to `./hello.nix` with with `callPackage` by populating the attrset:
			- It is common to find expressions in Go builds like `callPackage ./go-program.nix { buildGoModule = buildGo116Module; }` to change `go` compiler
		- ```nix
		  # default.nix
		  let
		    pkgs = import <nixpkgs> { };
		  in
		  pkgs.callPackage ./hello.nix { someString = "Mars"; }
		  ```
		- ### Overrides with `callPackage`
			- The returned value from `callPackage` also has a convenient `override` function
			- This lets us override the arguments sent to the 1st call of `callPackage`, *after the fact*
			- In this case, the 1st call to `callPackage` has `someString` in its arg. So we can later override this argument of this derivation to create custom derivations of `hello-world`, e.g. `hello-mars` and `hello-moon`
			- ```nix
			  # default.nix
			  let
			  	pkgs = import <nixpkgs> { };
			  in
			  rec {
			  	hello-world = pkgs.callPackage ./hello.nix { someString = "World"; };
			  	hello-mars = hello-world.override { someString = "Mars"; };
			  	hello-moon = hello-world.override { someString = "Moon"; };
			  }
			  ```
			- Building `nix-build -A hello-moon` will build a new shell script at `./result/bin/hello`
			- ```sh
			  $ nix-build -A hello-moon
			  ./result/bin/hello
			  Hello, Moon!
			  ```
		- ### Custom `callPackage` with `callPackageWith`
			- > See [manual for `callPackageWith`](https://nixos.org/manual/nixpkgs/stable/#function-library-lib.customisation.callPackageWith)
			- Let's say we have some set of packages that depend on each other, e.g. `e` depends on `c`, `d`:
			- ```nix
			  let
			    pkgs = import <nixpkgs> { };
			  in
			  rec {
			    a = pkgs.callPackage ./a.nix { };
			    b = pkgs.callPackage ./b.nix { inherit a; };
			    c = pkgs.callPackage ./c.nix { inherit b; };
			    d = pkgs.callPackage ./d.nix { };
			    e = pkgs.callPackage ./e.nix { inherit c d; };
			  }
			  ```
			- > Note that `{ inherit a }` is equivalent to `{ a = a; }`
			- This makes use of `callPackage` attrset argument.
			- But it requires developers to manually track each derivation dependencies, e.g. we must know that `b` expects `a` in the argument
			- This is simple, but can get tedious with large set of packages
			- So we use `callPackageWith` instead:
			- ```nix
			  let
			    pkgs = import <nixpkgs> { };
			    callPackage = pkgs.lib.callPackageWith (pkgs // packages);
			    packages = {
			      a = callPackage ./a.nix { };
			      b = callPackage ./b.nix { };
			      c = callPackage ./c.nix { };
			      d = callPackage ./d.nix { };
			      e = callPackage ./e.nix { };
			    };
			  in
			  packages
			  ```
			- Now the interesting part is on line 3.
				- `(pkgs // packages)` merges attrs in `pkgs` and `packages` together
					- `pkgs` attrs are from Nixpkgs
					- `packages` attrs are `a`, `b`, ..., `e`
			- Thanks to Nix lazy evaluation, `packages` will evaluate recursively up from `a` to `e`
				- When Nix evaluates line 6, the argument sent to `./b.nix` would have been `pkgs` merged with `{ a = a; }`
				- When Nix evaluates line 8, the argument sent to `./d.nix` would have been `pkgs` merged with `{ a = a; b = b; c = c; }`
				- i.e. `packages` is being built up recursively with each call to custom `callPackage`.
	- ## Local filesystem files
		- By default, Nix builders run in isolation and only allow to read from Nixpkgs and Nix store
		- Nix provides low-level features for moving our local files to Nix store for the builders
			- > Paths can be coerced to strings, and when that happen, the local files are copied to the Nix store, and the paths then evaluate to the Nix store path to the copied local files
			- Paths can be tricky, e.g. `src = ./.;` will make our drv depends on current dirname
			- `builtins.path` function may help, but it's still difficult to express complex build logic
		- ### File sets
			- > File sets are sets, so we can perform generic set operations on them such as union, intersection, and difference.
			- A file set is a data structure representing a *collection of local files*
			- We use `lib.fileset` to work with file sets
			- All function `lib.fileset` that accepts a file set also accepts a path, which will be converted into set which contains all files in that path
			- Files in a file set are never copied to Nix store unless explicitly told to using [toSource](https://nixos.org/manual/nixpkgs/stable/#function-library-lib.fileset.toSource)
			- See [nix.dev example projects](https://nix.dev/tutorials/working-with-local-files#example-project)
			- #### Set differences
				- With file set being a set, we can get the difference between 2 sets with the [`difference` function](https://nixos.org/manual/nixpkgs/stable/#function-library-lib.fileset.difference)
					- Caveat: `difference` will throw an error if the latter dir `./result` does not exist
					- ```nix
					  sourceFiles = fs.difference ./foo ./result;
					  ```
					- Tips: use [`maybeMissing` to allow blind subtraction](https://nixos.org/manual/nixpkgs/stable/#function-library-lib.fileset.maybeMissing)
					- ```nix
					  # If ./result is empty -> diff = foo - empty set
					  # If ./result has some -> diff = foo - result
					  sourceFiles = fs.difference ./. (fs.maybeMissing ./result);
					  ```
				- If any file sets are used to built a drv, then any changes to any of the files included in the set will trigger a rebuild (because hash changes) when `nix-build` is run
			- #### Set unions for explicit exclusion
				- Using `<src> difference <union>` will exclude files in `<union>`
				- id:: 660d9603-1e90-4257-b290-06cf292f915a
				  ```nix
				  sourceFiles =
				  	fs.difference
				  	./.
				  	(fs.unions [
				  		(fs.maybeMissing ./result)
				      	./default.nix
				  		./build.nix
				  		./nix
				  	]);
				  ```
				- From now, updating excluded files (e.g. `./default.nix` and `./build.nix`) will not trigger a rebuild
			- #### Set unions for explicit inclusion
				- ```nix
				  { stdenv, lib }:
				  let
				    fs = lib.fileset;
				    sourceFiles = fs.unions [
				      ./hello.txt
				      ./world.txt
				      ./build.sh
				      (fs.fileFilter
				        (file: file.hasExt "c" || file.hasExt "h")
				        ./src
				      )
				    ];
				  in
				  
				  fs.trace sourceFiles
				  
				  stdenv.mkDerivation {
				    name = "fileset";
				    src = fs.toSource {
				      root = ./.;
				      fileset = sourceFiles;
				    };
				    postInstall = ''
				      cp -vr . $out
				    '';
				  }
				  ```
				- Here, only files specified in the union are included:
				- ```sh
				  $ nix-build
				  trace: /home/user/fileset
				  trace: - build.sh (regular)
				  trace: - hello.txt (regular)
				  trace: - src (all files in directory)
				  trace: - world.txt (regular)
				  this derivation will be built:
				    /nix/store/sjzkn07d6a4qfp60p6dc64pzvmmdafff-fileset.drv
				  ...
				  '.' -> '/nix/store/zl4n1g6is4cmsqf02dci5b2h5zd0ia4r-fileset'
				  './build.sh' -> '/nix/store/zl4n1g6is4cmsqf02dci5b2h5zd0ia4r-fileset/build.sh'
				  './hello.txt' -> '/nix/store/zl4n1g6is4cmsqf02dci5b2h5zd0ia4r-fileset/hello.txt'
				  './world.txt' -> '/nix/store/zl4n1g6is4cmsqf02dci5b2h5zd0ia4r-fileset/world.txt'
				  './src' -> '/nix/store/zl4n1g6is4cmsqf02dci5b2h5zd0ia4r-fileset/src'
				  './src/select.c' -> '/nix/store/zl4n1g6is4cmsqf02dci5b2h5zd0ia4r-fileset/src/select.c'
				  './src/select.h' -> '/nix/store/zl4n1g6is4cmsqf02dci5b2h5zd0ia4r-fileset/src/select.h'
				  ...
				  /nix/store/zl4n1g6is4cmsqf02dci5b2h5zd0ia4r-fileset
				  ```
				- This greatly simplifies our `postInstall` hook, because a derivation only reads from `sourceFiles`, and so the `.` in `postInstall` is a working dir with only explicitly included files
			- #### Filters
				- Use [`fileFilter`](https://nixos.org/manual/nixpkgs/stable/#function-library-lib.fileset.fileFilter) to check file conditions
				- The snippet below is equivalent to [previous example](((660d9603-1e90-4257-b290-06cf292f915a))) if the local files are the same
				- ```nix
				  sourceFiles =
				  	fs.difference
				  	./.
				  	(fs.unions [
				  		(fs.maybeMissing ./result)
				      	(fs.fileFilter (file: file.hasExt "nix") ./.)
				  		./nix
				  	]);
				  ```
			- `gitTracked` for only including files tracked in a Git repo
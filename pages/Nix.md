- > [Nix Pills](https://nixos.org/guides/nix-pills/)
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
- # [[Nix language]]
	- > The Nix language is a domain-specific functional programming language created to compose [[Nix derivation]] , which is precise describing how contents of existing files are used to derive new files. Nix is also dynamically-typed, lazily-evaluated.
	- Since Nix is a functional language, there're *no statements*, only **expression**
	- The Nix language is used to describe derivations.
	- Nix runs derivations to produce *build results*.
	- Build results can in turn be used as *build inputs* for other derivations.
	- ## Nix expressions
		- Evaluating a Nix expression produces a Nix value
		- e.g. evaluating `1+2` expression yields a value `3`, which itself is also an expression
			- Other expression that evaluate to `3`
			- ```nix
			  let x=1;y=2;in x+y
			  ```
			- And because whitespaces are most of the times insignificant in Nix, we can write the expression above in this form instead:
			- ```nix
			  let
			   x = 1;
			   y = 2;
			  in x + y
			  ```
		- Note: when using Nix REPL, it can happen that our expression output is squashed due to Nix lazy evaluation. To make the REPL prints expected value, prepend `:p` to a command
		  id:: 660adc30-a264-4f5e-8d4a-0c6fec093f97
			- ```nix
			  nix-repl> { a.b.c = 1; }
			  { a = { ... }; }
			  
			  nix-repl> :p { a.b.c = 1; }
			  { a = { b = { c = 1; }; }; }
			  ```
	- ## Nix files
		- Each `.nix` file evaluates to a single Nix expression
		- ```sh
		  # Populate the file with expression `1+2`
		  echo 1 + 2 > foo.nix
		  
		  # Evaluate the file expression
		  # Note that --eval instructs nix-instantiate
		  # to only evaluate the expression and do nothing else
		  nix-instantiate --eval foo.nix
		  ```
		- If `--eval` is omitted, `nix-instantiate` will evaluate the expression to a [[Nix derivation]]
		- By default, `nix-instantiate` looks for `default.nix`
		- Pass `--strict` to `nix-instantiate` [if lazy evaluation messes up with our eval output](((660adc30-a264-4f5e-8d4a-0c6fec093f97)))
	- ## Nix attribute set
		- A Nix attrset is like a dictionary or JSON: it's an expression in key-value pair structure
			- JSON and Nix equivalent example:
				- ```json
				  {
				    "string": "hello",
				    "integer": 1,
				    "float": 3.141,
				    "bool": true,
				    "null": null,
				    "list": [1, "two", false],
				    "object": {
				      "a": "hello",
				      "b": 1,
				      "c": 2.718,
				      "d": false
				    }
				  }
				  ```
				- ```nix
				  {
				    string = "hello";
				    integer = 1;
				    float = 3.141;
				    bool = true;
				    null = null;
				    list = [ 1 "two" false ];
				    attribute-set = {
				      a = "hello";
				      b = 2;
				      c = 2.718;
				      d = false;
				    }; # comments are supported
				  }
				  ```
		- ### Nix recursive attribute set (`rec`)
			- A recursive attrset is declared with `rec` keyword
			- It allows attribute access within the same attrset
			- ```nix
			  rec {
			  	one = 1;
			      two = one + 1;
			      three = two + 1;
			  }
			  ```
			- Which evaluates to
			- ```nix
			  { one = 1; two = 2; three = 3; }
			  ```
		- ### Attribute access with dot notation
			- > The examples use [`let` expression](((660adebd-b7a3-42aa-a5b9-30fed6538548)))
			- ```nix
			  let
			    attrset = { x = 1; };
			  in
			  attrset.x # evals to 1
			  ```
			- ```nix
			  let
			    attrset = { a = { b = { c = 1; }; }; };
			  in
			  attrset.a.b.c # evals to 1
			  ```
		- #### Set attribute with dot notation
			- ```nix
			  { a.b.c = 1; }
			  ```
			- This will evaluate to
			- ```nix
			  { a = { b = { c = 1; }; }; }
			  ```
	- ### `let ... in ...`
	  id:: 660adebd-b7a3-42aa-a5b9-30fed6538548
		- `let` expression allows assigning names to values, and the names be used later
			- The expression below evals to `2`
			- ```nix
			  let
			  	a = 1;
			  in
			  a + a
			  ```
			- And this expression to `3`
			- ```nix
			  let
			  	b = a + 1;
			      a = 1;
			  in
			  a + b
			  ```
		- We can generally say that we do the name bindings ("assignments") between `let` and `in`, and use the values in the expression after `in`
		- `let` expression name bindings are scoped to the `let .. in ..` block
	- ### `with foo; ...`
		- `with` allows us to directly access attributes in `foo`
		- ```nix
		  with a; [ x y z ]
		  ```
		- Is equivalent to
		- ```nix
		  [a.x a.y a.z]
		  ```
		- So the expression below evals to `[1 2 3]`
		- ```nix
		  let
		    a = {
		      x = 1;
		      y = 2;
		      z = 3;
		    };
		  in
		  with a; [ x y z ]
		  ```
		- `with` attributes are scoped to the expression after `;`, in this case, only `[x y z]` can access `x`, `y`, `z` as `a.x`, `a.y`, `a.z`.
	- ### `inherit ...` and `inherit (...) ...`
		- `inherit` brings values of attributes from previous scope into the expression:
			- ```nix
			  let
			    x = 1;
			    y = 2;
			  in
			  {
			    inherit x y;
			  }
			  
			  ```
			- Here, `inherit x y` is equivalent to `x = x; y = y;`
			- Both exprs evaluate to attrset `{ x = 1; y = 2; }`
		- `inherit (foo) ...` will do `inherit` from attrset `foo`
			- ```nix
			  let
			    a = { x = 1; y = 2; };
			  in
			  {
			    inherit (a) x y;
			  }
			  ```
			- Here, `inherit (a) x y` is like `x = a.x; y = a.y`
			- Both exprs evaluate to attrset `{ x = 2;  y = 2; }`
		- We can use `inherit` inside a [`let ... in ...` expression](((660adebd-b7a3-42aa-a5b9-30fed6538548)))
			- ```nix
			  let
			    inherit ({ x = 1; y = 2; }) x y;
			  in
			  [ x y ]
			  ```
			- Here, `inherit({...}) x y` expands to `{ x = 1; y = 2 }`
			- So the whole expr evals to `[1 2]`
			- So the example expression above is verbatim-equivalent to:
			- ```nix
			  let
			    x = { x = 1; y = 2; }.x;
			    y = { x = 1; y = 2; }.y;
			  in
			  [x y]
			  ```
	- ## Nix strings
		- ### Interpolation with `${...}`
			- `$` without `{...}` is not string interpolation. **Usually it's shell variables**
				- ```nix
				  let
				    out = "Nix";
				  in
				  "echo ${out} > $out"
				  ```
				- Evaluates to `echo Nix > $out`, where `$out` is a shell variable `out`
			- The expression
			- ```nix
			  let
			    name = "World";
			  in
			  "Hello ${name}!"
			  ```
			- evaluates to `hello World!`
		- ### Multiline/indented strings `''...''`
			- Use double single quotes to wrap a multiline string
			- ```nix
			  ''
			    one
			     two
			      three
			  ''
			  ```
			- Will evaluate to string
			- ```json
			  "one\n two\n  three\n"
			  ```
	- ## Nix filesystem paths
		- FS paths have 1st-class support in Nix
		- Absolute paths start with `/`
		- Relative paths don't start with `/`, but contains one later in the path
		- Like with shells, `.` denotes the current directory, and `..` denotes the CWD's parent
		- `./.` evaluates to the Nix file's current directory
		- ### Lookup paths, e.g. `<nixpkgs>`
		  id:: 660ae72f-2260-4d68-a778-e7a5aad8db86
			- Lookup paths have angle brackets around them
			- Their values come from `builtins.nixPath`
			- We can go deeper from lookup paths, e.g. `<nixpkgs>/lib` will get a subdir `lib` from the lookup path `<nixpkgs>`
			- Lookup paths are *impure* and are recommended to avoid in prod
	- ## Nix functions
		- Functions are denoted by colon `:`
		- Arguments come before the `:`, and the body comes after
			- `a: a + 1` is like `fn (i: isize) { i + 1 }` in Rust
			- We can see here that function is another place in Nix that we can bind values to names (in this case we bind `a` with whatever value passed to this function when called)
		- ### Attrset as argument
			- > Note the use of comma in attrset argument
			- ```nix
			  { x, y }: x + y
			  ```
			- We can also assign default values to function arguments:
			- ```nix
			  { x, y ? 7 }: x + y
			  ```
			- If the callers pass large attrset as arg (e.g. the arg has extra attrs `foo`, `bar`), then we need to use spread notation to safely ignore other attrs, otherwise Nix will err:
			- ```nix
			  { a, b, ... }: a + b
			  ```
			- We can also capture/bind other unnamed arguments with `@` pattern:
			- ```nix
			  { a, b, ... }@args: a + b + args.foo
			  ```
				- We are free to choose where to put `@` pattern around the attrset
				- ```nix
				  @args{ a, b, ... }: a + b + args.foo
				  ```
			- Will evaluate to `1+10+1000`
		- Functions are anonymous, i.e. *lamda* (may be printed as `<LAMDA>` Nix console)
		- ### Calling functions
			- We can call a lambda function like so:
			- ```nix
			  (x: x + 1) 3
			  ```
			- This evaluates to `4`
			- We can also bind a function to a name with `let` and call it
			- ```nix
			  let
			  	compute = { a, b, ... }@args: a + b + args.foo;
			  in
			  compute { a = 1; b = 10; bar = 100; foo = 1000; }
			  ```
			- Will evaluate to `1011` from `1 + 10 + 1000`
			- We can also use the function right after bound to a name:
			- ```nix
			  let
			      f = x: x + 10;
			      n = f 7;
			  in
			  f n
			  ```
			- Here, `f(n)` evaluates to `f(f(7))`, and eventually evaluates to `27`
			- #### Caveats: whitespaces
				- Functions are delimited by whitespaces (hence the parenthesis when calling lambda func), and so are lists
				- So the following 2 expressions are different:
				- ```nix
				  let
				   f = x: x + 1;
				   a = 1;
				  in [ (f a) ]
				  ```
				- This evaluates to `[ 2 ]`
				- While this expression
				- ```nix
				  let
				   f = x: x + 1;
				   a = 1;
				  in [ f a ]
				  ```
				- Evaluates to `[ <LAMBDA> 1 ]`
		- ### Multiple arguments
			- In Nix, a function can actually accepts only 1 arguments
			- To do multiple arguments, Nix returns a closure as another function
				- Consider this function, which accepts `a` and `b` and returns `a+b`:
				- ```nix
				  a: b: a + b
				  ```
				- We are supposed to call this function with `<fname> a b`, which we *might* think it works like `fname(1, 2)`
				- But what Nix actually does is this: `fname(1)(2)`
				- So when Nix evaluates `fname(1)`, it gets this function back: `b: 1 + b`
				- So `fname(1)(2)` will call that function with `b = 2`, and gives us `3`
				- And so, the example function above is equivalent to:
				- ```Nix
				  a: (b: a + b)
				  ```
	- ## Library functions
		- ### `builtins` (sometimes call *primitive operations* or *primops*)
			- Built-in functions implemented in Nix interpreter (C++)
			- See [Nix manual](https://nix.dev/manual/nix/2.18/language/builtins)
			- They are evaluated as `PRIMOPS`:
			- ```nix
			  builtins.toString
			  <PRIMOPS>
			  ```
		- ### `import`
			- > `import` is the only built-in functions available at the top-level without having to refer to namespace `builtins`
			- `import` takes a path to a Nix file, and reads the file to evaluate its expression, returning the evaluated value.
			- If the path points to a directory, `import` reads `default.nix` in that directory
			- If the file evaluates to a function, we can immediately call the imported function:
			- ```sh
			  echo "x: x + 1" > ./foo/default.nix
			  
			  nix repl
			  <nix-repl> import ./foo 5
			  6
			  <nix-repl>
			  ```
		- ### `pkgs.lib`
			- The [nixpkgs](https://github.com/NixOS/nixpkgs) repository provides an attrset called [lib](https://github.com/NixOS/nixpkgs/blob/master/lib/default.nix)
			- Unlike `builtins` which are implemented in C++ and are part of the language, these are implemented in Nix
			- Due to historical reasons, `nixpkgs` `lib` may contains functions very similar to `builtins`
			- The expression in `nixpkgs` happens to be a function, so we must give it some argument - in these examples, an empty attrset `{}`
			- See [Nixpkgs manual](https://nixos.org/manual/nixpkgs/stable/#sec-functions-library)
			- #### Convention (`pkgs`, `lib`, etc.)
				- Due to this naming to `pkgs` convention, we usually see something like this on the internet:
				- By convention, we assign name `pkgs` to expression returned by `import <nixpkgs> {..}`
				- If we want to avoid [lookup path](((660ae72f-2260-4d68-a778-e7a5aad8db86))) `<nixpkgs>`, we can do:
				- ```Nix
				  let
				    nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/archive/06278c77b5d162e62df170fec307e83f1812d94b.tar.gz";
				    pkgs = import nixpkgs {};
				  in
				  pkgs.lib.strings.toUpper "always pin your sources"
				  ```
				- We might come across other people's code that looks like this:
				- ```nix
				  { pkgs, ... }:
				  pkgs.lib.strings.removePrefix "no " "no true scotsman"
				  ```
				- In cases like these, we can assume that `pkgs` will refer to `nixpkgs` attrset, and will contain `lib` attribute:
				- ```Nix
				  let
				    pkgs = import <nixpkgs> {};
				  in
				  pkgs.lib.strings.toUpper "lookup paths considered harmful"
				  ```
				- And sometimes, we may see other people's code importing attribute `lib`:
				- ```nix
				  { lib, ... }:
				  
				  let
				    to-be = true;
				  in
				  lib.trivial.or to-be (! to-be)
				  ```
					- We can try this by putting it to a file and run it:
					- ```sh
					  $ nix-instantiate --eval file.nix --arg lib '(import <nixpkgs> {}).lib'
					  true
					  ```
				- Most of the times, we can assume that `lib` is `pkgs.lib`. If we see that a function is expecting `{ pkgs, lib, ... }`, we can assume that `pkgs.lib` and `lib` are the same, but put there just for readability
	- ## Impurities
		- Most Nix expressions are pure
		- Examples of impurities are *build inputs*, which may be read from files on the system
		- ### Nix side effects
			- **Paths**: **Whenever a path is used in string interpolation, its content is copied to Nix store**, and the string interpolation expression evals to the absolute path to that file/directory in the Nix store
				- Why copy to Nix store? To make it more reproducible and robust. With hash-enforced access, content file changes will have less detrimental effects on our builds
				- ```sh
				  # File content is "123"
				  echo 123 > data
				  ```
				- ```nix
				  "${./data}" # Path inside string interpolation
				  ```
				- The expression above will evaluate to:
				- ```txt
				  "/nix/store/h1qj5h5n05b5dl5q4nldrqq8mdg7dhqk-data"
				  ```
			- **Fetches**: fetchers are used to get build inputs from non-FS locations (e.g. `builtins.fetchGit`). These fetchers will download the resources to Nix store, and so the fetcher expressions evaluate to Nix store path strings.
			  id:: 660c3bd6-b1b2-42a0-bc1a-6adc76494082
				- ```nix
				  builtins.fetchTarball "https://github.com/NixOS/nix/archive/7c3ab5751568a0bc63430b33a5169c5e4784a0ff.tar.gz"
				  ```
				- The fetcher expression will save the files to Nix store
				- Which means that the expression above evaluates to
				- ```txt
				  "/nix/store/d59llm96vgis5fy231x6m7nrijs0ww36-source"
				  ```
	- ## Derivations
		- > Nix provides a primitive impure function `derivation`, but since this is impure and advised against, we rarely see the function in practice
		- Nix derivations are in practice the results of `mkDerivation`
		- ### Build results
			- The return value of `mkDerivation`, aka *build results*, is what Nix will eventually build
			- The build results are an attrset, with particular structure
			- This build results attrset can be used in string interpolation, and like files and fetchers, a build result attrset will evaluates to a Nix store path string:
				- ```nix
				  let
				    pkgs = import <nixpkgs> {};
				  in "${pkgs.nix}"
				  ```
				- ```txt
				  "/nix/store/sv2srrjddrp2isghmrla8s6lazbzmikd-nix-2.11.0"
				  ```
				- The resulting string is the file system path where the build result of that derivation will end up.
				- A derivation’s output path is fully determined by its inputs, which in this case come from *some* version of `<nixpkgs>` (hence `-nix-2.11.0` suffix of the filename)
		- ### Built derivations
			- When built, a derivation is saved to Nix store and referenced by its hashy path
			- > Everything inside the Nix store is immutable
			- Let's use a derivation of `bash` as example:
			- ```nix
			   /nix/store/s4zia7hhqkin1di0f187b79sa2srhv6k-bash-4.2-p45
			  ```
			- The Nix store path above contains `/bin/bash`.
			- When this drv is enabled, **Nix will arrange the environment such that the `/bin/bash` points to some `bash` binary in `/nix/store/s4zia7hhqkin1di0f187b79sa2srhv6k-bash-4.2-p45`**.
			- The drv does not contains all dependencies, for example, `libc`
			- This is because these other drvs are also built and stored in Nix store
			- ```sh
			  $ ldd  `which bash`
			  libc.so.6 => /nix/store/94n64qy99ja0vgbkf675nyk39g9b978n-glibc-2.19/lib/libc.so.6 
			  ```
			- We can see that our *current* `bash` finds libc from another drv: `/nix/store/94n64qy99ja0vgbkf675nyk39g9b978n-glibc-2.19/lib/libc.so.6 `
			- This is because when we built the bash drv, it was built against this libc drv.
	- ## Simple examples
		- ### Declarative shell
			- ```nix
			  { pkgs ? import <nixpkgs> {} }:
			  let
			    message = "hello world";
			  in
			  pkgs.mkShellNoCC {
			    buildInputs = with pkgs; [ cowsay ];
			    shellHook = ''
			      cowsay ${message}
			    '';
			  }
			  ```
			- The  expression (a Nix function) takes 1 attrset argument with `pkgs` attr. If `pkgs` is not in the caller's argument, it defaults to importing Nixpkgs using [lookup paths `<nixpkgs>`](((660ae72f-2260-4d68-a778-e7a5aad8db86))) with empty attrset argument: `import <nixpkgs> {}`
		- ### System configuration
			- ```nix
			  { config, pkgs, ... }: {
			  
			    imports = [ ./hardware-configuration.nix ];
			  
			    environment.systemPackages = with pkgs; [ git ];
			  
			    # ...
			  
			  }
			  ```
			- The expression (a Nix function) takes 1 attrset  arg with attrs `config` and `pkgs`.
			- We can see that the argument `config` was unused
			- The returned expression will have the following attributes:
				- `imports`: which is set to be a list with 1 element, a path: `./hardware-configuration.nix`
				- `environment`: which has a nested attribute `systemPackages` set to `pkgs.git`
		- ### Package
			- ```nix
			  { lib, stdenv, fetchurl }:
			  
			  stdenv.mkDerivation rec {
			    pname = "hello";
			    version = "2.12";
			  
			    src = fetchurl {
			      url = "mirror://gnu/${pname}/${pname}-${version}.tar.gz";
			      sha256 = "1ayhp9v4m4rdhjmnl2bq3cibrbqqkgjbl3s7yk2nhlh8vj3ay16g";
			    };
			  
			    meta = with lib; {
			      license = licenses.gpl3Plus;
			    };
			  }
			  ```
			- This Nix expression (a Nix function) takes an attrset with exactly 3 attrs: `lib`, `stdenv`, `fetchUrl`
			- The whole Nix expression evaluates to the return value of  `stdenv.mkDerivation rec{..}`
			- Let's take a look at the attrset arg passed to `stdenv.mkDerivation`
				- It uses recursive attrset, so that it can refer to names from within the expr
				- `name` and `version` are simple, they are just named values within this rattrset
				- `src`
					- [Assigned to what `fetchUrl <s>` evaluates to](((660c3bd6-b1b2-42a0-bc1a-6adc76494082)))
					- The attrset `s` has 2 attrs
						- `url`, which is assigned to a URL string interpolated using `name` and `version` from the rattrset
						- `sha256`, which is assigned a hard-coded SHA2 checksum string
				- `meta`
					- Assigned to an attrset with 1 attr, `license`, which is `lib.license.gpl3Plus`
	- ## Nix style guide and convention
		- > See also: [Nix Pills](https://nixos.org/guides/nix-pills/)
		- Avoiding reinventing the wheel, instead explore Nixpkgs first
			- ```nix
			  { x, y, z }: (x y) z.a
			  ```
			- How do we know the individual type of each names here?
			- We can think that `x` is a function, and `x y` returns a function that takes `z.a`
			- Still, we might be wrong
			- It's possible that what we are going to do is already implemented in Nixpkgs
		- Conform to [Nix modules](https://nixos.org/manual/nixos/stable/index.html#sec-writing-modules) for more complex expressions, especially if it's meant to be a module and not just a simple value
		- ### `callPackage`
		  id:: 660d1a12-4c9b-4bbb-a1ea-de865fd5c4f8
			- [`callPackage`](https://github.com/nixos/nixpkgs/commit/d17f0f9cbca38fabb71624f069cd4c0d6feace92) emerges as a convention in Nix community
			- It helps reduce code size by automatically supplying attrs in attrset arguments
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
		  stdenv.mkDerivation {	};
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
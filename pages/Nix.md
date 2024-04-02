# [[nix-shell]]
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
			- The  expression (a Nix function) takes 1 attrset argument with `pkgs` attr. If `pkgs` is not in the caller's argument, it defaults to importing Nixpkgs using lookup paths with empty attrset: `import <nixpkgs> {}`
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
	-
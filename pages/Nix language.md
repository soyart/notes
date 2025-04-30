tags:: Programming, Language

- > The Nix language is a domain-specific functional programming language created to compose [[Nix derivation]] , which is precise describing how contents of existing files are used to derive new files. Nix is also dynamically-typed, lazily-evaluated.
- The Nix language is at the core of [[Nix]]
- Since Nix is a functional language, there're *no statements*, only **expression**
- # Nix files
	- > Each `.nix` file evaluates to a single Nix expression
	- ```sh
	  # Populate the file with expression `1+2`
	  $ echo 1 + 2 > 'foo.nix';
	  
	  # Evaluate the file expression
	  # Note that --eval instructs nix-instantiate
	  # to only evaluate the expression and do nothing else
	  $ nix-instantiate --eval 'foo.nix'; # Evaluates to 3
	  ```
	- If `--eval` is omitted, `nix-instantiate` will evaluate the expression to a [[Nix derivation]]
	- By default, `nix-instantiate` looks for `default.nix`
	- Pass `--strict` to `nix-instantiate` [if lazy evaluation messes up with our eval output](((660adc30-a264-4f5e-8d4a-0c6fec093f97)))
	- And because whitespaces are most of the times insignificant in Nix, we can write the expression above in this form instead:
	  ```nix
	  let
	   x = 1;
	   y = 2;
	  in x + y
	  ```
- # Nix expressions
	- Evaluating a Nix expression produces a Nix value
	- Everything is an expression
	- Evaluating an expression produces a value
		- Let's try evaluating Nix expressions with the REPL built into the interpreter:
		  ```sh
		  $ nix-repl
		  nix-repl>
		  ```
		- Simple arithmetic ops are expressions:
		  ```nix
		  nix-repl> 3*1
		  3
		  
		  nix-repl> 100+100
		  200
		  ```
		- And so are strings and booleans:
		  ```nix
		  nix-repl> "Hello, World!"
		  "Hello, World!"
		  
		  nix-repl> 2-2 == 0
		  true
		  ```
		- [Functions](((66117c4f-2d14-46d5-b3e1-c20b539d9e0d))) and ["attribute sets"](((66117c4f-000e-4be3-b016-43257b40bc48))) are also expressions
		- > Note: when using Nix REPL, it can happen that our expression output is squashed due to Nix lazy evaluation. To make the REPL prints expected value, prepend `:p` to a command
		- ```nix
		  nix-repl> { a.b.c = 1; }
		  { a = { ... }; }
		  
		  nix-repl> :p { a.b.c = 1; }
		  { a = { b = { c = 1; }; }; }
		  
		  nix-repl> x: x / 2 == 0
		  <<lambda @ <<string>>:1:1>>
		  
		  nix-repl> :p x: x / 2 == 0
		  <<lambda @ <<string>>:1:1>>
		  ```
- # `let ... in ...`
	- `let` expression allows assigning names to values, and the names be used later
		- The expression below evals to `2`:
		  ```nix
		  let
		  	a = 1;
		  in
		  a + a
		  ```
		- And this expression to `3`:
		  ```nix
		  let
		  	b = a + 1;
		      a = 1;
		  in
		  a + b
		  ```
	- We can generally say that we do the name bindings ("assignments") between `let` and `in`, and use the values in the expression after `in`
	- `let` expression name bindings are scoped to the `let .. in ..` block
- # `with foo; ...`
	- `with` allows us to directly access attributes in `foo`:
	  ```nix
	  with a; [ x y z ]
	  ```
	- Is equivalent to:
	  ```nix
	  [a.x a.y a.z]
	  ```
	- So the expression below evals to `[1 2 3]`:
	  ```nix
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
- # Nix data types
	- Nix supports many data types, from primitives like numbers, strings, booleans, to more complex ones like first-class functions and attribute sets
	- ## Nix strings
		- Nix strings are values of type `lib.types.str`
		- Utilities are built-in as well as implemented as Nixpkgs library `lib.strings`
		- ### Interpolation with `${...}`
			- > Sometimes, [string interpolation evaluation may have  *side effects*](((660c39e1-3de2-417a-8d00-04f98f4d17f5))), usually with paths
			- The following expr evaluates to string `Hello World!`
			  ```nix
			  let
			    name = "World";
			  in
			  "Hello ${name}!"
			  ```
			- `$` without `{...}` is not string interpolation:
			  ```nix
			  let
			    out = "Nix";
			  in
			  "echo ${out} > $out"
			  ```
			- Evaluates to string `echo Nix > $out`
		- ### Multiline/indented strings `''...''`
			- Use double-single quotes to wrap a multiline string:
			  ```nix
			  ''
			    one
			     two
			      three
			  ''
			  ```
			- Will evaluate to string
			  ```txt
			  "one\n two\n  three\n"
			  ```
			- #### Leading whitespaces quirks
				- > Nix respects the first character column of the left-most lines as the output starting column
				- Unlike Go strings with with backticks, Nix users perform string interpolations pretty frequently, so Nix strings are designed to be readable in code
				- In the following example, `foo` is respected as the starting column:
				  ```nix
				  ''
				  	foo
				  	bar
				      	baz
				  ''
				  
				  ========> "foo\n\bar\n   baz\n"
				  
				  foo
				  bar
				  	baz
				  ```
				- In the following example, `bar` is respected:
				  ```nix
				  ''
				  	  foo
				  	bar
				      baz
				  ''
				  
				  ========> "	foo\nbar\nbaz\n"
				  
				    foo
				  bar
				  baz
				  ```
				- The horizontal positions of the starting double-single-quote should not matter:
				  ```nix
				  ''
				  	foo
				  	bar
				      	baz
				  	''
				  
				  ========> "foo\n\bar\n    baz\n"
				  ```
				  ```nix
				  			''
				  	foo
				  	bar
				      	baz
				  	''
				  
				  ========> "foo\n\bar\n    baz\n"
				  ```
				- Although the blank lines until the line with chars matter:
				  ```nix
				  	''
				  
				  
				      foo
				  bar
				  baz
				      ''
				  
				  ========> "\n\n    foo\n\bar\nbaz\n"
				  ```
				- The closing double-single-quote do matter *only if it's on the same line as the last non-blank line*, as they determine the trailing `\n`:
				  ```nix
				  		''
				  	foo
				  	bar
				      	baz 
				  						''
				  
				  ========> "foo\n\bar\n    baz\n"
				  ```
					- ```nix
					  		''
					  	foo
					  	bar
					      	baz
					  	''
					  
					  ========> "foo\n\bar\n    baz\n"
					  ```
					- ```nix
					  		''
					  	foo
					  	bar
					      	baz  ''
					  
					  ========> "foo\n\bar\n    baz  "
					  ```
					- ```nix
					  		''
					  	foo
					  	bar
					      	baz''
					  
					  ========> "foo\n\bar\n    baz"
					  ```
	- ## Nix paths
		- FS paths have 1st-class support in Nix
		- Absolute paths start with `/`
		- Relative paths don't start with `/`, but contains one later in the path
		- Like with shells, `.` denotes the current directory, and `..` denotes the CWD's parent
		- `./.` evaluates to the Nix file's current directory
		- ## Lookup paths, e.g. `<nixpkgs>`
			- Lookup paths have angle brackets around them
			- Their values come from `builtins.nixPath`
			- We can go deeper from lookup paths, e.g. `<nixpkgs>/lib` will get a subdir `lib` from the lookup path `<nixpkgs>`
			- Lookup paths are *impure* and are recommended to avoid in prod
	- ## Nix attribute sets
	  id:: 66117c4f-000e-4be3-b016-43257b40bc48
		- A Nix attrset is like a dictionary or JSON: it's an expression in key-value pair structure
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
		- We can set each attr with dot notation:
		  ```nix
		  { a.b.c = 1; }
		  
		  # Evaluates to attrset: { a = { b = { c = 1; }; }; }
		  ```
		- Each attr is also accessed via dot notation:
		  ```nix
		  let
		  	attrset = { x = 1; };
		  in
		  attrset.x # 1
		  ```
		  We can go deep:
		  ```nix
		  let
		  	attrset = { a = { b = { c = 1; }; }; };
		  in
		  attrset.a.b.c # 1
		  ```
		- We can also use string variables to access an attr with key matching the string value:
		  ```nix
		  let
		  	attrset = { name = "foo"; year = 2032; x = 1; y = 2 };
		      y = "year";
		  in
		  attrset.${y} # 2032
		  ```
		- ## Recursive attribute sets (`rec {...}`)
			- A recursive attrset is declared with `rec` keyword
			- It allows attribute access within the same attrset:
			  ```nix
			  rec {
			  	one = 1;
			      two = one + 1;
			      three = two + 1;
			  }
			  ```
			- Which evaluates to
			  ```nix
			  { one = 1; two = 2; three = 3; }
			  ```
		- ## Inherit attributes with `inherit`
		  id:: 66117c4f-6003-4cdf-adeb-e0aa5fccd1de
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
				  ```nix
				  let
				    x = { x = 1; y = 2; }.x;
				    y = { x = 1; y = 2; }.y;
				  in
				  [x y]
				  ```
		- ## Helper functions
			- ### `builtins` (C++)
				- `builtins` provides low-level, primitive attrset operations like `isAttrs`,  `hasAttrs`, `getAttr`, `attrNames` `attrValues`
				- It also provides some higher-level but frequently performed operations like `mapAttrs`, `removeAttrs`, and `listToAttrs`
			- ### `<nixpkgs>.lib.attrsets`
				- [Nixpkgs also provide their own attrset utilities](https://nixos.org/manual/nixpkgs/stable/#sec-functions-library-attrsets)
				- The library also [inherits](((66117c4f-6003-4cdf-adeb-e0aa5fccd1de))) some names from `builtins` [See source](https://github.com/NixOS/nixpkgs/blob/master/lib/attrsets.nix).
					- The library sometimes also just wraps `builtins` function transparently (like with `attrValues`), so if we see identical names, we can infer that they will lead back to `builtins`
				- Higher-level functions are defined here, e.g. `attrVals`, which lets us choose attrs to be evaluaed
		- ## Examples
			- ```nix
			  with import <nixpkgs> { };
			  let
			    attr = {a="a"; b = 1; c = true;};
			    s = "b";
			  in
			  {
			    # Everything should evaluate to true
			    
			    ex0 = builtins.isAttrs attr;
			    ex1 = attr.a == "a";
			    ex2 = attr.${s} == 1;
			    ex3 = lib.attrsets.attrVals ["c" "b" ] attr == [ true 1 ];
			    ex4 = builtins.attrValues attr == [ "a" 1 true ];
			    ex5 = builtins.intersectAttrs attr {a = "b"; d = 234; c = "";} == { a="b" ; c=""; };
			    ex6 = lib.attrsets.removeAttrs attr ["b" "c"] == { a="a"; };
			    ex7 = ! attr ? a == false;
			  }
			  ```
	- ## Nix functions
	  id:: 66117c4f-2d14-46d5-b3e1-c20b539d9e0d
		- Functions are denoted by colon `:`
		- Arguments come before the `:`, and the body comes after
			- `a: a + 1` is like `fn (i: isize) { i + 1 }` in Rust
			- We can see here that function is another place in Nix that we can bind values to names (in this case we bind `a` with whatever value passed to this function when called)
		- ### Attrset as argument
			- Here is a basic Nix function that takes attrset arg with attrs `x` and `y`, returning `x+y`:
			  > Note the use of comma in attrset argument
			  
			  ```nix
			  { x, y }: x + y
			  ```
			- We can also assign default values to function arguments:
			  ```nix
			  { x, y ? 7 }: x + y
			  ```
			- If the callers pass large attrset as arg (e.g. the arg has extra attrs `foo`, `bar`), then we need to use spread notation to safely ignore other attrs, otherwise Nix will err:
			  ```nix
			  { a, b, ... }: a + b
			  ```
			- We can also capture/bind other unnamed arguments with `@` pattern:
			  ```nix
			  { a, b, ... }@args: a + b + args.foo
			  ```
			  > We can place `@args` on whichever side
			  > ```nix
			  > @args{ a, b, ... }: a + b + args.foo
			  > ```
			- Will evaluate to `1+10+1000`
		- Functions are anonymous, i.e. *lamda* (may be printed as `<LAMDA>` Nix console)
		- ## Calling functions
			- We can call a lambda function like so:
			  ```nix
			  (x: x + 1) 3
			  ```
			- This evaluates to `4`
			- We can also bind a function to a name with `let` and call it:
			  ```nix
			  let
			  	compute = { a, b, ... }@args: a + b + args.foo;
			  in
			  compute { a = 1; b = 10; bar = 100; foo = 1000; }
			  ```
			- Will evaluate to `1011` from `1 + 10 + 1000`
			- We can also use the function right after bound to a name:
			  ```nix
			  let
			      f = x: x + 10;
			      n = f 7;
			  in
			  f n
			  ```
			- Here, `f(n)` evaluates to `f(f(7))`, and eventually evaluates to `27`
			- ### Caveats: whitespaces
				- Functions are delimited by whitespaces (hence the parenthesis when calling lambda func), and so are lists
				- So the following 2 expressions are different:
				  ```nix
				  let
				   f = x: x + 1;
				   a = 1;
				  in [ (f a) ]
				  ```
				- This evaluates to `[ 2 ]`
				- While this expression:
				  ```nix
				  let
				   f = x: x + 1;
				   a = 1;
				  in [ f a ]
				  ```
				- Evaluates to `[ <LAMBDA> 1 ]`
		- ## Multiple arguments
			- In Nix, a function can actually accepts only 1 arguments
			- To do multiple arguments, Nix returns a closure as another function
				- Consider this function, which accepts `a` and `b` and returns `a+b`:
				  ```nix
				  a: b: a + b
				  ```
				- We are supposed to call this function with `<fname> a b`, which we *might* think it works like `fname(1, 2)`
				- But what Nix actually does is this: `fname(1)(2)`
				- So when Nix evaluates `fname(1)`, it gets this function back: `b: 1 + b`
				- So `fname(1)(2)` will call that function with `b = 2`, and gives us `3`
				- And so, the example function above is equivalent to:
				  ```nix
				  a: (b: a + b)
				  ```
			- ### Examples
				- ```nix
				  let
				    b = 1;
				    fu0 = (x: x);
				    fu1 = (x: y: x + y) 4;
				    fu2 = (x: y: (2 * x) + y);
				  in
				  rec {
				    ex00 = fu0 4;                 # 4
				    ex01 = (fu1) 1;               # 5
				    ex02 = (fu2 3 ) 1;            # 7
				    ex03 = (fu2 3 );              # <LAMBDA>s
				    ex04 = ex03 1;                # 7
				    ex05 = (n: x: (fu2 x n)) 1 3; # 7
				  }
				  ```
				- The same principle applies for functions that take attrset:
				  ```nix
				  let
				    arguments = {a="Happy"; b="Awesome";};
				    func = {a, b}: {d, b, c}: a+b+c+d;
				  in
				  {
				    # Evaluates to string "HappyFunctionsAreCalled"
				    A = func arguments {b = "Functions"; c="Are"; d="Called";};
				  }
				  ```
- # Library functions
	- ## `builtins` (sometimes call *primitive operations* or *primops*)
		- Built-in functions implemented in Nix interpreter (C++)
		- See [Nix manual](https://nix.dev/manual/nix/2.18/language/builtins)
		- They are evaluated as `PRIMOPS`:
		  ```nix
		  builtins.toString
		  <PRIMOPS>
		  ```
	- ## `import`
		- > `import` is the only built-in functions available at the top-level without having to refer to namespace `builtins`
		- `import` takes a path to a Nix file, and reads the file to evaluate its expression, returning the evaluated value.
		- If the path points to a directory, `import` reads `default.nix` in that directory
		- If the file evaluates to a function, we can immediately call the imported function:
		  ```sh
		  echo "x: x + 1" > ./foo/default.nix
		  
		  nix repl
		  <nix-repl> import ./foo 5
		  6
		  <nix-repl>
		  ```
	- ## `pkgs.lib`
		- The [nixpkgs](https://github.com/NixOS/nixpkgs) repository provides an attrset called [lib](https://github.com/NixOS/nixpkgs/blob/master/lib/default.nix)
		- Unlike `builtins` which are implemented in C++ and are part of the language, these are implemented in Nix
		- Due to historical reasons, `nixpkgs` `lib` may contains functions very similar to `builtins`
		- The expression in `nixpkgs` happens to be a function, so we must give it some argument - in these examples, an empty attrset `{}`
		- See [Nixpkgs manual](https://nixos.org/manual/nixpkgs/stable/#sec-functions-library)
		- ### Convention (`pkgs`, `lib`, etc.)
			- Due to this naming to `pkgs` convention, we usually see something like this on the internet:
			- By convention, we assign name `pkgs` to expression returned by `import <nixpkgs> {..}`
			- If we want to avoid [lookup path](((660ae72f-2260-4d68-a778-e7a5aad8db86))) `<nixpkgs>`, we can do:
			  ```nix
			  let
			    nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/archive/06278c77b5d162e62df170fec307e83f1812d94b.tar.gz";
			    pkgs = import nixpkgs {};
			  in
			  pkgs.lib.strings.toUpper "always pin your sources"
			  ```
			- We might come across other people's code that looks like this:
			  ```nix
			  { pkgs, ... }:
			  pkgs.lib.strings.removePrefix "no " "no true scotsman"
			  ```
			- In cases like these, we can assume that `pkgs` will refer to `nixpkgs` attrset, and will contain `lib` attribute:
			  ```nix
			  let
			    pkgs = import <nixpkgs> {};
			  in
			  pkgs.lib.strings.toUpper "lookup paths considered harmful"
			  ```
			- And sometimes, we may see other people's code importing attribute `lib`:
			  ```nix
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
- # Impurities
	- Most Nix expressions are pure
	- Examples of impurities are *build inputs*, which may be read from files on the system
	- ## Nix side effects
		- **Paths**: **Whenever a path is used in string interpolation, its content is copied to Nix store**, and the string interpolation expression evals to the absolute path to that file/directory in the Nix store
			- Why copy to Nix store? To make it more reproducible and robust.
			- With hash-enforced access, content file changes will have less detrimental effects on our builds:
			  ```sh
			  # File content is "123"
			  $ echo 123 > data
			  ```
			- We can use the evaluate path to file `data` in some Nix program:
			  ```nix
			  "${./data}" # Path inside string interpolation
			  ```
			- The expression above will evaluate to:
			  ```txt
			  "/nix/store/h1qj5h5n05b5dl5q4nldrqq8mdg7dhqk-data"
			  ```
		- **Fetches**: fetchers are used to get build inputs from non-FS locations (e.g. `builtins.fetchGit`).
			- These fetchers will download the resources to Nix store, and so the fetcher expressions evaluate to Nix store path strings:
			  ```nix
			  builtins.fetchTarball "https://github.com/NixOS/nix/archive/7c3ab5751568a0bc63430b33a5169c5e4784a0ff.tar.gz"
			  ```
			- The fetcher expression will save the files to Nix store. Which means that the expression above evaluates to path string:
			  id:: 66117c4f-535c-43cc-827e-95304192ca79
			  ```txt
			  "/nix/store/d59llm96vgis5fy231x6m7nrijs0ww36-source"
			  ```
- # Simple examples
	- ## Declarative shell
		- We can use `mkShell` function, or, preferably `mkShellNoCC` to describe a shell environment
			- Unlike `mkShell` which uses Nixpkgs `stdenv`, `mkShellNoCC` will build a Nix env against `stdenvNoCC`
		- We can specify programs in that environment with `buildInputs` attr arg, so we can write a Nix file that takes Nixpkgs `pkgs` and consumes our packages from that Nixpkgs:
		  ```nix
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
		- If `pkgs` is not in the caller's argument, this Nix file defaults to importing Nixpkgs using [lookup paths `<nixpkgs>`](((660ae72f-2260-4d68-a778-e7a5aad8db86))) with empty attrset argument: `import <nixpkgs> {}`
	- ## System configuration
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
	- ## Package
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
- # Nix style guide and convention
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
	- ## `callPackage`
		- [`callPackage`](https://github.com/nixos/nixpkgs/commit/d17f0f9cbca38fabb71624f069cd4c0d6feace92) emerges as a convention in Nix community
		- It helps reduce code size by automatically supplying attrs in attrset arguments
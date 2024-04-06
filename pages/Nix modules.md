- > Nix module system could be included in [[Nix language]] section, but I found it deserving a page of their own
- A Nix module is a [Nix file]((660ada16-e454-4f18-bf6f-b5a231487f15))
	- Nix modules are treated a bit differently than other non-module Nix files in Nix ecosystem
- Like most Nix files, a Nix module evaluates to a single expr:
- Nix modules are *standardized Nix files*:
	- But Nix modules expr will need 2 special attrs in its expr: `options` and `config`
	- `options` (attrset) defines exposed module options
	- `config` (attrset) defines how the option is going to be configured.
		- ```nix
		  { lib, config, ... }: # config here is module arg
		  
		  {
		  	options = {..};
		      config = {..}; # config here is module configuration
		  }
		  ```
- # Evaluating Nix modules
  id:: 66103169-7817-4639-8a1a-63ae69f2bcda
	- Let's say we have a module, `default.nix`, and another file `eval.nix` which uses the module and set some options
	- `evalModules` evaluates modules, checks type errors, and merge the module options
		- `evalModules` lazily evaluates and merges the config
		- This allows a module's option to use other module's option values (going back and forth, via `config` *return value* and `config` *arg*)
	- We can use `evalModules` in `eval.nix`:
	- ```nix
	  # eval.nix
	  
	  let
	    nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-22.11";
	    pkgs = import nixpkgs { config = {}; overlays = []; };
	    
	  in
	  pkgs.lib.evalModules {
	    modules = [
	      ./default.nix
	    ];
	  }
	  ```
	- ```sh
	  # Will error because we had not yet
	  # set config.foo.bar in eval.nix
	  
	  $ nix-instantiate --eval eval.nix -A config.foo.bar
	  ```
- # Module system
	- ## Basic option
		- Module options are created using function call `lib.mkOption {..}`
		- This attr is used to tell Nix that this module provides an option that can be set
		- We can use arbitrary names and attr paths in module option definition
		- ```nix
		   { lib, ... }: {
		  	options = {
		  		scripts.output = lib.mkOption {
		  			type = lib.types.lines;
		  		};
		  	};
		   }
		  ```
		- Here we define option `scripts.output`, of [type `lines`](https://nixos.org/manual/nixos/stable/#sec-option-types-basic)
			- Nix will throw errors if the value set in `config` conflicts with the one defined in `options`
			- ```nix
			  # default.nix
			  
			  { lib, ... }: {
			  	options = {
			  		scripts.output = lib.mkOption {
			  		type = lib.types.lines;
			  	};
			  
			  	config = {
			  		scripts.output = 42;
			  	};    
			  }
			  ```
			- Try [evaluating this module](((66103169-7817-4639-8a1a-63ae69f2bcda)))
			- ```sh
			  $ nix-instantiate --eval eval.nix -A config.scripts.output
			  error:
			  ...
			         error: A definition for option `scripts.output' is not of type `strings concatenated with "\n"'. Definition values:
			         - In `/home/nix-user/default.nix': 42
			  ```
			- Instead, we must pass `lines` value to `config.scripts.output`:
			- ```nix
			  # default.nix
			  
			  { lib, ... }: {
			  	options = {
			  		scripts.output = lib.mkOption {
			  		type = lib.types.lines;
			  	};
			  
			  	config = {
			  		scripts.output = ''
			          	Some Random Output String
			          '';
			  	};   
			  }
			  ```
	- ## Complex options
		- Sometimes, our module might expose more than 1 option
		- And these options may depend on other option values
- # Tip: reproducible shell script module
	- Let's say we have a `map` shell script that calls `curl` and `feh`
	- And our module was like this, using string as script
	- ```nix
	  # DO NOT DO THIS
	  # mod.nix
	  
	  { lib, ... }: {
	  	options = {
	  		scripts.output = lib.mkOption {
	  		type = lib.types.lines;
	  	};
	  
	  	config = {
	      	# Original script command
	  		scripts.output = ''
	          	./map size=640x640 scale=2 | feh -
	          '';
	  	};    
	  }
	  ```
	- Since Nix only sees `./map ...` (and as string too!)
	- Nix has no way to know that `map` internally uses `curl`, and that package `feh` is also required
	- Which means that this script will fail on systems without `curl` and `feh`
	- To fix this, simply package `map` as a script with `mkShellApplication`, with Nixpkgs constraints:
	- ```nix
	  # mod.nix
	  
	  { pkgs, lib, ... }: {
	  
	  	options = {
	  		scripts.output = lib.mkOption {
	          
	          	# Notice how type is now package
	  			type = lib.types.package;
	  		};
	  	};
	  
	  	config = {
	  		scripts.output = pkgs.writeShellApplication {
	  			name = "map";
	        
	  			# Tell Nix that this expr requires pkgs.{curl,feh}
	  			runtimeInputs = with pkgs; [ curl feh ];
	        
	  			# Note how we now use ${./map}
	              text = ''
	  				${./map} size=640x640 scale=2 | feh -
	  			'';
	       	};
	  	};
	  }
	  ```
	- Here, this module now also takes `pkgs`.
	- Thanks to `mkShellApplication`, the output is now a shell script saved in Nix store and linked to `./result`
		- ```sh
		  $ nix-build eval.nix -A config.scripts.output
		  $ ./result/bin/map
		  ```
	- Dependency packages `curl` and `feh` will then come from this `pkgs`
	- We also change text output with string interpolation on path `${./map}`, [which has side effects of copying the file `./map` to Nix store](((660c39e1-3de2-417a-8d00-04f98f4d17f5)))
	- Let's say we have another file, `eval.nix`, which [evaluates this module](((66103169-7817-4639-8a1a-63ae69f2bcda)))
	- Because of `evalModules` in `eval.nix`, then we can't just pass pkgs to `mod.nix` as with normal function calls.
	- We instead have to modify `config._module.args` to use `pkgs` from `eval.nix`, which we do so via a dummy module loaded before `mod.nix`
	- ```nix
	  pkgs.lib.evalModules {
	  	modules = [
	      
	      	# A dummy module that rewrites
	  		({ config, ... }: { config._module.args = { inherit pkgs; }; })
	          
	          # Now mod.nix will get the same pkgs
	          ./mod.nix
	      ];
	  }
	  ```
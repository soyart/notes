- Nix flakes allow users to *pin versions* of the builds, via lock files like `go.mod` and `go.sum` in Go
- NIx flakes are defined in a specific way, in `flakes.nix`
- # A Nix flake
	- **A flake is a directory tree**, with a `flake.nix`
	- Flakes can be referenced by other flakes
- # Caveats
	- If a flake is defined in a [[Git]] repository, then it can only referenced the files within that Git repository
	- All files referenced by any flakes are copied over to [[Nix store]], which is world-readable
- # Anatomy of `flake.nix`
	- `description` -> string description
	- `inputs` -> an attrset representing the flake's version-pinned dependencies
		- We can define our own inputs as top-level attrs in the `inputs` set:
		  ```nix
		  inputs.foo = {
		  	type = "github";
		      owner = "soyart";
		      repo = "foo";
		  }
		  ```
		  This creates an input named `foo`, which will be passed to function `outputs`
		- Usually, a flake input is also expected to be a flake. We can override that by setting attr `flake` of a particular input to false:
		  ```nix
		  inputs.grcov = {
		    type = "github";
		    owner = "mozilla";
		    repo = "grcov";
		    flake = false;
		  };
		  
		  outputs = { self, nixpkgs, grcov }: {
		    packages.x86_64-linux.grcov = stdenv.mkDerivation {
		      src = grcov;
		      # ...
		    };
		  };
		  ```
	- `outputs` -> an Nix function representing realized/evaluated outputs
		- Resolved inputs are passed to the functions `outputs`
		- Typical `outputs` function looks like this:
		  ```nix
		  outputs = { self, nixpkgs, some-input-name }: {
		  	# ..Outputs..
		  };
		  ```
		- We can also omit the inputs entirely, and only list them as expected args to `outputs` function:
		  ```ni
		  inputs = {
		  	# ..Inputs..
		  };
		  outputs = { self, nixpkgs }: ...;
		  ```
		  If `inputs.nixpkgs` are not defined, and Nix knows that `inputs.nixpkgs` are required, then Nix will do something equivalent to:
		  ```nix
		  inputs.nixpkgs = {
		  	type = "indirect";
		      id = "nixpkgs";
		  };
		  ```
	- `nixConfig` -> attrset to be given to `nix.conf`
- # Flake inputs and outputs
	- Flake inputs are Nix attrset mapping input names to flake references
	- We can specify each input names with an attrset:
	  ```nix
	  # flake.nix
	  inputs.import-cargo = {
	  	type = "github";
	      owner = "soyart";
	      repo = "soyutils";
	  };
	  
	  inputs.nixpkgs = {
	  	type = "indirect";
	      id = "nixpkgs";
	  };
	  ```
	  Or a URL with field `url`:
	  ```nix
	  inputs.import-cargo.url = "github:soyart/soyutils"
	  inputs.nixpkgs.url = "nixpkgs";
	  ```
	- After we gave our inputs a name (e.g. `imports-cargo` and `nixpkgs`), Nix then fetches and evaluates the inputs. They are then passed to `outputs` function with the exact same names
	- ## `follows` and overrides
		- We can override transitive inputs (assuming it's also a flake):
		  ```nix
		  inputs.nixops.inputs.nixpkgs = {
		    type = "github";
		    owner = "my-org";
		    repo = "nixpkgs";
		  };
		  ```
		  This overrides `inputs.nixpkgs` of our top-level inputs `nixops`
		- Flakes inputs can be inherited from other flake's inputs with `follows` attr:
		  ```nix
		  inputs.nixpkgs.follows = "some/nixpkgs";
		  ```
		  This sets the top-level `nixpkgs` inputs of the flake to be equal to that of a flake in `some/nixpkgs`.
		- The values of `follows` is a path-separated sequence of input names from the root flake, i.e. `some/nixpkgs` is referencing `inputs.some.inputs.nixpkgs`
		- We can also mix `follows` with overrides:
		  ```nix
		  inputs.nixops.inputs.nixpkgs.follows = "some/nixpkgs";
		  ```
		-
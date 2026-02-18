# Ad-hoc shell
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
- # Reproducible script
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
- # Declarative shell
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
	- ## Pinning Nixpkgs
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
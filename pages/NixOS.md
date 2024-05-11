- NixOS is a Linux distro managed by [[Nix]]
- # Configuration
	- By default, `nixos-rebuild` reads `/etc/configuration.nix`
	- But on real hardware, `/etc/configuration.nix` usually imports `./hardware-configuration.nix`
	- We can generate both of these files with: `nixos-generate-config`
		- This command can detect mountpoints, and add them accordingly to `hardware-configuration.nix`
		- This command can also detect CPU and other hardware, generating config with required kernel modules
	- ## Inspecting NixOS config
		- We can use `nix` cli tool to evaluate the system config:
		  ```sh
		  $ nix repl --file '<nixpkgs/nixos>'
		  Welcome to Nix 2.13.3. Type :? for help.
		  Loading installable ''...
		  Added 6 variables.
		  nix-repl>
		  ```
- # NixOS virtual machine
	- On any systems with Nix installed, we can create a VM with `nix-build` command
	- ```sh
	  nix-build '<nixpkgs/nixos>' -A vm \
	  -I nixpkgs=channel:nixos-23.11 \
	  -I nixos-config=./configuration.nix
	  ```
	- > If you are on NixOS, there's a simpler command that achieves similar results:
		- ```sh
		  nixos-rebuild build-vm -I nixos-config=./configuration.nix
		  ```
	- The `nix-build` command will build a new derivation with [`vm` attribute](((660add7d-d05c-4ec6-b533-5c39f6014708))), using `./configuration.nix` as NixOS config
	- The build outputs in Nix store will also be linked into `./result`:
		- ```sh
		  $ ls -al ./result
		  result:
		  bin  system
		  
		  result/bin:
		  run-nixos-vm
		  ```
	- We can run the VM like so:
	- ```sh
	  QEMU_KERNEL_PARAMS=console=ttyS0 ./result/bin/run-nixos-vm -nographic; reset
	  ```
		- `-nographic` => runs QEMU in console/terminal
		- `console=ttyS0` => will also show the boot process, which ends at the console login screen.
	- Each VM run will create a QEMU disk image `./nixos.qcow2`, which is persistent
	- States from previous VM runs, e.g. user password, are still in `nixos.qcow2`, so delete this file if we want a brand new system
	- ## NixOS Tests
		- > NixOS manual: [NixOS Tests](https://nixos.org/manual/nixos/stable/index.html#sec-nixos-tests)
		- NixOS provides reproducible test environments via VMs, and they are called **NixOS Tests**
		- These tests can be defined with **Nix**, and interacted with via **Python shell** (through QEMU)
		- These tests start VMs and then run the Python scripts
		- ### Defining tests with`testers.runNixOSTest`
			- ```nix
			  let
			    nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-23.11";
			    pkgs = import nixpkgs { config = {}; overlays = []; };
			  in
			  
			  pkgs.testers.runNixOSTest {
			    name = "test-name";
			    nodes = {
			      machine1 = { config, pkgs, ... }: {
			        # ...
			      };
			      machine2 = { config, pkgs, ... }: {
			        # ...
			      };
			    };
			    testScript = { nodes, ... }: ''
			      # ...
			    '';
			  }
			  ```
			- `testers.runNixOSTest` takes a [[Nix modules]] as an argument
			- `name` attr is required
			- `nodes` attr defines a list of VMs
			- [`testScript` attr](https://nixos.org/manual/nixos/stable/index.html#test-opt-testScript) defines the Python test script, either as literal string or as a function that takes a nodes attribute
				- The Python script can access each VM defined in `nodes` with its name
				- The Python script *has superuser* privileges
				- Each machine is accessed and represented via [`machine` object](https://nixos.org/manual/nixos/stable/index.html#ssec-machine-objects)
				  id:: 661025f8-6c01-4413-a32c-4341e2612e0d
		- ### Example 1 (1 VM)
		  id:: 66102669-3338-4208-a90e-d6fd005a536f
			- ```nix
			  # minimal-test.nix
			  
			  let
			    nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-23.11";
			    pkgs = import nixpkgs { config = {}; overlays = []; };
			  in
			  
			  pkgs.testers.runNixOSTest {
			    name = "minimal-test";
			  
			    nodes.machine = { config, pkgs, ... }: {
			  
			      users.users.alice = {
			        isNormalUser = true;
			        extraGroups = [ "wheel" ];
			        packages = with pkgs; [
			          firefox
			          tree
			        ];
			      };
			  
			      system.stateVersion = "23.11";
			    };
			  
			    testScript = ''
			      machine.wait_for_unit("default.target")
			      machine.succeed("su -- alice -c 'which firefox'")
			      machine.fail("su -- root -c 'which firefox'")
			    '';
			  }
			  ```
			- Here, since we only have 1 VM to define, we write `nodes` attr in short form (with only 1 attr `machine`, which is the name of our test VM)
			- [The object `machine` in Python test script **is NOT** from `nodes.machine` attr](((661025f8-6c01-4413-a32c-4341e2612e0d)))
			- The Python script validates that our VM will get to systemd `default.target`
			- It also validates that *only user `alice` has access to `firefox` binary* in their Nix environment
			- We can then run it with `nix-build`
			- ```sh
			  $ nix-build minimal-test.nix
			  ```
		- ### Interactive Python shell
			- > Assume we still work on [Example 1](((66102669-3338-4208-a90e-d6fd005a536f)))
			- Start interactive Python shell
			- ```sh
			  $(nix-build -A driverInteractive minimal-test.nix)/bin/nixos-test-driver
			  ```
			- Once inside, we can run test script defined in `testScript`
			- ```python
			  >>> test_script()
			  ```
			- Object `machine` is lazily initiated
				- Though we can manually start it inside the Python shell with:
				- ```python
				  >>> machine.start() # Specific node
				  ```
				- If our test however has several VMs, manually start them all with
				- ```python
				  >>> start_all()
				  ```
		- ### Example 2 (2 VMs)
			- This test involves 2 VMs, `server` and `client`
			- `server` has vanilla, default NGINX running
			- `client` has `curl` and should be able to access `server` via HTTP on port 80
			- ```nix
			  # client-server-test.nix
			  
			  let
			    nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-23.11";
			    pkgs = import nixpkgs { config = {}; overlays = []; };
			  in
			  
			  pkgs.testers.runNixOSTest {
			    name = "client-server-test";
			  
			    nodes.server = { pkgs, ... }: {
			      networking = {
			        firewall = {
			          allowedTCPPorts = [ 80 ];
			        };
			      };
			      services.nginx = {
			        enable = true;
			        virtualHosts."server" = {};
			      };
			    };
			  
			    nodes.client = { pkgs, ... }: {
			      environment.systemPackages = with pkgs; [
			        curl
			      ];
			    };
			  
			    testScript = ''
			      server.wait_for_unit("default.target")
			      client.wait_for_unit("default.target")
			      client.succeed("curl http://server/ | grep -o \"Welcome to nginx!\"")
			    '';
			  }
			  ```
			- Now we can run it
			- ```sh
			  $ nix-build client-server-test.nix
			  ```
- # Custom ISO image
	- First, grab something from the official image in `imports`
	- Then add attrs that you need to change
	- ```nix
	  { pkgs, modulesPath, lib, ... }: {
	    imports = [
	      "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
	    ];
	  
	    # Use the latest Linux kernel
	    boot.kernelPackages = pkgs.linuxPackages_latest;
	  
	    # Needed for https://github.com/NixOS/nixpkgs/issues/58959
	    boot.supportedFilesystems = lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];
	  }
	  ```
	- Build and write to device
	- ```sh
	  $ export NIX_PATH=nixpkgs=https://github.com/NixOS/nixpkgs/archive/74e2faf5965a12e8fa5cff799b1b19c6cd26b0e3.tar.gz
	  $ nix-shell -p nixos-generators --run "nixos-generate --format iso --configuration ./myimage.nix -o result"
	  
	  $ dd if="./result/iso/*.iso" of="/dev/sdc" status=progress
	  $ sync
	  ```

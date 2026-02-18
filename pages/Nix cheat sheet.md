## Find dependencies
	- ```sh
	  # See man's direct dependencies
	  $ nix-store -q --references `which man`
	  
	  # See main's direct dependents
	  $ $ nix-store -q --referrers `which hello`
	  
	  # See full, recursive dependency list of whichever `man` is in PATH
	  $ nix-store -qR `which man`
	  $ nix-store -q --tree `which man`
	  $ nix-store -q --tree ~/.nix-profile
	  ```
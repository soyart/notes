- #Git
- # Reset to some branch/ref:
  ```sh
  git reset --hard origin/master # Reset to master from origin
  git reset --hard deadbeef
  ```
	- After resets, old unreferenced objects still live in `.git/objects`
- # Garbage collection and pruning
	- Our Git repositories will be filled with garbage with time
	- We need a way to discard these less important history data, and preserve history of commits we care about
	- Enter `git prune` and `git gc`
	- ## `git prune`
		- Removes *loose* + *stale* + *unreachable* [[Git objects]]
		- Unreachable objects remain in their pack files
		- Reachable loose object remain loose
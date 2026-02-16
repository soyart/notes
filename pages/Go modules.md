- > Read more: https://go.dev/ref/mod #[[Go]]
- Go modules and packages are code organization strategy, first introduced in Go 1.11 and became default, replacing `$GOPATH` in Go 1.12
- Go modules are cached by `go get` at `$GOPATH/mod`
- Go modules are identify by a `go.mod` at the module's root
- Go modules can be nested
- # `go` commands for working with modules
	- `go list -m all` lists all modules used by the current module
		- The first output line is always the current module
		- The rest are other dependency modules sorted alphabetically
	- `go mod edit -replace $IMPORT=$TARGET@REF`
		- Example 1: use commit hash `ea84732a7725`
			- ```sh
			  go mod edit -replace github.com/docker/docker=github.com/docker/engine@ea84732a7725
			  ```
			- Equivalent to this line in `go.mod`:
			  ```go
			  replace github.com/docker/docker => github.com/docker/engine v17.12.0-ce-rc1.0.20191113042239-ea84732a7725+incompatible
			  ```
		- Example 2: pin tagged version `v1.13.1`
			- ```sh
			  go mod edit -replace github.com/docker/docker@v1.13.1=github.com/docker/engine@ea84732a7725
			  ```
			- Equivalent to this line in `go.mod`
			  ```go
			  replace github.com/docker/docker v1.13.1 => github.com/docker/engine v17.12.0-ce-rc1.0.20191113042239-ea84732a7725+incompatible
			  ```
- # Go packages
	- The smallest unit of code organization in Go is *Go package*, which maps to a directory
	- Code in the same package must reside in the same category
- # Versioning
	- Go modules strictly follow [[semver]]
	- In a Go module, if we do `go get example.com/pkg/hello` without specifying specific version, then the `go` command will select the *latest* revision based on precedence:
		- Highest *tagged* non-[prerelease](https://semver.org/#spec-item-9) version
		- Highest *tagged* prerelease version
			- Pre-releases examples:
			  ```
			  # stable
			  v2.6.7
			  
			  # prereleases
			  v2.6.7-pre.1.2.4
			  v2.6.7-alpha.1
			  ```
		- Highest *untagged* version
			- If the *latest* revision is untagged, go will use ((67fd3e0a-b532-4510-a9a5-5c39ed4f6b41))
			- See also: this example
			- ((67fd43d2-8bb1-4bf1-9f3f-58a8cfbd2bdc))
			  id:: 67fd464b-57a5-4a66-9ace-73a4804de62d
	- ## Module Path vs Import Path
		- Module path is defined in `go.mod`
			- Module path uniquely identifies the module root
		- Import path is used in `import` directive in Go source
			- Package path is a synonym to import path
			- Package/import path uniquely identifies a package
			- In this sense, we can say that package path is the module path joined with the sub-dir of the package
		- ### Major version suffix
		  id:: 67fd4698-4af6-4f04-9308-54cea019cb80
			- > This usually only matters if your module some how gets to `v2`
			  > See also: https://go.dev/ref/mod#major-version-suffixes
			- Major version suffix addresses import compatibility rule:
			  > If an old package and a new package have the same import path, the new package must be backwards compatible with the old package.
			- Major version suffixes assumes that major versions will always break compatibility
			- Major version suffixes let multiple major versions of a module coexist in the same build
				- This prevents [diamond dependency problem](https://research.swtch.com/vgo-import#dependency_story)
				- And also satisfy transitive dependencies
					- For example, let's say we directly import modules `a` and `b`
					- And `a` imports package `x` `v2.3.5`, while `b` imports `v3.2.1`
						- `example.com/a/a.go`:
						  ```go
						  package a
						  import "example.com/x/v2"
						  func A() {
						    fmt.Println("from module a")
						  }
						  ```
						- `example.com/b/b.go`:
						  ```go
						  package b
						  import "example.com/x/v3"
						  func B() {
						    fmt.Println("from module b")
						  }
						  ```
					- Naturally, Go will choose to import the revision `v3.2.1` of `x`
					- But since both `a` and `b` are using different import paths for their own dependencies, then the modules must be separate and thus will not break
			- Import path must match module path for versions starting from `v2`
				- i.e. If a module has the path `example.com/mod` at `v1.0.0`, it must have the path `example.com/mod/v2` at version `v2.0.0`.
				- Example 3
					- Let's say we have a module `example.com/foo`, now at `v1.12.7`
					- However, we're also rolling out a new major version `v2.0.0`, which provides its own `Foo(string) error`
					- But this v2 thinggy is separately developed by another team
					- Then you can just create a new repository for `v2`: `example.com/foo/v2`
					- This is good, because if later on, we decide to change `Foo(string) error` to just `Foo([]byte) error` in `v2.0.0`, then it can be done in its own repository
					- This ensures that the major version `v1` can continue to get new support
					- Different import paths -> different modules -> different repository
				- Example 2
					- Let's say we have a module `example.com/foo`, now at `v1.12.7`
					- This module is very flat and only contains 1 package (no sub-dirs)
					- And we want to maintain support for the current major version `v1`
					- And we want to do it in the same module
					- This module provides a function `Foo(string) error` in `/foo.go`
					- However, we're also rolling out a new major version `v2.0.0`, which provides its own `Foo(string) error`
					- Then we must put our new `v2.0.0.0` source in the `/v2` sub-dir of the module
					- This is good, because if later on, we decide to change `Foo(string) error` to just `Foo([]byte) error` in `v2.0.0`, then it can be done in `/v2/foo.go` without breaking diamond dependency
	- ## Pseudo-version
	  id:: 67fd3e0a-b532-4510-a9a5-5c39ed4f6b41
		- The `go` command gives untagged revision a [pseudo-version](https://go.dev/ref/mod#pseudo-versions)
		- id:: 67fd43d2-8bb1-4bf1-9f3f-58a8cfbd2bdc
		  ```shell
		  $ go get github.com/soyart/ssg
		  go: added github.com/soyart/ssg v0.0.0-20250413195948-88557d4a8f35
		  ```
		- Here, `v0.0.0-20250413195948-88557d4a8f35` is the pseudo-version
		- ### The 3 parts of p-version
			- ### Base version
			  id:: 67fd4395-3dca-4070-ba5c-c5d84fc54596
				- The base is the first part of the p-version
				- The base is derived from previous tagged semversion
				- If there is no such previous tag, then `v0.0.0`
					- From this [example](((67fd43d2-8bb1-4bf1-9f3f-58a8cfbd2bdc))), we see that the p-version base is `v0.0.0`
					- We can imply that there's never been a semver-tagged revision preceding our target revision for module `github.com/soyart/ssg`
			- ### Timestamp
				- Git **commit time** in UTC (not author times!)
					- Author time gets preserved forever, while commit time may changes, e.g. when we're doing rebasing and cherry-picking commits
				- From this [example](((67fd43d2-8bb1-4bf1-9f3f-58a8cfbd2bdc))),, the timestamp is `20250413195948`
			- ### Hash
				- Content hash
				- From this [example](((67fd43d2-8bb1-4bf1-9f3f-58a8cfbd2bdc))), the hash is `88557d4a8f35`
		- ### The 3 forms of p-version
			- > Note: note that p-version is for untagged revisions only!
			- Depending on the ((67fd4395-3dca-4070-ba5c-c5d84fc54596)), a p-version can only be in 3 forms
			- ### `vX.0.0-yyyymmddhhmmss-abcdefabcdef`
				- **This form is used when there's no base revision for major version `vX`**
					- Because it concerns major versions, you could have `v0.0.0`, `v1.0.0`, or even `v2.0.0`
				- And major version `vX` must match the ((67fd4698-4af6-4f04-9308-54cea019cb80))
				- The `v0.0.0` in this example is an example of this {{embed ((67fd464b-57a5-4a66-9ace-73a4804de62d))}}
			- ### `vX.Y.Z-pre.0.yyyymmddhhmmss-abcdefabcdef`
				- **This form is used when the base is a pre-release**
				- The base revision is a pre-release `vX.Y.Z-pre`
			- ### `vX.Y.(Z+1)-0.yyyymmddhhmmss-abcdefabcdef`
				- **Base version is a release**
				- The base revision is stable `vX.Y.Z`
		- ### More than 1 p-versions can refer to the same commit
			- This can happen when different base versions are used
			- Like when p-version is written first from untagged commit `a1b1c1d`, which later gets tagged
		- ### Sorting against non-pseudo-versions
			- For example, if the base version is `v3.2.1-alpha`
			- Then p-versions like `v3.2.1-alpha.0.20250413195948-88557d4a8f35`
				- Note the `-0.` after `v3.2.1-alpha`
				- This will make sorting cool
			- Then our p-version will always sort:
			- **Higher** than `v3.2.1`
			- **Higher** than base `v3.2.1-alpha`
			- **Lower** than pre-releases `v3.2.1-alpha`, and `v.3.2.1-pre.1.2`
			- **Lower** than later versions `v3.2.2`, and `v3.2.3`
			- P-versions of the same base sort chronologically thanks to the timestamp
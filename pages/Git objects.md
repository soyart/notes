- > https://git-scm.com/book/en/v2/Git-Internals-Git-Objects
- Git objects are what's stored in `.git/objects`, also called *object database*
- An object also has its own type, such as blob and tree
- # Git as content-addressable store
	- At the core, Git is content-addressable filesystem, meaning:
		- We can insert data into Git
		  logseq.order-list-type:: number
		- Git will return a unique key for the stored data
		  logseq.order-list-type:: number
		- We can use to retrieve the data from Git later
		  logseq.order-list-type:: number
	- Git stores content similar to UNIX filesystems:
		- *Everything* is stored as tree and blob objects
		- *Trees* correspond to UNIX filesystem *directory entries*
		- *Blobs* correspond to *inodes, or file content*
- # Walkthrough
	- A simple walkthrough with `git hash-object` and `git cat-file`
	- We can use low-level `git hash-object` to see how hashing works
		- Initialize **empty** repository and inspect the object db:
		  ```sh
		  $ cd ~/git
		  $ git init test
		  Initialized empty Git repository in ~/git/test/.git/
		  $
		  $ cd test
		  $ find .git/objects
		  .git/objects
		  .git/objects/info
		  .git/objects/pack
		  $ find .git/objects -type f
		  ```
		  So, no object files are created yet
		- Give `hash-object` some data, in this case, string `test content`:
		  ```sh
		  $ echo 'test content' | git hash-object --stdin
		  d670460b4b4aece5915caf5c68d12f560a9fe3e4
		  ```
		- And we get a hash for the data `test content` is `d670460b4b4aece5915caf5c68d12f560a9fe3e4`. The string should return the same hash every time on every machine
	- We can also use `hash-object -w` to also write the given data to object db:
		- > `git hash-object -w` takes some data, writes the data as objects into `.git/objects`, and returning back a hash
		- ```sh
		  echo 'test content' | git hash-object -w --stdin
		  d670460b4b4aece5915caf5c68d12f560a9fe3e4
		  
		  # Check stored data
		  find .git/objects -type f
		  .git/objects/d6/70460b4b4aece5915caf5c68d12f560a9fe3e4
		  ```
		- This would have put `test content` into object db
		- This is how Git store *new* data initially: as a single Git object file, named with its content hash
			- > Note: The reason it could fit a single file is because our data `test content` is quite small
		- Each objects are also organized into directory whose name is the first 2 characters of the object hash, so in our case, the object lives in `.git/objects/d6`, and the actual object filename starts with `704..` instead of `d6704..`
	- We can use `git cat-file` to inspect data represented by each Git object
		- > Here we use `-p` to make `cat-file` figure out the object's content type before printing it out properly
		- ```sh
		  git cat-file -p d670460b4b4aece5915caf5c68d12f560a9fe3e4
		  test content
		  ```
	- So now we can store and retrieve data from Git. Hooray!
	- Other than stdin, we can also use `git hash-object` with file content
		- id:: 6a23086c-062d-4c08-a719-124998bf5e81
		  ```sh
		  echo 'version 1' > test.txt
		  git hash-object -w test.txt
		  83baae61804e65cc73a7201a7252750c76066a30
		  
		  echo 'version 2' > test.txt
		  git hash-object -w test.txt
		  1f7a7a472abf3dd9643fd615f6da379c4acb3e3a
		  
		  $ find .git/objects -type f
		  .git/objects/1f/7a7a472abf3dd9643fd615f6da379c4acb3e3a
		  .git/objects/83/baae61804e65cc73a7201a7252750c76066a30
		  .git/objects/d6/70460b4b4aece5915caf5c68d12f560a9fe3e4
		  ```
		- Note that we now have 3 objects: the first one when we first played with `hash-object -w`, and the 2 versions of `test.txt`
		- We can remove `test.txt` and use Git to retrieve the data from Git objects, and restore the file content to matched the returned data:
		  ```sh
		  rm test.txt
		  git cat-file -p 83baae61804e65cc73a7201a7252750c76066a30 > test.txt
		  cat test.txt
		  version 1
		  ```
		- These 3 objects only contain the content data, not any other metadata like timestamps or other stuff
		- We call these data-only objects [[blobs]] . We can use `cat-file -t` to figure that out:
		  ```sh
		  git cat-file -t d670460b4b4aece5915caf5c68d12f560a9fe3e4
		  blob
		  git cat-file -t 83baae61804e65cc73a7201a7252750c76066a30
		  blob
		  git cat-file -t 1f7a7a472abf3dd9643fd615f6da379c4acb3e3a
		  blob
		  ```
- # Git object types
	- ## [[Git blob]]
		- Blob objects store data, i.e. the file content
		- Git usually compresses file content using zlib before creating objects
		- Metadata such as timestamps and filenames are not stored in blobs
	- ## [[Git tree]] #Tree
		- Tree objects can track filenames and group files together
		- Each tree object represents a snapshot of the repository
		- A single tree object contains >1 entries
			- Each tree entry is a SHA-1 hash pointing to a blob, or a subtree with associated metadata (e.g. filesystem mode, type, filenames)
			- Note that in Git, only 3 filesystem modes are valid for blobs:
				- `100644` normal files
				- `100755` executable
				- `120000` symlink
			- For example, let's say our repository `master` branch looks like this:
			  ```sh
			  git cat-file -p master^{tree}
			  100644 blob a906cb2a4a904a152e80877d4088654daad0c859      README
			  100644 blob 8f94139338f9404f26296befa88755fc2598c289      Rakefile
			  040000 tree 99f1a6d12cb4b6f19c8655fca46c3ecf317074e0      lib
			  ```
				- > `master^{tree}` syntax specifies the tree object that is pointed to by the last commit on branch `master`
				  >
				  > You might also want to write `master^{tree}` as `"master^{tree}"` on zsh
			- We can see that the tree `master` currently points to have 3 entries, 2/3 of which are blobs
			- But `99f1a6d` is a (sub)tree, pointing to `./lib` directory:
			  ```sh
			  git cat-file -p 99f1a6d12cb4b6f19c8655fca46c3ecf317074e0
			  100644 blob 47c6340d6459e05787f644c2447d2595f5d3a54b      simplegit.rb
			  ```
			- So `99f1a6d` represents `./lib`, a directory containing only 1 file, `simplegit.rb`, represented by single blob `47c634`
			- {{renderer code_diagram,mermaid}}
				- ```mermaid
				  graph LR
				      subgraph master_tree ["master^{tree}"]
				          direction TB
				          E1[100644 blob a906cb... README]
				          E2[100644 blob 8f9413... Rakefile]
				          E3[040000 tree 99f1a6... lib]
				      end
				  
				      subgraph lib_tree [lib tree]
				          direction TB
				          E4[100644 blob 47c634... simplegit.rb]
				      end
				  
				      E3 --> lib_tree
				  ```
		- ### Creating Git trees
			- Git normally creates a tree by taking the snapshot of [[Git staging area]] or [[Git index]], and writing tree objects to it (i.e. *commit*)
			- To create a Git tree, we need to have Git index beforehand, maybe by staging
				- > Note: `update-index` also writes new objects in the database
				- ((6a23144a-c2a4-4822-8184-fec10e82627d))
			- After we have our index, we can use `git write-tree` to write a new [[Git tree]] object from the updated index:
			  id:: 6a2315f7-0c5b-42be-a798-c70e1db9a012
			  ```sh
			  # Create a new tree out of current index
			  git write-tree
			  d8329fc1cc938780ffdd9f94e0d364e0ea74f579
			  
			  # Confirm the object is a tree
			  git cat-file -t d8329fc1cc938780ffdd9f94e0d364e0ea74f579
			  tree
			  
			  # Inspect the tree
			  git cat-file -p d8329fc1cc938780ffdd9f94e0d364e0ea74f579
			  100644 blob 83baae61804e65cc73a7201a7252750c76066a30      test.txt
			  ```
				- Note: `git write-tree` only reads from index, and leaves the index alone
					- Reads `.git/index`
					- Writes new tree objects to `.git/objects`
			- Let's see how Git index handles overwrites, by adding the second version of `test.txt` to the index
			  ```sh
			  # "Overwrite" test.txt in index
			  git update-index --cacheinfo 100644 \
			    1f7a7a472abf3dd9643fd615f6da379c4acb3e3a test.txt
			  
			  # Write out a tree
			  git write-tree
			  2f39845a4a2c3ad86adebb00b1ddabd959c131c4
			  
			  # Output tree only contains the latest version added to index
			  git cat-file -p
			  100644 blob 1f7a7a472abf3dd9643fd615f6da379c4acb3e3a    test.txt
			  ```
			- Let's also add a new file and see the tree:
			  ```sh
			  # Create new file and add it to index (note: we're giving the whole file, no for cacheinfo flag)
			  echo 'new file' > new.txt
			  git update-index --add new.txt
			  
			  git write-tree
			  0155eb4229851634a0f03eb265b69f5a2d56f341
			  
			  git cat-file -p 0155eb4229851634a0f03eb265b69f5a2d56f341
			  100644 blob fa49b077972391ad58037050f2a75f74e3671e92    new.txt
			  100644 blob 1f7a7a472abf3dd9643fd615f6da379c4acb3e3a    test.txt
			  ```
			- Any tree with `new.txt` pointing to `fa49b0` and `test.txt` pointing to `1f7a7a` is the same tree `0155eb`, regardless of the order of blobs being pushed into the index:
				- ```sh
				  cd ~/git
				  git init learngit
				  cd learngit
				  
				  # Empty repository
				  find .git -type f -name index
				  # Nothing
				  find .git/objects -type f
				  # Nothing
				  
				  # Add latest version of test.txt only
				  echo 'version 2' > test.txt
				  git update-index --add test.txt # Add to object DB and index
				  find .git -type f -name index
				  .git/index
				  find .git/objects -type f
				  .git/objects/1f/7a7a472abf3dd9643fd615f6da379c4acb3e3a
				  
				  echo 'new file' > new.txt
				  git update-index --add new.txt
				  find .git/objects -type f
				  .git/objects/1f/7a7a472abf3dd9643fd615f6da379c4acb3e3a
				  .git/objects/fa/49b077972391ad58037050f2a75f74e3671e92
				  
				  # Test that `new file` is indeed fa49b0:
				  echo 'new file' | git hash-object --stdin
				  fa49b077972391ad58037050f2a75f74e3671e92
				  
				  # Write and inspect tree
				  git write-tree
				  0155eb4229851634a0f03eb265b69f5a2d56f341
				  git cat-file -p 0155eb4229851634a0f03eb265b69f5a2d56f341
				  100644 blob fa49b077972391ad58037050f2a75f74e3671e92    new.txt
				  100644 blob 1f7a7a472abf3dd9643fd615f6da379c4acb3e3a    test.txt
				  ```
			- ### Reading and nesting Git trees
				- Git trees can be read with `git read-tree`
				- Example: nesting trees
					- From "create tree" example, we have 2 independent trees `2f3984` (1 file, version 1) and `0155eb` (2 files, version 2), where they point to tree containing `test.txt` with version 1 data, and version 2 data, respectively
					- `0115eb` (v2) happens to be our current staging area
					- We can try to put the v1 tree into the staging area, under `/bak`:
					  ```sh
					  git read-tree --prefix=bak d8329fc1cc938780ffdd9f94e0d364e0ea74f579
					  git write-tree
					  3c4e9cd789d88d8d89c1073707c3585e41b0e614
					  
					  git cat-file -p 3c4e9cd789d88d8d89c1073707c3585e41b0e614
					  040000 tree d8329fc1cc938780ffdd9f94e0d364e0ea74f579      bak
					  100644 blob fa49b077972391ad58037050f2a75f74e3671e92      new.txt
					  100644 blob 1f7a7a472abf3dd9643fd615f6da379c4acb3e3a      test.txt
					  ```
					- {{renderer code_diagram,mermaid}}
						- ```mermaid
						  graph TD
						      %% Styling Configuration
						      classDef treeNode fill:#f9f,stroke:#333,stroke-width:2px;
						      classDef blobNode fill:#bbf,stroke:#333,stroke-width:1px;
						      
						      %% Root Tree Object
						      Tree3["tree 3c4e9c"]:::treeNode
						      
						      %% Subtree Object
						      Tree1["tree d8329f (bak)"]:::treeNode
						      
						      %% Blob Objects
						      BlobNew["blob fa49b0 (new.txt)"]:::blobNode
						      BlobV2["blob 1f7a7a (test.txt v2)"]:::blobNode
						      BlobV1["blob 83baae (test.txt v1)"]:::blobNode
						      
						      %% Relationships
						      Tree3 -->|bak| Tree1
						      Tree3 -->|new.txt| BlobNew
						      Tree3 -->|test.txt| BlobV2
						      
						      Tree1 -->|test.txt| BlobV1
						  
						  ```
	- ## [[Git commit]]
		- Each Git tree is a snapshot, so in theory, this is enough to track all history
			- But it's tiring to remember SHA-1 hashes for every version of our project
			- Trees by themselves also don't have these information: author, author time, and some message
		- The Git commit object type provides those functionalities to us instead of mere Git trees
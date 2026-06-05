- > See also: [[Git cheat sheet]]
- Git is a version control system originally developed by Linus Torvalds for Linux development
- In Git, code is hosted and tracked on a "Git repository"
- Git repositories are self-hosting, and are distributed by design
	- i.e. each repo is a repo in its own right
- Git tries to be least destructive, and will track everything by default. If we can remember this it'll help to reason with Git behaviors
- # Git as content-addressable store
	- At the core, Git is content-addressable filesystem, meaning:
		- We can insert data into Git
		  logseq.order-list-type:: number
		- Git will return a unique key for the stored data ([[Git objects]])
		  logseq.order-list-type:: number
		- We can use to retrieve the data from Git later
		  logseq.order-list-type:: number
	- Git stores content similar to UNIX filesystems:
		- *Everything* is stored as tree and blob objects
		- *Trees* correspond to UNIX filesystem *directory entries*
		- *Blobs* correspond to *inodes, or file content*
- # Git internals
	- Git can be thought of as content-addressable [[filesystem]]
		- This means that at the core Git is key-value store
		- We can insert any data into Git, and it will return to us a **unique key** we can later use to retrieve the data
	- This is because Linus applied his experience working with Linux filesystems to Git
	- Let's see analogy between the two:
		- Files are organized into [[Git objects]] , analogous to blocks in a filesystem
			- Git objects are stored under `.git/objects`
			- > We can inspect these objects with `git show` or `git show <object>`
			- The most straightforward Git object type is a *blob object*, which only stores data/content
			- Blobs are organized into [trees]([[Tree]])
				- We can do `git ls-tree` to list all trees
				- Git trees are hash trees (Merkle trees), so they're blockchain of sort
			- Blobs are raw data (i.e. file content)
			- Trees are accessed via *commits*
			- These Git objects reside in `.git` directory
	- Data in Git repos can be thought of as [existing in 1 of these 3 states]([[Finite state automata]]):
		- Git *working* directory
			- > Think of it like working memory
			- Working data stays on the filesystems, on disks
			- We can move, (i.e. **add**) working data to the next stage via `git add <FILENAME>`
		- [[Git staging area]]
			- This is when the changes have been made into Git objects as blobs
			- We can commit the blobs into a new tree with `git commit`
		- Git repository
			- Data is committed to the [[Git tree]]
	- ## Example walkthrough
		- Init a new Git repo
		  ```sh
		  mkdir learn-git
		  cd lean-git
		  git init .
		  ```
		- Then we can list `.git` directory, which is where Git keeps its data:
		  > For now, we're not interested in `hooks`, so its content is not shown
		  
		  ```sh
		  $ tree .git
		  .git
		  ├── HEAD
		  ├── config
		  ├── description
		  ├── hooks
		  ├── info
		  │   └── exclude
		  ├── objects
		  │   ├── info
		  │   └── pack
		  └── refs
		      ├── heads
		      └── tags
		  ```
		- When we create a new, empty file, we can see that `.git` is unchanged:
		  ```sh
		  $ touch emptyfile;
		  $ tree .git
		  .git
		  ├── HEAD
		  ├── config
		  ├── description
		  ├── hooks
		  ├── info
		  │   └── exclude
		  ├── objects
		  │   ├── info
		  │   └── pack
		  └── refs
		      ├── heads
		      └── tags
		  ```
			- But if we do `git status`, we'll see that Git reports the new file as untracked
			  ```sh
			  $ git status
			  On branch master
			  No commits yet
			  
			  Untracked files:
			    (use "git add <file>..." to include in what will be committed)
			  	emptyfile
			  
			  nothing added to commit but untracked files present (use "git add" to track)
			  ```
		- Now, when we do `git add emptyfile`, the following happens:
		  ```sh
		  $ git add emptyfile
		  $ tree .git
		  ├── HEAD
		  ├── config
		  ├── description
		  ├── hooks
		  ├── index
		  ├── info
		  │   └── exclude
		  ├── objects
		  │   ├── e6
		  │   │   └── 9de29bb2d1d6434b8b29ae775ad8c2e48c5391
		  │   ├── info
		  │   └── pack
		  └── refs
		      ├── heads
		      └── tags
		  ```
			- Git copies the content of `emptyfile` to `.git` as a *blob* object
			  logseq.order-list-type:: number
			- Git runs a SHA1 hash on the blob + its metadata, and use the hash as identifier for the blob (i.e. blob does not have name)
			  logseq.order-list-type:: number
				- SHA1 outputs are 40-character-long hex strings
				  logseq.order-list-type:: number
				- In this case, our hash is `e69de29bb2d1d6434b8b29ae775ad8c2e48c5391`
				  logseq.order-list-type:: number
				- We can use `git show` on the object, which will be empty string since our blob was copied from an empty file:
				  logseq.order-list-type:: number
				  ```sh
				  $ git show e69
				  $
				  ```
		- We can now do a `git commit`, which produces 2 new objects `8edc` and `f007`:
		  ```sh
		  $ git commit -m 'initial commit'
		  [master (root-commit) 8edc0a2] initial commit
		   1 file changed, 0 insertions(+), 0 deletions(-)
		   create mode 100644 emptyfile
		   
		  $ tree .git
		  .git
		  ├── COMMIT_EDITMSG
		  ├── HEAD
		  ├── config
		  ├── description
		  ├── hooks
		  ├── info
		  │   └── exclude
		  ├── logs
		  │   ├── HEAD
		  │   └── refs
		  │       └── heads
		  │           └── master
		  ├── objects
		  │   ├── 8e
		  │   │   └── dc0a202bb3ae0849b499ff72a02d0bc47a60b8
		  │   ├── e6
		  │   │   └── 9de29bb2d1d6434b8b29ae775ad8c2e48c5391
		  │   ├── f0
		  │   │   └── 07c5ec15ea0a67c0f0fb1947d0fd61af0be47f
		  │   ├── info
		  │   └── pack
		  └── refs
		      ├── heads
		      │   └── master
		      └── tags
		  ```
			- From the stdout output of `git commit`, we saw that it produced a new commit `8edc`
			  logseq.order-list-type:: number
			- If we inspect `8edc`, we'll see that it is indeed a commit:
			  logseq.order-list-type:: number
			  ```sh
			  $ git show 8edc
			  commit 8edc0a202bb3ae0849b499ff72a02d0bc47a60b8 (HEAD -> master)
			  Author: Prem Phansuriyanon <prem.p@lmwn.com>
			  Date:   Tue Jul 30 22:46:21 2024 +0700
			  
			      initial commit
			  
			  diff --git a/emptyfile b/emptyfile
			  new file mode 100644
			  index 0000000..e69de29
			  ```
			- What about `f007`? (Remember that It was created when we committed the change):
			  logseq.order-list-type:: number
			  ```sh
			  $ git show f007
			  tree f007
			  
			  emptyfile
			  ```
			  So `f007` is a Git *tree* object. We can use `git ls-tree` to inspect the tree(s):
			  ```sh
			  $ git ls-tree f007
			  100644 blob e69de29bb2d1d6434b8b29ae775ad8c2e48c5391	emptyfile
			  
			  $ git ls-tree 8edc # We can also use our commit
			  100644 blob e69de29bb2d1d6434b8b29ae775ad8c2e48c5391	emptyfile
			  
			  $ git ls-tree master # Or use the latest commit
			  100644 blob e69de29bb2d1d6434b8b29ae775ad8c2e48c5391	emptyfile
			  
			  $ git ls-tree HEAD # Or our head
			  100644 blob e69de29bb2d1d6434b8b29ae775ad8c2e48c5391	emptyfile
			  ```
			  The output tells us that the free only has 1 file, represented by 1 blob `e69de`
		- If we do `git show`, we can inspect our latest commit:
		  ```sh
		  $ git show --pretty=raw
		  commit 8edc0a202bb3ae0849b499ff72a02d0bc47a60b8
		  tree f007c5ec15ea0a67c0f0fb1947d0fd61af0be47f
		  author Prem Phansuriyanon <prem.p@lmwn.com> 1722354381 +0700
		  committer Prem Phansuriyanon <prem.p@lmwn.com> 1722354381 +0700
		  
		      initial commit
		  
		  diff --git a/emptyfile b/emptyfile
		  new file mode 100644
		  index 0000000..e69de29
		  ```
			- The commit is like a snapshot at one point in time:
				- This *committer* created this *commit* with changes authored by this *author*, with this *message*, and that the snapshot is represented by this *tree*
			- Git commits represent the content change (blob diff), metadata (who and when it was committed),  and that the current state
		- Now, we from `git show <blob>` and `git show <tree>` see that **filenames are stored in the tree**, not the blobs (raw data).
			- This explains why file renames are so cheap in Git
			- This also saves on space (i.e. 2 different versions of file shares the same underlying blobs), like CoW in filesystems
			- When we rename a file and commit the change, what happens is
				- A new tree will be created, pointing to the same blob object
				  logseq.order-list-type:: number
				- But the name referenced in the new tree is the new filename
				  logseq.order-list-type:: number
				- We can check that no new blob object will be created, unlike when we first added `emptyfile`:
				  ```sh
				  $ mv emptyfile newfile
				  $ git add newfile # Added new file, but emptyfile is still in tree
				  
				  $ tree .git # No new blob
				  .git
				  ├── COMMIT_EDITMSG
				  ├── HEAD
				  ├── logs
				  │   ├── HEAD
				  │   └── refs
				  │       └── heads
				  │           └── master
				  ├── objects
				  │   ├── 8e
				  │   │   └── dc0a202bb3ae0849b499ff72a02d0bc47a60b8
				  │   ├── e6
				  │   │   └── 9de29bb2d1d6434b8b29ae775ad8c2e48c5391
				  │   ├── f0
				  │   │   └── 07c5ec15ea0a67c0f0fb1947d0fd61af0be47f
				  │   ├── info
				  │   └── pack
				  └── refs
				      ├── heads
				      │   └── master
				      └── tags
				      
				  $ git add -A # Add moved emptyfile too
				  $ tree .git # No new blob
				  .git
				  ├── COMMIT_EDITMSG
				  ├── HEAD
				  ├── logs
				  │   ├── HEAD
				  │   └── refs
				  │       └── heads
				  │           └── master
				  ├── objects
				  │   ├── 8e
				  │   │   └── dc0a202bb3ae0849b499ff72a02d0bc47a60b8
				  │   ├── e6
				  │   │   └── 9de29bb2d1d6434b8b29ae775ad8c2e48c5391
				  │   ├── f0
				  │   │   └── 07c5ec15ea0a67c0f0fb1947d0fd61af0be47f
				  │   ├── info
				  │   └── pack
				  ```
				- And when we commit, a new tree will be created:
				  > Because Git trees are Merkle trees, the new commit `7c9a` also knows about the previous commit (tip of `master`)
				  
				  ```sh
				  $ git commit -m 'rename';
				  [master 7c9a56c] rename
				   1 file changed, 0 insertions(+), 0 deletions(-)
				   rename emptyfile => newfile (100%)
				   
				  $ tree .git
				  .git
				  ├── logs
				  │   ├── HEAD
				  │   └── refs
				  │       └── heads
				  │           └── master
				  ├── objects
				  │   ├── 70
				  │   │   └── 2243c81d7d9184eefedd1e0a063ee9f8438f09
				  │   ├── 7c
				  │   │   └── 9a56ce71c4f96347967942f6d0aed067818054
				  │   ├── 8e
				  │   │   └── dc0a202bb3ae0849b499ff72a02d0bc47a60b8
				  │   ├── e6
				  │   │   └── 9de29bb2d1d6434b8b29ae775ad8c2e48c5391
				  │   ├── f0
				  │   │   └── 07c5ec15ea0a67c0f0fb1947d0fd61af0be47f
				  ```
				- When we added the 2nd commit `rename`, Git created 2 new objects: commit `7c9a` and tree `7022`:
				  ```sh
				  $ git show 7c9a
				  commit 7c9a56ce71c4f96347967942f6d0aed067818054 (HEAD -> master)
				  Author: Prem Phansuriyanon <prem.p@lmwn.com>
				  Date:   Tue Jul 30 23:49:35 2024 +0700
				  
				      rename
				  
				  diff --git a/emptyfile b/newfile
				  similarity index 100%
				  rename from emptyfile
				  rename to newfile
				  
				  $ git show 7022
				  tree 7022
				  
				  newfile
				  ```
- # Git branches
	- Git branches are simple pointers (references), stored as text files under `.git/refs`
	- A Git branch points to a commit
	- For example, the `master` branch is just a pointer to some commit, accessible at `./refs/heads/master`:
	  ```sh
	  $ cat ./git/refs/heads/master
	  ba5aa1291afce4029795d64c519a53a5c03de6e7
	  
	  $ touch completely_newfile
	  $ git add completely_newfile
	  $ git commit -m 'add completely_newfile'
	  [master 31d5aed] add completely_newfile
	   1 file changed, 0 insertions(+), 0 deletions(-)
	   create mode 100644 completely_newfile
	  
	  $ cat ./git/refs/heads/master
	  31d5aed86506cb3c915161a05e4e4e447934df3b
	  ```
	  So commit `ba5aa1291afce4029795d64c519a53a5c03de6e7` is currently the *tip* of branch `master`
	- *"Being in a branch"* just means that the next change is going to update the committed the branch pointer is pointing to.
		- People think of branches as some kind of divergent mechanisms, a forking point kind of thing. But there's no divergence: everything is still there together in `.git/objects`
- # Under the hood of everyday commands
	- > Git might have some OS-specific optimizations (i.e. hard links?) to boost performance of these operations
	- `git add <FILENAME>`
		- Copies the content of target files as blob objects
	- `git commit -m <MESSAGE>`
		- Creates a new tree object and a new commit object
	- `git checkout <BRANCH|COMMIT_HASH>` and `git switch <BRANCH|COMMIT_HASH>`
		- Git will go to the commit hash, get the tree for the commit, and syncs the local filesystem with the Git file tree (or subtree)
		- So it deletes everything not committed forever
	- `git rm <FILENAME>`
		- Git will remove the file from disk (working area)
		- Git will then *add* the remove operation to staging area
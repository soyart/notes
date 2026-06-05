- #Git
- Git index is a single binary file at `.git/index`
- Empty Git repository does not contain `.git/index`
- Git index represents [[Git staging area]]
- Git index is an intermediate binary file that prepares and organizes changes before they are committed to the repository
	- When we do `git add foo.txt`, the content of `foo.txt` is converted into [[Git objects]] and stored in the object database `.git/objects`
- `git update-index` works directly with index. It's like a lower-level version of `git add`
- We can use `git update-index` to manually update the index:
  id:: 6a23144a-c2a4-4822-8184-fec10e82627d
	- For example, say we're in this repository:
		- ((6a23086c-062d-4c08-a719-124998bf5e81))
	- We can create our first single entry index with:
	  ```sh
	  git update-index --add --cacheinfo 100644 \
	  83baae61804e65cc73a7201a7252750c76066a30 test.txt
	  ```
	  What we do here is *adding* the 1st version of `test.txt` file (`83baa`) to the staging area, as normal file (`100644`)
		- We can also add local files directly to `update-index`, and it'll use the filesystem metadata for file modes and names:
		  ```sh
		  git update-index --add foobar.txt
		  ```
	- ((6a2315f7-0c5b-42be-a798-c70e1db9a012))
	-
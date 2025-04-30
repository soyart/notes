tags:: Data structure, Tree
alias:: BST

- Binary search trees are sorted [[Binary tree]]
- Each node in BST has a value called *key*, and BSTs are sorted by these keys
	- The left child's key is always less than its root's key
	- The right child's key is always greater than its root's key
- It's like binary search on sorted arrays, but this time the structure is self-sorting
- ## Operations
	- ### Search
		- Set current node `curr` to root
		- If `curr` is a null leaf, return false
		- If target is equal to target, return true
		- If target is less than`curr`, assign `curr.left` as new `curr`
		- If target is greater than `curr`, asssign `curr.right` as new `curr`
	- ### Insert
		- Set current node `curr` to root
		- Traverse like search, but if `curr` is null, create a new leaf and assign new value to the null node
	- ### Deletion
		- Deletion is tricky because the BST invariant must hold after each node deletion
		- It's best to think of BST deletion as
		- To start, we generally traverse the tree until we get to the target node
		- Once at the target node, find a successor node
			- If target node is a leaf, then we can just simply
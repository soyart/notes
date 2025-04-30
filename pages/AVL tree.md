tags:: Data structure, Tree

- AVL tree is a balanced [[Binary search tree]] ([[Balanced binary search tree]])
- AVL tree balances itself after insertion/deletion
- AVL tree balances itself by determining *Balance Factor* BF, and using that information to perform rotation if needed.
- ## AVL tree Balance Factor
	- AVL tree balance factor is computed by `HLeft - HRight`
	- `HLeft` is the height of the left subtree, `HRight` is the height of the right subtree
	- A positive BF means that the tree is left-heavy, and negative BF means that the tree is right-heavy
- ## AVL tree rotations
	- Right rotation (RR) can be performed to fix left-heavy tree
	- Light rotation (LL) can be performed to fix right-heavy tree
	- Left-Right rotation (LR) can be performed to fix left-heavy tree with zigzagness
		- First, we perform LL rotation on the left subtree, then RR on the root
	- Right-Left rotation (RL) can be performed to fix right-heavy tree with zigzagness
		- First, we perform RR rotation on the right subtree, then LL on the root
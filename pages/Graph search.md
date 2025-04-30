tags:: Data structure, Graph

- # Connectivity and hops
	- ## DFS
		- Go depth-first, maintaining a stack for backtracking
	- ## BFS
		- Go breadth-first (neighbor), maintaining a queue for tracking neighbors before children
- # Shortest paths
	- ## Dijkstra
		- Find cheapest paths based on *edge weight*
		- Has no awareness about direction
		- **Negative weight** is not allowed
		- Maintain a priority queue to track shortest paths, ordered by edge weight
		- Get the shortest path by following *via*-references after traversal
	- ## A*
		- Find cheapest paths
		- Like Dijkstra, but take into account other metrics of heuristics
			- e.g. for maps, if Dijkstra only tracks *edge weight*, then A* can also use other metric, i.e. real distance between $node_i \rightarrow node_j$
			- This means that we can bake other metrics, i.e. direction when finding road paths, into Dijkstra-like style traversal
		- The score in the priority queue is some combination of both edge weight and custom weight, and we also have to track both separately
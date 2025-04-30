tags:: Data systems
alias:: Databases

- Databases are software tools to help us store and query data efficiently
- # Database types
	- #SQL
		- Assumes some data will be related
		- Normalization - reduce duplicate data at the expense of joins
		- Denormalization - reduce joins at the expense of duplicate data
	- #NoSQL (usually *graph* or *document* databases)
		- Graphs
			- Assume all data will be related, and new relations may emerge any time
		- Documents
			- Assume relation will be rare
- # Database storage engine
	- ((64b848e9-88a9-4ebf-b907-99fcbb74dc84))
- # Scaling databases
	- ## Replication
		- Replicas are full copies of the original database(s).
		- Replica strategies (3)
			- ### Single Leader replication
			- ### Multi-Leader replication
			- ### Leaderless replication
	- ## Paritioning
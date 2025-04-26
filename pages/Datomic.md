tags::  Data systems, datomic, datom, datomic, Datalog, datascript
title:: Datomic

- Datomic is a **closed-source** [database]([[Databases]]) for the JVM developed by Nu bank
	- Datomic is a distributed implementation of [[Datalog]]
	- Datomic is a *database of facts*, called [[Datom]]s
	- Datomic transactions add datoms, never updating or removing them
	- This means that we have an immutable past
	- Datomic’s indexes automatically support many access patterns common in SQL, column, K/V, hierarchical, and graph databases.
- [[Logseq]], itself a [[Clojure]] application, internally uses [[DataScript]], an in-browser or JVM database reverse-engineered from Datomic for its databases and queries
	- See also: [Logseq query]([[Query]])
	- [Unlike Datomic](https://github.com/tonsky/datascript?tab=readme-ov-file#differences-from-datomic)
		- DataScript is **open-source**
		- Aimed to run on browsers
		- Does not keep track of all history by default
		- Simplified schema, not queryable
		- No schema migrations
		- No full-text search, no partitions
		- No external dependencies
- Datomic applications use [[Datomic query]] to query information from the database
- # Inspiration
	- Datomic was inspired by [Out of the Tar Pit (2006)](https://curtclifton.net/papers/MoseleyMarks06a.pdf)
		- A paper about complexity in modern software
		- The paper suggests that we build a new, stateless data system
		- Datomic is an attempt to implement that new database
			- It redefines databases as values, instead of places to get values
			- Datomic thinks of database as expanding set of facts
		- The paper identifies the root causes of many complexity in databases
			- ### States
				- Databases are inherently stateful
			- ### Same query, different result
				- This is because decision making involves >1 components of the database
				- And these components may behave weirdly on race condition
			- ### The database is *over there*
				- Databases are shared by multiple consumers
			- ### Poor definition of *updates*
				- The new replaces the old?
					- Or write a new value to an immutable log?
				- Visibility?
					- Do other programs see these updates being updated?
					- Can they choose if they want to lock on reads?
- # Components
	- > Datomic delegates storage to external services
	  >
	  > This means we can integrate Datomic with any storage, from simple file systems, to other databases
	- ![Screenshot 2025-04-19 at 22.18.35.png](../assets/Screenshot_2025-04-19_at_22.18.35_1745075921452_0.png)
	- ## Transactor
		- Transactor is the writer part of Datomic
		- Runs separately from the application (that has peers), with some connection
	- ## Peers
		- Peers are "readers", and maintain live indexes
		- Can be scaled horizontally
		- When reading from storage, peers require no coordination with the Datomic transactor
- # EDN, Datomic, and Datalog
	- [Logseq queries](https://docs.logseq.com/#/page/advanced%20queries) use [Datomic](https://www.datomic.com/), a dialect of [Datalog](https://www.learndatalogtoday.org/)
	- [Datalog](https://en.wikipedia.org/wiki/Datalog) is a *declarative* logical programming language
		- A Datalog program consists of:
			- Facts - which are statements held to be *true*
				- Below are 2 facts:
				  ```datalog
				  parent(xerces, brooke).
				  parent(brooke, damocles).
				  ```
				- 1st fact: Xerxes is a parent of Brooke,
				- 2nd fact: Brooke is a parent of Damocles
			- Rules - how to deduce (not derive!) new facts from known facts
				- ```datalog
				  ancestor(X, Y) :- parent(X, Y).
				  ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).
				  ```
	- In Datomic, **Datalog query is written in [[EDN]]**
		- Logseq config is also in EDN: config.edn
	- Datomic is a [database]([[Databases]]) implementation with simplicity scalability in mind
	- Datomic presents data as if it's in-memory, as a graph of attributes
	- Read more on InfoQ: https://www.infoq.com/articles/Architecture-Datomic/
	  ![datomic.webp](../assets/datomic_1744992865210_0.webp)
- # Datomic datom
  id:: 68027a1b-5568-497f-a056-29716b8417b9
	- In Datomic, data model is based around *atomic facts* called datoms
	- Datoms are 4-element tuples:
		- Entity ID
		- Attribute ([[EDN]] keyword)
		- Value
		- Transaction ID
	- A *database* in Datomic is thus just a set of datoms:
	  id:: 68027d18-15ee-4f14-82c5-a817d316c0fd
	  ```edn
	  [ 167    :person/name     "James Cameron"    102  ]
	  [ 234    :movie/title     "Die Hard"         102  ]
	  [ 234    :movie/year      1987               102  ]
	  [ 235    :movie/title     "Terminator"       102  ]
	  [ 235    :movie/director  167                102  ]
	  ```
		- *Combining facts*
			- We can see that entity ID `234` is shared by datoms on line 2 and 3, implying that they both are facts for the same entity `234`.
			- This means that the entity `234` has attribute `:movie/title` with value `"Die Hard"`, and attribute `:movie/year` with value `1987`
		- *Foreign keys*
			- On line 5, we can see that the `:movie/director` attribute of e-id `235` is 167
			- And that `167` is just e-id for some entity with attribute `:person/name` equal to `"James Cameron"`
			- In [[SQL]] way of thinking, this is like linking a field in table `movies` with a foreign key set to some primary key in table `persons`
		- We see that transaction ID `102` is shared by all datoms here, implying they were written as part of the same database transaction
	- Even Datomic indexes are datoms - they are sorted set of datoms
	- Datomic indexes that sort by entity, attribute, value, and transaction is called EVAT
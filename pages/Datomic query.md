tags:: Datomic, DataScript, EDN

- A Datomic query is an [[EDN]] vector
- Before we go into the queries, let's first see how data on Datomic is stored as set of atoms:
	- {{embed ((68027d18-15ee-4f14-82c5-a817d316c0fd))}}
- # Basic form and syntax
  id:: 680d1990-fb1c-48d7-8478-16659801f65c
	- ```edn
	  [:find <pattern-variable> :where <data-patterns>]
	  ```
	- The query vector always starts with keyword `:find`
	- After `:find` comes one or more *pattern variables*, which are EDN symbols starting with `?`
	- After that comes the `:where` clause with its *data patterns* to match against
	- Special characters in Datomic query:
	  ```
	  '' literal
	  "" string
	  [] = list or vector
	  {} = map {k1 v1 ...}
	  () grouping
	  | choice
	  ? zero or one
	  + one or more
	  ```
- # Data patterns
  id:: 680d3988-5fb8-4220-89a0-71c5404dc068
	- The *data patterns* are just datoms, with some elements replaced with *pattern variables*
	- **Data patterns** are actually 5-member tuples
	  id:: 680d3988-dedc-4680-8e54-1c430e8fe20f
	  ```edn
	  [<database> <entity-id> <attribute> <value> <transaction-id>]
	  ```
	- But the first element `<database>` is usually omitted, so the basic form of data patterns is a 4-member tuple:
	  ```edn
	  [<entity-id> <attribute> <value> <transaction-id>]
	  ```
	- Wildcard `_` can be used to ignore matching (i.e. matches against all)
		- Note that omitting later parts of the data patterns also match against all, e.g.
		  ```edn
		  [?e :person/name "Mr T" _]
		  ```
		  Is the same with
		  ```edn
		  [?e :person/name "Mr T"]
		  ```
	- The query below finds all entity IDs (`?e`) whose attribute `:person/name` matches `"Ridley Scott"`
	  ```edn
	  [
	   	:find ?e
	  	:where
	  		[?e :person/name "Ridley Scott"]
	  ]
	  ```
	- This one gets title for movie with e-id `234`
	  ```edn
	  [
	   	:find ?t
	  	:where
	  		[234 :movie/title ?t]
	  ]
	  ```
	- This one gets *all* e-ids for 1987 movies
	  ```edn
	  [
	   	:find ?e
	  	:where
	  		[?e :movie/year 1987]
	  ]
	  ```
	- This one gets all `:movie/title` attribute values available in the database:
	  ```edn
	  [
	   	:find ?t
	  	:where
	  		[_ :movie/title ?t]
	  ]
	  ```
	- ## Multiple data patterns
		- Multiple data patterns may follow the `:where` keyword
		- **Example 1**: Find titles of movies made in 1987
		  ```edn
		  [
		  	:find ?t
		   	:where
		  		[?e :movie/year 1987]
		  		[?e :movie/title ?t]
		  ]
		  ```
			- The pattern variable `?e` is referenced in both data patterns, serving as the connection between the 2 data patterns
			- This means that `?e` is bound to the same variable, so all `?t` returns must comes from entity IDs whose attribute satisfies the 2 data patterns
				- We call this [unification](https://docs.datomic.com/query/query-executing.html#unification)
		- **Example 2**: Find out everyone who's starred in `"Lethal Weapon"`
		  ```edn
		  [
		  	:find ?n
		   	:where
		  		[?m :movie/title "Lethal Weapon"]
		  		[?m :movie/cast ?p]
		          [?p :person/name ?n]
		  ]
		  ```
			- It first matches all movies with title `Lethal Weapon`, binding the entity to `?m`
			- It then gets all of the values for `:movie/cast` from all entities `?m`, binding the value to `?p`
			- Lastly, it then returns all values from attribute `:person/name` from entity `?p`
			- The order of data patterns do not matter to the result (the result is the same), but also do matter for performance considerations
			- You can also rewrite Example 2 like this and incur performance penalty just for fun:
			  ```edn
			  [
			  	:find ?n
			   	:where
			          [?p :person/name ?n]
			  		[?m :movie/title "Lethal Weapon"]
			  		[?m :movie/cast ?p]
			  ]
			  ```
				- In this query, it first gets all values from all entities that has `:person/name` attribute, binding the entities (i.e. persons) to `?p` and the values to `?n`
					- This is akin to query all of the persons and their names
					- If many entities have this attribute, then this will be very costly
				- It then gets the entity-ids for all entities with `:movie/title` value to `Lethal Weapon`
				- It lastly joins `?m` and `?p`, returning `?n`
- # Query for attributes
	- **Datom attributes are also entities** stored in the Datomic database
	- This means that we can find out all attributes associated with an entity
	- Let's start with this query, which returns all e-ids to all attributes, for all entities with attribute `:person/name`, aka a person
	  ```edn
	  [:find ?attr
	   :where 
	   [?p :person/name]
	   [?p ?attr]
	  ]
	  ```
	  |`?attr`|
	  | ---| 
	  | `70` |
	  | `69` |
	  | `68` |
	- To get the attribute keywords, we'll lookup *special attribute* `:db/ident`, which stores the keyword (database identity) for the attribute:
	  ```edn
	  [:find ?a ?attr
	   :where
	   [?p :person/name]
	   [?p ?a]
	   [?a :db/ident ?attr]
	  ]
	  ```
	  | `?a` |  `?attr` |
	  | --- | --- |
	  | `70` | `:person/death` |
	  | `69` | `:person/born` |
	  | `68` | `:person/name` |
- # Query for transactions
	- Transaction IDs are the 4th element (or 5th if you count the usually omitted database element)
	- Each transaction is also stored as a datom within the database
	- This means that we can do:
	  ```edn
	  [:find ?timestamp
	   :where
	   [?p :person/name "James Cameron" ?tx]
	   [?tx :db/txInstant ?timestamp]
	  ]
	  ```
	  to get the timestamp of the insertion of James Cameron name into our database
- # Parameterized data patterns
	- Input parameters eliminate hard coded values like `"Lethal Weapon"`
	- The `:in` clause binds input parameters into the data patterns
	- We can have any number of input parameters
	- ### Example 1
		- We have this non-parameterized data patterns, which has hard-coded string `"Sylvester Stallone"` as actor name:
		  ```edn
		  [:find ?title
		   :where
		   [?p :person/name "Sylvester Stallone"]
		   [?m :movie/cast ?p]
		   [?m :movie/title ?title]
		  ]
		  ```
		- But we also want to reuse this query with other actors. This is where the input parameter comes in:
		  ```edn
		  [:find ?title
		   :in $ ?name
		   :where
		   [?p :person/name ?name]
		   [?m :movie/cast ?p]
		   [?m :movie/title ?title]
		  ]
		  ```
			- The query no longer hard-codes string `"Sylvester Stallone"` in the 1st data pattern
			- It looks like this query is taking 1 argument
			- But the query actually takes 2 arguments:
				- [`$`, which is the database itself](((680d3988-dedc-4680-8e54-1c430e8fe20f)))
					- This means that we could rewrite the parameterized query above as:
					  ```edn
					  [:find ?title
					   :in $ ?name
					   :where
					   [$ ?p :person/name ?name]
					   [$ ?m :movie/cast ?p]
					   [$ ?m :movie/title ?title]
					  ]
					  ```
				- `?name`, which will be the input for actor name
					- Here `?name` is bound to scalar (string) values
					- But it's possible to bind it to
						- Scalar (e.g. string and number like in this example)
						- [Tuples](((680d3988-addb-40e0-817a-acff35500f5a)))
						- [Collections](((680d3988-1e3e-4e97-a14f-449bacee38cf)))
						- [Relations](((680d3988-3f3c-420b-846d-7398e57ad2ce)))
			- In pseudo-language, the query engine `q` is performing something like:
			  ```lisp
			  (q query db "Steven Seagal")
			  ```
			  Where `query` is the query above, `db` is the database, and `"Steven Seagal"` as input `?name`
				- ```clojure
				  (require '[datomic.api :as d])
				  ;; get db value
				  (def db (d/db conn))
				  
				  ;; query
				  (d/q '[:find ?release-name
				         :where [_ :release/name ?release-name]]
				        db)
				  ```
				- ```clojure
				  ;; output
				  #{["Osmium"]
				    ["Hela roept de akela"]
				    ["Ali Baba"]
				    ["The Power of the True Love Knot"]
				    ...}
				  ```
	- ### Example 2
		- Get all attributes of a movie with matching title
		- ```edn
		  [:find ?attr
		   :in $ ?title
		   :where
		    [?m :movie/title ?title]
		    [?m ?a]
		    [?a :db/ident ?attr]
		  ]
		  ```
	- ### Tuple input parameter
	  id:: 680d3988-addb-40e0-817a-acff35500f5a
		- We can write input parameter as *a single tuple* `[?director ?actor]`:
		  ```edn
		  [:find ?title
		   :in $ [?director ?actor]
		   :where
		   [?d :person/name ?director]
		   [?a :person/name ?actor]
		   [?m :movie/director ?d]
		   [?m :movie/cast ?a]
		   [?m :movie/title ?title]
		  ]
		  ```
		- This'll help destructure *a single input vector* `["James Cameron" "Arnold Schwarzenegger"]` into the tuple elements
			- String `"James Cameron"` will be destructured into `?director`
			- String `"Arnold Schwarzenegger"` will be destructured into `?actor`
		- Tuple destructuring is an alternative to using separate inputs:
		  ```edn
		  [:find ?title
		   :in $ ?director ?actor
		   :where
		   [?d :person/name ?director]
		   [?a :person/name ?actor]
		   [?m :movie/director ?d]
		   [?m :movie/cast ?a]
		   [?m :movie/title ?title]
		  ]
		  ```
			- In this case, **the query must be called with 2 variables (excl. the database `$`)** - a string for `?director` and another for `?actor`
	- ### Collections input parameter
	  id:: 680d3988-1e3e-4e97-a14f-449bacee38cf
		- *Collections* can be used to implement a **logical `OR`**
		- *Collections* are denoted with literal ellipsis `...`
		- ```edn
		  [:find ?title
		   :in $ [?director ...]
		   :where
		   [?p :person/name ?director]
		   [?m :movie/director ?p]
		   [?m :movie/title ?title]
		  ]
		  ```
		- In the above example, if we call the query with *a tuple containing 2 director names* `["James Cameron" "Ridley Scott"]`, then it'll get all titles for movies directed by either of the 2 directors
		- > Calling this query with scalar input `"James Cameron"` will get empty results
		  > And 2 scalar inputs will also return empty result: `"James Cameron" "Ridley Scott"`
	- ### Relations input parameter
	  id:: 680d3988-3f3c-420b-846d-7398e57ad2ce
		- A *relation* is **a set of tuples**
		- *Relations* are the most powerful form of input binding
		- A relation lets us define some simple relationship
		- For example, a relation input parameter is defined as:
		  ```edn
		  [movie-title box-office-earnings]
		  ```
		- And we have this query:
		  ```edn
		  [:find ?title ?box-office
		   :in $ ?director [[?title ?box-office]]
		   :where
		   [?p :person/name ?director]
		   [?m :movie/director ?p]
		   [?m :movie/title ?title]
		  ]
		  ```
			- > Note: `?box-office` does not appear in the `:where` clause
			- Note how it defines **2 inputs**
				- Input 1: Scalar `?director`
				- Input 2: Relation `[?title ?box-office]`
		- Then, if we supply this tuple set as input 2:
		  ```edn
		  [
		   ["Die Hard" 140700000]
		   ["Alien" 104931801]
		   ["Lethal Weapon" 120207127]
		   ["Commando" 57491000]
		  ]
		  ```
			- This relation provides a relationship between some movie titles and some box office values, which existed outside of the database
			- The movie titles, i.e. the 1st element of the tuple, will be destructured into `?title`, while the 2nd element into `?box-office`
		- This means that, given the relation above and `?director` equal to `"Ridley Scott"`, we'll be able to query box office values of all Ridley Scott movies in the relation
			- If the relation supplied lacks any titles by Ridley Scott, then the query returns empty
- # Predicates
	- With data patterns, we can match against something with equal-to operations
	- But we have not yet compared the values (which one is greater, etc.)
	- This is where predicates come in
		- Predicates help with filtering
		- Predicates that returns *truthy* values are matched
			- A truthy value is non-nil, non-false
		- ```edn
		  [:find ?title
		   :where
		   [?m :movie/title ?title]
		   [?m :movie/year ?year]
		   [(< ?year 1984)]
		  ]
		  ```
		- The last `:where` clause, `[(< ?year 1984)]`, is a *predicate*
		- It returns true if `?year` value is less than 1984
	- Simple comparisons can be as operations right away, like `<`, `<=`, `=`, `>=`, `>`,  and `not=`
		- ```lisp
		  ; Lisp-style examples
		  (< 10 5)] ; false
		  (> 10 5) ; true
		  (not= 10 1) ; true
		  (= 10 (+ 5 5)) ; true
		  ```
	- Any *Java or Clojure methods* can be also be used as *predicates*
		- An example would be [Java method `startsWith` for type `String`](https://docs.oracle.com/javase/8/docs/api/java/lang/String.html#startsWith-java.lang.String-)
		  ```edn
		   (.startsWith ?name "M")
		  ```
	- Any *Clojure functions* can serve as *predicates*, but must contain fully-qualified namespace paths:
	  ```edn
	  (my.namespace/awesome? ?movie)
	  ```
- # Transformation
	- Transformation is purely functional transformation of the query *pattern variables*
	- A transformation function clause is in the form:
	  ```edn
	  [(<fn> <arg1> <arg2> ...) <result-binding>]
	  ```
	  The return value of the call is bound to `<result-binding>`
	- The binding variable, like with input parameters, could be
		- Scalar
		- [Tuple](((680d3988-addb-40e0-817a-acff35500f5a)))
		- [Collection](((680d3988-1e3e-4e97-a14f-449bacee38cf)))
		- [Relationship](((680d3988-3f3c-420b-846d-7398e57ad2ce)))
	- For example, if we have this Clojure function at namespace path `tutorial.fn/age`:
	  ```clojure
	  (defn age [birthday today]
	    (quot (- (.getTime today)
	             (.getTime birthday))
	          (* 1000 60 60 24 365)))
	  ```
	- Then we can use it to transform birth years (stored in our database) into age by using it to bind the function's return value to our pattern variable:
		- **Example 1**: Given a person's name and today as time, compute that person's age
		  ```edn
		  [:find ?age
		   :in $ ?name ?today
		   :where
		   [?p :person/name ?name]
		   [?p :person/born ?born]
		   [(tutorial.fns/age ?born ?today) ?age]
		  ]
		  ```
		- **Example 2**: Given a target age and today as time, get all person's names whose age matches target age:
		  ```edn
		  [:find ?name
		   :in $ ?age ?today
		   :where
		     [?p :person/name ?name]
		     [?p :person/born ?born]
		     [(tutorial.fns/age ?born ?today) ?age]
		  ]
		  ```
	- Transformations **cannot be nested**:
	  ```edn
	  [(f (g ?x)) ?a]
	  ```
	  Instead, we must bind the result to some temporary variable:
	  ```edn
	  [(g ?x) ?t]
	  [(f ?t) ?a]
	  ```
- # Pull expression
	- # Return map
		- Supplying return maps will make query return a map instead of a tuple
		- There're 3 keywords used for return maps
		  | Keyword | Symbols become |
		  | ---- | ---- | ---- |
		  | `:keys` | Keyword keys |
		  | `:strs` | String keys |
		  | `:syms` | Symbol keys |
		- An example would be this:
		  ```edn
		  [:find ?artist-name ?release-name
		  	:keys artist release
		  	:where
		   		[?release :release/name ?release-name]
		   		[?release :release/artists ?artist]
		  		[?artist :artist/name ?artist-name]]
		  ```
		- Which will returns result map:
		  ```edn
		  {
		   {:artist "George Jones" :release "With Love"}
		   {:artist "Shocking Blue" :release "Hello Darkness / Pickin' Tomatoes"} 
		   {:artist "Junipher Greene" :release "Friendship"}
		  }
		  ```
	- Definition
	  ```
	  pull-expr = ['pull' variable pattern]
	  pattern   = (pattern-name | pattern-data-literal)
	  ```
	- A pull expression returns information about a variable as specified by a pattern.
	- Each variable can appear in *at most one pull expression*
	- ## Example 1
		- Let's consider a simple `find` that returns the start and end year of artist:
		  ```edn
		  [
		  	:find ?start-year ?end-year
		   	:where
		   		[?e :artist/name "The Beatles"]
		  		[?e :artist/start-year]
		   		[?e :artist/end-year]
		  ]
		  ```
			- Here, we've used 3 data patterns to retrieve 2 information, albeit from a single entity
		- We can use `pull` to selectively returns desired fields from that entity instead:
		  ```edn
		  [
		  	:find (pull ?e [:artist/startYear :artist/endYear])
		   	:where
		   		[?e :artist/name "The Beatles"]
		  ]
		  ```
			- The pull query above just *finds* 1 entity `?e`, and then use `pull` to pull out 2 fields out of `?e`, returning it
	- This API provides a declarative interface where we specify *what* information we want for an entity without specifying *how* to find it.
	- We can use `pull` to do separation of concerns:
		- Notice `:find (pull ?t pattern)` on line 2
		- ```Clojure
		  (def songs-by-artist
		    '[:find (pull ?t pattern)
		      :in $ pattern ?artist-name
		      :where
		      [?a :artist/name ?artist-name]
		      [?t :track/artists ?a]])
		  
		  (def track-releases-and-artists
		    [:track/name
		     {:medium/_tracks
		      [{:release/_media
		        [{:release/artists [:artist/name]}
		         :release/name]}]}])
		  
		  ;; Query 1
		  ;; Pull only the :track/name
		  (d/q songs-by-artist db [:track/name] "Bob Dylan")
		  
		  
		  ;; Query 2
		  ;; Use a different pull pattern to get the track name, the release name, and the artists on the release.
		  (d/q songs-by-artist db track-releases-and-artists "Bob Dylan")
		  
		  
		  ;; Result of Query 1
		  ([#:track{:name "California"}]
		   [#:track{:name "Grasshoppers in My Pillow"}]
		   [#:track{:name "Baby Please Don't Go"}]
		   [#:track{:name "Man of Constant Sorrow"}]
		   [#:track{:name "Only a Hobo"}]
		  ...)
		  
		  ;; Result of Query 2
		  ([{:track/name "California",
		     :medium/_tracks
		     #:release{:_media #:release{:artists [#:artist{:name "Bob Dylan"}], :name "A Rare Batch of Little White Wonder"}}]
		   [{:track/name "Grasshoppers in My Pillow",
		     :medium/_tracks
		     #:release{:_media #:release{:artists [#:artist{:name "Bob Dylan"}], :name "A Rare Batch of Little White Wonder"}}]
		   [{:track/name "Baby Please Don't Go",
		     :medium/_tracks
		     #:release{:_media #:release{:artists [#:artist{:name "Bob Dylan"}], :name "A Rare Batch of Little White Wonder"}}]
		   [{:track/name "Man of Constant Sorrow",
		     :medium/_tracks
		     #:release{:_media #:release{:artists [#:artist{:name "Bob Dylan"}], :name "A Rare Batch of Little White Wonder"}}]
		   [{:track/name "Only a Hobo",
		     :medium/_tracks
		     #:release{:_media #:release{:artists [#:artist{:name "Bob Dylan"}], :name "A Rare Batch of Little White Wonder"}}]
		   ...)
		  ```
- # Aggregate
	- Aggregate functions transform `:find` result
	- Aggregate function appear as [a list](((680d1990-fb1c-48d7-8478-16659801f65c))) [in `find-spec`](((680d25da-958d-4e6d-9b4e-b17e06ddf7b6)))
	- Aggregates appear as lists in a find-spec
	- Built-in aggregate functions
		- Simple aggregation like `sum`, `max`, `min`, `count` are readily available in the `:find` clause:
		  ```edn
		  [:find (max ?rating)
		   :where
		   [?m :movie/director "James Cameron"]
		   [?m :movie/rating ?rating]
		  ]
		  ```
			- | Aggregate | Return n value | Notes |
			  | ---- | ---- | ---- |
			  | avg | 1 |   |
			  | count | 1 | counts duplicates |
			  | count-distinct | 1 | counts only unique values |
			  | distinct | n | set of distinct values |
			  | max | 1 | compares all types, not just numbers |
			  | max n | n | returns up to n largest |
			  | median | 1 |   |
			  | min | 1 | compares all types, not just numbers |
			  | min n | n | returns up to n smallest |
			  | rand n | n | random up to n with duplicates |
			  | sample n | n | sample up to n, no duplicates |
			  | stddev | 1 |   |
			  | sum | 1 |   |
			  | variance | 1 |   |
	- Aggregate functions can also appear in data patterns, as with `count` on line 4
	  ```edn
	  [:find ?year (median ?namelen) (avg ?namelen) (stddev ?namelen)
	         :with ?track
	         :where [?track :track/name ?name]
	                [(count ?name) ?namelen]
	                [?medium :medium/tracks ?track]
	                [?release :release/media ?medium]
	                [?release :release/year ?year]]
	  
	  [[1968 16 18.92181098534824 12.898760656290333] 
	   [1969 16 18.147895557287608 11.263945894977244] 
	   [1970 15 18.007481296758105 12.076103750401026] 
	   [1971 15 18.203682039283294 13.715552693168124] 
	   [1972 15 17.907170949841063 11.712941060399375] 
	   [1973 16 18.19300100438759 12.656827911058622]]
	  ```
	- ## Single value return value
		- `sum`, `max`, `count`, etc. returns a single value
		- Find newest movie
		  ```edn
		  [:find (max ?year)
		   :where
		   [_ :movie/year ?year]
		  ]
		  ```
		  | `(max ?year)` |
		  | ---- |
		  | `2003` |
		- Count all movie entities in the database
		  ```edn
		  [:find (count ?m)
		   :where
		   [?m :movie/title _]
		  ]
		  ```
		  | `(count ?m)` |
		  | --- |
		  | `20` |
		  Or we could count them by titles:
		  ```edn
		  [:find (count ?t)
		   :where
		   [_ :movie/title ?t]
		  ]
		  ```
		  | `(count ?m)` |
		  | --- |
		  | `20` |
	- ## Multiple values
		- Some aggregates can be formed to return >1 values
		- `(min n ?v)` returns a collection of at most `n` values of `?v`, in this case, the `n` smallest values
		- Find release year of the 4 oldest movies:
		  ```edn
		  [:find (min 4 ?year)
		   :where
		   [_ :movie/year ?year]
		  ]
		  ```
		  | `?year` |
		  | --- |
		  | `[1979 1981 1982 1984]` |
			- Note that we **cannot **do
			  ```edn
			  [:find (min 4 ?year) ?title
			   :where
			   [?m :movie/year ?year]
			   [?m :movie/title ?title]
			  ]
			  ```
			- This will simply finds all movie titles, and `(min 4 ?year)` will return 1-element tuple containing 1 value - the year of the movie title:
			  | `(min 4 ?year)` | `?title` |
			  | ---- | ---- | ---- |
			  | `[1979]` | `"Alien"` |
			  | `[1986]` | `"Aliens"` |
			  | `[1995`] | `"Braveheart"` |
			  | `[1985]` | `"Commando"` |
			  | `[1988]` | `"Die Hard"` |
			  | `[1982]` | `"First Blood"` |
			  | `[1987]` | `"Lethal Weapon"` |
			  | `[1989]` | `"Lethal Weapon 2"` |
- # `:with` clause
  id:: 680d34cf-4098-40d5-b6b7-6d80f4300b3f
	- The with-clause *considers additional variable* not mentioned in the find-spec
		- That variable is then removed
		- This leaves a bag (not a set!) of values to be consumed by the  find-spec
	- Consider this query, which finds all them years in which Bob Dylan released his records:
	  ```edn
	  [:find ?year
	  	:where
	   		[?artist :artist/name "Bob Dylan"]
	  		[?release :release/artists ?artist]
	  		[?release :release/year ?year]
	  ]
	  ```
	  ```edn
	  [[1969] [1970] [1971] [1973] [1968]]
	  ```
	- The 5 years are years in which Bob Dylan released his records, according to this database
	- But we know that there're possibly >5 records releases that year
		- **Identical years are merged due to set logic**
		- This means that if in 1973 Bob released more than 1 records,  we'll still only see a single `1973` in the output, despite the fact
		- This is where `:with` comes in handy
	- So if we need to *find every Bob Dylan's record's release years*, we can use `:with ?release` on line 2 to also consider `?release` the same way we consider `?year`:
	  ```edn
	  [:find ?year
	   	:with ?release
	  	:where
	   		[?artist :artist/name "Bob Dylan"]
	  		[?release :release/artists ?artist]
	  		[?release :release/year ?year]
	  ]
	  ```
	  Thanks to `:with ?release`, the query returns a list of the year of *each release* in the database:
	  ```edn
	  [[1973] [1971] [1973] [1973] [1970] [1968] [1971] [1969] [1968] [1970] [1973] [1970] [1971] [1970] [1973] [1968] [1971] [1973] [1970] [1969] [1971] [1970]]
	  ```
	  Bob Dylan is crazy
- # Rules
	- [Rules](https://docs.datomic.com/query/query-data-reference.html#rules) allow us to package set of `:where` clauses into named rules
	- Rules are like program functions - named reusable chunk of logic
	- We can compose a rule, give it a name, and use it in our queries
	- Rules can contain data patterns, aggregates, and
	- A rule is **a list of lists**, with a very simple form:
	  ```edn
	  [(head-vector) [body1] [body2] ...]
	  ```
		- 1st list is called a *rule head*
			- It's possible to use `[ ]` to enclose the rule head list
			- But it's convention to use `( )` to enclose the head, for visual comfort
			- The head is akin to function signature: it specifies its name and rule arguments
		- The rest is informally called *rule body*
		- Definition:
		  ```
		  rule                       = [ [rule-head clause+]+ ]
		  rule-head                  = [rule-name rule-vars]
		  rule-name                  = plain-symbol
		  rule-vars                  = [variable+ | ([variable+] variable*)]
		  ```
	- To use rules, *write the head* of the rules instead of the data patterns
	- ### Example 1
		- Original query (without rules):
		  ```edn
		  [:find ?name
		   :where
		   [?p :person/name ?name]
		   [?m :movie/cast ?p]
		   [?m :movie/title "The Terminator"]]
		  ```
		- Rule `actor-movie`
		  ```edn
		  [(actor-movie ?name ?title)
		   [?p :person/name ?name]
		   [?m :movie/cast ?p]
		   [?m :movie/title ?title]]
		  ```
			- This rule is named `actor-movie`
			- This rule can be used for both input and output, and thus can be used to:
				- Find movie titles, given an actor name
				- Find actor name, given a movie title
				- Find all combinations of actor-movie mapping, given nothing
		- New query, replacing data patterns with rule
		  ```edn
		  [:find ?name
		   :in $ %
		   (actor-movie ?name "The Terminator")]
		  ```
		- The `%` symbol in `:in` represent the rule
	- We can use >1 rules, collect their result into a vector, before passing it on to the query like usual:
	  ```edn
	  [
	  	[(head-1) [...] [...] [...]]
	  	[(head-2) [...] [...] [...]]
	  ]
	  ```
	  Which might look something like this
	  ```edn
	  [[(rule-a ?a ?b)
	    ...]
	   [(rule-b ?a ?b)
	    ...]
	   ...]
	  ```
		- With this, rules can also be composed to implement **logical `OR`**
			- Rules `associated-with` can be used multiple times:
			  ```edn
			  [[
			    (associated-with ?person ?movie)
			    [?movie :movie/cast ?person]]
			   [(associated-with ?person ?movie)
			    [?movie :movie/director ?person]
			  ]]
			  ```
			  Foo
			  ```edn
			  [:find ?name
			   :in $ %
			   :where
			   [?m :movie/title "Predator"]
			   (associated-with ?p ?m)
			   [?p :person/name ?name]]
			  ```
	- ### Example 2
		- Rule `movie-year`, which matches movie titles with release year
		  ```edn
		  [[(movie-year ?title ?year)
		   	[?m :movie/title ?title]
		    	[?m :movie/year ?year]]]
		  ```
- # Grammar
  id:: 680d25da-958d-4e6d-9b4e-b17e06ddf7b6
	- Definition
	  ```
	  query = [find-spec with-clause? inputs? where-clauses?]
	  ```
	- `find-spec` specifies pattern variables or aggregates to return
	- [Optional] `with-clause` controls how duplicate find values are handled
	- [Optional] `inputs` names the databases, data, and rules available to the query engine
	- [Optional] `where-clauses` additional constrain and transform data
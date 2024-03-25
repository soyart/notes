- MongoDB is a document databases, that stores each *document* as a BSON object
- Documents is stored together in a *collection*
- We can query MongoDB via JS-like query language
- We can see perf stats with `explain` method to see if indexes were used: `db.books.find({rating: 8}).explain(executionStats)`
- # Conntection string
- # #Indexing
	- Without indexes, MongoDB will have to scan the whole collection (colscan) to perform the queries
	- MongoDB defines indexes **at the collection level**, and can index every fields/subfields in the collection
	- MongoDB indexes store *a field* or *a set of fields*, ordered by their values
	- A special, unique field `_id` is already indexed. **We cannot drop `_id` indexes**
	- ## Index types
		- ### Single field
			- Tracks values of a single field of the document
			- Index direction can be specified: `1` for ascending, `-1` for descending
			- #### We can also index embedded document
				- ```json
				  {
				    "_id": ObjectId("570c04a4ad233577f97dc459"),
				    "score": 1034,
				    "location": { state: "NY", city: "New York" }
				  }
				  ```
				- The `location` object is the embedded document
				- The following command creates an index on the `location` field (embedded document) as a whole:
				- ```js
				  db.records.createIndex( { location: 1 } )
				  ```
				- And this allow us to use the created index to support this query:
				- ```js
				  db.records.find( { location: { city: "New York", state: "NY" } } )
				  ```
			- #### We can also index embedded field
				- ```json
				  {
				    "_id": ObjectId("570c04a4ad233577f97dc459"),
				    "score": 1034,
				    "location": { state: "NY", city: "New York" }
				  }
				  ```
				- Then we can index `location.state` with simple dot notation:
				- ```js
				  db.records.createIndex( { "location.state": 1 } )
				  ```
				- This created index can be used to handle this query:
				- ```js
				  db.records.find( { "location.state": "CA" } )
				  ```
		- ### Compound fields
			- Tracks values of >1 fields
			- #### Ordering of the fields when creating the index is significant:
				- Let's say we create index with this key pattern: `{a: 1, b: 1}`
				- The created index sorts its values by `a: 1` first, then `b: 1`
				- If we want the query to sort the return values, this index can only support sort by `{a: 1, b: 1}`, BUT NOT `{b: 1, a: 1}`
				- We can also sort by match the **inverse** of the index key pattern:
					- Let's say the index model is `{ a: 1, b: -1 }`
					- Then we can sort by both `{a: 1, b: -1}` (match) and `{a:  -1, b: 1}` (inverse)
					- But the index cannot support `{ a: 1, b: 1 }` or `{ a: -1, b: -1 }`
			- #### Index prefixes
				- Index prefixes are the beginning subsets of indexed fields. Compound indexes support queries on all fields included in the index prefix.
				- For example, we create this compound index: `{ "item": 1, "location": 1, "stock": 1 }`
				- Then the following `{ item: 1 }`, `{ item: 1, location: 1 }` are supported
				-
		- ### Multikey
			- > When we create an index for a field with array values, multikey index is created automatically
			- Used to track content stored in arrays
			- Every element's value is indexed
	- ## Creating an index
		- ### #Go
			- #### Single/compound field indexes
				- ```go
				  // Simple index
				  // Field title: ascending
				  coll := client.Database("sample_mflix").Collection("movies")
				  indexModel := mongo.IndexModel{
				      Keys: bson.D{{"title", 1}},
				  }
				  
				  // Default index name is the concatenation of the indexed keys and each key's direction
				  // We can create an index with custom name if we pass in the options.
				  name, err := coll.Indexes().CreateOne(context.TODO(), indexModel)
				  if err != nil {
				      panic(err)
				  }
				  
				  fmt.Println("Name of Index Created: " + name)
				  
				  // Compound index:
				  // Field fullplot: descending
				  // Field title: ascending
				  indexModel := mongo.IndexModel{
				      Keys: bson.D{
				          {"fullplot", -1},
				          {"title", 1}
				      }
				  }
				  
				  name, err := coll.Indexes().CreateOne(context.TODO(), indexModel)
				  if err != nil {
				      panic(err)
				  }
				  
				  fmt.Println("Name of Compound Index Created: " + name)
				  ```
			-
- > For testing and learning [[Logseq]] [[DataScript]] queries
- I'm learning querying for a side project based on [Logseq SPA](https://github.com/framedb/wiki)
- Pages tagged with testquery is for practice in this file
  {{query [[testquery]] }}
- # Misc
	- #+BEGIN_QUERY
	  {
	    :title [:b "Find all blocks that mention page steel, by string \"steel\""]
	    :query [
	      :find (pull ?b [*])
	        :where
	        [?b :block/page ?p]
	        [page-property ?p :tags "testquery"]
	        [?target :page/name "steel"]
	        [?b :block/refs ?target]
	    ]
	   }
	  #+END_QUERY%
	- #+BEGIN_QUERY
	  {
	    :title [:b "Find all blocks that mention page steel, by string \"steel\", as well as its aliases"]
	    :query [
	      :find (pull ?b [*])
	        :where
	        [?b :block/page ?p]
	        [page-property ?p :tags "testquery"]
	        [?target :page/name "steel"]
	        [?target :page/alias ?a]
	        (or
	          [?b :block/refs ?target]
	          [?b :block/refs ?a]
	        )
	    ]
	   }
	  #+END_QUERY%
- # Tag `features` (`featuresv1`)
	- ## Example 1
		- #+BEGIN_QUERY
		  {
		    :title [:b "Find all features for all pages tagged with testquery"]
		    :query [
		      :find (pull ?b [*])
		        :where
		        [page-property ?p :tags "testquery"]
		        [?b :block/parent ?parent]
		        [property ?parent :type "features"]
		    ]
		   }
		  #+END_QUERY%
	- ## Example 2
		- #+BEGIN_QUERY
		  {
		    :title [:b "Find feature blocks with material steel"]
		    :query [
		      :find (pull ?b [*])
		        :where
		        [page-property ?p :tags "testquery"]
		        [?b :block/parent ?parent]
		        [property ?parent :type "features"]
		        [property ?b :material "steel"]
		    ]
		   }
		  #+END_QUERY%
	- ## Example 3
		- #+BEGIN_QUERY
		  {
		    :title [:b "Find all shape feature blocks"]
		    :query [
		      :find (pull ?b [*])
		        :where
		        [page-property ?p :tags "testquery"]
		        [?b :block/parent ?parent]
		        [property ?parent :type "features"]
		        [has-property ?b :shape]
		    ]
		   }
		  #+END_QUERY%
- # Tag `featuresv2` and `featurev2`
	- ## Example 1
		- #+BEGIN_QUERY
		  {
		    :title [:b "Find all featuresv2 blocks"]
		    :query [
		      :find (pull ?b [*])
		        :where
		        [?b :block/page ?p]
		        [page-property ?p :tags "testquery"]
		        [property ?b :tags "featurev2"]
		    ]
		   }
		  #+END_QUERY%
	- ## Example 2
		- #+BEGIN_QUERY
		  {
		    :title [:b "Find all featuresv2 blocks with steel as material"]
		    :query [
		      :find (pull ?b [*])
		        :where
		        [?b :block/page ?p]
		        [page-property ?p :tags "testquery"]
		        [property ?b :tags "featurev2"]
		        [property ?b :material "aluminum"]
		    ]
		   }
		  #+END_QUERY%
	- ## Example 3
		- #+BEGIN_QUERY
		  {
		    :title [:b "Find all shape featuresv2 blocks"]
		    :query [
		      :find (pull ?b [*])
		        :where
		        [?b :block/page ?p]
		        [page-property ?p :tags "testquery"]
		        [property ?b :tags "featurev2"]
		        [has-property ?b :shape]
		    ]
		   }
		  #+END_QUERY%
	- ## Example 4
		- #+BEGIN_QUERY
		  {
		    :title [:b "Find all featuresv2 blocks for Test Query 2 by its original name"]
		    :query [
		      :find (pull ?b [*])
		        :where
		        [?b :block/page ?p]
		        [page-property ?p :tags "testquery"]
		        [?p :block/name "test query 2"]
		        [property ?b :tags "featurev2"]
		    ]
		   }
		  #+END_QUERY%
	- ## Example 5
		- #+BEGIN_QUERY
		  {
		    :title [:b "Find all featuresv2 blocks for Test Query 2 by its alias"]
		    :query [
		      :find (pull ?b [*])
		        :where
		        [?b :block/page ?p]
		        [page-property ?p :tags "testquery"]
		        [page-property ?p :page/alias "TQ 2"]
		        [property ?b :tags "featurev2"]
		    ]
		   }
		  #+END_QUERY%
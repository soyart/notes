alias:: EDN

- EDN is a data format, like JSON, but extensible
- EDN base types are more versatile than JSON's
	- Numbers: `42`, `3.14159`
	- Strings: `"This is a string"`
	- Keywords: `:kw`, `:namespaced/keyword`, `:foo.bar/baz`
	- Symbols: `max`, `+`, `?title`
	- Vectors: `[1 2 3]` `[:find ?foo ...]`
	- Lists: `(3.14 :foo [:bar :baz])`, `(+ 1 2 3 4)`
	- Instants: `#inst "2013-02-26"`
- EDN can be extended with user-defined types
- EDN looks very [[Lisp]]-ey
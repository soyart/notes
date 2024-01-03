- ## Alphabet $\Sigma$
  collapsed:: true
	- A set of symbols
	- e.g. $\Sigma_\text{A} = \{a, b, c, \dots, z\}$ is *alphabet* over lowercase Latin characters
	- e.g. $\Sigma_\text{B} = \{0, 1\}$ is *binary alphabets* named B, whose elements can only be symbols `0` or `1`
- ## Symbol
  collapsed:: true
	- e.g. the individual `a`, `b`, `c`, `0`, `1`
- ## Powers of Sigma Σ
  collapsed:: true
	- $\Sigma^n$ is the set of strings of length `n`
	- e.g. the language has this alphabets: $\Sigma = {0, 1}$
		- $\Sigma^0$ -> All strings of length 0 -> $Σ^0 = \Epsilon = \{ε\}$
		- $\Sigma^1$ -> All strings of length 1 -> $\Sigma^1 = \{0, 1\}$
		- $\Sigma^2$ -> All strings of length 2 -> $\Sigma^2 = \{00, 01, 10, 11\}$
	- #### Cardinality = Σ^n
		- Number of elements in a set
		- e.g. if the language has this alphabet set $\Sigma = {0, 1}$
		  collapsed:: true
			- Then cardinality is 2^n (Σ has 2 elements)
	- #### $\Sigma^\ast$ and $\Sigma^+$  (assume alphabets $\Sigma = {0, 1}$)
		- Sets of all possible strings over `{0, 1}`
		- $\Sigma^\ast = \Sigma^0 \cup \Sigma^1 \cup \Sigma^2 \cup \Sigma^3 \cup \dots \cup \Sigma^n$
		- $\Sigma^\ast = \Epsilon ∪ \{0, 1\} ∪ \{00, 01, 10, 11\} ∪ \{000, 001, 010, 011, 100, ...\}$
		- $\Sigma^+$ is like $\Sigma^\ast$, but without $\Epsilon$
- ## String
  collapsed:: true
	- Sequence over a set of symbols
	- An empty string is an Epsilon ε
	- e.g. we have symbols `0` and `1`, then `0011010` is a string
	- e.g. If alphabet $\Sigma = \{0, 1\}$, then `011101` is a string of legal alphabets `0` and `1`
- ## Language
  id:: eb18ac5c-b11f-4447-833f-aa748e9c88f6
	- A set of strings
	- e.g. the English language
		- English language alphabets $\Sigma_\text{English} = \{a, b, c, \dots, z\}$
		- Then any sets of strings containing only symbols from Σ is a valid English language string
	- e.g. Language *Simbin* (simple binary language)
		- Simbin alphabets $\Sigma_\text{simbin} = \{0, 1\}$
		- Then strings `0`, `1`, and `101011` are valid Simbin strings
		- Strings `02`, `a10` are not valid strings over
	- e.g. Language *Simbin2* accepts any strings over $\Sigma_\text{simbin}$ **of length 2**
		- Then strings `00`, `01`, `10`, `11` are valid Simbin2 strings
		- But `0`, `100`, `12` are not valid Simbin2 strings
	- e.g. Language *Simbin3* language accepts any strings over $\Sigma_\text{simbin}$ that starts with symbol `0`
		- Then `0110`, `011111`, `0` are valid Simbin3 strings
	- From examples Simbin1, Simbin2, and Simbin3, only Simbin2  have finite sets of valid strings.
	- ### Regular languages
		- Can be recognized by a finite state machine [[FSM]] (e.g. a [[DFA]] or [[NFA]])
		- Can be described by [[Regular Expression]]
		- Will pass regular pumping lemma
	- ### Context-free languages [[CFL]]
		- Can be described by a context-free grammar [[CFG]]
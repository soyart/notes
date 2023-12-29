- Is how we think of computation
  collapsed:: true
	- Computability theory (1930-1950s)
		- What we can compute
		- e.g. Can we solve problem `x`?
		- e.g. The halting problem
	- Complexity theory (from 1960s)
		- Can we compute `x` efficiently?
- Computers can be categorized (least complex first) based on its computational models, from [[FSM]], [[CFL]], [[Turing machine]], [[Undecidable]]
- Has roots in linguistics, so the study usually uses linguistics terms
- Languages and finite state automatons (FSM) are actually 2 representations of the same abstract concept
- ## Prerequisites
	- ### Symbol
		- e.g. the individual `a`, `b`, `c`, `0`, `1`
	- ### Alphabet (Σ)
		- A set of symbols
		- e.g. `{a, b, .., z}` is *Latin alphabets*
		- e.g. $B ∈ \{0, 1\}$ is *binary alphabets* named B, whose elements can only be 0 or 1
	- ### String
		- Sequence over a set of symbols
		- An empty string is an Epsilon ε
		- e.g. we have symbols `0` and `1`, then `0011010` is a string
		- e.g. If alphabet $Z ∈ \{0, 1\}$, then `011101` is a string of alphabets
	- ### Language
		- A set of strings
		- e.g. the English language
			- English language alphabets `Σ = {a, b, c, .., z}`
			- Then any sets of strings containing only symbols from Σ is a valid English language string
		- e.g. some simple binary language, Simbin
			- Simbin alphabets `Σ = {0, 1}`
			- Then strings `0`, `1`, and `101011` are valid Simbin strings
			- Strings `02`, `a10` are not valid Simbin strings
		- e.g. Simbin2 language accepts any strings over $Σ ∈ \{0, 1\}$ of length 2
			- Then strings `00`, `01`, `10`, `11` are valid Simbin2 strings
			- But `0`, `100`, `12` are not valid Simbin2 strings
		- e.g. Simbin3 language accepts any strings over $Σ ∈ \{0, 1\}$ that starts with symbol `0`
			- Then `0110`, `011111`, `0` are valid Simbin3 strings
		- From examples Simbin1, Simbin2, and Simbin3, only Simbin2  have finite sets of valid strings
	- ### Powers of Sigma Σ
		- Σ^n is the set of strings of length `n`
		- e.g. the language has this alphabets: `Σ = {0, 1}`
			- Σ^0 -> All strings of length 0 -> `Σ^0 = {ε}`
			- Σ^1 -> All strings of length 1 -> `Σ^1 = {0, 1}`
			- Σ^2 -> All strings of length 2 -> `Σ^2 = {00, 01, 10, 11}`
		- #### Cardinality = Σ^n
			- Number of elements in a set
			- e.g. if the language has this alphabet set `Σ = {0, 1}`
			  id:: 6585ba6f-778d-4666-af9d-42ea5a9b07f3
				- Then cardinality is 2^n (Σ has 2 elements)
		- #### `Σ* (or  Σ^*)` (assume alphabets `Σ = {0, 1}`)
			- Sets of all possible strings over `{0, 1}`
			- `Σ* = Σ^0 ∪ Σ^1 ∪ Σ^2 ∪ Σ^3 ...`
			- `Σ* = {ε} ∪ {0, 1} ∪ {00, 01, 10, 11} ∪ {000, 001, 010, 011, 100, ...} ...`
			- #### `Σ* (or  Σ^*)` (assume alphabets `Σ = {0, 1}`)
		- **`Σ† (or Σ+)` is like `Σ*` but without `ε`**
- ## [[FSM]] Finite state automata
	- > **A machine with finite states**
	- Simple, with known sets of states
	- Have no memory
	- Set of all states `Q`
	  collapsed:: true
		- Initial state `q1`
	- Set of all inputs `Σ`
	- ## [[DFA]]
		- A [[FSM]] with **no outputs**
		- **The transition table cells must be fully populated**
		  collapsed:: true
			- All states mush have known path given inputs, including the **dead** or **trap** states
			  collapsed:: true
				- `Q x Σ -> Q`
			- All inputs must have known destinations for all states
		- Accepts only if exits with one of the final states
		- Deterministic and very simple
		- Can have many final states, but only 1 initial states
		- Can be minimized (less states)
		- Examples
			- {{renderer code_diagram,plantuml}}
				- ```plantuml
				  @startuml
				  caption This machine accepts any strings ending with symbol '1'
				  left to right direction
				  hide empty description
				  
				  state start <<start>>
				  state q2 <<end>>
				  
				  start --> q1
				  
				  q1-[#red]->q1: 0
				  q1-[#red]->q2: 1
				  
				  q2-[#red]->q1: 0
				  q2-[#red]->q2: 1
				  
				  @enduml
				  ```
			- {{renderer code_diagram,plantuml}}
				- ```plantuml
				  @startuml
				  caption This machine accepts any strings starting with 1
				  left to right direction
				  hide empty description
				  
				  state start <<start>>
				  state q2 <<end>>
				  
				  start --> q1
				  
				  q1-[#red]->q1: 0
				  q1-[#red]->q2: 1
				  
				  q2-[#red]->q2: 0
				  q2-[#red]->q2: 1
				  
				  @enduml
				  ```
	- ## [[NFA]]
		- A [[FSM]] with **no outputs**
		- **Accepts input if *some* path leads to final states**
		- Multiple paths possible
			- A state + input can lead to >1 states
			- State `q1` may go to `q2` *or* `q3` on input `a`
		- Can have many final states, but only 1 initial states
		- Examples
			- {{renderer code_diagram,plantuml}}
			  collapsed:: true
				- ```plantuml
				  @startuml
				  left to right direction
				  hide empty description
				  
				  state start <<start>>
				  state q4 <<end>>
				  
				  start --> q1
				  
				  q1-[#red]->q1: a
				  q1-[#red]->q2: a
				  
				  q2-[#red]->q1: b
				  q2-[#blue]->q3: b
				  
				  q3-[#red]->q4: a
				  q3-[#blue]->q4: ε
				  
				  @enduml
				  ```
				- Accepts `ab`, `aba`, `abb`
				- Rejects `aa`
		- NFA does not map to a physical, real-world machine, but is used to do maths and model problems
		- Not that deterministic (but still has **finite states**)
		- The transition function maps Q and Σ to 2^Q
			- `Q x Σ -> 2^Q`
			- e.g. if `Q = [A, B, C]` then possible transitions are `[A, B, C, AA, AB, AC, BA, BB, BC, CA, CB, CC]`
		- Phi `Φ` means the transition will not happen (not to be confused with Epsilon `ε`)
		- Not to be confused with [[Epsilon-NFA]]
		- Can be converted into [[DFA]] - the resulting DFA may have more states than the original NFA
		- To solve complex problems, we can first design a NFA, and then convert it into [[DFA]], before finally minimizing the DFA.
	- ## [[Epsilon-NFA]]
		- Epsilon `ε` is empty string input
		- The formal definition is the same for normal [[NFA]], **excepts the transition function maps `Q x Σ ∪ ε -> 2^Q`**
		- Every state that gets Epsilon goes to itself including `q0` and final states
		- Can be converted to NFA with Epsilon closures
		- ### Epsilon closure `ε*`
			- All states that can be reached by only seeing Epsilon `ε`
	- ## [[Moore machines]]
		- Have outputs associated with states
		- Can be converted into [[Mealy machines]]
	- ## [[Mealy machines]]
		- Have outputs associated with *transition*
		- Mealy conversion to [[Moore machines]] will result in more states in the target Moore machines
		  collapsed:: true
			- Let's say Mealy has `x` number of states, and `y` number of outputs
			- The resulting Moore could have `x*y` number of states and the same `y` number of outputs
			- The resulting Moore will not have output associated with its initial states
- ## [[Regular Expression]]
	- > **Represent sets of strings in algebraic fashion**, such that a finite automata [[FSM]] can describe a language  (see [[Regex]] for practical syntax
	- > Λ and E are used to denote empty symbol (Epsilon), and Phi Φ used to denote empty set
	- ### 5 rules
		- 1. **Terminal symbols**, including empty `Λ` and null/unaccepted `ϕ`, are regex
		- 2. **Unions of 2 regexes** are also regex (`R1+R2`)
		- 3. **Concatenation of 2 regexes** are also regex (`R1.R2`)
		- 4. **Iteration or closures of regexes** are also regex `R -> R*`
			- Closure of alphabet `a -> a*`, where `a*` expands to `a* =  {Λ, aa, aaa, aaaa}`
				- a* then includes empty symbol Λ, a, aa, aaa, aaaa, ...
		- 5. The regular expression over Σ are those obtained by applying the 4 rules above
	- ### Examples: define the following sets as regex
		- `{0, 1, 2}`
			- Accepts any strings containing terminal symbols `0` or `1` or `2`
			- `R = 0 + 1 + 2`
		- `{Λ, ab}`
			- Accepts any strings containing empty symbol `Λ`, and terminal symbol`ab`
			- `R =  Λ  ab`
			- When we only have symbol (`ab`) and the empty symbol  `Λ`, we don't have to write down the `+` sign
		- `{abb, a, b, bba}`
			- Accepts any strings containing at least one string from the set
			- `R = abb + a + b + bba`
		- `{Λ, 0, 00, 000, ...}`
			- Accepts closure of `0`
			- `R = 0*`
				- (`Λ`  was already in `0*`)
		- `{1, 11, 111, 1111...}`
			- Looks like closure, but the set does not include `Λ`, so we denote it with a cross or plus
			- `R -> 1†` (or `R -> 1+`)
			- In other words, `R† = R.R*`, and `E + R† = R*`
	- ### Identities
		- > In this block, E is used as Epsilon Λ (accepted empty string),
		  while Phi Φ refers to null input (not accepted)
		- `Φ + R = R`
		- `Φ.R + R.Φ = Φ`
		  id:: 6585c5be-508d-4b4b-90fb-4469408566b6
		- `E.R = R.E = R`
		- `Ε* = E, and Φ* = E`
		- `R + R = R`
		- `R*.R* = R*`
		- `R.R* = R*.R = R†`
		- `(R*)* = R*`
		- `E + R.R* = E + R*.R = E + R† = R*`
		- `(P.Q)*.P = P.(Q.P)*`
		- `(P + Q)* = (P*.Q*)* = (P* + Q*)*`
		- `(P + Q).R = P.R + Q.R`
			- and `R.(P + Q) = R.P + R.Q`
	- ### Arden's theorem
		- If P and Q are regexes over Σ, **and P does not contain E**
		- Then `R = Q + R.P` has a unique solution `R = Q.(P*)`
		- Proof using identities
			- `R = Q + R.P` (and we know that `R = Q.P*`)
			- `R = Q + Q.P*.P`
			- `R = Q.(E + P*.P)`
				- Recall that `E  + R*.R = R*`
			- `R = Q.(E + P†)`
			- `R = Q.(P*)`
		- Or we can keep expanding R:
			- `R = Q + R.P`
			- `R = Q + (Q + R.P).P` which is `Q + Q.P  R.P^2)`
			- `R = Q + (Q + (Q + R.P).P).P` which is `Q + Q.P + Q.P^2 + R.P^3`
			- `R = Q + Q.P + Q.P^2 + Q.P^3 + ... + Q.P^n + R.P^n+1`
			- `R = Q.(E + P + P^2 + P^3 + ..)`
			- `R = Q.(E + P†)`
			- R = `Q.(P*)`
	- ### Proof examples
		- Prove that `(1+00*1)+(1+00*1).(0+10*1)*(0+10*1)` is equal to `0*1(0+10*)1*`
		- `(1+00*1)+(1+00*1).(0+10*1)*(0+10*1)` (start)
		- `(1+00*1).[(E+(0+10*1)*(0+10*1))]`
			- We pulled common term `(1+00*1)` out
		- `(1+00*1).[(E+(0+10*1)†]`
		- `(1+00*1).(0+10*1)*`
		- `[E.(1+00*1)].(0+10*1)*`
			- We added E to the first term, since `E.R = R`
		- `(E + 00*).1.(0+10*1)*`
			- We pull `(E + 00*)` out of `[E.(1+00*1)]` to get `(E + 00*).1`
		- `0*.1.(0+10*1)*`
	- ### Designing simple regexes
		- L1 accepts all strings of length 2 over `{a, b}`
			- `L1 = {aa, ab, ba, bb}`
			- `R1 = aa + ab + ba +  bb`
			- `R1 = a(a+b) + b(a+b)`
			- `R1 = (a+b)(a+b)`
			- If L1 was to accept strings of length 3, then `R1 = (a+b)(a+b)(a+b)`
		- L2 accepts all strings of min length 2 over `{a, b}`
			- `L2 = {aa, ab, ba, bb, aaa, aab, ...}`
			- `R2 = aa + ab + ba + bb + aaa + aab + ...`
			- `R2 = (a+b)(a+b) + aaa + aab + abb ...`
			- `R2 = (a+b)(a+b) + (a+b)*`
		- L3 accepts all strings of max length 2 over `{a,  b}`
			- `L3 = {E, a, b, aa, ab, ba, bb}`
			- `R3 = E + a + b + aa + ab + ba + bb`
			- `R3 = (E + a + b)(E + a + b)`
				- This will also matches empty strings (hits `E` on both terms)
				- This will also matches a single `a` (hits `a` and E)
				- This will also matches `bb` (hits `b` and `b`)
	- ### Converting regex to [[DFA]] and [[NFA]]
		- The resulting regex will match all string inputs acceptable by the source state machines
		- Unions are used to combine paths that lead to the same states
		- #### DFA to regex
			- Start from initial state, and work your way to the final state
			- Write down every possible states reachable by the the current state
			- Simplify the regexes
			- Examples
				- {{renderer code_diagram,plantuml}}
					- ```plantuml
					  @startuml
					  left to right direction
					  hide empty description
					  
					  start --> q1
					  
					  q1-[#red]->q2: a
					  q1-[#blue]->q3: b
					  
					  q2-[#red]->q4: a
					  q2-[#blue]->q1: b
					  
					  q3-[#red]->q1: a
					  q3-[#blue]->q4: b
					  
					  q4-[#red]->q4: a
					  q4-[#blue]->q4: b
					  q4: Accepted
					  
					  @enduml
					  ```
				- We start from `q1`
					- `q1 = E + q2b + q3a`
					- `q2 = q1a`
					- `q3 = q1b`
					- `q4 = q2a + q3b + q4a + q4b`
				- We can now solve for `p1`
					- `q1 = E + q1ab + q1ba`
					- `q1 = E + q1.(ab + ba)`
					- Recall that `R = Q + R.P = Q.(P*)`
					- `q1 = E.(ab+ba)*`
					- `q1 = (ab+ba)*`
		- #### NFA to regex
			- Start from final state, and work your way back to the initial state
			- Write down every possible previous states and their inputs to reach the current state
			- Simplify the regexes
			- Examples
				- {{renderer code_diagram,plantuml}}
					- ```plantuml
					  @startuml
					  
					  left to right direction
					  hide empty description
					  
					  state start <<start>>
					  
					  start-->q1
					  
					  q1-[#red]->q1: a
					  q1-[#red]->q2: a
					  
					  q2-[#red]->q3: a
					  q2-[#blue]->q1: b
					  q2-[#blue]->q2: b
					  
					  q3-[#blue]->q2: b
					  q3: Accepted
					  
					  @enduml
					  ```
				- We start from `q3`, and this gets us
					- `q3 = q2a`
					- `q2 = q1b + q2b + q3b`
					- `q1 = E + q1a + q2b`
				- Then we simplify (substitution)
					- `q3 = q1a + q2ba + q3ba`
					- `q2 = q1a + (b+ab)*`
					- `q1 = (a + a(b+ab)*b)*`
				- And finally, we solve for `q3`
					- `q3 = q2a`
					- `q3 = q1a + (b+ab)*`
					- `q3 = (a+a(b+ab)*)b*.a(b+ab)*a`
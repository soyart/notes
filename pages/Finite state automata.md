- > **A machine with finite states**
- The most basic type of machines.
- Good for regular languages and [[Regular expression]]
- ### Real world examples
  collapsed:: true
	- Vending machines can accept patterns of coins without using memory
		- {{renderer code_diagram,plantuml}}
		  collapsed:: true
			- ```plantuml
			  @startuml
			  left to right direction
			  hide empty description
			  
			  caption Vending machine accepts 10 bath with coins 10 and 5
			  
			  state start <<start>>
			  state end: accept
			  state bad: reject
			  
			  start -[#blue]-> end: 10
			  start -[#red]-> q1: 5
			  q1-[#red]->end: 5
			  q1-[#blue]->bad: 10
			  bad-[#red]->bad: 5
			  bad-[#blue]->bad: 10
			  end-[#red]->bad: 5
			  end-[#blue]->bad: 10
			  
			  @enduml
			  ```
- ## [[DFA]] - Deterministic finite automata
	- ### Definition $M = (Q, \Sigma, \delta, q_0, F)$
	  id:: 3d3cd125-712c-4563-b1d1-54b1be607b43
		- Set of all states $Q$
			- States are usually represented with $q_i$, e.g. $Q = \{q_0, q_1, q_2, q_3, \dots\}$
		- Set of all input alphabets $\Sigma$
		- Initial state $q_0$
			- $q_0 \in Q$
		- Set of all final states $F$
			- $F \subseteq Q$
			- There can be more than >= 1 states
		- Transition function $\delta$
			- $\delta: Q \times \Sigma \mapsto Q$
			- The function $\delta$ maps the current state in $Q$, and some input in $\Sigma$, to a new state still in $Q$
			- **The transition table cells must be fully populated**
				- All states mush have known path given inputs, including the **dead** or **trap** states
					- `Q x Σ -> Q`
				- All inputs must have known destinations for all states
	- **No outputs**
	- **Accepts input only if exits with one of the final states**
	- ### Examples
	  collapsed:: true
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
	- ### Weird examples
	  collapsed:: true
		- #### Recognize $A_1 \cup A_2$, where $A_1$ and $A_2$ are both regular languages
		  id:: dc35369f-7eee-4bb9-af21-e00b23a9109a
			- This proves that, if $A_1$ and $A_2$ are regular languages, then, if we could construct an FSM that recognizes $A_1 \cup A_2$, then that new language $A_1 \cup A_2$ is also regular
			- Given 2 languages and their machines:
				- $M_1 = (Q_1, \Sigma_1, \delta_1, q_1, F_1)$ recognizes $A_1$
				- $M_2 = (Q_2, \Sigma_2, \delta_2, q_2, F_2)$ recognizes $A_2$
			- Construct a new DFA $M$ recognizing $A_1 \cup A_2$
			- Lemma: $M$ should recognize string $w$ if either machine $M_1$ or $M_2$ accepts $w$
			- Solution
				- We can do this by having wrapping both $M_1$ and $M_2$ inside a new machine $M$
				- $M$'s states ($Q_M$)
					- $Q_M = Q_1 \times Q_2 \newline Q_M = \{(q_1, q_2) \mid q_1 \in Q_1$ and $q_2 \in Q_2 \}$
				- $M$'s initial state $q_M$
					- Is the pair of $M_1$'s and $M_2$'s initial states
					- $q_M = (q_1, q_2)$
				- $M$'s transition function $\delta_M$
					- On input $a$, the transition function should feed the same input to inner machines $M_1$ and $M_2$, and storing both inner machine states as a pair. That pair becomes $M$'s new current state
					- That is, if inner machine $M_1$ has current state $s1$, and inner machine $M_2$ has current state $s_2$, then:
					- $\delta_M((s1, s2), a) \mapsto (\delta_1(s1, a), \delta_2(s2, a))$
				- $M$'s final states ($F_M$)
					- Recall that we are validating $A_1 \cup A_2$ and $L(M_1) = A_1 \mid L(M_2) = A_2$
					- Which means that $M$ accepts, if either $M_1$ or $M_2$ accepts
					- collapsed:: true
					  > So $F_M$ **can NOT be** $F_1 \times F_2$ (that would mean **both** $M_1$ and $M_2$ have to accept in order for $M$ to do so)
						- If $F_1 = \{a, b\}$ and $F_2 = \{x, y, z\}$
						- Then $F_M = F_1 \times F_2 = \{(a, x), (a, y), (a, z), (b,x), (b,y), (b,z)\}$
					- Instead, $F_M = (F_1 \times Q_2) \cup (F_2 \times Q_1)$
						- i.e. some states which either have $F_1$ or $F_2$
	- ### Minimization
## [[NFA]] - Non-deterministic finite automata
	- ### Definition $M = (Q, \Sigma, \delta, q_0, F)$
	  collapsed:: true
		- $Q$, $q_0$, $F$ is the same as with [DFA definition](((3d3cd125-712c-4563-b1d1-54b1be607b43)))
		- Alphabet $\Sigma$ is actually $\Sigma_\epsilon = \{\Sigma \cup \Epsilon\}$
		  collapsed:: true
			- This means that NFA is allowed to jump without reading any input (i.e. reading $\epsilon$)
		- Transition function $\delta$ does not map to $Q$, **but to powerset of Q** $\mathcal{P}(Q)$
		  collapsed:: true
			- $\delta: Q \times \Sigma_\epsilon \mapsto \mathcal{P}(Q) = \{R \mid R \subseteq Q\}$
			- $\vert\mathcal{P}(Q)\vert = 2^Q$
			  collapsed:: true
				- e.g. if $Q = \{A, B, C\}$ then $\delta: Q \times \Sigma = \{A, B, C, AA, AB, AC, BA, BB, BC, CA, CB, CC\}$
			- Example
			  collapsed:: true
				- {{renderer code_diagram,plantuml}}
				  collapsed:: true
					- ```plantuml
					  @startuml
					  left to right direction
					  hide empty description
					  
					  state start <<start>>
					  state q4: Accepted
					  
					  start --> q1
					  
					  q1-[#red]->q1: a
					  q1-[#red]->q2: a
					  
					  q2-[#red]->q1: b
					  q2-[#blue]->q3: b
					  
					  q3-[#red]->q4: a
					  q3-[#blue]->q4: ε
					  
					  @enduml
					  ```
				- $\delta(q_1, a) = \{q_1, q_2\}$
				- $\delta(q_1, b) = \varnothing$
				  collapsed:: true
					- Likewise
					- $\delta(q_1, c) = \varnothing$
					- $\delta(q_1, \epsilon) = \varnothing$
				- $\delta(q_2, a) = \varnothing$
				- $\delta(q_2, b) = \{q_1, q_3\}$
				- $\delta(q_3, a) = \{q_4\}$
				- $\delta(q_3, \epsilon) = \{q_4\}$
	- ### Non-determinism
	  collapsed:: true
		- Think of it like the machine's *guessing*, or *branching*
		- **The machine always guesses right**
		- Any *bad* branch will be discarded/ignored on getting more input
		- Ways to think about non-determinism
			- Computational
				- Fork new parallel threads. Accept if any threads lead to $F$
			- Maths
				- Tree with branches. Accept if any branch leads to $F$
			- Magic
				- Guess at each non-deterministic step, and the machine, at runtime, will correctly choose the right path *if* the input is valid.
	- ### Quirks
		- #### No outputs
		- #### Accepts input if *some* path leads to final states
			- Can have many final states, but only 1 initial states
		- #### Multiple paths possible
			- A state + input can lead to >1 states
			- On input `a`, state $q_1$ *may* go to $q_2$ or $q_3$
		- #### Empty string $\epsilon$ is legal as input
			- In this case, if $q_j$ can be reached from $q_i$ via input $\epsilon$, the NFA can jump from $q_i$ to $q_j$ at any time without reading any input
		- #### Empty set $\phi$ is legal as destination (i.e. no state transition)
			- To do nothing, just leave no paths on the state and the machine will not go to any state
	- ### Examples
	  collapsed:: true
		- {{renderer code_diagram,plantuml}}
			- ```plantuml
			  @startuml
			  left to right direction
			  hide empty description
			  
			  caption Accepts ab, aba, abb, BUT rejects aa
			  
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
	- ### Closures
	  collapsed:: true
		- #### $A_1 \cup A_2$ (like [this DFA example](((dc35369f-7eee-4bb9-af21-e00b23a9109a))), but with NFA)
			- Like with DFA, we'll need a new machine $M$ that wraps $M_1$ and $M_2$.
			- But with the power of non-determinism, we can just **non-deterministically connect** $M_0$ **to the start states of** $M_1$ and $M_2$ on empty input
			- Think of this like parallel processing of both $A_1$ and $A_2$
			- Accept if *some path* leads to *some accepted state* in either $M_1$ or $M_2$
			- {{renderer code_diagram,plantuml}}
				- ```plantuml
				  @startuml
				  left to right direction
				  hide empty description
				  
				  caption M1 recognizes A1
				  
				  state q0: start
				  state q3: accepted
				  state q4: accepted
				  
				  q0 -[#blue]-> q1: b
				  
				  q1-[#red]->q1: a
				  q1-[#red]->q2: a
				  q1-[#blue]->q4: b
				  
				  q2-[#red]->q1: a
				  q2-[#blue]->q3: b
				  
				  @enduml
				  ```
			- {{renderer code_diagram,plantuml}}
				- ```plantuml
				  @startuml
				  left to right direction
				  hide empty description
				  
				  caption M2 recognizes A2
				  
				  state r0: start
				  state r3: accepted
				  
				  r0 -[#blue]-> r1: b
				  
				  r1-[#red]->r1: a
				  r1-[#red]->r2: a
				  
				  r2-[#red]->r1: b
				  r2-[#blue]->r3: b
				  
				  @enduml
				  ```
			- {{renderer code_diagram,plantuml}}
				- ```plantuml
				  @startuml
				  left to right direction
				  hide empty description
				  
				  caption M wraps M1 to M2 for A1 U B1
				  
				  state start <<start>>
				  state end <<end>>
				  state q0 #lightblue: Start state M1
				  state q3 #lightblue: Accept state M1
				  state q4 #lightblue: Accept state M1
				  state r0 #red: Start state M2
				  state r3 #red: Accept state M2
				  
				  start -[#green]-> q0: e
				  start -[#green]-> r0: e
				  
				  q0 --> q3: A1
				  q0 --> q4: A1
				  q3 -[#green]-> end: e
				  q4 -[#green]-> end: e
				  
				  r0 --> r3: A2
				  r3 -[#green]-> end: e
				  
				  @enduml
				  ```
		- #### $A_1 \circ A_2$
			- Like with DFA, we need a new machine $M$ that wraps $M_1$ and $M_2$
			- {{renderer code_diagram,plantuml}}
				- ```plantuml
				  @startuml
				  left to right direction
				  hide empty description
				  
				  caption M1 recognizes A1
				  
				  state q0: start
				  state q3: accepted
				  state q4: accepted
				  
				  q0 -[#blue]-> q1: b
				  
				  q1-[#red]->q1: a
				  q1-[#red]->q2: a
				  q1-[#blue]->q4: b
				  
				  q2-[#red]->q1: a
				  q2-[#blue]->q3: b
				  
				  @enduml
				  ```
			- {{renderer code_diagram,plantuml}}
				- Then we can construct $M$ by wrapping $M_1$ and $M_2$, jumping on $\epsilon$ from any state in $F_1$ to $q1$ non-deterministically
				- ```plantuml
				  @startuml
				  left to right direction
				  hide empty description
				  
				  caption M2 recognizes A2
				  
				  state r0: start
				  state r3: accepted
				  
				  r0 -[#blue]-> r1: b
				  
				  r1-[#red]->r1: a
				  r1-[#red]->r2: a
				  
				  r2-[#red]->r1: b
				  r2-[#blue]->r3: b
				  
				  @enduml
				  ```
			- We can *non-deterministically connect* the inner machines on empty input instead (so that the $M$ can just jump to $M_2$)
			- {{renderer code_diagram,plantuml}}
				- ```plantuml
				  @startuml
				  left to right direction
				  hide empty description
				  
				  caption M connects M1 to M2
				  
				  state start <<start>>
				  state end <<end>>
				  state q0 #lightblue: Start state M1
				  state q3 #lightblue: Accept state M1
				  state q4 #lightblue: Accept state M1
				  state r0 #red: Start state M2
				  state r3 #red: Accept state M2
				  
				  start --> q0: e
				  
				  q0 --> q3: A1
				  q0 --> q4: A1
				  
				  q3 -[#green]-> r0: e
				  q4 -[#green]-> r0: e
				  
				  r0 --> r3: A2
				  r3 -[#green]-> end: e
				  
				  @enduml
				  ```
			- This means that, the machine starts with recognizing $A_1$, but it may jump to do $A_2$ **at any point in time, non-deterministically**
			- This NFA will only accept the input if the last state is in $F_2$ ($r3$).
		- #### $A^\ast$
			- We can just feed the machine back to a start state every time it landed in some accepted states
			- But we'll also have to handle an empty string, which $\in A^\ast$
			- {{renderer code_diagram,plantuml}}
				- ```plantuml
				  @startuml
				  left to right direction
				  hide empty description
				  
				  caption M1 recognizes A
				  
				  state q0: start
				  state q3: accepted
				  state q4: accepted
				  
				  q0 -[#blue]-> q1: b
				  
				  q1-[#red]->q1: a
				  q1-[#red]->q2: a
				  q1-[#blue]->q4: b
				  
				  q2-[#red]->q1: a
				  q2-[#blue]->q3: b
				  
				  @enduml
				  ```
			- {{renderer code_diagram,plantuml}}
				- ```plantuml
				  @startuml
				  left to right direction
				  hide empty description
				  
				  caption M recognizes A*
				  
				  state start <<start>>
				  state end <<end>>
				  state q0 #lightblue: Start state M1
				  state q3 #lightblue: Accept state M1
				  state q4 #lightblue: Accept state M1
				  
				  start -[#green]-> q0: e
				  start -[#green]-> end: e
				  
				  q0 --> q3: A
				  q0 --> q4: A
				  
				  q3 -[#green]-> start: e
				  q4 -[#green]-> start: e
				  
				  @enduml
				  ```
	- NFA does not map to a physical, real-world machine, but is used to do maths and model problems
	- Not that deterministic (but still has **finite states**)
	- ### GNFA (generalized NFA)
	  collapsed:: true
		- GNFA is a high-level NFA whose transition allows [[Regular expression]] to be used as labels instead of simple symbols
		- Example: the simplest GNFA for any regex
			- Let $R$ be some regular expressions
			- Let $r = R$
			- Then our equivelent GNFA is:
			- {{renderer code_diagram,plantuml}}
			  id:: 65a17ad7-5035-47ad-85ec-d1080199050e
			  collapsed:: true
				- ```plantuml
				  @startuml
				  left to right direction
				  hide empty description
				  
				  caption GNFA equivalent of regular expression r
				  
				  state q1 <<start>>
				  state q2 <<end>>
				  
				  q1-->q2: r
				  
				  @enduml
				  ```
			- This GNFA is cool because it should be able to handle any regex $R$ (if you think about it, the minimum number of $k$ for GNFA is 2, start and end)
			- This special GNFA with 2 states is **the base case for recursion when proving**
		- #### Proving that [[Regular expression]] are [equivalent](((659712b0-694d-436f-8d4d-6dd52157c35a))) to NFAs
			- id:: 65a17cc6-e53c-4dea-ab10-17a656881ab6
			  > In this notes, the GNFA in use will have special forms (which can be converted into from any GNFA) with some special properties:
			  
			  1. Only 1 final state, separate from the initial state
			  2. Only 1 arrow for any $q_i$ to $q_j$, except if (a) exiting initial state (b) entering final state
			- Any GNFA with $k$ states can be converted into a new GNFA with $k-1$ states, given that $(k - 1) \geq 2$
				- #### Convert GNFA to GNFA (from $k$ to $k-1$ states)
					- 1. Pick any state $x$ except the initial and final state
					  2. Remove $x$
					  3. Repair damages from removing $x$
					- > GNFA below is in [special form](((65a17cc6-e53c-4dea-ab10-17a656881ab6)))
					- {{renderer code_diagram,plantuml}}
					  collapsed:: true
						- ```plantuml
						  @startuml
						  
						  left to right direction
						  hide empty description
						  
						  caption Original GNFA (k)
						  
						  state start <<start>>
						  state end <<end>>
						  state x: to be removed
						  state qi
						  state qj
						  
						  start --> qi
						  qi --> x: r1
						  x --> x: r2
						  x --> qj: r3
						  qi --> qj: r4
						  qj --> end: r5
						  
						  @enduml
						  ```
					- We can see that if we remove $x$, the transition connection $q_i \rightarrow q_j$ via $x$  was damaged, so we must restore it.
						- Note: see that $x$ loops on itself on input $r_2$, so $x \times {r_2}^\ast \mapsto x$
					- The connection $q_i \rightarrow q_2$ via $x$ that was lost was 3 transitions:
					  collapsed:: true
					  1. $q_i \times r_1 \mapsto x$
					  2. $x \times {r_2}^\ast \mapsto x$
					  3. $x \times r_3 \mapsto q_j$
						- This mean that, before we remove $x$, there was a transition $q_i \rightarrow q_j$ via $x$ that
						  1. See $r_1$
						  2. See $r_2$ one or many times
						  3. See $r_3$
					- That lost connection can be represented as $q_i \times r_1{r_2}^\ast r3 \mapsto q_j$
					- Then we can $\cup$ this lost connection to the untouched transition $q_i \times r_4 \mapsto q_j$
					- {{renderer code_diagram,plantuml}}
					  collapsed:: true
						- ```plantuml
						  @startuml
						  
						  left to right direction
						  hide empty description
						  
						  caption Original GNFA (k)
						  
						  state start <<start>>
						  state end <<end>>
						  state x: removed
						  state qi
						  state qj
						  
						  start --> qi
						  qi --> qj: r1.(r2)*.r3 U r4
						  qj --> end: r5
						  
						  @enduml
						  ```
			- Then we can recursively reduce $k$ until it becomes [the base case ($k = 2$)](((65a17ad7-5035-47ad-85ec-d1080199050e))), and prove that regexes and GNFA are equivalent
	- Can be converted into [[DFA]] - the resulting DFA may have more states than the original NFA
	- To solve complex problems, we can first design a NFA, and then convert it into [[DFA]], before finally minimizing the DFA.
## [[Moore machines]]
collapsed:: true
	- **Outputs associated with states**
	- Can be converted into [[Mealy machines]]
## [[Mealy machines]]
collapsed:: true
	- **Outputs associated with transition**
	- Mealy conversion to [[Moore machines]] will result in more states in the target Moore machines
	  collapsed:: true
		- Let's say Mealy has `x` number of states, and `y` number of outputs
		- The resulting Moore could have `x*y` number of states and the same `y` number of outputs
		- The resulting Moore will not have output associated with its initial states
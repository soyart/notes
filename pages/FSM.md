- > **A machine with finite states**
- The most basic type of machines.
- Good for regular languages and [[Regular Expression]]
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
		- $Q$, $q_0$, $F$ is the same as with [DFA definition](((3d3cd125-712c-4563-b1d1-54b1be607b43)))
		- Alphabet $\Sigma$ is actually $\Sigma_\epsilon = \{\Sigma \cup \Epsilon\}$
			- This means that NFA is allowed to jump without reading any input (i.e. reading $\epsilon$)
		- Transition function $\delta$ does not map to $Q$, **but to powerset of Q** $\mathcal{P}(Q)$
			- $\delta: Q \times \Sigma_\epsilon \mapsto \mathcal{P}(Q) = \{R \mid R \subseteq Q\}$
			- Example
			  collapsed:: true
				- {{renderer code_diagram,plantuml}}
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
					- Likewise
					- $\delta(q_1, c) = \varnothing$
					- $\delta(q_1, \epsilon) = \varnothing$
				- $\delta(q_2, a) = \varnothing$
				- $\delta(q_2, b) = \{q_1, q_3\}$
				- $\delta(q_3, a) = \{q_4\}$
				- $\delta(q_3, \epsilon) = \{q_4\}$
	- ### Non-determinism
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
		- #### Empty set $\Phi$ is legal as destination (i.e. no state transition)
	- ### Examples
		- {{renderer code_diagram,plantuml}}
		  collapsed:: true
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
		- #### $A_1 \cup A_2$ (like [this DFA example](((dc35369f-7eee-4bb9-af21-e00b23a9109a))), but with NFA)
			- Like with DFA, we'll need a new machine $M$ that wraps $M_1$ and $M_2$.
			- But with the power of non-determinism, we can just **non-deterministically connect** $M_0$ **to the start states of** $M_1$ and $M_2$ on empty input
			- Think of this like parallel processing of both $A_1$ and $A_2$
			- Accept if *some path* leads to *some accepted state* in either $M_1$ or $M_2$
			- {{renderer code_diagram,plantuml}}
			  collapsed:: true
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
			  collapsed:: true
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
			  collapsed:: true
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
			  collapsed:: true
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
			  collapsed:: true
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
			  collapsed:: true
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
			  collapsed:: true
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
			  collapsed:: true
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
	- The transition function maps Q and Σ to 2^Q
		- `Q x Σ -> 2^Q`
		- e.g. if `Q = [A, B, C]` then possible transitions are `[A, B, C, AA, AB, AC, BA, BB, BC, CA, CB, CC]`
	- Phi `Φ` means the transition will not happen (not to be confused with Epsilon `ε`)
	- Can be converted into [[DFA]] - the resulting DFA may have more states than the original NFA
	- To solve complex problems, we can first design a NFA, and then convert it into [[DFA]], before finally minimizing the DFA.
## [[Moore machines]]
	- **Outputs associated with states**
	- Can be converted into [[Mealy machines]]
## [[Mealy machines]]
	- **Outputs associated with transition**
	- Mealy conversion to [[Moore machines]] will result in more states in the target Moore machines
	  collapsed:: true
		- Let's say Mealy has `x` number of states, and `y` number of outputs
		- The resulting Moore could have `x*y` number of states and the same `y` number of outputs
		- The resulting Moore will not have output associated with its initial states
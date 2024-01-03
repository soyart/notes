- > **Represent sets of strings in algebraic fashion**, such that a finite automata [[FSM]] can describe a regular language (see also [[Language theory]], and [[Regex]] for practical syntax of regular expressions)
- > $\epsilon$ are used to denote empty symbol, the epsilon set (set with only $\epsilon$ as member) is denoted $\Epsilon$, and Phi $\Phi$ used to denote empty language (empty set).
- ## 5 regex rules
	- 1. **Terminal symbols** are regex, including empty string $\epsilon$ and empty set $\Phi$
	- 2. **Unions of 2 regexes** are also regex (expressed as $R_1+R_2$)
	- 3. **Concatenation of 2 regexes** are also regex (expressed as $R_1 \circ R_2$ or $R_1R_2$)
	- 4. **Iteration or closures of regexes** are also regex (expressed as $R \mapsto R^\ast$)
		- Star closure of alphabet $a \mapsto a^\ast$, where $a^\ast =  \{\epsilon, a, aa, aaa, aaaa, \dots, a^k\}$
		- Plus closure of alphabet $a \mapsto a^+$, where $a^+ = \{a, aa, aaa, aaaa, \dots, a^k\}$
	- 5. The regular expression over alphabet $\Sigma$ are those obtained by applying the 4 rules above
- ## Language to regex
	- $L_1 = \{0, 1, 2\}$
		- Accepts any strings from the set
		- $R_1 = 0 + 1 + 2$
	- $L_2 = \{\epsilon, ab\}$
		- Accepts any strings from the set
		- $R_2 =  \epsilon + ab$
	- $L_3 = \{abb, a, b, bba\}$
		- Accepts any strings from the set
		- $R_3 = abb + a + b + bba$
	- $L_4 = \{\epsilon, 0, 00, 000, ...\}$
		- Accepts closure of terminal symbol $0$
		- $R_4 = 0^\ast$
			- Note: $\epsilon \in 0^\ast$
	- $L_5 = \{1, 11, 111, 1111, \dots\}$
		- Looks like a star closure, but the set does not include empty string $\epsilon$
		- $R_5 = 1^+$
	- $L_6 = \{\Epsilon \cup \{a^i, b^j\}\}$
		- e.g. $L_6 \{\epsilon, a, b, aa, ab, bb, aaa, aab, \dots\}$
		- Accepts an empty string or any iterations of $a$ and $b$
		- $R_6 = a^\ast b^\ast$
- ## Identities
	- $\Phi + R = R$
	- $\Phi R + R\Phi = \Phi$
	- $\Epsilon R = R\Epsilon = R$
	- $\Epsilon^\ast = \Epsilon$, and $\Phi^\ast = \Epsilon$
	- $R + R = R$
	- $R^\ast R^\ast = R^\ast$
	- $RR^\ast = R^\ast R = R^+$
	- $(R^\ast)^\ast = R^\ast$
	- $\Epsilon + RR^\ast = \Epsilon + R^\ast R = \Epsilon + R^+ = R^\ast$
	- $(PQ)^\ast P = P (QP)^\ast$
	- $(P + Q)^\ast = (P^\ast Q^\ast)^\ast = (P^\ast + Q^\ast)^\ast$
	- $(P + Q)R = PR + QR$ and $R(P + Q) = RP + RQ$
- ## Arden's theorem
	- If P and Q are regexes over $\Sigma$, and P does not contain $\epsilon$
	- Then $R = Q + RP$ has a unique solution $R = Q(P^\ast)$
	- Proof using identities
		- $R = Q + R.P$
			- We know that $R = Q(P^\ast) = QP^\ast$
		- $R = Q + QP^\ast P$
		- $R = Q(\Epsilon + P^\ast P)$
			- Recall that $\Epsilon  + R^\ast R = R^\ast$
		- $R = Q(\Epsilon + P^+)$
			- Recall that $\Epsilon + R^+ = R^\ast$
		- $R = Q(P^\ast)$
	- Or we can keep expanding R:
		- $R = Q + RP$
		- $R = Q + (Q + RP)P$
			- Which is $Q + (QP + RP^2)$
		- $R = Q + (Q + (Q + RP)P)P$
			- Which is $Q + QP + QP^2 + RP^3$
		- $R = Q + QP + QP^2 + QP^3 + \dots + QP^n + RP^{(n+1)}$
		- $R = Q(\Epsilon + P + P^2 + P^3 + \dots + P^n)$
		- $R = Q(\Epsilon + P^+)$
		- $R = Q(P^\ast)$
- ## Proof examples
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
- ## Designing simple regexes
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
- ## Converting regex to [[DFA]] and [[NFA]]
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
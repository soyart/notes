title:: Regular expression
> **Represent sets of strings in algebraic fashion**, such that a finite automata [[Finite state automata]] can describe a regular language (see also [[Language theory]], and [[Regex]] for practical syntax of regular expressions)

- > $\epsilon$ are used to denote empty symbol, the epsilon set (set with only $\epsilon$ as member) is denoted $\Epsilon$, and Phi $\phi$ used to denote empty language (empty set).
- ## 5 regex rules
	- 1. **Terminal symbols** are regex, including empty string $\epsilon$ and empty set $\phi$
	- 2. **Unions of 2 regexes** are also regex (expressed as $R_1+R_2$)
	- 3. **Concatenation of 2 regexes** are also regex (expressed as $R_1 \circ R_2$ or $R_1R_2$)
	- 4. **Iteration or closures of regexes** are also regex (expressed as $R \mapsto R^\ast$)
		- Star closure of alphabet $a \mapsto a^\ast$, where $a^\ast =  \{\epsilon, a, aa, aaa, aaaa, \dots, a^k\}$
		- Plus closure of alphabet $a \mapsto a^+$, where $a^+ = \{a, aa, aaa, aaaa, \dots, a^k\}$
	- 5. The regular expression over alphabet $\Sigma$ are those obtained by applying the 4 rules above
- ## Identities
	- $\phi + R = R$
	- $\phi R + R\phi = \phi$
	- $\Epsilon R = R\Epsilon = R$
	- $\Epsilon^\ast = \Epsilon$, and $\phi^\ast = \Epsilon$
	- $R + R = R$
	- $R^\ast R^\ast = R^\ast$
	- $RR^\ast = R^\ast R = R^+$
	- $(R^\ast)^\ast = R^\ast$
	- $\Epsilon + RR^\ast = \Epsilon + R^\ast R = \Epsilon + R^+ = R^\ast$
	- $(PQ)^\ast P = P (QP)^\ast$
	- $(P + Q)^\ast = (P^\ast Q^\ast)^\ast = (P^\ast + Q^\ast)^\ast$
	- $(P + Q)R = PR + QR$ and $R(P + Q) = RP + RQ$
- ## Arden's theorem
  collapsed:: true
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
  collapsed:: true
	- Prove that $(1+00^\ast1)+(1+00^\ast1)(0+10^\ast1)*(0+10^\ast1)$ is equal to $0^\ast1(0+10^\ast)1^\ast$
	- $(1+00^\ast1)+(1+00^\ast1)(0+10^\ast1)^\ast(0+10^\ast1)$
		- We see here that there's a common term $(1+00^\ast1)$, which can be factored out
	- $(1+00^\ast1)\circ[(E+(0+10^\ast1)^\ast(0+10^\ast1))]$
		- We see identity $RR^\ast = R^\ast R = R^+$
	- $(1+00^\ast1)\circ[(E+(0+10^\ast1)^+]$
		- We see identity $\Epsilon + R^+ = R^\ast$
	- $(1+00^\ast1)\circ(0+10^\ast1)^\ast$
	  id:: ebf636ab-bdb1-4e9a-976e-82b577d68aa6
		- We see that we can add \Epsilon to the first term, since we have identity $\Epsilon R = R$
	- $[\Epsilon(1+00^\ast1)]\circ(0+10^\ast1)^\ast$
		- We can pull $\Epsilon + 00^\ast$ out of $\Epsilon(1+00^\ast1)$ to get $(\Epsilon + 00^\ast)\circ1$
			- $(\Epsilon+00^\ast)\circ1$
			- $\Epsilon1+00^\ast1$
			- $1+00\ast1$ - identical to the [one we expanded from](((ebf636ab-bdb1-4e9a-976e-82b577d68aa6)))
	- $(E + 00^\ast)\circ1\circ(0+10^\ast1)^\ast$
		- We see identity $RR^\ast = R^+$, so $00^\ast$ can be made into $0^+$
	- $(\Epsilon + 0^+)1(0+10^\ast1)^\ast$
		- We see identity $\Epsilon + R^+ = R^\ast$
	- $0^\ast1(0+10^\ast1)^\ast$
- ## Language to regex
	- $L_1 = \{0, 1, 2\}$
	  collapsed:: true
		- Accepts any strings from the set
		- $R_1 = 0 + 1 + 2$
	- $L_2 = \{\epsilon, ab\}$
	  collapsed:: true
		- Accepts any strings from the set
		- $R_2 =  \epsilon + ab$
	- $L_3 = \{abb, a, b, bba\}$
	  collapsed:: true
		- Accepts any strings from the set
		- $R_3 = abb + a + b + bba$
	- $L_4 = \{\epsilon, 0, 00, 000, ...\}$
	  collapsed:: true
		- Accepts closure of terminal symbol $0$
		- $R_4 = 0^\ast$
			- Note: $\epsilon \in 0^\ast$
	- $L_5 = \{1, 11, 111, 1111, \dots\}$
	  collapsed:: true
		- Looks like a star closure, but the set does not include empty string $\epsilon$
		- $R_5 = 1^+$
	- $L_6 = \{\Epsilon \cup \{a^i, b^j\}\}$
	  collapsed:: true
		- e.g. $L_6 \{\epsilon, a, b, aa, ab, bb, aaa, aab, \dots\}$
		- Accepts an empty string or any iterations of $a$ and $b$
		- $R_6 = a^\ast b^\ast$
	- ### More examples
		- $L_1$ accepts all strings of length 2 over alphabet $\Sigma = \{a, b\}$
			- $L_1 = \{aa, ab, ba, bb\}$
			- $R_1 = aa + ab + ba +  bb$
			- $R_1 = a(a+b) + b(a+b)$
			- $R_1 = (a+b)(a+b)$
				- If L1 was to accept strings of length 3, then $R1 = (a+b)(a+b)(a+b)$
			- $L_1 = L(R_1) = L((a+b)(a+b))$
		- $L_2$ accepts all strings of min length 2 over alphabet $\Sigma = \{a, b\}$
			- $L_2 = \{aa, ab, ba, bb, aaa, aab, \dots\}$
			- $R_2 = aa + ab + ba + bb + aaa + aab + \dots$
			- $R_2 = (a+b)(a+b) + aaa + aab + abb + \dots$
			- $R_2 = (a+b)(a+b) + (a+b)^\ast$
			- $L_2 = L(R_2) = L((a+b)(a+b) + (a+b)^\ast))$
		- L3 accepts all strings of max length 2 over $\Sigma = \{a,  b\}$
			- $L_3 = \{\epsilon, a, b, aa, ab, ba, bb\}$
			- $R_3 = \epsilon + a + b + aa + ab + ba + bb$
			- $R_3 = (\epsilon + a + b)(\epsilon + a + b)$
			  collapsed:: true
				- This will also matches empty strings (hits $\epsilon$ on both terms)
				- This will also matches a single $a$ (hits $a$ and $\epsilon$)
				- This will also matches $bb$ (hits $b$ and $b$)
			- $L_3 = L(R_3) = L((\epsilon + a + b)(\epsilon + a + b))$
- ## Regex to [[DFA]] and [[NFA]]
  id:: 659712b0-694d-436f-8d4d-6dd52157c35a
	- The resulting regex will match all string inputs acceptable by the source state machines
	- Unions are used to combine paths that lead to the same states
	- ### DFA to regex
	  collapsed:: true
		- Start from initial state, and work your way to the final state
		- Write down every possible states reachable by the the current state
		- Simplify the regexes
		- Examples
			- {{renderer code_diagram,plantuml}}
			  collapsed:: true
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
			- We start from $q_1$
				- $q_1 = \Epsilon + q_2b + q_3a$
				- $q_2 = q_1a$
				- $q_3 = q_1b$
				- $q_4 = q_2a + q_3b + q_4a + q_4b$
			- We can now solve for $q_1$
				- $q_1 = \Epsilon + q_1ab + q_1ba$
				- $q_1 = E + q_1(ab + ba)$
				- Recall that $R = Q + RP = Q(P^\ast)$
				- $q_1 = \Epsilon(ab+ba)^\ast$
				- $q_1 = (ab+ba)^\ast$
	- ### NFA to regex
	  collapsed:: true
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
			- We start from $q_3$, and this gets us
				- $q_3 = q_2a$
				- $q_2 = q_1b + q_2b + q_3b$
				- $q_1 = \Epsilon + q_1a + q_2b$
			- Then we simplify (substitution)
				- $q_3 = q_1a + q_2ba + q_3ba$
				- $q_2 = q_1a + (b+ab)^\ast$
				- $q_1 = (a + a(b+ab)^\ast b)^\ast$
			- And finally, we solve for $q_3$
				- $q_3 = q_2a$
				- $q_3 = q_1a + (b+ab)^\ast$
				- $q_3 = (a+a(b+ab)^\ast )b^\ast a(b+ab)^\ast a$
	- ### DFA examples
	- ### NFA examples
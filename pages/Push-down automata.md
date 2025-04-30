tags:: Automata
> A machine using a push-down stack as unbounded memory

- # Definition $P = (Q, \Sigma, \Gamma, \delta, q_0, f)$
	- Alphabet $\Sigma$
	- Stack variable $\Gamma$
	- Transition function $\delta$
		- $Q \times \Sigma_{\epsilon}$
- # Comparison with [[Finite state automata]]
	- Unlike [[Finite state automata]], whose only knowledge is that *we got to this current state*, **a PDA knows more than FSA in that it also know its current state as well as how it got here**.
		- Since "transition history" is stored in the stack (pushed down)
	- FSA reads inputs from an input tape, then jumps and stores its current states
	- PDA reads inputs from an input tape, while also pushing the new input down into its own stack tape
	- In addition to just pushing the stack, PDA can also performs arbitrary operations on its current state (the top of the stack)
		- These operations are usually *read-remove* or *write-add*
	- PDA can only operate non-deterministically
- # PDA and [[Context-free grammar]]
	- The PDA tests whether a string is legal in a CFL
	- ## Examples
		- #### $L = \{0^k1^k \mid k \geq 0\}$
			- Note: [we saw this language in CFG](((65a18e03-1693-4786-8f40-949ecf0c8097)))
			- Then out PDA can be very simple
			- Read a $0$ from input -> push onto stack until read $1$
			- Read a $1$ from input -> pop $0$ off stack
			- At the end of input, if stack is empty -> input is valid
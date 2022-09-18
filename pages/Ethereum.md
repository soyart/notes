title:: Ethereum

- # Ethereum scaling #[[Ethereum]] #scaling
  title:: Ethereum #[[Ethereum]]
	- Its popularity has made Ethereum Mainnet slow and expensive. This is where scaling comes in.
	- There're 2 ways to scale Ethereum network; on-chain (L1) and off-chain (L2) scaling.
	- ## Ethereum L1 scaling #L1 #scaling
		- > L1 scaling happens on the Ethereum chain itself. After the switch to PoS (The Merge), _sharding_ has somewhat become the main method for L1 scaling.
		- ### Ethereum sharding
			- Sharding splits the database horizontally across all of the network nodes.
			- Sharding also reduces the amount of data a node has to process, **enabling small players to host their own nodes and preventing centralization of Ethereum network** by, say, AWS and other cloud service providers with powerful offering.
	- ## Ethereum L2 scaling #L2 #scaling #off-chain
		- > L2 scaling is done off-chain, and the resulting aggregated chain data (not Ethereum Mainnet!) can then be committed to Ethereum Mainnet, spreading the TX costs and improving network throughput.
		- ### L2 scaling little history
		  collapsed:: true
			- First came [[StateChannel]], which allows pre-agreed parties to transact among themselves.
			- Then anyone could transact ([[PlasmaChain]]), but there's chance of censorship due to [[PlasmaChainOperator]]
			- Finally, censorship is solved with [[RollUps]]
		- ### L2 scaling solutions
			- ### [Channels](https://ethereum.org/en/developers/docs/scaling/state-channels/) (State Channels and Payment Channels) #StateChannel
			  collapsed:: true
				- > TL;DR: Channels use multisig contracts to perform multiple operations off-chain, coming back and write to the root chain later
				- Channels are made possible via multisig contracts. It lets participants transact their funds off-chain multiple times, before committing the root chain.
				- Channels downsides are that __channels don't offer open partition__, that is, participants need to be known up front, and users'll have to lock their funds in the multisig contract. Each of the channel is also application-specific.
				- Channels are some of the fist scaling solution for blockchains, having been adopted within the Bitcoin environment. [Raiden](https://raiden.network/) provides channel scaling on Ethereum
			- ### [Plasma chains](https://ethereum.org/ph/developers/docs/scaling/plasma/) #PlasmaChain
			  collapsed:: true
				- Plasma chains assume that __NOT__ every single transaction needs to be verified on the root chains.
				- id:: 2ffae875-09f1-4c63-8f32-1ae6ed7d13d0
				  > A plasma chain is a separate, secondary blockchain that is also anchored to Ethereum chain. In this case, the Mainnet is the _root chain_, while the plasma chain is _child chain_.
				- Plasma chains are __NOT sidechains__. The sidechains runs and derive consensus independently of the root chain and only acts as bridges, and they are responsible for their own network security.
				- They usually have their own block validation schemes, and use [fraud-proof](https://ethereum.org/ph/developers/docs/scaling/plasma/) to handle disputes.
				- Plasma chains compute transactions off-chain, since Ethereum consensus mechanism requires that many P2P nodes verify the blocks, which in turn limits L1 scalability.
				- #### Plasma chain entries and exits
					- #### Entering a plasma chain #EnteringPlasma
						- 1. To move funds from Ethereum to the plasma chains,  __users have to first deposit their ETH or ERC-20 tokens on the plasma contract__.
						  2. The _plasma contract_ then recreates an equal amount of whatever was deposited and releases the funds to user's wallet on the plasma chain. #EnteringPlasma
					- #### Exiting from a plasma chain #ExitingPlasma #Withdraw
						- > Exiting from plasma chains to Ethereum is _more complex than entering_. This is because Ethereum does not know any information inside the plasma chain (we only have commitments on Ethereum, which is just a tree of hashes). So __Ethereum cannot verifies if the plasma chain information is true or not__. Below are withdrawal steps, __note that step 3-4 are mutually exclusive__, depending on plasma chain characteristics.
						- Due to the above limitations, a __withdrawal challenge period is started__ for every withdrawal request to prevent fraud.
						- Honest withdrawing users can __initiate withdrawal by sending a withdrawal request to the _plasma contract_ on the root chain__. They also need to __add bond__ to the withdrawal request as stake.
						- __During the challenge period (usually 1 week), anyone (_challengers_) can challenge and knock down suspicious withdrawals,__ and if the challenge succeeds, the withdrawal is denied.
						- If the challenger founds fraud, the withdrawal is denied, and the bond is slashed and transferred to the challenger as reward. __If the challenge period elapsed and there was no fraud-proof submitted, then the withdrawal is valid__.
						- #### Verification data needed for withdrawal from plasma chains
							- If the plasma chain uses [UTXO](https://en.wikipedia.org/wiki/Unspent_transaction_output), as with [Plasma MVP](https://www.learnplasma.org/en/learn/mvp.html) users also need to provide the Merkel proof of the TX from which their funds on plasma chain was created (from #EnteringPlasma ) and include the proof on the current block.
							- If the plasma chain represents funds as NFTs, as with [Plasma Cash](https://www.learnplasma.org/en/learn/cash.html), then the withdrawal requires proof of ownership of tokens on the Plasma chain. This is done  by submitting the two latest transactions involving the token and  providing a Merkle proof verifying the inclusion of those transactions in a block.
				- #### Plasma chain operator and commitments #PlasmaChainOperator
					- [_Operators_](https://docs.plasma.group/en/latest/src/plasma/operator.html) verify, manage the order of executions and TXs, and write the new states as  _commitments_ to the root chain.
					- Current plasma chains usually have one such operator, although decentralized plasma operators is feasible, but usually not done due to no clear benefits.
					- __This single operator does not compromise plasma chain integrity, although it's not censorship-proof__. The plasma chain history cannot be rewritten since the committed L2 states were already verified and stored on the robust root chain However, due to operators mostly being a single entity, __censorship may happen__.
					- Plasma chain operators can be decentralized and scaled, depending on the plasma chains.
					- Plasma chains are designed such that users can always withdraw their assets, i.e. when that one operator is compromised.
					- > __Commitments__ are plasma block data periodically written to the root chain. Plasma chains use its smart contract on the Mainnet (_plasma contract_) to prevent the operators from rewriting written blocks.
					- With plasma chains, commitments implement [commitment scheme](https://en.wikipedia.org/wiki/Commitment_scheme) in the form of Merkel roots (derived from [Merkel trees](https://ethereum.org/ph/whitepaper/#merkle-trees)) , called block roots.
					- Plasma commitments comprise of compressed data on the plasma chain organized into a Merkel root, i.e. a cryptographic state (hash) tree of the plasma chain states at specific points in time. This way, plasma chain commitments are a from of commitment scheme in that the 2 chains can verify their data without revealing real data.
			- ### Rollups (snark) #RollUps
			  collapsed:: true
				- > Rollups aggregate L2 data and wraps them all up (roll up) in a few transactions to be ultimately sent to root chain.
				- Rollups will be more useful as Ethereum moved to 2.0 and sharding. This is because rollups only need the data layer of Ethereum.
				- Most peeps within Ethereum community tends to view rollups as the main L2 scaling technique for Ethereum.
				- #### [ZK Rollups](https://ethereum.org/en/developers/docs/scaling/zk-rollups/) #ZKRollup
					- > Faster and more efficient than optimistic rollups, although it does not really help with migrating current smart contracts on the root chain to L2.
					- Examples are Loopring, DeversiFi, etc.
				- #### [Optimistic Rollups](https://ethereum.org/en/developers/docs/scaling/optimistic-rollups/) #OptimisticRollup
					- > The solution uses an EVM-compatible VM (_OVM_), which executes the same bytecode as Ethereum Mainnet. This means that the existing, battle-tested smart contracts can be migrated to L2.
					- Examples include [Optimism](https://community.optimism.io/docs/how-optimism-works/)
					- #### Optimistic Rollup Disputes
						- According to Optimism blog post, the main idea for optimistic rollups is always about disputes. To quote the blog: _If you think of Ethereum as an almighty, decentralized court, then the core insight of L2 scalability is: “don’t go to court to cash a check — just go if the check bounces.”_
			- ### [Sidechains](https://ethereum.org/en/developers/docs/scaling/sidechains/) #SideChain
			  collapsed:: true
				- > Sidechains are independent, EVM/Ethereum-compatible blockchains with their own consensus mechanism and block parameters. This means that almost no sidechain security is derived from Sidechains and Ethereum can talk. They can help scale Ethereum by moving the computations from Ethereum to the sidechains.
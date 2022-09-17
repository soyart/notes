title:: Ethereum

- # Ethereum scaling #[[Ethereum]] #scaling
  title:: Ethereum #[[Ethereum]]
- Its popularity has made Ethereum Mainnet slow and expensive. This is where scaling comes in.
- There're 2 ways to scale Ethereum network; on-chain (L1) and off-chain (L2) scaling.
## Ethereum L1 scaling #L1 #scaling
- L1 scaling happens on the Ethereum chain itself. After the switch to PoS (The Merge), _sharding_ has somewhat become the main method for L1 scaling.
### Ethereum sharding
- Sharding splits the database horizontally across all of the network nodes.
- Sharding also reduces the amount of data a node has to process, **enabling small players to host their own nodes and preventing centralization of Ethereum network** by, say, AWS and other cloud service providers with powerful offering.
## Ethereum L2 scaling #L2 #scaling #off-chain
- L2 scaling is done off-chain, and the resulting aggregated chain data (not Ethereum Mainnet!) can then be committed to Ethereum Mainnet, spreading the TX costs and improving network throughput.
- There're many ways to scale Ethereum on L2. The more common methods include using 
   __Plasma Chains__ #PlasmaChain, __Optimistic Rollups__, etc
## L2 scaling methods, in no particular order
### [Plasma chains](https://ethereum.org/ph/developers/docs/scaling/plasma/) #PlasmaChain
- Using plasma chains remain one of the most widely used L2 scaling. A plasma chain is a separate, secondary blockchain that is also anchored to Ethereum chain. In this case, the Mainnet is the _root chain_, while the L2 chain is called _child chain_.
- Plasma chains compute transactions off-chain, since Ethereum consensus mechanism requires that many P2P nodes verify the blocks, which in turn limits L1 scalability.
- They usually have their own block validation schemes, and use [fraud-proof](https://ethereum.org/ph/developers/docs/scaling/plasma/) to handle disputes.
- Plasma chains are __NOT__ sidechains. The sidechains runs and derive consensus independently of the root chain and only acts as bridges, and they are responsible for their own network security.
- Plasma chains assume that __NOT__ every single transaction needs to be verified on the root chains.
- #### Plasma chain operator and commitments #PlasmaChainOperator #Operator
- [_Operators_](https://docs.plasma.group/en/latest/src/plasma/operator.html) verify, manage the order of executions and TXs, and write the new states as  _commitments_ to the root chain.
- Current plasma chains usually have one such operator, although decentralized operators
- __This single operator does not compromise plasma chain integrity, although it's not censorship-proof__. The plasma chain history cannot be rewritten since the committed L2 states were already verified and stored on the robust root chain However, due to operators mostly being a single entity, __censorship may happen__.
- Plasma chain operators can be decentralized and scaled, depending on the plasma chains.
- Plasma chains are designed such that users can always withdraw their assets, i.e. when that one operator is compromised.
- __Commitments__ are L2 block data periodically written to the root chain. Plasma chains use its smart contract on the Mainnet (_plasma contract_) to prevent the operators from rewriting written blocks.
- With plasma chains, commitments implement [commitment scheme](https://en.wikipedia.org/wiki/Commitment_scheme) in the form of Merkel roots (derived from [Merkel trees](https://ethereum.org/ph/whitepaper/#merkle-trees)) , called block roots.
- Plasma commitments comprise of compressed data on the plasma chain organized into a Merkel root, i.e. a cryptographic state (hash) tree of the plasma chain states at specific points in time. This way, plasma chain commitments are a from of commitment scheme in that the 2 chains can verify their data without revealing real data.
- #### Plasma chain entries and exits
- LATER Entries and exits are portals through which users can move funds between a plasma chain and its root chain. This is usually done with a _master contract_, which also serves other functions.
  :LOGBOOK:
  CLOCK: [2022-09-18 Sun 01:03:26]--[2022-09-18 Sun 01:03:27] =>  00:00:01
  :END:
- Entering a plasma chain from Ethereum requires that the __users have to first deposit their ETH or ERC-20 tokens on the plasma contract__. The _plasma contract_ then recreates an equal amount of whatever was deposited and releases the funds to user's wallet on the plasma chain. #EnteringPlasma
- Exiting from plasma chains to Ethereum is _more complex than entering_. This is because Ethereum does not know any information inside the plasma chain (we only have commitments on Ethereum, which is just a tree of hashes). So __Ethereum cannot verifies if the plasma chain information is true or not__. Below are withdrawal steps, __note that step 3-4 are mutually exclusive__, depending on plasma chain characteristics.
- 1. To prevent fraud from plasma chain, a __withdrawal challenge period__ is used. During the period (usually 1 week), anyone can challenge the suspected withdrawals, and if the challenge succeeds, the withdrawal is denied. Withdrawer needs to __add bond__ to the withdrawal request. If the challenger founds fraud, the withdrawal is denied, and the bond is slashed and transferred to the challenger as reward. If the challenge period elapsed and there was no fraud-proof submitted, then the withdrawal is valid.
  3. If the withdrawals are honest and verified by the challenge, then users can create a withdrawal request to the _plasma contract_ on the root chain.
  4. If the plasma chain uses [UTXO](https://en.wikipedia.org/wiki/Unspent_transaction_output), as with [Plasma MVP](https://www.learnplasma.org/en/learn/mvp.html) users also need to provide the Merkel proof of the TX from which their funds on plasma chain was created (from #EnteringPlasma ) and include the proof on the current block.
  5. If the plasma chain represents funds as NFTs, as with [Plasma Cash](https://www.learnplasma.org/en/learn/cash.html), then the withdrawal requires proof of ownership of tokens on the Plasma chain. This is done  by submitting the two latest transactions involving the token and  providing a Merkle proof verifying the inclusion of those transactions in a block.
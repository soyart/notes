- # [[Cleverse Arbitrum Node]] + [[Cleverse Optimism Node]] (140.82.22.144)
- ## Host info
	- Purpose: [[Cleverse Arbitrum Node]] and [[Cleverse Optimism Node]]
	- Disks: 2 x 1.8T, RAID1, 1.8T total. Mounted at `/`.
- ## [[Cleverse Arbitrum Node]]
	- Run as [[Docker Container]] `node-nitro_arb-node_1`.
		- Connected to Docker network `node-nitro_default`
			- Subnet: `172.27.0.0/16`.
			- Container IP address: `172.27.0.2/16`.
			- Network gateway:  `172.27.0.1`.
		- Docker volumes: none. Data is bind mounted from `/root/.arbitrum` on the host to `/home/user/.arbitrum` on the container.
		- Host port mappings:
			- `0.0.0.0:8547-8548->8547-8548/tcp`
			- `:::8547-8548->8547-8548/tcp`
- ## [[Cleverse Optimism Node]]
	- Run as [[Docker Container]]s. See [project's `docker-compose.yml`](https://github.com/ethereum-optimism/optimism/blob/develop/ops/docker-compose.yml) to get basic idea
		- ### Services overview and dependencies
			- As per [[OptimismClient]], we need 2 explicit components running: (1) Optimism client (99% Geth) and (2) [[DTL]], __and we need L1 chain some where__.
				- 1. [Optimism client](https://github.com/ethereum-optimism/optimism/tree/develop/l2geth) is referred to as `l2geth` on the project monorepo Docker files.
					- `l2geth` depends on `l1chain`
					- `l2geth` depends on `deployer`
				- 2. [[DTL]] is referred to as `dtl` on the project monorepo Docker files.
					- `dtl` depends on `l1chain` to pull data from [[CTC]]
					- `dtl` depends on `deployer`
					- `dtl` depends on `l2geth`
				- 3. `deployer` is not mentioned in [How Optimism Works](https://community.optimism.io/docs/how-optimism-works/), but is required by other services.
					- `deployer` depends on `l1chain`
				- 4. `l1chain` can be Cleverse's Ethereum node `http://45.77.189.55:8545`, so, 3 containers in total (`l2geth`, `deployer`, `dtl`)
	- ## Optimism Containers
		- We can deploy Optimism node using [[Docker Image]] from [these repositories](https://hub.docker.com/u/ethereumoptimism), and there's a dedicated Docker repository for each component.
		- ### Networking
			- We will be using Docker network `optimism-net` and assign a host name to each service.
		- ### `deployer`
			- Image name `ethereumoptimism/deployer:latest`
			- #### Image info
				- ```
				  "Cmd": [
				  	"yarn",
				  	"run",
				  	"deploy"
				  ],
				  "ArgsEscaped": true,
				  "Image": "",
				  "Volumes": null,
				  "WorkingDir": "/opt/optimism/packages/contracts",
				  "Entrypoint": [
				  	"docker-entrypoint.sh"
				  ],
				  ```
			- #### Container configuration
				- __Networking__: Connected to `optimism-net` with hostname alias `deployer`.
				- __Ports__: 8080:8081 (HTTP)
				- __L1__: `deployer` too needs to talk to `l1chain` (Our Ethereum node):
					- `CONTRACTS_RCP_URL`: URL for our L1 node. So it is the address of our Ethereum node.
					- `CONTRACTS_DEPLOYER_KEY`: Private key of whatever node lives at `CONTRACT_RPC_URL`. Currently, this is __taken from our Ethereum node (file `/root/.ethereum/geth/nodekey`)__
		- ### `l2geth` (Optimism Client)
			- Image name `ethereumoptimism/l2geth:latest`
			- #### Image info
				- ```
				  "Cmd": null,
				  "Image": "",
				  "Volumes": null,
				  "WorkingDir": "/usr/local/bin/",
				  "Entrypoint": [
				  	"geth"
				  ],
				  ```
				- > But in the monorepo's `docker-compose.yml`, the service entrypoint is `./ops/scripts/geth.sh`.
			- #### Container configuration
				- __Networking__: Connected to `optimism-net` with hostname alias `l2geth`.
				- __Ports__: This container exposes `:8545/HTTP` and `:8546/WS` for Optimism endpoints.
				- __Volumes__: Volumes should mirror [[Cleverse Arbitrum Node]], so we will be using [[Bind Mount]] from `/root/.optimism` on the hos to `/root/.ethereum` inside the container. The destination path is taken from `$DATADIR` from `./ops/env/geth.env` files.
				- __L1__: This container must some how talk to our Ethereum node to interact with its L1 chain.
					- Container setting examples as ENVs in `./ops/env/geth.env`. You can also see example in the project's `./ops/docker-compose.yml`.
					- Overwrite any envs pointing to the supposed `l1chain` with `ETH1_HTTP` to use our existing Ethereum node. (We won't be deploying `l1chain`).
		- `dtl` ([[DTL]])
			- Image name `ethereum-optimism/data-transport-layer:latest`
			- #### Image info
				- ```
				  "Cmd": [
				  	"node",
				  	"dist/src/services/run.js"
				  ],
				  "ArgsEscaped": true,
				  "Image": "",
				  "Volumes": null,
				  "WorkingDir": "/opt/optimism/packages/data-transport-layer",
				  "Entrypoint": [
				  	"docker-entrypoint.sh"
				  ],
				  ```
			- #### Container configuration
				- __Networking__: Connected to `optimism-net` with hostname alias `dtl`
				- __Ports__: 7878:7878
				- __L1__: Overwrite variable `$DATA_TRANSPORT_LAYER_L1_ENDPOINT` to be our Ethereum node.
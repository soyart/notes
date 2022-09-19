- # [[Docker Compose]]
	- > [[Docker Compose]] is a stand-alone software tool enabling us to _compose_ our containerized environment in a YAML file `docker-compose.yaml` #docker-compose.yaml
	- ## [[docker-compose.yaml]]
	  collapsed:: true
		- ### [Basic composing/Boilerplate](https://docs.docker.com/get-started/08_using_compose/)
			- In this example we're going to compose a [[Multi Container Apps]], This _todo app_ is going to use 2 containers - __a MySQL service _AND_ a backend service__, with its own Docker network `todo-net`.
			- We want to use `docker-compose` to _bring everything up_ for us. Lego.
			- If our _app backend_ service was run like this ([[Running Docker Containers]]):
			  collapsed:: true
			  ```
			  $ docker run -dp 3000:3000 \
			    -w /app -v "$(pwd):/app" \
			    --network todo-net \
			    -e MYSQL_HOST=mysql \
			    -e MYSQL_USER=root \
			    -e MYSQL_PASSWORD=secret \
			    -e MYSQL_DB=todos \
			    node:12-alpine \
			    sh -c "yarn install && yarn run dev";
			  ```
				- Based on the command above
				  collapsed:: true
					- We know that the [[Docker Image]] is `node:12-alpine`.
					- And that the _command_ to be run is `sh -c 'yarn install && yarn run dev'`
					- And that [[Docker Port Mapping]] is `-p 3000:3000`
					- And that container working directory was also specified as `/app` from `-w /app`
					- And that there's [[Docker Volume]] of type [[Bind Mount]] from `$(pwd)` _on the host_ to `/app` _on  the container_ from `-v $(pwd):/app`
					- And that it's connected to network `todo-net`
					- And we know the environments from all the `-e <ENV>` flags
					- Now we are ready to compose a `docker-compose..yaml`!
			- 1. Specifying `docker-compose` version. This is usually the latest stable version. [See this guide for more info](https://docs.docker.com/compose/compose-file/)
			  ```
			  # docker-compose.yaml
			  version: "3.7"
			  ```
			- 2. Define our app container in the file, __which will be named `myapp`__. Note that the network `todo-net` is not specified yet.
			  ```
			  # docker-compose.yaml
			  version: "3.7"
			  services:
			  	myapp:
			      	image: 'node:12-alpine'
			          command: "sh -c 'yarn install && yarn run dev'"
			          ports:
			          	- "3000:3000"
			          working_dir: '/app'
			          volumes:
			          	- "./:/app"
			         environment:
			         		MYSQL_HOST: mysql
			              MYSQL_USER: root
			              MYSQL_PASSWORD: secret
			              MYSQL_DB: todos
			  ```
			- 3. Now let's have a look at the backend. Suppose it's run like this:
			  ```
			  $ docker run -d \
			    --network todo-net --network-alias mysql \
			    -v todo-mysql-data:/var/lib/mysql \
			    -e MYSQL_ROOT_PASSWORD=secret \
			    -e MYSQL_DATABASE=todos \
			    mysql:5.7
			  ```
				- Based on the command above, we know that
					- The [[Docker Image]] is `mysql:5.7`
					- And that the container is connected to network `todo-net` with hostname `mysql` (which matches the config environment for `myapp`)
					- And that there's a [[Docker Volume]] of type [[Named Docker Volume]] `todo-mysql-data` mounted to `/var/lib/mysql` in the container.
					- And we also know all the environments from `-e <ENV>` flags
			- 4. Now we can compose `mydb`, and finish off the file.
			  ```
			  # docker-compose.yaml
			  version: "3.7"
			  services:
			  	myapp:
			      	image: 'node:12-alpine'
			          command: "sh -c 'yarn install && yarn run dev'"
			          ports:
			          	- "3000:3000"
			          working_dir: '/app'
			          volumes:
			          	- "./:/app"
			         environment:
			         		MYSQL_HOST: mysql
			              MYSQL_USER: root
			              MYSQL_PASSWORD: secret
			              MYSQL_DB: todos
			  	mydb:
			      	image: 'mysql:5.7'
			          # Note docker-compose won't create named volumes automatically,
			          # So we have to include a top level 'volumes' key in this file.
			          volumes:
			          	- "todo-mysql-data:/var/lib/mysql"
			  		environment:
			          	MYSQL_ROOT_PASSWORD: secret
			              MYSQL_DATABASE: todos
			  
			  # We'll need to specify named volumes here
			  volumes:
			  	todo-mysql-data:
			  ```
	- ## Bringing up containers
		- CD to your [[docker-compose.yaml]], and Use `docker compose up -d [-f path/to/docker-compose.yml]` to bring up your containers.
		- You can supply `-e <ENV>` with `docker compose`, and that env variables will be used in [[docker-compose.yaml]].
		-
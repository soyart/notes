- # [Docker](https://docs.docker.com)
	- Docker is a containerization technology using [[Linux]] kernel's namespaces and cgroups.
	- ### [[Docker Image]]
		- A Docker image is a digital image file containing our layers of binaries.
		- An image is created using `docker build`.
		- [[Dockerfile]] is used to define steps to build a Docker image, i.e. to containerize your applications.
			- It may specify the base image, commands to run before copying our code, and the main command to run when the container starts (`CMD` directive)
		- ### Building Docker images #BuildingDockerImage
			- To _containerize_ a software project, write a [[Dockerfile]] for it first.
			- Then go into the project, and use `docker build` to build the container from our project:
				- ```
				  docker build -t myapp-img-name .
				  ```
				- The `.` at the end instructs `docker` to find `./Dockerfile`
		- ### Sharing built Docker images
			- We can push our images to [Docker Hub](https://hub.docker.io) with `docker push <namespace>`, but before we can push, we must properly tag the image first.
			- To be able to push to [Docker Hub](https://hub.docker.io), tag the image with your Docker Hub namespace (i.e. username or whatever):
				- ```
				  docker tag myapp-img-name artnoi43/myapp
				  docker push artnoi43/myapp
				  ```
					- This will tag existing local image `myapp-img-name` with namespace `artnoi43/myapp`, and push the image to Docker Hub at `artnoi43/myapp`
	- ### [[Docker Container]]
		- > When using CLI `docker`, the program uses either the container name or container ID as the namespaces for containers. I usually use container IDs, because it can be partial.
		- A Docker container is a _running_ image. It is a process on the host OS.
		- Users can run a container (i.e. _start_) from an image by using `docker run`, or `docker run -d` for _detached_ run.
		- To view running containers, use `docker ps`, or use `docker ps -a` to view all containers, running or not.
		- Users can use `docker stop`, and `docker rm`, to stop and remove the containers.
		- [__By default, nothing persists on the container__](https://docs.docker.com/get-started/05_persisting_data/). Every time we restart the container, we are starting from the same old image that we've built.
			- This is because the images are built as layers on layers, and they have _scratch space_ for creating/updating new files not originally in the containers.
			- To make data persist, use [[Docker Volume]].
	- ### [[Running Docker Containers]]
		- After [[BuildingDockerImage]], we can run the images as containers with `docker run`.
		- `docker run` also accepts a lot of arguments to control how our containers should run, like [[Docker Port Mapping]] and [[Docker Volume]]
		- Basic detached run with [[Docker Port Mapping]] should look something like:
			- ```
			  docker run -d -p 3000:3000 myapp-img-name;
			  docker run -dp 3000:3000 myapp-img-name;
			  ```
		- ### [[Docker Mounting]]
			- Mounting volumes is specified with `-v src:dst` flag.
			- [[Docker Mounting]] For [[Named Docker Volume]]:
				- ```
				  docker run -d -v myappvol:/data/myapp myapp-img-name;
				  ```
			- [[Docker Mounting]] For [[Bind Mount]]:
				- ```
				  docker run -v /var/data:/data myapp-img-name
				  ```
		- ### Setup [[Docker Container Networking]]
			- Networking is done with `--network` and `--network-alias`.
	- ## [[Docker Volume]]
		-
		- There 2 types of Docker volumes - [[Named Docker Volume]] and [[Bind Mount]]. Both types are mounted to our containers using the same `-v` flag.
		- Let's say our app `myapp` uses 1 SQLite database file at `/var/db/myapp/sqlite.db`, and we want that file to persist on the host and so persist between runs. Then we can mount these volumes according to [[Docker Mounting]]
		- To have that file persist, we'll need a Docker volume, and mount that volume to the target directory inside the container filesystem.
		- [[Named Docker Volume]]
			- [[Named Docker Volume]] is convenient in that __Docker tracks and manages [[Named Docker Volume]] location on the host for you__. You only need to remember the volume name.
			- [[Named Docker Volume]] is managed using `docker volume` subcommand.
			- Use `docker volume create <volume name>` to create named volume.
			  collapsed:: true
				- ```
				  docker volume create myapp-db;
				  ```
		- [[Bind Mount]]
			- [[Bind Mount]] gives us more control over [[Named Docker Volume]] by allowing us to control the host mountpoints, as with standard UNIX mounting.
	- ## [[Docker Container Networking]]
		- [[Docker Container Networking]] allows our containers on the same host to talk.
		- [[Docker Container Networking]] is controlled using `docker network` subcommand.
		  collapsed:: true
			- To create a new network, use `docker network create <network name>`:
				- ```
				  docker network create myapp-net;
				  ```
	- ## Multi container apps
		- It is preferred that a container only hosts one application. So if an app requires 3 moving parts (i.e. 3 programs - webserver, back-end server, and database), then we will spin up 3 containers to run that app.
		- Because multiple containers now need to talk to each other, we need something called [[Container Networking]].
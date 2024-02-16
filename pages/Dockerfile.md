- > [[Dockerfile]] is used to build a [[Docker Image]] from your files.
- See also: [Building Docker Image](https://docs.docker.com/engine/reference/builder/), [Dockerfile Best Practice](https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/) [[Docker Image]]
- # `docker build`
	- `docker build` can build [[Docker Image]] automatically by (1) reading instructions in [[Dockerfile]] and (2) reading [[Docker Context]], which is a set of files you're building container from.
	- In most cases, it’s best to start with an empty directory as context and keep your [[Dockerfile]] in that directory. Add only the files needed for building the [[Dockerfile]].
	- A [`.dockerignore`](https://docs.docker.com/engine/reference/builder/#dockerignore-file) can be used in the same fashion as with `.gitignore`
		- ```
		  # comment
		  */temp*   # Exclude files and directories whose names start with temp in any immediate subdirectory of the root. For example, the plain file /somedir/temporary.txt is excluded, as is the directory /somedir/temp.
		  */*/temp* # Exclude files and directories starting with temp from any subdirectory that is two levels below the root. For example, /somedir/subdir/temporary.txt is excluded.
		  temp?     # Exclude files and directories in the root directory whose names are a one-character extension of temp. For example, /tempa and /tempb are excluded.
		  ```
- # [[Dockerfile]]
	- ## How Docker parses [[Dockerfile]]
		- ### File path parsing
			- File paths are matched with `filepath.Match`.
			- File paths are cleaned with `filepath.Clean`, eliminating `.` and `..` in the path string with actual path.
			- Beyond `filepath.Match`, Docker also supports wildcard `**`, which matches any number of directories.
	- ## [[Dockerfile]] keys
		- ### `FROM`
			- ```
			  FROM [--platform=<platform>] <image> [AS <name>]
			  FROM [--platform=<platform>] <image>[:<tag>] [AS <name>]
			  FROM [--platform=<platform>] <image>[@<digest>] [AS <name>]
			  ```
			- `FROM` instruction inits new build stage and sets Base Image for this image.
			- [`ARG` is the only instruction that can precede `FROM`](https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact).
			- `FROM` can appear many times in the [[Dockerfile]] to create multiple images or use one build stage as dependency of others.
		- ### [`RUN`, `ENTRYPOINT`, and `CMD`](https://stackoverflow.com/questions/21553353/what-is-the-difference-between-cmd-and-entrypoint-in-a-dockerfile)
			- `RUN` is used to run commands during build, while `CMD` and `ENTRYPOINT` defines how our container will executes default commands and when we use `docker exec`.
			- ### `RUN`
				- `RUN` can appear in 2 forms; _shell_ form and _exec_ form. The _exec_ from __DOES NOT invoke container's shell__.
					- ```
					  RUN <command>
					  RUN ["executable", "param1", "param2"]
					  ```
					- The `exec` form will fail to expand $HOME to its value:
						- ```
						  RUN [ "echo", "$HOME" ] # FAIL
						  RUN [ "sh", "-c", "echo $HOME" ]
						  ```
				- The  `RUN`  instruction will execute any commands in a new layer on top of the
				  current image and commit the results. The resulting committed image will be
				  used for the next step in the  `Dockerfile`.
				- It is the container shell that manages environment variables in [[Dockerfile]], not Docker.
				- You can use __`docker build --no-cache`__ to tell Docker not to cache the current `RUN` command for next build.
			- ### `CMD`
				- `CMD` can appear in 3 forms, (1) _exec_, (2) _default_, and (3) _shell_ forms.
					- ```
					  CMD ["executable","param1","param2"] # exec form, preferred
					  CMD ["param1","param2"] # as default parameters to ENTRYPOINT
					  CMD command param1 param2 # shell form
					  ```
				- __There can be ONLY ONE `CMD` instruction in the whole [[Dockerfile]]__.
				- __The main purpose of a  `CMD`  is to provide defaults for an executing container.__ These defaults can include an executable, or they can omit the executable, in which case you must specify an  `ENTRYPOINT` instruction as well.
				- The _exec_ form __DOES NOT INVOKE SHELL__.
			- ### `ENTRYPOINT`
				- [[Docker Container]] has, by default, `/bin/sh -c` as "_entrypoint_".
				- This allows `CMD` and `RUN` to be run by the _default_ entrypoint, and these 2 are usually shell statement strings.
				- Later, users want custom entrypoint, hence the key `ENTRYPOINT` and flag `--entrypoint`
				- This allows us to use any program on the container as _entrypoint_, and strings `CMD` and `RUN` will be passed as argument to the entrypoint.
				- `ENTRYPOINT` has 2 forms, (1) _exec_ form, and (2) _shell_ form:
					- ```
					  ENTRYPOINT ["executable", "param1", "param2"] # Exec form
					  ENTRYPOINT "command" "param1" "param2" # Shell form
					  ```
		- ### `LABEL`
			- `LABEL` allows us to add key-value metadata for a [[Docker Image]].
			- [[Docker Image]] labels can be inspected with `docker image inspect <id or name>`
		- ### `EXPOSE`
			- `EXPOSE` doesn't actually do anything, although it serves more of a documentation function.
			- To actually publish container port, use `-p`. #[[Docker Port Mapping]].
		- ### `ENV`
			- `ENV` sets key-value for environment variables.
			- These values persist in to the containers.
			- If you don't want them to persist in the containers, use `ARG` instead:
				- ```
				  ARG DEBIAN_FRONTEND=noninteractive
				  RUN apt-get update && apt-get install -y ...
				  ```
				-
			- Or you can just declare it in-line when executing
				- ```
				  RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y ...
				  ```
		- ### `ADD` and `COPY`
			- Both commands are very similar, but `ADD` can untar and download files from URLs, while `COPY` can only allow local files. Their general syntax is very similar, but it's the more advanced features that make them different.
			- `ADD` copies files from the _build context_ to path in the image filesystem.
				- `dst` can be either (1) path relative to `WORKDIR`, or (2) absolute path.
				- `ADD` has 2 forms, and `src` and `dst` can contain wildcards:
					- ```
					  ADD [--chown=<user>:<group>] <src>... <dest>
					  ADD [--chown=<user>:<group>] ["<src>",... "<dest>"] # For path with whitespace
					  ```
				- All new files and directories are created with a UID and GID of 0, unless using `--chown` flag:
					- ```
					  ADD --chown=55:mygroup files* /somedir/
					  ADD --chown=bin files* /somedir/
					  ADD --chown=1 files* /somedir/
					  ADD --chown=10:11 files* /somedir/
					  ```
					- If usernames/group names are used, then the container's `/etc/passwd` is consulted to translate the names to GID/UID.
				- ### `ADD` rules and limitations
					- `src` can only be inside the build context. `../foo` is not allowed.
					- URL `src` must not end with trailing slash
					- If `src` is a certain types of tar archives, then it is extracted. __If the archive is from URL, it's not unpacked__.
					-
			- `ADD` and `COPY` can be used to create symlinks with `ADD/COPY --link src dst`.
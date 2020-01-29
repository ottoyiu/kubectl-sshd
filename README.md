# kubectl-sshd

A kubectl plugin that utilize dropbear to run a temporary SSH server on any Running Pod in your Kubernetes cluster. 

It can be useful to run a SSH server in an existing Pod to securely copy files off the Pod itself using scp or rsync, without having to re-deploy a Pod with a SSH sidecar.

The use of this plugin should eventually be deprecated in favour of Ephemeral Containers (alpha since Kubernetes v1.16):
https://kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/

## Caution
In most cases, using SSH to gain access to a Pod is considered an anti-pattern. 
Please consider using `kubectl exec` for executing commands and `kubectl cp` for copying files between a Pod and your local workstation.

## How
kubectl-sshd use kubectl to do the following to the desired Pod: 
- uploads a statically compiled dropbear binary
- uploads the `authorized_keys` file into the specified user `.ssh` directory
- symlinks scp to the dropbear binary to enable secure copy
- start up the dropbear SSH server on the port of your choice

## Acknowledgements
Special thanks (!!) to the projects that this plugin relies on:

| Project       | Description | License |
| ------------- | ------------| ------- |
| [dropbear SSH](https://matt.ucc.asn.au/dropbear/dropbear.html) | "Dropbear is a relatively small SSH server and client."  | MIT License  |
| [docker-dropbear-static](https://github.com/danielkza/docker-dropbear-static)  | "Minimal Docker image containing static Dropbear binaries with musl libc (built in Alpine Linux)." | MIT License  |
| [argbash](https://github.com/matejak/argbash/) | "Argbash is a code generator - write a short definition and let Argbash modify your script so it magically starts to expose a command-line interface to your users and arguments passed using this interface as variables." | 3-Clause BSD LICENSE - No license restriction on generated content

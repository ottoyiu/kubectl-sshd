# kubectl-sshd

A kubectl plugin that utilize dropbear to run a temporary SSH server on any Running Pod in your Kubernetes cluster. 

It can be useful to run a SSH server in an existing Pod to securely copy files off the Pod itself using scp or rsync, without having to re-deploy a Pod with a SSH sidecar.

The use of this plugin should eventually be deprecated in favour of Ephemeral Containers (alpha since Kubernetes v1.16):
https://kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/

## Caution
In most cases, using SSH to gain access to a Pod is considered an anti-pattern. 
Please consider using `kubectl exec` for executing commands and `kubectl cp` for copying files between a Pod and your local workstation.

## Getting Started
### Installation
The preferred way to install `kubectl-sshd` is through [krew](https://github.com/GoogleContainerTools/krew). 
After following the [krew installation](https://github.com/GoogleContainerTools/krew#installation), you can install `kubectl-sshd` by running:
```
kubectl krew install sshd
```

You could also run this plugin manually by checking out the code:
```
git clone git@github.com/ottoyiu/kubectl-sshd.git
cd kubectl-sshd
./bin/kubectl-sshd
```

### Usage
```
> kubectl sshd --help
kssh - Start a SSH server in any Pod
Usage: ./bin/kubectl-sshd [-l|--local-dropbear-path <arg>] [-r|--remote-dropbear-dir <arg>] [-R|--remote-scp-path <arg>] [-b|--bind-port <arg>] [-k|--authorized-keys-path <arg>] [-s|--ssh-path <arg>] [-n|--namespace <arg>] [-c|--(no-)cleanup] [-V|--(no-)verbose] [-h|--help] [-v|--version] <pod>
        <pod>: Pod name
        -l, --local-dropbear-path: Local Path to statically-built dropbear/SSH server binary (default: /static-dropbear) (no default)
        -r, --remote-dropbear-dir: Pod Path to upload dropbear/SSH server to (default: '/tmp')
        -R, --remote-scp-path: Pod Path for scp (default: '/bin/scp')
        -b, --bind-port: Pod Bind Port for dropbear/SSH server to (default: '22')
        -k, --authorized-keys-path: Public keys of those authorized to authenticate through SSH (default: 'id_rsa.pub')
        -s, --ssh-path: SSH Path Location, specify if authenticate using non-root user (default: '/root/.ssh')
        -n, --namespace: Pod Namespace (no default)
        -c, --cleanup, --no-cleanup: Cleanup all the files and dropbear binary before script exits (off by default)
        -V, --verbose, --no-verbose: Increase verbosity of script (off by default)
        -h, --help: Prints help
        -v, --version: Prints version
```

### Examples
Start an SSH server with a new key-pair:
```
> ssh-keygen -t rsa -N '' -f id_rsa
> kubectl sshd ${POD_NAME}
Payload binary does not exist at /tmp/dropbear. Uploading...
Payload uploaded to /tmp/dropbear!
Starting dropbear SSH server in local-test-0. It is now accessible on 192.168.1.251 (port 22)
[75] Jan 29 00:00:53 Not backgrounding
```

Then connect to it using any SSH client:
```
> ssh -i id_rsa root@192.168.1.251
# 
```

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
| [krew](https://github.com/kubernetes-sigs/krew) | "krew is a tool that makes it easy to use kubectl plugins." | Apache License 2.0 |

## Contributing
Thank you for your interest in contributing to this project! Feel free to open issues for feature requests, bugs, or any questions or concerns you may have. Pull Requests are always welcomed!

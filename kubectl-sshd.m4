#!/bin/bash

# m4_ignore(
echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
exit 11  #)Created by argbash-init v2.8.1
# ARG_POSITIONAL_SINGLE([pod], [Pod name], )
# ARG_OPTIONAL_SINGLE([local-dropbear-path], l, [Local Path to statically-built dropbear/SSH server binary (default: $SCRIPT_DIR/static-dropbear)], [])
# ARG_OPTIONAL_SINGLE([remote-dropbear-dir], r, [Pod Path to upload dropbear/SSH server to], [/tmp])
# ARG_OPTIONAL_SINGLE([remote-scp-path], R, [Pod Path for scp], [/bin/scp])
# ARG_OPTIONAL_SINGLE([bind-port], b, [Pod Bind Port for dropbear/SSH server to], [22])
# ARG_OPTIONAL_SINGLE([authorized-keys-path], k, [Public keys of those authorized to authenticate through SSH], [id_rsa.pub])
# ARG_OPTIONAL_SINGLE([ssh-path], s, [SSH Path Location, specify if authenticate using non-root user], [/root/.ssh])
# ARG_OPTIONAL_SINGLE([namespace], n, [Pod Namespace], [])
# ARG_OPTIONAL_BOOLEAN([cleanup], c, [Cleanup all the files and dropbear binary before script exits])
# ARG_OPTIONAL_BOOLEAN([verbose], V, [Increase verbosity of script])
# ARG_DEFAULTS_POS
# ARG_HELP([kssh - Start a SSH server in any Pod])
# ARG_VERSION([echo $0 v0.1])
# ARGBASH_SET_INDENT([  ])
# ARGBASH_GO

# [ <-- needed because of Argbash

# resolve actual directory where script resides
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

POD_NAME=$_arg_pod
SOURCE_PATH=$_arg_local_dropbear_path
PAYLOAD_DIR=$_arg_remote_dropbear_dir
PAYLOAD_PATH="${PAYLOAD_DIR}/dropbear"
REMOTE_SCP_PATH=$_arg_remote_scp_path
PORT=$_arg_bind_port
AUTHORIZED_KEYS_PATH=$_arg_authorized_keys_path
NAMESPACE=$_arg_namespace
SSH_PATH=$_arg_ssh_path

KUBECTL_CMD="kubectl"
AUTHORIZED_KEYS_DEST="${SSH_PATH}/authorized_keys"

if [ -z "$SOURCE_PATH" ];
then
    SOURCE_PATH="${SCRIPT_DIR}/static-dropbear"
fi

if [ ! -z "$NAMESPACE" ];
then
    KUBECTL_CMD="${KUBECTL_CMD} -n ${NAMESPACE}"
fi


copy_binary() {
    $KUBECTL_CMD exec $POD_NAME ls $PAYLOAD_PATH > /dev/null 2>&1
    if [ $? -ne 0 ]
    then
        echo "Payload binary does not exist at $PAYLOAD_PATH. Uploading..."
        $KUBECTL_CMD exec $POD_NAME -- mkdir -p $PAYLOAD_DIR
        if [ $? -ne 0 ]
        then
            echo "Payload DIR $PAYLOAD_DIR could not be created. Aborting."
            exit 1
        fi
        $KUBECTL_CMD cp $SOURCE_PATH $POD_NAME:$PAYLOAD_PATH
        if [ $? -eq 0 ]
        then
            echo "Payload uploaded to $PAYLOAD_PATH!"
            if [ ! -z "${REMOTE_SCP_PATH}" ]
            then
                echo "Setting up scp symlink $REMOTE_SCP_PATH -> $PAYLOAD_PATH"
                $KUBECTL_CMD exec $POD_NAME -- ln -s $PAYLOAD_PATH $REMOTE_SCP_PATH
                if [ $? -ne 0 ]
                then
                    echo "Failed to symlink scp $REMOTE_SCP_PATH -> $PAYLOAD_PATH. Ignoring."
                fi
            fi
        else
            echo "Payload failed to upload. Aborting."
            cat << EOF

=================================================================================================
To obtain a static dropbear binary, you can run the following commands (requires Docker and Make):
> git clone https://github.com/ottoyiu/kubectl-sshd.git
> cd kubectl-sshd
> make bin/static-dropbear
> cp bin/static-dropbear .
=================================================================================================
EOF
            exit 1
        fi
    fi
}
copy_keys() {
    set -e
    if [ ! -f "$AUTHORIZED_KEYS_PATH" ]; then
        echo "Authorized Keys Path, $AUTHORIZED_KEYS_PATH, does not exist. Aborting."
        echo "To generate a new keypair, run the following command: ssh-keygen -t rsa -N '' -f id_rsa"
        exit 2
    fi
    $KUBECTL_CMD exec $POD_NAME -- mkdir -p $SSH_PATH
    $KUBECTL_CMD cp $AUTHORIZED_KEYS_PATH $POD_NAME:$AUTHORIZED_KEYS_DEST
    $KUBECTL_CMD exec $POD_NAME -- chmod 0600 -R $SSH_PATH
    $KUBECTL_CMD exec $POD_NAME -- chown root:root -R $SSH_PATH
    set +e
}
start_ssh_server() {
    set -e
    POD_IP=$($KUBECTL_CMD get pods $POD_NAME -o jsonpath='{.status.podIP}')
    echo "Starting dropbear SSH server in $POD_NAME. It is now accessible on $POD_IP (port $PORT)"
    $KUBECTL_CMD exec $POD_NAME -- mkdir -p /etc/dropbear
    $KUBECTL_CMD exec -it $POD_NAME -- $PAYLOAD_PATH -RFEs -p $PORT
    set +e
}

cleanup() {
    set -e
    echo "Cleanup Enabled. Initiating Cleanup"
    $KUBECTL_CMD exec $POD_NAME -- rm $AUTHORIZED_KEYS_DEST
    $KUBECTL_CMD exec $POD_NAME -- rm -rf /etc/dropbear
    $KUBECTL_CMD exec $POD_NAME -- rm $PAYLOAD_PATH
    $KUBECTL_CMD exec $POD_NAME -- rm $REMOTE_SCP_PATH
    set +e
}

if [ "$_arg_verbose" = on ]
then
    set -x
fi

copy_binary
copy_keys
start_ssh_server

if [ "$_arg_cleanup" = on ]
then
    cleanup
fi

# ] <-- needed because of Argbash

# Riot RPL Udp Scenarios

A campaign executing multiple scenarios based on the RIOT operating system, M3 FIT IoT-Lab nodes, the RPL routing protocol.

## Directory Structure

The directory structure is the following:

- `src/scenarios/` contains the ansible playbook configuration for the different scenarios;
- `src/ansible/` contains the ansible playbook used to execute the experiments on the FIT IoT-Lab platform
- `src/scripts/` contains various scripts needed by the ansible playbooks;

## Usage

```
$ # The SSH_* variables are used to connect to some external server and stream the experimental data as the available space on the FIT IoT-Lab frontend server is limited
$ export SSH_PORT="22"
$ export SSH_USER="myusername"
$ export SSH_HOST="myserver.tld"
$ export SSH_PRIVATE_KEY="stream_server_private_key"
$ # The FITIOT_* variables are used to connect to the FIT IoT-Lab frontend server. The FITIOT_KEY is the base64 encoded SSH key.
$ export FITIOT_KEY="frontend_server_private_key_base64_encoded"
$ export FITIOT_USER="myuseronfitiotlab"
$ nix build
[2 built, 137 copied (530.3 MiB), 117.3 MiB DL]

$ ./result/run
[…]
```
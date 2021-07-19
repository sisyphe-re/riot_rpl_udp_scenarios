# Riot RPL Udp Scenarios

A campaign executing multiple scenarios based on the RIOT operating system, M3 FIT IoT-Lab nodes, the RPL routing protocol.

## Directory Structure

The directory structure is the following:

- `src/ansible/` contains the ansible playbook used to execute the experiments on the FIT IoT-Lab platform and the scenario definitions;
- `src/scripts/` contains various scripts needed by the ansible playbooks.

## Build

In order to build the project, use [Nix](https://nixos.org/) and run ```nix build```.

## Setup

In order to run the experiments, a few environment variables are needed:

### Campaign-specific Environment Variables

- FITIOT_USER: User to use to connect to the FIT IoT-Lab frontend servers
- FITIOT_PRIVATE_KEY: base64 encoded SSH private key to use to connect to the FIT IoT-Lab frontend servers
- FITIOT_PUBLIC_KEY: base64 encoded SSH public key to use to connect to the FIT IoT-Lab frontend servers

### Sisyphe Environment Variables

- SSH_PORT: Port used by the SSH service running on the server receiving experimental data
- SSH_USER: User to use to connect to the server receiving experimental data using SSH
- SSH_HOST: Hostname of the server receiving experimental data
- SSH_PATH: Path where the data will be copied on the server receiving experimental data
- SSH_PRIVATE_KEY: SSH private key to use to connect to the server receiving experimental data
- SSH_PUBLIC_KEY: SSH public key to use to connect to the server receiving experimental data

## Testing

After having built the project and exported the needed environment variables, you can make a test run of the project by executing:

```
$ ./result/run
```

To run specific scenarios, edit the `flake.nix` file and replace `${./src/ansible/Test.yml}` by the scenario you want, e.g. `${./src/ansible/VoIP.yml}`.
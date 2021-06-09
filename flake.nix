{
  description = "A flake for setting up an experiment on FIT IoT-Lab";
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-20.09;
  inputs.firmwares.url = github:sisyphe-re/firmwares;

  outputs = { self, nixpkgs, firmwares }:
    with import nixpkgs { system = "x86_64-linux"; };
    let
      run_script = pkgs.writeScriptBin "run" ''
        #!${bash}/bin/bash

        if [ -z ''${FITIOT_USER+x} ]; then echo "FITIOT_USER is unset."; exit 1; else echo "FITIOT_USER is set to '$FITIOT_USER'."; fi
        if [ -z ''${FITIOT_KEY+x} ]; then echo "FITIOT_KEY is unset."; exit 1; else echo "FITIOT_KEY is set."; fi

        if [ -z ''${STREAM_USER+x} ]; then echo "STREAM_USER is unset."; exit 1; else echo "STREAM_USER is set to '$STREAM_USER'."; fi
        if [ -z ''${STREAM_HOST+x} ]; then echo "STREAM_HOST is unset."; exit 1; else echo "STREAM_HOST is set to '$STREAM_HOST'."; fi
        if [ -z ''${STREAM_PATH+x} ]; then echo "STREAM_PATH is unset."; exit 1; else echo "STREAM_PATH is set to '$STREAM_PATH'."; fi
        if [ -z ''${STREAM_KEY+x} ]; then echo "STREAM_KEY is unset."; exit 1; else echo "STREAM_KEY is set."; fi

        export BASE_EXPERIMENT="${./src/ansible/experiment.yml}";
        export SCRIPTS_PATH="${./src/scripts}";

        mkdir -p ~/.ssh/
        echo ''${FITIOT_KEY} | base64 -d &> ~/.ssh/id_fitiot
        chmod 600 ~/.ssh/id_fitiot

        echo "HOME is ''${HOME}"

        for site in {paris,grenoble,saclay,strasbourg,lyon,lille};
        do
            ${openssh}/bin/ssh-keyscan -t rsa ''${site}.iot-lab.info >> ~/.ssh/known_hosts;
        done

        echo "Trying to run uptime on the server"
        ${openssh}/bin/ssh -o UserKnownHostsFile=~/.ssh/known_hosts -o StrictHostKeyChecking=no -i ~/.ssh/id_fitiot grunblat@paris.iot-lab.info uptime

        echo "Running ansible-playbook"
        ${ansible}/bin/ansible-playbook -i ${./hosts} ${./src/ansible/Test.yml} --extra-vars "ansible_user=''${FITIOT_USER} ansible_ssh_private_key_file=''${HOME}/.ssh/id_fitiot ansible_ssh_extra_args=\"-o UserKnownHostsFile=''${HOME}/.ssh/known_hosts\""
      '';
    in
    {
      packages.x86_64-linux.scripts =
        stdenv.mkDerivation {
          src = self;
          name = "scripts";
          buildInputs = [
            run_script
          ];
          installPhase = ''
            mkdir $out;
            cp ${run_script}/bin/run $out;
          '';
        };
      defaultPackage.x86_64-linux = self.packages.x86_64-linux.scripts;
    };
}

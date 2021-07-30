{
  description = "A flake for setting up an experiment on FIT IoT-Lab";
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-21.05;
  inputs.firmwares.url = github:sisyphe-re/firmwares;
  inputs.moulinette.url = github:sisyphe-re/moulinette;

  outputs = { self, nixpkgs, firmwares, moulinette }:
    with import nixpkgs { system = "x86_64-linux"; };
    let
      run_script = pkgs.writeScriptBin "run" ''
        #!${bash}/bin/bash

        if [ -z ''${FITIOT_USER+x} ]; then echo "FITIOT_USER is unset."; exit 1; else echo "FITIOT_USER is set to '$FITIOT_USER'."; fi
        if [ -z ''${FITIOT_PRIVATE_KEY+x} ]; then echo "FITIOT_PRIVATE_KEY is unset."; exit 1; else echo "FITIOT_PRIVATE_KEY is set."; fi
        if [ -z ''${FITIOT_PUBLIC_KEY+x} ]; then echo "FITIOT_PUBLIC_KEY is unset."; exit 1; else echo "FITIOT_PUBLIC_KEY is set."; fi

        if [ -z ''${SSH_PORT+x} ]; then echo "SSH_PORT is unset."; exit 1; else echo "SSH_PORT is set to '$SSH_PORT'."; fi
        if [ -z ''${SSH_USER+x} ]; then echo "SSH_USER is unset."; exit 1; else echo "SSH_USER is set to '$SSH_USER'."; fi
        if [ -z ''${SSH_HOST+x} ]; then echo "SSH_HOST is unset."; exit 1; else echo "SSH_HOST is set to '$SSH_HOST'."; fi
        if [ -z ''${SSH_PATH+x} ]; then echo "SSH_PATH is unset."; exit 1; else echo "SSH_PATH is set to '$SSH_PATH'."; fi
        if [ -z ''${SSH_PRIVATE_KEY+x} ]; then echo "SSH_PRIVATE_KEY is unset."; exit 1; else echo "SSH_PRIVATE_KEY is set."; fi
        if [ -z ''${SSH_PUBLIC_KEY+x} ]; then echo "SSH_PUBLIC_KEY is unset."; exit 1; else echo "SSH_PUBLIC_KEY is set."; fi

        export BASE_EXPERIMENT="${./src/ansible/experiment.yml}";
        export SCRIPTS_PATH="${./src/scripts}";
        export FIRMWARES="${firmwares.packages.x86_64-linux.all-the-firmwares}";

        mkdir -p ~/.ssh/
        echo "''${FITIOT_PRIVATE_KEY}" | base64 -d &> ~/.ssh/id_fitiot
        echo "''${FITIOT_PUBLIC_KEY}" | base64 -d &> ~/.ssh/id_fitiot.pub
        chmod 600 ~/.ssh/id_fitiot
        echo "HOME is ''${HOME}"

        for site in {paris,grenoble,saclay,strasbourg,lyon,lille};
        do
            ${openssh}/bin/ssh-keyscan -t rsa ''${site}.iot-lab.info >> ~/.ssh/known_hosts;
        done

        echo "Trying to run uptime on the server"
        ${openssh}/bin/ssh -v -o UserKnownHostsFile=~/.ssh/known_hosts -o StrictHostKeyChecking=no -i ~/.ssh/id_fitiot grunblat@paris.iot-lab.info uptime

        echo "Running ansible-playbook"
        ${ansible}/bin/ansible-playbook -i ${./hosts} ${./src/ansible/sisyphe.yml} --extra-vars "ansible_user=''${FITIOT_USER} ansible_ssh_private_key_file=''${HOME}/.ssh/id_fitiot ansible_ssh_extra_args=\"-o UserKnownHostsFile=''${HOME}/.ssh/known_hosts\""
      '';
      finalize_script = pkgs.writeScriptBin "finalize" ''
        #!${bash}/bin/bash

        if [ -z ''${SSH_PATH+x} ]; then echo "SSH_PATH is unset."; exit 1; else echo "SSH_PATH is set to '$SSH_PATH'."; fi

        EXP_ID=$(ls ''${SSH_PATH}/*.zst| head -n 1 | sed -e s/[^0-9]//g)
        if [ -z ''${EXP_ID} ]; then echo "EXP_ID is unset."; exit 1; else echo "EXP_ID is set to '$EXP_ID'."; fi

        # Convert the output to a sqlite3 database
        ${moulinette.packages.x86_64-linux.moulinette}/bin/moulinette ''${EXP_ID}.db3 ''${SSH_PATH}/''${EXP_ID}-serial_output.zst ''${SSH_PATH}/''${EXP_ID}-server_output.zst;
        
        # Generate some plots
        ${./src/plot.py} ''${EXP_ID}.db3 ''${SSH_PATH}

        # Compress the database and cleanup
        ${zstd}/bin/zstd -T0 -19 ''${EXP_ID}.db3
        cp ''${EXP_ID}.db3.zst ''${SSH_PATH}
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
            cp ${finalize_script}/bin/finalize $out;
          '';
        };
      defaultPackage.x86_64-linux = self.packages.x86_64-linux.scripts;
    };
}

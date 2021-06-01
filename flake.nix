{
  description = "A flake for setting up an experiment on FIT IoT-Lab";
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-20.09;
  inputs.firmwares.url = github:sisyphe-re/firmwares;

  outputs = { self, nixpkgs, firmwares }:
    with import nixpkgs { system = "x86_64-linux"; };
    let
      configure_script = pkgs.writeScriptBin "configure" ''
        #!${bash}/bin/bash
        echo "Configure Phase.";
      '';
      build_script = pkgs.writeScriptBin "build" ''
        #!${bash}/bin/bash
        echo "Build Phase.";
      '';
      run_script = pkgs.writeScriptBin "run" ''
        #!${bash}/bin/bash
        echo "Home is $HOME";
        export BASE_EXPERIMENT="${./src/ansible/experiment.yml}";
        export SCRIPTS_PATH="${./src/scripts}";
        echo "Trying to run uptime on the server"
        ${openssh}/bin/ssh -o UserKnownHostsFile=~/.ssh/known_hosts -o StrictHostKeyChecking=no -i ~/.ssh/id_fitiot grunblat@paris.iot-lab.info uptime
        echo "Showing the key"
        cat /run/riot_udp/.ssh/id_fitiot
        echo "Running ansible-playbook"
        ${ansible}/bin/ansible-playbook -i ${./hosts} ${./src/ansible/Test.yml}
      '';
    in
    {
      packages.x86_64-linux.scripts =
        stdenv.mkDerivation {
          src = self;
          name = "scripts";
          buildInputs = [
            configure_script
            build_script
            run_script
          ];
          installPhase = ''
            mkdir $out;
            cp ${configure_script}/bin/configure $out;
            cp ${build_script}/bin/build $out;
            cp ${run_script}/bin/run $out;
          '';
        };
      defaultPackage.x86_64-linux = self.packages.x86_64-linux.scripts;
    };
}

{
  description = "Development shell for AstroSmol and the Smoldyn GPU build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
          };
        };

        python = pkgs.python314 or pkgs.python313;
        cudaPackages = pkgs.cudaPackages;
      in
      {
        devShells.default = pkgs.mkShell {
          name = "smoldyn-gpu-ip3r-dev";

          packages = with pkgs; [
            python
            uv

            cmake
            ninja
            pkg-config
            gcc
            gdb
            valgrind

            cudaPackages.cuda_nvcc
            cudaPackages.cudatoolkit
            cudaPackages.cuda_cudart
            cudaPackages.cuda_gdb

            libGL
            libGLU
            freeglut
            glew
            zlib
            libpng
            boost

            docker
            docker-compose
            podman
            podman-compose
            nvidia-container-toolkit

            pciutils
            usbutils
            lshw
            mesa-demos
            vulkan-tools
            clinfo
            linuxPackages.nvidia_x11
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            pkgs.libGL
            pkgs.libGLU
            pkgs.freeglut
            pkgs.glew
            pkgs.zlib
            pkgs.libpng
            cudaPackages.cuda_cudart
            cudaPackages.cudatoolkit
            pkgs.linuxPackages.nvidia_x11
          ];

          CUDA_PATH = cudaPackages.cudatoolkit;
          CUDA_HOME = cudaPackages.cudatoolkit;
          CMAKE_CUDA_COMPILER = "${cudaPackages.cuda_nvcc}/bin/nvcc";

          shellHook = ''
            export UV_PROJECT="$PWD/AstroSmol"
            export ASTROSMOL_ROOT="$PWD/AstroSmol"
            export SMOLDYN_GPU_ROOT="$PWD/smoldyn-gpu-gladkov"
            export ASTROSMOL_SMOLDYN_GPU="$SMOLDYN_GPU_ROOT/build/SmoldynGPU"
            export LD_LIBRARY_PATH="/run/opengl-driver/lib:/run/opengl-driver-32/lib:$LD_LIBRARY_PATH"
            export PATH="/run/opengl-driver/bin:$PATH"

            alias gpu-info='nvidia-smi && nvcc --version'
            alias astrosmol-sync='cd "$ASTROSMOL_ROOT" && uv sync --python ${python.interpreter}'
            alias astrosmol='cd "$ASTROSMOL_ROOT" && uv run'
            alias build-smoldyn-gpu='cmake -S "$SMOLDYN_GPU_ROOT" -B "$SMOLDYN_GPU_ROOT/build" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_CUDA_ARCHITECTURES=''${CUDA_ARCH:-native} && cmake --build "$SMOLDYN_GPU_ROOT/build"'

            echo "Smoldyn GPU dev shell"
            echo "Python: $(python --version 2>&1)"
            echo "uv: $(uv --version 2>&1)"
            echo "GPU check: run gpu-info"
            echo "Build GPU binary: build-smoldyn-gpu"
            echo "AstroSmol uv env: astrosmol-sync"
          '';
        };
      }
    );
}

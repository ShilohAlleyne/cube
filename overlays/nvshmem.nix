{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
    pname = "nvshmem";
    version = "3.4.5"; # match the version that provides libnvshmem_host.so.3

    src = pkgs.fetchurl {
        url = "https://github.com/NVIDIA/nvshmem/releases/download/v3.4.5/nvshmem_src_3.4.5.tar.gz";
        sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # fill this in after first fetch
    };

    nativeBuildInputs = [ pkgs.cmake pkgs.cudaPackages.cuda_cudart pkgs.gcc ];
    buildInputs = [
        pkgs.mpi
        pkgs.libfabric
        pkgs.ucx
        pkgs.pmix
        pkgs.rdma-core
    ];

    installPhase = ''
        mkdir -p $out/lib
        cp lib/libnvshmem_host.so.3 $out/lib/
        cp -r include $out/include
    '';
}

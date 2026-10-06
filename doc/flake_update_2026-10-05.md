chouette@nix01:~/NixOS-nix01$ nix flake update
warning: updating lock file "/home/chouette/NixOS-nix01/flake.lock":
• Updated input 'home-manager':
    'github:nix-community/home-manager/09ae1b85a6db412d841d60f924b23f881f0d0a38?narHash=sha256-hftabkb%2B73OcGzvwFAjCiQorAhprs9TnU1%2BFkGO5CIw%3D' (2026-08-17)
  → 'github:nix-community/home-manager/db7d5e2332710f5abb088f6b5de927d7f9511b35?narHash=sha256-f%2BkOxEmOUnQazVAmGg0i8hzwgd1kX/geY%2Bk/Dpheye8%3D' (2026-10-03)
• Updated input 'nixpkgs':
    'github:NixOS/nixpkgs/0dd31db7e6dbf9ce05697c4545f6fe01accec994?narHash=sha256-b4qgjdFtlz5TAZ1Hi7DFJeqX3sjaDUnrwr9OO%2BO1rM0%3D' (2026-08-17)
  → 'github:NixOS/nixpkgs/825e2028c29b702a4a5f085f08095d12099784f2?narHash=sha256-/FGDr01siZ8txrVzkOz6CYjiz0XR27JuVJP%2BaWchi4s%3D' (2026-10-03)
• Updated input 'nixvim':
    'github:nix-community/nixvim/8704f5ec5b2c500720fc65197e4edd49414b31a4?narHash=sha256-YoR5OFSUk5F/K1xWikfPcd27bSAt8x5ZVAqBZ/khEys%3D' (2026-08-17)
  → 'github:nix-community/nixvim/1cdfef1a6eb583d65b606b04fc97687491479d62?narHash=sha256-EeMn6SmrBe4gnxaMyb3NZYMXG8FPF9PY0OCcbPDFFNI%3D' (2026-10-02)
• Updated input 'nixvim/flake-parts':
    'github:hercules-ci/flake-parts/427bf4bd9435fdf21321c8cc628c24efc14c0f7a?narHash=sha256-4dtXQk/NMePegK/nWp5NSeuZKLATItOq61lpEvmXqGw%3D' (2026-08-01)
  → 'github:hercules-ci/flake-parts/31729ca8cbdb4fa927b34e5f4353e6a83f39e993?narHash=sha256-glZLQlzIn1fXH6PazR2iUmTo7kzzyYSshrWhLS9TqCU%3D' (2026-09-03)
• Updated input 'sops-nix':
    'github:Mic92/sops-nix/a8627b21b9107c5711c96b84f32a9a4b3d45295f?narHash=sha256-gkig4nPi1CWc4Z50GBsjE4ygSE7hMpl/TwID2an2Cck%3D' (2026-08-13)
  → 'github:Mic92/sops-nix/dcd241ba97088c22569d1573286e1b9daad340c0?narHash=sha256-nFxM%2BpKoZ8LJAEnUXARyCaOAloWgaW9kZQOSjWzKcTE%3D' (2026-10-04)
chouette@nix01:~/NixOS-nix01$  mkdir docs
chouette@nix01:~/NixOS-nix01$ vi docs/flake_update_2026-10-05.md
chouette@nix01:~/NixOS-nix01$ ./build nix01
-bash: ./build: そのようなファイルやディレクトリはありません
chouette@nix01:~/NixOS-nix01$ ./build.sh nix01
Building for nix01...
[sudo] chouette のパスワード:
warning: Git tree '/home/chouette/NixOS-nix01' is dirty
building the system configuration...
warning: Git tree '/home/chouette/NixOS-nix01' is dirty
Checking switch inhibitors... done
updating GRUB 2 menu...
installing the GRUB 2 boot loader on /dev/vda...
Installing for i386-pc platform.
Installation finished. No error reported.
stopping the following units: dschat.service, kmod-static-nodes.service, logrotate-checkconf.service, mysql.service, nfs-idmapd.service, nfs-mountd.service, nfs-server.service, nfsdcld.service, nscd.service, rpc-statd-notify.service, rpc-statd.service, rpcbind.service, rpcbind.socket, ssh-tunnel-kagoya.service, systemd-modules-load.service, systemd-networkd-wait-online.service, systemd-oomd.service, systemd-oomd.socket, systemd-sysctl.service, systemd-timesyncd.service, systemd-tmpfiles-resetup.service, systemd-vconsole-setup.service
NOT restarting the following changed units: getty@tty1.service, post-boot.service, systemd-journal-flush.service, systemd-logind.service, systemd-random-seed.service, systemd-remount-fs.service, systemd-update-utmp.service, systemd-user-sessions.service, systemd-zram-setup@zram0.service, user-runtime-dir@1001.service, user@1001.service
activating the configuration...
setting up /etc...
restarting systemd...
reloading user units for chouette...
NOT restarting the following user units: systemd-tmpfiles-setup.service
restarting the following user units: nixos-activation.service
restarting sysinit-reactivation.target
reloading the following units: dbus-broker.service, nftables.service, reload-systemd-vconsole-setup.service
restarting the following units: home-manager-chouette.service, nix-daemon.service, sshd.service, systemd-journald.service, systemd-networkd.service, systemd-udevd.service
starting the following units: dschat.service, kmod-static-nodes.service, logrotate-checkconf.service, mysql.service, nfs-idmapd.service, nfs-mountd.service, nfs-server.service, nfsdcld.service, nscd.service, rpc-statd-notify.service, rpc-statd.service, rpcbind.socket, ssh-tunnel-kagoya.service, systemd-modules-load.service, systemd-networkd-wait-online.service, systemd-oomd.socket, systemd-sysctl.service, systemd-timesyncd.service, systemd-tmpfiles-resetup.service, systemd-vconsole-setup.service
the following new units were started: dev-disk-by\x2dpartlabel-primary.swap
Done. The new configuration is /nix/store/f1gwjxbcpjl73km6zl6qk1blb9sxy49p-nixos-system-nix01-26.05.20261003.825e202
chouette@nix01:~/NixOS-nix01$ go version
go version go1.26.7 linux/amd64
chouette@nix01:~/NixOS-nix01$ 


chouette@nix01:~/NixOS-nix01$ nix-shell -p nh

[nix-shell:~/NixOS-nix01]$ nh os info
NixOS 26.05.20261003.825e202
Generation No Build Date           NixOS Version          Kernel  Closure Size
39 (current) 2026-10-05 13:42:15  26.05.20261003.825e202 6.18.55 3.6 GB      
38           2026-10-04 18:19:53  26.05.20260817.0dd31db 6.18.44 3.5 GB      
37           2026-10-04 11:38:53  26.05.20260817.0dd31db 6.18.44 3.2 GB      
36           2026-10-04 12:02:12  26.05.20260817.0dd31db 6.18.44 3.2 GB      
35           2026-10-04 11:38:53  26.05.20260817.0dd31db 6.18.44 3.2 GB      
34           2026-09-30 10:59:31  26.05.20260817.0dd31db 6.18.44 3.2 GB      
33           2026-09-28 12:11:24  26.05.20260817.0dd31db 6.18.44 3.3 GB      
32           2026-09-27 14:33:14  26.05.20260817.0dd31db 6.18.44 3.3 GB      
31           2026-08-28 13:29:28  26.05.20260817.0dd31db 6.18.44 3.3 GB      
30           2026-08-23 16:39:13  26.05.20260817.0dd31db 6.18.44 3.3 GB      
29           2026-08-23 14:43:33  26.05.20260817.0dd31db 6.18.44 3.3 GB      
28           2026-08-23 13:52:38  26.05.20260817.0dd31db 6.18.44 3.3 GB      
27           2026-08-23 08:33:08  26.05.20260817.0dd31db 6.18.44 3.3 GB      
26           2026-08-23 08:26:34  26.05.20260817.0dd31db 6.18.44 3.3 GB      
25           2026-08-23 08:22:22  26.05.20260817.0dd31db 6.18.44 3.3 GB      
24           2026-08-23 08:06:46  26.05.20260817.0dd31db 6.18.44 3.3 GB      
23           2026-08-22 23:42:07  26.05.20260817.0dd31db 6.18.44 3.3 GB      
22           2026-08-22 23:32:44  26.05.20260817.0dd31db 6.18.44 3.3 GB      
21           2026-08-22 23:21:11  26.05.20260817.0dd31db 6.18.44 3.3 GB      
20           2026-08-22 23:14:31  26.05.20260817.0dd31db 6.18.44 3.3 GB      
19           2026-08-22 23:11:20  26.05.20260817.0dd31db 6.18.44 3.3 GB      
18           2026-08-22 15:19:35  26.05.20260817.0dd31db 6.18.44 3.3 GB      
17           2026-08-21 20:02:29  26.05.20260817.0dd31db 6.18.44 3.3 GB      
16           2026-08-21 20:20:23  26.05.20260817.0dd31db 6.18.44 3.2 GB      
15           2026-08-21 20:02:29  26.05.20260817.0dd31db 6.18.44 3.3 GB      
14           2026-08-21 16:23:34  26.05.20260817.0dd31db 6.18.44 3.3 GB      
13           2026-08-21 20:02:29  26.05.20260817.0dd31db 6.18.44 3.3 GB      
12           2026-08-21 16:23:34  26.05.20260817.0dd31db 6.18.44 3.3 GB      
11           2026-08-21 15:13:47  26.05.20260817.0dd31db 6.18.44 3.3 GB      
10           2026-08-21 15:07:27  26.05.20260817.0dd31db 6.18.44 3.3 GB      
9            2026-08-19 14:20:15  26.05.20260817.0dd31db 6.18.44 3.3 GB      
8            2026-08-19 14:13:54  26.05.20260817.0dd31db 6.18.44 3.3 GB      
7            2026-08-19 14:11:10  26.05.20260817.0dd31db 6.18.44 3.3 GB      
6            2026-08-19 09:38:31  26.05.20260817.0dd31db 6.18.44 3.2 GB      
5            2026-08-19 09:22:39  26.05.20260817.0dd31db 6.18.44 3.2 GB      
4            2026-08-19 08:07:01  26.05.20260817.0dd31db 6.18.44 3.2 GB      
3            2026-08-19 07:19:49  26.05.20260817.0dd31db 6.18.44 3.2 GB      
2            2026-08-19 00:10:27  26.05.20260817.0dd31db 6.18.44 3.2 GB      
1            2026-08-18 23:40:42  26.05.20260817.0dd31db 6.18.44 3.2 GB      

[nix-shell:~/NixOS-nix01]$ 


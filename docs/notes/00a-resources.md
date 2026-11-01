# Замеры ресурсов 2026-11-01

```
=== racct/rctl support:
1
options	RCTL
options	RACCT_DEFAULT_TO_DISABLED
options	RACCT
/usr/bin/rctl
=== loader.conf racct:
/boot/loader.conf:kern.racct.enable="1"
none
=== memory:
physmem: 15.7 GB
108664	329203
4096
=== swap:
Device          1K-blocks     Used    Avail Capacity
=== top RSS (KB):
1225668 134.0 bhyve
1121236   1.6 qbittorrent-nox
 956632   3.7 bun
 750404  83.9 bun
 688572   4.5 bun
 611116   0.2 node
 393004   0.0 chrome
 371588   1.9 chrome
 367160   0.0 chrome
 347308   1.9 chrome
=== arc:
```

pkg установлены (T03, одобрено владельцем):
```
Updating hlab repository catalogue...
hlab repository is up to date.
All repositories are up to date.
pkg: No packages available to install matching 'e2fsprogs-libuuid' have been found in the repositories
pkg: No packages available to install matching 'lz4' have been found in the repositories
```

## rctl эксперименты (2026-11-01)
- exec-наследование: подтверждено (bun под process:$$:memoryuse=50m:deny упал на 300MB аллокации).
- fork-наследование: подтверждено — ребёнок под родительским кэпом убит.
- Пред-существующее правило: user:_p2p:memoryuse:deny=8589934592 (владелец уже управляет p2p-сервисами через rctl).
- pkg: liblz4 OK, libuuid (util-linux) установлен; e2fsprogs-libuuid в локальном репо hlab отсутствует — libuuid подходит.

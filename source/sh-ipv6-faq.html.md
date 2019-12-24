---
title: Silicon Hill IPv6 FAQ
category: misc
tags: history
date: 2004-05-21
---

Při úklidu na disku jsem našel kus Strahovské (Klub Silicon Hill) historie. Email/FAQ, který jsem sepisoval pro připojení bloků k nativnímu IPv6 (jojo už v roce 2004). Pro úplnost `nightmare` byl blokový server (a gateway/router) bloku 5.

```
IPv6 SH FAQ
-----------

* Postup připojení bloku

V současné chvíli jsou všechny bloky připojeny přes novou infrastrukturu,
takže NENÍ potřeba používat tunely. Pro zprovoznění IPv6 jsou potřeba tyto
kroky:
	- zažádáte správce adresního prostoru o přidělení IPv6 adres
	- směrovač (typicky PC) připojené pomocí 802.1q trunku do blokového
	  L3 switche cisco
	- do trunku si nakonfigurute VLAN6 (páteř) + vlany svých segmentů
	  na bloku
	    - pokud některou z VLAN máte nastavenou jako native VLAN, tak
	      pro ni NEVYTVÁŘÍTE subinterface
	- nakonfigurujete příslušná rozhraní (následuje
	  /etc/network/interfaces z nightmare):

auto eth0.6
iface eth0.6 inet6 static
        address 2001:718:2::501
        netmask 64

auto eth0.51
iface eth0.51 inet6 static
        pre-up vconfig add eth0 51
        pre-up ip link set eth0 up
        post-down vconfig rem eth0.51
        address 2001:718:2:0051::1
        netmask 64

auto eth0.52
iface eth0.52 inet6 static
        pre-up vconfig add eth0 52
        pre-up ip link set eth0 up
        post-down vconfig rem eth0.52
        address 2001:718:2:0052::1
        netmask 64

	- nakonfigurujte některý RIPng směrovací daemon, např. Zebra má
	  následující konfiguraci (opět z nightmare):

nightmare:/etc/zebra# cat /etc/zebra/zebra.conf
hostname nightmare
password pokus
enable password pokus
log file /var/log/zebra/zebra.log
service password-encryption
!
interface lo
!
interface eth0
  ipv6 nd suppress-ra
!
interface eth0.6
  ip address 147.32.115.1/24
  ipv6 address 2001:718:2::501/64
  ipv6 nd suppress-ra
!
interface eth0.51
  no ipv6 nd suppress-ra
  ipv6 nd prefix-advertisement 2001:718:2:51::/64 2592000 604800 onlink autoconfig
!
interface eth0.52
  no ipv6 nd suppress-ra
  ipv6 nd prefix-advertisement 2001:718:2:52::/64 2592000 604800 onlink autoconfig
!
line vty
!
log file /var/log/zebra/zebra.log

----------------------------------------------------

nightmare:/etc/zebra# cat /etc/zebra/ripngd.conf
hostname nightmare-ripngd
password pokus
enable password pokus
log file /var/log/zebra/ripngd.log
service password-encryption
!
debug ripng events
!
router ripng
 network eth0.6
 route 2001:718:2:51::/64
 route 2001:718:2:52::/64
 distribute-list local-only out eth0.6
!
router zebra
 redistribute ripng
!
ipv6 access-list local-only permit 2001:718:2:51::/64
ipv6 access-list local-only permit 2001:718:2:52::/64
ipv6 access-list local-only deny any
!
 line vty
!

----------------------------------------------------

DŮLEŽITÉ:

Všimněte si, že v RIPng je povoleno jenom páteřní rozhraní (tedy
eth0.6) nikoli další. Pomocí route se propagují přidělené prefixy, které
SMĚRUJE tento router - žádné jiné. Lze nahradit pomocí redistribute
connected.

Na toho, kdo sem přidá jiné interface nebo začne posílat defaultní routu,
pošlu bandu negrů s letlampama (courtesy of Pulp Fiction).
```

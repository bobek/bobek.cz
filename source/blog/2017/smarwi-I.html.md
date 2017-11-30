---
title: Smarwi, Část I.
category: tinkering
tags: iot, esp8266
toc: true
date: 2017-11-28
---

Podlehl jsem impulznímu nákupnímu rozhodnutí a pořídil [smarwi](https://vektiva.com/shop/smarwi). Celou akci spustil [Petr Stehlík](https://plus.google.com/+PetrStehl%C3%ADk/posts/bEiaeUeqkHU), který postnul link na recenzi produktu serverem [Geniální dům](http://www.genialnidum.cz/recenze-smarwi-automaticke-otevirani-oken/). Recenze na serveru ``genialnidum.cz`` je pěkně napsaná z uživatelského pohledu. Proto se na produkt zaměřím spíš optikou bastlíře a stůjce [několika](https://tech.showmax.com) Internetových [businessů](https://www.recombee.com).

> Editováno 2017-11-29 (ráno): přidána část o uchycení a ručním použití
>
> Editováno 2017-11-29 (věčer): přidána část o vnitřním provedení
>
> Editováno 2017-11-30 (ráno): přidána reakce výrobce


## Balení a setup

Celé zařízeni dorazilo pěkně zabalené za cca 3 dny od objednání na eshopu výrobce.

![smarwi v krabici](2017/smarwi_baleni.jpg)

Po startu vytvoří smarwi vytvoří wifi síť s SSDI ``SWR-*``. Stačí se do ní připojit a už můžete konfigurovat zařízení na ``http://192.168.1.1``. Klíčové je nastavit SSDI a heslo do wifi sítě, která ma konektivitu do Internetu, aby se mohlo smarwi spojit se serverem výrobce. Defaultní konfigurace má nastaveno ``broker.vektiva.com`` jako svůj cíl. Ano, adresu brokera lze takto jednoduše změnit! Velké plus :)

## Elektro-mechanické provedení

Musím říct, že zatím (ještě jsem ho nerozdělal) má u mě smarwi jedničku za mechanické provedení. Plasty sedí, nevržou atd. Konstrukce vypadá robustně a autoři přemýšleli na některými okrajovými stavy. Např. divná věc na konci ozubu je doraz, který aktivuje limitní spínač při zavírání okna. Obdobně přítlačný palec (který tlačí ozub na ozubené kolo nasazené na ose motoru) je vybaveno detekcí vychýlení. Takže zařízení ví, že jste ozub "vycvakli" a nemá smysl se snažit. V tomto případě, ale spínač neregistruje celý rozsah, takže se můžete dostat do stavu, kdy ozub nezabírá, ale zařízení o tom neví.

Vy diskusi pod Petrovým příspěvkem jsem vyjádřil hypotézu, že smarwi "brzdí motorem". Tedy, že brání pohybu okna tím, že udržuje motor pod napětím. Ještě prověřím po rozebrání, ale odběry tomu odpovídají. O napájení se stará klasický adaptér do zásuvky s uvedenými hodnotami 12V ss (DC) a 1.6A. Naměřené hodnoty po připojení k laboratornímu zdroji:

- klidový stav, okno nezajištěno: 40mA
- klidový stav, okno zajištěno: 190mA - 210mA
- změna stavu / motor běží: 480-500mA

Takže zavřené okno bude stát zhruba stovku ročně (``12*0.2*24*365/1000*4.83``).

### Uchycení na okno

Autoři primárně míří na trh plastových oken. Takže obě montážní plochy opatřili oboustrannou lepící páskou 3M VHB (což je jedna z těch opravdu dobrých). Zároveň jsou obě montážní plochy opatřeny dírami pro šrouby. Na hřebenu 2x, na jednotce 4x. Všechny průměr 4mm.

Mimochodem (je to vidět na fotografii výše) přichycení hřebenu je vymyšleno tak, že se hřeben může pohybovat v obou osách (nahoru-dolů, doleva-doprava). To umožňuje bezpečné ruční otevření okna, viz dále.

### Ruční ovládání

Chválím autory za ošetření krajních stavů. Např. pokud zamknete okno (zavřete na kličku) a pošlete smarwi příkaz k otevření, to správně detekuje, že okno nemůže otevřít a pošle chybový stav.

Pokud je potřeba rychle pohnout s oknem (aka bouřka) jsou dvě možnosti:

1. stisk ovládacího tlačítka (které je pevně spojené s jednotkou a typicky přidělané na okně, takže se neztratí). Tím dojde k odemčení motorové brzdy a oknem se dá v pohodě pohybovat.
2. uživatel může jednou rukou odtlačit hřeben doprava, tím jej vyhákne ze zubů na hřídeli motoru a okno je opět volné.

Pokud chcete okno otevřít dokořán, nic v tom nebrání (mimo případnou motorovou brzdu). Stačí tedy použít některý z postupů výše.

### Vnitřek

Samozřejmě jsem to nemohl vydžet moc dlouho a smarwi jsem kuchnul. Nejvíc asi napoví [fotografie](https://drive.google.com/drive/folders/1F_OGTq2zFTR5d8X0LHWN1xtplfOP_RNV). Plošňák vypadá třívrstvý (možná čtyř, vstvy jsou spatně vidět). Všechny limitní spínače jsou řešeny jako optické brány (všimněte si, že oba prsty v sobě mají bílé vložky, které brány detekují).

Hlavní kompontenty:

- krokový motor Micron SX17-1005LQECF (NEMA 17, podle datasheetu statický moment 0.51Nm)
- ESP8266MOD
- L5973A (2A step-down regulátor)
- L6470H (driver k motoru)
- 74HC14D (Hex inverting Schmitt trigger)

## Software

Mám rád open-source, nemám rád vendor lock-in. Mám pocit, že by svoje "smart" krabičky chtěl ovládat sám. Často se k tomu pak v budoucnu nedostanu, ale rád mám ten pocit, že můžu (kdybych chtěl, měl čas atd.).

Vektiva udělala několik rozhodnutí, které jsou z tohoto pohledu dobrá. Jedna nejspíš používají všemi oblíbený ESP8266, protože v HTTP requestech se vyskytuje ``User-Agent: ESP8266HTTPClient``. Ale hlavně používají MQTT pro veškerou zajímavou komunikaci. A [šifrování MQTT](https://hackaday.com/2017/06/20/practical-iot-cryptography-on-the-espressif-esp8266/) neřešili.

Zatím jsem jen pustil ``tcpdump`` a podíval se zhruba na provoz. Vyskytují se zde dva typy provozu.

### HTTP

Jeden HTTP (taky nešifrovaný). Requesty vzpadají takto:

```
GET /rcmd/18XXXXXXXXbe HTTP/1.0
Host: 185.8.236.58
User-Agent: ESP8266HTTPClient
Connection: close

HTTP/1.1 200 OK
Server: nginx
Date: Mon, 27 Nov 2017 20:57:26 GMT
Content-Type: text/html; charset=UTF-8
Content-Length: 0
Connection: close
```

Kde ``18XXXXXXXXbe`` je ID mého zařízení, jeho MAC je mimochodem ``1A:XX:XX:XX:XX:BE``. Poznámka k hostu. Já změnil ``broker.vektiva.com`` na IP adresu, na kterou resolvuje, což je aktuálně ``185.8.236.58``. Chtěl jsem vyzkoušet, jestli půjde smarwi poslat proti vlastní implementaci.

### MQTT

Po registraci na https://broker.vektiva.com jsou uživateli přiděleny dva stringy. Ty má uživatel nakonfigurovat přes rozhraní pro správu zařízení. Tyto řetězce přímo odpovídají MQTT uživatelskému jménu a heslu (které pak samozřejmě odejde sítí nešifrované). Po úspěšném ``MQTT Connect`` se zařízení přihlásí do několika topiců:

```
Topic: ion/dnlbkppare/%18XXXXXXXXbe/cmd/#
Topic: ion/dnlbkppare/%18XXXXXXXXbe/s/+/cmd
Topic: ion/dnlbkppare/nodes/swr
```

A také odešle zprávu do několika dalších:

```
Topic: ion/dnlbkppare/%18XXXXXXXXbe/online
Topic: ion/dnlbkppare/%18XXXXXXXXbe/status
```

Zpráva do ``status`` je zajímavá:

```
Message: t:swr\ns:-1\ne:0\na:-99\nok:0\nro:1\npos:o\nfix:0\nfw:202.5.0\nmem:19896\nup:15756\nno:-1\nnc:-1\nip:51030208\ncid:smarwi-bobek\nrssi:-52\ntime:1511819381\nwm:1\nwp:1\nwst:3\nec:0.0\n
```

Výrobce umožňuje konfigurovat zařízení i přes jejich webové rozhraní. Změna konfigurace vede k zaslání zprávy přes MQTT (následující šla od zařízení):

```
Topic: ion/dnlbkppare/%18XXXXXXXXbe/config/basic
Message: 01/01|ssid:bobek\npass:autobus1234\nssidap:SWR-e216be\npassap:12345678\nmode:cli\ndst:1\nzone:60\nrsetup:1\nrasetup:1\nwsleep:0\nmqttsvr:185.8.236.58\nmqttuser:dnlbkppare\nmqttpass:82584885\nmqttport:1883\nmqttka:30\nswrname:smarwi-bobek\nlat:50.088001\nlon:14.420000\nsunalgo:0\nunst:0

Topic: ion/dnlbkppare/%18XXXXXXXXbe/config/advanced
Message: vpct:100\nospd:40\nofspd:40\norpwr:50\nofpwr:60\nohcpwr:60\nohopwr:30\nhdist:0\nlwid:20\ncfdist:0\ncvdist:0\n
```

Kde ``SWR-e216be`` a ``12345678`` je SSID resp heslo pro síť sloužící ke konfiguraci zařízení (heslo není tajné, je uvedené v manuálu). A ano, ``bobek`` a ``autobus1234`` je SSID resp heslo k síti, ke které je zařízení připojeno a čerpá Internet. A ``lat`` a ``lon`` jsou souřadnice zařízení, které si může uživatel nastavit sám.

Příkazy pro zařízení jsou zasílány do topicu ``cmd``, reakce zařízení je typicky v ``response`` (případně ``status``):

```
Topic: ion/dnlbkppare/%18XXXXXXXXbe/cmd
Message: stat

Topic: ion/dnlbkppare/%18XXXXXXXXbe/cmd
Message: clos

Topic: ion/dnlbkppare/%18XXXXXXXXbe/response
Message: ERROR:0

```

Některé ze zachycených příkazů: ``clos``, ``open``, ``stab``, ``cstart``, ``cend``, ``stop``, ``load0``, ``sens``. Z nějakého záhadného důvodu jsem si myslel, že už tento model umí sám měřit koncentrace CO2. Takže ``sens`` mě nadchnul. Ale není tomu tak (a výrobce jasně uvádí, že to tak není, tohle je čistě moje chyba). Dostupné "senzory" jsou aktuálně

- Last open (unixtime)
- Last close (unixtime)
- Opened (bool)
- Sunrise (unixtime)
- Sunset (unixtime)

## Závěr

Čistě z uživatelského hlediska je zařízení pěkné

- kvalitní mechanické provedení (opravdu mě potěšilo ošetření okrajových stavů a promyšlení ruční manipulace)
- tichý chod
- levnější metoda větrání než třeba rekuperace (na naše lehce netěsnící dřevěná okna ovšem nemá :))

Vlastně jediné negativum je pochybné zabezpečení. A taky to, že celá aplikace běží nejspíš na jednom serveru (ale tam jsme byli všichni).

Z pohledu bastlíře je hlavní **pozitivum** nešifrované MQTT a možnost změnit adresu brokera. Takže další logický krok, je napsat si vlastní ovládání a napojit smarwi na vlastního brokera. Naprosto ideální řešení situace by bylo:

- umožnit zapnout šifrování v konfiguraci zařízení
- zveřejnit popis zpráv, aby je člověk nemusel reverse-engineerovat. Aktuálně je popsáno pouze [HTTP API](https://vektiva.gitlab.io/vektivadocs/api/#api-pres-lokalni-sit). Ale i za to dávám pozitivní body!

## Reakce výrobce

Poslal jsem email na `support@vektiva.com`, hned druhý den se ozvali. S jejich svolením jej "otiskuji".

```
Date: Wed, 29 Nov 2017 17:54:25 +0100
From: Hynek Bury

Dobrý den,

moc nás zaujal Váš zdravě kritický přístup k našemu zařízení a děkujeme za
věcné podněty (IP přesměrování opraveno).

Máte naprostou pravdu, že se vše na MQTT přenáší přes cleartext, ale toto
řešení jsme zvolili jako prozatímní, s tím, že v některém z dalších updatů
firmwaru bude k dispozici volitelná alternativa, pracujeme na tom. Z našeho
pohledu není toto zařízení úplně masový produkt, a navíc na trhu není příliš
známý. Proto jsme zvolili strategii rychlejšího dodání na trh s tím, že některá
softwarová vylepšení dodáme později .

Každopádně přenášení uloženého hesla k WiFi přes MQTT je regulérní bug, který
již měl být odstraněn, resp. vše v kódu se opravilo, až na malou drobnost. V
tento moment by to již mělo být v aktuálním firmwaru opraveno a můžete si jej
ze stránek https://vektiva.online/ aktualizovat. (Web prozatím nehlásí
automaticky dostupnost aktualizací)

Popis naší implementace MQTT komunikace máte velmi pěkný. My se budeme snažit
nějaký oficiální popis vytvořit také, ale ještě revidujeme některé "topiky" a
formáty zpráv, zatím jsme tedy nedošli ke zcela finální verzi. Pokusíme se to
uspíšit, protože naším cílem není trápit zákazníky tak, aby museli protokol
"reverse-engeneerovat" (i přesto, že to může být zábavné), ale aby měli volné
ruce a mohli zařízení využít, jak uznají za vhodné a čas mohli věnovat třeba
propojováním s existující infrastrukturou.

Pro pořádek okomentuji i HTTP požadavek, který ve vašem textu zmiňujete.
Využíváme jej jako "ping", abychom mohli v případě problémů našich zákazníků
vyloučit některé jiné chybové stavy. Je ale možné, že toto do budoucna zrušíme,
již to totiž prakticky nevyužíváme.

Naše strategie není vybudovat a dodat na trh sto padesátý uzavřený ekosystém,
ale naopak produkt schopný širší integrace, do řešení které již zákazník má a
navíc dle jeho technických možností/znalostí.  Byli bychom velmi rádi,
kdybychom si dokázali se zákazníky pomoci navzájem. Nakonec tento produkt
vznikl pro řešení problému s ventilací prvotně u nás doma a věřím, že naše
zájmy budou v mnoha ohledech velmi podobné.

V příloze posílám fotografie vnitřku (na foto před-produkční verze, je shodná s
Vaší verzí až na plastové díly). Může Vám to ušetřit pár minut při rozebírání
:)

Pokud budete mít dotazy, rádi Vám je zodpovíme!

S pozdravem,
Hynek Bury
```

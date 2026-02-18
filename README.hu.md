<div align="center">

```
                    _ _                      _ _ 
  _ __ ___   ___  __| (_) __ _ _ __  _   _| | |
 | '_ ` _ \ / _ \/ _` | |/ _` | '_ \| | | | | |
 | | | | | |  __/ (_| | | (_| | |_) | |_| | | |
 |_| |_| |_|\___|\__,_|_|\__,_| .__/ \__,_|_|_|
                                |_|              
```

**Batch médialetöltő, yt-dlp alapokon**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux%20%7C%20WSL-blue.svg)](https://github.com/microsoft/WSL)
[![Powered by yt-dlp](https://img.shields.io/badge/Powered%20by-yt--dlp-red.svg)](https://github.com/yt-dlp/yt-dlp)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

*Tölts le egy egész URL listát egyetlen paranccsal. Config-vezérelt. Mindent naplóz. Kihagyja ami már megvan.*

[🇬🇧 English](README.md) | 🇭🇺 Magyar

</div>

---

## Mi ez?

A `mediapull` a [yt-dlp](https://github.com/yt-dlp/yt-dlp) köré épített batch letöltő szkript. Ahelyett, hogy minden videóhoz külön futtatnád a yt-dlp-t, egyszerűen egy fájlba gyűjtöd a linkeket, és a mediapull elvégzi a többit — strukturált kimenettel, naplózással, skip logikával, és teljes yt-dlp pass-through támogatással.

Működik **Vimeo, YouTube és [1000+ más oldallal](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md)**, amit a yt-dlp támogat.

---

## Funkciók

- **Batch letöltés** egyszerű `.md` vagy `.txt` URL listából — soronként egy link
- **YAML konfiguráció** az alapértelmezett yt-dlp beállításokhoz — egyszer beállítod, mindig használod
- **Pass-through kapcsolók** — bármely yt-dlp opciót felülírhatsz futtatáskor, a config módosítása nélkül
- **Strukturált kimenet** — minden input fájlhoz saját névvel ellátott output könyvtár jön létre
- **Skip logika** — az újrafuttatás kihagyja a már letöltött fájlokat (biztonságosan megszakítható)
- **Időbélyeges naplók** — minden futtatás részletes logot hoz létre az output fájlok mellé
- **Bash autocomplete** — TAB-bal választhatsz input fájlt és yt-dlp kapcsolókat
- **Függőség-ellenőrzés** — azonnal leáll, ha hiányzik a yt-dlp/ffmpeg/yq

---

## Projekt struktúra

```
~/mediapull/
├── bin/
│   ├── mediapull              # symlink → mediapull.sh
│   ├── mediapull.sh           # főscript
│   └── mediapull_completion.sh
├── config/
│   └── config.yaml            # alapértelmezett beállítások
├── input/
│   └── videok.md              # URL lista fájlok ide kerülnek
└── output/
    └── videok/                # automatikusan létrejön, input fájlonként
        ├── video_001.mp3
        ├── video_002.mp3
        └── mediapull_20250218_143022.log
```

---

## Telepítés

**Függőségek:** `yt-dlp`, `ffmpeg`, `yq`

```bash
# Klónozd a repót
git clone https://github.com/tgellai/mediapull.git
cd mediapull

# Futtasd a setupot — telepíti a függőségeket, beállítja a PATH-t, engedélyezi az autocomplete-et
bash setup.sh
```

Telepítés után nyiss egy új terminált. Kész.

---

## Használat

```bash
# Alap — a config.yaml alapértelmezéseit használja
mediapull videok.md

# Audio formátum felülírása erre a futtatásra
mediapull videok.md --audio-format wav

# Videó letöltése audio helyett
# Állítsd be: extract_audio: false a config.yaml-ban

# Lassítás letöltések között (rate limit elkerülése)
mediapull videok.md --sleep-interval 5

# Bármely yt-dlp kapcsoló működik
mediapull videok.md --audio-quality 0 --embed-thumbnail --retries 5
```

TAB autocomplete input fájlokra és yt-dlp kapcsolókra egyaránt:

```bash
mediapull [TAB]                        # input/ könyvtár fájljait listázza
mediapull videok.md --[TAB][TAB]       # összes yt-dlp kapcsolót listázza
```

---

## Input fájl formátum

Egyszerű szövegfájl, soronként egy URL. A `#` kommentek és üres sorok figyelmen kívül maradnak.

```
# 1. modul
https://player.vimeo.com/video/XXXXXXXXX
https://player.vimeo.com/video/XXXXXXXXX

# 2. modul
https://player.vimeo.com/video/XXXXXXXXX
https://player.vimeo.com/video/XXXXXXXXX
```

---

## Konfiguráció

Szerkeszd a `config/config.yaml` fájlt az alapértelmezések beállításához:

```yaml
# Csak hangot tölts le — false esetén videó marad
extract_audio: true

# Audio formátum: mp3 | wav | m4a | flac | opus | vorbis | aac
audio_format: mp3

# Audio minőség: 0 (legjobb VBR) → 10 (legrosszabb) | vagy fix bitrate pl. 128K
audio_quality: 0

# Másodpercek letöltések között — légy udvarias a szerverrel
sleep_interval: 1

# Újrapróbálkozások száma hálózati hiba esetén
retries: 3

# Opcionális: extra yt-dlp kapcsolók listája
# extra_flags:
#   - "--embed-thumbnail"
#   - "--embed-metadata"
#   - "--no-playlist"
```

### Config + override prioritás

A parancssori kapcsolók **kiegészítik** a configot, nem helyettesítik:

```bash
# config.yaml:  audio_format: mp3
# parancssor:   --audio-format wav
# eredmény:     --audio-format wav nyer (yt-dlp az utolsó értéket használja)
```

### Flag cache törlése

A mediapull cache-eli a yt-dlp elérhető kapcsolóit a gyorsabb TAB completionhoz. Ha frissítetted a yt-dlp-t:

```bash
rm ~/.mediapull_flags_cache
```

---

## Kimenet

Minden futtatás egy könyvtárat hoz létre az input fájl neve alapján:

```
output/
└── videok/
    ├── video_001.mp3
    ├── video_002.mp3
    ├── video_003.mp3
    └── mediapull_20250218_143022.log
```

A log tartalmazza a teljes yt-dlp kimenetet minden letöltéshez, plus összesítőt:

```
[2025-02-18 14:30:22] [INFO] mediapull started
[2025-02-18 14:30:22] [INFO] Config args:    -x --audio-format mp3 --audio-quality 0
[2025-02-18 14:31:05] [OK]   [1] Sikeres
[2025-02-18 14:31:05] [SKIP] video_002 már létezik, kihagyom
[2025-02-18 14:32:11] [FAIL] [3] Sikertelen: https://...
[2025-02-18 14:32:11] [INFO] ÖSSZESÍTŐ: Sikeres: 1 | Kihagyott: 1 | Hibás: 1
```

---

## Követelmények

| Eszköz | Verzió | Telepítés |
|--------|--------|-----------|
| `yt-dlp` | legújabb | `curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp` |
| `ffmpeg` | bármely | `sudo apt install ffmpeg` |
| `yq` | v4+ | `sudo snap install yq` |
| `bash` | 4.0+ | előtelepített Linux/WSL-en |

---

## Licenc

MIT — csinálj vele amit akarsz.

---

<div align="center">

*Azért született, mert 30 videóhoz egyesével beírni a yt-dlp parancsot fárasztó.*

</div>

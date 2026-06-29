#!/usr/bin/env python3
"""
Sinclear Build & Deploy Tool

Automatisiert den gesamten Deployment-Prozess:
  1. Build  (flutter clean → pub get → build web → build apk)
  2. Post-Process  (Build-Ausgabe in versionierte Verzeichnisstruktur)
  3. FTP-Upload  (Web + APK)
  4. app_version.json aktualisieren
  5. Optional:  flutter run --debug starten

Versionierte Verzeichnisstruktur:
  /
  ├── index.html          (mit <base href="/{version}/">)
  ├── version.json        (immer fresh, kein Cache)
  ├── .htaccess
  └── {version}/
      ├── main.dart.js
      ├── flutter_bootstrap.js
      └── ...

Usage:
  python deploy.py            # Vollautomatischer Durchlauf
  python deploy.py --dry-run  # Nur Simulation, keine Änderungen

Umgebungsvariablen in .env (siehe .env.example):
  FTP_HOST, FTP_USER, FTP_PASS, FTP_PROJECT_ROOT_PATH
"""

import ftplib
import io
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

# ── Pfade ──────────────────────────────────────────────────────────────────
ROOT = Path(__file__).resolve().parent
ENV_FILE = ROOT / '.env'
ENV_EXAMPLE = ROOT / '.env.example'
PUBSPEC = ROOT / 'pubspec.yaml'
BUILD_WEB = ROOT / 'build' / 'web'
BUILD_APK = ROOT / 'build' / 'app' / 'outputs' / 'flutter-apk' / 'app-release.apk'
DIST = ROOT / 'dist'

# ── ANSI-Farben ────────────────────────────────────────────────────────────
R = '\033[0m'
B = '\033[1m'
G = '\033[92m'
Y = '\033[93m'
C = '\033[96m'
RE = '\033[91m'
GR = '\033[90m'
BL = '\033[94m'

DRY_RUN = '--dry-run' in sys.argv


# ══════════════════════════════════════════════════════════════════════════
#  HELFER
# ══════════════════════════════════════════════════════════════════════════

def print_header():
    print()
    print(f'  {BL}{"=" * 50}{R}')
    print(f'  {BL}   Sinclear Build & Deploy Tool   v2.0{R}')
    print(f'  {BL}   (versionierte Web-Deployment){R}')
    print(f'  {BL}{"=" * 50}{R}')
    if DRY_RUN:
        print(f'  {Y}   ⚠  DRY RUN – keine Änderungen{R}')
        print(f'  {Y}   Nur Simulation der geplanten Aktionen{R}')
    print()


def step(msg):
    print(f'\n  {B}{msg}{R}')


def ok(msg=''):
    if DRY_RUN:
        print(f'  {GR}{msg or "✔"}{R}')
    else:
        print(f'  {G}{msg or "✔"}{R}')


def fail(msg):
    print(f'\n  {RE}✖  {msg}{R}')
    sys.exit(1)


def run_cmd(cmdline):
    print(f'  {GR}$ {cmdline}{R}')
    if DRY_RUN:
        return
    r = subprocess.run(cmdline, shell=True, cwd=ROOT)
    if r.returncode != 0:
        fail(f'Kommando fehlgeschlagen: {cmdline}')


# ══════════════════════════════════════════════════════════════════════════
#  KONFIGURATION
# ══════════════════════════════════════════════════════════════════════════

def load_env():
    """Liest .env und validiert alle Keys, die .env.example vorgibt."""
    if not ENV_FILE.exists():
        fail(f'.env nicht gefunden ({ENV_FILE}).\n'
             f'  Kopiere .env.example nach .env und trage deine Zugangsdaten ein.')

    expected = set()
    with open(ENV_EXAMPLE) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                expected.add(line.split('=', 1)[0].strip())

    env = {}
    with open(ENV_FILE) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            if '=' not in line:
                continue
            key, _, val = line.partition('=')
            env[key.strip()] = val.strip().strip('"\'')

    missing = expected - env.keys()
    if missing:
        fail(f'Fehlende Variablen in .env: {", ".join(sorted(missing))}')

    return env


def parse_version():
    """Extrahiert Version aus pubspec.yaml und berechnet versionCode.

    Version "0.5.5"  → versionCode 55
    Version "1.2.4"  → versionCode 124
    """
    if not PUBSPEC.exists():
        fail(f'pubspec.yaml nicht gefunden ({PUBSPEC})')

    with open(PUBSPEC) as f:
        for line in f:
            m = re.match(r'^version:\s*(\S+)', line)
            if m:
                raw = m.group(1)
                raw = re.split(r'[+-]', raw)[0]
                parts = raw.split('.')
                if len(parts) >= 3:
                    major, minor, patch = parts[:3]
                    ver = f'{major}.{minor}.{patch}'
                    vc = int(f'{major}{minor}{patch}')
                    return ver, vc

    fail('Keine Version in pubspec.yaml (z. B. "version: 0.5.5")')


# ══════════════════════════════════════════════════════════════════════════
#  CHANGELOG
# ══════════════════════════════════════════════════════════════════════════

def prompt_changelog(old_data):
    """Zeigt ggf. die alte Version und fragt den neuen Changelog ab."""
    if old_data:
        print(f'  {GR}Aktuelle Version auf dem Server:{R}')
        print(f'    Version:      {old_data.get("version", "?")}')
        print(f'    VersionCode:  {old_data.get("versionCode", "?")}')
        if old_data.get('changelog'):
            print(f'    Changelog:')
            for e in old_data['changelog']:
                print(f'      • {e}')
        print()

    print(f'  {B}Changelog für das neue Update (leere Zeile = fertig):{R}')
    lines = []
    n = 1
    while True:
        try:
            line = input(f'  {n}. ')
        except (EOFError, KeyboardInterrupt):
            print()
            break
        if not line.strip():
            break
        lines.append(line.strip())
        n += 1

    if not lines:
        print(f'  {Y}⚠  Keine Changelog-Einträge eingegeben.{R}')
    else:
        s = '' if len(lines) == 1 else 'e'
        print(f'  {GR}→ {len(lines)} Eintrag{s} erfasst{R}')

    return lines


# ══════════════════════════════════════════════════════════════════════════
#  FTP-HELFER
# ══════════════════════════════════════════════════════════════════════════

def ftp_connect(env):
    """Verbindet per FTPS (TLS) zum Server und wechselt ins Projektverzeichnis."""
    if DRY_RUN:
        return None
    ftp = ftplib.FTP_TLS()
    ftp.connect(env['FTP_HOST'], 21)
    ftp.auth()
    ftp.login(env['FTP_USER'], env['FTP_PASS'])
    ftp.prot_p()
    root = env['FTP_PROJECT_ROOT_PATH'].rstrip('/')
    if root:
        try:
            ftp.cwd(root)
        except ftplib.error_perm as e:
            fail(f'FTP: Kann nicht nach {root} wechseln ({e})')
    return ftp


def ftp_fetch_json(ftp, path):
    """Liest eine JSON-Datei via FTP."""
    if ftp is None:
        return None
    try:
        buf = io.BytesIO()
        ftp.retrbinary(f'RETR {path}', buf.write)
        buf.seek(0)
        return json.loads(buf.read())
    except Exception:
        return None


def ftp_list(ftp, path):
    """Löst ein FTP-LIST aus und liefert (dirs, files)."""
    items: list[str] = []
    ftp.dir(path, items.append)
    dirs, files = [], []
    for line in items:
        parts = line.split(None, 8)
        if len(parts) < 9:
            continue
        name = parts[-1]
        if name in ('.', '..'):
            continue
        (dirs if parts[0].startswith('d') else files).append(name)
    return dirs, files


def ftp_clean_versioned_dirs(ftp, keep_recent=10, skip=frozenset({'api', 'downloads'})):
    """Löscht alte versionierte Verzeichnisse, behält die neuesten `keep_recent`.

    Nutzer die noch die App offen haben brauchen Assets aus ihrem geladenen
    Version-Ordner. Deshalb wird immer mindestens eine Vorgängerversion behalten.
    """
    if ftp is None:
        return

    dirs, _ = ftp_list(ftp, '.')
    version_pattern = re.compile(r'^(\d+)\.(\d+)\.(\d+)$')
    versions = []

    for d in dirs:
        if d in skip:
            continue
        m = version_pattern.match(d)
        if m:
            parts = (int(m.group(1)), int(m.group(2)), int(m.group(3)))
            versions.append((parts, d))

    # Sortiere absteigend (neueste zuerst)
    versions.sort(key=lambda x: x[0], reverse=True)

    # Behalte die neuesten `keep_recent`, lösche den Rest
    to_delete = versions[keep_recent:]

    for parts, name in to_delete:
        print(f'    🗑  {name}/ (alte Version)')
        _ftp_rmtree(ftp, name)


def _ftp_rmtree(ftp, path):
    """Löscht ein Verzeichnis rekursiv via FTP."""
    dirs, files = ftp_list(ftp, path)

    for f in files:
        try:
            ftp.delete(f'{path}/{f}')
        except ftplib.error_perm:
            pass

    for d in dirs:
        _ftp_rmtree(ftp, f'{path}/{d}')
        try:
            ftp.rmd(f'{path}/{d}')
        except ftplib.error_perm:
            pass


def ftp_clean_root_files(ftp):
    """Löscht Dateien im Root (außer api/, downloads/, versionierten Verzeichnissen)."""
    if ftp is None:
        return

    _, files = ftp_list(ftp, '.')
    version_pattern = re.compile(r'^\d+\.\d+\.\d+$')

    for f in files:
        if f in ('api', 'downloads'):
            continue
        try:
            ftp.delete(f)
            print(f'    🗑  {f}')
        except ftplib.error_perm as e:
            print(f'    {Y}⚠  {f} konnte nicht gelöscht werden: {e}{R}')


def ftp_upload_dir(ftp, local, remote):
    """Lädt ein lokales Verzeichnis rekursiv auf den FTP-Server hoch."""
    if ftp is None:
        return

    for entry in os.scandir(local):
        rpath = f'{remote}/{entry.name}' if remote and remote != '.' else entry.name

        if entry.is_dir():
            try:
                ftp.mkd(rpath)
                print(f'    📁  {rpath}/')
            except ftplib.error_perm:
                pass
            ftp_upload_dir(ftp, entry.path, rpath)
        else:
            print(f'    📄  {rpath}')
            with open(entry.path, 'rb') as fh:
                ftp.storbinary(f'STOR {rpath}', fh)


def ftp_upload_file(ftp, local_path, remote_path, label=''):
    """Lädt eine einzelne Datei hoch."""
    if ftp is None:
        return
    print(f'    📄  {label or remote_path}')
    with open(local_path, 'rb') as fh:
        ftp.storbinary(f'STOR {remote_path}', fh)


def ftp_write_json(ftp, path, data):
    """Schreibt ein Python-Dict als JSON-Datei auf den FTP-Server."""
    raw = json.dumps(data, indent=4, ensure_ascii=False).encode('utf-8')
    print(f'    📄  {path}  ({len(raw)} Bytes)')
    if ftp is not None:
        ftp.storbinary(f'STOR {path}', io.BytesIO(raw))


def ftp_mkdir(ftp, path):
    """Erstellt ein FTP-Verzeichnis (ignoriert Fehler, wenn es existiert)."""
    if ftp is None:
        return
    try:
        ftp.mkd(path)
    except ftplib.error_perm:
        pass


# ══════════════════════════════════════════════════════════════════════════
#  POST-PROCESSING (Python-Integration)
# ══════════════════════════════════════════════════════════════════════════

def post_process_web(version):
    """Erstellt die versionierte Verzeichnisstruktur aus build/web/."""
    if not BUILD_WEB.is_dir():
        fail(f'Build-Verzeichnis nicht gefunden: {BUILD_WEB}\n'
             f'  Der Web-Build war vermutlich nicht erfolgreich.')
    if not (BUILD_WEB / 'version.json').exists():
        fail(f'build/web/version.json nicht gefunden.')

    # Dist vorbereiten
    if DIST.exists() and not DRY_RUN:
        shutil.rmtree(DIST)
    if not DRY_RUN:
        DIST.mkdir(parents=True, exist_ok=True)

    # Build-Inhalte in versioniertes Verzeichnis verschieben
    versioned = DIST / version
    if not DRY_RUN:
        shutil.copytree(BUILD_WEB, versioned)

    # .htaccess für versionierte Assets
    htaccess_versioned = ROOT / 'web' / '.htaccess.versioned'
    if htaccess_versioned.exists() and not DRY_RUN:
        shutil.copy2(htaccess_versioned, versioned / '.htaccess')

    # index.html mit angepasstem <base href> erzeugen
    index_html = DIST / 'index.html'
    if not DRY_RUN:
        index_html.write_text(f'''<!DOCTYPE html>
<html>
<head>
  <base href="/{version}/">

  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="Sinclear Beyond – Deine intelligente Plattform.">

  <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
  <meta http-equiv="Pragma" content="no-cache">
  <meta http-equiv="Expires" content="0">

  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="Beyond">
  <link rel="apple-touch-icon" href="/{version}/apple-touch-icon.png">

  <link rel="icon" type="image/x-icon" href="/{version}/favicon.ico">
  <link rel="icon" type="image/png" sizes="192x192" href="/{version}/icons/icon-192x192.png"/>
  <link rel="icon" type="image/png" sizes="512x512" href="/{version}/icons/icon-512x512.png"/>

  <title>Sinclear Beyond</title>
  <link rel="manifest" href="/{version}/manifest.json">
</head>
<body>
  <script>
    if ('serviceWorker' in navigator) {{
      navigator.serviceWorker.register('/{version}/firebase-messaging-sw.js');
    }}
  </script>
  <script src="/{version}/flutter_bootstrap.js" async></script>
</body>
</html>
''', encoding='utf-8')

    # version.json auf Root kopieren
    if not DRY_RUN:
        shutil.copy2(BUILD_WEB / 'version.json', DIST / 'version.json')

    # .htaccess für Root
    htaccess_root = ROOT / 'web' / '.htaccess'
    if htaccess_root.exists() and not DRY_RUN:
        shutil.copy2(htaccess_root, DIST / '.htaccess')


# ══════════════════════════════════════════════════════════════════════════
#  MAIN
# ══════════════════════════════════════════════════════════════════════════

def main():
    print_header()

    # ── 1. Konfiguration lesen ─────────────────────────────────────────
    step('📋  Konfiguration')
    env = load_env()
    version, version_code = parse_version()
    apk_name = "app-release.apk"
    remote_root = env['FTP_PROJECT_ROOT_PATH'].rstrip('/') or '.'

    print(f'    Version:       {version}')
    print(f'    VersionCode:   {version_code}')
    print(f'    APK-Datei:     {apk_name}')
    print(f'    FTP-Server:    {env["FTP_HOST"]}')
    print(f'    Remote-Pfad:   {remote_root}')

    # ── 2. Alte Version vom Server holen ──────────────────────────────
    step('🌐  Alte Version vom Server')
    try:
        ftp_temp = ftp_connect(env)
        old_data = ftp_fetch_json(ftp_temp, 'api/app_version.json')
        if ftp_temp:
            ftp_temp.quit()
    except Exception as e:
        print(f'    {Y}⚠  Konnte Server nicht erreichen (FTPS/TLS): {e}{R}')
        old_data = None

    if old_data:
        print(f'    {GR}Letzte Version: {old_data.get("version")} '
              f'(Code {old_data.get("versionCode")}){R}')
    else:
        print(f'    {Y}⚠  Keine alte Version gefunden (oder Server nicht erreichbar){R}')

    # ── 3. Changelog eingeben ─────────────────────────────────────────
    step('📝  Changelog')
    changelog = prompt_changelog(old_data)

    # ── 4. Build ──────────────────────────────────────────────────────
    step('🔨  Build')
    run_cmd('flutter clean')
    run_cmd('flutter pub get')
    run_cmd('flutter build web --release')
    run_cmd('flutter build apk --release')

    if not BUILD_APK.is_file():
        fail(f'APK nicht gefunden: {BUILD_APK}\n'
             f'  Der APK-Build war vermutlich nicht erfolgreich.')

    # ── 5. Post-Processing ────────────────────────────────────────────
    step('📁  Post-Processing (versionierte Struktur)')
    post_process_web(version)

    if DIST.is_dir():
        versioned = DIST / version
        print(f'    Dist-Inhalt:')
        for item in sorted(DIST.iterdir()):
            if item.is_dir():
                count = sum(1 for _ in item.rglob('*') if _.is_file())
                print(f'    {G}📁  {item.name}/  ({count} Dateien){R}')
            else:
                print(f'    {G}📄  {item.name}{R}')
    ok(f'Versioniertes Build erstellt: {version}')

    # ── 6. FTP-Deployment ─────────────────────────────────────────────
    step('🌐  FTP-Deployment')

    vj_data = {
        'version': version,
        'versionCode': version_code,
        'apkFile': apk_name,
        'changelog': changelog,
    }

    if DRY_RUN:
        print(f'    {GR}→ Verbinde zu {env["FTP_HOST"]} …{R}')
        print(f'    {GR}→ Lösche alte versionierte Verzeichnisse (X.Y.Z){R}')
        print(f'    {GR}→ Lösche alte Root-Dateien (außer api/, downloads/){R}')
        print(f'    {GR}→ Lade dist/ → {remote_root}/ hoch:{R}')
        print(f'       index.html, version.json, .htaccess, {version}/')
        print(f'    {GR}→ Lade {apk_name} → {remote_root}/downloads/ hoch{R}')
        print(f'    {GR}→ Schreibe api/app_version.json:{R}')
        print(json.dumps(vj_data, indent=4, ensure_ascii=False))
        ok('Dry-Run erfolgreich')
    else:
        print(f'    Verbinde zu {env["FTP_HOST"]} (FTPS/TLS) …')
        try:
            ftp = ftp_connect(env)
        except Exception as e:
            fail(f'FTPS-Verbindung fehlgeschlagen: {e}\n'
                 f'  Prüfe FTP_HOST, FTP_USER, FTP_PASS in .env\n'
                 f'  Stelle sicher, dass der Server TLS unterstützt.')
        ok(f'Verbunden mit {env["FTP_HOST"]}')

        # 6a. Alte versionierte Verzeichnisse löschen
        print(f'    {GR}Alte versionierte Verzeichnisse bereinigen …{R}')
        ftp_clean_versioned_dirs(ftp)

        # 6b. Alte Root-Dateien löschen (index.html, version.json, etc.)
        print(f'    {GR}Alte Root-Dateien bereinigen …{R}')
        ftp_clean_root_files(ftp)

        # 6c. Dist hochladen (Root-Dateien + versioniertes Verzeichnis)
        print(f'    {GR}Web-Build hochladen (versioniert) …{R}')
        ftp_upload_dir(ftp, str(DIST), '.')

        # 6d. APK hochladen
        print(f'    {GR}APK hochladen …{R}')
        ftp_mkdir(ftp, 'downloads')
        ftp_upload_file(ftp, str(BUILD_APK), f'downloads/{apk_name}',
                        label=f'downloads/{apk_name}')

        # 6e. app_version.json schreiben
        print(f'    {GR}app_version.json aktualisieren …{R}')
        ftp_write_json(ftp, 'api/app_version.json', vj_data)

        ftp.quit()
        ok('FTP-Verbindung geschlossen')

    # ── 7. Lokales Dist bereinigen ────────────────────────────────────
    step('🧹  Lokales Dist bereinigen')
    if DIST.exists() and not DRY_RUN:
        shutil.rmtree(DIST)
        ok(f'Dist gelöscht: {DIST}')
    else:
        ok('Dist nicht vorhanden (Dry-Run)')

    # ── 8. Zusammenfassung ────────────────────────────────────────────
    step(f'✅  Deployment abgeschlossen')
    host = env['FTP_HOST']
    print(f'    Web:       {C}https://{host}/{R}')
    print(f'    Version:   {C}/{version}/{R}')
    print(f'    APK:       {C}https://{host}/downloads/{apk_name}{R}')
    print(f'    Version:   {version}  (Code {version_code})')
    if changelog:
        print(f'    Changelog:')
        for e in changelog:
            print(f'      • {e}')

    # ── 8. Debug-Frage ────────────────────────────────────────────────
    if not DRY_RUN:
        print()
        try:
            answer = input(f'  {BL}🐞{R}  Debug-Modus starten? '
                           f'(flutter run --debug) [{B}j{R}/N]: ').strip().lower()
            if answer in ('j', 'ja', 'y', 'yes'):
                run_cmd('flutter run --debug')
        except (EOFError, KeyboardInterrupt):
            print()

    print()
    print(f'  {G}✔  Fertig!{R}')
    print()


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print(f'\n  {Y}⚠  Abgebrochen{R}')
        sys.exit(130)

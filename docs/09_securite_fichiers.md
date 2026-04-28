# Sécurité des fichiers - Scan antivirus

## Présentation

Tous les fichiers déposés par les candidats sur Passe Marché sont automatiquement analysés par un antivirus avant d'être acceptés dans le dossier de candidature.

Le moteur antivirus utilisé est **ClamAV**, un antivirus open-source maintenu par **Cisco Talos**. ClamAV est le standard de référence pour le scan de fichiers côté serveur :

- Utilisé par des millions de serveurs en production dans le monde
- Base de signatures mise à jour quotidiennement
- Recommandé par l'ANSSI pour les architectures de dépôt de fichiers
- Licence GPL, auditable et transparent

## Configuration

Le scan antivirus est activé via le credential Rails `clamav.enabled: true`. Sans cette configuration, les fichiers ne sont pas scannés et aucun badge n'est affiché.

```bash
rails credentials:edit --environment <env>
# Ajouter :
# clamav:
#   enabled: true
```

### Sans le credential (`clamav.enabled` absent ou `false`)

Les fichiers ne sont pas scannés. Aucun badge affiché. Le parcours candidat fonctionne normalement.

### Avec le credential (`clamav.enabled: true`)

| Situation | Comportement | Badge |
|---|---|---|
| **ClamAV non installé** | Les fichiers ne sont pas scannés. Même comportement que sans le credential. | Aucun |
| **ClamAV installé, mauvais path** | Même comportement que "non installé". Corriger via le credential `clamav.clamscan_path`. | Aucun |
| **ClamAV installé et accessible** | Scan complet. | "Vérifié" ou "Malware détecté" |

## Installation pour les développeurs

### macOS (Homebrew)

```bash
brew install clamav

# Configurer freshclam (mise à jour des signatures)
cp /opt/homebrew/etc/clamav/freshclam.conf.sample /opt/homebrew/etc/clamav/freshclam.conf
sed -i '' 's/^Example/#Example/' /opt/homebrew/etc/clamav/freshclam.conf

# Télécharger les signatures (~300 MB)
freshclam
```

Vérifier l'installation :

```bash
clamscan --version
# ClamAV 1.x.x/xxxxx/...
```

Puis activer le scan via le credential (voir section Configuration ci-dessus).

### Linux (Debian/Ubuntu)

```bash
sudo apt-get update && sudo apt-get install -y clamav
sudo freshclam
```

Le binaire `clamscan` sera disponible à `/usr/bin/clamscan` (chemin par défaut de l'app).

### Sans ClamAV (défaut)

Rien à faire. L'app fonctionne sans ClamAV en développement. Aucun badge de scan ne sera affiché et le parcours candidat fonctionne normalement.

## Déploiement (staging / production)

### Prérequis serveur

1. **Activer le scan** via le credential Rails : `clamav.enabled: true` (voir section Configuration ci-dessus).

2. **Installer ClamAV** dans l'image Docker ou sur le serveur :

```dockerfile
RUN apt-get update && apt-get install -y clamav
RUN freshclam
```

3. **Mettre à jour les signatures** régulièrement (cron quotidien recommandé) :

```bash
0 2 * * * /usr/bin/freshclam --quiet
```

4. **Configurer le chemin** si le binaire n'est pas à `/usr/bin/clamscan` :
   - Via credential Rails : `clamav.clamscan_path`

### Vérification

```bash
# Sur le serveur, vérifier que clamscan est accessible
clamscan --version

# Tester un scan
echo "test" > /tmp/test.txt && clamscan /tmp/test.txt
```

## Architecture technique

```
Upload fichier
     │
     ▼
 ScanDocumentJob (Solid Queue)
     │
     ▼
 FileSecurityScanner
     ├── Validation taille (max configuré)
     ├── Validation extension (liste blanche)
     └── Scan antivirus
          │
          ▼
     AntivirusService
          │
          ▼
     ClamavService (via gem Clamby)
          │
          ├── OK → metadata: { scan_safe: true, scanner: "clamav" }
          ├── Malware → metadata: { scan_safe: false, scanner: "clamav" }
          └── Indisponible → metadata: { scanner: "none" }
```

### Badges affichés dans l'interface

| État | Badge | Signification |
|---|---|---|
| `scan_safe: true` | Vérifié | Fichier scanné, aucune menace détectée |
| `scan_safe: false` | Malware détecté | Fichier bloqué, ne sera pas inclus dans le dossier |
| `scanner: "none"` | Non vérifié | Antivirus indisponible, fichier accepté sans scan |
| Pas de metadata scan | Scan en cours | Scan en attente de traitement par Solid Queue |

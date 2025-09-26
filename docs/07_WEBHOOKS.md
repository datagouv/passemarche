# Webhooks - Notifications en Temps Réel

## Vue d'ensemble

Les webhooks Voie Rapide permettent aux éditeurs de recevoir des notifications en temps réel lors d'événements importants (complétion de marchés, finalisation de candidatures). Ce système garantit une synchronisation fiable et automatique entre Voie Rapide et les plateformes éditrices.

## Architecture des Webhooks

```
┌─────────────────┐    Événement     ┌─────────────────┐
│   Voie Rapide   │    Métier        │   File d'Attente│
│   Application   │ ─────────────────▶│   Webhooks      │
└─────────────────┘                  └─────────────────┘
                                              │
┌─────────────────┐    HTTP POST      ┌─────────────────┐
│   Plateforme    │ ◄────────────────── │   Processeur    │
│   Éditeur       │   + Signature HMAC │   Webhook       │
└─────────────────┘                  └─────────────────┘
                                              │
┌─────────────────┐    Retry/Circuit  ┌─────────────────┐
│   Gestion       │ ◄────────────────── │   Gestionnaire  │
│   d'Erreurs     │   Breaker         │   d'Erreurs     │
└─────────────────┘                  └─────────────────┘
```

## Configuration des Webhooks

### Configuration Éditeur

Les webhooks sont configurés par l'administrateur Voie Rapide au niveau de chaque éditeur.

### Paramètres de Configuration

| Paramètre | Description | Exemple |
|-----------|-------------|---------|
| `completion_webhook_url` | URL de réception des webhooks | `https://editeur.com/webhooks/voie-rapide` |
| `redirect_url` | URL de redirection post-complétion | `https://editeur.com/markets/{market_identifier}/status` |
| `webhook_secret` | Secret HMAC généré automatiquement | `a1b2c3d4e5f6...` |

### Variables dans les URLs

Les URLs supportent les variables suivantes :
- `{market_identifier}` : Identifiant du marché
- `{status}` : Statut de complétion (`completed`, `failed`)

## Types d'Événements

### Événement : Marché Complété

**Type** : `market.completed`

**Déclencheur** : Finalisation de la configuration d'un marché public par l'acheteur

**Payload** :
```json
{
  "event": "market.completed",
  "timestamp": "2024-06-15T14:30:45.123Z",
  "market": {
    "identifier": "VR-2024-A1B2C3D4E5F6",
    "name": "Fourniture de matériel informatique",
    "lot_name": "Lot 1 - Ordinateurs portables",
    "deadline": "2024-12-31T23:59:59.000Z",
    "market_type_codes": ["supplies", "services"],
    "completed_at": "2024-06-15T14:30:45.123Z",
    "field_keys": [
      "company_name",
      "siret",
      "legal_form",
      "turnover_year_n_minus_1",
      "turnover_year_n_minus_2",
      "turnover_year_n_minus_3",
      "employee_count",
      "certifications_iso"
    ]
  }
}
```

### Événement : Candidature Finalisée

**Type** : `market_application.completed`

**Déclencheur** : Soumission finale d'une candidature par une entreprise

**Payload** :
```json
{
  "event": "market_application.completed",
  "timestamp": "2024-06-15T16:45:30.456Z",
  "market_identifier": "VR-2024-A1B2C3D4E5F6",
  "market_application": {
    "identifier": "FT20240615A1B2C3D4",
    "siret": "12345678901234",
    "company_name": "ACME Solutions SARL",
    "completed_at": "2024-06-15T16:45:30.456Z",
    "attestation_url": "https://voie-rapide.gouv.fr/api/v1/market_applications/FT20240615A1B2C3D4/attestation",
    "documents_package_url": "https://voie-rapide.gouv.fr/api/v1/market_applications/FT20240615A1B2C3D4/documents_package"
  }
}
```

## Format des Requêtes Webhook

### En-têtes HTTP

```http
POST /webhooks/voie-rapide HTTP/1.1
Host: votre-editeur.com
Content-Type: application/json
X-Webhook-Signature-SHA256: sha256=a1b2c3d4e5f6789...
User-Agent: VoieRapide-Webhook/1.0
Content-Length: 1245
```

### Corps de la Requête

Le corps contient le payload JSON sérialisé de l'événement.

## Sécurité : Signatures HMAC

### Génération de la Signature

Chaque webhook inclut une signature HMAC-SHA256 calculée avec le secret de l'éditeur :

```
signature = HMAC-SHA256(webhook_secret, json_payload)
header_value = "sha256=" + hex(signature)
```

### Vérification Côté Récepteur

**Processus de vérification** :
1. Extraire la signature de l'en-tête `X-Webhook-Signature-SHA256`
2. Calculer la signature attendue avec HMAC-SHA256(secret, payload)
3. Comparer les signatures de manière sécurisée
4. Traiter l'événement uniquement si la signature est valide

**🔗 Scripts complets** :
- [Vérification signature HMAC (Bash)](99_SCRIPTS_REFERENCE.md#vérification-signature-hmac-bash)
- [Serveur webhook complet (Node.js)](99_SCRIPTS_REFERENCE.md#serveur-webhook-minimal-nodejs)


## Mécanisme de Retry et Gestion d'Erreurs

### Stratégie de Retry

Voie Rapide implémente un système de retry robuste avec circuit breaker :

**Configuration par défaut** :
- **Tentatives** : 3 essais maximum
- **Délais** : Backoff polynomial avec jitter (1s, 4s, 9s)
- **Timeout** : 30 secondes par tentative
- **Circuit breaker** : Suspension après 5 échecs consécutifs

### Codes de Réponse et Actions

| Code HTTP | Type | Action Voie Rapide | Description |
|-----------|------|-------------------|-------------|
| 200-299 | Succès | ✅ Marquer comme traité | Webhook délivré avec succès |
| 400, 401, 403, 404, 405, 410, 422 | Erreur client | ❌ Pas de retry | Erreur configuration côté éditeur |
| 408, 429 | Temporaire | 🔄 Retry avec délai | Timeout ou rate limiting |
| 500-599 | Erreur serveur | 🔄 Retry selon config | Problème temporaire côté éditeur |
| Timeout réseau | Réseau | 🔄 Retry selon config | Problème de connectivité |

### États de Synchronisation

| État | Description | Interface Admin |
|------|-------------|-----------------|
| `sync_pending` | En attente de traitement | 🕐 En attente |
| `sync_processing` | Webhook en cours d'envoi | 📤 Envoi en cours |
| `sync_completed` | Webhook délivré avec succès | ✅ Synchronisé |
| `sync_failed` | Tous les retries échoués | ❌ Échec - Retry disponible |

## Gestion de l'Idempotence

### Problématique

Un même webhook peut être reçu plusieurs fois en cas de :
- Retry automatique après timeout
- Problème réseau temporaire
- Redémarrage du processus de livraison

### Solution Recommandée

**Générer un ID unique** pour chaque événement :
```
event_id = event_type + timestamp + object_identifier
```

**Stratégies de déduplication** :
- Cache mémoire pour développement/test
- Redis/Memcached pour production
- Table de base de données avec TTL

**🔗 Implémentations complètes** : [Scripts de Référence - Serveur webhook](99_SCRIPTS_REFERENCE.md#serveur-webhook-minimal-nodejs)

## Monitoring et Métriques

### Métriques Recommandées

- **Taux de succès** des webhooks
- **Temps de traitement** moyen
- **Doublons détectés**
- **Erreurs par type**
- **Webhook en échec** nécessitant attention

### Endpoints de Monitoring

Exposez un endpoint `/webhooks/stats` pour surveiller :
- Nombre total de webhooks reçus/traités
- Taux de succès en pourcentage
- Temps de réponse moyens
- Distribution des erreurs

Cette documentation webhook fournit les éléments nécessaires pour une intégration robuste et sécurisée des notifications en temps réel avec Voie Rapide.
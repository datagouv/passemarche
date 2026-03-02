# Démarrage Rapide - Intégration Passe Marché

## Vue d'ensemble :&#x20;

Ce guide vous permet de réaliser votre première intégration avec l'API Passe Marché en moins de 30 minutes. Il couvre les étapes essentielles depuis l'authentification jusqu'au test complet des flux acheteur et candidat.

## Prérequis

### Enregistrement plateforme de marchés publics

Contactez l'équipe Passe Marché pour obtenir :

* `client_id` : Identifiant unique de votre plateforme
* `client_secret` : Clé secrète OAuth2
* `webhook_secret` : Secret pour vérification signatures HMAC
* URLs configurées (webhook et redirection)

### Environnement Technique

* **HTTPS** : Obligatoire en production
* **Dépendances** : Client HTTP compatible OAuth2
* **Outils requis** : curl, jq (pour les tests)
* **Données requises** : SIRET de l'organisation publique (14 chiffres) pour créer un marché

### Choix de l'environnement

Les exemples de ce guide utilisent la variable `$BASE_URL`. Choisissez l'environnement approprié :

| Environnement  | URL                                        | Usage                                     |
| -------------- | ------------------------------------------ | ----------------------------------------- |
| **Staging**    | `https://staging.passemarche.data.gouv.fr` | Tests d'intégration des plateformes de marchés publics (recommandé) |
| **Sandbox**    | `https://sandbox.passemarche.data.gouv.fr` | Réservé équipe interne (instable)         |
| **Preprod**    | `https://preprod.passemarche.data.gouv.fr` | Recette données réelles                   |
| **Production** | `https://passemarche.data.gouv.fr`         | Utilisateurs finaux                       |

```bash
# Configuration de l'environnement (staging recommandé pour débuter)
export BASE_URL="https://staging.passemarche.data.gouv.fr"
```

[**Documentation complète des environnements**](08_environnements.md)

***

## Étape 1 : Authentification OAuth2 (5 min)

```bash
# Test d'authentification
curl -X POST "${BASE_URL}/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&scope=api_access"

# Réponse attendue
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 86400,
  "scope": "api_access"
}
```

**🔗 Scripts complets** : [Scripts de Référence - Authentification](99_scripts_reference.md#authentification-oauth2)

***

## Étape 2 : Création d'un Marché Public (10 min)

```bash
# Création de marché avec token
curl -X POST "${BASE_URL}/api/v1/public_markets" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "public_market": {
      "name": "Test - Fourniture équipements informatiques",
      "lot_name": "Lot unique - Ordinateurs",
      "deadline": "2024-12-31T23:59:59Z",
      "siret": "13002526500013",
      "market_type_codes": ["supplies"]
    }
  }'

# Réponse
{
  "identifier": "VR-2024-A1B2C3D4E5F6",
  "configuration_url": "${BASE_URL}/buyer/public_markets/VR-2024-A1B2C3D4E5F6/setup"
}
```

**🔗 Script automatisé** : [Scripts de Référence - Création de marché](99_scripts_reference.md#création-de-marché---script-complet)

### Configuration Manuelle

1. **Ouvrez l'URL de configuration** dans votre navigateur
2. **Complétez les 4 étapes** : Setup, Champs obligatoires, Champs optionnels, Résumé
3. **Vérifiez la réception du webhook** (voir étape 4)

***

## Étape 3 : Création d'une Candidature (10 min)

```bash
# Création de candidature
curl -X POST "${BASE_URL}/api/v1/public_markets/VR-2024-A1B2C3D4E5F6/market_applications" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "market_application": {
      "siret": "12345678901234"
    }
  }'

# Réponse
{
  "identifier": "FT20240615A1B2C3D4",
  "application_url": "${BASE_URL}/candidate/market_applications/FT20240615A1B2C3D4/company_identification"
}
```

**🔗 Scripts automatisés** : [Scripts de Référence - Candidatures](99_scripts_reference.md#création-de-candidature)

### Soumission Manuelle

1. **Ouvrez l'URL de candidature** dans votre navigateur
2. **Remplissez les étapes dynamiques** : Identification entreprise, champs par catégorie, validation
3. **Vérifiez la génération des documents** et confirmez la soumission
4. **Confirmez la réception du webhook** (voir étape 4)

***

## Étape 4 : Réception des Webhooks (10 min)

Les webhooks notifient votre plateforme lors de la complétion des marchés ou candidatures.

**Types d'événements** :

* `market.completed` : Marché configuré et prêt
* `market_application.completed` : Candidature finalisée

**Signature HMAC** : Chaque webhook contient une signature `X-Webhook-Signature-SHA256` pour vérification.

**🔗 Serveur webhook complet** : [Scripts de Référence - Webhooks](99_scripts_reference.md#serveur-webhook-minimal-nodejs)

***

## Étape 5 : Test avec fake\_editor\_app (5 min)

L'application de démonstration `fake_editor_app` fournit un exemple complet d'intégration.

```bash
# 1. Configuration et lancement
cd fake_editor_app
bundle install
cp .env.example .env
# Éditez .env avec vos paramètres
bundle exec rackup -p 4567
```

**Test complet** :

1. Ouvrez http://localhost:4567
2. Authentification → Création marché → Configuration
3. Création candidature → Soumission → Vérification webhooks

**🔗 Détails complets** : [fake\_editor\_app/README.md](../fake_editor_app.md)

## Checklist de Démarrage

### ✅ Configuration de Base

* [ ] Identifiants OAuth2 obtenus et testés
* [ ] Variables d'environnement sécurisées
* [ ] Authentification OAuth2 fonctionnelle

### ✅ API Intégration

* [ ] Endpoint création marché testé
* [ ] Endpoint création candidature testé
* [ ] Endpoints téléchargement testés

### ✅ Webhooks

* [ ] Serveur webhook opérationnel
* [ ] Vérification signature HMAC implémentée
* [ ] Tests avec fake\_editor\_app réussis

***

## Support et Documentation Avancée

**En cas de problème** :

1. Vérifiez les logs de vos appels API et webhooks
2. Testez avec fake\_editor\_app pour isoler les problèmes
3. Consultez la documentation détaillée ci-dessous

**Documentation détaillée** :

* [Référence API](05_reference_api.md) - Spécifications complètes
* [Authentification OAuth](02_authentification_oauth.md) - Gestion des tokens
* [Webhooks](07_webhooks.md) - Notifications temps réel
* [Scripts de Référence](99_scripts_reference.md) - Utilitaires et exemples

**Flux métier** :

* [Flux Acheteur](03_flux_acheteur.md) - Configuration des marchés
* [Flux Candidat](04_flux_candidat.md) - Soumission des candidatures
* [Schémas d'Intégration](06_schemas_integration.md) - Architecture technique

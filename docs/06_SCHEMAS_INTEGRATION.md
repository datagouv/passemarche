# Schémas d'Intégration - Architecture Technique

## Vue d'ensemble

Ce document présente les schémas techniques détaillés de l'architecture d'intégration Passe Marché, incluant les flux de données, les interactions entre composants et les séquences d'appels API.

## Environnements

Les schémas utilisent `${BASE_URL}` comme placeholder. Consultez la [documentation des environnements](08_ENVIRONNEMENTS.md) pour les URLs spécifiques à chaque environnement.

---

## 1. Architecture Globale

```
                              PASSE MARCHE - ARCHITECTURE D'INTÉGRATION

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                         PLATEFORME ÉDITEUR                                              │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐                │
│  │  Interface      │   │  Gestionnaire   │   │  API Client     │   │  Webhook        │                │
│  │  Utilisateur    │   │  Marchés        │   │  OAuth2         │   │  Handler        │                │
│  │                 │   │                 │   │                 │   │                 │                │
│  └─────────────────┘   └─────────────────┘   └─────────────────┘   └─────────────────┘                │
│           │                       │                       │                       ▲                    │
└───────────┼───────────────────────┼───────────────────────┼───────────────────────┼────────────────────┘
            │                       │                       │                       │
            │                       │                       │                       │
         ┌──▼──┐                 ┌──▼──┐                 ┌──▼──┐                 ┌──┴──┐
         │     │                 │     │                 │     │                 │     │
         │ UI  │                 │ API │                 │Auth │                 │Hook │
         │     │                 │     │                 │     │                 │     │
         └──┬──┘                 └──┬──┘                 └──┬──┘                 └──▲──┘
            │                       │                       │                       │
            ▼                       ▼                       ▼                       │
┌─────────────────────────────────────────────────────────────────────────────────┼────────────────────┐
│                                     PASSE MARCHE API                              │                    │
├─────────────────────────────────────────────────────────────────────────────────┼────────────────────┤
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐         │                    │
│  │   OAuth2    │   │   Marchés   │   │ Candidatures│   │   Fichiers  │         │                    │
│  │  Endpoint   │   │  Publics    │   │             │   │ (PDF/ZIP)   │         │                    │
│  │             │   │             │   │             │   │             │         │                    │
│  └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘         │                    │
│                                                                                  │                    │
│  ┌─────────────────────────────────────────────────────────────────────────────┼────────────────┐   │
│  │                           INTERFACES UTILISATEUR                             │                │   │
│  │                                                                              │                │   │
│  │  ┌─────────────────┐                            ┌─────────────────┐          │                │   │
│  │  │   Interface     │                            │   Interface     │          │                │   │
│  │  │   Acheteur      │                            │   Candidat      │          │                │   │
│  │  │   (Wizard)      │                            │   (Formulaire)  │          │                │   │
│  │  │                 │                            │                 │          │                │   │
│  │  └─────────────────┘                            └─────────────────┘          │                │   │
│  └─────────────────────────────────────────────────────────────────────────────┼────────────────┘   │
│                                         ▲                            ▲          │                    │
└─────────────────────────────────────────┼────────────────────────────┼──────────┼────────────────────┘
                                          │                            │          │
                                          │                            │          │
                              ┌─────────────────┐            ┌─────────────────┐  │
                              │   Acheteur      │            │   Candidat      │  │
                              │   Public        │            │   Entreprise    │  │
                              │                 │            │                 │  │
                              └─────────────────┘            └─────────────────┘  │
                                                                                  │
                                                             ┌─────────────────┐  │
                                                             │   Webhook       │◄─┘
                                                             │   Système       │
                                                             │                 │
                                                             └─────────────────┘
```

---

## 2. Flux d'Authentification OAuth2

```
SÉQUENCE D'AUTHENTIFICATION OAUTH2 CLIENT CREDENTIALS

┌─────────────────┐                                  ┌─────────────────┐
│   Plateforme    │                                  │   Passe Marché  │
│   Éditeur       │                                  │   API OAuth     │
└─────────────────┘                                  └─────────────────┘
         │                                                    │
         │  1. POST /oauth/token                             │
         │     Content-Type: application/x-www-form-urlencoded│
         │     Body:                                          │
         │       grant_type=client_credentials                │
         │       client_id={client_id}                       │
         │       client_secret={client_secret}               │
         │       scope=api_access                            │
         ├───────────────────────────────────────────────────▶│
         │                                                    │
         │                                                    │ 2. Validation
         │                                                    │    - Vérif client_id/secret
         │                                                    │    - Vérif éditeur autorisé
         │                                                    │    - Vérif éditeur actif
         │                                                    │
         │  3. HTTP 200 OK                                   │
         │     Content-Type: application/json                │
         │     Body:                                          │
         │       {                                            │
         │         "access_token": "eyJ...",                 │
         │         "token_type": "Bearer",                   │
         │         "expires_in": 86400,                      │
         │         "scope": "api_access"                     │
         │       }                                            │
         │◄───────────────────────────────────────────────────┤
         │                                                    │
         │  4. Stockage token + expiration                   │
         │     Token valide 24h                              │
         │     Révocation auto ancien token                  │
         ▼                                                    │
   [Token stocké]                                            │
         │                                                    │
         │  5. Appels API ultérieurs                         │
         │     Authorization: Bearer {access_token}          │
         ├───────────────────────────────────────────────────▶│
         │                                                    │
         │  6. Réponse API                                   │
         │◄───────────────────────────────────────────────────┤
         │                                                    │

GESTION EXPIRATION TOKEN:

         │  7. Token expiré après 24h                        │
         ├───────────────────────────────────────────────────▶│
         │  HTTP 401 Unauthorized                            │
         │◄───────────────────────────────────────────────────┤
         │                                                    │
         │  8. Renouvellement automatique                    │
         │     Nouvelle requête /oauth/token                  │
         ├───────────────────────────────────────────────────▶│
         │  Nouveau token                                     │
         │◄───────────────────────────────────────────────────┤
         │                                                    │
```

---

## 3. Flux Complet Acheteur (Création et Configuration Marché)

```
SÉQUENCE COMPLÈTE FLUX ACHETEUR

┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ Plateforme  │  │ Passe Marché│  │ Interface   │  │ Acheteur    │  │ Webhook     │
│ Éditeur     │  │ API         │  │ Config      │  │ Public      │  │ Système     │
└─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘
       │                │                │                │                │
       │  1. Authentification OAuth2     │                │                │
       ├───────────────▶│                │                │                │
       │  Access Token  │                │                │                │
       │◄───────────────┤                │                │                │
       │                │                │                │                │
       │  2. POST /api/v1/public_markets │                │                │
       │     {                           │                │                │
       │       "public_market": {        │                │                │
       │         "name": "Marché IT",    │                │                │
       │         "deadline": "2024-12-31",│               │                │
       │         "siret": "13002526500013",│              │                │
       │         "market_type_codes": [  │                │                │
       │           "supplies", "services"│                │                │
       │         ]                       │                │                │
       │       }                         │                │                │
       │     }                           │                │                │
       ├───────────────▶│                │                │                │
       │                │ 3. Création   │                │                │
       │                │    Marché      │                │                │
       │                │    VR-2024-... │               │                │
       │                │                │                │                │
       │  4. HTTP 201 Created            │                │                │
       │     {                           │                │                │
       │       "identifier": "VR-2024-A1B2C3", │         │                │
       │       "configuration_url": "${BASE_URL}/buyer/  │              │
       │         .../setup"              │                │                │
       │     }                           │                │                │
       │◄───────────────┤                │                │                │
       │                │                │                │                │
       │  5. Redirection Acheteur        │                │                │
       │     vers configuration_url       │                │                │
       ├─────────────────────────────────▶│                │                │
       │                │                │  6. GET /setup │                │
       │                │                │◄──────────────┤                │
       │                │                │  Interface     │                │
       │                │                │  Étape 1       │                │
       │                │                ├───────────────▶│                │
       │                │                │                │  7. Config     │
       │                │                │                │     Defense?   │
       │                │                │                │     [Oui/Non]  │
       │                │                │  8. POST setup │◄──────────────│
       │                │                │◄──────────────┤                │
       │                │                │                │                │
       │                │                │  9. GET /required_fields       │
       │                │                │◄──────────────┤                │
       │                │                │  Interface     │                │
       │                │                │  Étape 2       │                │
       │                │                ├───────────────▶│                │
       │                │                │                │ 10. Sélection │
       │                │                │                │     Champs     │
       │                │                │                │     Obligatoires│
       │                │                │ 11. POST requi...│◄──────────────│
       │                │                │◄──────────────┤                │
       │                │                │                │                │
       │                │                │ 12. GET /additional_fields     │
       │                │                │◄──────────────┤                │
       │                │                │  Interface     │                │
       │                │                │  Étape 3       │                │
       │                │                ├───────────────▶│                │
       │                │                │                │ 13. Sélection │
       │                │                │                │     Champs     │
       │                │                │                │     Optionnels │
       │                │                │ 14. POST addi...│◄──────────────│
       │                │                │◄──────────────┤                │
       │                │                │                │                │
       │                │                │ 15. GET /summary               │
       │                │                │◄──────────────┤                │
       │                │                │  Interface     │                │
       │                │                │  Étape 4       │                │
       │                │                ├───────────────▶│                │
       │                │                │                │ 16. Validation │
       │                │                │                │     Finale     │
       │                │                │ 17. POST summa...│◄──────────────│
       │                │                │◄──────────────┤                │
       │                │ 18. Complétion │                │                │
       │                │     Marché     │                │                │
       │                │     completed_at│               │                │
       │                │     Génération │                │                │
       │                │     Field Keys │                │                │
       │                │                │                │                │
       │                │                │                │                │ 19. Webhook
       │                │                │                │                │     Job
       │                │                │                │                ├─────────────▶
       │ 20. POST {webhook_url}          │                │                │
       │     X-Webhook-Signature-SHA256  │                │                │
       │     {                           │                │                │
       │       "event": "market.completed",             │                │
       │       "timestamp": "2024-...",  │                │                │
       │       "market": {               │                │                │
       │         "identifier": "VR-...", │                │                │
       │         "field_keys": [...],    │                │                │
       │         ...                     │                │                │
       │       }                         │                │                │
       │     }                           │                │                │
       │◄────────────────────────────────────────────────────────────────┤
       │                │                │                │                │
       │ 21. HTTP 200 OK                │                │                │
       ├────────────────────────────────────────────────────────────────▶│
       │                │                │                │                │
```

---

## 4. Flux Complet Candidat (Création et Soumission Candidature)

```
SÉQUENCE COMPLÈTE FLUX CANDIDAT

┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ Plateforme  │  │ Passe Marché│  │ Interface   │  │ Candidat    │  │ Webhook +   │
│ Éditeur     │  │ API         │  │ Candidature │  │ Entreprise  │  │ Documents   │
└─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘
       │                │                │                │                │
       │  1. Token OAuth2 (déjà obtenu)  │                │                │
       │                │                │                │                │
       │  2. POST /api/v1/public_markets/{id}/market_applications       │
       │     {                           │                │                │
       │       "market_application": {   │                │                │
       │         "siret": "12345678901234" [optionnel]    │                │
       │       }                         │                │                │
       │     }                           │                │                │
       ├───────────────▶│                │                │                │
       │                │ 3. Création   │                │                │
       │                │    Application │                │                │
       │                │    FT20240615... │             │                │
       │                │                │                │                │
       │  4. HTTP 201 Created            │                │                │
       │     {                           │                │                │
       │       "identifier": "FT20240615A1B2",          │                │
       │       "application_url": "${BASE_URL}/candidate/│                │
       │         .../company_identification"             │              │
       │     }                           │                │                │
       │◄───────────────┤                │                │                │
       │                │                │                │                │
       │  5. Redirection Candidat        │                │                │
       │     vers application_url         │                │                │
       ├─────────────────────────────────▶│                │                │
       │                │                │  6. GET /company_identification │
       │                │                │◄──────────────┤                │
       │                │                │  Interface     │                │
       │                │                │  Étape 1       │                │
       │                │                ├───────────────▶│                │
       │                │                │                │  7. Saisie    │
       │                │                │                │     SIRET      │
       │                │                │                │     Nom        │
       │                │                │                │     Forme jur. │
       │                │                │  8. POST company│◄──────────────│
       │                │                │◄──────────────┤                │
       │                │                │                │                │
       │                │                │  9. GET /{categorie_1}         │
       │                │                │     (ex: capacite_economique)  │
       │                │                │◄──────────────┤                │
       │                │                │  Interface     │                │
       │                │                │  Champs        │                │
       │                │                │  Métier        │                │
       │                │                ├───────────────▶│                │
       │                │                │                │ 10. Remplissage│
       │                │                │                │     Chiffre    │
       │                │                │                │     d'Affaires │
       │                │                │                │     Effectifs  │
       │                │                │ 11. POST categ...│◄──────────────│
       │                │                │◄──────────────┤                │
       │                │                │                │                │
       │                │                │ 12. GET /{categorie_2}         │
       │                │                │     (ex: capacite_technique)   │
       │                │                │◄──────────────┤                │
       │                │                │  Interface     │                │
       │                │                ├───────────────▶│                │
       │                │                │                │ 13. Remplissage│
       │                │                │                │     Références │
       │                │                │                │     Certifs    │
       │                │                │ 14. POST categ...│◄──────────────│
       │                │                │◄──────────────┤                │
       │                │                │                │                │
       │                │                │     [Répétition pour chaque catégorie configurée]
       │                │                │                │                │
       │                │                │ 15. GET /summary               │
       │                │                │◄──────────────┤                │
       │                │                │  Récapitulatif │                │
       │                │                │  Toutes Données│                │
       │                │                ├───────────────▶│                │
       │                │                │                │ 16. Validation │
       │                │                │                │     Finale     │
       │                │                │                │     Soumission │
       │                │                │ 17. POST summa...│◄──────────────│
       │                │                │◄──────────────┤                │
       │                │ 18. Finalisation│               │                │
       │                │     Application │               │                │ 19. Génération
       │                │     completed_at│               │                │     Docs
       │                │                │                │                ├─────────────▶
       │                │                │                │                │ 20. PDF Attest.
       │                │                │                │                │ 21. ZIP Dossier
       │                │                │                │                │
       │                │                │                │                │ 22. Webhook Job
       │ 23. POST {webhook_url}          │                │                │
       │     X-Webhook-Signature-SHA256  │                │                │
       │     {                           │                │                │
       │       "event": "market_application.completed",  │                │
       │       "timestamp": "2024-...",  │                │                │
       │       "market_identifier": "VR-...",            │                │
       │       "market_application": {   │                │                │
       │         "identifier": "FT...",  │                │                │
       │         "attestation_url": "...",│               │                │
       │         "documents_package_url": "...",          │                │
       │         ...                     │                │                │
       │       }                         │                │                │
       │     }                           │                │                │
       │◄────────────────────────────────────────────────────────────────┤
       │                │                │                │                │
       │ 24. HTTP 200 OK                │                │                │
       ├────────────────────────────────────────────────────────────────▶│
       │                │                │                │                │
       │ 25. GET /api/v1/market_applications/{id}/attestation             │
       ├───────────────▶│                │                │                │
       │ PDF Binary     │                │                │                │
       │◄───────────────┤                │                │                │
       │                │                │                │                │
       │ 26. GET /api/v1/market_applications/{id}/documents_package       │
       ├───────────────▶│                │                │                │
       │ ZIP Binary     │                │                │                │
       │◄───────────────┤                │                │                │
       │                │                │                │                │
```

---

## 5. Architecture Webhook et Retry

```
SYSTÈME WEBHOOK AVEC RETRY ET CIRCUIT BREAKER

┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ Événement   │  │ File        │  │ Processeur  │  │ Plateforme  │  │ Gestionnaire│
│ Métier      │  │ d'Attente   │  │ Webhook     │  │ Éditeur     │  │ d'Erreurs   │
└─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘
       │                │                │                │                │
       │ 1. Complétion  │                │                │                │
       │    Marché/App  │                │                │                │
       ├───────────────▶│                │                │                │
       │                │ 2. Job Webhook │                │                │
       │                │    (delay=0s)  │                │                │
       │                ├───────────────▶│                │                │
       │                │                │ 3. Génération  │                │
       │                │                │    Payload     │                │
       │                │                │    + Signature │                │
       │                │                │                │                │
       │                │                │ 4. POST {url}  │                │
       │                │                │    Content-Type: application/json
       │                │                │    X-Webhook-Signature-SHA256   │
       │                │                │    Timeout: 30s │                │
       │                │                ├───────────────▶│                │
       │                │                │                │                │
       │                │                │     SUCCÈS     │                │
       │                │                │ 5. HTTP 200 OK │                │
       │                │                │◄───────────────┤                │
       │                │                │ 6. sync_completed│              │
       │                │◄───────────────┤                │                │
       │                │                │                │                │
       │                │                │     ÉCHEC      │                │
       │                │                │ 7. HTTP 500    │                │
       │                │                │    ou Timeout  │                │
       │                │                │◄───────────────┤                │
       │                │                │ 8. Erreur     │                ├─▶ RETRY 1
       │                │                ├───────────────────────────────▶│  (delay=1s)
       │                │                │                │                │
       │                │                │ 9. Job Webhook │                │◄─┘
       │                │                │    (retry=1)   │                │
       │                │                │◄───────────────────────────────┤
       │                │                │10. POST {url}  │                │
       │                │                │   (2ème essai) │                │
       │                │                ├───────────────▶│                │
       │                │                │                │                │
       │                │                │     ÉCHEC      │                │
       │                │                │11. HTTP 503    │                │
       │                │                │◄───────────────┤                │
       │                │                │12. Erreur     │                ├─▶ RETRY 2
       │                │                ├───────────────────────────────▶│  (delay=4s)
       │                │                │                │                │
       │                │                │13. Job Webhook │                │◄─┘
       │                │                │   (retry=2)    │                │
       │                │                │◄───────────────────────────────┤
       │                │                │14. POST {url}  │                │
       │                │                │   (3ème essai) │                │
       │                │                ├───────────────▶│                │
       │                │                │                │                │
       │                │                │     ÉCHEC      │                │
       │                │                │15. HTTP 404    │                │
       │                │                │◄───────────────┤                │
       │                │                │16. Erreur Final│                ├─▶ FINAL FAIL
       │                │                ├───────────────────────────────▶│  sync_failed
       │                │                │                │                │
       │                │17. sync_failed │                │                │
       │                │   (3 retries   │                │                │
       │                │   épuisés)     │                │                │
       │                │◄───────────────┤                │                │


CIRCUIT BREAKER (après 5 échecs consécutifs):

       │                │                │                │                │
       │                │18. Circuit     │                │                │
       │                │    OUVERT      │                │                │
       │                │   (5 échecs)   │                │                │
       │                ├───────────────▶│                │                │
       │                │                │19. Suspension  │                │
       │                │                │    Webhooks    │                │
       │                │                │    (30 min)    │                │
       │                │                │                │                │
       │                │                │     ...30min...│                │
       │                │                │                │                │
       │                │20. Tentative   │                │                │
       │                │    Test        │                │                │
       │                │   (1 webhook)  │                │                │
       │                ├───────────────▶│                │                │
       │                │                │21. POST test   │                │
       │                │                ├───────────────▶│                │
       │                │                │22. HTTP 200    │                │
       │                │                │◄───────────────┤                │
       │                │                │23. Circuit     │                │
       │                │                │    FERMÉ       │                │
       │                │◄───────────────┤                │                │
       │                │                │                │                │
```

---

## 6. États et Transitions du Système

```
DIAGRAMME D'ÉTATS - MARCHÉ PUBLIC

                    [Création API]
                          │
                          ▼
                ┌─────────────────┐
                │    PENDING      │◄──────────┐
                │  (Configuration)│           │
                └─────────────────┘           │
                          │                   │
                    [Finalisation]            │
                          │                   │ [Retry Sync]
                          ▼                   │
                ┌─────────────────┐           │
                │   COMPLETED     ├───────────┘
                │ (Webhook Queued)│
                └─────────────────┘
                          │
                ┌─────────┼─────────┐
                │         │         │
                ▼         ▼         ▼
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │sync_pending │ │sync_processing │ sync_completed│
    │             │ │             │ │             │
    └─────────────┘ └─────────────┘ └─────────────┘
                │         │
                │         │ [Échec]
                │         ▼
                │   ┌─────────────┐
                └──▶│sync_failed  │
                    │ (Retry Dispo)│
                    └─────────────┘


DIAGRAMME D'ÉTATS - CANDIDATURE

                    [Création API]
                          │
                          ▼
                ┌─────────────────┐
                │    PENDING      │
                │   (Saisie)      │
                └─────────────────┘
                          │
                    [Soumission]
                          │
                          ▼
                ┌─────────────────┐
                │   COMPLETED     │◄──────────┐
                │ (Docs Generated)│           │
                └─────────────────┘           │
                          │                   │
                ┌─────────┼─────────┐         │ [Retry Sync]
                │         │         │         │
                ▼         ▼         ▼         │
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │sync_pending │ │sync_processing │ sync_completed├───┘
    │             │ │             │ │             │
    └─────────────┘ └─────────────┘ └─────────────┘
                │         │
                │         │ [Échec]
                │         ▼
                │   ┌─────────────┐
                └──▶│sync_failed  │
                    │ (Retry Dispo)│
                    └─────────────┘
```

---

## 7. Matrice de Compatibilité et Limitations

```
MATRICE DE COMPATIBILITÉ API

┌─────────────────┬─────────────────┬─────────────────┬─────────────────┐
│   Composant     │   Version Min   │   Version Rec   │   Limitations   │
├─────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ OAuth2 Client   │ RFC 6749        │ RFC 6749 + PKCE│ Client Cred seul│
├─────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ HTTP Client     │ HTTP/1.1        │ HTTP/2          │ TLS 1.2+ requis │
├─────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ JSON Parser     │ RFC 7159        │ RFC 8259        │ UTF-8 seulement │
├─────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ Webhook HMAC    │ SHA-256         │ SHA-256         │ Pas d'autres    │
├─────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ Date Format     │ ISO 8601        │ ISO 8601 + TZ  │ UTC préféré     │
└─────────────────┴─────────────────┴─────────────────┴─────────────────┘

LIMITES DE TAUX (Rate Limiting)

┌─────────────────┬─────────────────┬─────────────────┬─────────────────┐
│   Endpoint      │   Limite/Heure  │   Burst Max     │   Reset Window  │
├─────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ /oauth/token    │       60        │       10        │    60 minutes   │
├─────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ API générale    │      1000       │       50        │    60 minutes   │
├─────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ Téléchargements │      100        │       10        │    60 minutes   │
├─────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ Webhooks reçus  │     Illimité    │      N/A        │      N/A        │
└─────────────────┴─────────────────┴─────────────────┴─────────────────┘

TAILLES MAXIMALES

┌─────────────────┬─────────────────┬─────────────────┬─────────────────┐
│   Type Données  │   Taille Max    │   Format        │   Contraintes   │
├─────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ Payload JSON    │      10 MB      │    JSON UTF-8   │ Struct validée  │
├─────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ Champ texte     │   255 caractères│    UTF-8        │ Pas HTML/JS     │
├─────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ PDF Attestation │      50 MB      │    PDF/A-1      │ Signature incluse│
├─────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ ZIP Dossier     │     500 MB      │    ZIP standard │ Pas d'exécutables│
└─────────────────┴─────────────────┴─────────────────┴─────────────────┘
```

---

## 8. Schémas de Données JSON

### Schéma de Création de Marché Public

Le payload pour créer un marché public doit respecter la structure suivante :

```json
{
  "public_market": {
    "name": {
      "type": "string",
      "maxLength": 255,
      "description": "Nom du marché public",
      "required": true
    },
    "deadline": {
      "type": "string",
      "format": "date-time",
      "description": "Date limite de candidature (ISO 8601)",
      "required": true
    },
    "siret": {
      "type": "string",
      "pattern": "^\\d{14}$",
      "description": "SIRET de l'organisation publique",
      "required": true
    },
    "market_type_codes": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": ["supplies", "services", "works", "defense"]
      },
      "minItems": 1,
      "description": "Types de marché (defense ne peut pas être seul)",
      "required": true
    },
    "lot_name": {
      "type": "string",
      "maxLength": 255,
      "description": "Nom du lot spécifique",
      "required": false
    }
  }
}
```

**Note sur les diagrammes de séquence** : Les diagrammes de flux acheteur et candidat ci-dessus reflètent déjà l'inclusion du SIRET dans les requêtes de création de marché. Aucune mise à jour visuelle des diagrammes n'est nécessaire.

---

## 9. Checklist d'Intégration

```
CHECKLIST TECHNIQUE D'INTÉGRATION

┌─────────────────────────────────────────────────────────────────────────────┐
│                              AUTHENTIFICATION                               │
├─────────────────────────────────────────────────────────────────────────────┤
│ ☐ Client OAuth2 implémenté (Client Credentials)                           │
│ ☐ Gestion expiration token (24h) avec renouvellement automatique          │
│ ☐ Stockage sécurisé des credentials (variables d'environnement)           │
│ ☐ Gestion erreurs auth (401, 403) avec retry approprié                    │
│ ☐ Test authentification avec credentials de test                          │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                              API MARCHÉS PUBLICS                            │
├─────────────────────────────────────────────────────────────────────────────┤
│ ☐ Endpoint création marché (POST /api/v1/public_markets)                  │
│ ☐ Validation locale des données avant envoi API                           │
│ ☐ Gestion erreurs validation (422) avec messages utilisateur              │
│ ☐ Redirection utilisateur vers configuration_url                          │
│ ☐ Interface de suivi des marchés créés                                    │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                              API CANDIDATURES                               │
├─────────────────────────────────────────────────────────────────────────────┤
│ ☐ Endpoint création candidature (POST /api/v1/.../market_applications)    │
│ ☐ Gestion SIRET optionnel à la création                                   │
│ ☐ Redirection utilisateur vers application_url                            │
│ ☐ Endpoints téléchargement (attestation + dossier)                        │
│ ☐ Gestion erreurs téléchargement (404, 422)                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                                WEBHOOKS                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│ ☐ Endpoint réception webhook (POST /webhooks/passemarche)                 │
│ ☐ Vérification signature HMAC-SHA256 obligatoire                          │
│ ☐ Parsing JSON payload avec gestion erreurs                               │
│ ☐ Gestion idempotence (détection doublons)                                │
│ ☐ Handlers pour market.completed et market_application.completed          │
│ ☐ Réponses HTTP appropriées (200, 401, 500)                               │
│ ☐ Logging des événements reçus                                            │
│ ☐ Tests avec payloads d'exemple                                           │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                              SÉCURITÉ                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│ ☐ HTTPS obligatoire en production                                          │
│ ☐ Validation certificats SSL/TLS                                          │
│ ☐ Pas d'exposition des secrets côté client                                │
│ ☐ Timeouts appropriés (30s standard, 5min téléchargements)                │
│ ☐ Rate limiting côté client respecté                                      │
│ ☐ Logs sécurisés (pas de secrets loggués)                                 │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                              MONITORING                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│ ☐ Métriques authentifications (succès/échecs)                             │
│ ☐ Métriques appels API (latence, erreurs)                                 │
│ ☐ Métriques webhooks (reçus, traités, échoués)                           │
│ ☐ Alertes sur échecs répétés                                              │
│ ☐ Dashboard de surveillance                                               │
│ ☐ Health checks pour les endpoints critiques                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                              TESTS                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│ ☐ Tests unitaires pour clients API                                        │
│ ☐ Tests d'intégration avec fake_editor_app                               │
│ ☐ Tests de charge sur endpoints critiques                                 │
│ ☐ Tests de sécurité (signatures, timeouts)                               │
│ ☐ Tests de résilience (retry, circuit breaker simulation)                │
│ ☐ Validation avec environnement de recette                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

Ces schémas techniques fournissent une vision complète de l'architecture d'intégration Passe Marché et servent de référence pour l'implémentation et le debugging des intégrations éditeurs.

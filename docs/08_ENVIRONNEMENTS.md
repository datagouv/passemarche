# Environnements Passe Marché

Ce document décrit les différents environnements disponibles pour l'intégration avec Passe Marché, leurs URLs, et leurs cas d'usage.

## Vue d'ensemble

| Environnement | Passe Marché URL | Fake Editor URL | Données API | Accès |
|---------------|------------------|-----------------|-------------|-------|
| **Sandbox** | `sandbox.passemarche.data.gouv.fr` | `sandbox.editeur.passemarche.data.gouv.fr` | Simulées | Interne (instable) |
| **Staging** | `staging.passemarche.data.gouv.fr` | `staging.editeur.passemarche.data.gouv.fr` | Simulées | Public |
| **Preprod** | `preprod.passemarche.data.gouv.fr` | `preprod.editeur.passemarche.data.gouv.fr` | Réelles | Sécurisé |
| **Production** | `passemarche.data.gouv.fr` | `editeur.passemarche.data.gouv.fr` | Réelles | Sécurisé |

---

## Sandbox

**Cas d'usage** : Tests d'intégration internes de l'équipe Passe Marché

> **Attention** : Cet environnement est réservé aux tests internes de l'équipe Passe Marché. Il n'est **pas stable** et peut être réinitialisé, modifié ou indisponible à tout moment. **Les éditeurs externes ne doivent pas utiliser cet environnement.**

### URLs

| Service | URL |
|---------|-----|
| Application Passe Marché | https://sandbox.passemarche.data.gouv.fr |
| Fake Editor (démo) | https://sandbox.editeur.passemarche.data.gouv.fr |
| API OAuth | https://sandbox.passemarche.data.gouv.fr/oauth/token |
| API v1 | https://sandbox.passemarche.data.gouv.fr/api/v1 |

### Caractéristiques

- **Données API** : Toutes les données provenant des APIs externes sont **simulées**
- **Accès** : Réservé à l'équipe Passe Marché
- **Utilisation** : Tests d'intégration internes, développement de nouvelles features
- **Stabilité** : **Environnement instable** - peut être réinitialisé ou modifié sans préavis

### Exemple d'authentification

```bash
curl -X POST https://sandbox.passemarche.data.gouv.fr/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&scope=api_access"
```

---

## Staging

**Cas d'usage** : Intégration des éditeurs partenaires

### URLs

| Service | URL |
|---------|-----|
| Application Passe Marché | https://staging.passemarche.data.gouv.fr |
| Fake Editor (démo) | https://staging.editeur.passemarche.data.gouv.fr |
| API OAuth | https://staging.passemarche.data.gouv.fr/oauth/token |
| API v1 | https://staging.passemarche.data.gouv.fr/api/v1 |

### Caractéristiques

- **Données API** : Toutes les données provenant des APIs externes sont **simulées**
- **Accès** : Public, destiné aux éditeurs pour leurs tests d'intégration
- **Utilisation** : Tests d'intégration éditeurs, validation des flux OAuth
- **Stabilité** : Plus stable que sandbox, versionné avec les releases

### Recommandations pour les éditeurs

1. Utilisez cet environnement pour développer votre intégration
2. Testez tous les flux (création marché, candidature, webhooks)
3. Validez la signature HMAC des webhooks
4. Testez les cas d'erreur et les timeouts

---

## Preprod

**Cas d'usage** : Tests de recette avec données réelles

### URLs

| Service | URL |
|---------|-----|
| Application Passe Marché | https://preprod.passemarche.data.gouv.fr |
| Fake Editor (démo) | https://preprod.editeur.passemarche.data.gouv.fr |
| API OAuth | https://preprod.passemarche.data.gouv.fr/oauth/token |
| API v1 | https://preprod.passemarche.data.gouv.fr/api/v1 |

### Caractéristiques

- **Données API** : Données **réelles** provenant des APIs gouvernementales
- **Accès** : **Sécurisé** - accès restreint aux éditeurs autorisés
- **Utilisation** : Tests de recette finaux avant mise en production
- **Stabilité** : Environnement iso-production

### Points d'attention

- Les données récupérées sont des données réelles d'entreprises
- Les credentials OAuth sont spécifiques à cet environnement
- La configuration webhook doit pointer vers un endpoint sécurisé
- Environnement utilisé pour la formation des éditeurs

---

## Production

**Cas d'usage** : Environnement de production pour les utilisateurs finaux

### URLs

| Service | URL |
|---------|-----|
| Application Passe Marché | https://passemarche.data.gouv.fr |
| Fake Editor (démo) | https://editeur.passemarche.data.gouv.fr |
| API OAuth | https://passemarche.data.gouv.fr/oauth/token |
| API v1 | https://passemarche.data.gouv.fr/api/v1 |

### Caractéristiques

- **Données API** : Données **réelles** provenant des APIs gouvernementales
- **Accès** : **Sécurisé** - réservé aux éditeurs validés en production
- **Utilisation** : Utilisation réelle par les acheteurs publics et candidats
- **Stabilité** : Haute disponibilité, SLA garanti

### Exigences pour la mise en production

- Validation complète sur l'environnement preprod
- Credentials OAuth de production obtenus auprès de l'équipe Passe Marché
- Endpoint webhook en HTTPS avec certificat valide
- Monitoring et alerting configurés côté éditeur

---

## Configuration par environnement

### Variables d'environnement recommandées

```bash
# Sandbox
export PASSEMARCHE_URL=https://sandbox.passemarche.data.gouv.fr
export PASSEMARCHE_CLIENT_ID=your_sandbox_client_id
export PASSEMARCHE_CLIENT_SECRET=your_sandbox_client_secret
export PASSEMARCHE_WEBHOOK_SECRET=your_sandbox_webhook_secret

# Staging
export PASSEMARCHE_URL=https://staging.passemarche.data.gouv.fr
export PASSEMARCHE_CLIENT_ID=your_staging_client_id
export PASSEMARCHE_CLIENT_SECRET=your_staging_client_secret
export PASSEMARCHE_WEBHOOK_SECRET=your_staging_webhook_secret

# Preprod
export PASSEMARCHE_URL=https://preprod.passemarche.data.gouv.fr
export PASSEMARCHE_CLIENT_ID=your_preprod_client_id
export PASSEMARCHE_CLIENT_SECRET=your_preprod_client_secret
export PASSEMARCHE_WEBHOOK_SECRET=your_preprod_webhook_secret

# Production
export PASSEMARCHE_URL=https://passemarche.data.gouv.fr
export PASSEMARCHE_CLIENT_ID=your_production_client_id
export PASSEMARCHE_CLIENT_SECRET=your_production_client_secret
export PASSEMARCHE_WEBHOOK_SECRET=your_production_webhook_secret
```

### Exemple de configuration dynamique

```bash
#!/bin/bash
# Script d'authentification multi-environnement

ENV="${1:-sandbox}"

case "$ENV" in
  sandbox)
    BASE_URL="https://sandbox.passemarche.data.gouv.fr"
    ;;
  staging)
    BASE_URL="https://staging.passemarche.data.gouv.fr"
    ;;
  preprod)
    BASE_URL="https://preprod.passemarche.data.gouv.fr"
    ;;
  production)
    BASE_URL="https://passemarche.data.gouv.fr"
    ;;
  *)
    echo "Environnement inconnu: $ENV"
    exit 1
    ;;
esac

# Authentification
TOKEN=$(curl -s -X POST "${BASE_URL}/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=${PASSEMARCHE_CLIENT_ID}&client_secret=${PASSEMARCHE_CLIENT_SECRET}&scope=api_access" \
  | jq -r '.access_token')

echo "Token obtenu pour $ENV: ${TOKEN:0:20}..."
```

---

## Flux de déploiement recommandé

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Sandbox   │ ──► │   Staging   │ ──► │   Preprod   │ ──► │ Production  │
│             │     │             │     │             │     │             │
│ Tests       │     │ Intégration │     │ Recette     │     │ Utilisateurs│
│ internes    │     │ éditeurs    │     │ données     │     │ finaux      │
│             │     │             │     │ réelles     │     │             │
│ Données     │     │ Données     │     │ Données     │     │ Données     │
│ simulées    │     │ simulées    │     │ réelles     │     │ réelles     │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

### Checklist de migration entre environnements

#### De Staging vers Preprod

- [ ] Tous les tests d'intégration passent sur staging
- [ ] Credentials preprod obtenus auprès de l'équipe Passe Marché
- [ ] Endpoint webhook HTTPS configuré et testé
- [ ] Configuration des variables d'environnement preprod

#### De Preprod vers Production

- [ ] Tests de recette validés avec données réelles
- [ ] Credentials production obtenus et sécurisés
- [ ] Monitoring et alerting en place
- [ ] Procédure de rollback documentée
- [ ] Support technique identifié

---

## Support

Pour obtenir des credentials pour chaque environnement ou en cas de problème :

1. **Sandbox/Staging** : Environnements publics, credentials de test disponibles
2. **Preprod** : Contactez l'équipe Passe Marché pour obtenir un accès
3. **Production** : Validation requise avant mise en production

**Contact** : Équipe Passe Marché via les canaux officiels

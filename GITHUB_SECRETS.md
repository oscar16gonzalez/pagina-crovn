# 🔐 Secretos requeridos en GitHub

Para que el CI/CD funcione (GitHub Actions → Vercel), configura estos **Secrets** en cada repositorio:
`Repo → Settings → Secrets and variables → Actions → New repository secret`

## Secretos comunes (ambos repos)

| Secreto | Valor | Dónde conseguirlo |
|---|---|---|
| `VERCEL_TOKEN` | Token de Vercel | Vercel Dashboard → Settings → Tokens → Create |
| `VERCEL_ORG_ID` | `team_G2pasSaJ6QEJ1GHVTUFGEcQ9` | ID del team "oscar16gonzalez's projects" |
| `VERCEL_TEAM` | `oscar16gonzalezs-projects` | Slug del team |

## Secretos del BACKEND (`crovn_tienda_virtual_back`)

| Secreto | Valor |
|---|---|
| `VERCEL_PROJECT_ID_BACKEND` | `prj_i832qpBCQqxVZKjVAFG3agfGVRlN` |
| `DATABASE_URL` | `postgres://avnadmin:***REDACTED***@pg-3a346d5d-crovn0315-8b4a.l.aivencloud.com:14721/defaultdb?sslmode=require` |
| `SMTP_HOST` | `smtp.gmail.com` |
| `SMTP_PORT` | `587` |
| `SMTP_USER` | `crovn0315@gmail.com` |
| `SMTP_PASS` | `dzyf vsjm hrih xiny` |
| `SMTP_FROM` | `crovn0315@gmail.com` |
| `NOTIFY_EMAIL` | `johamg168@gmail.com` |

## Secretos del FRONTEND (`crovn_tienda_virtual_front`)

| Secreto | Valor |
|---|---|
| `VERCEL_PROJECT_ID_FRONTEND` | `prj_0oBBHShvRN9H5NfNOt2SmzEl7Xvb` |
| `VITE_API_URL` | `https://crovn-backend.vercel.app` |

---

## Cómo crear el VERCEL_TOKEN

1. Ve a https://vercel.com/account/tokens
2. Clic en **Create Token**
3. Nombre: `github-actions-crovn`
4. Copia el token y pégalo como secreto `VERCEL_TOKEN` en ambos repos

## Flujo del CI/CD

```
Push a master ──▶ check/build ──▶ deploy a Vercel (producción)
                                     │
                                     ▼
                            https://crovn-backend.vercel.app
                            https://crovn-frontend.vercel.app
```

Cada push a `master` despliega automáticamente a producción.

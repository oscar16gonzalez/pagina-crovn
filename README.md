# 🛍️ CROVN — Panel de Administración

Sistema completo para una tienda de ropa urbana colombiana: **landing pública** con carrito y checkout, y **panel de administración** con inventario (variantes), clientes, pedidos, promociones, publicaciones y proveedores.

<div align="center">

**Stack:** React 18 + Vite + Tailwind · Express + Prisma + PostgreSQL (Aiven) · Nodemailer · WhatsApp Cloud API

🌐 **En vivo (gratis):**
<br>🛍️ Tienda: **https://crovn-frontend.vercel.app**
<br>⚙️ API: **https://crovn-backend.vercel.app**
<br>🗄️ DB: **Aiven PostgreSQL** (tier gratuito)

</div>

---

## 🚀 Despliegue en la nube (gratis)

La app está desplegada 100% gratis:

| Componente | Servicio | URL | Costo |
|---|---|---|---|
| Frontend (React/Vite estático) | **Vercel** | https://crovn-frontend.vercel.app | Gratis (Hobby) |
| Backend (Express/Node) | **Vercel** | https://crovn-backend.vercel.app | Gratis (Hobby) |
| Base de datos PostgreSQL | **Aiven** | pg-3a346d5d... | Gratis (Free tier) |

### CI/CD (GitHub Actions)
Cada push a `master` despliega automáticamente a producción:

```
Push a master ──▶ check/build ──▶ deploy a Vercel (producción)
```

**Repositorios:**
- 🔧 Backend: https://github.com/oscar16gonzalez/crovn_tienda_virtual_back
- 🛍️ Frontend: https://github.com/oscar16gonzalez/crovn_tienda_virtual_front

**Workflows** (`.github/workflows/deploy.yml` en cada repo):
- Job 1 `check/build`: instala dependencias, genera cliente Prisma, valida schema
- Job 2 `deploy`: instala Vercel CLI, genera `.env` con secretos, ejecuta `vercel deploy --prod`

**Secretos en GitHub** (Settings → Secrets and variables → Actions):
Ver `GITHUB_SECRETS.md` para la lista completa (VERCEL_TOKEN, DATABASE_URL, SMTP_*, etc.)

### Para re-deployar manual
```bash
# Backend
cd backend
vercel --prod

# Frontend
cd frontend
vercel --prod
```

### Variables de entorno en Vercel
Ya están configuradas en el proyecto Vercel (production):
- `DATABASE_URL` → conexión Aiven PostgreSQL
- `SMTP_*` → correo de confirmación
- `VITE_API_URL` → `https://crovn-backend.vercel.app` (frontend)

### DB local vs nube
- **Nube (Aiven):** PostgreSQL, `DATABASE_URL` en `.env.production`
- **Local (PostgreSQL Docker):** contenedor `postgres-local`, `DATABASE_URL="postgresql://crovn:crovn123@localhost:5432/crovn"`

---

## 📑 Índice

1. [Características](#-características)
2. [Arquitectura](#-arquitectura)
3. [Requisitos previos](#-requisitos-previos)
4. [Instalación y ejecución](#-instalación-y-ejecución)
5. [Configuración (`.env`)](#-configuración-env)
6. [Credenciales de acceso](#-credenciales-de-acceso)
7. [Estructura del proyecto](#-estructura-del-proyecto)
8. [Base de datos (Modelos Prisma)](#-base-de-datos-modelos-prisma)
9. [Cambios de modelo (Migrations)](#-cambios-de-modelo-migrations)
10. [API — Endpoints](#-api--endpoints)
11. [Frontend — Vistas y componentes](#-frontend--vistas-y-componentes)
12. [Lógica de negocio](#-lógica-de-negocio)
13. [Colección de Postman](#-colección-de-postman)
14. [Despliegue en la nube + CI/CD](#-despliegue-en-la-nube--cicd)
15. [Despliegue con ngrok (temporal)](#-despliegue-con-ngrok-temporal)
16. [Notas y escalabilidad](#-notas-y-escalabilidad)

---

## ✅ Características

### 🛍️ Landing pública (`#/tienda`)
- Catálogo de camisetas con animaciones
- Carrusel de **publicaciones** (colecciones / noticias / ofertas) con layout responsive
- Detalle de producto: galería de imágenes, tallas × colores, cantidad
- Carrito con descuentos (código promocional **o** oferta)
- Checkout: crea cliente + pedido, descuenta stock, envía **email de confirmación**
- **Consulta de pedido** pública (`#/consulta`) por email + número, con barra de progreso
- **Chatbot** con bienvenida, búsqueda de productos y consulta de pedidos (estado real desde la API)
- Botón flotante de WhatsApp
- Moneda **COP** (peso colombiano), locale `es-CO`

### 🔐 Panel de administración (`#/admin`)
- Login de admins (superadmin / admin) con token HMAC firmado (12h)
- **Dashboard**: ingresos totales (solo ventas aprobadas), pedidos por estado, top productos
- **Inventario**: CRUD de productos con **variantes** (tallas × colores), cada una con stock y SKU propios; imágenes ilimitadas (Base64)
- **Clientes**: CRUD, badge VIP (solo visual, sin descuento automático), envío de códigos
- **Pedidos**: cambio de estado (envía email al cliente), anulación solo para Pendiente/Procesado
- **Códigos promocionales**: crear/generar/activar/eliminar, enviar por email, validación pública
- **Publicaciones**: colecciones/noticias/ofertas con imagen, fechas, producto asociado, link externo y descuento % (solo ofertas)
- **Proveedores**: CRUD de proveedores; **costo, % ganancia y valor comercial son individuales por producto**
- **Calculadora de precios**: varía costo, % de ganancia y precio objetivo; tabla de variación rápida

---

## 🏗️ Arquitectura

```
┌─────────────────────┐         ┌─────────────────────┐
│   FRONTEND (React)  │  /api   │   BACKEND (Express) │
│   Vercel (estático) │ ──────▶ │   Vercel (Node)     │
│   - Landing         │         │   - Auth (HMAC)     │
│   - Admin panel     │         │   - Shop (público)  │
│   - Chatbot         │         │   - CRUD admin      │
└─────────────────────┘         └──────────┬──────────┘
                                            │ Prisma ORM
                                     ┌──────▼──────┐
                                     │  MySQL      │
                                     │  (Docker)   │
                                     │  db: crovn  │
                                     └─────────────┘
                                            │
                              ┌─────────────┼─────────────┐
                              ▼             ▼             ▼
                         Nodemailer    WhatsApp      (Base64
                         (SMTP)        Cloud API      en DB)
```

- **Frontend**: React + Vite + Tailwind. Proxy `/api` → `http://localhost:4000`. Enrutamiento por hash (`#/tienda`, `#/consulta`, `#/admin`).
- **Backend**: Express + Prisma. Tokens HMAC firmados (no JWT). Imágenes como Base64 en `TEXT`.
- **DB**: PostgreSQL (Aiven en la nube / Docker `postgres-local` en local).

---

## 📋 Requisitos previos

| Herramienta | Versión |
|---|---|
| Node.js | ≥ 18 |
| npm | ≥ 9 |
| Docker (para PostgreSQL local) | ≥ 20 |
| ngrok (opcional) | última |

---

## 🚀 Instalación y ejecución local

### 1. Clonar e instalar dependencias

```bash
# Backend
cd pagina_crovn/backend
npm install

# Frontend
cd ../frontend
npm install
```

### 2. Levantar PostgreSQL en Docker (local)

```bash
docker run -d \
  --name postgres-local \
  -e POSTGRES_USER=crovn \
  -e POSTGRES_PASSWORD=crovn123 \
  -e POSTGRES_DB=crovn \
  -p 5432:5432 \
  postgres:16
```

> Si ya existe el contenedor: `docker start postgres-local`
> **Credenciales local:** usuario `crovn` / contraseña `crovn123` / DB `crovn` / puerto `5432`

### 3. Configurar variables de entorno (`.env`)

Copia `backend/.env.example` a `backend/.env` y ajusta. Para **desarrollo local** usa:

```env
# PostgreSQL LOCAL (Docker postgres-local)
DATABASE_URL="postgresql://crovn:crovn123@localhost:5432/crovn"

PORT=4000
NODE_ENV=development

# Correo (SMTP) — Gmail: usa "contraseña de aplicación"
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=crovn0315@gmail.com
SMTP_PASS=dzyf vsjm hrih xiny
SMTP_FROM=crovn0315@gmail.com
NOTIFY_EMAIL=johamg168@gmail.com

# WhatsApp (opcional, deja vacío para usar wa.me)
WHATSAPP_BUSINESS_NUMBER=3128502119
WHATSAPP_COUNTRY=57
```

> **Producción (Aiven):** usa `DATABASE_URL` de Aiven (ver `.env.production`).

### 4. Sincronizar la base de datos (Prisma migrations)

```bash
cd ../backend
npx prisma generate          # genera el cliente Prisma
npx prisma migrate deploy    # aplica las migrations (crea tablas)
```

### 5. (Opcional) Sembrar datos de prueba

El seed crea 9 camisetas, 3 clientes y 2 admins:

```bash
npm run db:seed
```

### 6. Ejecutar Backend y Frontend

**Terminal 1 — Backend:**
```bash
cd pagina_crovn/backend
npm run dev        # node --watch (recarga automática) → http://localhost:4000
# o: npm start     # producción
```

**Terminal 2 — Frontend:**
```bash
cd pagina_crovn/frontend
npm run dev        # Vite → http://localhost:5173 (proxy /api → :4000)
```

### 🌐 URLs locales
- 🛍️ Tienda: http://localhost:5173
- 🔐 Admin: http://localhost:5173/#/admin
- ⚙️ API: http://localhost:4000/api

### 🔄 Cambiar entre DB local y producción

Solo cambia `DATABASE_URL` en `backend/.env`:
- **Local:** `postgresql://crovn:crovn123@localhost:5432/crovn`
- **Producción (Aiven):** `postgresql://avnadmin:...@pg-...aivencloud.com/defaultdb?sslmode=require`

> ⚠️ **Ojo:** si apuntas a Aiven, los cambios locales afectan la DB de producción.
npm run dev        # Vite dev server en :5173
```

### 6. Abrir la aplicación

| Vista | URL |
|---|---|
| 🛍️ Landing pública | http://localhost:5173/#/tienda |
| 📦 Consultar pedido | http://localhost:5173/#/consulta |
| 🔐 Panel admin | http://localhost:5173/#/admin |

---

## ⚙️ Configuración (`.env`)

Copia `backend/.env.example` a `backend/.env` y ajusta:

```env
# Base de datos
# Local (PostgreSQL Docker "postgres-local"):
DATABASE_URL="postgresql://crovn:crovn123@localhost:5432/crovn"
# Nube (Aiven PostgreSQL, despliegue):
# DATABASE_URL="postgresql://avnadmin:pass@pg-xxx.aivencloud.com/defaultdb?sslmode=require"

# Puerto del servidor
PORT=4000

# Entorno: development | production
NODE_ENV=development

# WhatsApp (Cloud API de Meta) — deja vacío para usar wa.me
WHATSAPP_TOKEN=
WHATSAPP_PHONE_ID=
WHATSAPP_BUSINESS_NUMBER=3128502119
WHATSAPP_COUNTRY=57

# Correo (SMTP) — Gmail: usa "contraseña de aplicación", no tu clave normal
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=crovn0315@gmail.com
SMTP_PASS=dzyf vsjm hrih xiny
SMTP_FROM=crovn0315@gmail.com
NOTIFY_EMAIL=johamg168@gmail.com

# URL pública del sitio (para links en el correo)
SITE_URL=http://localhost:5173
```

---

## 🔑 Credenciales de acceso

| Usuario | Contraseña | Rol |
|---|---|---|
| `oscar` | `12345` | **superadmin** |
| `johana` | `12345` | admin |

> El token de sesión expira en 12 horas.

---

## 📁 Estructura del proyecto

```
pagina_crovn/
├── backend/
│   ├── prisma/
│   │   └── schema.prisma          # Modelos de BD (12 tablas)
│   ├── src/
│   │   ├── index.js               # Servidor Express (rutas, middleware)
│   │   ├── config.js              # Configuración (puerto, uploads)
│   │   ├── prisma.js              # Cliente Prisma
│   │   ├── middleware/
│   │   │   ├── auth.js            # requireAuth (token HMAC)
│   │   │   ├── errorHandler.js    # Manejo centralizado de errores
│   │   │   └── upload.js          # Multer (imágenes → Base64)
│   │   ├── routes/
│   │   │   ├── auth.js            # Login, me, change-password
│   │   │   ├── shop.js            # Público: catálogo, checkout, lookup
│   │   │   ├── products.js        # CRUD + variantes + stock
│   │   │   ├── customers.js       # CRUD clientes
│   │   │   ├── orders.js          # CRUD + cambio de estado
│   │   │   ├── promoCodes.js      # CRUD + generate + send
│   │   │   ├── publications.js    # CRUD + toggle
│   │   │   ├── suppliers.js       # CRUD + apply pricing
│   │   │   └── categories.js      # CRUD categorías
│   │   ├── services/
│   │   │   ├── email.js           # Nodemailer (pedido, promo, estado)
│   │   │   └── whatsapp.js        # Cloud API / wa.me
│   │   └── utils/
│   │       └── responses.js       # success / errorResponse
│   ├── .env
│   └── package.json
├── frontend/
│   ├── src/
│   │   ├── App.jsx                # Hash routing + AdminShell
│   │   ├── api.js                 # Cliente API + formatCLP
│   │   ├── context/AuthContext.jsx# Estado de auth (login/logout)
│   │   ├── components/
│   │   │   ├── Sidebar.jsx        # Responsive (hamburguesa en móvil)
│   │   │   ├── Topbar.jsx         # Barra superior
│   │   │   ├── Modal.jsx          # Modal, ConfirmModal, EmptyState
│   │   │   └── CategoriesManager.jsx
│   │   └── pages/
│   │       ├── ShopPage.jsx       # Landing (pública) + chatbot
│   │       ├── OrderLookupPage.jsx# Consulta de pedido (pública)
│   │       ├── LoginPage.jsx      # Login admin
│   │       ├── DashboardPage.jsx  # Panel
│   │       ├── InventoryPage.jsx  # Productos + variantes
│   │       ├── CustomersPage.jsx  # Clientes
│   │       ├── OrdersPage.jsx     # Pedidos
│   │       ├── PromoCodesPage.jsx # Códigos promocionales
│   │       ├── PublicationsPage.jsx# Colecciones/noticias/ofertas
│   │       └── SuppliersPage.jsx  # Proveedores + calculadora
│   ├── vite.config.js             # host: true, allowedHosts: true
│   └── package.json
├── CROVN-API-postman.json         # Colección de Postman
└── README.md
```

---

## 🗄️ Base de datos (Modelos Prisma)

Las tablas se crean con `npx prisma migrate deploy`. Modelos en `backend/prisma/schema.prisma`:

| Modelo | Descripción | Campos clave |
|---|---|---|
| `AdminUser` | Administradores | username, password (SHA-256+salt), role |
| `Category` | Categorías | name (único) |
| `Customer` | Clientes | name, email (único), isVIP |
| `PromoCode` | Códigos de descuento | code, discountPct, maxUses, usedCount, expiresAt |
| `Publication` | Colecciones/noticias/ofertas | title, type, image, link, productId, discountPct, publishedAt, expiresAt |
| `Product` | Productos | sku, name, category, **supplierId**, **costPrice**, **profitPct**, price, stock, image |
| `ProductVariant` | Variantes (talla×color) | productId, size, color, stock, sku (único por producto) |
| `ProductImage` | Imágenes extra | productId, image (Base64), position |
| `Supplier` | Proveedores | name, contact, phone, email, address, notes, active |
| `Order` | Pedidos | customerId, total, discount, promoCode, status |
| `OrderItem` | Items del pedido | orderId, productId, quantity, price (snapshot) |

> **Nota:** los campos `costPrice` y `profitPct` están en `Product` (por producto), no en `Supplier`. Cada producto tiene su propio costo y porcentaje de ganancia.

---

## 🔄 Cambios de modelo (Migrations)

El proyecto usa **migrations formales** (historial en `backend/prisma/migrations/`). Esto permite que el CI/CD aplique los cambios a la DB de producción automáticamente.

### Para agregar un campo o tabla nueva

```bash
cd backend

# 1. Edita prisma/schema.prisma (agrega campo o modelo)

# 2. Crea la migration (genera SQL + aplica a tu DB local)
npx prisma migrate dev --name describe_tu_cambio
# Ejemplo: npx prisma migrate dev --name add_product_brand

# 3. Commit + push (la CI/CD aplica la migration a Aiven automáticamente)
git add -A
git commit -m "feat: agregar campo brand a Product"
git push origin master
```

### ¿Qué sucede en producción (Aiven)?

```
Push a master
   │
   ├──▶ check   (prisma validate)
   ├──▶ migrate (prisma migrate deploy → aplica la migration a Aiven)  ← NUEVO
   └──▶ deploy  (vercel deploy --prod)
```

**La CI/CD aplica las migrations automáticamente** antes de desplegar. No necesitas ejecutar nada manualmente en producción.

### Comandos útiles

| Comando | Descripción |
|---|---|
| `npx prisma migrate dev --name X` | Crear migration (dev, aplica a local) |
| `npx prisma migrate deploy` | Aplicar migrations pendientes (producción) |
| `npx prisma migrate status` | Ver migrations pendientes |
| `npx prisma migrate resolve --applied X` | Marcar migration como aplicada (baseline) |
| `npx prisma studio` | Editor visual de la DB |

> ⚠️ **Nunca** edites archivos de `prisma/migrations/` manualmente. Siempre usa `prisma migrate dev`.

---

## 🔌 API — Endpoints

**Base URL:** `http://localhost:4000`
**Auth:** `Authorization: Bearer <token>` (obtenido en `POST /api/auth/login`)

### 🔐 Auth
| Método | Endpoint | Auth | Descripción |
|---|---|---|---|
| POST | `/api/auth/login` | — | Login (retorna token HMAC) |
| GET | `/api/auth/me` | ✅ | Sesión actual |
| POST | `/api/auth/change-password` | ✅ | Cambiar contraseña |

### 🛍️ Shop (público)
| Método | Endpoint | Descripción |
|---|---|---|
| GET | `/api/shop` | Catálogo completo (landing) |
| GET | `/api/shop/products` | Productos con filtros (category, size, q, lowStock) |
| POST | `/api/shop/checkout` | Crear pedido (cliente + items + promoCode) |
| GET | `/api/shop/orders/lookup` | Consultar pedido (email + orderId) |
| GET | `/api/shop/orders/by-email` | Historial por email |

### 📦 Productos (admin)
| Método | Endpoint | Descripción |
|---|---|---|
| GET | `/api/products` | Listar (filtros: category, q, lowStock) |
| GET | `/api/products/meta` | Categorías, tallas, colores |
| GET | `/api/products/:id` | Detalle |
| POST | `/api/products` | Crear (form-data, con variantes) |
| PUT | `/api/products/:id` | Actualizar (form-data) |
| DELETE | `/api/products/:id` | Eliminar |
| PATCH | `/api/products/:id/stock` | Ajustar stock (add/subtract/set) |
| DELETE | `/api/products/:id/images/:imageId` | Eliminar imagen extra |

### 👥 Clientes · 📦 Pedidos · 🎟️ Promos · 📰 Publicaciones · 🏭 Proveedores · 🏷️ Categorías

Ver la **colección de Postman** (`CROVN-API-postman.json`) para la documentación completa con ejemplos de cada endpoint, incluyendo:
- Clientes: CRUD + búsqueda
- Pedidos: CRUD + cambio de estado (email) + anulación
- Códigos promocionales: CRUD + generate + send + validate (público)
- Publicaciones: CRUD + toggle + active (público)
- Proveedores: CRUD + apply pricing
- Categorías: listar + crear + eliminar

---

## 🖥️ Frontend — Vistas y componentes

### Enrutamiento por hash
| Hash | Vista | Acceso |
|---|---|---|
| `#/tienda` o `#/` | ShopPage (landing) | Público |
| `#/consulta` | OrderLookupPage | Público |
| `#/admin` | Panel admin | Protegido (login) |

### Componentes principales
- **App.jsx**: `AdminShell` con hash routing, `VIEWS` (mapa de vistas), toasts, responsive layout
- **Sidebar.jsx**: fijo en desktop (`w-64`), deslizable en móvil (botón hamburguesa + overlay)
- **Topbar.jsx**: título de vista, fecha, estado del sistema, usuario, refresh, logout
- **Modal.jsx**: `Modal`, `ConfirmModal`, `EmptyState`, `Spinner`
- **api.js**: cliente HTTP + `formatCLP` (COP, es-CO)

### Responsive
- Layout admin: sidebar oculto en móvil con toggle; contenido con `px-3 sm:px-4 lg:px-8`
- Tablas: `overflow-x-auto` con `min-w` para scroll horizontal en móvil
- Grids: `grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4`
- Modales: `max-h-[90vh]` con scroll interno

---

## 💡 Lógica de negocio

### Descuentos en checkout (solo una fuente aplica)
1. **Oferta** (publicación tipo `oferta`): descuenta del `unitPrice` del producto asociado
2. **Código promocional**: descuenta del subtotal (prioridad sobre la oferta si ambos existen)
- No se acumulan: si hay código promocional, este tiene prioridad

### VIP (badge solamente)
- Se marca cuando el cliente tiene **3+ pedidos** o **300k+ COP** gastado
- Es solo visual; **no** otorga descuento automático

### Proveedores y precios
- Cada **producto** tiene `costPrice` (val proveedor), `profitPct` (% ganancia) y `price` (valor comercial)
- `price = costPrice × (1 + profitPct/100)`
- El proveedor en sí solo guarda datos de contacto
- `POST /api/suppliers/:id/apply` recalcula el precio de todos los productos del proveedor que tengan costo definido

### Estados de pedido
- `Pendiente` → `Procesado` → `Enviado` → `Entregado` (o `Anulado`)
- El cambio de estado envía **email** al cliente
- Solo se puede **anular** un pedido `Pendiente` o `Procesado`
- **Ingresos totales** del dashboard suma solo `Procesado` + `Enviado` + `Entregado`

### Emails (Nodemailer)
- **Confirmación de pedido** al cliente en el checkout
- **Cambio de estado** al cliente
- **Código promocional** al enviar a un cliente

---

## 📚 Colección de Postman

El archivo **`CROVN-API-postman.json`** contiene todos los endpoints organizados por carpetas:

- 🔐 Auth
- 🛍️ Shop (público)
- 📦 Productos (admin)
- 👥 Clientes (admin)
- 📦 Pedidos (admin)
- 🎟️ Códigos promocionales (admin)
- 📰 Publicaciones (admin)
- 🏭 Proveedores (admin)
- 🏷️ Categorías (admin)

**Variables de colección:**
- `baseUrl` = `http://localhost:4000`
- `token` = se guarda automáticamente al ejecutar el **Login** (test Postman)

**Para usar:**
1. Importa `CROVN-API-postman.json` en Postman
2. Ejecuta `Login (obtener token)` — el token se guarda automáticamente
3. El resto de endpoints protegidos usan `{{token}}` en el header `Authorization`

---

## 🌐 Despliegue con ngrok (temporal)

Para exponer la app rápido (ej: pruebas en otro dispositivo). **Es temporal**: se cae al cerrar ngrok o la PC. Para despliegue permanente usa Vercel (ver arriba).

```bash
# Terminal 1: backend
cd backend && npm run dev

# Terminal 2: frontend
cd frontend && npm run dev

# Terminal 3: ngrok (expone el frontend)
ngrok http 5173
```

El `vite.config.js` tiene `host: true` y `allowedHosts: true` para aceptar el host de ngrok.

> Actualiza `SITE_URL` en `.env` con la URL de ngrok para los links del correo.

---

## 📝 Notas y escalabilidad

- **Imágenes**: se almacenan como Base64 en `TEXT`. Para producción con muchas imágenes, migra a **S3 / Cloudinary** y guarda solo la URL.
- **Sesiones**: tokens HMAC firmados (no JWT), expiran en 12h.
- **Seguridad**: en producción, usa HTTPS, variables de entorno secretas y restringe CORS al dominio real.
- **WhatsApp**: si `WHATSAPP_TOKEN` está vacío, se abre `wa.me/<número>` con el mensaje pre-escrito.
- **Chatbot**: lógica 100% en frontend; consulta la API pública de pedidos para mostrar el estado real.

---

<div align="center">

**CROVN** · Panel v1.0 · Moda streetwear con estilo 🖤❤️🤍

</div>

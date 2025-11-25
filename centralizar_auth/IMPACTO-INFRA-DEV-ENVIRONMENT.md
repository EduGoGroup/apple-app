# 🔍 ANÁLISIS DE IMPACTO: INFRAESTRUCTURA Y DEV-ENVIRONMENT
## Evaluación de la Centralización de Autenticación en api-admin

**Fecha**: 24 de Noviembre, 2025  
**Proyecto**: EduGo - Ecosistema de Autenticación  
**Objetivo**: Evaluar impacto en edugo-infrastructure y edugo-dev-environment

---

## 📊 RESUMEN EJECUTIVO

### Hallazgo Principal
✅ **Los proyectos NO se ven negativamente afectados**. De hecho, la arquitectura actual YA ESTÁ PARCIALMENTE CENTRALIZADA a nivel de base de datos.

### Conclusión
La centralización de autenticación en api-admin es un paso natural que completa lo que ya está parcialmente implementado a nivel de infraestructura.

---

## 🏗️ SITUACIÓN ACTUAL

### 1. edugo-infrastructure (Gestión de Tablas)

**Rol Actual**: Define y gestiona todas las tablas de autenticación centralmente.

```
edugo-infrastructure/postgres/migrations/
├── structure/
│   ├── 001_create_users.sql            # Tabla de usuarios
│   ├── 009_create_refresh_tokens.sql   # Tokens de sesión
│   └── 010_create_login_attempts.sql   # Rate limiting
└── testing/
    └── 001_demo_users.sql              # 8 usuarios de prueba
```

**Tablas de Autenticación**:

```sql
-- Tabla users (compartida por todas las APIs)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Tabla refresh_tokens (usada por api-mobile y api-admin)
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    user_id UUID NOT NULL REFERENCES users(id),
    client_info JSONB,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    revoked_at TIMESTAMPTZ,
    replaced_by UUID REFERENCES refresh_tokens(id)
);

-- Tabla login_attempts (auditoría compartida)
CREATE TABLE login_attempts (
    id SERIAL PRIMARY KEY,
    identifier VARCHAR(255) NOT NULL,
    attempt_type VARCHAR(50) NOT NULL,
    successful BOOLEAN DEFAULT false,
    user_agent TEXT,
    ip_address VARCHAR(45),
    attempted_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2. edugo-dev-environment (Orquestación Local)

**Rol Actual**: Orquesta el ambiente de desarrollo con Docker Compose.

```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:16-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: edugo
      POSTGRES_USER: edugo_user
      POSTGRES_PASSWORD: edugo_password

  migrator:
    build: ./migrator
    depends_on:
      - postgres
    environment:
      MIGRATIONS_PATH: /infrastructure/postgres/migrations
    volumes:
      - ../edugo-infrastructure:/infrastructure:ro

  api-mobile:
    depends_on:
      - migrator
    # Usa las tablas creadas por infrastructure

  api-admin:
    depends_on:
      - migrator
    # Usa las mismas tablas
```

**Flujo de Inicialización**:
1. PostgreSQL inicia
2. Migrator ejecuta scripts de infrastructure
3. Se crean tablas centralizadas
4. Se insertan 8 usuarios demo
5. APIs conectan a la BD compartida

### 3. Usuarios Demo Pre-cargados

**Ubicación**: `/edugo-infrastructure/postgres/migrations/testing/001_demo_users.sql`

```sql
-- 8 usuarios con contraseña: edugo2024
INSERT INTO users (email, password_hash, first_name, last_name, role, is_active, email_verified) VALUES
('admin@edugo.test', '$2a$10$...', 'Admin', 'Demo', 'admin', true, true),
('teacher.math@edugo.test', '$2a$10$...', 'María', 'González', 'teacher', true, true),
('teacher.science@edugo.test', '$2a$10$...', 'Carlos', 'Rodríguez', 'teacher', true, true),
('student1@edugo.test', '$2a$10$...', 'Ana', 'Martínez', 'student', true, true),
('student2@edugo.test', '$2a$10$...', 'Luis', 'García', 'student', true, true),
('student3@edugo.test', '$2a$10$...', 'Sofia', 'López', 'student', true, true),
('guardian1@edugo.test', '$2a$10$...', 'Pedro', 'Martínez', 'guardian', true, true),
('guardian2@edugo.test', '$2a$10$...', 'Carmen', 'García', 'guardian', true, true);
```

---

## 🎯 IMPACTO DE LA CENTRALIZACIÓN

### ✅ Lo que NO cambia

1. **Estructura de tablas**: Permanece idéntica
2. **Migraciones SQL**: Sin cambios
3. **Usuarios demo**: Siguen funcionando igual
4. **Docker Compose**: Misma configuración
5. **Proceso de inicialización**: Idéntico

### 🔄 Lo que cambia (mejoras)

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Inserción de usuarios** | api-mobile y api-admin duplican lógica | Solo api-admin inserta |
| **Cambio de password** | Cada API implementa su endpoint | Solo api-admin lo gestiona |
| **Validación de tokens** | Cada API valida localmente | api-admin valida para todos |
| **JWT Secret** | Diferente en cada API | Unificado en api-admin |
| **Issuer** | "edugo-mobile" vs "edugo-admin" | "edugo-central" |

---

## 📝 CAMBIOS REQUERIDOS

### edugo-infrastructure ✅
**Impacto**: NINGUNO

```bash
# No requiere cambios
# Las tablas ya están centralizadas y funcionan perfectamente
```

### edugo-dev-environment ✅
**Impacto**: MÍNIMO

```bash
# 1. Actualizar variables de entorno en .env.example
JWT_SECRET_UNIFIED=your-unified-secret-min-32-chars

# 2. Actualizar docker-compose.yml (opcional)
# Agregar la variable unificada a los servicios
```

### api-admin 🔧
**Impacto**: MODERADO (pero positivo)

```go
// Nuevos endpoints para gestión centralizada
POST   /v1/auth/verify          // Verificar tokens para otros servicios
POST   /v1/users                // Crear usuarios (admin only)
PUT    /v1/users/:id/password   // Cambiar contraseña
DELETE /v1/users/:id            // Soft delete
```

### api-mobile 🔧
**Impacto**: MODERADO (simplificación)

```go
// Eliminar:
- Lógica de inserción de usuarios
- Lógica de cambio de password
- Validación local de JWT

// Agregar:
+ AuthClient para consultar api-admin
+ RemoteAuthMiddleware
```

---

## 🔄 FLUJO DE DATOS ACTUALIZADO

### Antes (Descentralizado)
```
Usuario nuevo
    ├─> api-mobile → INSERT INTO users
    └─> api-admin  → INSERT INTO users (duplicado)

Cambio de password
    ├─> api-mobile → UPDATE users SET password_hash
    └─> api-admin  → UPDATE users SET password_hash
```

### Después (Centralizado)
```
Usuario nuevo
    └─> api-admin → INSERT INTO users
        └─> Disponible para api-mobile (lectura)

Cambio de password
    └─> api-admin → UPDATE users SET password_hash
        └─> Token renovado automáticamente
```

---

## 📊 ANÁLISIS DE RIESGOS

### Riesgos Identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| Scripts de seed rotos | Baja | Bajo | Ya están vacíos, no se usan |
| Migraciones incompatibles | Nula | Alto | No se modifican migraciones |
| Usuarios demo no funcionan | Nula | Medio | Siguen igual, sin cambios |
| Docker compose falla | Baja | Alto | Testing exhaustivo |

### Evaluación Global
- **Riesgo Total**: BAJO ✅
- **Beneficio**: ALTO ✅
- **Recomendación**: PROCEDER ✅

---

## 🚀 PLAN DE IMPLEMENTACIÓN

### Fase 0: Análisis (COMPLETADO ✅)
- [x] Analizar estructura de infrastructure
- [x] Revisar dev-environment
- [x] Identificar dependencias
- [x] Evaluar impacto

### Fase 1: Preparación (1 día)
- [ ] Backup de base de datos
- [ ] Documentar estado actual
- [ ] Preparar rollback plan

### Fase 2: Unificación de Secrets (1 día)
```bash
# En todos los .env
JWT_SECRET_UNIFIED=production-secret-min-32-chars
JWT_ISSUER=edugo-central
```

### Fase 3: api-admin como Auth Central (3 días)
- [ ] Implementar `/v1/auth/verify`
- [ ] Agregar endpoints de gestión de usuarios
- [ ] Tests unitarios e integración

### Fase 4: Migración api-mobile (2 días)
- [ ] Implementar AuthClient
- [ ] Eliminar código duplicado
- [ ] Tests de integración

### Fase 5: Validación (1 día)
- [ ] Test end-to-end completo
- [ ] Verificar usuarios demo
- [ ] Performance testing

---

## 📈 MÉTRICAS DE ÉXITO

### Indicadores Clave

| Métrica | Objetivo | Cómo Medir |
|---------|----------|------------|
| Usuarios demo funcionan | 100% | Login test automatizado |
| Migraciones ejecutan | 100% | Docker compose logs |
| Seeds cargan | N/A | No aplica (vacíos) |
| APIs conectan a BD | 100% | Health checks |
| Tokens intercambiables | 100% | Test cross-API |

---

## 🎯 CONCLUSIÓN Y RECOMENDACIONES

### Conclusión Principal
**La infraestructura actual YA ESTÁ DISEÑADA para autenticación centralizada**. Las tablas están en infrastructure, compartidas por todas las APIs. Solo falta completar la centralización a nivel de lógica de negocio.

### Recomendaciones

1. **PROCEDER con la centralización** ✅
   - Riesgo mínimo
   - Beneficio alto
   - Arquitectura ya preparada

2. **Mantener infrastructure sin cambios** ✅
   - Las tablas están bien diseñadas
   - Las migraciones funcionan
   - Los índices son óptimos

3. **Actualizar solo la lógica de negocio** ✅
   - api-admin como servicio central
   - api-mobile como consumidor
   - worker valida contra api-admin

4. **Aprovechar usuarios demo existentes** ✅
   - 8 usuarios ya configurados
   - Contraseña conocida: edugo2024
   - Perfectos para testing

### Beneficios Adicionales Descubiertos

- 🎯 **Consistencia total**: Una sola fuente de verdad para usuarios
- 🔒 **Seguridad mejorada**: Políticas de password centralizadas
- 📊 **Auditoría completa**: Todos los cambios en un lugar
- 🚀 **Desarrollo más rápido**: No duplicar lógica de usuarios
- 🧪 **Testing simplificado**: Un solo lugar para probar auth

---

## 📎 ANEXOS

### Scripts Útiles Encontrados

```bash
# Generar nuevo password hash (en dev-environment)
./scripts/generate-password.sh "nueva-contraseña"

# Conectar a PostgreSQL local
docker exec -it edugo-postgres psql -U edugo_user -d edugo

# Ver usuarios actuales
SELECT email, role, is_active FROM users;

# Ver tokens activos
SELECT u.email, COUNT(rt.id) as active_tokens 
FROM users u 
LEFT JOIN refresh_tokens rt ON u.id = rt.user_id 
WHERE rt.revoked_at IS NULL 
GROUP BY u.email;
```

### Archivos Clave para Referencia

```
# Estructura de tablas
/edugo-infrastructure/postgres/migrations/structure/001_create_users.sql
/edugo-infrastructure/postgres/migrations/structure/009_create_refresh_tokens.sql
/edugo-infrastructure/postgres/migrations/structure/010_create_login_attempts.sql

# Datos de prueba
/edugo-infrastructure/postgres/migrations/testing/001_demo_users.sql

# Orquestación
/edugo-dev-environment/docker/docker-compose.yml
/edugo-dev-environment/.env.example

# Documentación existente
/edugo-api-administracion/docs/AUTH_GUIDE.md
```

---

**Documento preparado por**: Claude + Jhoan Medina  
**Fecha**: 24 de Noviembre, 2025  
**Estado**: ✅ Análisis completo - Impacto mínimo identificado  
**Decisión recomendada**: PROCEDER con la centralización
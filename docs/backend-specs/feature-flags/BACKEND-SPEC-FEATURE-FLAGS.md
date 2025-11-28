# Backend Specification: Feature Flags API

**Proyecto**: EduGo API Administración  
**Feature**: Sistema de Feature Flags  
**Versión**: 1.0  
**Fecha**: 2025-11-28  
**Cliente**: Apple App (iOS/iPadOS/macOS/visionOS)

---

## 📋 Resumen Ejecutivo

Esta especificación define el **endpoint de Feature Flags** que debe implementarse en `edugo-api-administracion` para soportar el control remoto de características en la aplicación Apple.

### Objetivos

1. **Control Remoto**: Habilitar/deshabilitar features sin desplegar nueva versión de la app
2. **Segmentación**: Permitir control por usuario, rol, versión de app
3. **Experimentación**: Facilitar A/B testing y rollout gradual
4. **Kill Switch**: Capacidad de deshabilitar features con problemas inmediatamente

### Stack Tecnológico Backend

- **Lenguaje**: Go 1.23+
- **Framework**: Echo v4
- **Base de Datos**: PostgreSQL 16
- **ORM**: GORM v2
- **Auth**: JWT (existing)
- **Caché**: Redis (opcional, Phase 2)

---

## 🎯 Funcionalidad Requerida

### Casos de Uso

| ID | Caso de Uso | Prioridad | Fase |
|----|-------------|-----------|------|
| UC-001 | Obtener feature flags globales | P0 - Crítico | Phase 1 |
| UC-002 | Obtener feature flags por usuario | P1 - Alta | Phase 1 |
| UC-003 | Admin: Crear/actualizar feature flags | P1 - Alta | Phase 2 |
| UC-004 | Admin: Listar todos los feature flags | P1 - Alta | Phase 2 |
| UC-005 | Admin: Segmentar por versión/build | P2 - Media | Phase 3 |
| UC-006 | Admin: A/B testing por porcentaje | P2 - Media | Phase 3 |

---

## 📐 Diseño de Base de Datos

### Tabla: `feature_flags`

```sql
CREATE TABLE feature_flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Identificación
    key VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Estado
    enabled BOOLEAN NOT NULL DEFAULT false,
    enabled_globally BOOLEAN NOT NULL DEFAULT false,
    
    -- Metadata
    category VARCHAR(50),
    priority INTEGER NOT NULL DEFAULT 0,
    
    -- Restricciones
    minimum_app_version VARCHAR(20),
    minimum_build_number INTEGER,
    maximum_app_version VARCHAR(20),
    maximum_build_number INTEGER,
    
    -- Segmentación (Phase 2)
    enabled_for_roles JSONB DEFAULT '[]',
    enabled_for_user_ids JSONB DEFAULT '[]',
    disabled_for_user_ids JSONB DEFAULT '[]',
    
    -- A/B Testing (Phase 3)
    rollout_percentage INTEGER DEFAULT 100 CHECK (rollout_percentage >= 0 AND rollout_percentage <= 100),
    
    -- Flags de control
    is_experimental BOOLEAN NOT NULL DEFAULT false,
    requires_restart BOOLEAN NOT NULL DEFAULT false,
    is_debug_only BOOLEAN NOT NULL DEFAULT false,
    affects_security BOOLEAN NOT NULL DEFAULT false,
    
    -- Auditoría
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Índices
    CONSTRAINT valid_rollout CHECK (
        rollout_percentage >= 0 AND rollout_percentage <= 100
    ),
    CONSTRAINT valid_build_numbers CHECK (
        minimum_build_number IS NULL OR maximum_build_number IS NULL 
        OR minimum_build_number <= maximum_build_number
    )
);

-- Índices
CREATE INDEX idx_feature_flags_key ON feature_flags(key);
CREATE INDEX idx_feature_flags_enabled ON feature_flags(enabled);
CREATE INDEX idx_feature_flags_category ON feature_flags(category);
CREATE INDEX idx_feature_flags_updated_at ON feature_flags(updated_at);

-- Trigger para updated_at
CREATE TRIGGER update_feature_flags_updated_at
    BEFORE UPDATE ON feature_flags
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

### Tabla: `feature_flag_overrides` (Phase 2 - Opcional)

```sql
-- Sobrescrituras específicas por usuario
CREATE TABLE feature_flag_overrides (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    feature_flag_id UUID NOT NULL REFERENCES feature_flags(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    enabled BOOLEAN NOT NULL,
    reason TEXT,
    expires_at TIMESTAMP,
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    
    UNIQUE(feature_flag_id, user_id)
);

CREATE INDEX idx_ff_overrides_user ON feature_flag_overrides(user_id);
CREATE INDEX idx_ff_overrides_flag ON feature_flag_overrides(feature_flag_id);
```

---

## 🔌 API Endpoints

### Phase 1: Endpoints Esenciales

#### 1. GET `/api/v1/feature-flags` - Obtener Feature Flags

**Descripción**: Retorna los feature flags aplicables al usuario actual.

**Auth**: Requiere JWT Token

**Query Parameters**:

| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `app_version` | string | No | Versión de la app (ej: "1.2.0") |
| `build_number` | integer | No | Build number de la app |
| `platform` | string | No | Plataforma (ios, ipados, macos, visionos) |

**Request Example**:
```http
GET /api/v1/feature-flags?app_version=1.0.0&build_number=42&platform=ios
Authorization: Bearer <jwt_token>
```

**Response Success (200 OK)**:
```json
{
  "success": true,
  "data": {
    "flags": [
      {
        "key": "biometric_login",
        "enabled": true,
        "metadata": {
          "requires_restart": false,
          "is_experimental": false,
          "priority": 100
        }
      },
      {
        "key": "new_dashboard",
        "enabled": false,
        "metadata": {
          "requires_restart": false,
          "is_experimental": true,
          "priority": 10
        }
      },
      {
        "key": "offline_mode",
        "enabled": true,
        "metadata": {
          "requires_restart": false,
          "is_experimental": false,
          "priority": 50
        }
      }
    ],
    "sync_metadata": {
      "server_timestamp": "2025-11-28T10:30:00Z",
      "cache_ttl_seconds": 3600,
      "total_flags": 11
    }
  },
  "timestamp": "2025-11-28T10:30:00Z"
}
```

**Response Error (401 Unauthorized)**:
```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Token inválido o expirado"
  },
  "timestamp": "2025-11-28T10:30:00Z"
}
```

**Lógica de Evaluación**:

1. **Filtro por build_number**: Si el flag tiene `minimum_build_number`, verificar que el build del cliente sea >= mínimo
2. **Filtro por app_version**: Si el flag tiene `minimum_app_version`, verificar compatibilidad semántica
3. **Filtro por debug_only**: Si `is_debug_only = true` y el cliente es producción, excluir
4. **Filtro por rol**: Si `enabled_for_roles` está definido, verificar que el rol del usuario esté incluido
5. **Override por usuario**: Si existe un override específico para el usuario, usar ese valor
6. **Valor global**: Usar `enabled` del flag

**Pseudo-código Evaluación**:
```go
func EvaluateFlag(flag FeatureFlag, user User, appVersion string, buildNumber int) bool {
    // 1. Check build number
    if flag.MinimumBuildNumber != nil && buildNumber < *flag.MinimumBuildNumber {
        return false
    }
    
    // 2. Check debug only
    if flag.IsDebugOnly && !isDebugBuild(buildNumber) {
        return false
    }
    
    // 3. Check user override
    if override := getOverride(flag.ID, user.ID); override != nil {
        if override.ExpiresAt == nil || time.Now().Before(*override.ExpiresAt) {
            return override.Enabled
        }
    }
    
    // 4. Check role segmentation
    if len(flag.EnabledForRoles) > 0 {
        if !contains(flag.EnabledForRoles, user.Role) {
            return false
        }
    }
    
    // 5. Check user blacklist
    if contains(flag.DisabledForUserIDs, user.ID) {
        return false
    }
    
    // 6. Check user whitelist
    if len(flag.EnabledForUserIDs) > 0 {
        return contains(flag.EnabledForUserIDs, user.ID)
    }
    
    // 7. Check rollout percentage (Phase 3)
    if flag.RolloutPercentage < 100 {
        return isInRollout(user.ID, flag.RolloutPercentage)
    }
    
    // 8. Default: global enabled
    return flag.Enabled
}
```

---

### Phase 2: Endpoints de Administración

#### 2. GET `/api/v1/admin/feature-flags` - Listar Todos (Admin)

**Descripción**: Lista todos los feature flags con filtros.

**Auth**: Requiere JWT Token + Role ADMIN

**Query Parameters**:

| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `category` | string | No | Filtrar por categoría |
| `enabled` | boolean | No | Filtrar por estado |
| `page` | integer | No | Página (default: 1) |
| `limit` | integer | No | Límite (default: 50, max: 100) |

**Response Success (200 OK)**:
```json
{
  "success": true,
  "data": {
    "flags": [
      {
        "id": "uuid-v4",
        "key": "biometric_login",
        "name": "Login Biométrico",
        "description": "Habilita Face ID/Touch ID",
        "enabled": true,
        "enabled_globally": true,
        "category": "security",
        "priority": 100,
        "minimum_build_number": null,
        "enabled_for_roles": [],
        "rollout_percentage": 100,
        "is_experimental": false,
        "requires_restart": false,
        "is_debug_only": false,
        "affects_security": true,
        "created_at": "2025-11-01T10:00:00Z",
        "updated_at": "2025-11-28T10:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 50,
      "total_items": 11,
      "total_pages": 1
    }
  },
  "timestamp": "2025-11-28T10:30:00Z"
}
```

#### 3. POST `/api/v1/admin/feature-flags` - Crear Feature Flag (Admin)

**Descripción**: Crea un nuevo feature flag.

**Auth**: Requiere JWT Token + Role ADMIN

**Request Body**:
```json
{
  "key": "new_chat_feature",
  "name": "Chat en Tiempo Real",
  "description": "Habilita chat entre estudiantes y profesores",
  "enabled": false,
  "enabled_globally": false,
  "category": "features",
  "priority": 30,
  "minimum_build_number": 50,
  "is_experimental": true,
  "requires_restart": false
}
```

**Response Success (201 Created)**:
```json
{
  "success": true,
  "data": {
    "id": "uuid-v4",
    "key": "new_chat_feature",
    "name": "Chat en Tiempo Real",
    "enabled": false,
    "created_at": "2025-11-28T10:30:00Z"
  },
  "timestamp": "2025-11-28T10:30:00Z"
}
```

**Response Error (409 Conflict)**:
```json
{
  "success": false,
  "error": {
    "code": "DUPLICATE_KEY",
    "message": "Ya existe un feature flag con el key 'new_chat_feature'"
  },
  "timestamp": "2025-11-28T10:30:00Z"
}
```

#### 4. PATCH `/api/v1/admin/feature-flags/:key` - Actualizar Feature Flag (Admin)

**Descripción**: Actualiza un feature flag existente.

**Auth**: Requiere JWT Token + Role ADMIN

**Request Body** (campos opcionales):
```json
{
  "enabled": true,
  "rollout_percentage": 25,
  "enabled_for_roles": ["teacher", "admin"]
}
```

**Response Success (200 OK)**:
```json
{
  "success": true,
  "data": {
    "key": "new_chat_feature",
    "enabled": true,
    "rollout_percentage": 25,
    "updated_at": "2025-11-28T10:35:00Z"
  },
  "timestamp": "2025-11-28T10:35:00Z"
}
```

#### 5. DELETE `/api/v1/admin/feature-flags/:key` - Eliminar Feature Flag (Admin)

**Descripción**: Elimina un feature flag (soft delete recomendado).

**Auth**: Requiere JWT Token + Role ADMIN

**Response Success (204 No Content)**

---

## 📊 Modelos de Datos (Go Structs)

### Domain Entity

```go
// internal/domain/entities/feature_flag.go
package entities

import (
    "time"
    "github.com/google/uuid"
)

type FeatureFlag struct {
    ID               uuid.UUID  `json:"id"`
    Key              string     `json:"key"`
    Name             string     `json:"name"`
    Description      string     `json:"description"`
    Enabled          bool       `json:"enabled"`
    EnabledGlobally  bool       `json:"enabled_globally"`
    Category         string     `json:"category"`
    Priority         int        `json:"priority"`
    
    // Versioning
    MinimumAppVersion    *string `json:"minimum_app_version,omitempty"`
    MinimumBuildNumber   *int    `json:"minimum_build_number,omitempty"`
    MaximumAppVersion    *string `json:"maximum_app_version,omitempty"`
    MaximumBuildNumber   *int    `json:"maximum_build_number,omitempty"`
    
    // Segmentation
    EnabledForRoles      []string    `json:"enabled_for_roles"`
    EnabledForUserIDs    []uuid.UUID `json:"enabled_for_user_ids"`
    DisabledForUserIDs   []uuid.UUID `json:"disabled_for_user_ids"`
    
    // A/B Testing
    RolloutPercentage int `json:"rollout_percentage"`
    
    // Flags
    IsExperimental   bool `json:"is_experimental"`
    RequiresRestart  bool `json:"requires_restart"`
    IsDebugOnly      bool `json:"is_debug_only"`
    AffectsSecurity  bool `json:"affects_security"`
    
    // Audit
    CreatedAt time.Time  `json:"created_at"`
    UpdatedAt time.Time  `json:"updated_at"`
    CreatedBy *uuid.UUID `json:"created_by,omitempty"`
    UpdatedBy *uuid.UUID `json:"updated_by,omitempty"`
}
```

### DTOs

```go
// internal/application/dtos/feature_flag_dto.go
package dtos

// Response para el cliente mobile
type FeatureFlagClientResponse struct {
    Key      string                 `json:"key"`
    Enabled  bool                   `json:"enabled"`
    Metadata FeatureFlagMetadata    `json:"metadata"`
}

type FeatureFlagMetadata struct {
    RequiresRestart bool `json:"requires_restart"`
    IsExperimental  bool `json:"is_experimental"`
    Priority        int  `json:"priority"`
}

type FeatureFlagsResponse struct {
    Flags        []FeatureFlagClientResponse `json:"flags"`
    SyncMetadata SyncMetadata                `json:"sync_metadata"`
}

type SyncMetadata struct {
    ServerTimestamp  time.Time `json:"server_timestamp"`
    CacheTTLSeconds  int       `json:"cache_ttl_seconds"`
    TotalFlags       int       `json:"total_flags"`
}

// Request para crear/actualizar (admin)
type CreateFeatureFlagRequest struct {
    Key                string   `json:"key" validate:"required,max=100"`
    Name               string   `json:"name" validate:"required,max=255"`
    Description        string   `json:"description"`
    Enabled            bool     `json:"enabled"`
    Category           string   `json:"category" validate:"max=50"`
    Priority           int      `json:"priority"`
    MinimumBuildNumber *int     `json:"minimum_build_number,omitempty"`
    IsExperimental     bool     `json:"is_experimental"`
    RequiresRestart    bool     `json:"requires_restart"`
}

type UpdateFeatureFlagRequest struct {
    Enabled           *bool     `json:"enabled,omitempty"`
    EnabledGlobally   *bool     `json:"enabled_globally,omitempty"`
    RolloutPercentage *int      `json:"rollout_percentage,omitempty" validate:"omitempty,min=0,max=100"`
    EnabledForRoles   []string  `json:"enabled_for_roles,omitempty"`
}
```

---

## 🔒 Seguridad y Permisos

### Roles Requeridos

| Endpoint | Rol Requerido | Notas |
|----------|---------------|-------|
| GET `/api/v1/feature-flags` | Cualquier usuario autenticado | - |
| GET `/api/v1/admin/feature-flags` | ADMIN | - |
| POST `/api/v1/admin/feature-flags` | ADMIN | Auditar creación |
| PATCH `/api/v1/admin/feature-flags/:key` | ADMIN | Auditar cambios |
| DELETE `/api/v1/admin/feature-flags/:key` | ADMIN | Soft delete preferido |

### Validaciones de Seguridad

1. **Rate Limiting**: Máximo 100 requests/minuto por usuario para GET
2. **Auditoría**: Todos los cambios admin deben registrarse con `created_by`/`updated_by`
3. **Flags Sensibles**: Flags con `affects_security = true` requieren confirmación adicional
4. **Caché**: Response debe ser cacheable por 1 hora (header `Cache-Control: max-age=3600`)

---

## 🚀 Plan de Implementación

### Phase 1: MVP (Estimado: 8 horas)

**Objetivo**: Endpoint básico funcional para que la app pueda obtener flags

**Tareas**:
1. ✅ Crear migración de base de datos (`feature_flags` table)
2. ✅ Crear entity `FeatureFlag`
3. ✅ Crear repository `FeatureFlagRepository`
4. ✅ Crear service `FeatureFlagService` con lógica de evaluación
5. ✅ Crear handler `GET /api/v1/feature-flags`
6. ✅ Seedear flags iniciales (11 flags definidos en app)
7. ✅ Tests unitarios
8. ✅ Tests de integración

**Entregables**:
- [ ] PR con implementación Phase 1
- [ ] Migraciones SQL
- [ ] Tests (coverage > 80%)
- [ ] Documentación API (Swagger)

### Phase 2: Panel Admin (Estimado: 12 horas)

**Tareas**:
1. Crear endpoints CRUD admin
2. Agregar validaciones y permisos
3. Implementar auditoría completa
4. UI básica en panel admin (opcional)

### Phase 3: Features Avanzadas (Estimado: 16 horas)

**Tareas**:
1. A/B testing con `rollout_percentage`
2. Overrides por usuario
3. Métricas y analytics
4. Caché con Redis

---

## 📝 Seed Data Inicial

Los siguientes feature flags deben crearse en la migración inicial:

```sql
INSERT INTO feature_flags (key, name, description, enabled, category, priority, requires_restart, is_debug_only, affects_security, is_experimental) VALUES
-- Security
('biometric_login', 'Login Biométrico', 'Habilita Face ID/Touch ID', true, 'security', 100, false, false, true, false),
('certificate_pinning', 'Certificate Pinning', 'Habilita certificate pinning SSL', true, 'security', 99, true, false, true, false),
('login_rate_limiting', 'Rate Limiting Login', 'Límite de intentos de login', true, 'security', 98, false, false, true, false),

-- Features
('offline_mode', 'Modo Offline', 'Habilita funcionalidad offline', true, 'features', 50, false, false, false, false),
('background_sync', 'Sync Background', 'Sincronización en segundo plano', false, 'features', 49, false, false, false, false),
('push_notifications', 'Notificaciones Push', 'Habilita push notifications', false, 'features', 48, false, false, false, false),

-- UI
('auto_dark_mode', 'Tema Oscuro Auto', 'Tema oscuro según sistema', true, 'ui', 30, false, false, false, false),
('new_dashboard', 'Dashboard Nuevo', 'Dashboard rediseñado (experimental)', false, 'ui', 10, false, false, false, true),
('transition_animations', 'Animaciones', 'Animaciones de transición', true, 'ui', 20, false, false, false, false),

-- Debug
('debug_logs', 'Logs Debug', 'Logs de debug en producción', false, 'debug', 5, true, true, false, false),
('mock_api', 'API Mock', 'Usar API mock (solo dev)', false, 'debug', 1, true, true, false, false);
```

---

## 🧪 Testing

### Test Cases Críticos

| ID | Descripción | Tipo |
|----|-------------|------|
| TC-001 | Usuario autenticado puede obtener sus flags | Integration |
| TC-002 | Flags filtrados por build_number correctamente | Unit |
| TC-003 | Flags debug_only no aparecen en producción | Unit |
| TC-004 | Override por usuario funciona correctamente | Unit |
| TC-005 | Admin puede crear nuevo flag | Integration |
| TC-006 | Admin puede actualizar flag existente | Integration |
| TC-007 | Usuario normal no puede acceder a endpoints admin | Integration |
| TC-008 | Rollout percentage funciona (hash consistente) | Unit |

### Coverage Esperado

- **Unit Tests**: > 85%
- **Integration Tests**: Todos los endpoints
- **E2E Tests**: Flujo completo app -> API

---

## 📚 Referencias

### Documentación Relacionada

- **Apple App SPEC-009**: `/docs/specs/feature-flags/`
- **Auth Guide**: `/docs/auth/AUTH_GUIDE.md`
- **API Standards**: `/docs/cicd/API_STANDARDS.md`

### Ejemplos de Implementación

- LaunchDarkly API: https://apidocs.launchdarkly.com/
- Firebase Remote Config: https://firebase.google.com/docs/remote-config/
- Unleash API: https://docs.getunleash.io/

---

## ✅ Checklist de Aceptación

### Phase 1 (MVP)

- [ ] Tabla `feature_flags` creada con migración
- [ ] Endpoint `GET /api/v1/feature-flags` funcional
- [ ] Lógica de evaluación implementada correctamente
- [ ] 11 feature flags iniciales seeded
- [ ] Tests unitarios (coverage > 80%)
- [ ] Tests de integración para endpoint GET
- [ ] Documentación Swagger actualizada
- [ ] Validado con cliente Apple app (mock primero)

### Phase 2 (Admin)

- [ ] Endpoints CRUD admin funcionando
- [ ] Permisos y validaciones implementadas
- [ ] Auditoría completa (created_by, updated_by)
- [ ] Tests de seguridad (roles)

### Phase 3 (Avanzado)

- [ ] A/B testing con rollout_percentage
- [ ] Overrides por usuario
- [ ] Caché con Redis (opcional)
- [ ] Métricas y analytics

---

## 🔄 Changelog

| Versión | Fecha | Cambios |
|---------|-------|---------|
| 1.0 | 2025-11-28 | Especificación inicial - Phase 1 MVP |

---

## 👥 Stakeholders

- **Apple App Team**: Consumidor principal del API
- **Backend Team**: Implementadores del API
- **Product Team**: Definición de feature flags iniciales
- **QA Team**: Testing y validación

---

**Documento Generado**: 2025-11-28  
**Autor**: Claude (Arquitecto de Software)  
**Para**: Equipo Backend EduGo API Administración  
**Relacionado**: SPEC-009 Feature Flags (Apple App)

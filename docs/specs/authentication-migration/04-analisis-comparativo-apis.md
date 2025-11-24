# Análisis Comparativo: DummyJSON vs API Real EduGo

**Fecha**: 2025-01-24  
**Versión**: 1.0  
**Estado**: 📊 Análisis Técnico  
**Autor**: Claude Code  

---

## 📋 Resumen Ejecutivo

Este documento compara el contrato actual de DummyJSON (usado actualmente) contra el API real de EduGo para identificar gaps, incompatibilidades y ajustes necesarios.

### Conclusión Rápida

| Aspecto | DummyJSON | API Real EduGo | Gap | Acción Requerida |
|---------|-----------|----------------|-----|------------------|
| **Login Request** | `username` | `email` | ❌ Field diferente | ✅ Cambiar DTO |
| **Login Response** | `id: Int` | `id: UUID` | ❌ Tipo diferente | ✅ Cambiar DTO |
| **User Model** | Campos extra (gender, image) | Campos básicos | ⚠️ Diferente estructura | ✅ Actualizar User entity |
| **Refresh Response** | Retorna user completo | Solo access token | ⚠️ Diferente estructura | ✅ Actualizar DTO |
| **JWT Format** | No estandarizado | HS256 con claims específicos | ✅ Compatible | ✅ Implementar decoder |
| **Endpoints** | `/auth/*` | `/v1/auth/*` | ⚠️ Versionado | ✅ Actualizar paths |
| **Token Refresh** | `expiresInMins` param | Sin parámetro | ⚠️ Diferente | ✅ Remover parámetro |

---

## 🔍 Comparación Detallada

### 1. POST /auth/login

#### DummyJSON (Actual)

**URL**: `https://dummyjson.com/auth/login`

**Request**:
```json
{
  "username": "emilys",
  "password": "emilyspass",
  "expiresInMins": 30
}
```

**Response**:
```json
{
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "id": 1,
  "username": "emilys",
  "email": "emily.johnson@x.dummyjson.com",
  "firstName": "Emily",
  "lastName": "Johnson",
  "gender": "female",
  "image": "https://dummyjson.com/icon/emilys/128"
}
```

**Características**:
- ✅ Usa `username` en lugar de `email`
- ✅ `id` es `Int`
- ✅ Retorna datos adicionales (`gender`, `image`)
- ✅ Ambos tokens son JWT

---

#### API Real EduGo

**URL**: `http://localhost:8080/v1/auth/login`

**Request**:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response**:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "550e8400-e29b-41d4-a716-446655440000",
  "expires_in": 900,
  "token_type": "Bearer",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "full_name": "John Doe",
    "role": "student"
  }
}
```

**Características**:
- ✅ Usa `email` (estándar de la industria)
- ✅ `id` es `UUID` (más seguro)
- ✅ Usa snake_case (convención Go/JSON)
- ✅ Access token es JWT, refresh token es UUID
- ✅ Incluye `expires_in` explícitamente
- ✅ Incluye `role` del usuario

---

#### Gaps Identificados

| Campo | DummyJSON | API Real | Acción |
|-------|-----------|----------|--------|
| Username/Email | `username` | `email` | ✅ Cambiar LoginRequest |
| ID Type | `Int` | `UUID String` | ✅ Cambiar User.id a String |
| Response Keys | camelCase | snake_case | ✅ Agregar CodingKeys |
| Refresh Token | JWT | UUID | ✅ Actualizar validación |
| Expires | Calculado | `expires_in` | ✅ Usar valor del API |
| User Fields | gender, image | role, full_name | ✅ Actualizar User entity |

---

### 2. POST /auth/refresh

#### DummyJSON (Actual)

**URL**: `https://dummyjson.com/auth/refresh`

**Request**:
```json
{
  "refreshToken": "eyJhbGc...",
  "expiresInMins": 30
}
```

**Response**:
```json
{
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "id": 1,
  "username": "emilys",
  "email": "emily.johnson@x.dummyjson.com",
  "firstName": "Emily",
  "lastName": "Johnson",
  "gender": "female",
  "image": "https://dummyjson.com/icon/emilys/128"
}
```

**Características**:
- ✅ Retorna user completo (igual que login)
- ✅ Genera nuevo refresh token
- ⚠️ Parámetro `expiresInMins` opcional

---

#### API Real EduGo

**URL**: `http://localhost:8080/v1/auth/refresh`

**Request**:
```json
{
  "refresh_token": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response**:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 900,
  "token_type": "Bearer"
}
```

**Características**:
- ✅ Solo retorna nuevo access token
- ✅ Refresh token NO cambia (más simple)
- ✅ No retorna user (usar GET /auth/me)
- ✅ No acepta parámetros de expiración

---

#### Gaps Identificados

| Aspecto | DummyJSON | API Real | Acción |
|---------|-----------|----------|--------|
| Response | User completo + tokens | Solo access token | ✅ Crear RefreshResponse separado |
| Refresh Token | Cambia en cada refresh | Permanece igual | ✅ No actualizar en Keychain |
| User Data | Incluido | Omitido | ✅ Si necesita, llamar GET /auth/me |
| Parámetro expiración | Opcional | No soportado | ✅ Remover de RefreshRequest |

---

### 3. GET /auth/me

#### DummyJSON (Actual)

**URL**: `https://dummyjson.com/auth/me`

**Headers**:
```
Authorization: Bearer eyJhbGc...
```

**Response**:
```json
{
  "id": 1,
  "username": "emilys",
  "email": "emily.johnson@x.dummyjson.com",
  "firstName": "Emily",
  "lastName": "Johnson",
  "gender": "female",
  "image": "https://dummyjson.com/icon/emilys/128"
}
```

---

#### API Real EduGo

**URL**: `http://localhost:8080/v1/auth/me` (ASUMIDO - NO ENCONTRADO)

**Headers**:
```
Authorization: Bearer eyJhbGc...
```

**Response Esperada**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "full_name": "John Doe",
  "role": "student"
}
```

---

#### ⚠️ GAP CRÍTICO: Endpoint /auth/me NO ENCONTRADO

**Problema**: No se encontró implementación de GET /auth/me en el API backend.

**Archivos revisados**:
- `internal/infrastructure/http/handler/auth_handler.go`: Solo login, refresh, logout, revoke-all
- `internal/infrastructure/http/router/routes.go`: No hay ruta para GET /auth/me

**Opciones**:

**Opción A**: Decodificar JWT localmente (RECOMENDADO)
```swift
// Extraer user info del JWT sin llamar al API
let payload = try jwtDecoder.decode(accessToken)
let user = User(
    id: payload.sub,
    email: payload.email,
    role: payload.role
)
```

**Pros**:
- ✅ Sin latencia de red
- ✅ Funciona offline
- ✅ No requiere cambios en backend

**Cons**:
- ⚠️ Datos podrían estar desactualizados
- ⚠️ Requiere decodificar JWT

**Opción B**: Implementar GET /auth/me en backend
```go
// TAREA BACKEND
// Archivo: internal/infrastructure/http/handler/auth_handler.go
func (h *AuthHandler) GetCurrentUser(c *gin.Context) {
    userID := c.GetString("user_id") // Del middleware
    user, err := h.authService.GetUserByID(userID)
    // ...
}
```

**Pros**:
- ✅ Datos siempre actualizados
- ✅ Estándar REST

**Cons**:
- ❌ Requiere desarrollo backend
- ❌ Latencia adicional

**DECISIÓN**: Opción A (decodificar JWT) + crear issue backend para Opción B

---

### 4. POST /auth/logout

#### DummyJSON (Actual)

**NO SOPORTADO** - La app solo elimina tokens del Keychain localmente.

---

#### API Real EduGo

**URL**: `http://localhost:8080/v1/auth/logout`

**Headers**:
```
Authorization: Bearer eyJhbGc...
```

**Request**:
```json
{
  "refresh_token": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response**:
```
HTTP 204 No Content
```

**Características**:
- ✅ Requiere autenticación (Bearer token)
- ✅ Requiere refresh token en body
- ✅ Revoca el refresh token en BD
- ✅ 204 = éxito sin contenido

---

#### Gaps Identificados

| Aspecto | DummyJSON | API Real | Acción |
|---------|-----------|----------|--------|
| Soporte | ❌ No existe | ✅ Implementado | ✅ Implementar en AuthRepositoryImpl |
| Revocación | Solo local | Servidor + local | ✅ Llamar API + eliminar Keychain |
| Request Body | N/A | Requiere refresh token | ✅ Crear LogoutRequest DTO |

---

## 🔐 JWT Format Comparison

### DummyJSON JWT

**Claims** (decodificado):
```json
{
  "id": 1,
  "username": "emilys",
  "email": "emily.johnson@x.dummyjson.com",
  "firstName": "Emily",
  "lastName": "Johnson",
  "gender": "female",
  "iat": 1516239022,
  "exp": 1516242622
}
```

**Características**:
- ⚠️ No sigue estándar RFC 7519
- ⚠️ Usa campos custom (no `sub`, `aud`, `iss`)
- ✅ Incluye `iat` y `exp`

---

### API Real EduGo JWT

**Claims** (esperados según código backend):
```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "role": "student",
  "iat": 1706054400,
  "exp": 1706055300,
  "iss": "edugo-mobile"
}
```

**Características**:
- ✅ Sigue RFC 7519
- ✅ Usa `sub` (subject = user ID)
- ✅ Usa `iss` (issuer)
- ✅ Incluye `role` para autorización
- ✅ Algoritmo HS256

**Generación** (backend):
```go
// github.com/EduGoGroup/edugo-shared/auth v0.7.0
jwtManager.GenerateToken(
    userID,      // → sub
    email,       // → email
    role,        // → role
    15*time.Minute, // → exp = now + 15min
)
```

---

#### Gaps Identificados

| Campo | DummyJSON | API Real | Acción |
|-------|-----------|----------|--------|
| User ID | `id` (Int) | `sub` (UUID) | ✅ Mapear sub → id en decoder |
| Username | `username` | ❌ No incluido | ⚠️ No disponible en JWT |
| Role | ❌ No incluido | `role` | ✅ Agregar a User entity |
| Issuer | ❌ No incluido | `iss: "edugo-mobile"` | ✅ Validar en decoder |
| Name | `firstName`, `lastName` | ❌ No incluido | ⚠️ Llamar GET /auth/me si necesita |

---

## 📊 Tabla Resumen de DTOs

### LoginRequest

| Campo | DummyJSON | API Real | Decisión |
|-------|-----------|----------|----------|
| email | ❌ | ✅ | **Usar email** |
| username | ✅ | ❌ | **Remover** |
| password | ✅ | ✅ | **Mantener** |
| expiresInMins | ✅ (opcional) | ❌ | **Remover** |

**Nuevo DTO**:
```swift
struct LoginRequest: Codable {
    let email: String
    let password: String
}
```

---

### LoginResponse

| Campo | DummyJSON | API Real | Decisión |
|-------|-----------|----------|----------|
| accessToken / access_token | ✅ | ✅ | **Usar con CodingKeys** |
| refreshToken / refresh_token | ✅ | ✅ | **Usar con CodingKeys** |
| id | Int | UUID | **String (UUID)** |
| username | ✅ | ❌ | **Remover** |
| email | ✅ | ✅ (en user) | **Mantener** |
| firstName / first_name | ✅ | ✅ (en user) | **Usar con CodingKeys** |
| lastName / last_name | ✅ | ✅ (en user) | **Usar con CodingKeys** |
| gender | ✅ | ❌ | **Remover** |
| image | ✅ | ❌ | **Remover** |
| role | ❌ | ✅ (en user) | **Agregar** |
| full_name | ❌ | ✅ (en user) | **Agregar** |
| expires_in | ❌ | ✅ | **Agregar** |
| token_type | ❌ | ✅ | **Agregar** |
| user | ❌ | ✅ (objeto) | **Agregar** |

**Nuevo DTO**:
```swift
struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
    let user: UserDTO
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case user
    }
}

struct UserDTO: Codable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let fullName: String
    let role: String
    
    enum CodingKeys: String, CodingKey {
        case id, email, role
        case firstName = "first_name"
        case lastName = "last_name"
        case fullName = "full_name"
    }
    
    func toDomain() -> User {
        User(
            id: id,
            email: email,
            displayName: fullName,
            role: UserRole(rawValue: role) ?? .student
        )
    }
}
```

---

### RefreshRequest

| Campo | DummyJSON | API Real | Decisión |
|-------|-----------|----------|----------|
| refreshToken / refresh_token | ✅ | ✅ | **Usar con CodingKeys** |
| expiresInMins | ✅ (opcional) | ❌ | **Remover** |

**Nuevo DTO**:
```swift
struct RefreshRequest: Codable {
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}
```

---

### RefreshResponse

| Campo | DummyJSON | API Real | Decisión |
|-------|-----------|----------|----------|
| accessToken / access_token | ✅ | ✅ | **Usar con CodingKeys** |
| refreshToken | ✅ | ❌ | **Remover (no cambia)** |
| user | ✅ (completo) | ❌ | **Remover** |
| expires_in | ❌ | ✅ | **Agregar** |
| token_type | ❌ | ✅ | **Agregar** |

**Nuevo DTO**:
```swift
struct RefreshResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}
```

---

## 🚨 Issues Backend Identificados

### Issue #1: GET /auth/me NO implementado

**Descripión**: No existe endpoint para obtener perfil del usuario autenticado.

**Solución Propuesta** (backend):
```go
// Archivo: internal/infrastructure/http/handler/auth_handler.go

func (h *AuthHandler) GetCurrentUser(c *gin.Context) {
    logger := c.MustGet("logger").(*logger.Logger)
    
    // Extraer user_id del contexto (seteado por middleware)
    userIDStr := c.GetString("user_id")
    userID, err := uuid.Parse(userIDStr)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid user id"})
        return
    }
    
    // Obtener usuario
    user, err := h.authService.GetUserByID(c.Request.Context(), userID)
    if err != nil {
        logger.Error("Failed to get user", "error", err)
        c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
        return
    }
    
    // Retornar user DTO
    c.JSON(http.StatusOK, dto.UserResponse{
        ID:       user.ID.String(),
        Email:    user.Email,
        FirstName: user.FirstName,
        LastName:  user.LastName,
        FullName:  user.FullName(),
        Role:     string(user.Role),
    })
}

// Archivo: internal/infrastructure/http/router/routes.go
authProtected.GET("/me", authHandler.GetCurrentUser)
```

**Prioridad**: P2 - Media (workaround: decodificar JWT)

---

### Issue #2: Logout requiere refresh_token en body

**Descripción**: Actualmente logout requiere enviar el refresh token en el body del request.

**Problema**: 
- Si el cliente perdió el refresh token (eliminado del Keychain), no puede hacer logout
- Mejor práctica: revocar basado en el access token

**Solución Propuesta** (backend):
```go
// Opción A: Hacer refresh_token opcional
// Si se provee, revoca ese token específico
// Si no, revoca todos los tokens del usuario (extraído del JWT)

func (h *AuthHandler) Logout(c *gin.Context) {
    var req dto.LogoutRequest
    
    // Refresh token es opcional
    if err := c.ShouldBindJSON(&req); err != nil {
        req.RefreshToken = "" // No hay refresh token
    }
    
    if req.RefreshToken != "" {
        // Revocar token específico
        h.authService.RevokeRefreshToken(ctx, req.RefreshToken)
    } else {
        // Revocar todos los tokens del usuario
        userID := c.GetString("user_id")
        h.authService.RevokeAllUserTokens(ctx, userID)
    }
    
    c.Status(http.StatusNoContent)
}
```

**Prioridad**: P3 - Baja (funciona actualmente)

---

## ✅ Checklist de Ajustes Necesarios

### App iOS (CRÍTICO)

- [ ] **AuthDTO.swift**: Actualizar todos los DTOs
  - [ ] LoginRequest: email (no username)
  - [ ] LoginResponse: estructura con user anidado
  - [ ] RefreshRequest: sin expiresInMins
  - [ ] RefreshResponse: solo access token
  - [ ] Crear LogoutRequest
  - [ ] CodingKeys para snake_case

- [ ] **User.swift** (Domain): Agregar campos
  - [ ] role: UserRole enum
  - [ ] Cambiar id a String (no Int)
  - [ ] Remover gender, image, photoURL

- [ ] **Endpoint.swift**: Actualizar paths
  - [ ] `/auth/login` → `/v1/auth/login`
  - [ ] `/auth/refresh` → `/v1/auth/refresh`
  - [ ] Agregar `/v1/auth/logout`

- [ ] **JWTDecoder.swift**: Implementar
  - [ ] Decodificar base64URL
  - [ ] Parsear claims (sub, email, role, exp, iat, iss)
  - [ ] Validar issuer = "edugo-mobile"
  - [ ] Validar expiración

- [ ] **AuthRepositoryImpl.swift**: Actualizar lógica
  - [ ] login(): usar email, no username
  - [ ] refreshSession(): no actualizar refresh token
  - [ ] logout(): llamar POST /v1/auth/logout
  - [ ] getCurrentUser(): decodificar JWT (no llamar API)

### Backend API (OPCIONAL)

- [ ] **GET /v1/auth/me**: Implementar (P2)
- [ ] **POST /v1/auth/logout**: Hacer refresh_token opcional (P3)

---

## 🎯 Recomendaciones Finales

### ✅ Estrategia Recomendada

1. **Fase 1**: Adaptar app a API real actual
   - Implementar todos los ajustes de DTOs
   - Decodificar JWT para getCurrentUser
   - Implementar logout con API
   - Feature flag para toggle DummyJSON/Real

2. **Fase 2**: Mejoras backend (paralelo)
   - Crear issues en repo backend
   - Implementar GET /auth/me
   - Mejorar logout

3. **Fase 3**: Optimizaciones
   - Usar GET /auth/me cuando esté disponible
   - Token refresh automático
   - Biometric auth

### ⚠️ Bloqueantes Identificados

**NINGUNO** - El API actual es suficiente para implementar SPEC-003.

---

**Próximo paso**: Ver `PLAN-EJECUCION-SPEC-003.md`

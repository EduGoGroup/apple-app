# Runbook - Auth Centralizada

## Información General

| Campo | Valor |
|-------|-------|
| Servicio | api-admin (auth centralizada) |
| Puerto | 8081 |
| Health Check | GET /health |
| Metrics | GET /metrics |
| Logs | `kubectl logs -l app=api-admin` |

---

## Incidentes Comunes

### 1. api-admin no responde

**Alerta**: `AuthServiceDown`

**Síntomas**:
- api-mobile retorna 503
- apple-app muestra error de login
- Dashboard de Grafana muestra servicio down

**Impacto**: CRÍTICO - Ningún usuario puede autenticarse

**Diagnóstico**:
```bash
# Verificar estado del pod
kubectl get pods -l app=api-admin

# Verificar health endpoint
curl http://api-admin:8081/health

# Ver logs recientes
kubectl logs -l app=api-admin --tail=100

# Verificar recursos
kubectl top pod -l app=api-admin
```

**Resolución**:

1. **Si el pod está en CrashLoopBackOff**:
   ```bash
   # Ver eventos
   kubectl describe pod -l app=api-admin
   
   # Ver logs del crash
   kubectl logs -l app=api-admin --previous
   ```

2. **Si no hay conexión a PostgreSQL**:
   ```bash
   # Verificar PostgreSQL
   kubectl exec -it postgres-0 -- pg_isready
   
   # Verificar credenciales
   kubectl get secret api-admin-secrets -o yaml
   ```

3. **Si no hay conexión a Redis**:
   ```bash
   # Verificar Redis
   kubectl exec -it redis-0 -- redis-cli ping
   ```

4. **Reiniciar pod**:
   ```bash
   kubectl rollout restart deployment/api-admin
   ```

**Escalación**: Si no se resuelve en 10 minutos, escalar a DevOps Lead.

---

### 2. Alto rate de errores de login

**Alerta**: `AuthServiceHighErrorRate`

**Síntomas**:
- Error rate > 20% en Grafana
- Usuarios reportan errores de login
- Logs muestran múltiples "login failed"

**Impacto**: ALTO - Algunos usuarios no pueden autenticarse

**Diagnóstico**:
```bash
# Ver logs de errores de login
kubectl logs -l app=api-admin | grep "login failed" | tail -50

# Verificar IPs con más errores (posible ataque)
kubectl logs -l app=api-admin | grep "login failed" | awk '{print $NF}' | sort | uniq -c | sort -rn | head -10

# Verificar rate limiting
redis-cli keys "rate:login:*" | wc -l
```

**Resolución**:

1. **Si es un ataque de fuerza bruta**:
   ```bash
   # Bloquear IP específica (si es necesario)
   kubectl exec -it api-admin-xxx -- curl -X POST localhost:8081/admin/block-ip -d '{"ip":"1.2.3.4"}'
   
   # O via Redis
   redis-cli SET "blocked:ip:1.2.3.4" "1" EX 3600
   ```

2. **Si es problema legítimo de credenciales**:
   ```bash
   # Verificar si hay usuarios bloqueados por rate limit
   redis-cli keys "rate:login:user:*" | head -10
   
   # Limpiar rate limit de un usuario específico
   redis-cli DEL "rate:login:user:uuid-del-usuario"
   ```

3. **Si hay problema con la base de datos**:
   ```bash
   # Verificar queries lentas
   kubectl exec -it postgres-0 -- psql -c "SELECT * FROM pg_stat_activity WHERE state='active';"
   ```

---

### 3. Latencia alta en validación de tokens

**Alerta**: `AuthHighVerifyLatency`

**Síntomas**:
- p99 > 100ms en verify endpoint
- Operaciones lentas en api-mobile
- Dashboard muestra picos de latencia

**Impacto**: MEDIO - Sistema funciona pero lento

**Diagnóstico**:
```bash
# Verificar cache hit rate
curl http://api-admin:8081/metrics | grep cache_hit

# Verificar conexión a Redis
redis-cli INFO stats | grep ops_per_sec

# Verificar carga de PostgreSQL
kubectl exec -it postgres-0 -- psql -c "SELECT count(*) FROM pg_stat_activity WHERE state='active';"
```

**Resolución**:

1. **Si cache hit rate es bajo (<50%)**:
   ```bash
   # Verificar TTL del cache
   redis-cli TTL "token:hash:xxxxx"
   
   # Verificar memoria de Redis
   redis-cli INFO memory
   ```

2. **Si Redis está sobrecargado**:
   ```bash
   # Verificar slow queries
   redis-cli SLOWLOG GET 10
   
   # Limpiar cache si es necesario
   redis-cli FLUSHDB
   ```

3. **Si PostgreSQL está lento**:
   ```bash
   # Verificar índices
   kubectl exec -it postgres-0 -- psql -c "EXPLAIN ANALYZE SELECT * FROM users WHERE email='test@test.com';"
   
   # Verificar conexiones
   kubectl exec -it postgres-0 -- psql -c "SELECT count(*) FROM pg_stat_activity;"
   ```

---

### 4. Circuit Breaker abierto en api-mobile

**Alerta**: `AuthCircuitBreakerOpen`

**Síntomas**:
- api-mobile rechaza requests inmediatamente
- Logs muestran "circuit breaker open"
- No hay llamadas a api-admin

**Impacto**: ALTO - api-mobile no puede validar tokens

**Diagnóstico**:
```bash
# Ver estado del circuit breaker en logs
kubectl logs -l app=api-mobile | grep "circuit breaker"

# Verificar si api-admin está accesible desde api-mobile
kubectl exec -it api-mobile-xxx -- curl http://api-admin:8081/health
```

**Resolución**:

1. **Verificar y resolver problema de api-admin** (ver incidente #1)

2. **Esperar a que circuit breaker se cierre** (automático después de timeout)

3. **Si necesita forzar reset**:
   ```bash
   # Reiniciar api-mobile (resetea circuit breaker)
   kubectl rollout restart deployment/api-mobile
   ```

---

### 5. Tokens no se refrescan

**Síntomas**:
- Usuarios son deslogueados después de 15 minutos
- Logs muestran "refresh token invalid"
- apple-app reporta errores de refresh

**Diagnóstico**:
```bash
# Verificar refresh tokens en base de datos
kubectl exec -it postgres-0 -- psql -c "SELECT count(*) FROM refresh_tokens WHERE revoked=false;"

# Ver logs de refresh
kubectl logs -l app=api-admin | grep "refresh" | tail -20
```

**Resolución**:

1. **Si tokens están siendo revocados incorrectamente**:
   ```bash
   # Verificar política de revocación
   kubectl exec -it postgres-0 -- psql -c "SELECT * FROM refresh_tokens ORDER BY created_at DESC LIMIT 10;"
   ```

2. **Si hay problema de sincronización de tiempo**:
   ```bash
   # Verificar hora del servidor
   kubectl exec -it api-admin-xxx -- date
   
   # Comparar con hora local
   date
   ```

---

## Procedimientos de Emergencia

### Rollback a Auth Local

**Tiempo estimado**: 5 minutos

```bash
# 1. Activar feature flag
kubectl set env deployment/api-mobile FF_USE_REMOTE_AUTH=false

# 2. Reiniciar api-mobile
kubectl rollout restart deployment/api-mobile

# 3. Verificar que funciona
kubectl rollout status deployment/api-mobile
curl http://api-mobile:9091/health

# 4. Notificar al equipo
# Slack: #edugo-incidents
```

### Escalar api-admin

```bash
# Escalar a más réplicas
kubectl scale deployment/api-admin --replicas=5

# Verificar
kubectl get pods -l app=api-admin
```

### Limpiar cache de tokens

```bash
# Limpiar todo el cache (usar con cuidado)
redis-cli KEYS "token:*" | xargs redis-cli DEL

# Limpiar cache de un usuario específico
redis-cli KEYS "token:*:user-uuid" | xargs redis-cli DEL
```

---

## Contactos

| Rol | Nombre | Contacto |
|-----|--------|----------|
| Backend Lead | [nombre] | [email/slack] |
| DevOps | [nombre] | [email/slack] |
| DBA | [nombre] | [email/slack] |
| On-call | Rotación | PagerDuty |

---

## Métricas Clave

| Métrica | Normal | Warning | Critical |
|---------|--------|---------|----------|
| Login error rate | <5% | 5-20% | >20% |
| Verify latency p99 | <50ms | 50-100ms | >100ms |
| Cache hit rate | >80% | 50-80% | <50% |
| Active sessions | <10k | 10k-50k | >50k |

---

## Dashboards

- **Grafana**: [URL del dashboard de auth]
- **Prometheus**: [URL de Prometheus]
- **Logs**: [URL de sistema de logs]

# Tests de Flujos Críticos

## Instrucciones
Marcar cada item como completado `[x]` después de verificar manualmente.

---

## Flujo 1: Usuario nuevo hace login
- [ ] Usuario abre apple-app
- [ ] Ve pantalla de login
- [ ] Ingresa credenciales correctas
- [ ] Login exitoso, redirige a Home
- [ ] Token guardado en Keychain
- [ ] Puede acceder a Materials
- [ ] Puede acceder a Schools

**Notas:**
```
Fecha verificación: ___________
Probado por: ___________
Dispositivo: ___________
```

---

## Flujo 2: Token expira durante uso
- [ ] Usuario está usando la app
- [ ] Token próximo a expirar (< 2 min)
- [ ] Hace request a API
- [ ] Token se refresca automáticamente
- [ ] Request completa exitosamente
- [ ] Usuario no nota interrupción

**Notas:**
```
Fecha verificación: ___________
Probado por: ___________
```

---

## Flujo 3: Sesión en múltiples dispositivos
- [ ] Login en iPhone
- [ ] Login en iPad
- [ ] Ambos funcionan independientemente
- [ ] Logout en uno no afecta al otro

**Notas:**
```
Fecha verificación: ___________
Probado por: ___________
```

---

## Flujo 4: Recuperación de api-admin caído
- [ ] Sistema funcionando normalmente
- [ ] api-admin se detiene
- [ ] api-mobile retorna error 503 (circuit breaker)
- [ ] api-admin se reinicia
- [ ] Sistema se recupera automáticamente
- [ ] Circuit breaker se cierra

**Comando para probar:**
```bash
# Detener api-admin
docker stop api-admin

# Verificar que api-mobile retorna error
curl http://localhost:9091/v1/materials -H "Authorization: Bearer $TOKEN"

# Reiniciar api-admin
docker start api-admin

# Verificar recuperación
sleep 30
curl http://localhost:9091/v1/materials -H "Authorization: Bearer $TOKEN"
```

**Notas:**
```
Fecha verificación: ___________
Probado por: ___________
```

---

## Flujo 5: Worker procesa jobs autenticados
- [ ] Job con token válido → Procesado
- [ ] Job con token expirado → Rechazado
- [ ] Job sin permisos → Rechazado
- [ ] Bulk validation funciona

**Notas:**
```
Fecha verificación: ___________
Probado por: ___________
```

---

## Flujo 6: Credenciales incorrectas
- [ ] Usuario ingresa email incorrecto → Error claro
- [ ] Usuario ingresa password incorrecto → Error claro
- [ ] Múltiples intentos fallidos → Rate limiting
- [ ] Mensaje de error no revela información sensible

**Notas:**
```
Fecha verificación: ___________
Probado por: ___________
```

---

## Flujo 7: Logout y re-login
- [ ] Usuario hace logout
- [ ] Token eliminado de Keychain
- [ ] Redirige a pantalla de login
- [ ] Puede hacer login nuevamente
- [ ] Nuevo token funciona correctamente

**Notas:**
```
Fecha verificación: ___________
Probado por: ___________
```

---

## Flujo 8: Rollback (si es necesario)
- [ ] Sistema con auth centralizada funcionando
- [ ] Se detecta problema crítico
- [ ] Ejecutar rollback via feature flag
- [ ] api-mobile usa auth local nuevamente
- [ ] Usuarios pueden seguir trabajando
- [ ] Tiempo de rollback < 5 minutos

**Comando de rollback:**
```bash
# Activar feature flag de auth local
export FF_USE_REMOTE_AUTH=false

# Reiniciar api-mobile
docker restart api-mobile
```

**Notas:**
```
Fecha verificación: ___________
Probado por: ___________
Tiempo de rollback: ___________
```

---

## Resumen de Verificación

| Flujo | Estado | Fecha | Verificador |
|-------|--------|-------|-------------|
| 1. Login nuevo usuario | ⬜ | | |
| 2. Token refresh | ⬜ | | |
| 3. Multi-dispositivo | ⬜ | | |
| 4. Recuperación api-admin | ⬜ | | |
| 5. Worker auth | ⬜ | | |
| 6. Credenciales incorrectas | ⬜ | | |
| 7. Logout/re-login | ⬜ | | |
| 8. Rollback | ⬜ | | |

**Firma de aprobación:**
```
Fecha: ___________
QA Lead: ___________
Dev Lead: ___________
```

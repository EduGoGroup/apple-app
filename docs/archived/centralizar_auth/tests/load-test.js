// load-test.js - Load testing con k6 para auth centralizada
// Ejecutar: k6 run centralizar_auth/tests/load-test.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Métricas personalizadas
const errorRate = new Rate('errors');
const loginDuration = new Trend('login_duration');
const verifyDuration = new Trend('verify_duration');
const refreshDuration = new Trend('refresh_duration');

// Configuración de escenarios
export const options = {
    scenarios: {
        // Escenario 1: Carga constante (smoke test)
        smoke: {
            executor: 'constant-arrival-rate',
            rate: 10,              // 10 requests/segundo
            timeUnit: '1s',
            duration: '1m',
            preAllocatedVUs: 20,
            maxVUs: 50,
        },
        // Escenario 2: Carga normal
        load: {
            executor: 'ramping-vus',
            startVUs: 0,
            stages: [
                { duration: '30s', target: 50 },   // Ramp up
                { duration: '2m', target: 50 },    // Stay
                { duration: '30s', target: 0 },    // Ramp down
            ],
            startTime: '1m30s',
        },
        // Escenario 3: Stress test
        stress: {
            executor: 'ramping-vus',
            startVUs: 0,
            stages: [
                { duration: '1m', target: 100 },
                { duration: '2m', target: 100 },
                { duration: '1m', target: 200 },
                { duration: '2m', target: 200 },
                { duration: '1m', target: 0 },
            ],
            startTime: '5m',
        },
    },
    thresholds: {
        http_req_duration: ['p(95)<500', 'p(99)<1000'],
        errors: ['rate<0.05'],  // <5% error rate
        login_duration: ['p(95)<300'],
        verify_duration: ['p(99)<50'],  // Verify debe ser muy rápido
    },
};

// URLs configurables via variables de entorno
const API_ADMIN_URL = __ENV.API_ADMIN_URL || 'http://localhost:8081';
const TEST_EMAIL = __ENV.TEST_EMAIL || 'admin@edugo.test';
const TEST_PASSWORD = __ENV.TEST_PASSWORD || 'edugo2024';

export default function() {
    // 1. Login
    const loginStart = new Date();
    const loginRes = http.post(`${API_ADMIN_URL}/v1/auth/login`, JSON.stringify({
        email: TEST_EMAIL,
        password: TEST_PASSWORD,
    }), {
        headers: { 'Content-Type': 'application/json' },
        tags: { name: 'login' },
    });
    loginDuration.add(new Date() - loginStart);

    const loginSuccess = check(loginRes, {
        'login status 200': (r) => r.status === 200,
        'login has token': (r) => {
            try {
                const body = JSON.parse(r.body);
                return body.access_token !== undefined || body.token !== undefined;
            } catch (e) {
                return false;
            }
        },
        'login latency ok': (r) => r.timings.duration < 300,
    });

    errorRate.add(!loginSuccess);

    if (!loginSuccess) {
        console.error(`Login failed: ${loginRes.status} - ${loginRes.body}`);
        sleep(1);
        return;
    }

    let token;
    try {
        const body = JSON.parse(loginRes.body);
        token = body.access_token || body.token;
    } catch (e) {
        console.error('Failed to parse login response');
        sleep(1);
        return;
    }

    // 2. Verify token (simula validaciones de api-mobile/worker)
    for (let i = 0; i < 5; i++) {
        const verifyStart = new Date();
        const verifyRes = http.post(`${API_ADMIN_URL}/v1/auth/verify`, JSON.stringify({
            token: token,
        }), {
            headers: { 'Content-Type': 'application/json' },
            tags: { name: 'verify' },
        });
        verifyDuration.add(new Date() - verifyStart);

        const verifySuccess = check(verifyRes, {
            'verify status 200': (r) => r.status === 200,
            'verify valid true': (r) => {
                try {
                    return JSON.parse(r.body).valid === true;
                } catch (e) {
                    return false;
                }
            },
            'verify fast (<50ms)': (r) => r.timings.duration < 50,
        });

        errorRate.add(!verifySuccess);

        sleep(0.1); // Pequeña pausa entre verificaciones
    }

    // 3. Refresh token (ocasionalmente)
    if (Math.random() < 0.2) { // 20% de las veces
        let refreshToken;
        try {
            refreshToken = JSON.parse(loginRes.body).refresh_token;
        } catch (e) {
            // No hay refresh token
        }

        if (refreshToken) {
            const refreshStart = new Date();
            const refreshRes = http.post(`${API_ADMIN_URL}/v1/auth/refresh`, JSON.stringify({
                refresh_token: refreshToken,
            }), {
                headers: { 'Content-Type': 'application/json' },
                tags: { name: 'refresh' },
            });
            refreshDuration.add(new Date() - refreshStart);

            check(refreshRes, {
                'refresh status 200': (r) => r.status === 200,
                'refresh has new token': (r) => {
                    try {
                        const body = JSON.parse(r.body);
                        return body.access_token !== undefined || body.token !== undefined;
                    } catch (e) {
                        return false;
                    }
                },
            });
        }
    }

    sleep(1); // Simula tiempo entre operaciones de usuario
}

// Función para generar reporte al final
export function handleSummary(data) {
    const summary = generateTextSummary(data);

    return {
        'load-test-results.json': JSON.stringify(data, null, 2),
        stdout: summary,
    };
}

function generateTextSummary(data) {
    const duration = data.state.testRunDurationMs / 1000;
    const requests = data.metrics.http_reqs?.values?.count || 0;
    const rps = (requests / duration).toFixed(2);

    const loginP95 = data.metrics.login_duration?.values['p(95)']?.toFixed(2) || 'N/A';
    const verifyP99 = data.metrics.verify_duration?.values['p(99)']?.toFixed(2) || 'N/A';
    const verifyP50 = data.metrics.verify_duration?.values.med?.toFixed(2) || 'N/A';
    const errRate = ((data.metrics.errors?.values?.rate || 0) * 100).toFixed(2);

    const httpP95 = data.metrics.http_req_duration?.values['p(95)']?.toFixed(2) || 'N/A';
    const httpP99 = data.metrics.http_req_duration?.values['p(99)']?.toFixed(2) || 'N/A';

    return `
╔══════════════════════════════════════════════════════════════╗
║           LOAD TEST SUMMARY - AUTH CENTRALIZADA              ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  Duration:        ${duration.toFixed(0).padStart(6)}s                                  ║
║  Total Requests:  ${requests.toString().padStart(6)}                                   ║
║  Requests/sec:    ${rps.padStart(6)}                                   ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║  LATENCY                                                     ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  Login Duration:                                             ║
║    - p95:         ${loginP95.padStart(6)}ms                                 ║
║                                                              ║
║  Verify Duration:                                            ║
║    - p50:         ${verifyP50.padStart(6)}ms                                 ║
║    - p99:         ${verifyP99.padStart(6)}ms  ${parseFloat(verifyP99) < 50 ? '✓' : '✗'}                           ║
║                                                              ║
║  HTTP Overall:                                               ║
║    - p95:         ${httpP95.padStart(6)}ms                                 ║
║    - p99:         ${httpP99.padStart(6)}ms                                 ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║  ERROR RATE:      ${errRate.padStart(6)}%  ${parseFloat(errRate) < 5 ? '✓ PASS' : '✗ FAIL'}                          ║
╚══════════════════════════════════════════════════════════════╝

Thresholds:
  - verify p99 < 50ms: ${parseFloat(verifyP99) < 50 ? '✓ PASS' : '✗ FAIL'}
  - login p95 < 300ms: ${parseFloat(loginP95) < 300 ? '✓ PASS' : '✗ FAIL'}
  - error rate < 5%:   ${parseFloat(errRate) < 5 ? '✓ PASS' : '✗ FAIL'}
  - http p95 < 500ms:  ${parseFloat(httpP95) < 500 ? '✓ PASS' : '✗ FAIL'}
  - http p99 < 1000ms: ${parseFloat(httpP99) < 1000 ? '✓ PASS' : '✗ FAIL'}

`;
}

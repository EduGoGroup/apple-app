# Análisis de Diseño: Security Hardening

---

## Componentes

### 1. SSL Pinning

```swift
final class CertificatePinningService: CertificatePinner {
    private let pinnedCertificates: Set<SecCertificate>
    
    func validate(_ trust: SecTrust, for host: String) -> Bool {
        let serverCerts = extractCertificates(from: trust)
        return serverCerts.contains(where: pinnedCertificates.contains)
    }
}
```

### 2. Jailbreak Detection

```swift
final class SecurityValidationService: SecurityValidator {
    var isJailbroken: Bool {
        #if !targetEnvironment(simulator)
        return checkSuspiciousPaths() || 
               checkCydiaInstalled() || 
               checkSystemIntegrity()
        #else
        return false
        #endif
    }
}
```

### 3. URLSession with Pinning

```swift
final class SecureSessionDelegate: NSObject, URLSessionDelegate {
    private let pinner: CertificatePinner
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        let isValid = pinner.validate(trust, for: challenge.protectionSpace.host)
        
        if isValid {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
```

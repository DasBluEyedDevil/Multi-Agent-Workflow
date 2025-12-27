# Security Audit Template

Security Audit Request.

Please analyze for vulnerabilities:

1. **Authentication & Authorization**
   - Password storage (hashing, salting)
   - Token management (JWT, session)
   - Permission checks

2. **Data Protection**
   - Encryption at rest and in transit
   - Sensitive data exposure
   - PII handling

3. **Input Validation**
   - SQL injection
   - XSS vulnerabilities
   - Command injection

4. **API Security**
   - Rate limiting
   - CORS configuration
   - API key exposure

5. **Dependencies**
   - Known vulnerabilities (CVEs)
   - Outdated packages

Severity ratings: CRITICAL / HIGH / MEDIUM / LOW
Provide file:line references for each finding.

Target:

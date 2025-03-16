;; Sustainability Certification Contract
;; Issues verifiable eco-friendly credentials

(define-data-var admin principal tx-sender)

;; Map of certification standards
(define-map certification-standards
  { standard-id: (string-ascii 32) }
  {
    name: (string-ascii 64),
    description: (string-ascii 256),
    criteria: (string-ascii 256),
    created-by: principal,
    creation-date: uint,
    active: bool
  }
)

;; Map of certifications
(define-map certifications
  { certification-id: (string-ascii 32) }
  {
    entity-id: (string-ascii 32),
    entity-type: (string-ascii 16),
    standard-id: (string-ascii 32),
    issue-date: uint,
    expiry-date: uint,
    issuer: principal,
    status: (string-ascii 16),
    score: uint,
    evidence-hash: (buff 32)
  }
)

;; Map of certification audits
(define-map certification-audits
  {
    certification-id: (string-ascii 32),
    audit-id: (string-ascii 32)
  }
  {
    auditor: principal,
    audit-date: uint,
    findings: (string-ascii 256),
    recommendation: (string-ascii 32),
    evidence-hash: (buff 32)
  }
)

;; Create a certification standard
(define-public (create-standard
    (standard-id (string-ascii 32))
    (name (string-ascii 64))
    (description (string-ascii 256))
    (criteria (string-ascii 256)))
  (let ((current-time (unwrap-panic (get-block-info? time u0))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (map-insert certification-standards
      { standard-id: standard-id }
      {
        name: name,
        description: description,
        criteria: criteria,
        created-by: tx-sender,
        creation-date: current-time,
        active: true
      }
    )
    (ok true)
  )
)

;; Issue a certification
(define-public (issue-certification
    (certification-id (string-ascii 32))
    (entity-id (string-ascii 32))
    (entity-type (string-ascii 16))
    (standard-id (string-ascii 32))
    (expiry-date uint)
    (score uint)
    (evidence-hash (buff 32)))
  (let ((standard (unwrap! (map-get? certification-standards { standard-id: standard-id }) (err u404)))
        (current-time (unwrap-panic (get-block-info? time u0))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-eq (get active standard) true) (err u403))
    (asserts! (<= score u100) (err u400))

    (map-insert certifications
      { certification-id: certification-id }
      {
        entity-id: entity-id,
        entity-type: entity-type,
        standard-id: standard-id,
        issue-date: current-time,
        expiry-date: expiry-date,
        issuer: tx-sender,
        status: "active",
        score: score,
        evidence-hash: evidence-hash
      }
    )
    (ok true)
  )
)

;; Record a certification audit
(define-public (record-audit
    (certification-id (string-ascii 32))
    (audit-id (string-ascii 32))
    (findings (string-ascii 256))
    (recommendation (string-ascii 32))
    (evidence-hash (buff 32)))
  (let ((certification (unwrap! (map-get? certifications { certification-id: certification-id }) (err u404)))
        (current-time (unwrap-panic (get-block-info? time u0))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (map-insert certification-audits
      {
        certification-id: certification-id,
        audit-id: audit-id
      }
      {
        auditor: tx-sender,
        audit-date: current-time,
        findings: findings,
        recommendation: recommendation,
        evidence-hash: evidence-hash
      }
    )
    (ok true)
  )
)

;; Update certification status
(define-public (update-certification-status
    (certification-id (string-ascii 32))
    (status (string-ascii 16)))
  (let ((certification (unwrap! (map-get? certifications { certification-id: certification-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (map-set certifications
      { certification-id: certification-id }
      (merge certification { status: status })
    )
    (ok true)
  )
)

;; Verify a certification (public function)
(define-read-only (verify-certification (certification-id (string-ascii 32)))
  (let ((certification (unwrap! (map-get? certifications { certification-id: certification-id }) (err u404))))
    (if (is-eq (get status certification) "active")
      (let ((current-time (unwrap-panic (get-block-info? time u0))))
        (if (> (get expiry-date certification) current-time)
          (ok true)
          (ok false)
        )
      )
      (ok false)
    )
  )
)

;; Get standard details
(define-read-only (get-standard (standard-id (string-ascii 32)))
  (map-get? certification-standards { standard-id: standard-id })
)

;; Get certification details
(define-read-only (get-certification (certification-id (string-ascii 32)))
  (map-get? certifications { certification-id: certification-id })
)

;; Get audit details
(define-read-only (get-audit (certification-id (string-ascii 32)) (audit-id (string-ascii 32)))
  (map-get? certification-audits { certification-id: certification-id, audit-id: audit-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)


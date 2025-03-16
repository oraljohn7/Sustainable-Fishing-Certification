;; Vessel Registration Contract
;; Records details of fishing boats and equipment

(define-data-var admin principal tx-sender)

;; Map of registered vessels
(define-map vessels
  { vessel-id: (string-ascii 32) }
  {
    owner: principal,
    name: (string-ascii 64),
    registration-number: (string-ascii 32),
    vessel-type: (string-ascii 32),
    length: uint,
    capacity: uint,
    home-port: (string-ascii 64),
    registration-date: uint,
    license-expiry: uint,
    active: bool
  }
)

;; Map of vessel equipment
(define-map vessel-equipment
  {
    vessel-id: (string-ascii 32),
    equipment-id: (string-ascii 32)
  }
  {
    equipment-type: (string-ascii 32),
    description: (string-ascii 128),
    installation-date: uint,
    last-inspection: uint,
    inspector: principal
  }
)

;; Map of vessel certifications
(define-map vessel-certifications
  {
    vessel-id: (string-ascii 32),
    certification-id: (string-ascii 32)
  }
  {
    certification-type: (string-ascii 32),
    issuer: (string-ascii 64),
    issue-date: uint,
    expiry-date: uint,
    status: (string-ascii 16)
  }
)

;; Register a new vessel
(define-public (register-vessel
    (vessel-id (string-ascii 32))
    (name (string-ascii 64))
    (registration-number (string-ascii 32))
    (vessel-type (string-ascii 32))
    (length uint)
    (capacity uint)
    (home-port (string-ascii 64))
    (license-expiry uint))
  (let ((current-time (unwrap-panic (get-block-info? time u0))))
    (asserts! (not (is-some (map-get? vessels { vessel-id: vessel-id }))) (err u403))

    (map-insert vessels
      { vessel-id: vessel-id }
      {
        owner: tx-sender,
        name: name,
        registration-number: registration-number,
        vessel-type: vessel-type,
        length: length,
        capacity: capacity,
        home-port: home-port,
        registration-date: current-time,
        license-expiry: license-expiry,
        active: true
      }
    )
    (ok true)
  )
)

;; Add equipment to a vessel
(define-public (add-equipment
    (vessel-id (string-ascii 32))
    (equipment-id (string-ascii 32))
    (equipment-type (string-ascii 32))
    (description (string-ascii 128))
    (installation-date uint))
  (let ((vessel (unwrap! (map-get? vessels { vessel-id: vessel-id }) (err u404)))
        (current-time (unwrap-panic (get-block-info? time u0))))
    (asserts! (is-eq tx-sender (get owner vessel)) (err u403))

    (map-insert vessel-equipment
      {
        vessel-id: vessel-id,
        equipment-id: equipment-id
      }
      {
        equipment-type: equipment-type,
        description: description,
        installation-date: installation-date,
        last-inspection: current-time,
        inspector: tx-sender
      }
    )
    (ok true)
  )
)

;; Add certification to a vessel
(define-public (add-certification
    (vessel-id (string-ascii 32))
    (certification-id (string-ascii 32))
    (certification-type (string-ascii 32))
    (issuer (string-ascii 64))
    (issue-date uint)
    (expiry-date uint))
  (let ((vessel (unwrap! (map-get? vessels { vessel-id: vessel-id }) (err u404))))
    (asserts! (or (is-eq tx-sender (get owner vessel)) (is-eq tx-sender (var-get admin))) (err u403))

    (map-insert vessel-certifications
      {
        vessel-id: vessel-id,
        certification-id: certification-id
      }
      {
        certification-type: certification-type,
        issuer: issuer,
        issue-date: issue-date,
        expiry-date: expiry-date,
        status: "active"
      }
    )
    (ok true)
  )
)

;; Update vessel status (active/inactive)
(define-public (update-vessel-status (vessel-id (string-ascii 32)) (active bool))
  (let ((vessel (unwrap! (map-get? vessels { vessel-id: vessel-id }) (err u404))))
    (asserts! (or (is-eq tx-sender (get owner vessel)) (is-eq tx-sender (var-get admin))) (err u403))

    (map-set vessels
      { vessel-id: vessel-id }
      (merge vessel { active: active })
    )
    (ok true)
  )
)

;; Update certification status
(define-public (update-certification-status
    (vessel-id (string-ascii 32))
    (certification-id (string-ascii 32))
    (status (string-ascii 16)))
  (let ((vessel (unwrap! (map-get? vessels { vessel-id: vessel-id }) (err u404)))
        (certification (unwrap! (map-get? vessel-certifications { vessel-id: vessel-id, certification-id: certification-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (map-set vessel-certifications
      {
        vessel-id: vessel-id,
        certification-id: certification-id
      }
      (merge certification { status: status })
    )
    (ok true)
  )
)

;; Get vessel details
(define-read-only (get-vessel (vessel-id (string-ascii 32)))
  (map-get? vessels { vessel-id: vessel-id })
)

;; Get vessel equipment
(define-read-only (get-equipment (vessel-id (string-ascii 32)) (equipment-id (string-ascii 32)))
  (map-get? vessel-equipment { vessel-id: vessel-id, equipment-id: equipment-id })
)

;; Get vessel certification
(define-read-only (get-certification (vessel-id (string-ascii 32)) (certification-id (string-ascii 32)))
  (map-get? vessel-certifications { vessel-id: vessel-id, certification-id: certification-id })
)

;; Transfer vessel ownership
(define-public (transfer-ownership (vessel-id (string-ascii 32)) (new-owner principal))
  (let ((vessel (unwrap! (map-get? vessels { vessel-id: vessel-id }) (err u404))))
    (asserts! (is-eq tx-sender (get owner vessel)) (err u403))

    (map-set vessels
      { vessel-id: vessel-id }
      (merge vessel { owner: new-owner })
    )
    (ok true)
  )
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)


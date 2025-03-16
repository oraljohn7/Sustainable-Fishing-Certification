;; Processing Verification Contract
;; Monitors chain of custody to consumer

(define-data-var admin principal tx-sender)

;; Map of processing facilities
(define-map processing-facilities
  { facility-id: (string-ascii 32) }
  {
    name: (string-ascii 64),
    location: (string-ascii 64),
    owner: principal,
    registration-date: uint,
    certification-status: (string-ascii 16),
    active: bool
  }
)

;; Map of processing batches
(define-map processing-batches
  { batch-id: (string-ascii 32) }
  {
    facility-id: (string-ascii 32),
    input-catch-ids: (list 20 (string-ascii 32)),
    input-trip-ids: (list 20 (string-ascii 32)),
    processing-type: (string-ascii 32),
    start-time: uint,
    end-time: uint,
    output-quantity: uint,
    output-unit: (string-ascii 16),
    quality-grade: (string-ascii 16),
    status: (string-ascii 16)
  }
)

;; Map of custody transfers
(define-map custody-transfers
  { transfer-id: (string-ascii 32) }
  {
    batch-id: (string-ascii 32),
    from-entity: principal,
    to-entity: principal,
    transfer-time: uint,
    transport-method: (string-ascii 32),
    transport-conditions: (string-ascii 64),
    verified-by: (optional principal),
    verification-time: (optional uint),
    status: (string-ascii 16)
  }
)

;; Register a processing facility
(define-public (register-facility
    (facility-id (string-ascii 32))
    (name (string-ascii 64))
    (location (string-ascii 64)))
  (let ((current-time (unwrap-panic (get-block-info? time u0))))
    (asserts! (not (is-some (map-get? processing-facilities { facility-id: facility-id }))) (err u403))

    (map-insert processing-facilities
      { facility-id: facility-id }
      {
        name: name,
        location: location,
        owner: tx-sender,
        registration-date: current-time,
        certification-status: "pending",
        active: true
      }
    )
    (ok true)
  )
)

;; Update facility certification status
(define-public (update-facility-certification
    (facility-id (string-ascii 32))
    (certification-status (string-ascii 16)))
  (let ((facility (unwrap! (map-get? processing-facilities { facility-id: facility-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (map-set processing-facilities
      { facility-id: facility-id }
      (merge facility { certification-status: certification-status })
    )
    (ok true)
  )
)

;; Start a processing batch
(define-public (start-processing-batch
    (batch-id (string-ascii 32))
    (facility-id (string-ascii 32))
    (input-catch-ids (list 20 (string-ascii 32)))
    (input-trip-ids (list 20 (string-ascii 32)))
    (processing-type (string-ascii 32)))
  (let ((facility (unwrap! (map-get? processing-facilities { facility-id: facility-id }) (err u404)))
        (current-time (unwrap-panic (get-block-info? time u0))))
    (asserts! (is-eq tx-sender (get owner facility)) (err u403))
    (asserts! (is-eq (get active facility) true) (err u403))

    (map-insert processing-batches
      { batch-id: batch-id }
      {
        facility-id: facility-id,
        input-catch-ids: input-catch-ids,
        input-trip-ids: input-trip-ids,
        processing-type: processing-type,
        start-time: current-time,
        end-time: u0,
        output-quantity: u0,
        output-unit: "",
        quality-grade: "",
        status: "in-progress"
      }
    )
    (ok true)
  )
)

;; Complete a processing batch
(define-public (complete-processing-batch
    (batch-id (string-ascii 32))
    (output-quantity uint)
    (output-unit (string-ascii 16))
    (quality-grade (string-ascii 16)))
  (let ((batch (unwrap! (map-get? processing-batches { batch-id: batch-id }) (err u404)))
        (facility (unwrap! (map-get? processing-facilities { facility-id: (get facility-id batch) }) (err u404)))
        (current-time (unwrap-panic (get-block-info? time u0))))
    (asserts! (is-eq tx-sender (get owner facility)) (err u403))
    (asserts! (is-eq (get status batch) "in-progress") (err u400))

    (map-set processing-batches
      { batch-id: batch-id }
      (merge batch {
        end-time: current-time,
        output-quantity: output-quantity,
        output-unit: output-unit,
        quality-grade: quality-grade,
        status: "completed"
      })
    )
    (ok true)
  )
)

;; Record a custody transfer
(define-public (record-custody-transfer
    (transfer-id (string-ascii 32))
    (batch-id (string-ascii 32))
    (to-entity principal)
    (transport-method (string-ascii 32))
    (transport-conditions (string-ascii 64)))
  (let ((batch (unwrap! (map-get? processing-batches { batch-id: batch-id }) (err u404)))
        (facility (unwrap! (map-get? processing-facilities { facility-id: (get facility-id batch) }) (err u404)))
        (current-time (unwrap-panic (get-block-info? time u0))))
    (asserts! (is-eq tx-sender (get owner facility)) (err u403))
    (asserts! (is-eq (get status batch) "completed") (err u400))

    (map-insert custody-transfers
      { transfer-id: transfer-id }
      {
        batch-id: batch-id,
        from-entity: tx-sender,
        to-entity: to-entity,
        transfer-time: current-time,
        transport-method: transport-method,
        transport-conditions: transport-conditions,
        verified-by: none,
        verification-time: none,
        status: "in-transit"
      }
    )
    (ok true)
  )
)

;; Verify a custody transfer
(define-public (verify-custody-transfer
    (transfer-id (string-ascii 32)))
  (let ((transfer (unwrap! (map-get? custody-transfers { transfer-id: transfer-id }) (err u404)))
        (current-time (unwrap-panic (get-block-info? time u0))))
    (asserts! (is-eq tx-sender (get to-entity transfer)) (err u403))

    (map-set custody-transfers
      { transfer-id: transfer-id }
      (merge transfer {
        verified-by: (some tx-sender),
        verification-time: (some current-time),
        status: "received"
      })
    )
    (ok true)
  )
)

;; Get facility details
(define-read-only (get-facility (facility-id (string-ascii 32)))
  (map-get? processing-facilities { facility-id: facility-id })
)

;; Get batch details
(define-read-only (get-batch (batch-id (string-ascii 32)))
  (map-get? processing-batches { batch-id: batch-id })
)

;; Get transfer details
(define-read-only (get-transfer (transfer-id (string-ascii 32)))
  (map-get? custody-transfers { transfer-id: transfer-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)


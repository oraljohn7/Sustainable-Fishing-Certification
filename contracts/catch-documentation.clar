;; Catch Documentation Contract
;; Tracks species, quantities, and locations

(define-data-var admin principal tx-sender)

;; Map of fishing trips
(define-map fishing-trips
  { trip-id: (string-ascii 32) }
  {
    vessel-id: (string-ascii 32),
    captain: principal,
    departure-time: uint,
    return-time: uint,
    departure-port: (string-ascii 64),
    return-port: (string-ascii 64),
    fishing-zone: (string-ascii 64),
    status: (string-ascii 16)
  }
)

;; Map of catch records
(define-map catch-records
  {
    trip-id: (string-ascii 32),
    catch-id: (string-ascii 32)
  }
  {
    species: (string-ascii 64),
    quantity: uint,
    unit: (string-ascii 16),
    location: {
      latitude: int,
      longitude: int
    },
    catch-time: uint,
    fishing-method: (string-ascii 32),
    quality-grade: (string-ascii 16),
    notes: (string-ascii 256)
  }
)

;; Map of catch verifications
(define-map catch-verifications
  {
    trip-id: (string-ascii 32),
    catch-id: (string-ascii 32)
  }
  {
    verifier: principal,
    verification-time: uint,
    verification-method: (string-ascii 32),
    verified: bool,
    notes: (string-ascii 256)
  }
)

;; Start a fishing trip
(define-public (start-trip
    (trip-id (string-ascii 32))
    (vessel-id (string-ascii 32))
    (departure-port (string-ascii 64))
    (fishing-zone (string-ascii 64)))
  (let ((current-time (unwrap-panic (get-block-info? time u0))))
    (asserts! (not (is-some (map-get? fishing-trips { trip-id: trip-id }))) (err u403))

    (map-insert fishing-trips
      { trip-id: trip-id }
      {
        vessel-id: vessel-id,
        captain: tx-sender,
        departure-time: current-time,
        return-time: u0,
        departure-port: departure-port,
        return-port: "",
        fishing-zone: fishing-zone,
        status: "active"
      }
    )
    (ok true)
  )
)

;; End a fishing trip
(define-public (end-trip
    (trip-id (string-ascii 32))
    (return-port (string-ascii 64)))
  (let ((trip (unwrap! (map-get? fishing-trips { trip-id: trip-id }) (err u404)))
        (current-time (unwrap-panic (get-block-info? time u0))))
    (asserts! (is-eq tx-sender (get captain trip)) (err u403))
    (asserts! (is-eq (get status trip) "active") (err u400))

    (map-set fishing-trips
      { trip-id: trip-id }
      (merge trip {
        return-time: current-time,
        return-port: return-port,
        status: "completed"
      })
    )
    (ok true)
  )
)

;; Record a catch
(define-public (record-catch
    (trip-id (string-ascii 32))
    (catch-id (string-ascii 32))
    (species (string-ascii 64))
    (quantity uint)
    (unit (string-ascii 16))
    (latitude int)
    (longitude int)
    (fishing-method (string-ascii 32))
    (quality-grade (string-ascii 16))
    (notes (string-ascii 256)))
  (let ((trip (unwrap! (map-get? fishing-trips { trip-id: trip-id }) (err u404)))
        (current-time (unwrap-panic (get-block-info? time u0))))
    (asserts! (is-eq tx-sender (get captain trip)) (err u403))
    (asserts! (is-eq (get status trip) "active") (err u400))

    (map-insert catch-records
      {
        trip-id: trip-id,
        catch-id: catch-id
      }
      {
        species: species,
        quantity: quantity,
        unit: unit,
        location: {
          latitude: latitude,
          longitude: longitude
        },
        catch-time: current-time,
        fishing-method: fishing-method,
        quality-grade: quality-grade,
        notes: notes
      }
    )
    (ok true)
  )
)

;; Verify a catch
(define-public (verify-catch
    (trip-id (string-ascii 32))
    (catch-id (string-ascii 32))
    (verification-method (string-ascii 32))
    (verified bool)
    (notes (string-ascii 256)))
  (let ((catch (unwrap! (map-get? catch-records { trip-id: trip-id, catch-id: catch-id }) (err u404)))
        (current-time (unwrap-panic (get-block-info? time u0))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (map-insert catch-verifications
      {
        trip-id: trip-id,
        catch-id: catch-id
      }
      {
        verifier: tx-sender,
        verification-time: current-time,
        verification-method: verification-method,
        verified: verified,
        notes: notes
      }
    )
    (ok true)
  )
)

;; Get trip details
(define-read-only (get-trip (trip-id (string-ascii 32)))
  (map-get? fishing-trips { trip-id: trip-id })
)

;; Get catch details
(define-read-only (get-catch (trip-id (string-ascii 32)) (catch-id (string-ascii 32)))
  (map-get? catch-records { trip-id: trip-id, catch-id: catch-id })
)

;; Get catch verification
(define-read-only (get-catch-verification (trip-id (string-ascii 32)) (catch-id (string-ascii 32)))
  (map-get? catch-verifications { trip-id: trip-id, catch-id: catch-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)


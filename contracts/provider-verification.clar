;; Provider Verification Contract
;; Validates legitimate healthcare entities

(define-data-var admin principal tx-sender)

;; Provider status: 0 = unverified, 1 = pending, 2 = verified, 3 = rejected
(define-map providers principal
  {
    status: uint,
    name: (string-utf8 100),
    license-id: (string-utf8 50),
    specialty: (string-utf8 50),
    registration-time: uint
  }
)

(define-read-only (get-provider (provider-id principal))
  (default-to
    {
      status: u0,
      name: u"",
      license-id: u"",
      specialty: u"",
      registration-time: u0
    }
    (map-get? providers provider-id)
  )
)

(define-read-only (is-verified (provider-id principal))
  (is-eq (get status (get-provider provider-id)) u2)
)

(define-public (register-provider
    (name (string-utf8 100))
    (license-id (string-utf8 50))
    (specialty (string-utf8 50)))
  (let ((provider-exists (map-get? providers tx-sender)))
    (asserts! (is-none provider-exists) (err u1)) ;; Error 1: Provider already registered
    (ok (map-set providers tx-sender
      {
        status: u1, ;; pending
        name: name,
        license-id: license-id,
        specialty: specialty,
        registration-time: block-height
      }
    ))
  )
)

(define-public (verify-provider (provider-id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Error 2: Not admin
    (asserts! (is-some (map-get? providers provider-id)) (err u3)) ;; Error 3: Provider not registered
    (ok (map-set providers provider-id
      (merge (get-provider provider-id) { status: u2 }) ;; verified
    ))
  )
)

(define-public (reject-provider (provider-id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Error 2: Not admin
    (asserts! (is-some (map-get? providers provider-id)) (err u3)) ;; Error 3: Provider not registered
    (ok (map-set providers provider-id
      (merge (get-provider provider-id) { status: u3 }) ;; rejected
    ))
  )
)

(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Error 2: Not admin
    (ok (var-set admin new-admin))
  )
)

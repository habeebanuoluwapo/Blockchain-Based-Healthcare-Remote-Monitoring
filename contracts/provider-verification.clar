;; Provider Verification Contract
;; Validates healthcare entities on the blockchain

(define-data-var admin principal tx-sender)

;; Map to store verified providers
(define-map providers
  principal
  {
    name: (string-utf8 100),
    license-number: (string-utf8 50),
    specialty: (string-utf8 50),
    verified: bool,
    timestamp: uint
  }
)

;; Public function to register a new provider
(define-public (register-provider (name (string-utf8 100)) (license-number (string-utf8 50)) (specialty (string-utf8 50)))
  (let ((provider-principal tx-sender))
    (if (is-provider provider-principal)
      (err u1) ;; Provider already exists
      (ok (map-set providers
                  provider-principal
                  {
                    name: name,
                    license-number: license-number,
                    specialty: specialty,
                    verified: false,
                    timestamp: block-height
                  }))
    )
  )
)

;; Admin function to verify a provider
(define-public (verify-provider (provider-principal principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403)) ;; Only admin can verify
    (asserts! (is-provider provider-principal) (err u404)) ;; Provider must exist

    (let ((provider-data (unwrap! (map-get? providers provider-principal) (err u404))))
      (ok (map-set providers
                  provider-principal
                  (merge provider-data {verified: true})))
    )
  )
)

;; Read-only function to check if a principal is a verified provider
(define-read-only (is-verified-provider (provider-principal principal))
  (match (map-get? providers provider-principal)
    provider-data (get verified provider-data)
    false
  )
)

;; Helper function to check if a principal is a provider (verified or not)
(define-read-only (is-provider (provider-principal principal))
  (is-some (map-get? providers provider-principal))
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)

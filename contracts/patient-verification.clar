;; Patient Verification Contract
;; Manages participant identities in the healthcare system

(define-data-var admin principal tx-sender)

;; Map to store patient data
(define-map patients
  principal
  {
    id: (string-utf8 50),
    consent-given: bool,
    provider: (optional principal),
    timestamp: uint
  }
)

;; Public function for patients to register
(define-public (register-patient (id (string-utf8 50)))
  (let ((patient-principal tx-sender))
    (if (is-patient patient-principal)
      (err u1) ;; Patient already exists
      (ok (map-set patients
                  patient-principal
                  {
                    id: id,
                    consent-given: false,
                    provider: none,
                    timestamp: block-height
                  }))
    )
  )
)

;; Function for patients to give consent for monitoring
(define-public (give-consent (provider-principal principal))
  (let ((patient-principal tx-sender))
    (asserts! (is-patient patient-principal) (err u404)) ;; Must be a registered patient

    (let ((patient-data (unwrap! (map-get? patients patient-principal) (err u404))))
      (ok (map-set patients
                  patient-principal
                  (merge patient-data {
                    consent-given: true,
                    provider: (some provider-principal)
                  })))
    )
  )
)

;; Function for patients to revoke consent
(define-public (revoke-consent)
  (let ((patient-principal tx-sender))
    (asserts! (is-patient patient-principal) (err u404)) ;; Must be a registered patient

    (let ((patient-data (unwrap! (map-get? patients patient-principal) (err u404))))
      (ok (map-set patients
                  patient-principal
                  (merge patient-data {
                    consent-given: false,
                    provider: none
                  })))
    )
  )
)

;; Read-only function to check if a principal is a patient
(define-read-only (is-patient (patient-principal principal))
  (is-some (map-get? patients patient-principal))
)

;; Read-only function to check if a patient has given consent to a provider
(define-read-only (has-consent (patient-principal principal) (provider-principal principal))
  (match (map-get? patients patient-principal)
    patient-data (and
                   (get consent-given patient-data)
                   (is-eq (some provider-principal) (get provider patient-data)))
    false
  )
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)

;; Device Registration Contract
;; Records monitoring equipment on the blockchain

(define-data-var admin principal tx-sender)

;; Map to store registered devices
(define-map devices
  {device-id: (string-utf8 50)}
  {
    device-type: (string-utf8 50),
    manufacturer: (string-utf8 100),
    owner: principal,
    is-active: bool,
    timestamp: uint
  }
)

;; Map to track devices assigned to patients
(define-map patient-devices
  principal
  (list 20 (string-utf8 50)) ;; List of device IDs assigned to a patient
)

;; Public function to register a new device (by admin or manufacturer)
(define-public (register-device
                (device-id (string-utf8 50))
                (device-type (string-utf8 50))
                (manufacturer (string-utf8 100)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403)) ;; Only admin can register devices

    (if (is-device device-id)
      (err u1) ;; Device already exists
      (ok (map-set devices
                  {device-id: device-id}
                  {
                    device-type: device-type,
                    manufacturer: manufacturer,
                    owner: tx-sender,
                    is-active: true,
                    timestamp: block-height
                  }))
    )
  )
)

;; Function to assign a device to a patient
(define-public (assign-device (device-id (string-utf8 50)) (patient-principal principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403)) ;; Only admin can assign devices
    (asserts! (is-device device-id) (err u404)) ;; Device must exist

    (let ((current-devices (default-to (list) (map-get? patient-devices patient-principal))))
      (ok (map-set patient-devices
                  patient-principal
                  (append current-devices device-id)))
    )
  )
)

;; Function to deactivate a device
(define-public (deactivate-device (device-id (string-utf8 50)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403)) ;; Only admin can deactivate
    (asserts! (is-device device-id) (err u404)) ;; Device must exist

    (let ((device-data (unwrap! (map-get? devices {device-id: device-id}) (err u404))))
      (ok (map-set devices
                  {device-id: device-id}
                  (merge device-data {is-active: false})))
    )
  )
)

;; Read-only function to check if a device exists
(define-read-only (is-device (device-id (string-utf8 50)))
  (is-some (map-get? devices {device-id: device-id}))
)

;; Read-only function to check if a device is active
(define-read-only (is-active-device (device-id (string-utf8 50)))
  (match (map-get? devices {device-id: device-id})
    device-data (get is-active device-data)
    false
  )
)

;; Read-only function to get devices assigned to a patient
(define-read-only (get-patient-devices (patient-principal principal))
  (default-to (list) (map-get? patient-devices patient-principal))
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)

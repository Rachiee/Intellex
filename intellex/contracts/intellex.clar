;; Intellectual Property Rights Management
;; Enables creators to register, manage, and monetize intellectual property rights
;; with transparent licensing, royalty distribution, and usage tracking

;; Define NFT trait locally instead of importing from an external contract
(define-trait digital-asset-trait
  (
    ;; Last token ID, limited to uint range
    (get-last-token-id () (response uint uint))
    ;; URI for metadata associated with the token
    (get-token-uri (uint) (response (optional (string-utf8 256)) uint))
    ;; Owner of a specific token
    (get-owner (uint) (response (optional principal) uint))
    ;; Transfer token to a new principal
    (transfer (uint principal principal) (response bool uint))
  )
)

;; Intellectual property registrations
(define-map creative-assets
  { asset-id: uint }
  {
    asset-title: (string-utf8 256),
    asset-description: (string-utf8 1024),
    originator: principal,
    established-at: uint,
    content-category: (string-ascii 32),     ;; "image", "music", "text", "code", "video", "design", etc.
    content-fingerprint: (buff 64),        ;; Hash of the IP content
    asset-status: (string-ascii 16),      ;; "registered", "disputed", "revoked"
    token-contract: (optional principal),  ;; Optional NFT contract for this IP
    token-identifier: (optional uint),        ;; Optional NFT ID within the contract
    open-access: bool,            ;; Whether the work is in the public domain
    expiration-block: (optional uint)  ;; Optional block height when registration expires
  }
)

;; IP ownership shares (can be fractional)
(define-map asset-ownership
  { asset-id: uint, stakeholder: principal }
  {
    ownership-percentage: uint,         ;; Out of 10000 (e.g., 5000 = 50%)
    obtained-at: uint,
    obtained-from: (optional principal)
  }
)

;; License templates
(define-map agreement-templates
  { template-identifier: uint }
  {
    template-name: (string-utf8 64),
    template-description: (string-utf8 1024),
    template-creator: principal,
    template-created-at: uint,
    permitted-uses: (list 10 (string-ascii 32)),  ;; e.g., "reproduce", "distribute", "derivative", "commercial"
    pricing-model: (string-ascii 16),        ;; "one-time", "recurring", "usage-based", "free"
    standard-fee: uint,                          ;; Default fee amount
    standard-duration: (optional uint),          ;; Default duration in blocks
    can-transfer: bool,                         ;; Whether license can be transferred
    exclusive-option: bool,                ;; Whether exclusive licenses are available
    region-limited: bool,                 ;; Whether license can be territory-restricted
    legal-document-uri: (string-utf8 256)             ;; URI to the full legal template
  }
)

;; Granted licenses
(define-map active-licenses
  { agreement-id: uint }
  {
    asset-id: uint,          ;; The IP being licensed
    template-identifier: uint,              ;; The license template used
    rights-grantor: principal,            ;; Entity granting the license
    rights-holder: principal,            ;; Entity receiving the license
    issued-at: uint,
    terminates-at: (optional uint),
    payment-made: uint,
    geographic-scope: (optional (string-ascii 64)),
    is-exclusive: bool,
    is-active: bool,
    utilization-count: uint,            ;; Counter for usage-based licensing
    utilization-limit: (optional uint),     ;; Max allowed usage
    special-terms: (optional (string-utf8 1024)),
    is-revoked: bool,
    revocation-reason: (optional (string-utf8 256))
  }
)

;; Usage logs for IP
(define-map asset-usage-records
  { asset-id: uint, usage-record-id: uint }
  {
    user: principal,
    agreement-id: (optional uint),
    activity-type: (string-ascii 32),
    service-platform: (string-ascii 64),
    activity-hash: (buff 32),          ;; Hash of usage evidence
    recorded-timestamp: uint,
    earnings-generated: (optional uint),
    is-verified: bool,
    verification-authority: (optional principal)
  }
)

;; Royalty recipients
(define-map payment-beneficiaries
  { asset-id: uint, beneficiary: principal }
  {
    beneficiary-percentage: uint,         ;; Out of 10000
    beneficiary-role: (string-ascii 16),  ;; "creator", "collaborator", "label", "publisher", etc.
    is-active: bool
  }
)

;; Royalty payments
(define-map compensation-records
  { transaction-id: uint }
  {
    asset-id: uint,
    agreement-id: (optional uint),
    payment-source: principal,
    payment-amount: uint,
    payment-timestamp: uint,
    usage-record-id: (optional uint),
    transaction-category: (string-ascii 16),  ;; "license-fee", "royalty", "settlement"
    funds-distributed: bool
  }
)

;; Dispute records
(define-map asset-disputes
  { dispute-case-id: uint }
  {
    asset-id: uint,
    dispute-initiator: principal,
    dispute-filed-at: uint,
    dispute-grounds: (string-utf8 256),
    supporting-evidence-hash: (buff 32),
    dispute-status: (string-ascii 16),      ;; "pending", "resolved", "rejected", "withdrawn"
    dispute-resolution: (optional (string-utf8 256)),
    dispute-resolver: (optional principal),
    resolution-timestamp: (optional uint)
  }
)

;; Derivative works
(define-map derived-creations
  { source-asset-id: uint, derived-asset-id: uint }
  {
    derivation-type: (string-ascii 32),  ;; "adaptation", "translation", "remix", etc.
    is-approved: bool,
    approval-timestamp: (optional uint),
    attribution-percentage: uint        ;; How much goes back to original work
  }
)

;; Next available IDs
(define-data-var next-asset-id uint u0)
(define-data-var next-template-identifier uint u0)
(define-data-var next-agreement-id uint u0)
(define-data-var next-dispute-case-id uint u0)
(define-data-var next-transaction-id uint u0)
(define-map next-usage-record-id { asset-id: uint } { id: uint })

;; Protocol configuration
(define-data-var arbitration-address principal tx-sender)
(define-data-var system-fee-percentage uint u250)  ;; 2.5% of transactions
(define-data-var dispute-submission-fee uint u1000000)   ;; 1 STX

;; Validation functions
(define-private (validate-asset-id (asset-id uint))
  (if (< asset-id (var-get next-asset-id))
      (ok asset-id)
      (err u"Invalid registration ID"))
)

(define-private (validate-utf8-256 (text (string-utf8 256)))
  (if (> (len text) u0)
      (ok text)
      (err u"Text cannot be empty"))
)

(define-private (validate-utf8-64 (text (string-utf8 64)))
  (if (> (len text) u0)
      (ok text)
      (err u"Text cannot be empty"))
)

(define-private (validate-utf8-1024 (text (string-utf8 1024)))
  (if (> (len text) u0)
      (ok text)
      (err u"Text cannot be empty"))
)

(define-private (validate-content-fingerprint (content-fingerprint (buff 64)))
  (if (> (len content-fingerprint) u0)
      (ok content-fingerprint)
      (err u"Content hash cannot be empty"))
)

(define-private (validate-template-identifier (template-identifier uint))
  (if (< template-identifier (var-get next-template-identifier))
      (ok template-identifier)
      (err u"Invalid template ID"))
)

(define-private (validate-agreement-id (agreement-id uint))
  (if (< agreement-id (var-get next-agreement-id))
      (ok agreement-id)
      (err u"Invalid license ID"))
)

(define-private (validate-dispute-case-id (dispute-case-id uint))
  (if (< dispute-case-id (var-get next-dispute-case-id))
      (ok dispute-case-id)
      (err u"Invalid dispute ID"))
)

(define-private (validate-usage-record-id (asset-id uint) (usage-record-id uint))
  (match (map-get? next-usage-record-id { asset-id: asset-id })
    counter (if (< usage-record-id (get id counter))
               (ok usage-record-id)
               (err u"Invalid usage ID"))
    (err u"Registration ID not found"))
)

(define-private (validate-derivation-type (derivation-type (string-ascii 32)))
  (if (or (is-eq derivation-type "adaptation")
          (or (is-eq derivation-type "translation")
              (or (is-eq derivation-type "remix")
                  (is-eq derivation-type "derivative"))))
      (ok derivation-type)
      (err u"Invalid relationship type"))
)

(define-private (validate-activity-type (activity-type (string-ascii 32)))
  (if (or (is-eq activity-type "online-display")
          (or (is-eq activity-type "broadcast")
              (or (is-eq activity-type "print")
                  (or (is-eq activity-type "merchandise")
                      (is-eq activity-type "performance")))))
      (ok activity-type)
      (err u"Invalid usage type"))
)

(define-private (validate-beneficiary-role (beneficiary-role (string-ascii 16)))
  (if (or (is-eq beneficiary-role "creator")
          (or (is-eq beneficiary-role "collaborator")
              (or (is-eq beneficiary-role "label")
                  (or (is-eq beneficiary-role "publisher")
                      (is-eq beneficiary-role "distributor")))))
      (ok beneficiary-role)
      (err u"Invalid recipient type"))
)

(define-private (validate-transaction-category (transaction-category (string-ascii 16)))
  (if (or (is-eq transaction-category "license-fee")
          (or (is-eq transaction-category "royalty")
              (is-eq transaction-category "settlement")))
      (ok transaction-category)
      (err u"Invalid payment type"))
)

;; Register new intellectual property
(define-public (register-creative-asset
                (asset-title (string-utf8 256))
                (asset-description (string-utf8 1024))
                (content-category (string-ascii 32))
                (content-fingerprint (buff 64))
                (open-access bool)
                (expiration-block (optional uint)))
  (let
    ((validated-title-resp (validate-utf8-256 asset-title))
     (validated-description-resp (validate-utf8-1024 asset-description))
     (validated-fingerprint-resp (validate-content-fingerprint content-fingerprint))
     (asset-id (var-get next-asset-id)))
    
    ;; Validate parameters
    (asserts! (is-valid-content-category content-category) (err u"Invalid IP type"))
    (asserts! (is-ok validated-title-resp) (err (unwrap-err! validated-title-resp (err u"Title validation failed"))))
    (asserts! (is-ok validated-description-resp) (err (unwrap-err! validated-description-resp (err u"Description validation failed"))))
    (asserts! (is-ok validated-fingerprint-resp) (err (unwrap-err! validated-fingerprint-resp (err u"Content hash validation failed"))))
    
    ;; Create the registration
    (map-set creative-assets
      { asset-id: asset-id }
      {
        asset-title: (unwrap-panic validated-title-resp),
        asset-description: (unwrap-panic validated-description-resp),
        originator: tx-sender,
        established-at: block-height,
        content-category: content-category,
        content-fingerprint: (unwrap-panic validated-fingerprint-resp),
        asset-status: "registered",
        token-contract: none,
        token-identifier: none,
        open-access: open-access,
        expiration-block: expiration-block
      }
    )
    
    ;; Set initial ownership
    (map-set asset-ownership
      { asset-id: asset-id, stakeholder: tx-sender }
      {
        ownership-percentage: u10000,     ;; 100%
        obtained-at: block-height,
        obtained-from: none
      }
    )
    
    ;; Initialize usage counter
    (map-set next-usage-record-id
      { asset-id: asset-id }
      { id: u0 }
    )
    
    ;; Increment registration ID counter
    (var-set next-asset-id (+ asset-id u1))
    
    (ok asset-id)
  )
)

;; Check if IP type is valid
(define-private (is-valid-content-category (content-category (string-ascii 32)))
  (or (is-eq content-category "image")
      (or (is-eq content-category "music")
          (or (is-eq content-category "text")
              (or (is-eq content-category "code")
                  (or (is-eq content-category "video")
                      (is-eq content-category "design"))))))
)

;; Link an NFT to an IP registration
(define-public (link-token-to-asset
                (asset-id uint)
                (token-contract principal)
                (token-identifier uint))
  (let
    ((validated-id-resp (validate-asset-id asset-id)))
    
    ;; Validate registration ID is valid
    (asserts! (is-ok validated-id-resp) 
              (err (unwrap-err! validated-id-resp (err u"Invalid registration ID"))))
    
    (let ((validated-id (unwrap-panic validated-id-resp)))
      ;; Get the registration
      (let ((asset (unwrap! (map-get? creative-assets { asset-id: validated-id }) 
                                  (err u"Registration not found"))))
        ;; Validate
        (asserts! (is-eq tx-sender (get originator asset)) 
                  (err u"Only creator can link NFT"))
        (asserts! (is-eq (get asset-status asset) "registered") 
                  (err u"Registration not in valid state"))
        
        ;; TODO: In a real implementation, verify NFT ownership
        
        ;; Update registration with NFT info
        (map-set creative-assets
          { asset-id: validated-id }
          (merge asset 
            { 
              token-contract: (some token-contract),
              token-identifier: (some token-identifier)
            }
          )
        )
        
        (ok true)
      )
    )
  )
)

;; Create a license template
(define-public (create-agreement-template
                (template-name (string-utf8 64))
                (template-description (string-utf8 1024))
                (permitted-uses (list 10 (string-ascii 32)))
                (pricing-model (string-ascii 16))
                (standard-fee uint)
                (standard-duration (optional uint))
                (can-transfer bool)
                (exclusive-option bool)
                (region-limited bool)
                (legal-document-uri (string-utf8 256)))
  (let
    ((validated-name-resp (validate-utf8-64 template-name))
     (validated-description-resp (validate-utf8-1024 template-description))
     (template-identifier (var-get next-template-identifier)))
    
    ;; Validate parameters
    (asserts! (is-ok validated-name-resp) 
              (err (unwrap-err! validated-name-resp (err u"Name validation failed"))))
    (asserts! (is-ok validated-description-resp) 
              (err (unwrap-err! validated-description-resp (err u"Description validation failed"))))
    (asserts! (is-valid-pricing-model pricing-model) (err u"Invalid fee type"))
    (asserts! (> (len permitted-uses) u0) (err u"Must provide at least one usage right"))
    
    (let
      ((validated-name (unwrap-panic validated-name-resp))
       (validated-description (unwrap-panic validated-description-resp)))
      
      ;; Create the template
      (map-set agreement-templates
        { template-identifier: template-identifier }
        {
          template-name: validated-name,
          template-description: validated-description,
          template-creator: tx-sender,
          template-created-at: block-height,
          permitted-uses: permitted-uses,
          pricing-model: pricing-model,
          standard-fee: standard-fee,
          standard-duration: standard-duration,
          can-transfer: can-transfer,
          exclusive-option: exclusive-option,
          region-limited: region-limited,
          legal-document-uri: legal-document-uri
        }
      )
      
      ;; Increment template ID counter
      (var-set next-template-identifier (+ template-identifier u1))
      
      (ok template-identifier)
    )
  )
)

;; Check if fee type is valid
(define-private (is-valid-pricing-model (pricing-model (string-ascii 16)))
  (or (is-eq pricing-model "one-time")
      (or (is-eq pricing-model "recurring")
          (or (is-eq pricing-model "usage-based")
              (is-eq pricing-model "free"))))
)

;; Grant a license to use IP - split into free and paid versions
;; This version is for free licenses (fee = 0)
(define-public (grant-free-agreement
                (asset-id uint)
                (template-identifier uint)
                (rights-holder principal)
                (duration (optional uint))
                (geographic-scope (optional (string-ascii 64)))
                (is-exclusive bool)
                (utilization-limit (optional uint))
                (special-terms (optional (string-utf8 1024))))
  (let
    ((validated-asset-id-resp (validate-asset-id asset-id))
     (validated-template-id-resp (validate-template-identifier template-identifier)))
    
    ;; Check validation results
    (asserts! (is-ok validated-asset-id-resp) 
              (err (unwrap-err! validated-asset-id-resp (err u"Invalid registration ID"))))
    (asserts! (is-ok validated-template-id-resp) 
              (err (unwrap-err! validated-template-id-resp (err u"Invalid template ID"))))
    
    (let ((validated-asset-id (unwrap-panic validated-asset-id-resp))
          (validated-template-id (unwrap-panic validated-template-id-resp)))
      
      ;; Get registration and template records
      (let ((asset (unwrap! (map-get? creative-assets { asset-id: validated-asset-id }) 
                                 (err u"Registration not found")))
            (template (unwrap! (map-get? agreement-templates { template-identifier: validated-template-id }) 
                             (err u"Template not found")))
            (ownership (unwrap! (map-get? asset-ownership 
                               { asset-id: validated-asset-id, stakeholder: tx-sender })
                              (err u"Not an owner of this IP")))
            (agreement-id (var-get next-agreement-id)))
        
        ;; Validate
        (asserts! (is-eq (get asset-status asset) "registered") 
                  (err u"Registration not in valid state"))
        (asserts! (not (get open-access asset)) 
                  (err u"Public domain works don't require licenses"))
        (asserts! (or (not is-exclusive) (get exclusive-option template)) 
                  (err u"Exclusive license not available for this template"))
        (asserts! (or (is-none geographic-scope) (get region-limited template)) 
                  (err u"Territory restrictions not available for this template"))
        
        ;; Calculate expiration if duration provided
        (let ((expiry (if (is-some duration)
                          (some (+ block-height (unwrap-panic duration)))
                          (get standard-duration template))))
          
          ;; Create the license grant
          (map-set active-licenses
            { agreement-id: agreement-id }
            {
              asset-id: validated-asset-id,
              template-identifier: validated-template-id,
              rights-grantor: tx-sender,
              rights-holder: rights-holder,
              issued-at: block-height,
              terminates-at: expiry,
              payment-made: u0,  ;; Free license
              geographic-scope: geographic-scope,
              is-exclusive: is-exclusive,
              is-active: true,
              utilization-count: u0,
              utilization-limit: utilization-limit,
              special-terms: special-terms,
              is-revoked: false,
              revocation-reason: none
            }
          )
          
          ;; Increment license ID counter
          (var-set next-agreement-id (+ agreement-id u1))
          
          (ok agreement-id)
        )
      )
    )
  )
)

;; Grant a license with payment
(define-public (grant-paid-agreement
                (asset-id uint)
                (template-identifier uint)
                (rights-holder principal)
                (payment-amount uint)  ;; Must be > 0
                (duration (optional uint))
                (geographic-scope (optional (string-ascii 64)))
                (is-exclusive bool)
                (utilization-limit (optional uint))
                (special-terms (optional (string-utf8 1024))))
  (let
    ((validated-asset-id-resp (validate-asset-id asset-id))
     (validated-template-id-resp (validate-template-identifier template-identifier)))
    
    ;; Check validation results
    (asserts! (is-ok validated-asset-id-resp) 
              (err (unwrap-err! validated-asset-id-resp (err u"Invalid registration ID"))))
    (asserts! (is-ok validated-template-id-resp) 
              (err (unwrap-err! validated-template-id-resp (err u"Invalid template ID"))))
    
    (let ((validated-asset-id (unwrap-panic validated-asset-id-resp))
          (validated-template-id (unwrap-panic validated-template-id-resp)))
      
      ;; Get registration and template records
      (let ((asset (unwrap! (map-get? creative-assets { asset-id: validated-asset-id }) 
                                 (err u"Registration not found")))
            (template (unwrap! (map-get? agreement-templates { template-identifier: validated-template-id }) 
                             (err u"Template not found")))
            (ownership (unwrap! (map-get? asset-ownership 
                               { asset-id: validated-asset-id, stakeholder: tx-sender })
                              (err u"Not an owner of this IP")))
            (agreement-id (var-get next-agreement-id))
            (system-fee (/ (* payment-amount (var-get system-fee-percentage)) u10000)))
        
        ;; Validate
        (asserts! (is-eq (get asset-status asset) "registered") 
                  (err u"Registration not in valid state"))
        (asserts! (not (get open-access asset)) 
                  (err u"Public domain works don't require licenses"))
        (asserts! (or (not is-exclusive) (get exclusive-option template)) 
                  (err u"Exclusive license not available for this template"))
        (asserts! (or (is-none geographic-scope) (get region-limited template)) 
                  (err u"Territory restrictions not available for this template"))
        (asserts! (> payment-amount u0) (err u"Fee must be greater than 0"))
        
        ;; Transfer fee from licensee
        (asserts! (is-ok (stx-transfer? payment-amount rights-holder (as-contract tx-sender))) 
                  (err u"License fee transfer failed"))
        
        ;; Transfer protocol fee
        (asserts! (is-ok (as-contract (stx-transfer? system-fee tx-sender (var-get arbitration-address))))
                  (err u"Protocol fee transfer failed"))
        
        ;; Calculate expiration if duration provided
        (let ((expiry (if (is-some duration)
                          (some (+ block-height (unwrap-panic duration)))
                          (get standard-duration template))))
          
          ;; Create the license grant
          (map-set active-licenses
            { agreement-id: agreement-id }
            {
              asset-id: validated-asset-id,
              template-identifier: validated-template-id,
              rights-grantor: tx-sender,
              rights-holder: rights-holder,
              issued-at: block-height,
              terminates-at: expiry,
              payment-made: payment-amount,
              geographic-scope: geographic-scope,
              is-exclusive: is-exclusive,
              is-active: true,
              utilization-count: u0,
              utilization-limit: utilization-limit,
              special-terms: special-terms,
              is-revoked: false,
              revocation-reason: none
            }
          )
          
          ;; Record payment
          (let ((transaction-id (var-get next-transaction-id)))
            ;; Create payment record
            (map-set compensation-records
              { transaction-id: transaction-id }
              {
                asset-id: validated-asset-id,
                agreement-id: (some agreement-id),
                payment-source: rights-holder,
                payment-amount: payment-amount,
                payment-timestamp: block-height,
                usage-record-id: none,
                transaction-category: "license-fee",
                funds-distributed: true  ;; Simplified for this example
              }
            )
            
            ;; Increment payment ID counter
            (var-set next-transaction-id (+ transaction-id u1))
          )
          
          ;; Increment license ID counter
          (var-set next-agreement-id (+ agreement-id u1))
          
          (ok agreement-id)
        )
      )
    )
  )
)

;; Record IP usage
(define-public (record-asset-usage
                (asset-id uint)
                (agreement-id (optional uint))
                (activity-type (string-ascii 32))
                (service-platform (string-ascii 64))
                (activity-hash (buff 32))
                (earnings-generated (optional uint)))
  (let
    ((validated-asset-id-resp (validate-asset-id asset-id))
     (validated-activity-type-resp (validate-activity-type activity-type)))
    
    ;; Validate parameters
    (asserts! (is-ok validated-asset-id-resp) 
              (err (unwrap-err! validated-asset-id-resp (err u"Invalid registration ID"))))
    (asserts! (is-ok validated-activity-type-resp) 
              (err (unwrap-err! validated-activity-type-resp (err u"Invalid usage type"))))
    
    (let ((validated-asset-id (unwrap-panic validated-asset-id-resp))
          (validated-activity-type (unwrap-panic validated-activity-type-resp)))
      
      ;; Get registration and usage counter
      (let ((asset (unwrap! (map-get? creative-assets 
                                 { asset-id: validated-asset-id }) 
                                (err u"Registration not found")))
            (usage-counter (unwrap! (map-get? next-usage-record-id 
                                  { asset-id: validated-asset-id }) 
                                   (err u"Counter not found")))
            (usage-record-id (get id usage-counter)))
        
        ;; Validate license if provided
        (if (is-some agreement-id)
            (let ((agreement-id-value (unwrap-panic agreement-id))
                  (validated-agreement-id-resp (validate-agreement-id (unwrap-panic agreement-id))))
              
              (asserts! (is-ok validated-agreement-id-resp)
                        (err (unwrap-err! validated-agreement-id-resp (err u"Invalid license ID"))))
              
              (let ((validated-agreement-id (unwrap-panic validated-agreement-id-resp))
                    (license (unwrap! (map-get? active-licenses 
                                     { agreement-id: validated-agreement-id })
                                    (err u"License not found"))))
                ;; Check license validity
                (asserts! (and (is-eq (get asset-id license) validated-asset-id)
                              (is-eq (get rights-holder license) tx-sender))
                          (err u"Invalid license for this usage"))
                (asserts! (get is-active license) (err u"License not active"))
                (asserts! (not (get is-revoked license)) (err u"License revoked"))
                
                ;; Check license expiration
                (if (is-some (get terminates-at license))
                    (asserts! (< block-height (unwrap-panic (get terminates-at license))) 
                              (err u"License expired"))
                    true)
                
                ;; Check usage limits
                (if (is-some (get utilization-limit license))
                    (asserts! (< (get utilization-count license) (unwrap-panic (get utilization-limit license)))
                              (err u"Usage limit exceeded"))
                    true)
                
                ;; Update usage counter for license
                (map-set active-licenses
                  { agreement-id: validated-agreement-id }
                  (merge license { utilization-count: (+ (get utilization-count license) u1) })
                )
              )
            )
            ;; If no license provided, ensure the work is public domain
            (asserts! (get open-access asset) (err u"Non-public domain works require a license"))
        )
        
        ;; Create the usage record
        (map-set asset-usage-records
          { asset-id: validated-asset-id, usage-record-id: usage-record-id }
          {
            user: tx-sender,
            agreement-id: agreement-id,
            activity-type: validated-activity-type,
            service-platform: service-platform,
            activity-hash: activity-hash,
            recorded-timestamp: block-height,
            earnings-generated: earnings-generated,
            is-verified: false,
            verification-authority: none
          }
        )
        
        ;; Increment usage counter
        (map-set next-usage-record-id
          { asset-id: validated-asset-id }
          { id: (+ usage-record-id u1) }
        )
        
        ;; If revenue was generated, process royalty payment
        (if (and (is-some earnings-generated) (> (unwrap-panic earnings-generated) u0))
            (record-usage-compensation validated-asset-id usage-record-id (unwrap-panic earnings-generated))
            (ok usage-record-id))
      )
    )
  )
)

;; Record royalty from usage revenue
(define-public (record-usage-compensation (asset-id uint) (usage-record-id uint) (revenue uint))
  (let
    ((validated-asset-id-resp (validate-asset-id asset-id)))
    
    ;; Validate registration ID
    (asserts! (is-ok validated-asset-id-resp) 
              (err (unwrap-err! validated-asset-id-resp (err u"Invalid registration ID"))))
    
    (let ((validated-asset-id (unwrap-panic validated-asset-id-resp)))
      ;; Validate usage ID with the unwrapped registration ID
      (let ((validated-usage-id-resp (validate-usage-record-id validated-asset-id usage-record-id)))
        
        ;; Check if usage ID is valid
        (asserts! (is-ok validated-usage-id-resp)
                  (err (unwrap-err! validated-usage-id-resp (err u"Invalid usage ID"))))
        
        (let ((validated-usage-id (unwrap-panic validated-usage-id-resp))
              (standard-compensation-rate u1000)  ;; 10% standard rate
              (compensation-amount (/ (* revenue standard-compensation-rate) u10000))
              (transaction-id (var-get next-transaction-id)))
          
          ;; Create payment record
          (map-set compensation-records
            { transaction-id: transaction-id }
            {
              asset-id: validated-asset-id,
              agreement-id: none,
              payment-source: tx-sender,
              payment-amount: compensation-amount,
              payment-timestamp: block-height,
              usage-record-id: (some validated-usage-id),
              transaction-category: "royalty",
              funds-distributed: false
            }
          )
          
          ;; Increment payment ID counter
          (var-set next-transaction-id (+ transaction-id u1))
          
          ;; Transfer royalty payment
          (asserts! (is-ok (stx-transfer? compensation-amount tx-sender (as-contract tx-sender)))
                    (err u"Royalty payment transfer failed"))
          
          ;; Mark as distributed
          (map-set compensation-records
            { transaction-id: transaction-id }
            (merge (unwrap-panic (map-get? compensation-records { transaction-id: transaction-id }))
              { funds-distributed: true })
          )
          
          (ok transaction-id)
        )
      )
    )
  )
)

;; Verify IP usage
(define-public (verify-asset-usage (asset-id uint) (usage-record-id uint))
  (let
    ((validated-asset-id-resp (validate-asset-id asset-id)))
    
    ;; Validate registration ID
    (asserts! (is-ok validated-asset-id-resp) 
              (err (unwrap-err! validated-asset-id-resp (err u"Invalid registration ID"))))
    
    (let ((validated-asset-id (unwrap-panic validated-asset-id-resp)))
      ;; Validate usage ID with the unwrapped registration ID
      (let ((validated-usage-id-resp (validate-usage-record-id validated-asset-id usage-record-id)))
        
        ;; Check if usage ID is valid
        (asserts! (is-ok validated-usage-id-resp)
                  (err (unwrap-err! validated-usage-id-resp (err u"Invalid usage ID"))))
        
        (let ((validated-usage-id (unwrap-panic validated-usage-id-resp))
              (asset (unwrap! (map-get? creative-assets 
                                     { asset-id: validated-asset-id }) 
                                    (err u"Registration not found")))
              (usage (unwrap! (map-get? asset-usage-records 
                             { asset-id: validated-asset-id, usage-record-id: validated-usage-id })
                            (err u"Usage not found"))))
          
          ;; Validate
          (asserts! (or (is-eq tx-sender (get originator asset))
                       (is-asset-stakeholder validated-asset-id tx-sender))
                    (err u"Not authorized to verify usage"))
          
          ;; Update usage verification
          (map-set asset-usage-records
            { asset-id: validated-asset-id, usage-record-id: validated-usage-id }
            (merge usage { 
              is-verified: true,
              verification-authority: (some tx-sender)
            })
          )
          
          (ok true)
        )
      )
    )
  )
)

;; Check if principal is an IP owner
(define-private (is-asset-stakeholder (asset-id uint) (user principal))
  (is-some (map-get? asset-ownership { asset-id: asset-id, stakeholder: user }))
)

;; Transfer IP ownership shares
(define-public (transfer-asset-shares
                (asset-id uint)
                (recipient principal)
                (ownership-percentage uint))
  (let
    ((validated-asset-id-resp (validate-asset-id asset-id)))
    
    ;; Validate registration ID
    (asserts! (is-ok validated-asset-id-resp) 
              (err (unwrap-err! validated-asset-id-resp (err u"Invalid registration ID"))))
    
    (let ((validated-asset-id (unwrap-panic validated-asset-id-resp))
          (asset (unwrap! (map-get? creative-assets 
                               { asset-id: (unwrap-panic validated-asset-id-resp) }) 
                              (err u"Registration not found")))
          (sender-ownership (unwrap! (map-get? asset-ownership 
                                   { asset-id: (unwrap-panic validated-asset-id-resp), stakeholder: tx-sender })
                                  (err u"No ownership found")))
          (recipient-ownership (map-get? asset-ownership 
                              { asset-id: (unwrap-panic validated-asset-id-resp), stakeholder: recipient })))
      
      ;; Validate
      (asserts! (is-eq (get asset-status asset) "registered") 
                (err u"Registration not in valid state"))
      (asserts! (<= ownership-percentage (get ownership-percentage sender-ownership)) 
                (err u"Insufficient ownership shares"))
      (asserts! (> ownership-percentage u0) 
                (err u"Share percentage must be greater than zero"))
      
      ;; Update sender's ownership
      (map-set asset-ownership
        { asset-id: validated-asset-id, stakeholder: tx-sender }
        (merge sender-ownership 
          { ownership-percentage: (- (get ownership-percentage sender-ownership) ownership-percentage) }
        )
      )
      
      ;; Update or create recipient's ownership
      (if (is-some recipient-ownership)
          (map-set asset-ownership
            { asset-id: validated-asset-id, stakeholder: recipient }
            (merge (unwrap-panic recipient-ownership)
              { 
                ownership-percentage: (+ (get ownership-percentage (unwrap-panic recipient-ownership)) 
                                   ownership-percentage),
                obtained-at: block-height,
                obtained-from: (some tx-sender)
              }
            )
          )
          (map-set asset-ownership
            { asset-id: validated-asset-id, stakeholder: recipient }
            {
              ownership-percentage: ownership-percentage,
              obtained-at: block-height,
              obtained-from: (some tx-sender)
            }
          )
      )
      
      (ok true)
    )
  )
)
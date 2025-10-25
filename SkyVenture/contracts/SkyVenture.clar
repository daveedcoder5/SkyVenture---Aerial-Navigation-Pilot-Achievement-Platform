;; SkyVenture - Aerial Navigation & Pilot Achievement Platform
;; A decentralized platform for airspace mapping, expedition tracking,
;; and aviator community incentives

;; Contract constants
(define-constant contract-admin tx-sender)
(define-constant err-admin-only (err u100))
(define-constant err-record-not-found (err u101))
(define-constant err-duplicate-entry (err u102))
(define-constant err-access-denied (err u103))
(define-constant err-invalid-parameter (err u104))

;; Token configuration
(define-constant token-title "SkyVenture Aviator Token")
(define-constant token-ticker "SVT")
(define-constant token-precision u6)
(define-constant token-ceiling u35000000000) ;; 35k tokens with 6 decimals

;; Incentive amounts (in micro-tokens)
(define-constant incentive-expedition u2300000) ;; 2.3 SVT
(define-constant incentive-airspace u2700000) ;; 2.7 SVT
(define-constant incentive-achievement u9800000) ;; 9.8 SVT

;; State variables
(define-data-var tokens-minted uint u0)
(define-data-var airspace-counter uint u1)
(define-data-var expedition-counter uint u1)

;; Token ledger
(define-map token-ledger principal uint)

;; Aviator registry
(define-map aviator-registry
  principal
  {
    handle: (string-ascii 24),
    craft-category: (string-ascii 12), ;; "racing", "photography", "mapping", "freestyle", "commercial"
    expeditions-completed: uint,
    airspaces-discovered: uint,
    airtime-hours: uint,
    aviator-rank: uint, ;; 1-5
    registration-block: uint
  }
)

;; Airspace registry
(define-map airspace-registry
  uint
  {
    location-name: (string-ascii 30),
    geo-coordinates: (string-ascii 24),
    airspace-category: (string-ascii 12), ;; "open", "restricted", "recreational", "commercial"
    ceiling-meters: uint,
    landscape: (string-ascii 12), ;; "urban", "rural", "coastal", "mountain"
    regulatory-notes: (string-ascii 20),
    registered-by: principal,
    expedition-tally: uint,
    community-score: uint
  }
)

;; Expedition ledger
(define-map expedition-ledger
  uint
  {
    airspace-ref: uint,
    aviator: principal,
    duration-minutes: uint,
    peak-altitude: uint, ;; meters
    atmospheric-state: (string-ascii 8), ;; "clear", "windy", "cloudy"
    expedition-purpose: (string-ascii 12), ;; "recreation", "photography", "survey", "practice"
    expedition-memo: (string-ascii 100),
    expedition-block: uint,
    completed-safely: bool
  }
)

;; Airspace feedback
(define-map airspace-feedback
  { airspace-ref: uint, evaluator: principal }
  {
    score: uint, ;; 1-10
    feedback-memo: (string-ascii 110),
    safety-assessment: (string-ascii 8), ;; "excellent", "good", "fair", "risky"
    feedback-block: uint,
    endorsement-count: uint
  }
)

;; Aviator achievements
(define-map aviator-achievements
  { aviator: principal, achievement-key: (string-ascii 12) }
  {
    unlocked-block: uint,
    expedition-count: uint
  }
)

;; Helper function to retrieve or initialize aviator profile
(define-private (retrieve-or-init-aviator (aviator principal))
  (match (map-get? aviator-registry aviator)
    profile profile
    {
      handle: "",
      craft-category: "photography",
      expeditions-completed: u0,
      airspaces-discovered: u0,
      airtime-hours: u0,
      aviator-rank: u1,
      registration-block: stacks-block-height
    }
  )
)

;; Token interface functions
(define-read-only (get-name)
  (ok token-title)
)

(define-read-only (get-symbol)
  (ok token-ticker)
)

(define-read-only (get-decimals)
  (ok token-precision)
)

(define-read-only (get-balance (account principal))
  (ok (default-to u0 (map-get? token-ledger account)))
)

(define-private (issue-tokens (beneficiary principal) (quantity uint))
  (let (
    (existing-balance (default-to u0 (map-get? token-ledger beneficiary)))
    (updated-balance (+ existing-balance quantity))
    (updated-supply (+ (var-get tokens-minted) quantity))
  )
    (asserts! (<= updated-supply token-ceiling) err-invalid-parameter)
    (map-set token-ledger beneficiary updated-balance)
    (var-set tokens-minted updated-supply)
    (ok quantity)
  )
)

;; Register new airspace
(define-public (register-airspace (location-name (string-ascii 30)) (geo-coordinates (string-ascii 24)) (airspace-category (string-ascii 12)) (ceiling-meters uint) (landscape (string-ascii 12)) (regulatory-notes (string-ascii 20)))
  (let (
    (airspace-id (var-get airspace-counter))
    (profile (retrieve-or-init-aviator tx-sender))
  )
    (asserts! (> (len location-name) u0) err-invalid-parameter)
    (asserts! (> (len geo-coordinates) u0) err-invalid-parameter)
    (asserts! (> ceiling-meters u0) err-invalid-parameter)
    
    (map-set airspace-registry airspace-id {
      location-name: location-name,
      geo-coordinates: geo-coordinates,
      airspace-category: airspace-category,
      ceiling-meters: ceiling-meters,
      landscape: landscape,
      regulatory-notes: regulatory-notes,
      registered-by: tx-sender,
      expedition-tally: u0,
      community-score: u0
    })
    
    ;; Update aviator profile
    (map-set aviator-registry tx-sender
      (merge profile {airspaces-discovered: (+ (get airspaces-discovered profile) u1)})
    )
    
    ;; Distribute airspace registration incentive
    (try! (issue-tokens tx-sender incentive-airspace))
    
    (var-set airspace-counter (+ airspace-id u1))
    (print {event: "airspace-registered", airspace-id: airspace-id, registered-by: tx-sender})
    (ok airspace-id)
  )
)

;; Record expedition
(define-public (record-expedition (airspace-ref uint) (duration-minutes uint) (peak-altitude uint) (atmospheric-state (string-ascii 8)) (expedition-purpose (string-ascii 12)) (expedition-memo (string-ascii 100)) (completed-safely bool))
  (let (
    (expedition-id (var-get expedition-counter))
    (airspace (unwrap! (map-get? airspace-registry airspace-ref) err-record-not-found))
    (profile (retrieve-or-init-aviator tx-sender))
  )
    (asserts! (> duration-minutes u0) err-invalid-parameter)
    (asserts! (<= peak-altitude (get ceiling-meters airspace)) err-invalid-parameter)
    
    (map-set expedition-ledger expedition-id {
      airspace-ref: airspace-ref,
      aviator: tx-sender,
      duration-minutes: duration-minutes,
      peak-altitude: peak-altitude,
      atmospheric-state: atmospheric-state,
      expedition-purpose: expedition-purpose,
      expedition-memo: expedition-memo,
      expedition-block: stacks-block-height,
      completed-safely: completed-safely
    })
    
    ;; Update airspace expedition count
    (map-set airspace-registry airspace-ref
      (merge airspace {expedition-tally: (+ (get expedition-tally airspace) u1)})
    )
    
    ;; Update aviator profile and distribute incentives
    (if completed-safely
      (begin
        (map-set aviator-registry tx-sender
          (merge profile {
            expeditions-completed: (+ (get expeditions-completed profile) u1),
            airtime-hours: (+ (get airtime-hours profile) (/ duration-minutes u60)),
            aviator-rank: (+ (get aviator-rank profile) (/ duration-minutes u45))
          })
        )
        (try! (issue-tokens tx-sender incentive-expedition))
        true
      )
      (begin
        (map-set aviator-registry tx-sender
          (merge profile {expeditions-completed: (+ (get expeditions-completed profile) u1)})
        )
        (try! (issue-tokens tx-sender (/ incentive-expedition u4)))
        true
      )
    )
    
    (var-set expedition-counter (+ expedition-id u1))
    (print {event: "expedition-recorded", expedition-id: expedition-id, airspace-ref: airspace-ref})
    (ok expedition-id)
  )
)

;; Submit airspace feedback
(define-public (submit-feedback (airspace-ref uint) (score uint) (feedback-memo (string-ascii 110)) (safety-assessment (string-ascii 8)))
  (let (
    (airspace (unwrap! (map-get? airspace-registry airspace-ref) err-record-not-found))
    (profile (retrieve-or-init-aviator tx-sender))
  )
    (asserts! (and (>= score u1) (<= score u10)) err-invalid-parameter)
    (asserts! (> (len feedback-memo) u0) err-invalid-parameter)
    (asserts! (is-none (map-get? airspace-feedback {airspace-ref: airspace-ref, evaluator: tx-sender})) err-duplicate-entry)
    
    (map-set airspace-feedback {airspace-ref: airspace-ref, evaluator: tx-sender} {
      score: score,
      feedback-memo: feedback-memo,
      safety-assessment: safety-assessment,
      feedback-block: stacks-block-height,
      endorsement-count: u0
    })
    
    ;; Update airspace community score
    (let (
      (current-score (get community-score airspace))
      (expedition-tally (get expedition-tally airspace))
      (updated-score (if (> expedition-tally u0)
                 (/ (+ (* current-score expedition-tally) score) (+ expedition-tally u1))
                 score))
    )
      (map-set airspace-registry airspace-ref (merge airspace {community-score: updated-score}))
    )
    
    (print {event: "feedback-submitted", airspace-ref: airspace-ref, evaluator: tx-sender})
    (ok true)
  )
)

;; Endorse feedback
(define-public (endorse-feedback (airspace-ref uint) (evaluator principal))
  (let (
    (feedback (unwrap! (map-get? airspace-feedback {airspace-ref: airspace-ref, evaluator: evaluator}) err-record-not-found))
  )
    (asserts! (not (is-eq tx-sender evaluator)) err-access-denied)
    
    (map-set airspace-feedback {airspace-ref: airspace-ref, evaluator: evaluator}
      (merge feedback {endorsement-count: (+ (get endorsement-count feedback) u1)})
    )
    
    (print {event: "feedback-endorsed", airspace-ref: airspace-ref, evaluator: evaluator})
    (ok true)
  )
)

;; Update craft category
(define-public (update-craft-category (new-craft-category (string-ascii 12)))
  (let (
    (profile (retrieve-or-init-aviator tx-sender))
  )
    (asserts! (> (len new-craft-category) u0) err-invalid-parameter)
    
    (map-set aviator-registry tx-sender (merge profile {craft-category: new-craft-category}))
    
    (print {event: "craft-category-updated", aviator: tx-sender, category: new-craft-category})
    (ok true)
  )
)

;; Unlock achievement
(define-public (unlock-achievement (achievement-key (string-ascii 12)))
  (let (
    (profile (retrieve-or-init-aviator tx-sender))
  )
    (asserts! (is-none (map-get? aviator-achievements {aviator: tx-sender, achievement-key: achievement-key})) err-duplicate-entry)
    
    ;; Validate achievement criteria
    (let (
      (criteria-met
        (if (is-eq achievement-key "pilot-60") (>= (get expeditions-completed profile) u60)
        (if (is-eq achievement-key "explorer-11") (>= (get airspaces-discovered profile) u11)
        false)))
    )
      (asserts! criteria-met err-access-denied)
      
      ;; Register achievement
      (map-set aviator-achievements {aviator: tx-sender, achievement-key: achievement-key} {
        unlocked-block: stacks-block-height,
        expedition-count: (get expeditions-completed profile)
      })
      
      ;; Distribute achievement incentive
      (try! (issue-tokens tx-sender incentive-achievement))
      
      (print {event: "achievement-unlocked", aviator: tx-sender, achievement-key: achievement-key})
      (ok true)
    )
  )
)

;; Update aviator handle
(define-public (update-handle (new-handle (string-ascii 24)))
  (let (
    (profile (retrieve-or-init-aviator tx-sender))
  )
    (asserts! (> (len new-handle) u0) err-invalid-parameter)
    (map-set aviator-registry tx-sender (merge profile {handle: new-handle}))
    (print {event: "handle-updated", aviator: tx-sender})
    (ok true)
  )
)

;; Query functions
(define-read-only (get-aviator-profile (aviator principal))
  (map-get? aviator-registry aviator)
)

(define-read-only (get-airspace-details (airspace-ref uint))
  (map-get? airspace-registry airspace-ref)
)

(define-read-only (get-expedition-record (expedition-id uint))
  (map-get? expedition-ledger expedition-id)
)

(define-read-only (get-airspace-feedback (airspace-ref uint) (evaluator principal))
  (map-get? airspace-feedback {airspace-ref: airspace-ref, evaluator: evaluator})
)

(define-read-only (get-achievement-status (aviator principal) (achievement-key (string-ascii 12)))
  (map-get? aviator-achievements {aviator: aviator, achievement-key: achievement-key})
)
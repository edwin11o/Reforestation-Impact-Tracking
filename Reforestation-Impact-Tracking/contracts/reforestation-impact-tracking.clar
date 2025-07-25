;; Reforestation Impact Tracking Smart Contract
;; Monitor and reward tree planting with verifiable satellite data

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-data (err u103))
(define-constant err-already-exists (err u104))
(define-constant err-insufficient-balance (err u105))

;; Data Variables
(define-data-var next-project-id uint u1)
(define-data-var total-trees-planted uint u0)
(define-data-var reward-per-tree uint u1000000) ;; 1 STX per tree in microSTX
(define-data-var verification-threshold uint u3) ;; Number of verifications needed

;; Data Maps
(define-map projects 
  { project-id: uint }
  {
    owner: principal,
    location: (string-ascii 100),
    target-trees: uint,
    planted-trees: uint,
    verified-trees: uint,
    status: (string-ascii 20),
    created-at: uint,
    total-rewards: uint
  }
)

(define-map satellite-verifications
  { project-id: uint, verifier: principal }
  {
    trees-count: uint,
    verification-date: uint,
    coordinates: (string-ascii 50),
    confidence-score: uint
  }
)

(define-map verifiers
  { verifier: principal }
  {
    is-authorized: bool,
    total-verifications: uint,
    reputation-score: uint
  }
)

(define-map user-rewards
  { user: principal }
  {
    total-earned: uint,
    projects-completed: uint,
    trees-planted: uint
  }
)

(define-map project-verifications
  { project-id: uint }
  {
    verification-count: uint,
    verified-by: (list 10 principal)
  }
)

;; Read-only functions
(define-read-only (get-project (project-id uint))
  (map-get? projects { project-id: project-id })
)

(define-read-only (get-user-rewards (user principal))
  (default-to 
    { total-earned: u0, projects-completed: u0, trees-planted: u0 }
    (map-get? user-rewards { user: user })
  )
)

(define-read-only (get-verifier-info (verifier principal))
  (map-get? verifiers { verifier: verifier })
)

(define-read-only (get-satellite-verification (project-id uint) (verifier principal))
  (map-get? satellite-verifications { project-id: project-id, verifier: verifier })
)

(define-read-only (get-project-verification-status (project-id uint))
  (map-get? project-verifications { project-id: project-id })
)

(define-read-only (get-total-trees-planted)
  (var-get total-trees-planted)
)

(define-read-only (get-reward-per-tree)
  (var-get reward-per-tree)
)

(define-read-only (get-next-project-id)
  (var-get next-project-id)
)

;; Public functions

;; Create a new reforestation project
(define-public (create-project (location (string-ascii 100)) (target-trees uint))
  (let
    (
      (project-id (var-get next-project-id))
      (current-time (unwrap-panic (get-stx-block-info? time (- stacks-block-height u1))))
    )
    (asserts! (> target-trees u0) err-invalid-data)
    (asserts! (> (len location) u0) err-invalid-data)
    
    (map-set projects
      { project-id: project-id }
      {
        owner: tx-sender,
        location: location,
        target-trees: target-trees,
        planted-trees: u0,
        verified-trees: u0,
        status: "active",
        created-at: current-time,
        total-rewards: u0
      }
    )
    
    (map-set project-verifications
      { project-id: project-id }
      {
        verification-count: u0,
        verified-by: (list)
      }
    )
    
    (var-set next-project-id (+ project-id u1))
    (ok project-id)
  )
)

;; Add verifier (only contract owner)
(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set verifiers
      { verifier: verifier }
      {
        is-authorized: true,
        total-verifications: u0,
        reputation-score: u100
      }
    )
    (ok true)
  )
)

;; Submit satellite verification
(define-public (submit-satellite-verification 
  (project-id uint) 
  (trees-count uint) 
  (coordinates (string-ascii 50))
  (confidence-score uint))
  (let
    (
      (project (unwrap! (get-project project-id) err-not-found))
      (verifier-info (unwrap! (get-verifier-info tx-sender) err-unauthorized))
      (current-time (unwrap-panic (get-stx-block-info? time (- stacks-block-height u1))))
      (existing-verification (get-satellite-verification project-id tx-sender))
    )
    (asserts! (get is-authorized verifier-info) err-unauthorized)
    (asserts! (is-none existing-verification) err-already-exists)
    (asserts! (and (>= confidence-score u70) (<= confidence-score u100)) err-invalid-data)
    (asserts! (> trees-count u0) err-invalid-data)
    
    (map-set satellite-verifications
      { project-id: project-id, verifier: tx-sender }
      {
        trees-count: trees-count,
        verification-date: current-time,
        coordinates: coordinates,
        confidence-score: confidence-score
      }
    )
    
    ;; Update verifier stats
    (map-set verifiers
      { verifier: tx-sender }
      (merge verifier-info { total-verifications: (+ (get total-verifications verifier-info) u1) })
    )
    
    (ok true)
  )
)

;; Process verification and update project
(define-public (process-verification (project-id uint))
  (let
    (
      (project (unwrap! (get-project project-id) err-not-found))
      (verification-status (default-to 
        { verification-count: u0, verified-by: (list) }
        (get-project-verification-status project-id)))
    )
    (asserts! (is-eq tx-sender (get owner project)) err-unauthorized)
    
    ;; This is a simplified version - in production, you'd aggregate multiple verifications
    (let
      ((verification-count (+ (get verification-count verification-status) u1)))
      
      (if (>= verification-count (var-get verification-threshold))
        (begin
          (map-set projects
            { project-id: project-id }
            (merge project { 
              status: "verified",
              verified-trees: (get target-trees project)
            })
          )
          (try! (distribute-rewards project-id))
          (ok true)
        )
        (begin
          (map-set project-verifications
            { project-id: project-id }
            (merge verification-status { verification-count: verification-count })
          )
          (ok false)
        )
      )
    )
  )
)

;; Distribute rewards for verified trees
(define-public (distribute-rewards (project-id uint))
  (let
    (
      (project (unwrap! (get-project project-id) err-not-found))
      (reward-amount (* (get verified-trees project) (var-get reward-per-tree)))
      (project-owner (get owner project))
      (current-rewards (get-user-rewards project-owner))
    )
    (asserts! (is-eq (get status project) "verified") err-invalid-data)
    (asserts! (> (get verified-trees project) u0) err-invalid-data)
    
    ;; Transfer STX rewards (simplified - assumes contract has STX balance)
    (try! (stx-transfer? reward-amount (as-contract tx-sender) project-owner))
    
    ;; Update project rewards
    (map-set projects
      { project-id: project-id }
      (merge project { total-rewards: reward-amount })
    )
    
    ;; Update user rewards
    (map-set user-rewards
      { user: project-owner }
      {
        total-earned: (+ (get total-earned current-rewards) reward-amount),
        projects-completed: (+ (get projects-completed current-rewards) u1),
        trees-planted: (+ (get trees-planted current-rewards) (get verified-trees project))
      }
    )
    
    ;; Update global stats
    (var-set total-trees-planted (+ (var-get total-trees-planted) (get verified-trees project)))
    
    (ok reward-amount)
  )
)

;; Update project status
(define-public (update-project-status (project-id uint) (new-status (string-ascii 20)))
  (let
    ((project (unwrap! (get-project project-id) err-not-found)))
    (asserts! (is-eq tx-sender (get owner project)) err-unauthorized)
    
    (map-set projects
      { project-id: project-id }
      (merge project { status: new-status })
    )
    (ok true)
  )
)

;; Admin function to set reward per tree
(define-public (set-reward-per-tree (new-reward uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set reward-per-tree new-reward)
    (ok true)
  )
)

;; Admin function to set verification threshold
(define-public (set-verification-threshold (new-threshold uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (and (>= new-threshold u1) (<= new-threshold u10)) err-invalid-data)
    (var-set verification-threshold new-threshold)
    (ok true)
  )
)

;; Function to fund the contract with STX for rewards
(define-public (fund-contract (amount uint))
  (begin
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (ok true)
  )
)
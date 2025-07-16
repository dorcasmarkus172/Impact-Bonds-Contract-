(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_BOND_NOT_FOUND (err u2))
(define-constant ERR_INVALID_AMOUNT (err u3))
(define-constant ERR_BOND_CLOSED (err u4))
(define-constant ERR_INSUFFICIENT_FUNDS (err u5))
(define-constant ERR_ALREADY_INVESTED (err u6))
(define-constant ERR_NOT_INVESTOR (err u7))
(define-constant ERR_OUTCOME_ALREADY_REPORTED (err u8))
(define-constant ERR_BOND_NOT_MATURE (err u9))
(define-constant ERR_INVALID_OUTCOME (err u10))

(define-data-var next-bond-id uint u1)
(define-data-var contract-treasury uint u0)

(define-map bonds uint {
  issuer: principal,
  target-amount: uint,
  raised-amount: uint,
  target-outcome: uint,
  actual-outcome: uint,
  outcome-reported: bool,
  maturity-block: uint,
  success-rate: uint,
  payout-rate: uint,
  is-active: bool,
  created-at: uint
})

(define-map investments { bond-id: uint, investor: principal } {
  amount: uint,
  claimed: bool
})

(define-map bond-investors uint (list 200 principal))

(define-read-only (get-bond (bond-id uint))
  (map-get? bonds bond-id)
)

(define-read-only (get-investment (bond-id uint) (investor principal))
  (map-get? investments { bond-id: bond-id, investor: investor })
)

(define-read-only (get-bond-investors (bond-id uint))
  (default-to (list) (map-get? bond-investors bond-id))
)

(define-read-only (get-contract-treasury)
  (var-get contract-treasury)
)

(define-read-only (get-next-bond-id)
  (var-get next-bond-id)
)

(define-read-only (calculate-payout (bond-id uint) (investor principal))
  (let (
    (bond (unwrap! (get-bond bond-id) ERR_BOND_NOT_FOUND))
    (investment (unwrap! (get-investment bond-id investor) ERR_NOT_INVESTOR))
  )
    (if (get outcome-reported bond)
      (let (
        (success-percentage (if (> (get actual-outcome bond) u0)
          (/ (* (get actual-outcome bond) u100) (get target-outcome bond))
          u0))
        (base-payout (get amount investment))
        (bonus-multiplier (if (>= success-percentage u100)
          (get payout-rate bond)
          (/ (* success-percentage (get payout-rate bond)) u100)))
      )
        (ok (/ (* base-payout bonus-multiplier) u100))
      )
      (ok u0)
    )
  )
)

(define-public (create-bond 
  (target-amount uint) 
  (target-outcome uint) 
  (maturity-blocks uint) 
  (payout-rate uint))
  (let (
    (bond-id (var-get next-bond-id))
    (maturity-block (+ stacks-block-height maturity-blocks))
  )
    (asserts! (> target-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> target-outcome u0) ERR_INVALID_OUTCOME)
    (asserts! (and (>= payout-rate u100) (<= payout-rate u200)) ERR_INVALID_OUTCOME)
    
    (map-set bonds bond-id {
      issuer: tx-sender,
      target-amount: target-amount,
      raised-amount: u0,
      target-outcome: target-outcome,
      actual-outcome: u0,
      outcome-reported: false,
      maturity-block: maturity-block,
      success-rate: u0,
      payout-rate: payout-rate,
      is-active: true,
      created-at: stacks-block-height
    })
    
    (map-set bond-investors bond-id (list))
    (var-set next-bond-id (+ bond-id u1))
    (ok bond-id)
  )
)

(define-public (invest (bond-id uint) (amount uint))
  (let (
    (bond (unwrap! (get-bond bond-id) ERR_BOND_NOT_FOUND))
    (existing-investment (get-investment bond-id tx-sender))
    (current-investors (get-bond-investors bond-id))
  )
    (asserts! (get is-active bond) ERR_BOND_CLOSED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (is-none existing-investment) ERR_ALREADY_INVESTED)
    (asserts! (<= (+ (get raised-amount bond) amount) (get target-amount bond)) ERR_INVALID_AMOUNT)
    
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (map-set investments 
      { bond-id: bond-id, investor: tx-sender }
      { amount: amount, claimed: false }
    )
    
    (map-set bonds bond-id
      (merge bond { raised-amount: (+ (get raised-amount bond) amount) })
    )
    
    (map-set bond-investors bond-id 
      (unwrap! (as-max-len? (append current-investors tx-sender) u200) ERR_INVALID_AMOUNT)
    )
    
    (var-set contract-treasury (+ (var-get contract-treasury) amount))
    (ok true)
  )
)

(define-public (report-outcome (bond-id uint) (actual-outcome uint))
  (let (
    (bond (unwrap! (get-bond bond-id) ERR_BOND_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get issuer bond)) ERR_UNAUTHORIZED)
    (asserts! (>= stacks-block-height (get maturity-block bond)) ERR_BOND_NOT_MATURE)
    (asserts! (not (get outcome-reported bond)) ERR_OUTCOME_ALREADY_REPORTED)
    
    (let (
      (success-rate (if (> (get target-outcome bond) u0)
        (/ (* actual-outcome u100) (get target-outcome bond))
        u0))
    )
      (map-set bonds bond-id
        (merge bond {
          actual-outcome: actual-outcome,
          outcome-reported: true,
          success-rate: success-rate
        })
      )
      (ok true)
    )
  )
)

(define-public (claim-payout (bond-id uint))
  (let (
    (bond (unwrap! (get-bond bond-id) ERR_BOND_NOT_FOUND))
    (investment (unwrap! (get-investment bond-id tx-sender) ERR_NOT_INVESTOR))
    (payout-amount (unwrap! (calculate-payout bond-id tx-sender) ERR_BOND_NOT_FOUND))
  )
    (asserts! (get outcome-reported bond) ERR_OUTCOME_ALREADY_REPORTED)
    (asserts! (not (get claimed investment)) ERR_ALREADY_INVESTED)
    (asserts! (>= (var-get contract-treasury) payout-amount) ERR_INSUFFICIENT_FUNDS)
    
    (map-set investments 
      { bond-id: bond-id, investor: tx-sender }
      (merge investment { claimed: true })
    )
    
    (var-set contract-treasury (- (var-get contract-treasury) payout-amount))
    (try! (as-contract (stx-transfer? payout-amount tx-sender tx-sender)))
    (ok payout-amount)
  )
)

(define-public (close-bond (bond-id uint))
  (let (
    (bond (unwrap! (get-bond bond-id) ERR_BOND_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get issuer bond)) ERR_UNAUTHORIZED)
    (asserts! (get is-active bond) ERR_BOND_CLOSED)
    
    (map-set bonds bond-id (merge bond { is-active: false }))
    (ok true)
  )
)

(define-public (withdraw-unused-funds (bond-id uint))
  (let (
    (bond (unwrap! (get-bond bond-id) ERR_BOND_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get issuer bond)) ERR_UNAUTHORIZED)
    (asserts! (get outcome-reported bond) ERR_OUTCOME_ALREADY_REPORTED)
    
    (let (
      (total-raised (get raised-amount bond))
      (investors (get-bond-investors bond-id))
      (total-payouts (fold calculate-total-payouts investors u0))
      (unused-funds (if (> total-raised total-payouts) (- total-raised total-payouts) u0))
    )
      (if (> unused-funds u0)
        (begin
          (var-set contract-treasury (- (var-get contract-treasury) unused-funds))
          (try! (as-contract (stx-transfer? unused-funds tx-sender tx-sender)))
          (ok unused-funds)
        )
        (ok u0)
      )
    )
  )
)

(define-private (calculate-total-payouts (investor principal) (acc uint))
  (let (
    (bond-id u1)
    (payout (unwrap-panic (calculate-payout bond-id investor)))
  )
    (+ acc payout)
  )
)

(define-read-only (get-bond-status (bond-id uint))
  (let (
    (bond (unwrap! (get-bond bond-id) ERR_BOND_NOT_FOUND))
  )
    (ok {
      is-active: (get is-active bond),
      is-mature: (>= stacks-block-height (get maturity-block bond)),
      outcome-reported: (get outcome-reported bond),
      funding-complete: (>= (get raised-amount bond) (get target-amount bond)),
      success-rate: (get success-rate bond)
    })
  )
)

(define-read-only (get-investor-summary (investor principal) (bond-id uint))
  (let (
    (investment (get-investment bond-id investor))
    (payout (calculate-payout bond-id investor))
  )
    (if (is-some investment)
      (ok {
        invested: (get amount (unwrap-panic investment)),
        claimed: (get claimed (unwrap-panic investment)),
        potential-payout: (unwrap! payout ERR_BOND_NOT_FOUND)
      })
      (ok { invested: u0, claimed: false, potential-payout: u0 })
    )
  )
)

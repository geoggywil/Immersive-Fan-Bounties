(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-INVALID-AMOUNT (err u400))
(define-constant ERR-BOUNTY-EXPIRED (err u403))
(define-constant ERR-BOUNTY-NOT-EXPIRED (err u402))
(define-constant ERR-ALREADY-SUBMITTED (err u409))
(define-constant ERR-NO-SUBMISSIONS (err u405))
(define-constant ERR-ALREADY-REWARDED (err u410))

(define-data-var bounty-counter uint u0)
(define-data-var submission-counter uint u0)

(define-map bounties
    { bounty-id: uint }
    {
        creator: principal,
        title: (string-ascii 100),
        description: (string-ascii 500),
        reward-amount: uint,
        deadline: uint,
        winner: (optional principal),
        is-active: bool,
        created-at: uint
    }
)

(define-map submissions
    { submission-id: uint }
    {
        bounty-id: uint,
        submitter: principal,
        content-hash: (string-ascii 64),
        description: (string-ascii 300),
        submitted-at: uint
    }
)

(define-map bounty-submissions
    { bounty-id: uint, submitter: principal }
    { submission-id: uint }
)

(define-map user-bounties
    { user: principal }
    { bounty-ids: (list 100 uint) }
)

(define-map user-submissions
    { user: principal }
    { submission-ids: (list 100 uint) }
)

(define-private (is-bounty-creator (bounty-id uint) (user principal))
    (match (map-get? bounties { bounty-id: bounty-id })
        bounty-info (is-eq (get creator bounty-info) user)
        false
    )
)

(define-private (is-bounty-expired (bounty-id uint))
    (match (map-get? bounties { bounty-id: bounty-id })
        bounty-info (>= stacks-block-height (get deadline bounty-info))
        true
    )
)

(define-private (add-to-user-bounties (user principal) (bounty-id uint))
    (let ((current-bounties (default-to (list) (get bounty-ids (map-get? user-bounties { user: user })))))
        (begin
            (map-set user-bounties
                { user: user }
                { bounty-ids: (unwrap! (as-max-len? (append current-bounties bounty-id) u100) (err u500)) }
            )
            (ok true)
        )
    )
)

(define-private (add-to-user-submissions (user principal) (submission-id uint))
    (let ((current-submissions (default-to (list) (get submission-ids (map-get? user-submissions { user: user })))))
        (begin
            (map-set user-submissions
                { user: user }
                { submission-ids: (unwrap! (as-max-len? (append current-submissions submission-id) u100) (err u500)) }
            )
            (ok true)
        )
    )
)

(define-public (create-bounty (title (string-ascii 100)) (description (string-ascii 500)) (reward-amount uint) (duration uint))
    (let ((bounty-id (+ (var-get bounty-counter) u1))
          (deadline (+ stacks-block-height duration)))
        (asserts! (> reward-amount u0) ERR-INVALID-AMOUNT)
        (asserts! (> duration u0) ERR-INVALID-AMOUNT)
        (try! (stx-transfer? reward-amount tx-sender (as-contract tx-sender)))
        (map-set bounties
            { bounty-id: bounty-id }
            {
                creator: tx-sender,
                title: title,
                description: description,
                reward-amount: reward-amount,
                deadline: deadline,
                winner: none,
                is-active: true,
                created-at: stacks-block-height
            }
        )
        (var-set bounty-counter bounty-id)
        (try! (add-to-user-bounties tx-sender bounty-id))
        (ok bounty-id)
    )
)

(define-public (submit-to-bounty (bounty-id uint) (content-hash (string-ascii 64)) (description (string-ascii 300)))
    (let ((bounty-info (unwrap! (map-get? bounties { bounty-id: bounty-id }) ERR-NOT-FOUND))
          (submission-id (+ (var-get submission-counter) u1)))
        (asserts! (get is-active bounty-info) ERR-BOUNTY-EXPIRED)
        (asserts! (< stacks-block-height (get deadline bounty-info)) ERR-BOUNTY-EXPIRED)
        (asserts! (is-none (map-get? bounty-submissions { bounty-id: bounty-id, submitter: tx-sender })) ERR-ALREADY-SUBMITTED)
        (map-set submissions
            { submission-id: submission-id }
            {
                bounty-id: bounty-id,
                submitter: tx-sender,
                content-hash: content-hash,
                description: description,
                submitted-at: stacks-block-height
            }
        )
        (map-set bounty-submissions
            { bounty-id: bounty-id, submitter: tx-sender }
            { submission-id: submission-id }
        )
        (var-set submission-counter submission-id)
        (try! (add-to-user-submissions tx-sender submission-id))
        (ok submission-id)
    )
)

(define-public (select-winner (bounty-id uint) (winner principal))
    (let ((bounty-info (unwrap! (map-get? bounties { bounty-id: bounty-id }) ERR-NOT-FOUND)))
        (asserts! (is-bounty-creator bounty-id tx-sender) ERR-NOT-AUTHORIZED)
        (asserts! (is-bounty-expired bounty-id) ERR-BOUNTY-NOT-EXPIRED)
        (asserts! (is-none (get winner bounty-info)) ERR-ALREADY-REWARDED)
        (asserts! (is-some (map-get? bounty-submissions { bounty-id: bounty-id, submitter: winner })) ERR-NOT-FOUND)
        (try! (as-contract (stx-transfer? (get reward-amount bounty-info) tx-sender winner)))
        (map-set bounties
            { bounty-id: bounty-id }
            (merge bounty-info { winner: (some winner), is-active: false })
        )
        (ok true)
    )
)

(define-public (cancel-bounty (bounty-id uint))
    (let ((bounty-info (unwrap! (map-get? bounties { bounty-id: bounty-id }) ERR-NOT-FOUND)))
        (asserts! (is-bounty-creator bounty-id tx-sender) ERR-NOT-AUTHORIZED)
        (asserts! (is-bounty-expired bounty-id) ERR-BOUNTY-NOT-EXPIRED)
        (asserts! (is-none (get winner bounty-info)) ERR-ALREADY-REWARDED)
        (try! (as-contract (stx-transfer? (get reward-amount bounty-info) tx-sender (get creator bounty-info))))
        (map-set bounties
            { bounty-id: bounty-id }
            (merge bounty-info { is-active: false })
        )
        (ok true)
    )
)

(define-public (extend-deadline (bounty-id uint) (additional-blocks uint))
    (let ((bounty-info (unwrap! (map-get? bounties { bounty-id: bounty-id }) ERR-NOT-FOUND)))
        (asserts! (is-bounty-creator bounty-id tx-sender) ERR-NOT-AUTHORIZED)
        (asserts! (get is-active bounty-info) ERR-BOUNTY-EXPIRED)
        (asserts! (> additional-blocks u0) ERR-INVALID-AMOUNT)
        (map-set bounties
            { bounty-id: bounty-id }
            (merge bounty-info { deadline: (+ (get deadline bounty-info) additional-blocks) })
        )
        (ok true)
    )
)

(define-read-only (get-bounty (bounty-id uint))
    (map-get? bounties { bounty-id: bounty-id })
)

(define-read-only (get-submission (submission-id uint))
    (map-get? submissions { submission-id: submission-id })
)

(define-read-only (get-user-bounties (user principal))
    (map-get? user-bounties { user: user })
)

(define-read-only (get-user-submissions (user principal))
    (map-get? user-submissions { user: user })
)

(define-read-only (get-bounty-submission (bounty-id uint) (submitter principal))
    (map-get? bounty-submissions { bounty-id: bounty-id, submitter: submitter })
)

(define-read-only (get-total-bounties)
    (var-get bounty-counter)
)

(define-read-only (get-total-submissions)
    (var-get submission-counter)
)

(define-read-only (is-bounty-active (bounty-id uint))
    (match (map-get? bounties { bounty-id: bounty-id })
        bounty-info (and (get is-active bounty-info) (< stacks-block-height (get deadline bounty-info)))
        false
    )
)

(define-read-only (get-bounty-status (bounty-id uint))
    (match (map-get? bounties { bounty-id: bounty-id })
        bounty-info 
            (if (is-some (get winner bounty-info))
                "completed"
                (if (>= stacks-block-height (get deadline bounty-info))
                    "expired"
                    "active"
                )
            )
        "not-found"
    )
)

(define-read-only (get-contract-balance)
    (stx-get-balance (as-contract tx-sender))
)

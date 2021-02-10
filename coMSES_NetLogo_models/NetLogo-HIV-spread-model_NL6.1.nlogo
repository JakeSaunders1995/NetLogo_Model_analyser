
extensions [profiler ls nw csv]
directed-link-breed [dummylinks dummylink]
undirected-link-breed [main-links main-link]
undirected-link-breed [casual-links casual-link]
undirected-link-breed [onetime-links onetime-link]

breed [
  M0C0s M0C0
]
breed [
  M0C1s M0C1
]
breed [
  M0C2s M0C2
]
breed [
  M1C0s M1C0
]
breed [
  M1C1s M1C1
]
breed [
  M1C2s M1C2
]

globals [
  file-n                    ; this is for running behaviorspace experiments
  run-number                ; this is to make sure that files from the same run are given an identifier
  hiv-pos-count
  alist
]

turtles-own [
  onetime-quintile          ; an indicator specifying if the activity of one-time sex acts
  sexual-role               ; an indicator specifying if the sex-role during intercourse
  insertivity-preference    ; an indicator specifying if the preference for insertive sex, for those individuals that have a versatile sex role
  age-weeks                 ; an indicator specifying if the individual's age in weeks
  african-american?         ; an indicator specifying if the individual is of african-american decent
  circumcized?              ; an indicator specifying if the individual is circumsized
  CCR5-mutation             ; an indicator specifying the individual's CCR5 mutation

  hiv-tester?               ; an indicator specifying if the individual goes in for testing
  full-suppression?         ; an indicator specifying if the individual will achieve full suppression when retained in care
  prep-risk-reduction       ; an indicator specifying the individual's adherence to PrEP, which consequently determines the reduction in risk

  condom-always-pref        ; an indicator specifying if the individual always wants to use condoms
  always-condom-casual?     ; an indicator specifying if the individual always wants to use condoms in casual ties
  always-condom-onetime?    ; an indicator specifying if the individual always wants to use condoms in onetime ties

  hiv-positive?             ; an indicator specifying if the individual is HiV-positive
  viral-load                ; an indicator specifying the viral load levels of the individual
  infected-at-tick          ; an indicator specifying the time at which the individual was infected with HIV
  last-test-tick            ; an indicator specifying the last date at which the individual was tested
  diagnosed?                ; an indicator specifying if the HIV-positive status is known
  diagnosed-at-tick         ; an indicator specifying if the time at which the HIV-positive status become known
  last-treated              ; an indicator specifying when the individual was last treated
  time-on-ART               ; an indicator specifying the time the individual has spend on ART
  on-prep?                  ; an indicator specifying if the individual is currently on PrEP

  prep-1a                   ; an indicator specifying when the individual last qualified for prep prescription criteria 1a
  prep-1b                   ; an indicator specifying when the individual last qualified for prep prescription criteria 1b
  prep-2a                   ; an indicator specifying when the individual last qualified for prep prescription criteria 2a
  prep-2b                   ; an indicator specifying when the individual last qualified for prep prescription criteria 2b
  prep-3a                   ; an indicator specifying when the individual last qualified for prep prescription criteria 3a
  prep-3b                   ; an indicator specifying when the individual last qualified for prep prescription criteria 3b
  prep-4a                   ; an indicator specifying when the individual last qualified for prep prescription criteria 4a
  prep-4b                   ; an indicator specifying when the individual last qualified for prep prescription criteria 4b
  last-prep-check           ; an indicator specifying when the individual last checked it's PrEP qualifications

  changed-relationship-status?  ; an indicator specifying if the individual has changed their relationship profile in the current tick

;; non-functional attributes on used for porting the EpiModel data into this model
  traj
  r-stageuse
  stage-time
  in-treat?
  hiv-on-import?
  name
  stage
]

links-own [
  hiv-disclosed?            ; an indicator specifying if HIV-positive status is disclosed in the partnership
  duration                  ; an indicator specifying remaining duration of the partnership
  intercourses-this-week    ; a list specifying for each intercourse this week if a condom was used
  transmission-this-week    ; a list specifying for each intercourse this week if the event resulted in HIV spread
  e_type                    ; a supporting characteristic for porting data from EpiModel into this model
  disclosed                 ; a supporting characteristic for porting data from EpiModel into this model
  r-hiv-disclosed           ; a supporting characteristic for porting data from EpiModel into this model
  hiv-disclosed             ; a supporting characteristic for porting data from EpiModel into this model
]

to setup
  ;; create the required level-space models (if desired)
  ls:reset
  ca
  if hiv-transmission-network? [
    ls:create-models 1 "LevelSpace Analysis.nlogo"
  ]
  if sexual-activity-network? [
    ls:create-models 1 "AggregateNetwork.nlogo"
  ]
  if sexual-activity-network? or hiv-transmission-network? [
    ls:ask ls:models [setup]
  ]
  if sexual-activity-network? or hiv-transmission-network? [
    ls:ask ls:models [reset-ticks]
  ]

  reset-ticks
  set run-number random 100000000

  ;; create a set of individuals without ties
  create-M0C0s n-people [
    initialize-new-person
    set age-weeks (18 * 52) + random (52 * 22)
    if infect-on-setup?[
      ifelse age-shifted-prevalence? [
        if random-float 1 < risk-of-initial-infection (25.6 / 29)  and (ccr5-mutation != 2 or ccr5-mutation = 1 and random-float 1 < 30) [
          set hiv-positive? true
          set full-suppression?  random-float 1 < chance-to-be-fully-suppressed?
        ]
      ]
      [
        if random-float 1 < .256 [
          set hiv-positive? true
        ]
      ]
      if hiv-positive? [
        set infected-at-tick 0
        if diagnosed-on-setup? and hiv-tester? [
          if random-float 1 < .9 [
            set diagnosed? true
          ]
        ]
        if treatment-on-setup? and diagnosed? [
          if random-float 1 < .3 [
            set last-treated -1
          ]
        ]
        if distributed-infection? [
          set infected-at-tick random max (list (-1 * (age-weeks - (18 * 52))) -520)
          let weeks -1 * infected-at-tick
          let tested? false
          while [weeks > 0 and not tested?]
          [
            set tested? getting-tested-this-week?
            set weeks weeks - 1
          ]
          let ever-in-treatment? false
          while [weeks > 0 and not ever-in-treatment?][
            set ever-in-treatment? random-float 1 < 0.1095
            set weeks weeks - 1
          ]
          let currently-in-treatment? true
          while [weeks > 0] [
            set time-on-art time-on-art + 1
            set weeks weeks - 1
            set viral-load calculate-viral-load
            ifelse currently-in-treatment? [
              if random-float 1 < risk-of-falling-out [
                set currently-in-treatment? false
              ]
            ]
            [
              if random-float 1 <  chance-of-re-achieving-suppression [
                set currently-in-treatment? true
              ]
            ]
          ]
        ]
      ]
    ]
  ]
  if hiv-transmission-network? [
    ask turtles with [hiv-positive?][
      add-initial-hiv+
    ]
  ]
  reset-ticks
end

to add-initial-hiv+
  ls:let the-who who
  ls:let vars vars-to-list [
    "onetime-quintile"
    "sexual-role"
    "age-weeks"
    "circumcized?"
    "CCR5-mutation"
    "hiv-tester?"
    "insertivity-preference"
    "condom-always-pref"
    "always-condom-casual?"
    "always-condom-onetime?"
  ]
  ls:ask 0 [seed-me the-who vars ]
end

to add-hiv+ [my-partner]
  if my-partner = self [show self stop]
  ls:let the-who who
  ls:let partner-who [who] of my-partner
  ls:let vars vars-to-list [
    "onetime-quintile"
    "sexual-role"
    "age-weeks"
    "circumcized?"
    "CCR5-mutation"
    "hiv-tester?"
    "insertivity-preference"
    "condom-always-pref"
    "always-condom-casual?"
    "always-condom-onetime?"
  ]
  ls:ask 0 [add-me the-who vars partner-who]
end

;; reporter to support the transition of agent attributes to other levelspace models
to-report vars-to-list [list-of-varnames]
  report map [ var-name -> (list var-name run-result var-name)] list-of-varnames
end

;; reporter to determine the infection probability at initiation conditional upon age
to-report risk-of-initial-infection [scale]
 let age age-years
 (ifelse
    age = 18 [report 0.005964215 * scale]
    age = 19 [report 0.032818533 * scale]
    age = 20 [report 0.046966732 * scale]
    age = 21 [report 0.1	* scale]
    age = 22 [report 0.104208417 * scale]
    age = 23 [report 0.160583942 * scale]
    age = 24 [report 0.207089552 * scale]
    age = 25 [report 0.235294118 * scale]
    age = 26 [report 0.263366337 * scale]
    age = 27 [report 0.265873016 * scale]
    age = 28 [report 0.329268293 * scale]
    age = 29 [report 0.366666667 * scale]
    age = 30 [report 0.348336595 * scale]
    age = 31 [report 0.39453125 * scale]
    age = 32 [report 0.432432432 * scale]
    age = 33 [report 0.415966387 * scale]
    age = 34 [report 0.4 * scale]
    age = 35 [report 0.48173516 * scale]
    age = 36 [report 0.474157303 * scale]
    age = 37 [report 0.449771689 * scale]
    age = 38 [report 0.43559719 * scale]
    age = 39 [report 0.474056604 * scale]
    [report 0]
  )
end

;; procedure to create a new individual after the intial setup
to initialize-new-person
  set hiv-positive? false
  set diagnosed? false
  set onetime-quintile who mod 5
  set sexual-role sex-role-setup
  set CCR5-mutation CCR5-setup
  set african-american? one-of [true false]
  set circumcized? ifelse-value (random 1000 < 896) [true] [false]
  set age-weeks 18 * 52
  set hiv-tester? random 1000 > 65
  set last-test-tick 0
  set last-treated -10000
  set time-on-ART 0
  set insertivity-preference random-float 1
  set condom-always-pref cond-pref-setup
  if condom-always-pref = 0 [
    set always-condom-casual? FALSE
    set always-condom-onetime? FALSE]
  if condom-always-pref = 1 [
    set always-condom-casual? TRUE
    set always-condom-onetime? FALSE]
  if condom-always-pref = 2 [
    set always-condom-casual? FALSE
    set always-condom-onetime? TRUE]
  if condom-always-pref = 3 [
    set always-condom-casual? TRUE
    set always-condom-onetime? TRUE]
  set prep-1a -10000
  set prep-1b -10000
  set prep-2a -10000
  set prep-2b -10000
  set prep-3a -10000
  set prep-3b -10000
  set on-prep? false
  set last-prep-check -10000
  set prep-risk-reduction prep-risk-setup
  set changed-relationship-status? false
  set full-suppression?  random-float 1 < chance-to-be-fully-suppressed?
  if sexual-activity-network? [
    ls:let vars vars-to-list [
      "onetime-quintile"
      "sexual-role"
      "age-weeks"
      "circumcized?"
      "CCR5-mutation"
      "hiv-tester?"
      "insertivity-preference"
      "condom-always-pref"
      "always-condom-casual?"
      "always-condom-onetime?"
    ]
    ls:ask 1 [
      add-me vars
    ]
  ]
end

;; reporter to pick the sexrole at setup
to-report sex-role-setup
  let n random 1000
    (ifelse
    n < 236 [report "insertive"]
    n < 511 [report "receptive"]
    [report "versatile"]
  )
end

;; reporter to pick the CCR5 mutation at setup
to-report CCR5-setup
  let n random 1000
  (ifelse
    n < 17  [report 2 ]
    n < 116 [report 1]
    [report 0]
  )
end

;; reporter to pick the condom use preference at setup
to-report cond-pref-setup
  let n random 10000
  (ifelse
    n < 6185 [report 0]
    n < 7807 [report 1]
    n < 9497 [report 2]
    [report 3]
  )
end

;; reporter to pick the PrEP risk reduction at setup
to-report prep-risk-setup
  let n random 1000
  (ifelse
    n < 221 [report 0 ]
    n < 281 [report .31]
    n < 381 [report .81]
    [report 0.95]
  )
end

to go
;; add an ending condition to the model run
  if ticks > 30000 [stop]

;; update the data describing the weekly behaviors for both links and agents
  ask links [
    set intercourses-this-week (list)
    set duration duration - 1
    set transmission-this-week false
  ]
  ask turtles [
    set changed-relationship-status? false
  ]
  ask links with [duration <= 0] [
    ask both-ends [set changed-relationship-status? true]
    die
  ]
  ask turtles [
    set breed appropriate-breed
  ]

;; add a given number of new individuals to the model (to keep population numbers relatively stable)
  create-m0c0s random-poisson (0.001 * n-people) [
      initialize-new-person
    ]

  ;; update the network of structure of sexual ties
  update-constrained-network

  ask links [
    set intercourses-this-week map [ [ ] -> using-condom?] range calculate-intercourses-this-week
;; consider if PrEP criteria 1a/1b and 3a/3b apply
    if [diagnosed?] of both-ends = [false false] and [count my-links] of both-ends = [1 1] and length UAIs-this-week > 0 [
      if [ticks - last-test-tick < partner-testing-window-ind1] of end1 [
        ask end2 [set prep-1a ticks]
      ]
      if [ticks - last-test-tick < partner-testing-window-ind1] of end2 [
        ask end1 [set prep-1a ticks]
      ]
    ]
    if [diagnosed?] of both-ends = [false false]  and length UAIs-this-week > 0  [
      if [ticks - last-test-tick < partner-testing-window-ind1] of end1 and [count my-links = 1] of end2 [
        ask end2 [set prep-1b ticks]
      ]
      if [ticks - last-test-tick < partner-testing-window-ind1] of end2 and [count my-links = 1] of end1 [
        ask end1 [set prep-1b ticks]
      ]
    ]
    if (is-main-link? self or is-casual-link? self) and hiv-disclosed? and count both-ends with [diagnosed?] = 1 and length intercourses-this-week > 0 [
      ask both-ends with [not diagnosed?] [set prep-3a ticks]
    ]
    if (is-main-link? self or is-casual-link? self) and hiv-disclosed? and count both-ends with [diagnosed?] = 1 and length UAIs-this-week > 0 [
      ask both-ends with [not diagnosed?] [set prep-3b ticks]
    ]
;; specify the transmission of HIV for serodiscordant couples
    if count both-ends with [hiv-positive?] = 1  [
      let infection-bool-list map [ [ condom? ] -> random-float 1 < risk-of-transmission-factors condom?] intercourses-this-week
      if length filter [[infected?] -> infected?] infection-bool-list > 0 [
        set transmission-this-week true
        ask hiv- [
          set hiv-pos-count hiv-pos-count + 1
          if hiv-transmission-network? [
            add-hiv+ [hiv+] of myself
          ]
          set hiv-positive? true set infected-at-tick ticks]
      ]
    ]
  ]
;; consider if PrEP criteria 2a/2b apply
  ask turtles with [count my-links > 0 and not hiv-positive?] [
    let my-intercourses-this-week [intercourses-this-week] of my-links
    if length filter [[intercourses] -> member? false intercourses] my-intercourses-this-week > 1 [set prep-2a ticks]
    set my-intercourses-this-week [intercourses-this-week] of my-links with [is-casual-link? self or is-onetime-link? self]
    if length filter [[intercourses] -> member? false intercourses] my-intercourses-this-week > 0 [set prep-2b ticks]
  ]


;; individuals are retained in PrEP care
  ask turtles with [on-prep? and (ticks - last-prep-check) >= 52] [
    set on-prep? false
    if indicate-1a and ticks - prep-1a < indication-window [ set on-prep? true set last-prep-check ticks ]
    if indicate-1b and ticks - prep-1b < indication-window [ set on-prep? true set last-prep-check ticks ]
    if indicate-2a and ticks - prep-2a < indication-window [ set on-prep? true set last-prep-check ticks ]
    if indicate-2b and ticks - prep-2b < indication-window [ set on-prep? true set last-prep-check ticks ]
    if indicate-3a and ticks - prep-3a < indication-window [ set on-prep? true set last-prep-check ticks ]
    if indicate-3b and ticks - prep-3b < indication-window [ set on-prep? true set last-prep-check ticks ]
  ]

;; Individuals go in for HIV testing.
  let this-weeks-hiv-testers turtles with  [hiv-tester? and not diagnosed? and getting-tested-this-week?]
  ask this-weeks-hiv-testers [
    set diagnosed? test-results-positive?
    set last-test-tick ticks
    if diagnosed? [
      set diagnosed-at-tick ticks
      ask (link-set my-main-links my-casual-links) [set hiv-disclosed? true]
    ]
    if prep? [
      if not diagnosed? and not on-prep? [
        if count turtles with [on-prep?] < prep-coverage-fraction * count turtles [
          if indicate-1a and ticks - prep-1a < indication-window [ set on-prep? true  set last-prep-check ticks ]
          if indicate-1b and ticks - prep-1b < indication-window [ set on-prep? true set last-prep-check ticks  ]
          if indicate-2a and ticks - prep-2a < indication-window [ set on-prep? true set last-prep-check ticks  ]
          if indicate-2b and ticks - prep-2b < indication-window [ set on-prep? true  set last-prep-check ticks ]
          if indicate-3a and ticks - prep-3a < indication-window [ set on-prep? true  set last-prep-check ticks ]
          if indicate-3b and ticks - prep-3b < indication-window [ set on-prep? true  set last-prep-check ticks  ]
          if indicate-4a and sexual-role = "versatile" [set on-prep? true set last-prep-check ticks]
        ]
      ]
    ]
  ]

;; update individual's treatment information
  let turtles-in-treatment-last-week turtles with [last-treated = ticks - 1]
  let fallen-out-turtles turtles with [diagnosed? and ever-treated? and not in-treatment?]
  let untreated-but-diagnosed-turtles turtles with [diagnosed? and not ever-treated?]

;; individuals can drop out of care
  ask turtles-in-treatment-last-week [
    if random-float 1 > risk-of-falling-out [
      set last-treated ticks
    ]
  ]
;; individuals can come back into care
  ask fallen-out-turtles [
    if random-float 1 < chance-of-re-achieving-suppression [
      set last-treated ticks
    ]
  ]
;; or individuals can initate care (for the first time)
  ask untreated-but-diagnosed-turtles  [
    if random-float 1 < 0.1095 [
      set last-treated ticks
    ]
  ]

;; Individuals might age and die
  ask turtles [
    set age-weeks age-weeks + 1
    if in-treatment? [set time-on-ART time-on-ART + 1]
    if hiv-positive?[
      set viral-load calculate-viral-load
    ]
  ]
  let naturally-dying-turtles turtles with [random-float 1 < natural-mortality-rate]
  let aids-dying-turtles turtles with [viral-load >= 7]
  let deaths-this-week count (turtle-set  naturally-dying-turtles  aids-dying-turtles)
  ask naturally-dying-turtles [die]
  ask aids-dying-turtles [die]

;; update the aggregate network structure
  if sexual-activity-network? [
    ask onetime-links  [
      ls:let end-1 [who] of end1
      ls:let end-2 [who] of end2
      ls:let count-this-weeks-intercourses length intercourses-this-week
      ls:ask 1 [
        ask turtle end-1 [create-link-with turtle end-2]
        ask link end-1 end-2 [
          if ticks-in-relationship  = 0 [set ticks-in-relationship  (list)]
          if intercourses-at-tick  = 0 [set intercourses-at-tick  (list)]
        set ticks-in-relationship lput ticks ticks-in-relationship
        set intercourses-at-tick lput count-this-weeks-intercourses  intercourses-at-tick
        ]
      ]
    ]
  ]
;; end the timestep
  ls:ask ls:models [tick]
  tick
end

to update-constrained-network
  let potential-mains eligible-main-turtles
  let potential-casuals eligible-casual-turtles
  let done? false
  while [not done?] [
    if count potential-mains > 2 [
      ask one-of potential-mains [
        let my-potential-mains other potential-mains with [sexually-compatible? and not member? myself link-neighbors]
        let potential-partners age-appropriate-partners my-potential-mains 0.464
        let new-partner one-of potential-partners
        create-main-link-with new-partner [begin-relationship]
        ask new-partner [set breed appropriate-breed]
        set breed appropriate-breed
      ]
    ]
    if count potential-casuals > 2 [
      ask one-of potential-casuals [
        let my-potential-casuals other potential-casuals with [sexually-compatible? and not member? myself link-neighbors]
        let potential-partners age-appropriate-partners my-potential-casuals 0.586
        let new-partner one-of potential-partners
        create-casual-link-with new-partner [begin-relationship]
        ask new-partner [set breed appropriate-breed]
        set breed appropriate-breed
      ]
    ]

    set potential-mains eligible-main-turtles
    set potential-casuals eligible-casual-turtles
    if count potential-mains < 2 and count potential-casuals < 2 [
      set done? true
    ]
  ]
  let onetime-seekers turtles with [random-float 1 < probability-of-onetime-ai]
  while [count  onetime-seekers > 2] [
    ask one-of onetime-seekers [
      let my-potential-onetimes age-appropriate-partners (other onetime-seekers with [sexually-compatible? and not member? myself link-neighbors]) 0.544
      ifelse count my-potential-onetimes = 0 [
        set onetime-seekers other onetime-seekers
      ][
        create-onetime-link-with one-of my-potential-onetimes [begin-relationship]
        set onetime-seekers onetime-seekers with [not any? my-onetime-links]
      ]
    ]
  ]
end

to-report using-condom?
  report random-float 1 < probability-of-using-condom
end

to-report chance-to-be-fully-suppressed?
  report ifelse-value african-american? [0.614] [0.651]
end

to-report getting-tested-this-week?
  repeat 7 [
    if random 308 < 1 [
      report true
    ]
  ]
  report false
end

to-report days-between-testing
  ifelse african-american? [
    report 301
  ]
  [
    report 315
  ]
end

to-report test-results-positive?
  report weeks-since-infected > 3 and hiv-positive?
end

to-report calculate-intercourses-this-week
    if is-main-link? self [
    report random-poisson (1.54 * AI_scale)
  ]
  if is-casual-link? self [
    report random-poisson (0.96 * AI_scale)
  ]
  if is-onetime-link? self [
    report random-poisson (1 * AI_scale)
  ]
end

to begin-relationship
  set hiv-disclosed? false
  if count both-ends with [hiv-positive? and diagnosed?] > 0
  [
    set hiv-disclosed? disclose-or-not?
  ]
  set duration randomized-relationship-duration
  set transmission-this-week false
end

to-report is-serodiscordant?
  report count both-ends with [hiv-positive?] = 1
end

to-report probability-of-using-condom
  let log-odds relationship-condom-use-coefficient
  if breed = main-links [report log-odds-to-prob log-odds]
  if breed = casual-links [ifelse any? both-ends with [always-condom-casual?] [report 1][report log-odds-to-prob log-odds]]
  if breed = onetime-links [ifelse any? both-ends with [always-condom-onetime?] [report 1][report log-odds-to-prob log-odds]]
end

to-report relationship-condom-use-coefficient
  let Unprotected_AI 0
  if is-main-link? self [
    set Unprotected_AI 1 - 0.21 ]
  if is-casual-link? self [
    set Unprotected_AI 1 - 0.26 ]
  if is-onetime-link? self [
    set Unprotected_AI 1 - 0.27 ]
  let logodds_UAI ln (Unprotected_AI / (1 - Unprotected_AI ))
  if hiv-disclosed? [
    set logodds_UAI logodds_UAI - .850
  ]
  if any? both-ends with [diagnosed?] [
    set logodds_UAI logodds_UAI - .670
  ]
  let protected_AI logodds_UAI * -1
  report protected_AI
end

to-report condition-condom-use-coefficient
  if not any? both-ends with [diagnosed?] [report 0]
  if hiv-disclosed? [
    report 0.850
  ]
if any? both-ends with [diagnosed?] [ ;
    report 0.670
  ]
end

to-report eligible-main-turtles
  let eligible-turtles (turtle-set) ;; only ever ones that don't have one already
  ;; add each of the three if they are OK
  set eligible-turtles  ifelse-value (not enough-m1-c0s?) [(turtle-set eligible-turtles m0c0s )] [eligible-turtles]
  set eligible-turtles  ifelse-value (not enough-m1-c1s?) [(turtle-set eligible-turtles m0c1s )] [eligible-turtles]
  set eligible-turtles  ifelse-value (not enough-m1-c2s?) [(turtle-set eligible-turtles m0c2s )] [eligible-turtles]
  report eligible-turtles
end

to-report eligible-casual-turtles
  let eligible-turtles (turtle-set)
  set eligible-turtles ifelse-value (not enough-m0-c2s?) [(turtle-set eligible-turtles m0c1s )] [eligible-turtles]
  set eligible-turtles ifelse-value (not enough-m0-c1s?) [(turtle-set eligible-turtles m0c0s )] [eligible-turtles]
  set eligible-turtles ifelse-value (not enough-m1-c2s?) [(turtle-set eligible-turtles m1c1s )] [eligible-turtles]
  set eligible-turtles ifelse-value (not enough-m1-c1s?) [(turtle-set eligible-turtles m1c1s )] [eligible-turtles]
  report eligible-turtles
end

to-report target-size-m0-c0s
  report round count turtles * .471
end
to-report target-size-m0-c1s
  report round count turtles * 0.167
end
to-report target-size-m0-c2s
  report round count turtles * 0.074
end
to-report target-size-m1-c0s
  report round count turtles * 0.22
end
to-report target-size-m1-c1s
  report round count turtles * 0.047
end
to-report target-size-m1-c2s
  report round count turtles * 0.021
end
to-report enough-m0-c1s?
  report (count m0c1s >= target-size-m0-c1s)
end
to-report enough-m0-c2s?
  report (count m0c2s >= target-size-m0-c2s)
end
to-report enough-m1-c0s?
  report (count m1c0s >= target-size-m1-c0s)
end
to-report enough-m1-c1s?
  report (count m1c1s >= target-size-m1-c1s)
end
to-report enough-m1-c2s?
  report (count m1c2s >= target-size-m1-c2s)
end

to-report probability-of-onetime-ai
  let rate (onetime-ai-quintile-effect * onetime-ai-relationship-effect)
  report rate

end

to-report onetime-ai-quintile-effect
  let q onetime-quintile
  (ifelse
    q = 0 [report 0 / 0.0674]
    q = 1 [report 0.007 / 0.0674]
    q = 2 [report 0.038 / 0.0674]
    q = 3 [report 0.071 / 0.0674]
    q = 4 [report 0.221 / 0.0674]
    [report false]
  )
end

to-report onetime-ai-relationship-effect
  let rel (list count my-main-links count my-casual-links)
  (ifelse
    rel = [0 0] [report 0.065]
    rel = [0 1] [report 0.087]
    rel = [0 2] [report 0.086]
    rel = [1 0] [report 0.056]
    rel = [1 1] [report 0.055]
    rel = [1 2] [report 0.055]
    [report false]
  )
end

to-report randomized-relationship-duration
  if is-main-link? self [
    report random-exponential 58.1
  ]
  if is-casual-link? self [
    report random-exponential 23.71
  ]
  if is-onetime-link? self [
    report 1
  ]
end

to-report disclose-or-not?
  if is-main-link? self [
    report random 1000 < 787
  ]
  if is-casual-link? self [
    report random 1000 < 678
  ]
  if is-onetime-link? self [
    report random  1000 < 568
  ]
end

to-report age-appropriate-partners [potential-partners desired-age-score-mean]
  let desired-age-mix-score random-normal desired-age-score-mean .1
  let pot-partners potential-partners with-min [abs (turtle-age-mix-score myself - desired-age-mix-score)]
  report pot-partners
end

to-report age-mixing-score
  report abs (sqrt [age-years] of end1 - sqrt [age-years] of end2)
end

to-report turtle-age-mix-score [another-turtle]
  report abs (sqrt age-years - sqrt [age-years] of another-turtle)
end

to-report age-years
  report floor (age-weeks / 52)
end

to-report sexually-compatible?
  report sexual-role = "versatile" and [sexual-role] of myself = "versatile" or sexual-role != [sexual-role] of myself
end

to-report age-difference
  report abs ([age-years] of end1 - [age-years] of end2)
end

to-report natural-mortality-rate
  (ifelse
    not african-american?[
      (ifelse
        age-years <= 24 [report (1.00103 ^ (1 / 52)) - 1]
        age-years <= 34 [report (1.00133  ^ (1 / 52)) - 1]
        age-years <= 39 [report (1.00214 ^ (1 / 52)) - 1]
        [report 1]
      )
    ]
    [
      (ifelse
        age-years <= 24 [report (1.00159  ^ (1 / 52)) - 1]
        age-years <= 34 [report (1.00225 ^ (1 / 52)) - 1]
        age-years <= 39 [report (1.00348 ^ (1 / 52)) - 1]
        [report 1]
      )
  ])
end

to-report calculate-viral-load
  ifelse time-on-ART = 0 [
    report calculate-untreated-viral-load][
    ifelse weeks-since-infected < (52 * 10) [
      report calculate-treated-viral-load
    ][
      report calculate-aids-viral-load
    ]
  ]
end

to-report calculate-untreated-viral-load
  report untreated-viral-load
end

to-report calculate-treated-viral-load
  let stage1to3-endpoint 4.5
  ifelse in-treatment? [
    report max (list (viral-load - 0.25) minimum-viral-load) ]
  [
    report min (list (viral-load + 0.25) stage1to3-endpoint )
  ]
end

to-report calculate-aids-viral-load
  let vl-fatal 7
  let vl-setpoint 4.5
  let AIDS-durations 52 * 2
  let AIDS? in-AIDS-stage?
  let AIDS-increase (vl-fatal - vl-setpoint) / AIDS-durations
  ifelse AIDS? [
    report viral-load + AIDS-increase
  ][
    ifelse in-treatment? [
      report max (list (viral-load - 0.25) minimum-viral-load) ][
      report min (list (viral-load + 0.25) vl-setpoint)
    ]
  ]
end

to-report in-AIDS-stage?
  let time-off-ART weeks-since-infected - time-on-ART
  let in-AIDS-stage FALSE
  let max-time-on-ART 52 * 15
  let max-time-off-ART 52 * 10
  if last-treated < 0 and weeks-since-infected > 520 [ set in-AIDS-stage TRUE]
  ifelse full-suppression? [
    if time-on-ART >= max-time-on-ART [ set in-AIDS-stage TRUE ]
  ][
    if ((time-on-ART / max-time-on-ART) + (time-off-ART / max-time-off-ART)) > 1 [set in-AIDS-stage TRUE ]
  ]
  report in-AIDS-stage
end

to-report minimum-viral-load
  report ifelse-value full-suppression? [1.5] [3.5]
end

to-report untreated-viral-load
  let the-stage 0
  let stage1-duration 6
  let stage2-duration 6
  let stage3-duration ( 10 * 52 ) - stage1-duration - stage2-duration
  let stage4-duration 104
  let stage1-endpoint 6.886
  let stage2-endpoint 4.5
  let stage3-endpoint 4.5
  let stage4-endpoint 7
  let d1 stage1-endpoint / stage1-duration
  let d2 (stage2-endpoint - stage1-endpoint) / stage2-duration
  let d3 (stage3-endpoint - stage2-endpoint) / stage3-duration
  let d4 (stage4-endpoint - stage4-endpoint) / stage4-duration
  if weeks-since-infected <= stage1-duration [
    let weeks-into-current-stage weeks-since-infected
    report (weeks-into-current-stage * d1)
  ]
  if weeks-since-infected <= stage1-duration + stage2-duration [
    let weeks-into-current-stage weeks-since-infected - stage1-duration
    report stage1-endpoint + (d2 * weeks-into-current-stage)
  ]
  if weeks-since-infected <= (stage1-duration + stage2-duration + stage3-duration) [
    report stage3-endpoint
  ]
  if weeks-since-infected < (stage1-duration + stage2-duration + stage3-duration + stage4-duration) [
    let weeks-into-current-stage weeks-since-infected - (stage1-duration + stage2-duration + stage3-duration)
    report stage3-endpoint + (d4 * weeks-into-current-stage)
  ]
  if weeks-since-infected >=  (stage1-duration + stage2-duration + stage3-duration + stage4-duration)  [
    report 7
  ]
end

to-report in-treatment?
  report last-treated = ticks
end

to-report risk-of-falling-out
  report (.0071 + .0102) / 2
end
to-report chance-of-re-achieving-suppression ;; AH:
  report (.00291 + 0.00066) / 2

end

to-report ever-treated?
  report time-on-art > 0
end

to-report serodiscordant-couples
  report links with [count both-ends with [hiv-positive?] = 1]
end
to-report hiv-pos-couples
  report links with [count both-ends with [hiv-positive?] = 2]
end
to-report hiv-neg-couples
  report links with [count both-ends with [hiv-positive?] = 0]
end

to-report weeks-since-infected
  report ticks - infected-at-tick
end

to-report is-acute?
  report weeks-since-infected < 12 and weeks-since-infected > 0
end

to-report log-odds-to-prob [logodds]
  report 1 / ( 1 + exp (-1 * logodds))
end

to-report risk-selector [hiv-neg-ai-position]
  let p hiv-neg-ai-position
(ifelse
    p = "receptive" [report 0.008938]
    p = "insertive" [report 0.003379]
    [report (1.008938 * 1.003379) - 1] ;; this is IEV
  )
end

to test-untreated-viral-load [some-ticks]
  ca
  reset-ticks
  crt 1 [set hiv-positive? true set last-treated -1000]
  repeat some-ticks [
    tick
    ask turtles [
    set viral-load calculate-viral-load
    ]
  ]
end


to-report UAIs-this-week
 report filter [[condom-use?] -> not condom-use? ] intercourses-this-week
end

to-report condom-usage-this-week
  report length filter [[condom-use?] -> condom-use?] intercourses-this-week / length intercourses-this-week
end

to-report same-both-ends-as? [a-link]
  report [both-ends] of a-link = both-ends
end

to-report export-world-name
  report (word indicate-1a indicate-1b indicate-2a indicate-2b indicate-3a indicate-3b "__" random 1000)
end

to exp-w
  export-world (word "/exported_worlds/" export-world-name)
end

to-report appropriate-breed
  if count my-main-links = 0 and count my-casual-links = 0 [ report M0C0S]
  if count my-main-links = 0 and count my-casual-links = 1 [ report M0C1S]
  if count my-main-links = 0 and count my-casual-links = 2 [ report M0C2S]
  if count my-main-links = 1 and count my-casual-links = 0 [ report M1C0S]
  if count my-main-links = 1 and count my-casual-links = 1 [ report M1C1S]
  if count my-main-links = 1 and count my-casual-links = 2 [ report M1C2S]
end

to-report the-file-name
  report (word "starting_states/network-" file-n ".graphmloutput.graphml")
end

to-report #-intercourses-this-week
  report sum [ifelse-value (length intercourses-this-week > 0) [length intercourses-this-week] [0]] of my-links
end

to-report ccr5-to-number [ccr5-input]
  if ccr5-input = "WW" [report 0]
  if ccr5-input = "DW" [report 1]
  if ccr5-input = "DD" [report 2]
  report 0
end

to-report to-bool [avar]
  if is-string? avar [set avar runresult avar]
  if avar = 0 [report false]
  if avar = 1 [report true]
  report "ERROR"
end
to-report prevalence
  report count turtles with [hiv-positive?] / count turtles
end

to go-one-tick-comparison
  random-seed a-random-number
  ask links [
    set intercourses-this-week (list)
    set duration duration - 1
    set transmission-this-week false
  ]
  ask links [
    set intercourses-this-week map [ [ ] -> using-condom?] range calculate-intercourses-this-week
    if count both-ends with [hiv-positive?] = 1  [
      let infection-bool-list map [ [ condom? ] -> random-float 1 < risk-of-transmission-factors condom?] intercourses-this-week
      if length filter [[infected?] -> infected?] infection-bool-list > 0 [ ;;
        set transmission-this-week true
        ask hiv- [
          set hiv-pos-count hiv-pos-count + 1
          if hiv-transmission-network? [
            add-hiv+ [hiv+] of myself
          ]
          set hiv-positive? true set infected-at-tick ticks]
      ]
    ]
  ]
  tick

end

to-report  a-random-number
  report runresult reduce word  (sentence substring date-and-time 0 2  substring date-and-time 3 5 substring date-and-time 6 8  substring date-and-time 9 12 )
end


to-report risk-of-transmission-factors [condom?]
  if hiv- = nobody or hiv+ = nobody [report 0]
  if [viral-load] of hiv+ = 0 [report 0]
  let hiv-neg-ai-position 0
  if [sexual-role = "receptive"] of hiv- or [sexual-role = "insertive"] of hiv+ [set hiv-neg-ai-position "receptive"]
  if [sexual-role = "insertive"] of hiv- or [sexual-role = "receptive"] of hiv+ [set hiv-neg-ai-position "insertive"]
  if [sexual-role = "versatile"] of hiv- and  [sexual-role = "versatile"] of hiv+
  [
    ifelse random-float 1 < .49 [
      set hiv-neg-ai-position "IEV"
    ]
    [
      ifelse ([insertivity-preference] of hiv- / ([insertivity-preference] of hiv- + [insertivity-preference] of hiv+)) > random-float 1 [
        set hiv-neg-ai-position "insertive"
      ]
      [
        set hiv-neg-ai-position  "receptive"
      ]
    ]
  ]

  let receptive-risk 0.008938
  let insertive-risk 0.003379
  set receptive-risk receptive-risk * 2.45 ^ ([viral-load] of hiv+ - 4.5)
  set insertive-risk insertive-risk * 2.45 ^ ([viral-load] of hiv+ - 4.5)
  if hiv-neg-ai-position = "insertive" or hiv-neg-ai-position = "IEV" and [circumcized?] of hiv- [
    set insertive-risk insertive-risk * 0.4
  ]
  if [CCR5-mutation] of hiv- = 2 [
    set receptive-risk 0
    set insertive-risk 0
  ]
  if [CCR5-mutation] of hiv- = 1 [
    set receptive-risk receptive-risk * 0.3
    set insertive-risk insertive-risk * 0.3
  ]

  if condom? [
    set receptive-risk receptive-risk * 0.295
    set insertive-risk insertive-risk * 0.295
  ]

  if [on-prep?] of hiv-
  [
    set receptive-risk receptive-risk * (1 - [prep-risk-reduction] of hiv-)
    set insertive-risk insertive-risk * (1 - [prep-risk-reduction] of hiv-)
  ]
  if [is-acute?] of hiv+ [
    set receptive-risk receptive-risk * 6
    set insertive-risk insertive-risk * 6
  ]
  let risk 0
  if hiv-neg-ai-position = "IEV" [ set risk 1 - ((1 - insertive-risk) * (1 - receptive-risk))]
  if hiv-neg-ai-position = "insertive" [set risk insertive-risk]
  if hiv-neg-ai-position = "receptive" [ set risk receptive-risk]
  report risk
end

to go-n-tick-comparison [n]
  reset-ticks
  repeat n [

    ask links [
      set intercourses-this-week (list)
      set duration duration - 1
      set transmission-this-week false
    ]
    ask links [
      set intercourses-this-week map [ [ ] -> using-condom?] range calculate-intercourses-this-week
      if count both-ends with [hiv-positive?] = 1  [
        let infection-bool-list map [ [ condom? ] -> random-float 1 < risk-of-transmission-factors condom?] intercourses-this-week
        if length filter [[infected?] -> infected?] infection-bool-list > 0 [ ;;
          set transmission-this-week true
          ask hiv- [
            set hiv-pos-count hiv-pos-count + 1
            if hiv-transmission-network? [
              add-hiv+ [hiv+] of myself
            ]
            set hiv-positive? true set infected-at-tick ticks]
        ]
      ]
    ]
    let incidence count turtles with [not hiv-on-import? and hiv-positive?]
    tick
    let total-intercourses sum map [ l -> length l] [                                      intercourses-this-week] of links
    let UAIs               sum map [ l -> length l] [ filter [ intercourse -> intercourse] intercourses-this-week] of links
    file-print csv:to-row (list ticks prevalence incidence total-intercourses UAIs)

  ]
end

to run-n-ticks-m-times [n m]
  open-graphml
  show (word "opening world " file-n)
  file-open (word "world_" file-n "_for_" m "ticks_" a-random-number ".csv")
  file-print csv:to-row ["tick" "prevalence" "incidence" "intercourses" "UAIs"]
  file-print csv:to-row (list 0 prevalence file-n )
  let counter 0
  repeat m [
    ask turtles [set hiv-positive? hiv-on-import?]
    go-n-tick-comparison n
    file-print csv:to-row (list counter "-" "-")
    if counter mod 500 = 0 [file-flush

    ]
    if counter mod 5000 = 0 [
      show (list date-and-time counter)]
    set counter counter + 1
  ]
  file-flush
  file-close
  tick
  tick
  tick
  tick
end

to open-graphml
  let n file-n
  ca
  set file-n n
  nw:load-graphml the-file-name
  ask turtles [
    set on-prep? false
    set circumcized? to-bool circumcized?
    set diagnosed? to-bool diagnosed?
    set hiv-positive? to-bool hiv-positive?
    set hiv-on-import? hiv-positive?
    set age-weeks round (age-weeks * 52)
    set african-american? ifelse-value (african-american? = "B") [true] [false]
    set condom-always-pref to-bool condom-always-pref
    set always-condom-casual? to-bool always-condom-casual?
    set always-condom-onetime? to-bool always-condom-onetime?
    set ccr5-mutation ccr5-to-number ccr5-mutation
    ifelse stage < 3 and stage > 0[
      set infected-at-tick -2
    ]
    [
      set infected-at-tick 5
    ]
    set sexual-role sex-role-readin
  ]
  ask links [set hiv-disclosed? to-bool hiv-disclosed]
  reset-ticks
end

to-report sex-role-readin
  let r sexual-role
  (ifelse
    r = "R" [report "receptive"]
    r = "V" [report "versatile"]
    r = "I" [report "insertive"]
    [report "ERROR"]
  )
end

to print-link-probabilities
  file-open "Probabilities-per-link.csv"
  file-print csv:to-row ["v_name1" "v_name2" "probability"]
  ask serodiscordant-couples [
    file-print csv:to-row (list [name] of end1 [name] of end2 probability-of-using-condom)
  ]
  file-close
end

to-report link-with-ids [id1 id2]
  report one-of links with [any? both-ends with [name = id1] and any? both-ends with [name = id2]]
end

to-report transmission-risks
  report remove-duplicates map [ -> risk-of-transmission-factors one-of [true false]] range 1
end

to-report hiv-
  report one-of both-ends with [not hiv-positive?]
end
to-report hiv+
  report one-of both-ends with [hiv-positive?]
end

to-report prob-of-hiv--insertive
  if [sexual-role = "receptive"] of hiv- or [sexual-role = "insertive"] of hiv+ [report 0]
  if [sexual-role = "insertive"] of hiv- or [sexual-role = "receptive"] of hiv+ [report 1]
  report ([insertivity-preference] of hiv- / ([insertivity-preference] of hiv- + [insertivity-preference] of hiv+))
end

to write-sexual-position-probs [world-ids]
  file-open "Sexual_Position_probabilities.csv"
  file-print csv:to-row (list "World-id" "ID of HIV+" "ID of HIV-" "Prob of HIV- being Insertive")
  foreach world-ids [ id ->
    show id
    set file-n id
    open-graphml
    ask serodiscordant-couples [
      let data-list []
      set data-list lput id data-list
      set data-list lput [name] of hiv+ data-list
      set data-list lput [name] of hiv- data-list
      set data-list lput prob-of-hiv--insertive data-list
      file-print csv:to-row data-list
    ]
  ]
  file-close
end

to write-average-risk-test-n-times [n]
  ask serodiscordant-couples[
  file-open (word "/average_risk_test/" [name] of hiv+ "_" [name] of hiv- ".csv")
    repeat n [
      set intercourses-this-week map [ [ ] -> using-condom?] range calculate-intercourses-this-week
      let transmission-prob-list map [ [ condom? ] -> risk-of-transmission-factors condom?] intercourses-this-week
      file-print csv:to-row transmission-prob-list
    ]
    file-close
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
540
45
733
239
-1
-1
185.0
1
10
1
1
1
0
1
1
1
0
0
0
0
1
1
1
ticks
30.0

BUTTON
5
195
170
228
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
5
160
165
194
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
4
10
174
43
n-people
n-people
0
10000
10000.0
100
1
NIL
HORIZONTAL

TEXTBOX
1035
10
1185
28
Relationship type counts
11
0.0
1

SWITCH
5
45
165
78
infect-on-setup?
infect-on-setup?
0
1
-1000

SWITCH
5
80
165
113
distributed-infection?
distributed-infection?
0
1
-1000

SWITCH
15
245
105
278
PrEP?
PrEP?
0
1
-1000

TEXTBOX
20
230
170
248
PrEP variables
11
0.0
1

SLIDER
15
280
295
313
indication-window
indication-window
12
48
29.0
1
1
weeks/ticks
HORIZONTAL

SLIDER
15
405
260
438
partner-testing-window-ind1
partner-testing-window-ind1
0
26
26.0
1
1
NIL
HORIZONTAL

SWITCH
15
440
132
473
indicate-1a
indicate-1a
1
1
-1000

SWITCH
140
440
257
473
indicate-1b
indicate-1b
1
1
-1000

SWITCH
15
500
132
533
indicate-2a
indicate-2a
1
1
-1000

SWITCH
135
500
252
533
indicate-2b
indicate-2b
1
1
-1000

SWITCH
15
560
132
593
indicate-3a
indicate-3a
1
1
-1000

SWITCH
135
560
252
593
indicate-3b
indicate-3b
1
1
-1000

TEXTBOX
20
385
80
403
Prep 1
11
0.0
1

SLIDER
120
245
297
278
prep-coverage-fraction
prep-coverage-fraction
0
1
0.4
.01
1
NIL
HORIZONTAL

SWITCH
355
45
505
78
diagnosed-on-setup?
diagnosed-on-setup?
0
1
-1000

SWITCH
165
80
332
113
treatment-on-setup?
treatment-on-setup?
0
1
-1000

TEXTBOX
915
315
1065
356
Jenness' model has around 26% after it stabilizes. We have slightly higher.
11
0.0
1

SWITCH
165
45
352
78
age-shifted-prevalence?
age-shifted-prevalence?
0
1
-1000

SWITCH
5
120
212
153
sexual-activity-network?
sexual-activity-network?
1
1
-1000

SWITCH
215
120
412
153
hiv-transmission-network?
hiv-transmission-network?
1
1
-1000

SWITCH
15
615
132
648
indicate-4a
indicate-4a
1
1
-1000

TEXTBOX
445
445
595
541
print:\n- prevalnce at each tick\n- incidence for each tick\n- populatio nsize for each tick\n- UAI\n- AIs\n- deaths, etc.
11
0.0
1

PLOT
525
315
890
610
plot 1
NIL
NIL
0.0
10.0
0.1
0.35
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles with [hiv-positive?] / count turtles"

MONITOR
915
370
987
415
prevalence
count turtles with [hiv-positive?] / count turtles
4
1
11

INPUTBOX
235
170
387
230
AI_scale
1.525
1
0
Number

@#$#@#$#@
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.0
@#$#@#$#@
need-to-manually-make-preview-for-this-model
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="TickComparison" repetitions="100" runMetricsEveryStep="true">
    <setup>open-graphml</setup>
    <go>go-one-tick-comparison</go>
    <timeLimit steps="5"/>
    <metric>count turtles with [hiv-positive?]</metric>
    <metric>count turtles</metric>
    <metric>file-n</metric>
    <steppedValueSet variable="file-n" first="1" step="1" last="20"/>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>run-n-ticks-m-times 1 10000</setup>
    <timeLimit steps="2"/>
    <metric>1</metric>
    <steppedValueSet variable="file-n" first="1" step="1" last="20"/>
  </experiment>
  <experiment name="AI-Scaling- zoom (10k)" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="15000"/>
    <metric>count turtles with [hiv-positive?] / count turtles</metric>
    <enumeratedValueSet variable="sexual-activity-network?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="indication-window">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="test-versatile?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-people">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="indicate-3b">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="partner-testing-window-ind1">
      <value value="26"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="indicate-4a">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="treatment-on-setup?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="indicate-1a">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="indicate-1b">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diagnosed-on-setup?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="age-shifted-prevalence?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prep-coverage-fraction">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="indicate-2a">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributed-infection?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infect-on-setup?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PrEP?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="indicate-2b">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hiv-transmission-network?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="indicate-3a">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="AI_scale" first="1.5" step="0.025" last="1.575"/>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@

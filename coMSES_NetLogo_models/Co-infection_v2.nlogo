globals [
  ;infection-chance ;; The chance out of 100 that an infected person will pass on
                    ;;   infection during one week of couplehood.
  treatment-length  ;; HCV-treatment duration
  slider-check-1    ;; Temporary variables for slider values, so that if sliders
  slider-check-2    ;;   are changed on the fly, the model will notice and
  slider-check-3    ;;   change people's tendencies appropriately.
  slider-check-4
  slider-check-5
  slider-check-6
  slider-check-1-1
  slider-check-2-1
  slider-check-3-1
  slider-check-4-1
  slider-check-5-1
  slider-check-6-1
  calibration
  new-infections
  new-notifications
  cumulative-incidence
  cumulative-notifications
  annual-incidence
  annual-notifications
  start-time
  total-treats
  elimination-time
  previous-infections-dist
  commitment-dist
  partners-per-year-dist
  casual-partners-per-year-dist
  times-per-year-casual-dist
  condom-use-dist
  condom-use-dist-casual
  test-frequency-dist
  treat-wait-dist
  R0-dist
  m ;; dummy variable
  a ;; dummy variable

]

turtles-own [
  infected?          ;; If true, the person is infected.  It may be known or unknown.
  known?             ;; If true, the infection is known (and infected? must also be true).
  infection-length   ;; How long the person has been infected.
  coupled?           ;; If true, the person is in a sexually active couple.
  couple-length      ;; How long the person has been in a couple.
  commitment         ;; How long the person will stay in a couple-relationship.
  partners-per-year  ;; How likely the person is to join a couple.
  condom-use         ;; The percent chance a person uses protection in their partnership.
  condom-use-casual
  IDU
  test-frequency     ;; Number of times a person will get tested per year.
  treat-wait         ;; The nuber of weeks a person will wait to go into HCV-treatment once they are aware of infection
  time-on-treatment  ;; How long a person has been in treatment for so far
  partner            ;; The person that is our current partner in a couple.
  previous-infections ;; The number of times they have previously been HCV infected and cleared
  casual-partners-per-year
  times-per-year-casual
  concurrency
  casual-partner
  regular-partners ;; tells if someone has regular partners or not
  R0-individual
]

undirected-link-breed [partnerships partnership]
undirected-link-breed [casual-partnerships casual-partnership]
undirected-link-breed [hook-ups hook-up]
partnerships-own [lenght]
casual-partnerships-own [casual-length]



;;;
;;; SETUP PROCEDURES
;;;

to setup
  clear-all
  setup-globals
  setup-people
  reset-ticks
end

to setup-globals
  set treatment-length 12    ;; treatment length
  set slider-check-1 average-partners-per-year
  set slider-check-2 average-commitment
  set slider-check-3 average-condom-use
  set slider-check-4 infection-chance
  set slider-check-5 average-test-frequency
  set slider-check-6 average-treat-wait

  set slider-check-1-1 variation-partners-per-year
  set slider-check-2-1 variation-commitment
  set slider-check-3-1 variation-condom-use
  ;set slider-check-4-1 infection-chance
  set slider-check-5-1 variation-test-frequency
  set slider-check-6-1 variation-treat-wait
  set calibration 1
  set new-infections 0
  set new-notifications 0
  set elimination-time 0
end


to setup-people
  crt initial-people
    [ setxy random-xcor random-ycor
      set known? false
      set coupled? false
      set partner nobody
      set previous-infections 0
      set shape "person righty"
      assign-partners-per-year
      assign-casual-partners-per-year
      assign-times-per-year-casual
      assign-commitment
      assign-condom-use
      assign-test-frequency
      assign-treat-wait
      set time-on-treatment 0
      set infected? (who < initial-people * 0.1)
      ifelse random 100 < percent-concurrency [set concurrency 1][set concurrency 0]
      ifelse random 100 < percent-regular-partners [set regular-partners 1][set regular-partners 0]
      if infected?
        [ set infection-length random-float (200)
          if infection-length > 52 / max(list ([test-frequency] of self) 0.5) [set known? true] ]
      assign-color
      set casual-partner nobody ]
    ask turtles [assign-casual-partners]
    ask turtles [ifelse random-float 100 < 18 [set IDU 1][set IDU 0]]
    ask turtles [ifelse [regular-partners] of self > 0
      [set m (1 - [concurrency] of self) set a (100 - [condom-use] of self) / 100 * min( list 1 (([average-commitment] of self) / 52 * [partners-per-year] of self))]
      [set m 0 set a (100 - [condom-use-casual] of self) / 100 * ([casual-partners-per-year] of self)]
      set R0-individual min(list  (
          (infection-chance / 100) * ((100 - [condom-use-casual] of self) / 100) * (0.15 * 12 / 52 + 0.85 * (0.5 / ([test-frequency] of self) + (1 - risk-reduction-diagnosed) * ([treat-wait] of self) / 52))
          * (m * (100 - [condom-use] of self) / 100 * ([partners-per-year] of self) +
            (1 - m) * (100 - [condom-use-casual] of self) / 100 * ([casual-partners-per-year] of self) * (([times-per-year-casual] of self) / max(list 1 [casual-partners-per-year] of self))))
    a )]
end

;; Different people are displayed in 3 different colors depending on health
;; green is not HCV-infected
;; blue is HCV-infected but doesn't know it
;; red is HCV-infected and knows it

to assign-color  ;; turtle procedure
  ifelse not infected?
    [ set color green ]
    [ ifelse known?
      [ set color red ]
      [ set color blue ] ]
end

;; The following four procedures assign core turtle variables.
;alpha = mean * mean / variance; lambda = 1 / (variance / mean)
to assign-commitment  ;; turtle procedure
  set commitment random-gamma (average-commitment * average-commitment / variation-commitment) (1 / (variation-commitment / average-commitment))
  if commitment <= 0 [set commitment 1]
  set commitment-dist [commitment] of turtles
end

to assign-partners-per-year  ;; turtle procedure
  ifelse regular-partners = 1 [
    set partners-per-year random-gamma (average-partners-per-year * average-partners-per-year / variation-partners-per-year) (1 / (variation-partners-per-year / average-partners-per-year))
    ] [set partners-per-year 0]
  if partners-per-year <= 0 [set partners-per-year 1]
  set partners-per-year-dist [partners-per-year] of turtles
end


to assign-casual-partners-per-year
  ifelse random 100 > percent-with-casual-partners [set casual-partners-per-year 0]
  [set casual-partners-per-year round random-gamma (average-casual-partners-per-year * average-casual-partners-per-year / variation-casual-partners-per-year) (1 / (variation-casual-partners-per-year / average-casual-partners-per-year))]
  if casual-partners-per-year <= 0 [set casual-partners-per-year 0]
  set casual-partners-per-year-dist [casual-partners-per-year] of turtles
end


to assign-casual-partners
  ifelse casual-partner = nobody [set m ([casual-partners-per-year] of self) * percent-casual-hook-ups-who-are-regular / 100]
  [set m max(list (([casual-partners-per-year] of self) * percent-casual-hook-ups-who-are-regular / 100 - count [casual-partner] of self) 0) ]
  let casual turtle-set n-of m other turtles with [(casual-partner = nobody and [casual-partners-per-year] of self > 0)
    or (casual-partner != nobody and count [casual-partner] of self < ([casual-partners-per-year] of self) * percent-casual-hook-ups-who-are-regular / 100 and [casual-partner] of self != myself)]
  set casual-partner (turtle-set casual)
  ask casual [create-casual-partnership-with myself [set color blue set casual-length random-normal duration-casual-partnership variation-duration-casual-partnership]]
  ask casual [set casual-partner (turtle-set [casual-partner] of self myself)]
end

to assign-times-per-year-casual
  ifelse casual-partners-per-year = 0 [set times-per-year-casual 0]
  [set times-per-year-casual [casual-partners-per-year] of self * random-normal times-per-year-casual-hook-up variation-times-per-year-casual-hook-up]
  if times-per-year-casual < 0 [set times-per-year-casual 0]
  set times-per-year-casual-dist [times-per-year-casual] of turtles
end

to assign-condom-use  ;; turtle procedure
  ifelse average-condom-use = 0 [set condom-use 0] [ifelse average-condom-use = 100 [set condom-use 100]
  [set condom-use random-beta 0 100 average-condom-use variation-condom-use
  if condom-use <= 0 [set condom-use 0]
  if condom-use >= 100 [set condom-use 100]]]
  set condom-use-dist [condom-use] of turtles
  ifelse average-condom-use-casual = 0[set condom-use-casual 0] [ifelse average-condom-use-casual = 100 [set condom-use-casual 100]
  [set condom-use-casual random-beta 0 100 average-condom-use-casual variation-condom-use-casual
  if condom-use-casual <= 0 [set condom-use-casual 0]
  if condom-use-casual >= 100 [set condom-use-casual 100]]]
  set condom-use-dist-casual [condom-use-casual] of turtles
end

to assign-test-frequency  ;; turtle procedure
  set test-frequency random-beta 0 6 average-test-frequency variation-test-frequency ;(average-test-frequency * max(list (min(list ([casual-partners-per-year] of self / 4) 3)) 1))  variation-test-frequency
  if test-frequency <= 0.04 [set test-frequency 0.04]
  set test-frequency-dist [test-frequency] of turtles
end

to assign-treat-wait  ;; turtle procedure
  set treat-wait random-gamma (average-treat-wait * average-treat-wait / variation-treat-wait) (1 / (variation-treat-wait / average-treat-wait))
  if treat-wait <= 0 [set treat-wait 1]
  set treat-wait-dist [treat-wait] of turtles
end

to assign-test-frequency-2  ;; turtle procedure
  set test-frequency random-beta 0 6 scale-up-ave-test scale-up-var-test ;(scale-up-ave-test * max(list (min(list ([casual-partners-per-year] of self / 4) 3)) 1))  scale-up-var-test
  if test-frequency <= 0.04 [set test-frequency 0.04]
  set test-frequency-dist [test-frequency] of turtles
end

to assign-treat-wait-2  ;; turtle procedure
  set treat-wait random-gamma (scale-up-ave-treat-wait * scale-up-ave-treat-wait / scale-up-var-treat-wait) (1 / (scale-up-var-treat-wait / scale-up-ave-treat-wait))
  if treat-wait <= 0 [set treat-wait 1]
  set treat-wait-dist [treat-wait] of turtles
end

to-report random-near [center]  ;; turtle procedure
  let result 0
  repeat 40
    [ set result (result + random-float center) ]
  report result / 20
end




;;;
;;; GO PROCEDURES
;;;

to go
  if all? turtles [infected? = false] [ stop ]
  ;ifelse calibration > 0 [check-sliders] [check-sliders-2]
  if calibration = 0 [if (count turtles with [infected?] / count turtles) * 100 < 0.1 [stop]]
  calibrate
  set new-infections 0
  set new-notifications 0
  ask turtles
    [ if infected? [ set infection-length infection-length + 1 ]
      if coupled?  [ set couple-length couple-length + 1 ] ]
  ask turtles [ break-hook-ups]
  ;update-casual-links
  ;ask turtles [ if not coupled? [ move ] ]
  ask turtles
    [ if not coupled? and (random-float 52 < [partners-per-year] of self)
        [ couple ] ]
  ask turtles [ uncouple ]
  ask turtles
    [ if not (coupled? and concurrency = 0)
     [if (random-float 52 < [casual-partners-per-year] of self) [make-hook-ups] ] ]
  ask turtles [ infect ]
  ask turtles [ import-infections ]
  ask turtles [ test ]
  ask turtles [ treat ]
  ;ask turtles [ assign-color ]
  count-treats
  set previous-infections-dist [previous-infections] of turtles
  set cumulative-incidence cumulative-incidence + new-infections
  set cumulative-notifications cumulative-notifications + new-notifications
  set annual-incidence cumulative-incidence / max(list 1 ticks) * 52
  set annual-notifications cumulative-notifications / max(list 1 ticks) * 52
  set R0-dist [R0-individual] of turtles
  tick
end


to calibrate
  if calibration > 0 and ticks mod 30 = 0
  [ifelse (count turtles with [infected?] / count turtles) * 100 < 8
    [set infection-chance infection-chance + 0.1 * infection-chance
      setup
      set calibration 1]
    [ifelse (count turtles with [infected?] / count turtles) * 100 > 11
      [set infection-chance max(list (infection-chance - 0.1 * infection-chance) 0)
        setup
        set calibration 1]
      [set calibration calibration + 1] ] ]
  if calibration = 16 [set calibration 0
    set start-time ticks
    set new-infections 0
    set new-notifications 0
    set cumulative-incidence 0
    set cumulative-notifications 0
    check-sliders-2
    ask turtles [ifelse [regular-partners] of self > 0
      [set m (1 - [concurrency] of self) set a (100 - [condom-use] of self) / 100 * min( list 1 (([average-commitment] of self) / 52 * [partners-per-year] of self))]
      [set m 0 set a (100 - [condom-use-casual] of self) / 100 * ([casual-partners-per-year] of self)]
      set R0-individual min(list  (
          (infection-chance / 100) * ((100 - [condom-use-casual] of self) / 100) * (0.15 * 12 / 52 + 0.85 * (0.5 / ([test-frequency] of self) + (1 - risk-reduction-diagnosed) * ([treat-wait] of self) / 52))
          * (m * (100 - [condom-use] of self) / 100 * ([partners-per-year] of self) +
            (1 - m) * (100 - [condom-use-casual] of self) / 100 * ([casual-partners-per-year] of self) * (([times-per-year-casual] of self) / max(list 1 [casual-partners-per-year] of self))))
    a )]]
    ;reset-ticks]
  if calibration = 0 [set elimination-time ticks - start-time]
end


;; People move about at random.
to move
  rt random-float 360
  fd 1
end

;; People have a chance to form regular relationships.
;; To better show that this has occurred, the patches below
;; the couple turn gray.

to couple
  let pr-pair random-float 52
  let potential-partner one-of other (turtles with [partner = nobody and not coupled? and partners-per-year > pr-pair])
  if potential-partner != nobody
    [if pr-pair < [partners-per-year] of self
      [ set partner potential-partner
        create-partnership-with potential-partner
        set coupled? true
        ask partner [ set coupled? true
          set partner myself]
        setxy pxcor pycor ;; move to center of patch
        ask partner [setxy ([xcor] of myself - 1)([ycor] of myself)] ;; partner moves to center of patch
        ask partner [set pcolor gray - 3]
        set pcolor gray - 3 ] ]
end

;; If two people are in a regular partnership for longer than either person's commitment variable
;; allows, the couple breaks up.

to uncouple
  if partner != nobody
    [ if (couple-length > commitment)  or ([couple-length] of partner) > ([commitment] of partner)
        [ let pr-unpair random-float 100
          if pr-unpair < 100 * 1 / max(list ([commitment] of partner - commitment) 1) [
            set coupled? false
            ask partner [ set couple-length 0
            set pcolor black
            set partner nobody
            set coupled? false]
          ask my-partnerships [die]
          set couple-length 0
          set pcolor black
          set partner nobody ] ] ]
end

to make-hook-ups
  if not (coupled? and concurrency = 0) [
    if random 52 < times-per-year-casual [
      ifelse random times-per-year-casual <= times-per-year-casual * (1 - percent-casual-hook-ups-who-are-regular / 100)
      [let potential-partner one-of other turtles with [not (coupled? and concurrency = 0)]
          if potential-partner != nobody [create-hook-up-with potential-partner [set color yellow]] ]
      [let potential-partner one-of casual-partnership-neighbors with [not (coupled? and concurrency = 0)]
          if potential-partner != nobody [create-hook-up-with potential-partner [set color yellow]] ]
    ]
  ]
end


to update-casual-links
  ask turtles [ask casual-partnerships [if random 2 * 52 < (1 / [casual-length] of self) [die]] ]
  ask turtles [set casual-partner casual-partnership-neighbors]
  ask turtles [
       ifelse casual-partner = nobody [
         set m ([casual-partners-per-year] of self) * percent-casual-hook-ups-who-are-regular / 100]
         [set m max(list (([casual-partners-per-year] of self) * percent-casual-hook-ups-who-are-regular / 100 - count [casual-partner] of self) 0) ]
       if m > 0 [
         let casual n-of m other turtles with [(casual-partner = nobody and [casual-partners-per-year] of self > 0)
           or (casual-partner != nobody and (count [casual-partner] of self) * percent-casual-hook-ups-who-are-regular / 100 < ([casual-partners-per-year] of self) * percent-casual-hook-ups-who-are-regular / 100)
           and casual-partner = casual-partner with [self != myself]]
         ;let casual2 casual with [not member? [casual-partner] of self turtle-set myself]
         set casual-partner (turtle-set [casual-partner] of self casual)
         if casual != nobody [
           ask casual [create-casual-partnership-with myself [set color blue set casual-length random-normal duration-casual-partnership variation-duration-casual-partnership]]
           ask casual [set casual-partner (turtle-set [casual-partner] of self myself)]
         ]
       ]
  ]
end

to break-hook-ups
  if count (hook-up-neighbors) > 0
  [ask my-hook-ups [die]
  ]
end


to infect
  if coupled? and infected? [
    ifelse not known?
      [ if random-float 100 > condom-use
         ;; or random-float 100 > ([condom-use] of partner)
        [ if random-float 100 < infection-chance
            [ ask partner [ set infected? true ]
              set new-infections new-infections + 1 ] ] ]
    [ if random-float 100 > condom-use + (1 - condom-use) * risk-reduction-diagnosed
         ;; or random-float 100 > ([condom-use] of partner)
        [ if random-float 100 < infection-chance
            [ ask partner [ set infected? true ]
              set new-infections new-infections + 1 ] ] ]
    ]
   if count hook-up-neighbors > 0 and infected? [
    ifelse not known?
    [ ask hook-up-neighbors [
        if random-float 100 > [condom-use-casual] of myself
          [if random-float 100 < infection-chance
            [set infected? true
            set new-infections new-infections + 1 ] ] ] ]
    [ ask hook-up-neighbors [
        if random-float 100 > ([condom-use-casual] of myself) + (1 - ([condom-use-casual] of myself)) * risk-reduction-diagnosed
          [if random-float 100 < infection-chance
            [set infected? true
            set new-infections new-infections + 1 ] ] ] ]
   ]
end

to import-infections
  if IDU = 1 and not infected?
  [ if random-float 100 < import-probability
    [set infected? true
     set new-infections new-infections + 1]]
end


to test
  if random-float 1 < test-frequency / 52
    [ if infected?
        [ set known? true
          set new-notifications new-notifications + 1] ]
end

to treat
  if infected? and known?
    [ifelse time-on-treatment = 0
      [if random-float 1 < (1 / treat-wait)
        [set time-on-treatment time-on-treatment + 1] ]
      [set time-on-treatment time-on-treatment + 1]
     if time-on-treatment = treatment-length
       [set infected? false
         set known? false
         set infection-length 0
         set previous-infections previous-infections + 1
         set time-on-treatment 0] ]
end

to count-treats
  if calibration = 0
  [set total-treats total-treats + count turtles with [time-on-treatment = 1] ]
end




;;;
;;; MONITOR PROCEDURES
;;;

to-report %infected
  ifelse any? turtles
    [ report (count turtles with [infected?] / count turtles) * 100 ]
    [ report 0 ]
end

to-report treatment-rate
  ifelse any? turtles
    [ report (count turtles with [time-on-treatment = 1] / count turtles) * 1000 ]
    [ report 0 ]
end


to-report calibration-variable
  report calibration
end

to-report R0
  report sum([R0-individual] of turtles) / count turtles
end


to-report random-beta [#minval #maxval #likeval #varval]
  ;use pert params to draw from a beta distribution
  if not (#minval <= #likeval and #likeval <= #maxval) [error "wrong argument ranking"]
  if (#minval = #likeval and #likeval = #maxval) [report #minval] ;;handle trivial inputs
  let pert-var #varval / (#maxval - #minval)
  let pert-mean (#likeval - #minval) / (#maxval - #minval) ;(#maxval + 4 * #likeval - 5 * #minval) / (6 * (#maxval - #minval))
  ;let temp pert-mean * (1 - pert-mean) / pert-var
  ;let alpha1 pert-mean * (temp - 1)
  ;let alpha2 (1 - pert-mean) * (temp - 1)
  let alpha1 (-1) * pert-mean * (pert-var + pert-mean ^ 2 - pert-mean) / pert-var
  let alpha2 (pert-var + pert-mean ^ 2 - pert-mean) * (pert-mean - 1) / pert-var
  let x1 random-gamma alpha1 1
  let x2 random-gamma alpha2 1
  report (x1 / (x1 + x2)) * (#maxval - #minval) + #minval
end

;; Each tick a check is made to see if sliders have been changed.
;; If one has been, the corresponding turtle variable is adjusted

to check-sliders
  if (slider-check-1 != average-partners-per-year)
    [ ask turtles [ assign-partners-per-year ]
      set slider-check-1 average-partners-per-year ]
  if (slider-check-2 != average-commitment)
    [ ask turtles [ assign-commitment ]
      set slider-check-2 average-commitment ]
  if (slider-check-3 != average-condom-use)
    [ ask turtles [ assign-condom-use ]
      set slider-check-3 average-condom-use ]
  ;if (slider-check-4 != infection-chance )
  ;   [ set slider-check-4 infection-chance ]
  if (slider-check-5 != average-test-frequency)
    [ ask turtles [ assign-test-frequency ]
      set slider-check-5 average-test-frequency ]
  if (slider-check-6 != average-treat-wait)
    [ ask turtles [ assign-treat-wait ]
      set slider-check-6 average-treat-wait ]

   if (slider-check-1-1 != variation-partners-per-year)
    [ ask turtles [ assign-partners-per-year ]
      set slider-check-1-1 variation-partners-per-year ]
  if (slider-check-2-1 != variation-commitment)
    [ ask turtles [ assign-commitment ]
      set slider-check-2-1 variation-commitment ]
  if (slider-check-3-1 != variation-condom-use)
    [ ask turtles [ assign-condom-use ]
      set slider-check-3-1 variation-condom-use ]
  if (slider-check-5-1 != variation-test-frequency)
    [ ask turtles [ assign-test-frequency ]
      set slider-check-5-1 variation-test-frequency ]
  if (slider-check-6-1 != variation-treat-wait)
    [ ask turtles [ assign-treat-wait ]
      set slider-check-6-1 variation-treat-wait ]
end

to check-sliders-2
  if (slider-check-1 != average-partners-per-year)
    [ ask turtles [ assign-partners-per-year ]
      set slider-check-1 average-partners-per-year ]
  if (slider-check-2 != average-commitment)
    [ ask turtles [ assign-commitment ]
      set slider-check-2 average-commitment ]
  if (slider-check-3 != average-condom-use)
    [ ask turtles [ assign-condom-use ]
      set slider-check-3 average-condom-use ]
  ;if (slider-check-4 != infection-chance )
  ;   [ set slider-check-4 infection-chance ]
  if (slider-check-5 != scale-up-ave-test)
    [ ask turtles [ assign-test-frequency-2 ]
      set slider-check-5 scale-up-ave-test ]
  if (slider-check-6 != scale-up-ave-treat-wait)
    [ ask turtles [ assign-treat-wait-2 ]
      set slider-check-6 scale-up-ave-treat-wait ]

   if (slider-check-1-1 != variation-partners-per-year)
    [ ask turtles [ assign-partners-per-year ]
      set slider-check-1-1 variation-partners-per-year ]
  if (slider-check-2-1 != variation-commitment)
    [ ask turtles [ assign-commitment ]
      set slider-check-2-1 variation-commitment ]
  if (slider-check-3-1 != variation-condom-use)
    [ ask turtles [ assign-condom-use ]
      set slider-check-3-1 variation-condom-use ]
  if (slider-check-5-1 != scale-up-var-test)
    [ ask turtles [ assign-test-frequency-2 ]
      set slider-check-5-1 variation-test-frequency ]
  if (slider-check-6-1 != scale-up-var-treat-wait)
    [ ask turtles [ assign-treat-wait-2 ]
      set slider-check-6-1 scale-up-var-treat-wait ]
end
@#$#@#$#@
GRAPHICS-WINDOW
331
10
766
466
12
12
17.0
1
10
1
1
1
0
1
1
1
-12
12
-12
12
1
1
1
weeks
30.0

BUTTON
12
81
95
114
setup
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

BUTTON
96
81
179
114
go
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

MONITOR
184
74
267
119
% infected
%infected
2
1
11

SLIDER
7
37
276
70
initial-people
initial-people
50
5000
5000
1
1
NIL
HORIZONTAL

PLOT
779
10
1048
209
Populations
weeks
people
0.0
52.0
0.0
350.0
true
true
"set-plot-y-range 0 (initial-people + 50)" ""
PENS
"S" 1.0 0 -10899396 true "" "plot count turtles with [not infected?]"
"HCV+" 1.0 0 -2674135 true "" "plot count turtles with [known?]"
"HCV?" 1.0 0 -13345367 true "" "plot count turtles with [infected?] - count turtles with [known?]"

INPUTBOX
489
471
644
531
infection-chance
1.05
1
0
Number

INPUTBOX
10
216
165
276
average-partners-per-year
1
1
0
Number

INPUTBOX
9
278
164
338
average-commitment
234
1
0
Number

INPUTBOX
9
339
164
399
average-condom-use
19
1
0
Number

INPUTBOX
330
554
485
614
average-test-frequency
1.4
1
0
Number

INPUTBOX
330
616
485
676
average-treat-wait
200
1
0
Number

INPUTBOX
167
216
322
276
variation-partners-per-year
0.25
1
0
Number

INPUTBOX
167
277
322
337
variation-commitment
432
1
0
Number

INPUTBOX
166
339
321
399
variation-condom-use
5
1
0
Number

INPUTBOX
488
554
643
614
variation-test-frequency
0.25
1
0
Number

INPUTBOX
488
616
643
676
variation-treat-wait
30
1
0
Number

MONITOR
778
213
963
258
Treatment rate (per 1000 per year)
treatment-rate
17
1
11

MONITOR
966
213
1036
258
calibration
calibration-variable
17
1
11

INPUTBOX
660
554
815
614
scale-up-ave-test
1.4
1
0
Number

INPUTBOX
818
554
973
614
scale-up-var-test
0.05
1
0
Number

INPUTBOX
659
616
814
676
scale-up-ave-treat-wait
26
1
0
Number

INPUTBOX
818
615
973
675
scale-up-var-treat-wait
5
1
0
Number

MONITOR
779
260
867
305
Total treatments
total-treats
0
1
11

MONITOR
868
260
1034
305
Weeks from scale-up campaign
elimination-time
0
1
11

PLOT
780
306
1058
484
Populations post-intervention
Weeks from scale-up
People
0.0
10.0
0.0
10.0
true
true
"set-plot-y-range 0 (0.15 * count turtles)" "if calibration = 0 [set-plot-x-range start-time start-time + 52]"
PENS
"HCV+" 1.0 0 -2674135 true "" "plot count turtles with [known?]"
"HCV?" 1.0 0 -13345367 true "" "plot count turtles with [infected?] - count turtles with [known?]"

INPUTBOX
11
752
166
812
percent-concurrency
30
1
0
Number

INPUTBOX
12
484
167
544
average-casual-partners-per-year
13
1
0
Number

INPUTBOX
168
484
323
544
variation-casual-partners-per-year
46
1
0
Number

INPUTBOX
331
471
486
531
import-probability
0.01
1
0
Number

INPUTBOX
8
401
163
461
average-condom-use-casual
42
1
0
Number

INPUTBOX
166
401
321
461
variation-condom-use-casual
5
1
0
Number

INPUTBOX
12
545
167
605
duration-casual-partnership
52
1
0
Number

INPUTBOX
168
545
323
605
variation-duration-casual-partnership
5
1
0
Number

INPUTBOX
11
670
166
730
percent-with-casual-partners
56
1
0
Number

INPUTBOX
11
607
166
667
times-per-year-casual-hook-up
17
1
0
Number

INPUTBOX
169
607
324
667
variation-times-per-year-casual-hook-up
10
1
0
Number

INPUTBOX
170
669
324
729
percent-casual-hook-ups-who-are-regular
95
1
0
Number

TEXTBOX
187
176
337
233
Regular partners
12
0.0
1

TEXTBOX
127
465
277
483
Casual partners
12
0.0
1

TEXTBOX
401
537
599
567
Current testing and treatment
12
0.0
1

TEXTBOX
722
532
930
562
Intervention testing and treatment
12
0.0
1

MONITOR
955
490
1060
535
annual-incidence
annual-incidence
17
1
11

INPUTBOX
172
752
327
812
risk-reduction-diagnosed
0.45
1
0
Number

INPUTBOX
10
152
165
212
percent-regular-partners
30
1
0
Number

MONITOR
1003
542
1060
587
R0
R0
2
1
11

MONITOR
941
687
1062
732
annual-notifications
annual-notifications
17
1
11

@#$#@#$#@
## OVERVIEW

This model was built by modifying the existing AIDS model to simulate HCV rather than HIV transmission dynamics, to include different types of sexual partnerships (described below) and to reflect the characteristics of MSM in Victoria.

The model uses weekly time steps and at each step agents in the model have an HCV status (not infected, infected and undiagnosed, diagnosed, in treatment), and can interact with other agents through “regular partnerships�? (relationships lasting more than one time step), or “casual partnerships�? (relationships lasting only one time step). Each agent tracks a network of “regular-casual partners�? (a network of “fuck-buddies�?—individuals who they meet up with for casual partnerships on more than one occasion), so that when a casual interaction occurs it can be with either a regular-casual partner or a once-off “random-partner�?. A percentage of agents do not form any casual partnerships, and conversely a percentage of agents have concurrent partnerships (approximating behaviours such as having one or more simultaneous partners or participating in group sex).

An additional feature, an “HCV import probability�?, is included to account for all other transmission mechanisms. For example, transmission though partnerships between agents (HIV-positive MSM) and HIV-negative MSM (which contribute substantially lower risk of HCV transmission to agents as HIV-negative MSM are much less likely to be HCV-infected), transmission though injecting drug use or transmission during international travel.


## SIMULATION STEPS
The model time-steps represent one week, and at each step the following eight procedures are performed:

1)	Increase the duration of existing infections, partnerships and treatment courses:

Agents who reach 17 weeks on treatment (see Table S1) become uninfected (setting 		HCV-infection status=0, length of infection=0, diagnosis status=0 and time on 			treatment=0).


2)	Create new regular-partnerships:

For each agent with no regular-partner, an independent random number pr< 52 is 			drawn. If pr<(regular partners per year) AND there is another un-partnered agent 		with pr<(partners per year), the two agents will pair (both setting partnership 		status=1 and each other as their partner).


3)	End some old regular-partnerships:

For each regular-partnership, if the partnership length > the average relationship length of either agent then a random number pr<1 is drawn. If pr< (1 / 	difference in average relationship lengths of partners), then they will separate (both 	setting partnership status=0 and regular partner to nobody).


4)	Assign some casual interactions:

For each agent who is available for casual sex (i.e. either does not have a regular partner or has a regular partner and is able to have concurrent partners), an independent random number pr<52 is drawn. If pr<frequency of hook-up with a casual partner, the agent will create a temporary casual-partnership link to either an available agent in their regular-casual network (if another random number pr2 < casual partners per year*(1- % of casual hook-ups that are with regular partners)) or to a randomly selected available agent.


5)	Spread infection through some discordant partnerships:

For each partnership link (regular or casual), an independent random number pr<100 is drawn. If pr>the condom use probability of either agent, condoms are assumed to have been used inconsistently. Therefore, to determine the chance of infection spread a second random number pr2<100 is drawn. If pr2<infection-chance (the global parameter, see calibration below) then the uninfected partner acquires HCV (setting HCV infection status=1).


6)	End casual interactions:

Links assigned in step 5 will be removed. This does not change the regular-casual network of individual agents.


7)	Allow agents to test for HCV-infection:

For each HCV-infected agent, an independent random number pr<52 is drawn. If pr<their test frequency then the agent is diagnosed (setting diagnosis status=1).


8)	Allow diagnosed HCV-infected agents to commence treatment:

For each infected and diagnosed agent, an independent random number pr<52 is drawn. If pr< their waiting time from diagnosis to treatment commencement then the agent commences treatment (setting time on treatment=1).

## CALIBRATION
The “infection chance parameter�? – the probability that HCV is transmitted between a discordant MSM partnership in a single time step – is varied until the estimated HCV prevalence of 10% among HIV-positive MSM in Victoria was achieved. However, due to the stochasticity of the model this involves incremental variations of the “infection chance�? parameter throughout an extensive model burn-in period. The model is started with 10% of the population infected and undiagnosed. Every 30 time-steps, the prevalence is checked: if it is greater than 11.5%, the infection chance probability is lowered by 10% of its current value, if it is less than 8.5%, the infection chance probability is increased by 10% of its current value, and if it falls within the accepted range of 8.5–11.5%, no changes are made. The model is then run for another 30 time steps and this process is repeated. This is continued until the model prevalence has been within the 8.5–11.5% range for 15 consecutive checks, at which point the simulation burn-in period is ended.

## IMPLEMENTING TREATMENT SCALE-UP
After the burn-in period of a simulation is completed, the testing rates and waiting time to treatment variables are re-distributed. The number of people infected with HCV and cumulative number of treatments initiated is recorded at each time step for a three-year projection.


## BASIC REPRODUCTION NUMBER (R0)
A similar approach to Anderson and May is used. Let:

“Regular partners or not�? be a binary variable for whether or not an individual is in a regular relationship;

“Concurrency�? be a binary variable for whether or not an individual has concurrent partners (including when in a regular relationship); and

“m�? be the expected proportion of a year that an individual spends in a monogamous regular relationship.

Then

m=min(1,regular parners or not * average regular relationship length) * (1-concurrency)

and we can calculate an individual’s expected number of transmission (if infected) as:

c= force of infection * expected duration of infection * [m * (1-condom use regular) * average regular relationship length + (1-m) * (1-condom use casual) * number of casual partners per year * average hook–ups per year with each casual partner]

where the expected duration of infection for an individual is weighted by their transmission risk and defined as

1/(testing frequency) + (risk reduction post diagnosis) * (time from diagnosis to treatment).

If we let Pr(c) be the probability density function for c, then the expected number of new infections caused by one typical infected individual in a completely susceptible population is calculated as

R0=∫cPr(c)≈1/N ∑_(i=1)^N c

for a population size N.
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

person lefty
false
0
Circle -7500403 true true 170 5 80
Polygon -7500403 true true 165 90 180 195 150 285 165 300 195 300 210 225 225 300 255 300 270 285 240 195 255 90
Rectangle -7500403 true true 187 79 232 94
Polygon -7500403 true true 255 90 300 150 285 180 225 105
Polygon -7500403 true true 165 90 120 150 135 180 195 105

person righty
false
0
Circle -7500403 true true 50 5 80
Polygon -7500403 true true 45 90 60 195 30 285 45 300 75 300 90 225 105 300 135 300 150 285 120 195 135 90
Rectangle -7500403 true true 67 79 112 94
Polygon -7500403 true true 135 90 180 150 165 180 105 105
Polygon -7500403 true true 45 90 0 150 15 180 75 105

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
0
@#$#@#$#@

globals [
;set in user interface:
;  population            ; targeted number of agents, can be slightly different after set-up due to stochastics
;  mean-encounters       ; average number of encounters outside the own household that individuals have, per time step
;  p_adoption            ; fraction of aadopters (excluding deceased) who are expexted to install the application, per time step
;  p_quit                ; fraction of adopters who are expected to quit using the app, per time step
;  p_failure             ; fraction of time the app is expected to be off during contacts outside the household
;  initial-infections    ; number of agents intially infected
;  p_external-inf        ; fraction of susceptible agents infected from external sources, per time step
;  p_i-per-encounter     ; probability that infection is tranmitted when encountering an infected or symptomatic person (calibrated in setup)
;  p_asymptomatic        ; probability of state transition "infected" --> "immune", per time step
;  p_symptomatic         ; probability of state transition "infected" --> "symptomatic" , per time step
;  p_mortality           ; probability of state transition "symptomatic" --> "deceased", per time step
;  p_recovery            ; probability of state transition "symptomatic" --> "immune", per time step
;  p_backslide           ; probability of state transition "immune" --> "suceptible", per time step
;  p_other_disease       ; probability that an indidividual suffers from symilar symptoms, caused by another disease
;  lock-down             ; switch, full lockdown reduces the contact-frequency, and thus R0, by 75%
;  time-step-lockdown    ; time step in which lockdown is put in place if lockdown = true
;  time-step-lockdown-release    ; time step in which release from lockdown is started
;  lockdown-release-steps        ; if 0, immediate full release; otherwise gradually in a number of stages of 3 time steps
;  app                   ; switch, if on the app will be running from time-step-app-launch
;  time-step-app-launch  ; time step in which the app is to be launched if app = true
  app-introduced        ; true after user pushed the introduce-app button
  setup-population      ; initial population size after setup
  mean-household-size   ; average household size after setup
  lockdown-factor       ; = current / initial contact-frequency
; statistics:
  current-population    ; number of living agents
  average-contacts      ; average length of individuls' contact lists in recent time step
  R0                    ; reproduction rate (average number of individuals infected by an infected individual before it recovers)
  app-users             ; number of agents who have adopted the smartphone application
  percent-infected      ; patients in state "infected" (asymptomatic)
  percent-symptomatic   ; patients in symptomatic state
  percent-immune        ; patients in state "immune"
  isolated              ; number of patients in isolation
  test-counter          ; to continuously record numer of tests performed
  tests                 ; number of tests performed during recent time step
  positive-test-counter ; to continuously record numer of tests with outcome "positive"
  positive-tests        ; number of tests with outcome "positive"
  percent-isolated
  percent-tests
  peak-tests-1
  peak-tests-2
  peak-isolated-1
  peak-isolated-2
  peak-symptomatic-1
  peak-symptomatic-2
  peak-time-1
  peak-time-2
]

turtles-own [
  household-members     ; agent set of other members of the household (may be empty)
  app-adopted           ; boolean, true when the application is currently installed on the agent's smartphone
  app-running           ; boolean, true when the app is currently running
  app-contact-list      ; list of contacts, only for application users
  contact-frequency-0   ; initial number of encountered others per time step
  contact-persistence   ; fraction of contacts from previous time step to be encountered again in current time step
  contacts              ; agent set, all contacts initiated by the individual in current time-step
  corona-state          ; literal, one of {"susceptible", "infected", "symptomatic", "immune", "deceased"}
  corona-state-time     ; time step of recent status change
  ill                   ; boolean, true if symptomatic either from the virus or another disease causing similar symptoms
  test-state            ; literal, one of {"none", "positive", "negative", "immune"}
  test-time             ; time step of recent test
  in-isolation          ; boolean
  in-isolation-time     ; time of recent isolation state change
  test-request          ; true when waiting to be tested
  susceptible           ; boolean to indicate corona state
  infected              ; boolean to indicate corona state
  immune                ; boolean to indicate corona state
  symptomatic           ; boolean to indicate corona state
  deceased              ; boolean to indicate corona state
  infected-contacts     ; number of contacts with infected or symptomatic individuals initiated by the agent
]

to DEFAULT;  values of parameters to be set in the user interface; to be checked
  set population         17000   ; number of agents, will be adjusted to fit a sqare world with one household per patch
  set mean-encounters    100     ; average number of encounters outside the own household that individuals have, per time step
  set p_adoption         0.2     ; fraction of aadopters (excluding deceased) who are expexted to install the application, per time step
  set p_quit             0.1     ; fraction of adopters who are expected to quit using the app, per time step
  set p_failure          0.1     ; fraction of time the app is expected to be off during contacts outside the household
  set initial-infections 0       ; number of agents intially infected
  set p_external-inf     0.001   ; fraction of susceptible agents infected from external sources, per time step
  set p_i-per-encounter  0.020   ; reproduction rate (average number of individuals infected by an infected individual before it recovers)
  set p_asymptomatic     0.5     ; probability of state transition "infected" --> "immune", per time step
  set p_symptomatic      0.5     ; probability of state transition "infected" --> "symptomatic" , per time step
  set p_mortality        0.0035  ; probability of state transition "symptomatic" --> "deceased", per time step
  set p_recovery         0.70    ; probability of state transition "symptomatic" --> "immune", per time step
  set p_backslide        0       ; probability of state transition "immune" --> "suceptible", per time step
  set p_other-disease    0.01    ; probability that an indidividual suffers from similar symptoms, caused by another disease
  set simulation-time    25      ; simulation stops after 25 tomi steps (typically approximately half a year)
  set lockdown           false   ; initially no reduced contact frequency
  set time-step-lockdown 3       ; time step in which lockdown is put in place if lockdown = true
  set time-step-lockdown-release 9   ; time step in which release from lockdown is started
  set lockdown-release-steps     0   ; if 0, immediate full release; otherwise gradually in a number of stages of 3 time steps
  set app                false   ; switch, if on the app will be running from time-step-app-launch
  set time-step-app-launch       8   ; time step in which the app is to be launched if app = true
end; default

to setup
  clear-all
  reset-ticks
  let household-size-distribution shuffle (sentence n-values 38 [1] n-values 33 [2] n-values 12 [3] n-values 12 [4] n-values 5 [6])
  let axis-length int sqrt (population / 8.72)
  resize-world (- axis-length) axis-length (- axis-length) axis-length
  ask patches
  [ set pcolor white
    sprout one-of household-size-distribution
    [ set shape "person"
      set size 0.8
      set household-members other turtles-here
      set app-adopted false
      set app-running false
      set app-contact-list [ ]
      set-susceptible
      set ill false
      set test-state "none"
      set test-time 0
      set in-isolation false
      set test-request false
      set contact-frequency-0 random (mean-encounters + 1)
      set contact-persistence random-float 1
      set contacts no-turtles
    ]
  ]
  ask n-of initial-infections turtles [set-infected]
  set setup-population count turtles
  set mean-household-size setup-population / count patches
  set app-introduced false
  set peak-symptomatic-1 0
  set peak-symptomatic-2 0
  set peak-isolated-1 0
  set peak-isolated-2 0
  set peak-tests-1 0
  set peak-tests-2 0
  set peak-time-1 0
  set peak-time-2 0
;  reset-ticks
end; setup

to go
  tick      ; a tick typicallly represents a week
  if app and ticks > time-step-app-launch [set app-introduced true]
  ifelse lockdown and ticks > time-step-lockdown and ticks < (time-step-lockdown-release + 3 * lockdown-release-steps) [
    ifelse ticks < time-step-lockdown-release [
      set lockdown-factor 0.25
    ][; else
      set lockdown-factor 0.25 + (0.75 / lockdown-release-steps) * int ((ticks - time-step-lockdown-release + 2) / 3)
    ]
  ][; else
    set lockdown-factor 1
  ]
  ask turtles
  [ adopt-smartphone-application
    encounter-other-agents
    state-transitions
    ifelse deceased [
      die
    ][; else
      test
      set-isolation-state
    ]
  ]
  statistics
  if ticks >= simulation-time [ stop ]                                                               ; the simulation-time parameter is set in the user interface
end; go

to adopt-smartphone-application
  ifelse app-adopted and (p_quit > random-float 1) [
    set app-adopted false
    set app-running false
    set app-contact-list [ ]
  ][; else
    if app-introduced and p_adoption > random-float 1 [
      set app-adopted true
    ]
  ]
end; adopt-smartphone-application

to encounter-other-agents
  if app-adopted [set app-running p_failure < random-float 1]
  let to-encounter [ ]
  ifelse in-isolation [
    set to-encounter household-members
  ][; else
    let contact-frequency lockdown-factor * contact-frequency-0
    set contacts up-to-n-of round (0.5 + contact-persistence * contact-frequency) contacts
    set contacts (turtle-set contacts up-to-n-of (contact-frequency - count contacts) turtles)       ; multiple assignments are possible, but will not be statistically relevant
    set contacts contacts with [not in-isolation]
    set to-encounter (turtle-set contacts household-members)
  ]
  set infected-contacts 0
  foreach sort to-encounter [contact ->
    if app-running and [app-running] of contact [
      set app-contact-list lput contact app-contact-list
      ask contact [set app-contact-list lput myself app-contact-list]
    ]
    let contact-state [corona-state] of contact
    ifelse susceptible and (contact-state = "infected" or contact-state = "symptomatic") [
      set infected-contacts infected-contacts + 1
    ][; else
      if (infected or symptomatic) and (contact-state = "susceptible") [
        ask contact [
          if p_i-per-encounter > random-float 1 [set-infected]
        ]
      ]
    ]
  ]
end; encounter-other-agents

to state-transitions
  if symptomatic and p_mortality > random-float 1 [set-deceased]
  if symptomatic and p_recovery / (1 - p_mortality) > random-float 1 [set-immune]
  if infected and p_symptomatic > random-float 1 [set-symptomatic]
  if infected and p_asymptomatic / (1 - p_symptomatic)  > random-float 1 [set-immune]
  if immune and p_backslide > random-float 1 [set-susceptible]
  if susceptible and p_external-inf > random-float 1 [set-infected]
  while [infected-contacts > 0 and susceptible] [
    if p_i-per-encounter > random-float 1 [set-infected]
    set infected-contacts infected-contacts - 1
  ]
  set ill symptomatic or p_other-disease > random-float 1
end; state-transitions

to check-application ; is activated after positive test of a recent contact
  if test-state = "unknown" or test-state = "negative" [
    go-into-isolation
    set test-request true
  ]
end; check-application

to test
  if in-isolation or test-request or ill [
    set test-counter test-counter + 1
    set test-request false
    set test-time ticks
    ifelse immune [
      set test-state "immune"
    ][; else
      ifelse susceptible [
        set test-state "negative"
      ][; else
        set positive-test-counter positive-test-counter + 1
        set test-state "positive"
        go-into-isolation
        ask household-members [
          go-into-isolation
          set test-request true
        ]
        ask (turtle-set app-contact-list) with [app-adopted] [check-application]
      ]
    ]
  ]
end; test

to set-isolation-state
  ifelse any? household-members with [test-state = "positive"] [     ; policy: entire household in isolation if one meber tested positive
    go-into-isolation
  ][; else
    ifelse in-isolation [
      if test-time = ticks and                                       ; release only based on recent test if:
          (test-state = "immune"                                     ; recovered
          or (test-state = "negative" and (ill                       ; or symptoms only caused by other disease
             or in-isolation-time < (ticks - 1)))) [                    ; or end of incubation period
        go-out-of-isolation
      ]
    ][; else
      if ill or test-state = "positive" [
        go-into-isolation
      ]
    ]
  ]
end; set-isolation-state

to go-into-isolation
  set in-isolation-time ticks
  set in-isolation true
  set color red
end; go-into-isolation

to go-out-of-isolation
  set in-isolation-time ticks
  set in-isolation false
  ifelse susceptible [
    set color grey
  ][ ;else
    if immune [
      set color green
    ]
  ]
end; go-out-of-isolation

to set-susceptible
  set corona-state "susceptible"
  set corona-state-time ticks
  set color grey
  set susceptible true
  set infected false
  set immune false
  set symptomatic false
  set deceased false
end; set-susceptible

to set-infected
  set corona-state "infected"
  set corona-state-time ticks
  set color black
  set susceptible false
  set infected true
  set immune false
  set symptomatic false
  set deceased false
end; set-infected

to set-immune
  set corona-state "immune"
  set corona-state-time ticks
  set color green
  set susceptible false
  set infected false
  set immune true
  set symptomatic false
  set deceased false
end; set-immune

to set-symptomatic
  set corona-state "symptomatic"
  set corona-state-time ticks
  set color orange
  set susceptible false
  set infected false
  set immune false
  set symptomatic true
  set deceased false
end; set-symptomatic

to set-deceased
  set corona-state "deceased"
  set corona-state-time ticks
  set color black
  set susceptible false
  set infected false
  set immune false
  set symptomatic false
  set deceased true
end; set-deceased

to statistics
  set current-population count turtles
  set average-contacts 2 * mean [count contacts] of turtles
  set app-users count turtles with [app-adopted]
  set percent-infected 100 * count turtles with [infected] / current-population    ; patients in state "infected" (asymptomatic)
  set percent-symptomatic 100 * count turtles with [symptomatic] / current-population  ; patients in symptomatic state
  set percent-immune 100 * count turtles with [immune] / current-population
  set isolated count turtles with [in-isolation]             ; number of patients in isolation
  set percent-isolated 100 * isolated / current-population
  set tests test-counter                ; number of tests performed during recent time step
  set percent-tests 100 * tests / current-population
  set test-counter 0
  set positive-tests positive-test-counter       ; number of tests with outcome "positive"
  set positive-test-counter 0
  ifelse ticks < 10 [
    if percent-symptomatic > peak-symptomatic-1 [
      set peak-symptomatic-1 percent-symptomatic
      set peak-time-1 ticks
    ]
    if percent-isolated > peak-isolated-1 [
      set peak-isolated-1 percent-isolated
    ]
    if percent-tests > peak-tests-1 [
      set peak-tests-1 percent-tests
    ]
  ][; else
    if percent-symptomatic > peak-symptomatic-2 [
      set peak-symptomatic-2 percent-symptomatic
      set peak-time-2 ticks
    ]
    if percent-isolated > peak-isolated-2 [
      set peak-isolated-2 percent-isolated
    ]
    if percent-tests > peak-tests-2 [
      set peak-tests-2 percent-tests
    ]
  ]
  set R0 (percent-immune * mean-household-size / 100 + 2 * mean [count contacts with [not immune]] of turtles with [not immune]) * p_i-per-encounter
end; statistics
@#$#@#$#@
GRAPHICS-WINDOW
680
10
2112
1443
-1
-1
16.0
1
10
1
1
1
0
1
1
1
-44
44
-44
44
1
1
1
ticks
30.0

BUTTON
11
10
74
43
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

BUTTON
380
10
443
43
step1
go
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
466
10
530
43
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

SLIDER
95
10
360
43
simulation-time
simulation-time
0
200
25.0
5
1
time steps
HORIZONTAL

BUTTON
11
556
275
589
set default values
DEFAULT
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
11
47
275
80
population
population
0
100000
17000.0
1000
1
individuals
HORIZONTAL

SLIDER
11
192
275
225
mean-encounters
mean-encounters
0
200
100.0
1
1
per ind. per time step
HORIZONTAL

MONITOR
547
10
676
55
NIL
mean-household-size
3
1
11

SLIDER
11
228
275
261
initial-infections
initial-infections
0
100
0.0
1
1
(total number)
HORIZONTAL

SLIDER
11
265
275
298
p_external-inf
p_external-inf
0
0.01
0.001
0.001
1
(infection prob. per step)
HORIZONTAL

SLIDER
11
302
275
335
p_i-per-encounter
p_i-per-encounter
0
0.100
0.02
0.001
1
(transmission probability)
HORIZONTAL

SLIDER
11
338
275
371
p_asymptomatic
p_asymptomatic
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
11
374
275
407
p_symptomatic
p_symptomatic
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
11
410
275
443
p_mortality
p_mortality
0
0.02
0.0035
0.0005
1
NIL
HORIZONTAL

SLIDER
11
446
275
479
p_recovery
p_recovery
0
1
0.7
0.01
1
NIL
HORIZONTAL

SLIDER
11
482
275
515
p_backslide
p_backslide
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
11
83
275
116
p_adoption
p_adoption
0
1
0.2
0.01
1
(app adoption per time step)
HORIZONTAL

SLIDER
11
119
275
152
p_quit
p_quit
0
1
0.1
0.01
1
(probability per time step)
HORIZONTAL

SLIDER
11
155
275
188
p_failure
p_failure
0
1
0.1
0.01
1
(average fraction of time)
HORIZONTAL

SLIDER
11
518
275
551
p_other-disease
p_other-disease
0
1
0.01
0.01
1
(average prevalence)
HORIZONTAL

MONITOR
547
206
676
251
NIL
R0
5
1
11

MONITOR
547
60
676
105
NIL
setup-population
0
1
11

MONITOR
547
109
676
154
NIL
current-population
0
1
11

MONITOR
548
544
677
589
app-users
app-users
17
1
11

PLOT
281
437
543
587
% tested, isolated, app users
time step
%
0.0
25.0
0.0
100.0
true
true
"" ""
PENS
"apps" 1.0 0 -16777216 true "" "plot 100 * app-users / (current-population + 1)"
"tests" 1.0 0 -11221820 true "" "plot 100 * tests / (current-population + 1)"
"isolated" 1.0 0 -2674135 true "" "plot 100 * isolated / (current-population + 1)"

MONITOR
547
158
676
203
NIL
average-contacts
1
1
11

PLOT
281
281
543
431
virus states
time
%
0.0
25.0
0.0
1.0
true
true
"" ""
PENS
"infected" 1.0 0 -16777216 true "" "plot percent-infected"
"sympto." 1.0 0 -955883 true "" "plot percent-symptomatic"
"immune" 1.0 0 -10899396 true "" "plot percent-immune"

MONITOR
548
446
677
491
NIL
tests
0
1
11

MONITOR
547
253
676
298
percent-infected
percent-infected
3
1
11

MONITOR
548
300
677
345
NIL
percent-symptomatic
3
1
11

MONITOR
548
349
677
394
NIL
percent-immune
3
1
11

MONITOR
548
397
677
442
NIL
isolated
0
1
11

MONITOR
548
495
677
540
NIL
positive-tests
0
1
11

SWITCH
279
51
542
84
lockdown
lockdown
1
1
-1000

SWITCH
278
204
543
237
app
app
1
1
-1000

SLIDER
279
87
542
120
time-step-lockdown
time-step-lockdown
0
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
279
123
542
156
time-step-lockdown-release
time-step-lockdown-release
0
25
9.0
1
1
NIL
HORIZONTAL

SLIDER
279
159
542
192
lockdown-release-steps
lockdown-release-steps
0
4
0.0
1
1
NIL
HORIZONTAL

SLIDER
278
240
543
273
time-step-app-launch
time-step-app-launch
0
25
8.0
1
1
NIL
HORIZONTAL

MONITOR
11
592
133
637
NIL
peak-symptomatic-1
1
1
11

MONITOR
370
592
495
637
NIL
peak-symptomatic-2
1
1
11

MONITOR
136
592
215
637
NIL
peak-time-1
17
1
11

MONITOR
217
592
325
637
NIL
peak-isolated-1
1
1
11

MONITOR
579
592
677
637
NIL
peak-isolated-2
1
1
11

MONITOR
497
592
576
637
NIL
peak-time-2
17
1
11

@#$#@#$#@
## WHAT IS IT?

This section could give a general understanding of what the model is trying to show or explain.

## HOW IT WORKS

This section could explain what rules the agents use to create the overall behavior of the model.

## HOW TO USE IT

This section could explain how to use the model, including a description of each of the items in the interface tab.

## THINGS TO NOTICE

This section could give some ideas of things for the user to notice while running the model.

## THINGS TO TRY

This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.

## EXTENDING THE MODEL

This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.

## NETLOGO FEATURES

This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.

## RELATED MODELS

This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.

## CREDITS AND REFERENCES

This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
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

farm
false
0
Rectangle -7500403 true true 30 105 90 255
Circle -7500403 true true 30 75 58
Polygon -7500403 true true 120 150 180 105 255 150 255 255 120 255
Rectangle -16777216 true false 150 180 225 255

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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="basic scenario" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>peak-time-1</metric>
    <metric>peak-time-2</metric>
    <metric>peak-symptomatic-1</metric>
    <metric>peak-symptomatic-2</metric>
    <metric>peak-isolated-1</metric>
    <metric>peak-isolated-2</metric>
    <enumeratedValueSet variable="lockdown">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_external-inf">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown-release-steps">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_adoption">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_mortality">
      <value value="0.0035"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation-time">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-step-lockdown-release">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_i-per-encounter">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="17000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_symptomatic">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_other-disease">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_backslide">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_asymptomatic">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-infections">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-encounters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_recovery">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_quit">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_failure">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-step-lockdown">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-step-app-launch">
      <value value="8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="basic scenario with app" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>peak-time-1</metric>
    <metric>peak-time-2</metric>
    <metric>peak-symptomatic-1</metric>
    <metric>peak-symptomatic-2</metric>
    <metric>peak-isolated-1</metric>
    <metric>peak-isolated-2</metric>
    <enumeratedValueSet variable="lockdown">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_external-inf">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown-release-steps">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_adoption">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_mortality">
      <value value="0.0035"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation-time">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-step-lockdown-release">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_i-per-encounter">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="17000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_symptomatic">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_other-disease">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_backslide">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_asymptomatic">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-infections">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-encounters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_recovery">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_quit">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_failure">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-step-lockdown">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-step-app-launch">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="lockdown scenario" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>peak-time-1</metric>
    <metric>peak-time-2</metric>
    <metric>peak-symptomatic-1</metric>
    <metric>peak-symptomatic-2</metric>
    <metric>peak-isolated-1</metric>
    <metric>peak-isolated-2</metric>
    <enumeratedValueSet variable="lockdown">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_external-inf">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown-release-steps">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_adoption">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_mortality">
      <value value="0.0035"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation-time">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-step-lockdown-release">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_i-per-encounter">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="17000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_symptomatic">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_other-disease">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_backslide">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_asymptomatic">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-infections">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-encounters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_recovery">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_quit">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_failure">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-step-lockdown">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-step-app-launch">
      <value value="8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="stepwise release scenario" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>peak-time-1</metric>
    <metric>peak-time-2</metric>
    <metric>peak-symptomatic-1</metric>
    <metric>peak-symptomatic-2</metric>
    <metric>peak-isolated-1</metric>
    <metric>peak-isolated-2</metric>
    <enumeratedValueSet variable="lockdown">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_external-inf">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown-release-steps">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_adoption">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_mortality">
      <value value="0.0035"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation-time">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-step-lockdown-release">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_i-per-encounter">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="17000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_symptomatic">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_other-disease">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_backslide">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_asymptomatic">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-infections">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-encounters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_recovery">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_quit">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_failure">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-step-lockdown">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-step-app-launch">
      <value value="8"/>
    </enumeratedValueSet>
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
0
@#$#@#$#@

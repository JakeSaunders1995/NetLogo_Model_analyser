extensions [ rnd ]

turtles-own[
  state
  chosen?
  exposed-age

]

globals[
  ;H
  max-infected
]


to setup
  random-seed randomseed
  clear-all
  reset-ticks
  crt num-agents [
    set shape "person"
    set color white
    set state "s"
    set chosen? false
    set exposed-age 0
  ]

  ask n-of (num-agents * initial-percent-i) turtles [
    set state "i"
    set color red
  ]

  ask n-of (num-agents * intial-percent-f) turtles [
    set state "f"
    set color yellow
  ]
  ask turtles[
    setxy random-pxcor random-pycor
  ]
  set max-infected 0
end




to go

  if ((count turtles with [(state = "i") or (state = "if") or (state = "qif") ]) > max-infected) [
    set max-infected count turtles with [(state = "i") or (state = "if") or (state = "qif") ]
  ]
  if (ticks < 15) [set H 0.05]
  ;if (ticks = 15) [set H 0.2]
  if (ticks = 16) [set H 0.35]
  ;if (ticks = 17) [set H 0.5]
  ;if (ticks = 18) [set H 0.69]
  ;if (ticks = 19) [set H 0.80]
  if (ticks > 19) [set H 0.9]
  ;let a 50
  ;let b 8
  ;if (((ticks / a) ^ b) <= 1) [set H ((ticks / a) ^ b)]
  ;if (((ticks / a) ^ b) > 1) [set H 1]
  ;if ticks < 18 [set H 0.2]
  ;if ticks >= 18 [set H 0.95]


  ;if (count turtles with [state = "s"] = 0) [ stop ]
  ask turtles [


    ;;Changing Exposed state to Infected state
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    if state = "e" [
      set exposed-age (exposed-age + 1)
      if exposed-age > exposed-period [ get-i ]
    ]

    if state = "ef" [
      set exposed-age (exposed-age + 1)
      if exposed-age > exposed-period [ get-if ]
    ]

    if state = "qef" [
      set exposed-age (exposed-age + 1)
      if exposed-age > exposed-period [ get-qif ]
    ]
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    ;;;Quarantine
    ;;;;;;;;;;;;;;;;;;;;;
    if state = "f" [
      let prob random-float 1
      if prob < landa-1 [
        get-qf
      ]
    ]


    ;;;put agent to quarantine if agent is pf
    if state = "ef" [
      let prob random-float 1
      if prob < landa-2 [
        get-qef
      ]
    ]

    if state = "if" [
      let prob random-float 1
      if prob < landa-3 [
        get-qif
      ]
    ]
    ;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;





    ;;;ENDING the Quarantine
    ;;;;;;;;;;;;;;;;;;;;;;;;;;
    if state = "qf" [
      let prob random-float 1
      if prob < H [
        get-s
      ]
    ]

    if state = "qif"[
      let prob random-float 1
      if prob < H [
        get-i
      ]
    ]

    if state = "qef"[
      let prob random-float 1
      if prob < H [
        get-e
      ]
    ]
    ;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;






    ;;;Recovery
    ;;;;;;;;;;;;;;;;;;;;;;;;;;
    if (state = "i") or (state = "if") or (state = "qif") [
      let prob random-float 1
      if prob < landa-4 [
        get-recovered
      ]
    ]
    ;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;


    ;agents don't move if they are quarantined
    if (state != "qif") and (state != "qf") [
      find-new-spot
    ]

    set chosen? true
    let my-neighbor one-of turtles-on neighbors

    ;checking if neighbor is not empty
    if my-neighbor != nobody [

      ask my-neighbor [set chosen? true]

      if ((state = "s") and ([state] of my-neighbor = "e")) or ((state = "e") and ([state] of my-neighbor = "s"))[

      ;make an agentset with chosen = true
      let agentpair turtles with [chosen? = true]
        let agent-s agentpair with [state = "s"]
        let agent-e agentpair with [state = "e"]
      let items [ 1 ]
      let weights (list (beta))
      let pairs (map list items weights)
      let choice first rnd:weighted-one-of-list pairs [ [p] -> last p ]


        if choice = 1 [
        ask agent-s [get-e]
        ask agent-e [get-e]
        ]
    ]


    if ((state = "s") and ([state] of my-neighbor = "ef")) or ((state = "ef") and ([state] of my-neighbor = "s"))[

      ;make an agentset with chosen = true
      let agentpair turtles with [chosen? = true]
        let agent-s agentpair with [state = "s"]
        let agent-ef agentpair with [state = "ef"]
      let items [ 1 2 3 4 ]
      let weights (list ((1 - alpha) * (1 - beta)) (alpha * (1 - beta)) ((1 - alpha) * beta) (alpha * beta))
      let pairs (map list items weights)
      let choice first rnd:weighted-one-of-list pairs [ [p] -> last p ]


        if choice = 1 [
        ask agent-s [get-s]
        ask agent-ef [get-ef]
        ]
        if choice = 2 [
        ask agent-s [get-f]
        ask agent-ef [get-ef]
        ]
        if choice = 3 [
          ask agent-s [get-e]
          ask agent-ef [get-ef]
        ]
        if choice = 4 [
          ask agent-s [get-ef]
        ]
    ]

    if ((state = "s") and ([state] of my-neighbor = "f")) or ((state = "f") and ([state] of my-neighbor = "s"))[

      ;make an agentset with chosen = true
      let agentpair turtles with [chosen? = true]
        let agent-s agentpair with [state = "s"]
        let agent-f agentpair with [state = "f"]
      let items [ 1 ]
      let weights (list (alpha))
      let pairs (map list items weights)
      let choice first rnd:weighted-one-of-list pairs [ [p] -> last p ]


        if choice = 1 [
        ask agent-s [get-f]
        ask agent-f [get-f]
        ]
    ]

    if ((state = "s") and ([state] of my-neighbor = "i")) or ((state = "i") and ([state] of my-neighbor = "s"))[

      ;make an agentset with chosen = true
      let agentpair turtles with [chosen? = true]
        let agent-s agentpair with [state = "s"]
        let agent-i agentpair with [state = "i"]
      let items [ 1 2 3 4 ]
      let weights (list ((1 - alpha) * (1 - beta)) (beta * (1 - alpha)) (alpha * beta) (alpha *(1 - beta)))
      let pairs (map list items weights)
      let choice first rnd:weighted-one-of-list pairs [ [p] -> last p ]


        if choice = 1 [
        ask agent-s [get-s]
        ask agent-i [get-i]
        ]
        if choice = 2 [
        ask agent-s [get-e]
        ask agent-i [get-i]
        ]
        if choice = 3 [
          ask agent-s [get-ef]
          ask agent-i [get-i]
        ]
        if choice = 4 [
          ask agent-s [get-f]
          ask agent-i [get-i]
        ]
    ]


    if ((state = "s") and ([state] of my-neighbor = "if")) or ((state = "if") and ([state] of my-neighbor = "s"))[

      ;make an agentset with chosen = true
      let agentpair turtles with [chosen? = true]
        let agent-s agentpair with [state = "s"]
        let agent-if agentpair with [state = "if"]
      let items [ 1 2 3 4 ]
      let weights (list ((1 - alpha) * (1 - beta)) (beta * (1 - alpha)) ((1 - beta) * alpha) (alpha * beta))
      let pairs (map list items weights)
      let choice first rnd:weighted-one-of-list pairs [ [p] -> last p ]


        if choice = 1 [
        ask agent-s [get-s]
        ask agent-if [get-if]
        ]
        if choice = 2 [
        ask agent-s [get-e]
        ask agent-if [get-if]
        ]
        if choice = 3 [
          ask agent-s [get-f]
          ask agent-if [get-if]
        ]
        if choice = 4 [
          ask agent-s [get-ef]
          ask agent-if [get-if]
        ]
    ]

    if ((state = "e") and ([state] of my-neighbor = "ef")) or ((state = "ef") and ([state] of my-neighbor = "e"))[

      ;make an agentset with chosen = true
      let agentpair turtles with [chosen? = true]
        let agent-e agentpair with [state = "e"]
        let agent-ef agentpair with [state = "ef"]
      let items [ 1 ]
      let weights (list (alpha))
      let pairs (map list items weights)
      let choice first rnd:weighted-one-of-list pairs [ [p] -> last p ]


        if choice = 1 [
        ask agent-e [get-ef]
        ask agent-ef [get-ef]
        ]
    ]

    if ((state = "e") and ([state] of my-neighbor = "f")) or ((state = "f") and ([state] of my-neighbor = "e"))[

      ;make an agentset with chosen = true
      let agentpair turtles with [chosen? = true]
        let agent-e agentpair with [state = "e"]
        let agent-f agentpair with [state = "f"]
      let items [ 1 2 3 4 ]
      let weights (list ((1 - alpha) * (1 - beta)) (alpha * (1 - beta)) ((1 - alpha) * beta) (alpha * beta))
      let pairs (map list items weights)
      let choice first rnd:weighted-one-of-list pairs [ [p] -> last p ]


        if choice = 1 [
        ask agent-e [get-e]
        ask agent-f [get-f]
        ]
        if choice = 2 [
        ask agent-e [get-ef]
        ask agent-f [get-f]
        ]
        if choice = 3 [
          ask agent-e [get-e]
          ask agent-f [get-ef]
        ]
        if choice = 4 [
          ask agent-e [get-ef]
          ask agent-f [get-ef]
        ]
    ]


    if ((state = "e") and ([state] of my-neighbor = "if")) or ((state = "if") and ([state] of my-neighbor = "e"))[

      ;make an agentset with chosen = true
      let agentpair turtles with [chosen? = true]
        let agent-e agentpair with [state = "e"]
        let agent-if agentpair with [state = "if"]
      let items [ 1 ]
      let weights (list (alpha))
      let pairs (map list items weights)
      let choice first rnd:weighted-one-of-list pairs [ [p] -> last p ]


        if choice = 1 [
        ask agent-e [get-ef]
        ask agent-if [get-if]
        ]
    ]

    if ((state = "ef") and ([state] of my-neighbor = "f")) or ((state = "f") and ([state] of my-neighbor = "ef"))[

      ;make an agentset with chosen = true
      let agentpair turtles with [chosen? = true]
        let agent-ef agentpair with [state = "ef"]
        let agent-f agentpair with [state = "f"]
      let items [ 1 ]
      let weights (list (beta))
      let pairs (map list items weights)
      let choice first rnd:weighted-one-of-list pairs [ [p] -> last p ]


        if choice = 1 [
        ask agent-ef [get-ef]
        ask agent-f [get-ef]
        ]
    ]

    if ((state = "ef") and ([state] of my-neighbor = "i")) or ((state = "i") and ([state] of my-neighbor = "ef"))[

      ;make an agentset with chosen = true
      let agentpair turtles with [chosen? = true]
        let agent-ef agentpair with [state = "ef"]
        let agent-i agentpair with [state = "i"]
      let items [ 1 ]
      let weights (list (alpha))
      let pairs (map list items weights)
      let choice first rnd:weighted-one-of-list pairs [ [p] -> last p ]


        if choice = 1 [
        ask agent-ef [get-ef]
        ask agent-i [get-if]
        ]
    ]

    if ((state = "f") and ([state] of my-neighbor = "i")) or ((state = "i") and ([state] of my-neighbor = "f"))[

      ;make an agentset with chosen = true
      let agentpair turtles with [chosen? = true]
        let agent-i agentpair with [state = "i"]
        let agent-f agentpair with [state = "f"]
      let items [ 1 2 3 4 ]
      let weights (list ((1 - alpha) * (1 - beta)) (beta * (1 - alpha)) ((1 - beta) * alpha) (alpha * beta))
      let pairs (map list items weights)
      let choice first rnd:weighted-one-of-list pairs [ [p] -> last p ]


        if choice = 1 [
        ask agent-f [get-f]
        ask agent-i [get-i]
        ]
        if choice = 2 [
        ask agent-f [get-ef]
        ask agent-i [get-i]
        ]
        if choice = 3 [
          ask agent-f [get-f]
          ask agent-i [get-if]
        ]
        if choice = 4 [
          ask agent-f [get-ef]
          ask agent-i [get-if]
        ]
    ]

    if ((state = "f") and ([state] of my-neighbor = "if")) or ((state = "if") and ([state] of my-neighbor = "f"))[

      ;make an agentset with chosen = true
      let agentpair turtles with [chosen? = true]
        let agent-f agentpair with [state = "f"]
        let agent-if agentpair with [state = "if"]
      let items [ 1 ]
      let weights (list (beta))
      let pairs (map list items weights)
      let choice first rnd:weighted-one-of-list pairs [ [p] -> last p ]


        if choice = 1 [
        ask agent-f [get-ef]
        ask agent-if [get-if]
        ]
    ]

    if ((state = "i") and ([state] of my-neighbor = "if")) or ((state = "if") and ([state] of my-neighbor = "i"))[

      ;make an agentset with chosen = true
      let agentpair turtles with [chosen? = true]
        let agent-if agentpair with [state = "if"]
        let agent-i agentpair with [state = "i"]
      let items [ 1 ]
      let weights (list (alpha))
      let pairs (map list items weights)
      let choice first rnd:weighted-one-of-list pairs [ [p] -> last p ]


        if choice = 1 [
        ask agent-i [get-if]
        ask agent-if [get-if]
        ]
    ]




   ask my-neighbor [set chosen? false] ]

  set chosen? false]
  tick
end




to-report susceptibles
  report count turtles with [(state = "f") or (state = "s")]
end

to-report infecteds
  report count turtles with [(state = "i") or (state = "if") or (state = "qif")]
end

to-report quarantineds
  report count turtles with [(state = "qf") or (state = "qif") or (state = "qef")]
end




to move
  ask turtles [
    find-new-spot
  ]
end


to find-new-spot
  setxy random-pxcor random-pycor
  if any? other turtles-here [ find-new-spot ]

end

to get-s
  set state "s"
  set color white
  set exposed-age 0
end

to get-e
  set state "e"
  set color orange
end

to get-ef
  set state "ef"
  set color orange
end

to get-i
  set state "i"
  set color red
  set exposed-age 0
end

to get-f
  set state "f"
  set color yellow
  set exposed-age 0
end

to get-if
  set state "if"
  set color red
  set exposed-age 0
end


to get-qf
  set state "qf"
  set color blue
  set exposed-age 0
end

to get-qef
  set state "qef"
  set color blue
end

to get-qif
  set state "qif"
  set color blue
  set exposed-age 0
end

to get-recovered
  set state "recovered"
  set color gray
  set exposed-age 0
end
@#$#@#$#@
GRAPHICS-WINDOW
280
20
907
648
-1
-1
7.654321
1
10
1
1
1
0
1
1
1
-40
40
-40
40
1
1
1
ticks
30.0

BUTTON
55
235
125
270
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
50
35
222
68
num-agents
num-agents
0
10000
1000.0
1
1
NIL
HORIZONTAL

SLIDER
50
105
232
138
initial-percent-i
initial-percent-i
0
1
0.011
0.001
1
NIL
HORIZONTAL

SLIDER
55
175
227
208
intial-percent-f
intial-percent-f
0
1
0.0
0.001
1
NIL
HORIZONTAL

SLIDER
60
350
232
383
alpha
alpha
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
60
390
232
423
beta
beta
0
1
0.2
0.01
1
NIL
HORIZONTAL

BUTTON
165
235
228
268
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

PLOT
1275
365
1800
715
plot 1
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"infected" 1.0 0 -2674135 true "" "plot count turtles with [(state = \"i\") or (state = \"if\") or (state = \"qif\") or (state = \"e\") or (state = \"qef\") or (state = \"ef\")]"
"Susceptibels" 1.0 0 -13345367 true "" "plot count turtles with [(state = \"f\") or (state = \"s\")]"
"self-quarantined" 1.0 0 -16383231 true "" "plot count turtles with [(state = \"qef\") or (state = \"qif\") or (state = \"qf\")]"
"Exsposed and Free" 1.0 0 -7500403 true "" "plot count turtles with [(state = \"e\") or (state = \"ef\")]"
"IIs" 1.0 0 -955883 true "" "plot count turtles with [(state = \"i\") or (state = \"if\") or (state = \"qif\")]"
"Recovered" 1.0 0 -6459832 true "" "plot count turtles with [(state = \"recovered\")]"

SLIDER
65
540
237
573
landa-1
landa-1
0
1
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
65
585
237
618
landa-2
landa-2
0
1
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
65
630
237
663
landa-3
landa-3
0
1
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
65
765
237
798
H
H
0
1
0.9
0.01
1
NIL
HORIZONTAL

BUTTON
165
285
230
318
go-once
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

PLOT
1345
60
1750
220
plot 2
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"infected / quarantined" 1.0 0 -16777216 true "" "plot ((count turtles with [(state = \"i\") or (state = \"if\") or (state = \"qif\") or (state = \"e\") or (state = \"qef\") or (state = \"ef\") ]) / (count turtles with [(state = \"qef\") or (state = \"qif\") or (state = \"qf\")] + 1))"

SLIDER
65
685
237
718
landa-4
landa-4
0
1
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
60
435
232
468
exposed-period
exposed-period
0
15
5.0
1
1
NIL
HORIZONTAL

PLOT
1285
215
1485
365
H
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"H" 1.0 0 -16777216 true "" "plot H"

SLIDER
1265
10
1457
43
randomseed
randomseed
0
10000000
54.0
1
1
NIL
HORIZONTAL

PLOT
790
360
1255
730
plot 3
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"recovered" 1.0 0 -16777216 true "" "plot count turtles with [(state = \"recovered\")]"
"susceptible" 1.0 0 -14730904 true "" "plot count turtles with [(state = \"s\")]"

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
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>susceptibles</metric>
    <metric>quarantineds</metric>
    <metric>infecteds</metric>
    <enumeratedValueSet variable="landa-2">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-percent-i">
      <value value="0.002"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intial-percent-f">
      <value value="0.004"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landa-3">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="5000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exposed-period">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landa-4">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landa-1">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomseed">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Normal-max-infected" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>max-infected</metric>
    <enumeratedValueSet variable="landa-2">
      <value value="0.23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-percent-i">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intial-percent-f">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landa-3">
      <value value="0.42"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="H">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exposed-period">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landa-4">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landa-1">
      <value value="0.25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="No-Zoning" repetitions="200" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>max-infected</metric>
    <enumeratedValueSet variable="landa-2">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-percent-i">
      <value value="0.002"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landa-3">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intial-percent-f">
      <value value="0.004"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="5000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="H">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exposed-period">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landa-4">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landa-1">
      <value value="0.2"/>
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
1
@#$#@#$#@

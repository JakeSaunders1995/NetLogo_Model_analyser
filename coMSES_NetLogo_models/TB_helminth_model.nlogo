turtles-own
[ 
  epistate            ;; epidemiological state (0 = dead, 1 = susceptible, 2.1 = latent stage 1 (primary progression), 2.2 = latent stage 2 (endogenous reactivation), 2.3 = latent stage 3 (exogenous reinfection), 3 = infected, 4 = recovered)
  epistate-year       ;; current year in current epistate stage.  used for tracking length of time in latent state (within first 5 years for primary progression)
  lastmonth-epistate   ;; epistate of agent of last year
  link-count          ;; number of links possed by agent; used for reincarnation process to ensure network average degree is maintained when agent is reborn with new network connections
  helminthes-load     ;; level of helminthes
  IHBB                ;; agent's Individual Health-Beneficial Behavior (compliance level)
  count-as-new-case?  ;; flag for identifying actual new cases (for R0); self-recovery could cause an agent be counted multiple times as a new case
]

globals 
[ 
  count-cases         ;; counter for number of new disease cases (Infectious)
  movavgcases
  movavgS
  movavgL1
  movavgL2
  movavgL3
  movavgI
  movavgR
  
  p-primaryprogression
  p-endoreactivation
  p-naturaldeath
  p-tbdeath
  p-birth
  p-selfrecovery
  p-relapse
  
  epimax
]

to setup
  clear-all
  setup-nodes
  setup-spatially-clustered-network
  
  ; calculate the monthly probabilities based on the annual numbers
  set p-primaryprogression ((1 + p-primaryprogressiony) ^ (1 / 12)) - 1
  set p-endoreactivation ((1 + p-endoreactivationy) ^ (1 / 12)) - 1
  set p-naturaldeath ((1 + p-naturaldeathy) ^ (1 / 12)) - 1
  set p-tbdeath ((1 + p-tbdeathy) ^ (1 / 12)) - 1
  set p-birth ((1 + p-birthy) ^ (1 / 12)) - 1
  set p-selfrecovery ((1 + p-selfrecoveryy) ^ (1 / 12)) - 1
  set p-relapse ((1 + p-relapsey) ^ (1 / 12)) - 1
  set epimax 60 ; 60 months is 5 years

  file-open "output.txt"
  tick 
end     
  

to go
  while [ticks <= 2400]
  [
    if ticks = 1 [
      set count-cases 0  
      set movavgcases 0  set movavgS 0  set movavgL1 0  set movavgL2 0  set movavgL3 0  set movavgI 0  set movavgR 0
      reset-nodes
  
      ask n-of initial-outbreak-size turtles [ 
        become-infected set count-as-new-case? false 
        set count-cases count-cases + 1]
      ask n-of 800 turtles with [epistate = 1] [ 
        become-latent1
        set epistate-year 1 + random 39]
      ask n-of 4150 turtles with [epistate = 1][
        become-latent2]
      ask n-of 1500 turtles with [epistate = 1][
        become-latent3
        set epistate-year 1 + random 39]
 
      update-plot
    ]
    if (ticks mod 12 = 0) [set count-cases 0]
  
    spread-virus
    update-plot
    tick
  ]
  if ticks = 2401 [
    file-open "output.txt"
    file-type ticks file-type ","
    file-type number-of-nodes file-type ","
    file-type average-node-degree file-type ","
    file-type D file-type ","
    file-type initial-outbreak-size file-type ","
    file-type collective-action file-type ","
    file-type individual-HBB file-type ","
    file-type p-infection file-type ","
    file-type collective-action file-type ","
    file-type p-accesstreatment file-type ","
    file-type count-cases file-type ","
    file-type movavgcases file-type ","
    file-type movavgS file-type ","
    file-type movavgL1 file-type ","
    file-type movavgL2 file-type ","
    file-type movavgL3 file-type ","
    file-type movavgI file-type ","
    file-print movavgR
    file-close-all   
  ]  
end

to setup-nodes
  set-default-shape turtles "circle"
  crt number-of-nodes
  [
    set size 0.01
    set epistate 0
    set epistate-year 0
    set link-count 0
    set helminthes-load 0
    set IHBB 0
    set count-as-new-case? true
    
    setxy random-xcor random-ycor

    set IHBB IHBBmax * individual-HBB
    set helminthes-load 1 - ( .6 * collective-action ) - ( .4 * individual-HBB ) 
    become-susceptible
  ]
end

to reset-nodes
  ask turtles
  [
    set epistate 1
    set epistate-year 0
    set link-count 0
    set helminthes-load 0
    set IHBB 0
    set count-as-new-case? true
    set IHBB IHBBmax * individual-HBB
    set helminthes-load 1 - ( .6 * collective-action ) - ( .4 * individual-HBB ) 
  ]
end

to setup-spatially-clustered-network
  let num-links (average-node-degree * number-of-nodes) / 2
  while [ count links < num-links ]
  [
    ask one-of turtles
    [
      ask other turtles with [not link-neighbor? myself]
      [
        if random-float 1 < ( average-node-degree / ( 2 * pi * D ^ 2 ) ) * e ^ ( -1 * number-of-nodes * (distance myself) ^ 2 / (2 * D ^ 2) ) 
        [
          create-link-with myself
        ]
      ]
    ]
  ]
  ask turtles
  [
    set link-count count my-links
  ]
  if not display-links? [ ask links [ hide-link ] ]
end
  


to become-susceptible  ;; turtle procedure
  set epistate 1
  set color green
end

to become-latent1      ;; enter base latent infection stage (potential primary progression)
  set epistate 2.1
  set epistate-year 1
  set color yellow
end

to become-latent2      ;; enter second latent infection stage (post-primary progression stage; potential endogenous reactivation)
  set epistate 2.2
end

to become-latent3      ;; enter third latent infection stage (reinfection period; similar to primary progression but with slight immunity)
  set epistate 2.3
  set epistate-year 1
end

to become-infected
  set epistate 3
  set color red
end

to become-recovered
  set epistate 4
 set color blue
end

to become-death
  set epistate 0
end

to birth
  ; the agent who is turned alive and succeptible will be linked with up to four neighbors around the original neighbors of the reincarnated agent
  let agent1 self
  let agent2 one-of link-neighbors
  let agent3 nobody
  let agent4 nobody
  if agent2 != nobody [
    set agent3 one-of turtles with [link-neighbor? agent2 and self != agent1]
    if agent3 != nobody [
      set agent4 one-of turtles with [link-neighbor? agent3 and self != agent1 and self != agent2]    
    ]
  ]
  ifelse agent2 != nobody [
    set epistate [epistate] of agent2          
    set epistate-year [epistate-year] of agent2     
    set lastmonth-epistate [lastmonth-epistate] of agent2  
    set helminthes-load [helminthes-load] of agent2    
    set IHBB [IHBB] of agent2               
    set count-as-new-case? [count-as-new-case?] of agent2
  ][
    set epistate 1     
    set epistate-year 0
    set lastmonth-epistate 0    
    set helminthes-load 1 - ( .6 * collective-action ) - ( .4 * individual-HBB ) 
    set IHBB IHBBmax * individual-HBB      
    set count-as-new-case? true
  ]
  ifelse agent2 != nobody and agent3 != nobody [
    ask agent2 [
      set epistate [epistate] of agent3         
      set epistate-year [epistate-year] of agent3     
      set lastmonth-epistate [lastmonth-epistate] of agent3  
      set helminthes-load [helminthes-load] of agent3    
      set IHBB [IHBB] of agent3               
      set count-as-new-case? [count-as-new-case?] of agent3
    ]
   ][
     if agent2 != nobody [
       ask agent2 [
         set epistate 1     
         set epistate-year 0
         set lastmonth-epistate 0    
         set helminthes-load 1 - ( .6 * collective-action ) - ( .4 * individual-HBB ) 
         set IHBB IHBBmax * individual-HBB      
         set count-as-new-case? true
       ]
    ]
  ]
  ifelse agent2 != nobody and agent3 != nobody and agent4 != nobody [
    ask agent3 [
      set epistate [epistate] of agent4         
      set epistate-year [epistate-year] of agent4     
      set lastmonth-epistate [lastmonth-epistate] of agent4  
      set helminthes-load [helminthes-load] of agent4    
      set IHBB [IHBB] of agent4               
      set count-as-new-case? [count-as-new-case?] of agent4
    ]
    ask agent4 [
      set epistate 1     
      set epistate-year 0
      set lastmonth-epistate 0    
      set helminthes-load 1 - ( .6 * collective-action ) - ( .4 * individual-HBB ) 
      set IHBB IHBBmax * individual-HBB      
      set count-as-new-case? true
    ]
   ] [
     if agent2 != nobody and agent3 != nobody [
       ask agent3 [
        set epistate 1     
        set epistate-year 0
        set lastmonth-epistate 0    
        set helminthes-load 1 - ( .6 * collective-action ) - ( .4 * individual-HBB ) 
        set IHBB IHBBmax * individual-HBB      
        set count-as-new-case? true
       ]
     ]
   ]
end

to spread-virus
  ask turtles [set lastmonth-epistate epistate] ; since spread depends on state of agents in previous month
  ask turtles 
  [
    ifelse epistate = 0
    [
      if random-float 1 < p-birth [birth]
    ][
      ifelse epistate = 1 
      [
        ifelse random-float 1 < p-naturaldeath
        [
          become-death
        ][
          let pinf (1 - ( 1 - ( p-infection * (1 - IHBB))) ^ (count link-neighbors with [lastmonth-epistate = 3 ]))
          if random-float 1 < pinf
          [
            become-latent1
          ]
        ] 
        ] [
        ifelse epistate = 2.1
        [
          ifelse random-float 1 < p-naturaldeath
          [
            become-death
          ][
            
            ifelse epistate-year <= epimax
            [
              if random-float 1 < ( p-primaryprogression * (1 - hmax * (1 - helminthes-load )))
              [                                              ;; primary progression to infection
                become-infected
                  if count-as-new-case?
                  [ set count-cases count-cases + 1 ]
              ]
              set epistate-year epistate-year + 1
            ]
            [                                                ;; exit primary progression stage
              become-latent2
            ]
        ]
      ] [
        ifelse epistate = 2.2
        [
          ifelse random-float 1 < p-naturaldeath
          [
            become-death
          ][
            ifelse random-float 1 < (p-endoreactivation * (1 - hmax * (1 - helminthes-load ))) 
            [                                                ;; endogenous reactivation to infection
              become-infected
              if count-as-new-case?
              [ set count-cases count-cases + 1 ]
            ]
            [  
              let pinf 0
              set pinf (1 - ( 1 - ( p-infection * (1 - IHBB))) ^ (count link-neighbors with [lastmonth-epistate = 3 ]))
              if random-float 1 < pinf
              [
                become-latent3
              ]
              set epistate-year epistate-year + 1
            ]
          ]
        ] [
          ifelse epistate = 2.3
          [
            ifelse random-float 1 < p-naturaldeath
            [
              become-death
            ][
              ifelse epistate-year <= epimax
              [
                if random-float 1 < (( 1 - partial-immunity ) * ( p-primaryprogression * (1 - hmax * (1 - helminthes-load ))))   ;; probability of progression to infection is reduced by partial immunity from preexisting reinfections
                [
                  become-infected
                  if count-as-new-case?
                  [ set count-cases count-cases + 1 ]
                ]
                set epistate-year epistate-year + 1
              ]
              [                                                ;; elevated infection rate expires; return to secondary latent stage
                become-latent2
              ]
            ]
          ][
            ifelse epistate = 3
            [
              ifelse random-float 1 < p-accesstreatment
              [
                let te 0
                set te treatment-efficacy
                ifelse random-float 1 < te [
                  ifelse random-float 1 < p-naturaldeath
                  [
                    become-death
                  ][
                    become-recovered]
                ][
                  ifelse random-float 1 < p-tbdeath * (1 - hmax * (1 - helminthes-load))
                  [
                    become-death
                  ][
                    if random-float 1 < (p-selfrecovery * (1 - hmax * (1 - helminthes-load)))           
                    [                                                          
                      become-latent2                                                               ;; when a self-recovered latent later becomes infectious again, they should probably not be counted again as a new case
                      set count-as-new-case? false                                                 ;; we don't want to count this agent again as a new case, should they reactivate into Infectiousness
                    ]
                  ]
                ]
              ] [  
                ifelse random-float 1 < p-tbdeath * (1 - hmax * (1 - helminthes-load))
                [
                  become-death
                ] [
                  if random-float 1 < (p-selfrecovery * (1 - hmax * (1 - helminthes-load))) 
                  [
                    become-latent2
                    set count-as-new-case? false                                                 ;; we don't want to count this agent again as a new case, should they reactivate into Infectiousness
                  ]
                ]
              ]
            ][
              ; epistate = 4
              ifelse random-float 1 < p-naturaldeath
              [
                become-death
              ][
                if random-float 1 < (p-relapse * (1 - hmax * (1 - helminthes-load)))
                [
                  become-infected
                  set count-as-new-case? false
                ]
              ]
            ]
          ]
        ]
      ]
    ]
    ]
  ]
end 

to update-plot
if gui-on? [
  set-current-plot "Network Status"
  set-current-plot-pen "susceptible"
  plot ( count turtles with [epistate = 1] / count turtles * 100 )
  set-current-plot-pen "latent"
  plot ( count turtles with [epistate > 1 AND epistate < 3] / count turtles * 100 )
  set-current-plot-pen "infected"
  plot ( count turtles with [epistate = 3] / count turtles * 100 )
  set-current-plot-pen "recovered"
  plot ( count turtles with [epistate = 4] / count turtles * 100 )
  
  set-current-plot "cases in 100000"  
   if ticks mod 12 = 11 [plot (count-cases * 100000 / ( count turtles with [epistate > 0]))]]
  
  if ticks > 1200 [
    if ticks mod 12 = 11 [set movavgcases movavgcases + (count-cases * 100000 / ( count turtles with [epistate > 0]))]
    set movavgS movavgS + count turtles with [epistate = 1]
    set movavgL1 movavgL1 + count turtles with [epistate = 2.1]
    set movavgL2 movavgL2 + count turtles with [epistate = 2.2]
    set movavgL3 movavgL3 + count turtles with [epistate = 2.3]
    set movavgI movavgI + count turtles with [epistate = 3]
    set movavgR movavgR + count turtles with [epistate = 4]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
400
10
710
341
0
0
300.0
1
10
1
1
1
0
0
0
1
0
0
0
0
1
1
1
ticks

BUTTON
8
10
82
50
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

BUTTON
85
10
160
50
go
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

PLOT
716
11
1068
290
Network Status
time
% of nodes
0.0
52.0
0.0
100.0
true
true
PENS
"susceptible" 1.0 0 -10899396 true
"latent" 1.0 0 -1184463 true
"Infected" 1.0 0 -2674135 true
"recovered" 1.0 0 -13345367 true

SLIDER
457
356
652
389
number-of-nodes
number-of-nodes
10
10000
10000
5
1
NIL
HORIZONTAL

SLIDER
457
426
652
459
initial-outbreak-size
initial-outbreak-size
1
200
50
1
1
NIL
HORIZONTAL

SLIDER
457
391
652
424
average-node-degree
average-node-degree
1
25
16
1
1
NIL
HORIZONTAL

SLIDER
457
461
652
494
D
D
1
10
2
1
1
NIL
HORIZONTAL

SLIDER
9
63
200
96
p-infection
p-infection
0
1
0.17
.01
1
NIL
HORIZONTAL

SLIDER
7
212
200
245
p-tbdeathy
p-tbdeathy
0
1
0.3
.01
1
NIL
HORIZONTAL

SLIDER
7
286
200
319
p-selfrecoveryy
p-selfrecoveryy
0
1
0.2
.1
1
NIL
HORIZONTAL

SLIDER
7
324
201
357
p-relapsey
p-relapsey
0
0.1
0.05
.01
1
NIL
HORIZONTAL

SLIDER
8
361
202
394
partial-immunity
partial-immunity
0
1
0.4
.01
1
NIL
HORIZONTAL

SLIDER
9
103
200
136
p-primaryprogressiony
p-primaryprogressiony
0
0.1
0.03
.01
1
NIL
HORIZONTAL

SLIDER
8
139
199
172
p-endoreactivationy
p-endoreactivationy
0
.001
2.7E-4
.00001
1
NIL
HORIZONTAL

SWITCH
259
10
387
43
display-links?
display-links?
1
1
-1000

SLIDER
8
175
200
208
p-naturaldeathy
p-naturaldeathy
0
.1
0.02
.01
1
NIL
HORIZONTAL

SLIDER
7
400
203
433
treatment-efficacy
treatment-efficacy
0
1
0.85
0.01
1
NIL
HORIZONTAL

SWITCH
260
81
387
114
file-output?
file-output?
1
1
-1000

PLOT
718
340
1062
556
cases in 100000
NIL
NIL
0.0
10.0
0.0
10.0
true
false
PENS
"default" 1.0 0 -16777216 true

SLIDER
214
272
391
305
hmax
hmax
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
213
236
390
269
IHBBmax
IHBBmax
0
1
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
8
249
200
282
p-birthy
p-birthy
0
1
0.2
0.1
1
NIL
HORIZONTAL

SLIDER
213
126
388
159
collective-action
collective-action
0
1
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
213
163
390
196
Individual-HBB
Individual-HBB
0
1
0
0.1
1
NIL
HORIZONTAL

SLIDER
213
199
390
232
p-accesstreatment
p-accesstreatment
0
1
0.2
0.1
1
NIL
HORIZONTAL

SWITCH
259
46
387
79
gui-on?
gui-on?
0
1
-1000

MONITOR
717
294
907
339
Infectious Agents
count turtles with [epistate = 3]
17
1
11

@#$#@#$#@
WHAT IS IT?
-----------
This is a model that is developed to investigate the consequences of helminthes in public health policy to eradicate tuberculosis. Helminthes surprise immune system responses and without changes in hygiene and sanitation, treatments for tuberculosis are less effective. The model is described in the following paper:

Janssen, M.A., A. Cherif, A.M. Hurtado, M. Hurtado and N. Rollins (2010) The effect of public health policy on tuberculosis epidemic: modelling helminthes loads and tuberculosis dynamics, submitted 

COPYRIGHT
--------------------
The model is developed by Marco A. Janssen, Alhaji Cherif, Magdalena Hurtado, Marcel Hurtado and Nathan Rollins, Arizona State University, July 2009.
Copyright (C) 2008 M.A. Janssen, A. Cherid, A.M. Hurtado, M. Hurtado and N. Rollins

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
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
NetLogo 4.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2400"/>
    <metric>movavgcases</metric>
    <metric>movavgS</metric>
    <metric>movavgL1</metric>
    <metric>movavgL2</metric>
    <metric>movavgL3</metric>
    <metric>movavgI</metric>
    <metric>movavgR</metric>
    <metric>nrcum</metric>
    <enumeratedValueSet variable="IHBBmax">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-endoreactivation">
      <value value="3.0E-4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="partial-immunity">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-relapse">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-links?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-accesstreatment">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="individual-HBB">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="D">
      <value value="2"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-infection">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gui-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nodes">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hmax">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-selfrecovery">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-tbdeath">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-birth">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-node-degree">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-primaryprogression">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-naturaldeath">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collective-action">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="treatment-efficacy">
      <value value="0.82"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-outbreak-size">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="output-filename">
      <value value="&quot;cluster1.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="file-output?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Annual">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Treatment" first="0" step="0.1" last="1"/>
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

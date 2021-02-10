extensions [  nw       ; includes the *nw* extesion (bundled in NetLogo) / uses several fonctions to compute statistics on generate networks
              stats ]  ; includes the *stats* extesion (not bundled in NetLogo) (to be downloaded here: https://github.com/cstaelin/Stats-Extension/releases)
                       ; use this extension to compute correlation coefficient (for degree assortativity and degree-clustering correlation) (see procedure "netStats" within *utilities* .nls file)

; To make code more readable, includes several .nls files where I write different section of the code ; each file can be opened by using the button "included file" in the *Code* tab just above
__includes ["1_SetUpPop.nls" "2_SetUpNet.nls" "3_Dynamic.nls" "4_Utilities.nls" "5_Replication.nls"]

;;;; Global variables;;;;

globals [
seed                 ; variable that I use when I replicate extensively to fix random-generator-seed from a list of seed (see *Replication* included file)
nb-infected          ; number of currently infected agents
nb-infected-iter-0   ; number of infected agent at the outset of the process
nb-recovered         ; number of currently recovered agents
infectiousness-length    ;  number of days during which an infected agent can transmit the disease
average-recovery-time    ; Average Time (in nb of ticks/iteration --> one iteration=one day) it takes before the person has a chance to recover from the infection
average-recovery-chance  ; Average probablity an agent in the I-state will recover
]

;;;; agents (nodes) attributes;;;;

turtles-own[
                   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; #####Empirical variables: Values are imported from 2012 COMES-F dataset################
                   ; NOTA BENE: on all the empirical variables variables, when, in the original dataset, no value was present (i.e. empty cell), I fill the case with 9999 (thus this is equivalent to "NA").
caseID             ; (my variable) Unique ID (from 1 to 2033) (col. 1 respondent_data file) that I created for respondent because, the variable numQ, in fact may have the same value for two cases when they were survey in the two survey waves
numQ_r	           ; ID respondent/agent (col. 2 respondent_data file) (data are imported but not used in the current model)
quest_r            ; type of quest. 1=adult 2=child (col. 3 respondent_data file) (data are imported but not used in the current model)
age  	             ; respondent's age (col. 4 respondent_data file) OR age of the respondent's contacts (estimated by the respondent or by the person who responded for the child) (data are imported but not used in the current model)
sex                ; respondent's sex (col. 5 respondent_data file) OR sex of the respondent's contacts (as reported by the respondent or the person who responded for the child) (data are imported but not used in the current model)
ZIP_r              ; ZIP code (col. 6 respondent_data file)	(data are imported but not used in the current model)
edu_r              ; edu	(col. 7 respondent_data file) (data are imported but not used in the current model)
occ_r              ; occupational status (col. 8 respondent_data file) 	(data are imported but not used in the current model)
sec_r              ; occupational sector (col. 9 respondent_data file) (data are imported but not used in the current model)
spc_r              ; nb contacts per day for those considering their job as expectionnally exposed to social contacts (col. 10 respondent_data file)
spc_age1           ; 0-3 years / estimated main age of contacts for those considering their job as expectionnally exposed to social contacts (col. 11 respondent_data file)
spc_age2           ; 3-10 years / same as above (col. 12 respondent_data file) (data are imported but not used in the current model)
spc_age3           ; 11-17 years / same as above (col. 13 respondent_data file) (data are imported but not used in the current model)
spc_age4           ; 18-64 years / same as above (col. 14 respondent_data file) (data are imported but not used in the current model)
spc_age5           ; 0>64 / same as above (col. 15 respondent_data file) (data are imported but not used in the current model)
ctot_r             ; total number of max-2-mt-distant contacts with verbal and/or physical skin touch self-reported by respondent over two consecutive days (col. 16 respondent_data file)
ctot_day1_r        ; total number of max-2-mt-distant contacts with verbal and/or physical skin touch self-reported by respondent during day 1 (col. 17 respondent_data file)
ctot_day2_r        ; total number of max-2-mt-distant contacts with verbal and/or physical skin touch self-reported by respondent during day 2 (col. 18 respondent_data file)
                   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; #####Virtual variables: variable that I create for the needs of the simulation################
source             ; to distinguish 1= individuals in the empirical dataset 2= target: a self-declared node by one of the source |only needed if all contact data are imported]
cavday             ; (procedure net-creation) average of the number of self-reported contacts on day1 and day2
cavday&SPC         ; (procedure net-creation) cavday (for respondent without SPC) and cavday + SPC (for those who declared SPC) (with poosible restriction on the fraction of SPC to take into account)
done               ; (procedure net-creation) 0= the agents has not reached yet the required degree ; 1= the agent has reached the required degree
h                  ; (*dynamic* part) (endogenous) agent's health state : 0=susceptible 1=infected 2=recovered
infection-length   ; (*dynamic* part) (endogenous)) how long (in nb of ticks/iteration --> one iteration=one day) a I-agent remains within the I-state
recovery-time      ; (*dynamic part) (exogenous) Time (in nb of ticks/iteration --> one iteration=one day) it takes before the person has a chance to recover from the infection
infection-chance   ; (*dynamic part) (exogenous) probablity an agent in the I-state will transmit the disease within a dyadic interaction
recovery-chance    ; (*dynamic part) (exogenous) probablity an agent in the I-state will recover
]

;;;; ties' attributes;;;;

links-own [
pl1                ; place where the contact occurs (private places like home) 1=yes 0=no       [Relevant only when data on nominated contacts are also imported, which is not the case in the current model] 	
pl2	               ; place where the contact occurs (school-related places) 1=yes 0=no          [Relevant only when data on nominated contacts are also imported, which is not the case in the current model]
pl3	               ; place where the contact occurs (closed workplaces) 1=yes 0=no              [Relevant only when data on nominated contacts are also imported, which is not the case in the current model]
pl4	               ; place where the contact occurs (closed-related persons in closed places) 1=yes 0=no   [Relevant only when data on nominated contacts are also imported, which is not the case in the current model]
pl5	               ; place where the contact occurs (other closed places like restaurants, shops, etc.) 1=yes 0=no [Relevant only when data on nominated contacts are also imported, which is not the case in the current model]
pl6	               ; place where the contact occurs (public transportations) 1=yes 0=no [Relevant only when data on nominated contacts are also imported, which is not the case in the current model]
pl7	               ; place where the contact occurs (open public places) 1=yes 0=no [Relevant only when data on nominated contacts are also imported, which is not the case in the current model]
freq               ; contact's frequence (1=almost every day; 2=some times a week; 3=some times a month; 4=sometimes per year or less 5=first time) [Relevant only when data on nominated contacts are also imported, which is not the case in the current model]
skin               ; presence of skin touch (1=yes; 2=non) [Relevant only when data on nominated contacts are also imported, which is not the case in the current model]
dur                ; duration of the contact (1=<5'; 2=5'-15'; 3=15'-60'; 4=60'-240'; 5=>240')                [Relevant only when data on nominated contacts are also imported, which is not the case in the current model]
tieType            ; (my own variable) 0=the link exists in the original datset 1=the link is created by us   [Relevant only when data on nominated contacts are also imported, which is not the case in the current model]
EgoDegree          ; (my own variable) number of links of tie's end1 (the turtle with the lowest who, between the two tied turtles) ; need this to compute degree assortativity
AlterDegree        ; (my own variable) number of links of tie's end2 (the turtle with the highest who, between the two tied turtles) ; need this to compute degree assortativity
]

to setup
; If I am not replicating extensively, I erase everything before a new initialization is launched
; Oterwise, when I am replicating extensively on the model, *ca*, *no-display* (turn off the world visualization, to speed up intialization) and *random-seeds* are done within the *exp* procedures
ifelse (replicate? = false) [no-display ca random-seed 2004049253] [random-seed seed] ;  and set the seed to fix all random elements within the setup procedure (like random-xcor, random-ycor, etc.)
;## Creation of the population based on the number of individuals on COMES-F, including all their relevant socio-demographic variables
if (replicate? = false) [reset-timer] ; *reset-timer*, allow to reset the time counter (real time in seconds)
PopulationCreation ; see *SetUpPoP* .nls file
if (replicate? = false)
[print "" type "Seconds needed to load COMES-F respondents' data=" type timer print ""]; I print time need to execute this procedure
;## Procedure to connect the 2033 (or 2029 when 4 case with 0 degree are eliminate) COMES-F respondents through a random network with the degree distribution given by number of contacts self-reported by each respondent
; NB: within COMES-F, "contact" means: interactions involving physical and/or kin touch at max-2-mt-distance
if (replicate? = false) [reset-timer] ; *reset-timer*, allow to reset the time counter (real time in seconds)
if (NetAlgorithm = "EmpNet") [EmpNet] ; Degree-calibrated network creation ; see *SetUpNet* .nls file
;;;;;;;Uncomment this line AND comment the line above when you want to use the network including both diary-based contacts and job-related extra contacts
; if (NetAlgorithm = "EmpNet") [EmpNet_1] ; Degree-calibrated network creation ; see *SetUpNet* .nls file
if (NetAlgorithm = "ErdosRenyi") [ER] ; ErdosRenyi network (with average empirical degree) creation ; see *SetUpNet* .nls file
if (replicate? = false) [do-plot]     ; plot degree distribution (see *utilities* .nls file)
if (replicate? = false)
[type "Seconds needed to perform NewLinkCreation=" type timer print ""] ; I print time need to execute this procedure
;; ## ; determines global variables (values of variables that can be read by any agent everywhere within the program) and agent-specific variable that are relevant to the diffusion model
Globals&Agent-specficDiffusionVariables ; see *SetUpPoP* .nls file
if (replicate? = false) [netStats display] ; for netStats, see *Utilities* .nls file //display-->turn on the world visualization
reset-ticks ; I reset at 0 the tick counter

end

to dynamic
; If I am not replicating extensively, set random-seed (same as setup)
; Oterwise, when I am replicating extensively on the model, *random-seeds* are done within the *exp* procedures (same as for setup)
ifelse (replicate? = false) [random-seed 2004049253] [random-seed seed] ;
infectionStart  ; Determine the number of initial infected agents
; (if I am not replicating extensively) collects agent-level data and data on the macroscopic dynamic of the epidemic at the outset iter=0 (day=0)
if (replicate? = false ) [Aggregates_start] ; see *Dynamic* .nls file
; Real model agent-level dynamic
; Stop the dynamic after 10 months (10*300Iter/days) (other stopping rules are possible)
; with current parameter this is enough to observe the end of the epidemic
 while [ticks < 300 ] [
; When interventions are in place, at the beginning of each iteration, I reset the number of H0- and H1-actions so that I get at every iteration only per-day actions
if (Intervention = "hub-target") [immunization] ; ( see *Dynamic* .nls file) determines which agents are tested/treated/isolated (in the model, put into R-state) --deterministic reverse degree-based order (1, 2,...,*cured* per iteration)
if (Intervention = "contact-target") [immunization_1] ; (see *Dynamic* .nls file) ; determines which agents are tested/treated/isolated (in the model, put into R-state) --random selection of *cured* agents and random selection of 1 of their neighbors
if (Intervention = "no-target") [immunization_2]; ( see *Dynamic* .nls file) determines which agents are tested/treated/isolated (in the model, put into R-state) --random selection of *cured* agents
I-to-S-transmission              ; (see *Dynamic* .nls file) determines how I-state agents transmits the disease
I-agent-infection-time-elapsing  ; (see *Dynamic* .nls file) determines how long I-state agents stay in the I-state
I-to-R-transition                ; (see *Dynamic* .nls file) determines how I-state agents recover (i.e. move to the R-state)
tick ; increase by one the tick counter (number of iteration)
ifelse (replicate? = false) [Aggregates]  ; (see *Dynamic* .nls file) If I am not replicating extensively, I collect (and output in command center) data on the macroscopic dynamic of the epidemic at the end of each iteration (day)
                            [fileprint ]  ; If I am replicating extensively, I print data into the file open before entering the while-loop (see procedure *file-print* below)
  ]

end

to fileprint

if (experiments = "exp2") [file-type Intervention file-type " " file-type NetAlgorithm file-type " " file-type average-infection-chance file-type " "]
if (experiments = "exp2a") [file-type Intervention file-type " " file-type plt file-type " " file-type average-infection-chance file-type " "]
if (experiments = "exp3") [file-type Intervention file-type " " file-type NetAlgorithm file-type " " file-type average-infection-chance file-type " " file-type cured file-type " "]
if (experiments = "exp4") [file-type Intervention file-type " " file-type plt          file-type " " file-type average-infection-chance file-type " " file-type cured file-type " "]
file-type seed file-type " "
file-type ticks file-type " "
file-type count turtles with [h = 0 ] file-type " "
file-type nb-infected file-type " "
file-type nb-recovered
file-print ""

end
@#$#@#$#@
GRAPHICS-WINDOW
1070
180
1481
592
-1
-1
2.86
1
10
1
1
1
0
0
0
1
-70
70
-70
70
0
0
1
ticks
30.0

BUTTON
358
264
421
299
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
426
265
488
298
NIL
dynamic
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
14
279
155
324
NetAlgorithm
NetAlgorithm
"EmpNet" "ErdosRenyi"
0

PLOT
356
310
700
612
Nodes' Degree
Neighbors
N# of Nodes
0.0
10.0
0.0
10.0
true
false
"" "stop"
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

PLOT
709
310
1053
615
Agents' Health States
days
N# of Agents in a given h-state
0.0
10.0
0.0
10.0
true
true
"if (replicate? = true) [stop]" "if (replicate? = true) [stop]"
PENS
"S" 1.0 0 -16777216 true "" "plot count turtles with [h = 0]"
"I" 1.0 0 -2674135 true "" "plot count turtles with [h = 1]"
"R" 1.0 0 -13345367 true "" "plot count turtles with [h = 2]"

CHOOSER
10
27
102
72
PopMultiple
PopMultiple
"1n" "2n" "5n" "10n"
0

SWITCH
354
160
463
193
replicate?
replicate?
1
1
-1000

BUTTON
583
161
690
194
NIL
ModelExperiment
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
469
160
577
205
experiments
experiments
"exp1" "exp2" "exp2a" "exp3" "exp4"
0

INPUTBOX
13
542
87
602
cured
1.0
1
0
Number

INPUTBOX
11
80
72
140
I-seeds
5.0
1
0
Number

INPUTBOX
12
144
69
204
average-infection-chance
0.05
1
0
Number

TEXTBOX
108
27
337
74
1. Choose the size of the agent population (1n=2033, empirical value used in the paper's analyses).
12
0.0
1

TEXTBOX
82
87
278
137
2. Choose the number of intial infected agents (5 --value used in paper's analyses).
12
0.0
1

TEXTBOX
78
139
283
229
3. Choose the value of the average of the dyadic transmission probability distribution (0.03/0.05/0.07 are the values used in the paper's analyses --the name of this parameter in the paper is \"r\"). 
11
0.0
1

TEXTBOX
16
212
213
272
4. Choose the type of network (the two networks are systematically confronted in the paper's analyses).
12
0.0
1

TEXTBOX
14
410
335
470
5. If you want to intervene during the epidemic dynamic, please choose the \"hub-target\", the \"contact-target\" or\nthe \"no-target\" methods (see description in paper's section 3.3).
12
0.0
1

TEXTBOX
93
540
316
620
6. If one of the three interventions is selected, please choose the number of agent to be \"immunized\" at each iteration (1, 3, 5 and 10 are the values studied in the paper's analyses). 
12
0.0
1

TEXTBOX
357
106
717
152
7. To replicate the model 100 times, please turn *replicate* \"ON\", and choose the \"experiments\" (see description in the \"replication\" file). Then push the *ModelExperiment* button.  
12
0.0
1

TEXTBOX
359
212
699
257
8. If *replicate* is *off\", then use the *setup* button to initialize the model, and use the *dynamic* button to trigger one epidemic.
12
0.0
1

TEXTBOX
336
14
1174
102
################################################################\n# In order to use and study the model, please first read the paper and, then, go through steps 1 to 8  #\n################################################################ 
18
15.0
1

INPUTBOX
15
333
65
393
plt
0.0
1
0
Number

TEXTBOX
70
330
298
402
4a. If \"EmNet\" is active, choose the probability of creating local ties among a given agents' neighbors (0=no clustering/ 0.5, and 1 are the values used in the paper's analyses --the name of this parameter in the paper is \"p\").
11
0.0
1

CHOOSER
12
477
150
522
Intervention
Intervention
"no-intervention" "hub-target" "contact-target" "no-target"
0

@#$#@#$#@
## WHAT IS IT?

The model is intended to show how a virus with empirical features mimicking the COVID-19 spreads on a network of close-range contacts with an empirically observed broad degree distribution in absence/presence of interventions targeting high-degree nodes for immunization. 

## HOW IT WORKS

Before using and studying the model, it is necessary carefully to read the submitted paper .

## HOW TO USE IT

Please follow steps 1 to 8 in the interface.


## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

The following models within the NetLogo models library may be of interest:

epiDEM Basic
epiDEM Travel and Control
Virus on a Network

## CREDITS AND REFERENCES

The code was authored by anonymized. To be completed at the end of the review process.
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
NetLogo 6.0.4
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

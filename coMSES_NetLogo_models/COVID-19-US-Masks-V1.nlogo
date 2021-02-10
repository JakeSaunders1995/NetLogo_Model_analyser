;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Title:     COVID-19 US Masks
;; Author:    Dale K. Brearcliffe
;; Email:     dbrearcl@gmu.edu
;; Version:   1
;; Date:      9 August 2020
;; Copyright: 2020 Dale K. Brearcliffe
;; This work is licensed under a Creative Commons
;; Attribution-NonCommercial-ShareAlike 3.0 License.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

turtles-own [
  age                ;;Agent age based on census distribution
  susceptible?       ;;Agent susceptible status {True, False}
  exposed?           ;;Agent exposed status {True, False}
  infected?          ;;Agent infected status {True, False}
  recovered?         ;;Agent recovered status {True, False}
  time-to-recover    ;;The number of ticks before an infected (symptomatic) agent recovers
  time-to-sick       ;;The number of ticks before an exposed (asymptomatic) agent becoms infected
                     ;;(symptomatic)
  sick-time          ;;The initial value for time-to-recover
  mask-type          ;;One of four types [0,3] {"None", "Homemade", "Medical", "N95"}
  mask-name-ingress  ;;The study author and mask data used to protect wearer
  mask-name-egress   ;;The study author and mask data used to protect from wearer
  mask-ingress       ;;The efficacy percent in protecting the wearer
  mask-egress        ;;The efficacy percent in protecting from the wearer
]

globals [
  population           ;;Number of agents where one agent represents 100,000 people
  age-distro           ;;The cumulative percent of population from age zero to one hundred
  age-fatality         ;;The probability of dying if infected for each of ten year age groups from
                       ;;zero to one hundred
  illness-period       ;;The minimum and maximum days an agent can be infected based on user input
  exposed-period       ;;The minimum and maximum days an agent can be exposed mased on user input
  deaths               ;;Cumulative number of deaths
  max-exposed-infected ;;Maximum number of exposed plus infected agents during a simulation
  max-affected         ;;Maximum number of exposed plus infected plus recovered agents during a
                       ;;simulation
  max-tick             ;;The tick when the maximum number of exposed plus infected agents took place
  n95-ingress          ;;A list of N95 ingress masks with each having the name, mean, and standard
                       ;;deviation
  n95-egress           ;;A list of N95 egress masks with each having the name, mean, and standard
                       ;;deviation
  medical-ingress      ;;A list of Medical ingress masks with each having the name, mean, and standard
                       ;;deviation
  medical-egress       ;;A list of Medical egress masks with each having the name, mean, and standard
                       ;;deviation
  homemade-ingress     ;;A list of Homemade ingress masks with each having the name, mean, and
                       ;;standard deviation
  homemade-egress      ;;A list of Homemade egress masks with each having the name, mean, and standard
                       ;;deviation
]

to setup
  clear-all
  ;;As of 3 JUN 2020 Source https://www.census.gov/popclock/
  set population ceiling (329736376 / 100000)

  ;;Ensure MAX is greater than or equal to MIN
  if max-exposed-period < min-exposed-period [set max-exposed-period min-exposed-period] ;;[2 14]
  ;;Source: https://www.womenshealthmag.com/health/a31284395/how-long-does-coronavirus-last/
  set exposed-period list min-exposed-period max-exposed-period
  ;;Ensure MAX is greater than or equal to MIN
  if max-infected-period < min-infected-period [set max-infected-period min-infected-period] ;;[10 14]
  ;;Source: https://www.womenshealthmag.com/health/a31284395/how-long-does-coronavirus-last/
  set illness-period list min-infected-period max-infected-period

  ;;Adjust the mask values so they total 100%
  set masks-none 100 - masks-n95 - masks-medical - masks-homemade
  let masks-adjust masks-n95 + masks-medical + masks-homemade
  if masks-adjust > 100 [
    set masks-n95 round(masks-n95 / masks-adjust * 100)
    set masks-medical round(masks-medical / masks-adjust * 100)
    set masks-homemade round(masks-homemade / masks-adjust * 100)
    set masks-none 100 - masks-n95 - masks-medical - masks-homemade
  ]

  set-masks
  set-age-distro
  set-age-fatality
  set deaths 0
  set max-exposed-infected 0
  set max-tick 0
  setup-turtles
  reset-ticks
end

to go
  ask turtles [
    move
    progress
  ]
  update-curve
  if check-for-end [stop]
  tick
end

to setup-turtles
  create-turtles population [
    setxy random-xcor random-ycor
    set susceptible? true
    set exposed? false
    set infected? false
    set recovered? false
    set time-to-recover 0
    set age set-age
    set color Green
  ]
  ;;Randomly infect four agents
  ;;Infecting less than four runs danger of a premature model ending
  ;;Change n-of X below to a different number to modify this
  ask n-of 4 turtles [
    set exposed? true
    set susceptible? false
    set color 95
    ;;Pick exposure time based on a random uniform distribution
    set time-to-sick random (last exposed-period - first exposed-period + 1) + first exposed-period
  ]
  ;;agents pick masks based on user input
  ask turtles [
    ;;First set mask type
    ;;Based on probabilities set by user
    let mask-pick random 100 + 1
    ;;New in NetLogo 6.1, the code below is effectively a CASE statement
    (ifelse
      mask-pick <= masks-n95 [
        set mask-type 3 ;;N95 mask
        ;;Pick one available mask for both ingress and egress using a random uniform distribution
        let ingress-mask item random length n95-ingress n95-ingress
        let egress-mask item random length n95-egress n95-egress
        set mask-name-ingress item 0 ingress-mask
        set mask-name-egress item 0 egress-mask
        ;;Use values for mask to set efficiency using a random normal distribution
        set mask-ingress random-normal item 1 ingress-mask item 2 ingress-mask
        set mask-egress random-normal item 1 egress-mask item 2 egress-mask
      ]
      mask-pick <= (masks-n95 + masks-medical) [
        set mask-type 2 ;;Medical mask
        ;;Pick one available mask for both ingress and egress using a random uniform distribution
        let ingress-mask item random length medical-ingress medical-ingress
        let egress-mask item random length medical-egress medical-egress
        set mask-name-ingress item 0 ingress-mask
        set mask-name-egress item 0 egress-mask
        set mask-ingress random-normal item 1 ingress-mask item 2 ingress-mask
        set mask-egress random-normal item 1 egress-mask item 2 egress-mask
      ]
      mask-pick <= (masks-n95 + masks-medical + masks-homemade) [
        set mask-type 1 ;;Homemade mask
        ;;Pick one available mask for both ingress and egress using a random uniform distribution
        let ingress-mask item random length homemade-ingress homemade-ingress
        let egress-mask item random length homemade-egress homemade-egress
        set mask-name-ingress item 0 ingress-mask
        set mask-name-egress item 0 egress-mask
        set mask-ingress random-normal item 1 ingress-mask item 2 ingress-mask
        set mask-egress random-normal item 1 egress-mask item 2 egress-mask
      ]
      ;;Default
      [
        set mask-type 0 ;;No mask
        set mask-name-ingress "None"
        set mask-name-egress "None"
        set mask-ingress 0
        set mask-egress 0
    ]) ;;End CASE statement
  ]
end

to move
  ;;A right then left turn using random uniform distributions
  ;;The agent moves in a generally forward direction.
  rt random 100
  lt random 100
  fd 1
end

to progress ;;An agent progresses through their disease
  ;;For all symptomatic agents...
  if infected? [
    infect-others
    ;;Check for death - Can only die when symptomatic
    let age-index int (age / 10)
    if age-index > 9 [set age-index 9]
    ;;Using a random uniform distribution compared to the probability of dying for the age group
    ;;divided by the number of symptomatic days
    ;;Assumes death does not occur when asymptomatic and the probability of death for the age group is
    ;;spread out over the symptomatic days
    ifelse random-float 1 < (item age-index age-fatality / sick-time) [
      set deaths deaths + 1
      die
    ][
      ;;Check for recovered
      set time-to-recover (time-to-recover - 1)
      if time-to-recover <= 0 [
        set color 5
        set recovered? true
        set infected? false
      ]
    ]
  ]
  ;;For all asymptomatic agents...
  if exposed? [
    infect-others
    set time-to-sick (time-to-sick - 1)
    if time-to-sick <= 0 [
      set exposed? false
      set infected? true
      set color 15
      ;;Pick symptomatic time based on a random uniform distribution
      set time-to-recover random (last illness-period - first illness-period + 1)
                                                      + first illness-period
      set sick-time time-to-recover
    ]
  ]
end

to update-curve
  ;;Track the tick with the highest number of asymptomatic plus symptomatic
  let temp count turtles with [exposed? or infected?]
  if temp >= max-exposed-infected [
    set max-exposed-infected temp
    set max-tick ticks
  ]
  ;;Track the most number of agents affected
  set max-affected count turtles with [exposed? or infected? or recovered?]
end

to infect-others
  let a-turtle-egress mask-egress
  ;;Are there other agents nearby?
  ask other turtles-here with [susceptible?] [
    ;;Can the other agent get the virus?
    ;;Random uniform distribution
    if random-float 100 < infectiousness [
      ;;Did the agent's mask block the virus? (Egress)
      ;;Random uniform distribution
      if random-float 1 >= a-turtle-egress [
        ;;Did the other's mask block the virus? (Ingress)
        ;;Random uniform distribution
        if random-float 1 >= mask-ingress [
          set exposed? true
          set susceptible? false
          set color 95
          set time-to-sick random (last exposed-period - first exposed-period + 1)
                                                       + first exposed-period
        ]
      ]
    ]
  ]
end

to-report check-for-end

  ;;If there are no agents that are asymptomatic or symptomatc then no others can be infected so
  ;;simulation ends
  let sick-turtles count turtles with [exposed? or infected?]
  ifelse sick-turtles = 0 [report true] [report false]
end

to-report set-age
  ;;Use a random uniform distribution to set an agents age based on census distribution
  let age-prob random-float 1
  let max-num length age-distro
  let i 0
  while [age-prob > (item i age-distro)] [set i (i + 1)]
  report i
end

to set-age-distro
  ;;US Census 2019 age distribution by age
  ;;Age group data was transformed into age data
  ;;Source: https://www.census.gov/data/tables/2019/demo/age-and-sex/2019-age-sex-composition.html
  ;;(Table 1)
  ;;These are cummulative values from age zero to 100
  set age-distro [0.0122	0.0243	0.0365	0.0487	0.0608	0.0735	0.0862	0.0988	0.1115	0.1241
                  0.1368	0.1494	0.1621	0.1747	0.1874	0.2004	0.2133	0.2263	0.2393	0.2523	
                  0.2653	0.2782	0.2912	0.3042	0.3172	0.3311	0.3451	0.3590	0.3729	0.3869	
                  0.4008	0.4147	0.4287	0.4426	0.4566	0.4692	0.4819	0.4945	0.5072	0.5198	
                  0.5324	0.5451	0.5577	0.5704	0.5830	0.5956	0.6081	0.6207	0.6332	0.6458	
                  0.6583	0.6709	0.6834	0.6960	0.7085	0.7214	0.7343	0.7471	0.7600	0.7729	
                  0.7858	0.7986	0.8115	0.8244	0.8373	0.8470	0.8567	0.8664	0.8761	0.8858	
                  0.8955	0.9052	0.9149	0.9246	0.9343	0.9391	0.9438	0.9486	0.9533	0.9581	
                  0.9628	0.9676	0.9723	0.9771	0.9818	0.9830	0.9841	0.9852	0.9864	0.9875	
                  0.9886	0.9898	0.9909	0.9921	0.9932	0.9943	0.9955	0.9966	0.9977	0.9989	
                  1.0000]
end

to set-age-fatality
  ;;Age Groups: 0-9 10-19 20-29 30-39 40-49 50-59 60-69 70-79 80-89 90+
  ;;Probabilities calculated and transformed into these age groups from different age groups
  ;;Source: https://data.cdc.gov/NCHS/Provisional-COVID-19-Death-Counts-by-Sex-Age-and-S/9bhg-hcku
  set age-fatality [0.0003203 0.0001335 0.0000794 0.0005933 0.0035470
                    0.0080512 0.0226807 0.0976895 0.3733900 0.2988882]
end

to set-masks
  set n95-ingress [["Balazy A" 0.956 0.006] ["Balazy B"  0.944  0.005] ["Konda"  0.85  0.15]
                   ["Johnson"  0.95  0.0]]
  set n95-egress [["Johnson"  0.950  0.0]]
  set medical-ingress [["MacIntyre"  0.44 0.0] ["Oberg A"  0.098  0.0086] ["Oberg B"  0.471  0.048]
                       ["Oberg C"  0.228  0.024] ["Oberg D"  0.9402  0.006] ["Oberg E"  0.626  0.008]
                       ["Oberg F"  0.711  0.014] ["Oberg G"  0.8956  0.016] ["Oberg H"  0.9604  0.004]
                       ["Oberg I"  0.684  0.022] ["Balazy A"  0.15  0.001] ["Balazy B"  0.8  0.002]
                       ["Konda"  0.5  0.07]]
  set medical-egress [["Davies"  0.8952  0.0265]]
  set homemade-ingress [["MacIntyre"  0.03  0.0] ["Konda A"  0.83  0.09] ["Konda B"  0.67  0.16]
                        ["Konda C"  0.57  0.08] ["Konda D"  0.96  0.02] ["Konda E"  0.81  0.19]
                        ["Konda F"  0.79  0.23] ["Konda G"  0.38  0.11] ["Konda H"  0.09  0.13]]
  set homemade-egress [["Davies A"  0.5085  0.1681] ["Davies B"  0.4887  0.1977]
                       ["Davies C"  0.5713  0.1055] ["Davies D"  0.6167  0.0241]
                       ["Davies E"  0.5432  0.2949]]
end

;;==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ====+
;;Mask Data Sources:
;;Balazy, A., Toivola, M., Adhikari, A., Sivasubramani, S. K., Reponen, T., & Grinshpun, S. A. (2006).
;;   Do N95 respirators provide 95% protection level against airborne viruses, and how adequate are
;;   surgical masks? American Journal of Infection Control, 51-57.
;;Davies, A., Thompson, K.-A., Giri, K., & Kafatos, G. (2013). Testing the Efficacy of Homemade Masks:
;;   Would They Protect in an Influenza Pandemic? Disaster Medicine and Public Health Preparedness,
;;   413-418.
;;Johnson, D. F., Druce, J. D., Birch, C., & Grayson, M. L. (2009). A Quantitative Assessment of the
;;   Efficacy of Surgical and N95 Masks to Filter Influenza Virus in Patients with Acute Influenza
;;   Infection. Clinical Infectious Diseases, 275-277.
;;Konda, A., Prakash, S., Moss, G. A., Schmoldt, M., Grant, G. D., & Guha, S. (2020). Aerosol
;;   Filtration Efficiency of Common Fabrics Used in Respiratory Cloth Masks. ACS Nano, 6339–6347.
;;MacIntyre, R., Seale, H., Dung, T. C., Hien, N. T., Nga, P. T., Chughtai, A. A., ... Wang, Q.
;;   (2015). A cluster randomised trial of cloth masks compared with medical masks in healthcare
;;   workers. BMJ Open.
;;Oberg, T., & Brosseau, L. M. (2008). Surgical mask filter and fit performance. American Journal of
;;   Infection Control, 276-282.
;;==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ====+
@#$#@#$#@
GRAPHICS-WINDOW
210
10
723
524
-1
-1
5.0
1
10
1
1
1
0
1
1
1
-50
50
-50
50
0
0
1
ticks
30.0

BUTTON
68
14
132
47
Setup
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
18
55
97
88
Go
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
737
11
1185
161
U.S. Population Age Distribution (Census 2019)
Age
Count
0.0
101.0
0.0
0.0
true
false
"set-histogram-num-bars 20" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [age] of turtles"

MONITOR
65
429
136
474
Population
count turtles
17
1
11

PLOT
737
169
1187
462
SEIR
Days
Count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Susceptible" 1.0 0 -10899396 true "" "plot count turtles with [susceptible?]"
"Exposed" 1.0 0 -13791810 true "" "plot count turtles with [exposed?]"
"Infected" 1.0 0 -2674135 true "" "plot count turtles with [infected?]"
"Recovered" 1.0 0 -7500403 true "" "plot count turtles with [recovered?]"

SLIDER
13
97
187
130
infectiousness
infectiousness
0
100
99.0
1
1
Percent
HORIZONTAL

BUTTON
101
55
180
88
Go Once
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

MONITOR
27
477
96
522
Deaths
deaths
0
1
11

MONITOR
101
477
171
522
Death %
(deaths / population) * 100
4
1
11

MONITOR
895
471
1038
516
Max Exposed+Infected
max-exposed-infected
17
1
11

MONITOR
737
471
892
516
Day Max Exposed+Infected
max-tick
17
1
11

TEXTBOX
17
412
199
440
U.S. Population as of 3 June 2020
11
0.0
1

SLIDER
8
133
192
166
min-exposed-period
min-exposed-period
1
20
2.0
1
1
Days
HORIZONTAL

SLIDER
8
166
192
199
max-exposed-period
max-exposed-period
1
20
14.0
1
1
Days
HORIZONTAL

SLIDER
8
200
192
233
min-infected-period
min-infected-period
1
20
10.0
1
1
Days
HORIZONTAL

SLIDER
8
233
192
266
max-infected-period
max-infected-period
0
20
14.0
1
1
Days
HORIZONTAL

SLIDER
9
270
193
303
masks-n95
masks-n95
0
100
1.0
1
1
Percent
HORIZONTAL

SLIDER
9
305
193
338
masks-medical
masks-medical
0
100
4.0
1
1
Percent
HORIZONTAL

SLIDER
9
340
193
373
masks-homemade
masks-homemade
0
100
50.0
1
1
Percent
HORIZONTAL

SLIDER
10
375
193
408
masks-none
masks-none
0
100
45.0
1
1
Percent
HORIZONTAL

MONITOR
1042
471
1186
516
Max Affected
max-affected
0
1
11

@#$#@#$#@
## WHAT IS IT?

The primary purpose of this abstract model is to demonstrate the use of masks in providing a non-pharmaceutical "herd immunity" against an airborne communicable disease to an otherwise unprotected population. A sufficiently protected population of agents can prevent a disease from easily finding a new host and cause the disease spread to terminate, ending the pandemic. This can occur at high adoption levels even with mostly homemade masks of mixed efficacy. This model is abstracted using a representative US population moving without purpose in a large space. More information, including an Overview, Design concepts, and Details (ODD) description can be found at: https://tinyurl.com/y2dvu8df. 

## HOW IT WORKS

The simulation uses a Susceptible-Exposed-Infectious-Recovered (SEIR) model of a viral infection process. Initially all agents are susceptible (green) to the COVID-19 virus as there is no inherent immunity in the population. When first infected, agents become exposed (blue) and can infect others even though they have no symptoms (asymptomatic). From exposed they move to infectious (red) with visible symptoms (symptomatic). Finally, they recover (grey).

Agents are assigned an age based on U.S. Census 2019 data and the number of agents is set so each represents 100,000 people of the U.S. population as of 3 June 2020.

Initially four agents are set to exposed. (On occasion, agents are anti-social, expose no other agents, and the simulation ends early.) As the simulation progresses, the agents move about the model space. When an exposed (asymptomatic) or infectious (symptomatic) agent comes into contact with a susceptible agent, the susceptible agent will become exposed based on the value of the INFECTIOUSNESS slider, the efficacy of the exposed/infectious agent's mask, and the efficacy of the susceptible agent's mask. After exposure, the agent will be remain in that state for 2 to 14 days (default setting) before becoming infectious. Once infectious, the agent will remain in that state for 10 to 14 days (default setting) before either dying or becoming recovered.

Agents die based on a probability assigned to their age group.

The simulation stops when there are no exposed or infectious agents.

## HOW TO USE IT

There are nine user controls.

1. INFECTIOUSNESS: Integer from [1,100], increment 1, default of 99 percent.
2. MIN-EXPOSED-PERIOD: Integer from [1,20], increment 1, default of 2 days.
3. MAX-EXPOSED-PERIOD: Integer from [1,20], increment 1, default of 14 days.
4. MIN-INFECTED-PERIOD: Integer from [1,20], increment 1, default of 10 days.
5. MAX-INFECTED-PERIOD: Integer from [1,20], increment 1, default of 14 days.
6. MASKS-N95: Integer from [1,100], increment 1, default of 1 percent.
7. MASKS-MEDICAL: Integer from [1,100], increment 1, default of 4 percent.
8. MASKS-HOMEMADE: Integer from [1,100], increment 1, default of 45 percent.
9. MASKS-NONE: Integer from [1,100], increment 1, default of 50 percent.

INFECTIOUSNESS sets the probability of an exposed or infectious agent infecting a susceptible agent.

MIN-EXPOSED-PERIOD is the minimum value from which an agent's asymptomatic exposure period is selected using a random uniform distribution. Note if you set MIN-EXPOSED-PERIOD to more than MAX-EXPOSED-PERIOD, MAX-EXPOSED-PERIOD will change to match MIN-EXPOSED-PERIOD during SETUP.

MAX-EXPOSED-PERIOD is the maximum value from which an agent's asymptomatic exposure period is selected using a random uniform distribution. Note if you set MAX-EXPOSED-PERIOD to be less than MIN-EXPOSED-PERIOD, MAX-EXPOSED-PERIOD will change to match MIN-EXPOSED-PERIOD during SETUP.

MIN-INFECTED-PERIOD is the minimum value from which an agent's symptomatic infectious period is selected using a random uniform distribution. Note if you set MIN-INFECTED-PERIOD to more than MAX-INFECTED-PERIOD, MAX-INFECTED-PERIOD will change to match MIN-INFECTED-PERIOD during SETUP.

MAX-INFECTED-PERIOD is the maximum value from which an agent's symptomatic infectious period is selected using a random uniform distribution. Note if you set MAX-INFECTED-PERIOD to be less than MIN-INFECTED-PERIOD, MAX-INFECTED-PERIOD will change to match MIN-INFECTED-PERIOD during SETUP.

The sum of the values MASKS-N95, MASKS-MEDICAL, MASKS-HOMEMADE, and MASKS-NONE must total 100 percent. If they do not they will be adjusted to 100 percent during SETUP.

## THINGS TO NOTICE

The box labeled "Day Max Exposed+Infected" shows the day on which the most number of agents were either exposed or infectious. This is the day the curve was highest. The box labeled "Max Exposed+Infected" shows the height of the curve for that day. As mask use increases, "Day Max Exposed+Infected" will generally increase (but not always) and "Max Exposed+Infected" will decrease. The box labeled "Max Affected" is the number of agents exposed and infectious and recovered at the end of the simulation.

Observe mask usage in your area and set the four mask percentages to match.

## EXTENDING THE MODEL

Change the model so the recovered agents can become susceptible again, much as the flu does each year.

Add new mask data.

Incorporate social distancing.

## RELATED MODELS

* HIV
http://ccl.northwestern.edu/netlogo/models/HIV
* Virus
http://ccl.northwestern.edu/netlogo/models/Virus
* Virus on a Network
https://ccl.northwestern.edu/netlogo/models/VirusonaNetwork
* Flatten the Curve
http://tangledinfo.com/?q=node/15

## CREDITS AND REFERENCES

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Brearcliffe, D. (2020).  COVID-19 US Masks model. George Mason University. dbrearcl@gmu.edu

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

### Sources
* Balazy, A., Toivola, M., Adhikari, A., Sivasubramani, S. K., Reponen, T., & Grinshpun, S. A. (2006). Do N95 respirators provide 95% protection level against airborne viruses, and how adequate are surgical masks? American Journal of Infection Control, 51-57.
https://doi.org/10.1016/j.ajic.2005.08.018
* CDC Provisional COVID-19 Death Counts by Sex, Age, and State
https://data.cdc.gov/NCHS/Provisional-COVID-19-Death-Counts-by-Sex-Age-and-S/9bhg-hcku
* Davies, A., Thompson, K.-A., Giri, K., & Kafatos, G. (2013). Testing the Efficacy of Homemade Masks: Would They Protect in an Influenza Pandemic? Disaster Medicine and Public Health Preparedness, 413-418.
https://doi.org/10.1017/dmp.2013.43
* Johnson, D. F., Druce, J. D., Birch, C., & Grayson, M. L. (2009). A Quantitative Assessment of the Efficacy of Surgical and N95 Masks to Filter Influenza Virus in Patients with Acute Influenza Infection. Clinical Infectious Diseases, 275-277.
https://doi.org/10.1086/600041
* Konda, A., Prakash, S., Moss, G. A., Schmoldt, M., Grant, G. D., & Guha, S. (2020). Aerosol Filtration Efficiency of Common Fabrics Used in Respiratory Cloth Masks. ACS Nano, 6339–6347.
https://doi.org/10.1021/acsnano.0c03252
* MacIntyre, R., Seale, H., Dung, T. C., Hien, N. T., Nga, P. T., Chughtai, A. A., ... Wang, Q. (2015). A cluster randomised trial of cloth masks compared with medical masks in healthcare workers. BMJ Open.
http://dx.doi.org/10.1136/bmjopen-2014-006577
* Oberg, T., & Brosseau, L. M. (2008). Surgical mask filter and fit performance. American Journal of Infection Control, 276-282.
https://doi.org/10.1016/j.ajic.2007.07.008
* US Census 2019 age distribution by age (Table 1)<br> https://www.census.gov/data/tables/2019/demo/age-and-sex/2019-age-sex-composition.html
* U.S. Census Population Clock 
https://www.census.gov/popclock/
* Women's Health Magazine
https://www.womenshealthmag.com/health/a31284395/how-long-does-coronavirus-last/

## COPYRIGHT AND LICENSE

Copyright 2020 Dale K. Brearcliffe

<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/3.0/"><img alt="Creative Commons License" style="border-width:0" src="https://licensebuttons.net/l/by-nc-sa/3.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/3.0/">Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License</a>.

<!-- 2020 -->
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
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Mask Experiment 5" repetitions="500" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>masks-none</metric>
    <metric>max-affected</metric>
    <metric>max-tick</metric>
    <metric>max-exposed-infected</metric>
    <metric>deaths</metric>
    <metric>count turtles with [susceptible?]</metric>
    <metric>count turtles with [exposed?]</metric>
    <metric>count turtles with [infected?]</metric>
    <metric>count turtles with [recovered?]</metric>
    <enumeratedValueSet variable="masks-n95">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="masks-medical">
      <value value="4"/>
    </enumeratedValueSet>
    <steppedValueSet variable="masks-homemade" first="0" step="5" last="95"/>
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

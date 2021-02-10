;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Variable Declarations;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

globals [
  ;; Slider variables. Baseline values listed below are standard values to use if not exploring the effect of the particular variable. Estimated are derived from literature or
  ;;     Newfoundland data.
  ;; latent-period  ; baseline value = 1 day or 6 ticks (from literature)
  ;; infectious-period  ; baseline value = 3 days or 18 ticks  (from literature)
  ;; transmission-prob ; baseline value = 0.04; estimated to achieve a 55% attack rate (value from literature)
  ;; death-prob ; baseline value = 0.00086 per tick which converts to about 8 per 1000 deaths over the course of an epidemic, a value estimated from Newfoundland mortality data
  ;; church-density ; default value = 1, sets level (%) at which churches can fill -- we assume that both churches fill to the same density
  ;; run-length ; default value, sets the number of ticks a simulation should run
  ;; start-tick ; time at which a run will start; M 6-10 am = 1; used to set the timekeeper properly

  pop-size ; This variable is used for data recording purposes only and is set equal to the count of agents at the start of a simulation
  num-susceptible num-exposed num-infectious num-recovered num-dead

  RD ; The sum of recovered and dead. Gives total number of cases.
  SRD ; The sum of susceptible, recovered, and dead. If an epidemic runs through completely, this will equal population size.

  first-case ; the agt-id of the first infected case
  first-case-occ ; the occupation of the first infected case
  peak-number
  peak-tick-list
  peak-tick
  final-tick
  final-tick-recorded?

  pastor1-present? ; designates whether the pastor has already moved to church 1 on a Sunday
  pastor2-present? ; designates whether the pastor has already moved to church 2 on a Sunday
  pastor1-location ; designates the present location of the church 1 pastor
  pastor2-location ; designates the present location of the church 2 pastor

  orphanage-id ; the building ID of the orphanage, initialized in import-map-data
  orphanage-hshld ; the household number corresponding to the orphanage, initialized in import-map-data
  church1-id ; the building ID of church1, initialized in import-map-data
  church2-id ; the building ID of church2, initialized in import-map-data
  church3-id ; the building ID of church3, which is the orphanage for this particular version of the model, initialized in import-map-data
  num-houses
  num-orphs
  num-schools
  num-hospitals
  num-churches
  num-boats
  house-list

  timekeeper ; determines the simulation's current 4-hour time block so agent's call the appropriate activity methods or record the present time in selected print statements.
             ; Timekeeper values of 1-6 correspond to block on Mondays through Fridays (6am-10am, 10am-2pm, 2pm-6pm, 6pm-10pm, 10pm-2am, 2am-6am). Values of 7-12 correspond
             ; to the same time slots on Saturday; those from 13-18 correspond to these time slots on Sundays.

]

breed [SAagents SAagent]
breed [ghosts ghost]

turtles-own [ ; The first 12 variables are read in from a file
  agt-id
  residence  ; All agents are given a value of 1 which corresponds to St. Anthony
  disease-status ; 0 = susceptible, 1 = exposed, 2 = infectious, 3 = recovered, 4 = dead
  dwelling ; The ID of a person's dwelling
  household ; The ID of a person's household. Multiple households per dwelling are possible.
  ext-family ; The ID of a person's extended family. All agents are currently set to 0 because this variable is designed for future model versions.
  sex ; male = 0, female = 1
  age
  church ; The present model includes two churches + the orphanage, which serves as a church for orphans. This variable indicates which of these an agent attends.
  health-history ; Corresponds to an agent's relative health status, designed to take into account different possible influences that may impact an agent's outcome when faced with a potential
  ; disease-transmitting contact. This variable can range from -1 to 1, with -1 corresponding to a maximum negative impact (i.e., 100% reduction), 0 corresponding to no impact on health,
  ; and 1 corresponding to a maximum positive impact. All agents are currently set to 0 because this variable is designed for future model versions.
  occupation ; is a user-defined integer variable corresponding to a agent's occupation. All agents have been assigned a 3-digit occupation code. See the Info tab for more details on these
  ; specific occupation codes. Occupations refer to agent behavior categories that relate to normal daily activities.
  boat-id ; everyone in a household, no matter their occupation, is assigned to the same boat; orphans, orphan workers, Grenfell, and the household with just doctors and nurses are assigned to boat 999

  occ-type ; A single digit code referring to the agent's general occupation category and corresponding to the first digit of the occupation value, e.g. 1 = fishermen, whereas an occupation
  ; of 102 = a fisherman assigned to boat 2.

  present-location ; building ID of the patch where an agent is located
  can-visit? ; a boolean variable that indicates whether an agent is allowed to visit another agent
  can-pray? ; a boolean variable that indicates whether an agent has yet to go to church
  family-can-move? ; a boolean that indicates whether a family is free to either go to church or visit someone else on Sunday
  group-size ; the size of a traveling group
  dest-x ; the x-coordinate of a patch to which an agent wants to move
  dest-y ; the y-coordinate of a patch to which an agent wants to move
  temp-dwelling ; the building of a dwelling to be visited temporarily when space is not available at home

  ; The following variables are used in identifying new caretakers for children whose parents or previous caretakers have died.
  children-under-five? ; true if there are any preschool children living in the house
  stay-at-home-dad? ; This variable is used to identify a fisherman who is a caretaker of preschool-aged children.

  ; The following three variables are true if a caretaker of the designated sex and occupation type is available.
  female07-caretaker-found?
  female2569-caretaker-found?
  male-caretaker-found?

  time-to-infectious ; Timer variable set equivalent to the latent period that starts running at the tick a agent is infected
  time-to-recovery ; Timer variable set equivalent to the infectious period that starts running at the tick an infected agent becomes infectious
  time-infected ; Tick at which the agent is infected
  place-infected ; ID of the location where an agent is infected
  time-died
  place-died
  infector-id ; the agt-id of the infecting agent
  infector-occ ; the occupation of the infecting agent
  infector-dwelling ; the ID of the infecting agent's dwelling

  newly-infected?
  newly-infectious?
  newly-dead?
  step-completed?
  ]

SAagents-own [
  possible-new-cases
  possible-infectors
]

patches-own [
  building-id ; the ID of the building situated on the patch
  building-type ; 1 = house, 2 = orphanage, 3 = school, 4 = hospital, 5 = church, 6,7 = boat
  occupied? ; determines whether a patch is occupied by an agent or not.
]

;;;;;;;;;;;;;;;;;
;;Setup Methods;;
;;;;;;;;;;;;;;;;;

to setup
  clear-all
  ask patches [
    set pcolor gray + 4
    set occupied? false
    set building-id 0]
  import-map-data
  import-agent-data
  initialize-globals
  infect-first-case
  create-files
  reset-ticks
end

; This procedure creates the buildings on the SA map by reading in a file that contains the coordinates of the lower left hand corner for each building, the dimensions, building ID and building type.
; The method then counts the number of buildings of each type and makes a list of houses. It then identifies the remaining cells in the building and ensures that they have the same building ID and type.
; At the end of the procedure, all patches are given a pcolor corresponding to their building type. Those patches that are not buildings retain the base gray color.
to import-map-data
  set house-list []
  file-open "St_Anthony_Bldgs500.txt"
  while [not file-at-end?]
  [
    ; The following code reads a single line into a six-item list and uses the information in the list to create the buildings
    let items read-from-string (word "[" file-read-line "]") ; Items is a temporary list of variables read in as string but converted to the appropriate variable type.
                                                             ; "Word" concatenates the brackets to the line being read in, because list arguments need to be in brackets
                                                             ; (see Netlogo user manual)
    let llc-x item 0 items
    let llc-y item 1 items
    let building-width item 2 items
    let building-length item 3 items

    ask patch llc-x llc-y [
      set building-id item 4 items
      set building-type item 5 items

      if building-type = 1
         [
           set num-houses num-houses + 1 ; house
           set pcolor green
           set house-list lput building-id house-list
         ]
      if building-type = 2
      [
        set num-orphs num-orphs + 1
        set pcolor orange + 1
        ] ; orphanage
      if building-type = 3
      [
        set num-schools num-schools + 1
        set pcolor red + 2
        ] ; school
      if building-type = 4
      [
        set num-hospitals num-hospitals + 1
        set pcolor turquoise + 1
        ] ; hospital
      if building-type = 5
      [
        set num-churches num-churches + 1
        set pcolor violet + 3
        ] ; church
      if building-type = 6
      [
        set num-boats num-boats + 1
        set pcolor cyan
        ] ; boat type 1--boats are assigned alternating colors so we can distinguish individual boats on the map
      if building-type = 7
      [
        set num-boats num-boats + 1
        set pcolor sky
        ] ; boat type 2
      ]
    ; the following block finds all patches in a building and sets their id, type, and color to match that assigned to the lower left hand corner patch
    let building-patches (patch-set patches with [pxcor >= llc-x and pxcor < (llc-x + building-width) and pycor >= llc-y and pycor < (llc-y + building-length)])
    ask building-patches [
      set building-id [building-id] of patch llc-x llc-y
      set building-type [building-type] of patch llc-x llc-y
      set pcolor [pcolor] of patch llc-x llc-y
    ]
  ] ; closes while
  file-close

  set orphanage-id 85
  set orphanage-hshld 98
  set church1-id 88
  set church2-id 89
  set church3-id 85

end

; This procedure creates the agents and assigns their attributes by reading in a file that contains the 12 agent-specific attributes listed above as turtles-own variables
; and indicated as input from file. It also sets the initial values of the additonal turtles-own variables that are not read in.
to import-agent-data
  file-open "St_Anthony_Agents500.txt"
  ; The following code reads in all the data in the file. Each line of data contains the values for the first 12 attributes for a single node in the order listed below .
  while [not file-at-end?]
  [
    let items read-from-string (word "[" file-read-line "]") ; Items is a temporary list of variables read in as string but converted to the appropriate variable type. "Word" concatenates
    ; the brackets to the line being read in, because list arguments need to be in brackets (see Netlogo user manual)
    create-SAagents 1 [
      set agt-id item 0 items
      set residence item 1 items
      set disease-status item 2 items
      set dwelling item 3 items
      set household item 4 items
      set ext-family item 5 items
      set sex item 6 items
      set age item 7 items
      set church item 8 items
      set health-history item 9 items
      set occupation item 10 items
      set boat-id item 11 items

      set occ-type floor (occupation / 100)  ;floor reports the largest integer less than or equal to input number

      set present-location 0
      set can-visit? true
      set can-pray? true
      set family-can-move? true
      set group-size 1

      set children-under-five? false
      set stay-at-home-dad? false
      set female07-caretaker-found? false
      set female2569-caretaker-found? false
      set male-caretaker-found? false

      set time-to-infectious latent-period
      set time-to-recovery infectious-period
      set time-infected -1
      set place-infected -1
      set time-died -1
      set place-died -1
      set infector-id -1
      set infector-occ -1
      set infector-dwelling -1

      set newly-infected? false
      set newly-infectious? false
      set newly-dead? false
      set step-completed? false

      set shape "circle"
      set color black
      set size 1
    ]
  ]
  file-close

  ask turtles
  [
    initialize-home
    if occupation = 311 ; initialize pastor-location variables
    [
    ifelse church = church1-id
    [set pastor1-location dwelling]
    [set pastor2-location dwelling]
     ]
  ]
end


to initialize-home
  let home-patches (patch-set patches with [building-id = [dwelling] of myself and not occupied?])
  ifelse any? home-patches
  [
     let dest-patch one-of home-patches
     assign-location (dest-patch)
  ] ; closes "if"
  [ ; no unoccupied patches in assigned dwelling
    reassign-dwelling
  ] ; close else
end


to reassign-dwelling ; if a child must be reassigned, it goes to the orphanage, otherwise the agent just goes to a random open dwelling patch
      ifelse age < 15
    [
      set dwelling orphanage-id
      set household orphanage-hshld
      ifelse age < 5
      [set occupation 561]
      [set occupation 861]
      set occ-type floor (occupation / 100)
    ] ; closes "if age < 15"
    [
      let open-home-patches (patch-set patches with [building-type = 1 and not occupied?])
      set dwelling [building-id] of one-of open-home-patches
      let other-residents (turtle-set SAagents with [dwelling = [dwelling] of myself])
      let new-housemate one-of other-residents
      set household [household] of new-housemate
      set church [church] of new-housemate
      set boat-id [boat-id] of new-housemate
      ; Occupation variables have not been changed because only specific occupations (doctors, nurses, teachers, etc.) are used in methods and we
      ; need to retain these. When a fisherman, mother, etc. is reassigned to a new dwelling, he or she will retain the occupation corresponding to
      ; the previous boat, but only occ-type or boat-id will be used in methods, so the difference between the occupation-specified boat and the
      ; assigned boat won't matter.
    ] ; closes else of age < 15
      let new-home-patches (patch-set patches with [building-id = [dwelling] of myself and not occupied?])
      let new-home one-of new-home-patches
      assign-location (new-home)
  end


to initialize-globals
  set pop-size count SAagents
  set num-susceptible count SAagents
  set num-exposed 0
  set num-infectious 0
  set num-recovered 0
  set num-dead 0

  set RD 0
  set SRD 0

  set first-case 0
  set first-case-occ 0
  set peak-number -1
  set peak-tick-list []
  set peak-tick -1
  set final-tick -1
  set final-tick-recorded? false

  set pastor1-present? false
  set pastor2-present? false

  set timekeeper 0
end

to infect-first-case ; This method should be used when the epidemic starts at time 0. If a user wants to delay the start of the epidemic, the call for infect-first-case will need
                     ; to be moved out of the setup procedure and the time infected will need to be reset to the delayed time after the method is called (because the method sets the
                     ; time infected to 0).
  ask one-of SAagents [  ; Randomly chooses one SAagent to be the first case.
   ; ask turtle 10 [ ; Chooses a specific SAagent to be the first case. If a random agent with specific characteristics is desired, the code can be changed accordingly. NOTE: when using
   ; "ask turtle," the agent must be identified by its who value, which is the agt-id - 1
    set disease-status 1 ; "Exposed"
    set num-exposed 1
    set num-susceptible num-susceptible - 1
    set color yellow + 2
    set time-to-infectious latent-period

    ; The indicated values for the following variables allow the user to easily identify the first case in output data
    set time-infected 0
    set place-infected [building-id] of patch-here
    set infector-id 0
    set infector-occ 0
    set infector-dwelling 0
    set first-case agt-id
    set first-case-occ occupation
;    type "Agent " type agt-id print " is the first case."
   ]

end

to create-files
  ; The following four lines can be called before creating a data file so that if that file has been used before, it gets erased before adding data for a new run. See Railsback & Grimm (2012)
  ; for examples.
 ; if (file-exists? "CasesData.csv")[
  ;  carefully
   ;   [file-delete "CasesData.csv"]
    ;  [print error-message]]

  ; The next three blocks of code put headers at the top of new output files (one each for case, daily and final data) and then the files are closed again, which must happen before a
  ; simulation begins. The process of inserting headers only happens if the files don't exist already. If a file does exist, output data are just appended to data from previous simulations
  ; without inserting headers again.

  if (not file-exists? "St_Anthony_flu_Cases.csv")[
  file-open "St_Anthony_flu_Cases.csv"
  file-type "Run Number,"
  file-type "Tick, "
  file-type "Population Size, "
  file-type "Transmission Probability, "
  file-type "Mortality Probability, "
  file-type "Latent Period, "
  file-type "Infectious Period, "
  file-type "First Case ID, "
  file-type "First Case Occ, "
  file-type "Agent ID, "
  file-type "Agent Dwelling, "
  file-type "Agent Occupation, "
  file-type "Infector ID, "
  file-type "Infector Dwelling, "
  file-type "Infector Occupation, "
  file-type "Time Infected, "
  file-type "Place Infected, "
  file-type "Time Died, "
  file-type "Place Died, "
  file-print "Start Tick, "
  file-close]

  if (not file-exists? "St_Anthony_flu_Daily.csv")[
  file-open "St_Anthony_flu_Daily.csv"
  file-type "Run Number,"
  file-type "Tick, "
  file-type "Population Size, "
  file-type "Transmission Probability, "
  file-type "Mortality Probability, "
  file-type "Latent Period, "
  file-type "Infectious Period, "
  file-type "First Case ID, "
  file-type "First Case Occ, "
  file-type "Susceptible, "
  file-type "Newly Infected, "
  file-type "Exposed, "
  file-type "Infectious, "
  file-type "Recovered, "
  file-type "Newly Dead, "
  file-type "Total Dead, "
  file-print "Start Tick, "
  file-close]

  if (not file-exists? "St_Anthony_flu_Final.csv")[
  file-open "St_Anthony_flu_Final.csv"
  file-type "Run Number,"
  file-type "Tick, "
  file-type "Population Size, "
  file-type "Transmission Probability, "
  file-type "Mortality Probability, "
  file-type "Latent Period, "
  file-type "Infectious Period, "
  file-type "First Case ID, "
  file-type "First Case Occ, "
  file-type "Peak Size, "
  file-type "Peak Tick List, "
  file-type "Peak Tick, "
  file-type "Final Tick, "
  file-type "Susceptible, "
  file-type "Recovered, "
  file-type "Total Dead, "
  file-type "R+D (Number of cases), "
  file-type "S+R+D (Finish?), "
  file-print "Start Tick, "
  file-close]

end

;;;;;;;;;;;;;;;;
;;Step Methods;;
;;;;;;;;;;;;;;;;

to go
    ask turtles [  ; the newly? variables reset here are for data recording purposes and to prevent multiple transmissions (e.g. if an agent is infected by another before it goes through the
    ; go method itself and before disease variables are updated accordingly).
    if time-infected != ticks + 1 [
    set newly-infected? false
  ]
  set newly-dead? false
  ]

  ask one-of turtles [set-timekeeper]

  ask SAagents [
    if (disease-status = 1 or disease-status = 2) [
    update-disease-status
    ]

  if disease-status != 4 [

  find-days-activities

  ; The following code only causes actions if there are any infectious agents. In that case it first makes a turtle set of the 4 von Neumann neighbors of the calling agent. If that
  ; agent is susceptible, then the method makes a subset of the neighbor-agents turtle set that consists of neighbors who are infectious. The method transmit-from is then called to
  ; determine whether the calling agent becomes infected. If the calling agent is already infectious, then a subset of susceptible neighbors is made and the transmit-to method determines
  ; whether any of those neighbors become infected. We are assuming a Von Neumann neighborhood (N, S, E, W neighbors only) rather than a Moore Neighborhood because the Moore neighborhood,
  ; with its eight neighbors (adds NE, SE, SW, NW), causes disease transmission to be unrealistically rapid. In thinking about the process, it seems that a limit of four contacts at a time
  ; reflects how many individuals people interact with simultaneously, even in relatively crowded situations.

  let neighbor-agents (turtle-set SAagents-on neighbors4)
  ifelse disease-status = 0
     [
       if any? neighbor-agents with [disease-status = 2]
     [
      set possible-infectors neighbor-agents with [disease-status = 2]
      transmit-from (possible-infectors)
     ] ; closes if any?
     ] ; closes if of disease-status = 0
     [ ; opens else of disease-status = 0
       if disease-status = 2
       [
         if any? neighbor-agents with [disease-status = 0]
         [
         set possible-new-cases neighbor-agents with [disease-status = 0]
         transmit-to (possible-new-cases)
         ] ; closes if any? neighbor-agents
       ] ; closes if disease-status = 2
     ] ; closes else of disease-status = 0
  ] ; closes if disease-status != 4
     set step-completed? true
  ] ; closes ask SAagents


  ask ghosts with [newly-dead?] [reassign-occupation]  ; Immediately after SAagents die, any caretakers must arrange for dependent children to be reassigned to new caretakers. Any dying children need to determine whether
    ; they have suriving siblings under age 5 and if not, arrange for male caretakers to return to previous activities, e.g. fishing. Female caretakers retain their existing status throughout the
    ; rest of the simulation. Dying agents who are engaged in critical occupations (e.g., teachers, pastors, etc.) are also replaced by appropriate agents that are still alive.

  ; The next few lines of code reset boolean variables for the next iteration of the go method.

  ask turtles [
    set step-completed? false
    set newly-infectious? false
    ]
  ask one-of SAagents
  [
    set pastor1-present? false
    set pastor2-present? false
  ]

  update-daily-output

  ; The tick value (on a slider on the interface) can and should be set with the appropriate parameter value to make sure that the entire epidemic is included in data output.
  if ticks + 1 = run-length [
    update-final-output
    stop]

  ; type "This is the end of step " print ticks + 1
  tick
end

; The program is set up for six time ticks per day. Consequently, each time tick is 4 hours long. The following series of statements sets up the time schedule within
; which agent activities will occur. The 6 time slots in a day are 6-10am, 10am-2pm, 2-6pm, 6-10pm, 10pm-2am, and 2-6am. Values of timekeeper between 1 and 6
; correspond to these 6 slots on Mondays through Fridays (in this order); values of timekeeper between 7 and 12 correspond to these 6 slots on Saturdays; values of
; timekeeper between 13 and 18 correspond to these 6 slots on Sundays.

to set-timekeeper
  let counter ticks + start-tick
  if (remainder (counter - 1) 6 = 0) and (remainder (counter - 31) 42 != 0) and (remainder (counter - 37) 42 != 0) [set timekeeper 1]
    if (remainder (counter - 2) 6 = 0) and (remainder (counter - 32) 42 != 0) and (remainder (counter - 38) 42 != 0) [set timekeeper 2]
      if (remainder (counter - 3) 6 = 0) and (remainder (counter - 33) 42 != 0) and (remainder (counter - 39) 42 != 0) [set timekeeper 3]
        if (remainder (counter - 4) 6 = 0) and (remainder (counter - 34) 42 != 0) and (remainder (counter - 40) 42 != 0) [set timekeeper 4]
          if (remainder (counter - 5) 6 = 0) and (remainder (counter - 35) 42 != 0) and (remainder (counter - 41) 42 != 0) [set timekeeper 5]
            if (remainder (counter - 6) 6 = 0) and (remainder (counter - 36) 42 != 0) and (remainder (counter - 42) 42 != 0) [set timekeeper 6]
              if (remainder (counter - 31) 42 = 0) [set timekeeper 7]
                if (remainder (counter - 32) 42 = 0) [set timekeeper 8]
                  if (remainder (counter - 33) 42 = 0) [set timekeeper 9]
                    if (remainder (counter - 34) 42 = 0) [set timekeeper 10]
                      if (remainder (counter - 35) 42 = 0) [set timekeeper 11]
                        if (remainder (counter - 36) 42 = 0) [set timekeeper 12]
                          if (remainder (counter - 37) 42 = 0) [set timekeeper 13]
                            if (remainder (counter - 38) 42 = 0) [set timekeeper 14]
                              if (remainder (counter - 39) 42 = 0) [set timekeeper 15]
                                if (remainder (counter - 40) 42 = 0) [set timekeeper 16]
                                  if (remainder (counter - 41) 42 = 0) [set timekeeper 17]
                                    if (remainder (counter - 42) 42 = 0) [set timekeeper 18]
end

to find-days-activities ; timekeeper values of 5, 6, 11, 12, 17, and 18 correspond to sleeping times when nothing happens, so they are not included in the method at
  ; the present time. If a future version of the model needs to incorporate activities of some agents at these times (e.g., doctors or nurses), the appropriate lines
  ; and corresponding methods must be added to the model.

  if (timekeeper = 1) [do-MF610am-Acts]
  if (timekeeper = 2) [do-MF10am2pm-Acts]
  if (timekeeper = 3) [do-MF26pm-Acts]
  if (timekeeper = 4) [do-MF610pm-Acts]
  if (timekeeper = 7) [do-Sat610am-Acts]
  if (timekeeper = 8) [do-Sat10am2pm-Acts]
  if (timekeeper = 9) [do-Sat26pm-Acts]
  if (timekeeper = 10) [do-Sat610pm-Acts]
  if (timekeeper = 13) [do-Sun610am-Acts]
  if (timekeeper = 14) [do-Sun10am2pm-Acts]
  if (timekeeper = 15) [do-Sun26pm-Acts]
  if (timekeeper = 16) [do-Sun610pm-Acts]
end

; Note: It is assumed that stay-at-home dads only move within their households every day except Sunday. Although they can receive visitors, they do not go visiting
; and unlike mothers, they do not direct the movement of their children. Thus, at time MF10-2 or Sat10-2, this means that children under age 5 do not move at all.
; These are the only time steps where this is the case.

; See info tab for details on the timing of different activities and descriptions of each occ-type (occupation type).

to do-MF610am-Acts
  ifelse stay-at-home-dad? [move-home]
  [
    if (occ-type = 0 or occ-type = 2 or occ-type = 6 or occ-type = 7 or occ-type = 9) [move-home]
    if occ-type = 1 [move-boat]
    if (occ-type = 3 or occ-type = 8) [move-school]
    if occ-type = 4 [move-hospital]
    if occ-type = 5 [move-orphanage]
  ]
end

to do-MF10am2pm-Acts
  ifelse stay-at-home-dad? [move-home]
  [
    if occ-type = 0
    [
    ; A mother with only school-aged children has a chance of going to the boat at this time step. Ethnographic evidence suggests this occurred fairly often,
    ; so we have made the probability 0.8. Otherwise, she can either go visit someone or move within her home. Since the probability of going to the boat is
    ; so high, we figure that there is likely a reason when she doesn't do that, so we have made the probability of visiting low. The movement of this mother
    ; occurs independently of the rest of her household (on M-F only; on Saturdays she acts like mothers with preschool children).

      let prob0a random-float 1.0
      ifelse prob0a <= 0.8
      [
        ifelse can-visit?
        [move-boat]
        [move-home]
      ]
      [
        let prob0b random-float 1.0
        let fw-visit-group (turtle-set self)
        let visit-building dwelling
        if (can-visit? and prob0b <= 0.2) [
          set visit-building find-visit-dwelling (count fw-visit-group)
        ]
        move-group fw-visit-group visit-building
      ]
      ]

    if occ-type = 1 [move-boat]

    if occ-type = 2
     [
    ; A fisherwoman has a chance of going to the boat at this time step. Ethnographic evidence suggests this occurred fairly often, so we have made
    ; the probability 0.8. Otherwise, she can either go visit someone or move within her home. Since the probability of going to the boat is
    ; so high, we figure that there is likely a reason when she doesn't do that, so we have made the probability of visiting low. The movement
    ; a fisherwoman occurs independently of the rest of her household.

      let prob2a random-float 1.0
      ifelse prob2a <= 0.8
      [
        ifelse can-visit?
        [move-boat]
        [move-home]
      ]
      [
        let prob2b random-float 1.0
        let fw-visit-group (turtle-set self) ; The fisherwoman visiting group consists only of herself. No other agents move with her.
        let visit-building dwelling
        if (can-visit? and prob2b <= 0.2) [
          set visit-building find-visit-dwelling (count fw-visit-group)
        ]
        move-group fw-visit-group visit-building
      ]
      ]

    if (occ-type = 3 or occ-type = 8) [move-school]
    if occ-type = 4 [move-hospital]
    if occ-type = 5 [move-orphanage]
    if occ-type = 6 [move-home]

    if occ-type = 7
    [
      ; Stay-at-home moms control the movement of themselves and agents with occ-type 9 (i.e., older women, unmarried daughters/sisters, or preschool children).
      ; All agents present in the household are initially put on a travel list, which is then pared down to include only the desired agents (leaving
      ; out servants or any fisherwomen who are still there). The mother then decides whether the group in this second list will visit another household
      ; and if so, which one, and then the entire group moves to that household's dwelling.  Within the move-group method, the can-visit? variable for all
      ; members of the group as well as others agents present in the visited dwelling is changed to false so that no other movements will occur for any of those agents.
      ; If the group does not go to visit another household, each agent in the traveling group will move within its own house (when the move-group method is called
      ; visit-building is equal to their dwelling).

      let prob7 random-float 1.0
      let household-set make-travel-group
      let travel-set no-turtles
      ask household-set [
        if (occ-type = 7 or occ-type = 9) [
          set travel-set (turtle-set travel-set self)
      ]
      ]
      let visit-building dwelling
      if (can-visit? and prob7 <= 0.5) [
        set visit-building find-visit-dwelling (count travel-set)
      ]
      move-group travel-set visit-building
    ]

;    if occ-type = 9 [] ; do nothing; movement is controlled by the case 700 in house
  ]
end

to do-MF26pm-Acts
  ifelse stay-at-home-dad? [move-home]
  [
    if occ-type = 0
    [
      ; If the mother with school-aged children went to the boat at the previous time step, she moves within the boat at this time; otherwise
      ; she goes home or moves within the house (depending on whether she went visiting in the last time step).

      ifelse present-location = boat-id [move-boat]
      [move-home]
      ]

    if occ-type = 1 [move-boat]

    if occ-type = 2
    [
      ; If the fisherwoman went to the boat at the previous time step, she moves within the boat at this time; otherwise
      ; she goes home or moves within the house (depending on whether she went visiting in the last time step).

      ifelse present-location = boat-id [move-boat]
      [move-home]
      ]

    if (occ-type = 3 or occ-type = 8) [move-school]
    if occ-type = 4 [move-hospital]
    if occ-type = 5 [move-orphanage]
    if (occ-type = 6 or occ-type = 7 or occ-type = 9) [move-home]
  ]
end

to do-MF610pm-Acts

  ; The statement below resets the canVisit variable since all weekday visiting is over by this time. If we decide there will be other
  ; kinds of activities besides moving home at this time (e.g., hospital visits), then we need to add cases as in other do... methods.

    set can-visit? true
    move-home
end

to do-Sat610am-Acts
  ifelse stay-at-home-dad? [move-home]
  [
    if (occ-type = 0 or occ-type = 2 or occ-type = 3 or occ-type = 6 or occ-type = 7 or occ-type = 9) [move-home]
    if occ-type = 1 [move-boat]
    if occ-type = 4 [move-hospital]
    if occ-type = 5 [move-orphanage]
    if occ-type = 8
    [
      ; Ethnographic evidence suggests that any children aged 10 and older who are assigned to a family boat (i.e., not an orphan or orphanage worker's child) have a high
      ; probability of going to work at their family's boat on Saturdays. If they don't go to the boat, they and all other school-aged kids, including orphans, move within their house.
      ; Most likely only older boys would go at this time of day, because that is when boats would actually go out on the water, while girls would go later after the boats returned.
      ; At the time, we are not differentiating in our code because the number of children involved is relatively low, but we might want to consider adapting this later.

      let prob8 random-float 1.0
      ifelse (prob8 <= 0.8 and age >= 10 and occupation != 851 and occupation != 861)
      [move-boat]
      [move-home]
    ]
  ]
end

to do-Sat10am2pm-Acts
  ifelse stay-at-home-dad? [move-home]
  [
    if occ-type = 0
    [
      ; On Saturdays, women with only school-aged children need to include any of their children under age 10 who are present in the house in a traveling group if they go to visit.
      ; They also include agents in the house with occ-type 9 (i.e., older women, unmarried daughters/sisters, or preschool children), although the way occupations are
      ; assigned is such that agents of this occ-type are highly unlikely to (or cannot?) be in the same household as a woman of occ-type 0.
      ; All agents present in the household are initially put on a travel list, which is then pared down to include only the desired agents (leaving
      ; out servants or any fisherwomen who are still there). The mother then decides whether the group in this second list will visit another household
      ; and if so, which one, and then the entire group moves to that household's dwelling.  Within the move-group method, the can-visit? variable for all
      ; members of the group as well as others agents present in the visited dwelling is changed to false so that no other movements will occur for any of those agents.
      ; If the group does not go to visit another household, each agent in the traveling group will move within its own house (when the move-group method is called
      ; visit-building is equal to their dwelling).

      let prob0 random-float 1.0
      let household-set make-travel-group
      let travel-set no-turtles
      ask household-set [
        if ((occ-type = 0 or occ-type = 9) or (occ-type = 8 and age < 10)) [
          set travel-set (turtle-set travel-set self)
      ]
      ]
      let visit-building dwelling
      if (can-visit? and prob0 <= 0.5) [
        set visit-building find-visit-dwelling (count travel-set)
      ]
      move-group travel-set visit-building
    ]

    if occ-type = 1 [move-boat]

    if occ-type = 2
    [
    ; A fisherwoman has a chance of going to the boat at this time step. Ethnographic evidence suggests this occurred fairly often, so we have made
    ; the probability 0.8. Otherwise, she can either go visit someone or move within her home. Since the probability of going to the boat is
    ; so high, we figure that there is likely a reason when she doesn't do that, so we have made the probability of visiting low. The movement
    ; a fisherwoman occurs independently of the rest of her household.

      let prob2a random-float 1.0
      ifelse prob2a <= 0.8
      [
        ifelse can-visit?
      [move-boat]
      [move-home]
      ]
      [
        let prob2b random-float 1.0
        let fw-visit-group (turtle-set self)
        let visit-building dwelling
        if (can-visit? and prob2b <= 0.2) [
          set visit-building find-visit-dwelling (count fw-visit-group)
        ]
        move-group fw-visit-group visit-building
      ]
      ]

    if occ-type = 3
      [
        ; Teachers and clergymen move independently from their families on Saturdays. They either visit other households or they move within their own house. Their travel
        ; group consists only of themselves.

        let prob3 random-float 1.0
        let teach-visit-group (turtle-set self)
        let visit-building dwelling
        if (can-visit? and prob3 <= 0.5) [
          set visit-building find-visit-dwelling (count teach-visit-group)
        ]
        move-group teach-visit-group visit-building
      ]

    if occ-type = 4 [move-hospital]
    if occ-type = 5 [move-orphanage]
    if occ-type = 6 [move-home]

    if occ-type = 7
    [

      ; Stay at home mothers behave essentially the same on Saturdays as they do the rest of the week. However, they also control the movement of any schoolchildren under age 10.

      let prob7 random-float 1.0
      let household-set make-travel-group
      let travel-set no-turtles
      ask household-set [
        if ((occ-type = 7 or occ-type = 9) or (occ-type = 8 and age < 10)) [
          set travel-set (turtle-set travel-set self)
      ]
      ]
      let visit-building dwelling
      if (can-visit? and prob7 <= 0.5)
      [set visit-building find-visit-dwelling (count travel-set)]
      move-group travel-set visit-building
    ]

    if occ-type = 8
    [
      ; At this time step, all orphans are moving within the orphanage. Other children under age 10 who have not already gone somewhere with their mother (i.e., they are called
      ; in the simulation before their mother) and the school-aged children of the orphanage workers can go to the school to play with other children. If the chosen probability
      ; is such that they do not go to the school, children of the orphanage workers go to the orphanage (which is where their parents are going). The fisher's children
      ; don't do anything if they don't go to the school unless they move with their mother later during the time step. If fisher's kids age 10 and over went to the boat in the
      ; previous time step, they move within the boat; otherwise they have a chance of going to the school to hang out with others and if they they don't do that, they move home.
      ; They do not move with their mother and others in the household.

      let prob8 random-float 1.0
      ifelse occupation = 861
      [move-orphanage] ; if of occupation test
      [
        ifelse (age < 10 or occupation = 851)
        [
          ifelse (can-visit? and prob8 <= 0.8)
          [move-school] ; closes if of can-visit/prob test
          [if occupation = 851 [move-orphanage]] ; closes else of can-visit/prob
                                                 ; other children do nothing at this point--they will move with mom
        ] ; closes if of age/occupation test
          [ifelse present-location = boat-id
            [move-boat] ; closes if of present-location
            [ifelse prob8 <= 0.8 [
              ifelse can-visit?
              [move-school]
              [move-home]
            ] ; closes if of prob8
            [move-home] ; closes else of prob8
          ] ; closes else of present-location
      ] ; closes else of age/occupation
    ] ; closes else of occupation 861
  ] ; closes if of occ-type 8

   ; if occ-type = 9 [] ; movements of occ-type 9 are controlled by the occ-type 7 in their household
  ]
end

to do-Sat26pm-Acts
  ifelse stay-at-home-dad? [move-home]
  [
    if (occ-type = 0 or occ-type = 3 or occ-type = 6 or occ-type = 7 or occ-type = 9) [move-home]
    if occ-type = 1 [move-boat]
    if occ-type = 2
    [
      ; If the fisherwoman went to the boat at the previous time step, she moves within the boat at this time; otherwise
      ; she goes home or moves within the house (depending on whether she went visiting in the last time step).

      ifelse present-location = boat-id [move-boat]
      [move-home]
    ]
    if occ-type = 4 [move-hospital]
    if occ-type = 5 [move-orphanage]

    if occ-type = 8
    [
      ; Any child that went to the school or visiting with their mother in the previous time step goes home (or to the orphanage if a child of an orphanage worker);
      ; children who went to the boat earlier in the day move within the boat.

     ifelse (age < 10 or occupation = 861) [move-home]
     [ifelse occupation = 851 [move-orphanage]
       [ifelse present-location = boat-id [move-boat]
         [move-home]
      ] ; closes else of present-location
     ] ; closes else of occupation 851
    ] ; closes else of age test
  ]
end

to do-Sat610pm-Acts

    ; The statement below resets the canVisit variable since all Saturday visiting is over by this time.

    set can-visit? true
    move-home
      if occupation = 311 ; the following statements initialize the pastors' locations in preparation for Sunday activities
      [
        ifelse church = church1-id
        [set pastor1-location present-location]
        [set pastor2-location present-location]
        ]
end

to do-Sun610am-Acts

  ; move-Sunday is called by the first adult agent in the household, and that method changes the family-can-move? variable
  ; for everybody in that family. The movements of all fisher's children are governed by the adults in their household, while
  ; the movement of the orphans is governed by their age.

  if family-can-move? [
    ifelse dwelling != orphanage-id
       [if age > 15
         [move-Sunday]
       ]
       [
          ifelse (age <= 15)
          [move-orphanage] ; Preschool-aged orphans attend church in the orphanage
          [move-Sunday] ; other 561s are orphans over age 15; they have a chance of going to church at the same times as everyone else
       ]
  ]
end

to do-Sun10am2pm-Acts
  ; The first two statements reset the visiting variables so that agents can visit others in the next time step (2-6 pm). At this time
  ; step every agent calls moveHome -- if they are not at home, they go home; if they are already there, they move within their home.
  ; Pastor-location statements are also reset.

  set can-visit? true
  set family-can-move? true
      move-home
      if occupation = 311
      [
        ifelse church = church1-id
        [set pastor1-location present-location]
        [set pastor2-location present-location]
        ]
end

to do-Sun26pm-Acts

  ; This method is identical to the do-Sun610am-Acts method since it is just the second time slot for Sunday activities.

  if family-can-move? [
    ifelse dwelling != orphanage-id
       [if age > 15
         [move-Sunday]
       ]
       [
          ifelse (age <= 15)
          [move-orphanage] ; Preschool-aged orphans attend church in the orphanage
          [move-Sunday] ; other 561s are orphans over age 15; they have a chance of going to church at the same times as everyone else
       ]
  ]
end

to do-Sun610pm-Acts

  ; The statements below reset the can-visit?, can-pray?, and family-can-move? variables in preparation for the next week.

  set can-pray? true
  set can-visit? true
  set family-can-move? true
   move-home
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Destination-related movement methods;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to move-home

  ; The moveHome method moves agents to or within their assigned dwellings at any time after model initialization. If an agent attempts
  ; to move within a full house, it stays where it is. If the house is full when an agent tries to return from outside, it picks a different
  ; dwelling to go to, but is not reassigned permanently.

  set group-size 1
  ; In the present model, only individuals call move-home, so group-size is set at 1.  If in the future we have groups traveling home, we need
  ; to set group-size equal to the size of the traveling group.

  let dest-patch -1 ; initialized at an unrealistic value to prevent and/or better identify unintended errors

  let home-patches (patch-set patches with [building-id = [dwelling] of myself and not occupied?])
  ifelse any? home-patches
  [
     set dest-patch one-of home-patches
  ] ; closes "if"
  [
    ; no unoccupied patches in assigned dwelling. If already at home, do nothing; if not at home, find a dwelling to visit
    ; if dwelling is the orphanage and the orphanage is full, find new dwelling to visit

    ifelse (present-location != dwelling) [
       set temp-dwelling find-visit-dwelling (group-size)
       let visit-dest-patches (patch-set patches with [building-id = [temp-dwelling] of myself and not occupied?])
       set dest-patch one-of visit-dest-patches
  ]
    [set dest-patch patch-here]
  ] ; close else
  assign-location (dest-patch)
end

to move-school
  ; The move-school method sends agents to school when it is called (by school-aged children, teachers, and clergymen, who also serve as teachers).
  ; If no space is available, the agent stays where it is. This model assumes the community has only one school, which is reasonable for early 20th
  ; century Newfoundland.

  let dest-patch -1
  let school-patches (patch-set patches with [building-type = 3 and not occupied?])
    ifelse any? school-patches
    [
     set dest-patch one-of school-patches
    ] ; closes if
    [
    set dest-patch patch-here
    ] ; closes else
  assign-location (dest-patch)
end

to move-hospital
  ; The move-hospital method sends agents to the hospital when it is called (by doctors and nurses right now--they are assigned an occupational code
  ; that indicates that status; eventually we will add seriously ill agents to the call). If no space is available, the agent stays where it is.

  let dest-patch -1
  let hospital-patches (patch-set patches with [building-type = 4 and not occupied?])
    ifelse any? hospital-patches
    [
     set dest-patch one-of hospital-patches
    ] ; closes if
    [
    set dest-patch patch-here
    ] ; closes else
  assign-location (dest-patch)
end

to move-orphanage
  ; The move-orphanage method sends agents to the orphanage when it is called (by orphans or orphanage and industrial workers). If no space is available
  ; when the method is called, the agent stays where it is.

  let dest-patch -1
  let orphanage-patches (patch-set patches with [building-type = 2 and not occupied?])
    ifelse any? orphanage-patches
    [
     set dest-patch one-of orphanage-patches
    ] ; closes if
    [
    set dest-patch patch-here
    ] ; closes else
  assign-location (dest-patch)
end

to move-boat
  ; The move-boat method sends agents to their assigned boat when it is called. An agent's boat-ID determines the specific boat assignment.
  ; Fishermen call moveBoat every Monday-Saturday during the day; Fisherwomen call the method with a specified probability on those days depending on
  ; their occ-type (related to child care responsibilities). Older children (≥ 10 years) of fishermen may call this method on Saturdays. If no space
  ; is available in an assigned boat when the method is called, the agent stays where it is.

  let dest-patch -1
  let boat-patches (patch-set patches with [building-id = [boat-id] of myself and not occupied?])
    ifelse any? boat-patches
    [
     set dest-patch one-of boat-patches
    ] ; closes if
    [
    set dest-patch patch-here
    ] ; closes else
  assign-location (dest-patch)
end

to move-Sunday
  ; The move-Sunday method governs movement of pastors to church for both services and movement of family groups, older orphans, and other independent
  ; adults to either church or visiting (unless someone is visiting them). It is only called by orphans over age 15 and the first adult agent in a regular
  ; household who calls the go method. Any other adults and all children in the household do not call the method; their movement is based on decisions made by
  ; the first household adult who calls the method. Older orphans move independently and pastors always go to church; younger orphans stay in the orphanage
  ; for church services.

  ifelse occupation = 311
  [
    ; The if-portion of this loop ensures that the pastors go to church each service independent of their families. This code also prevents them from visiting others
    ; during church times.

    let pastor-set (turtle-set self)
    move-group pastor-set church
    ifelse church = church1-id
   [
     set pastor1-present? true
     set can-visit? false
   ] ; closes if church = church1-id
   [
     if church = church2-id
     [
     set pastor2-present? true
     set can-visit? false
     ] ; closes if church = church2-id
   ] ; closes else church = church1-id
  ] ; closes if occupation = 311
  [
    ; The else-portion of the loop creates travel groups and sets related variables for all agents other than the pastors. At the end of this portion, the choose-church-or-visit
    ; method is called and determines the specific activities of the agents.

    let sunday-group no-turtles
    ifelse (occupation = 561 and age > 15) ; older orphans go to church by themselves
      [
        set sunday-group (turtle-set self)
        set family-can-move? false
        ]
      [
        let group-list make-travel-group
        ask group-list [
          if occupation != 311 [
            set sunday-group (turtle-set sunday-group self) ; calling agent makes a travel group of all agents in the household except for any pastors (who move by themselves)
            set family-can-move? false
          ] ; close if occupation
        ] ; closes ask group-list
      ] ; closes else of occupation = 561
      choose-church-or-visit (sunday-group)
    ] ; closes else of occupation = 311
end


;;;;;;;;;;;;;;;;;;;;;;;;
;;Movement sub-methods;;
;;;;;;;;;;;;;;;;;;;;;;;;

;; Procedure for finding a dwelling to visit
to-report find-visit-dwelling [group-num]
  let counter 0
  let available-cells 0
  let lonely-pastor1? false ; the lonely-pastor variables are used to prevent individuals from visiting pastors on Sundays during service times if they are the only agents in a house and
  let lonely-pastor2? false ; have not yet gone to church. This ensures that visitors will not be in a pastor's house when all other residents are gone.
  let visit-dwelling-id one-of house-list
  set available-cells count patches with [building-id = visit-dwelling-id and not occupied?]

  if (timekeeper = 13 or timekeeper = 15) [
    if (visit-dwelling-id = pastor1-location and available-cells = 15 and not pastor1-present?) [set lonely-pastor1? true]
    if (visit-dwelling-id = pastor2-location and available-cells = 15 and not pastor2-present?) [set lonely-pastor2? true]
  ]

    while [(counter <= num-houses * 10) and ((group-num > available-cells) or (available-cells = count patches with [building-id = visit-dwelling-id])
        or (visit-dwelling-id = dwelling) or (lonely-pastor1?) or (lonely-pastor2?))]
    [
      set visit-dwelling-id one-of house-list
      set available-cells count patches with [building-id = visit-dwelling-id and not occupied?]
      set lonely-pastor1? false
      set lonely-pastor2? false
      if (timekeeper = 13 or timekeeper = 15) [
        if (visit-dwelling-id = pastor1-location and available-cells = 15 and not pastor1-present?) [set lonely-pastor1? true]
        if (visit-dwelling-id = pastor2-location and available-cells = 15 and not pastor2-present?) [set lonely-pastor2? true]
      ]
      set counter counter + 1
    ]
    if counter > num-houses * 10 [set visit-dwelling-id dwelling] ; if unable to find a visit-dwelling within the max allowed attempts, set the visit-dwelling to be own dwelling
    report visit-dwelling-id
end

to assign-location [destination] ; this method is only called when "destination" (a specific patch) is known to be available at a desired building. The initial error statement is a security
                                 ; blanket that should never be used
  ask patch-here [set occupied? false]
  ifelse destination = nobody
  [print "NOBODY-ERROR: Assign-location returned nobody for the destination."]
     [setxy [pxcor] of destination [pycor] of destination]
       set present-location [building-id] of patch-here
  ask patch-here [set occupied? true]
end

; make-travel-group makes a set of all members of the same household in the same building as the calling agent to be used for group movement. Right now, it is limited to members of
; the same household. If later on, we want to have more general traveling groups, we will need to either generalize this method or write an analogous new method. The turtle-set
; is limited to SAagents, which excludes all ghosts who may be part of the household.

to-report make-travel-group
  let residents-set no-turtles
  let occupants (turtle-set SAagents-on patches with [building-id = [present-location] of myself])
    ask occupants [
      if household = [household] of myself [set residents-set (turtle-set residents-set self)]
    ]
  report residents-set
end

; move-group contains code to allow a group to visit another place. This is called by any agent directing its own movement or that of a group it is responsible for. The ID of the
; building to be visited and the traveling group are determined by the appropriate agent before the method is called. During this process, the calling agent also makes sure that
; there is enough space in the visit-bldg for the entire group. The group then moves to the building chosen.

to move-group [group-set visit-bldg]
  ask group-set [
  let visit-patches (patch-set patches with [building-id = visit-bldg and not occupied?]) ; each agent in the group-set makes their own set of unoccupied visit-patches
  let dest-patch nobody
  ifelse count visit-patches = 0 ; This might occur if the group is staying home. In that situation there would be enough space available, but if the house is full, there would
                                 ; be no unoccupied cells. In this case, the dest-patch would be assigned to the present location.
  [set dest-patch patch-here]
  [set dest-patch one-of visit-patches]
  assign-location (dest-patch)

  ; The following loop changes the value of can-pray? to make sure that the moving group is not able to attend church a second time on the same day.
  if ([building-type] of patch-here = 5 and occupation != 311) [
      set can-pray? false
    ]
  ]

  ; The following makes sure that canVisit becomes false when a group either goes to visit someone else or is being visited.

      if ([building-type] of patch-here = 1) [
        let occupant-set (turtle-set SAagents-on patches with [building-id = visit-bldg])
           ask occupant-set [
           set can-visit? false
    ]
  ]
end

; the choose-church-or-visit determines the specific activities a group will engage in during the church/visit time slots on Sundays. We think the probability of visiting should
; be fairly high (0.5 or greater) since Sunday is a day for socializing. Code in move-Sunday also ensures that the pastors always go to church at these times.

to choose-church-or-visit [Sunday-set]
  let num-church-cells 0
  let available-cells 0
  let church-occupants 0
  set num-church-cells count patches with [building-id = [church] of myself]
  set available-cells (round num-church-cells * church-density) - 1 ; The church-density variable (a slider) governs how packed the church is allowed to become.
                                                                    ; The - 1 in the equation ensures that a space is always available for the pastor.
  set church-occupants (count SAagents-on patches with [building-id = [church] of myself] + count Sunday-set)

  ; If both can-visit? and can-pray? are true, the first priority is to go to church; if that doesn't happen, the Sunday-set will try to visit another
  ; household, and if that doesn't happen, they move within their own house. When they try to go to church, they need to check the available space in
  ; light of whether the pastor is already present to ensure that there is space for him regardless of how late he comes through in the simulation.

  ifelse (can-visit? and can-pray?)
  [
    ifelse ((church = church1-id and not pastor1-present?) or (church = church2-id and not pastor2-present?)) ; pastor has not yet gone to the church
    [
      ifelse church-occupants <= available-cells
      [
      move-group Sunday-set church ; move-group 1
      ] ; closes if of church-occupants
      [
        ifelse ((present-location = dwelling) or (present-location = temp-dwelling))
        [
        let probS1 random-float 1.0
        let visit-building dwelling
        if (probS1 <= 0.5) [
          set visit-building find-visit-dwelling (count Sunday-set)
        ]
        move-group Sunday-set visit-building ; move-group 2
      ] ; closes if of present-location
        [type "Agent " type agt-id print ", Sunday True/True Option 1 failed after trying to go to church and visit."] ; closes else of present-location
      ] ; closes else of church-occupants
    ] ; closes if of church/pastor not present

    [
    if ((church = church1-id and pastor1-present?) or (church = church2-id and pastor2-present?)) ; pastor already at church, an extra cell is available in the church
    [
      ifelse church-occupants <= (available-cells + 1)
      [
      move-group Sunday-set church ; move-group 3
      ]
      [
        ifelse ((present-location = dwelling) or (present-location = temp-dwelling))
        [
        let probS2 random-float 1.0
        let visit-building dwelling
        if (probS2 <= 0.5) [
          set visit-building find-visit-dwelling (count Sunday-set)
        ]
        move-group Sunday-set visit-building ; move-group 4
      ] ; closes if of present-location
        [type "Agent " type agt-id print ", Sunday True/True Option 2 failed after trying to go to church and visit."] ; closes else of present-location
      ] ; closes else of church-occupants
    ] ; closes if of church/pastor present
    ] ; closes else of church/pastor not present
    ] ; closes if of can-visit?/can-pray?

    [ifelse (can-visit? and not can-pray?) ; This will only occur if a family has already gone to church (in a previous time step), so their options are to either visit
                                           ; another household or move within their own house.
      [
        let probS3 random-float 1.0
        let visit-building dwelling
        if (probS3 <= 0.5) [
          set visit-building find-visit-dwelling (count Sunday-set)
        ]
        move-group Sunday-set visit-building ; move-group 5
      ] ; closes if of can-visit?/not can-pray?

      [ifelse not can-visit? [] ; This will only occur if a family is being visited by other agents. In this case, the family will not have moved within their house yet, but
                                ; at the present time we have decided not to allow them the chance to move within the house so that we do not raise the number of potential
                                ; contacts with visitors. NOTE: THIS IS NOT CONSISTENT WITH WHAT WE DO AT OTHER VISITING TIMES, AND SO WE SHOULD PROBABLY CHANGE THIS IN THE FUTURE.
        [type "Agent " type agt-id print ": Complete Sunday fail."]
      ] ; closes else of can-visit?/not can-pray?
    ] ; closes else of can-visit?/can-pray?
end


;;;;;;;;;;;;;;;;;;;
;;Disease Methods;;
;;;;;;;;;;;;;;;;;;;

to update-disease-status ; An SAagents method called near the beginning of the go method. Depending on their current disease status and the value of relevant timing variables,
  ; SAagents will transition to the next disease status or reduce the time remaining for the current status (or die, with some probability, if they are infectious). The durations of disease
  ; stages are equal for all SAagents.

  ; Susceptible SAagents do nothing

  ; Exposed agents must check the value of time-to-infectious to see if they should become infectious this time period.
  if disease-status = 1
  [
    ifelse time-to-infectious = 0
       [set disease-status 2
        set newly-infectious? true
        set time-to-recovery infectious-period
        set color red]
       [set time-to-infectious time-to-infectious - 1]
    ] ; closes if of disease-status = 1

;  [ ; opens else of disease-status = 1

  ; Infectious agents first check whether they will die this time period. If they survive, they must check the value of time-to-recovery to see if they should recover this time period.
  if disease-status = 2  [
    if not newly-infectious? [
    let death-threshold random-float 1.0
    if death-threshold <= death-prob
      [create-ghost]
    ]

    ifelse time-to-recovery = 0 and disease-status = 2 ; The ifelse statement includes the disease-status component so agent who die this tick don't override changes made in create-ghost
       [set disease-status 3
        set color violet - 1]
       [set time-to-recovery time-to-recovery - 1]
  ] ; closes if disease-status = 2
;  ] ; closes else of disease-status = 1

  ; Recovered and dead SAagents do nothing.

end

; transmit-to and transmit-from assign a random probability of transmission to a contact between an infectious and a susceptible agent. When such a contact occurs, the method compares the
; parameter value of the transmission probability to the assigned probability. If the transmission probability is greater than or equal to the assigned probability, then disease transmission
; occurs and the susceptible agent moves into the exposed state. The length of time in the exposed class is determined by the parameter latent-period. If the transmission probability is less
; than the assigned probability, the susceptible agent does not change disease status. NOTE: AT THE PRESENT TIME THE LENGTH OF THE LATENT PERIOD IS ASSUMED TO BE CONSTANT.

to transmit-from [infectors-set] ; called by a susceptible agent
  let susc-agent self
  let prob random-float 1.0
  ask infectors-set [
    if (disease-status = 2 and prob <= transmission-prob  and not [newly-infected?] of susc-agent) ; the condition "disease-status = 2" is not really needed since it is used in making the infector's set,
                                                                                   ; but it reminds us here that that is the case
    [
      if ((building-id = [building-id] of susc-agent) or (building-type = 6 and [building-type] of susc-agent = 7) or (building-type = 7 and [building-type] of susc-agent = 6)) [
        ; agents can only come into contact if they are in the same building or in the same or adjacent boats
      ask susc-agent [
        set disease-status 1
        set color yellow
        set time-to-infectious latent-period - 1 ; the subtraction of 1 from the latent period takes the present time tick into account
        set time-infected ticks + 1  ; The plus one is to correct the timing since ticks increment at the end of the go method and thus it is recording the previous value of ticks
        ; during the current go.
        set place-infected [building-id] of patch-here
        set infector-id [agt-id] of myself ; myself now refers to the member of infectors-set who called the above "ask susc-agent".
        set infector-occ [occupation] of myself
        set infector-dwelling [dwelling] of myself
        set newly-infected? true
        ] ; closes ask susc-agent
      ] ; closes if ((building-id ...)
      ] ; closes if (disease-status ...)
    ] ; closes ask infectors-set
end

to transmit-to [new-cases-set] ; called by an infectious agent
  let infector-agent self
  let prob random-float 1.0
  ask new-cases-set [
    if (disease-status = 0 and prob <= transmission-prob) [ ; the condition "disease-status = 0" is not really needed since it is used in making the new-cases-set,
                                                            ; but it reminds us here that that is the case
      if ((building-id = [building-id] of infector-agent) or (building-type = 6 and [building-type] of infector-agent = 7) or (building-type = 7 and [building-type] of infector-agent = 6)) [
      set disease-status 1
      set color yellow
      set time-to-infectious latent-period ; time-to-infectious is set to the latent period here (not latent period - 1) because the new case is not the agent calling the method. If the new
                                           ; case has already completed its step, its time-to-infectious is adjusted at the end of this method. Otherwise, that adjustment occurs in update-disease-status
                                           ; when that agent completes its step.
      set time-infected ticks + 1  ; The plus one is to correct the timing since ticks increment at the end of the go method and thus it is recording the previous value of ticks
                                   ; during the current go.
      set place-infected [building-id] of patch-here
      set infector-id [agt-id] of infector-agent
      set infector-occ [occupation] of infector-agent
      set infector-dwelling [dwelling] of infector-agent
      set newly-infected? true
      if step-completed? [
        set time-to-infectious time-to-infectious - 1
      ]
      ]
    ]
  ]
  end

;;;;;;;;;;;;;;;;;
;;Death Methods;;
;;;;;;;;;;;;;;;;;

; The create-ghost method is called by an SAagent who has died. It records death-related variables and creates a new turtle
; in the breed "ghost" with the same attributes as the calling agent. The calling agent is then moved to the cemetery (coordinates 1,1)
; and the GhostAgent remains at the location where the agent died. Users can control whether the ghost is visible or not with the
; "hide-turtle" statement below.

to create-ghost
  set shape "ghost"
  set disease-status 4
  set color gray
  set newly-dead? true
  set time-died ticks + 1 ; as in the transmission methods above, the plus one needs to correct for how the go method keeps track of time
  set place-died [building-id] of patch-here
  hatch-ghosts 1 [
  set shape "ghost"
  set color white
  set size 2
  ask patch-here
  [set occupied? false]
  hide-turtle
  ]

  ; The following statements set the size of ghosts in the cemetery to be proportional to the number of ghosts in order to provide a
  ; visualization of the number of deaths during the epidemic. At present this code results in multiple visible ghosts of different
  ; sizes superimposed on one another at the location of the cemetery. The icons are also centered over the patch (1,1), with the
  ; result that when the ghost gets large enough, only part of it can be seen. These are commented out for batch runs, but need to
  ; be uncommented for gui runs.
  setxy 1 1
  ;  let prop-ghosts (count ghosts / pop-size)
  ;  if prop-ghosts > 0.01  [set size floor (prop-ghosts * 50)]
end

; The reassign-occupation method is called by all newly dead agents.
to reassign-occupation
  set children-under-five? false
  let dying-agent self
  let live-children (turtle-set SAagents with [disease-status != 4 and age <= 15 and household = [household] of dying-agent])
  ; The live-children is set for the purpose of determining new caretakers for children of a dying agent who is a primary caretaker.
  ; Therefore the set only needs to contain children who are assigned to the same household as the dying agent.

  let live-adults (turtle-set SAagents with [disease-status != 4 and age > 15])
;  type "tick " type ticks + 1 type ", agent " type agt-id type ", occupation " type occupation type ", household " type household print ", has died."

; The following block of code determines whether a dying agent has live children in the household, and if so, it identifies
; whether any caretakers are available for those children. Agents over age 15 who live in the orphanage are not included because
; they would usually find live children in the household (unless there are no surviving orphans under age 15), but they are not
; the caretakers for those children.

  if any? live-children [
  if (age > 15 and dwelling != orphanage-id)
  [
    if any? live-children with [age < 5] [set children-under-five? true]
    ifelse any? live-adults
       [caretaker-test live-adults live-children]
       [print "There are no living adults left in the community. Total societal collapse!!"]
  ]
  ]
  if any? live-adults ; There must be at least one live adult in the community if any replacements are to occur
  [

  if occ-type = 0
  [
    ; All children of women in occ-type 0 are of school-age. If there are still children at home (not all have died),
    ; first try to choose a new mom from available females if any have been identified during the caretaker-test method.
    ; If there are no available females, the caretaker test method will have either designated a male as the new
    ; caretaker or sent the children to the orphanage.

    let sub0-found? false
    if any? live-children [
      if female2569-caretaker-found?
      [
        set sub0-found? choose-new-mom live-adults sub0-found?
      if not sub0-found?
      [
        print "Substitute mom not found when there is supposed to be one. Check method."
      ]
    ]
    ]
  ]

;  if occ-type = 1 [] ; fishermen are not replaced when they die

;  if occ-type = 2 [] ; fisherwomen are not replaced when they die

  if occ-type = 3 ; If a pastor dies, a male replacement is always chosen unless no one is available, in which case the community
                  ; is just left without spiritual guidance. If a teacher dies, a replacement (drawn from fisherwomen) is also
                  ; found as long as one is available.
  [
    let pastor-found? false
    let teacher-found? false
    ifelse occupation = 311
    [
      set pastor-found? choose-pastor live-adults pastor-found?
      if not pastor-found? [type "New pastor cannot be found. People are in the midst of a disaster "
                           print "and have no spiritual guidance!"]
    ]
    [
      set teacher-found? choose-from-fisherwomen live-adults teacher-found?
      if not teacher-found? [type "New teacher cannot be found. People are in the midst of a disaster "
                           print "and have no educational guidance!"]
    ]
    ]

  if occ-type = 4 ; If a nurse dies, a replacement (drawn from fisherwomen) is found as long as one is available. Doctors are
                  ; not replaced because of their specialized knowledge and the likelihood that a new one could not be put in
                  ; place on short notice during an epidemic.
  [
    let nurse-found? false
    if occupation = 421
    [
    set nurse-found? choose-from-fisherwomen live-adults nurse-found?
      if not nurse-found? [type "New nurse cannot be found. People are in the midst of a disaster "
                           print "and have no nursing care!"]
    ]
  ]

  if occ-type = 5 ; Orphanage workers are replaced whenever a suitable substitute can be found.
  [
    let orph-worker-found? false
    if occupation = 551
    [
    set orph-worker-found? choose-orph-worker live-adults orph-worker-found?
      if not orph-worker-found? [print "Orphanage worker cannot be found. Orphans running amok."]
    ]
    ]

;  if occ-type = 6 [] ; servants are not replaced when they die

    ; At least some children of women in occ-type 7 are below school-age. If there are still children at home (not all have died),
    ; first try to choose a new mom from available females if any have been identified during the caretaker-test method.
    ; If there are no available females, the caretaker test method will have either designated a male as the new
    ; caretaker (stay-at-home-dad) or sent the children to the orphanage.

  if occ-type = 7
  [
    let sub7-found? false
    if any? live-children [
      if female2569-caretaker-found?
      [
        set sub7-found? choose-new-mom live-adults sub7-found?
      if not sub7-found?
      [
        print "Substitute mom not found when there is supposed to be one. Check method."
      ]
    ]
    ]
    ]

;  if occ-type = 8 [] ; schoolchildren are not replaced when they die and they do not need to change
                      ; a stay-at-home-dad's status

  if occ-type = 9 ; An adult of occ-type 9 who dies is not replaced. A child has to change its dad's stay-at-home-dad status if
                  ; it is the last preschool-aged child to die.
  [
    if age < 5
    [
      if not any? live-children with [age < 5]
      [
        if any? live-adults with [household = [household] of dying-agent and stay-at-home-dad?]
        [
        ask live-adults with [household = [household] of dying-agent and stay-at-home-dad?]
          [
            set stay-at-home-dad? false
            ]
        ]
        ]
    ]
  ]
  ]
end

 ; caretaker-test goes through a systematic process to determine the availability of caretakers when an agent dies, looking
 ; first for possible females, and then if no females are available, for a possible male. If no caretakers are identified
 ; all children in the household are sent to the orphanage.

to caretaker-test [living-adults living-children]
    find-poss-fem-carer (living-adults)
    if (not female07-caretaker-found? and not female2569-caretaker-found?)
    [
      find-poss-male-carer (living-adults)
      if not male-caretaker-found?
      [
        send-to-orphanage (living-children)
      ]
    ]
end

; The find-poss-fem-carer method first checks to see if the mother of the household (occ-type 0 or 7) is still present. If not,
; the method searches for an available female among  fisherwomen, orphanage workers, servants, or mother's aids within the
; same household. This method just identifies that possible caretakers exist, it does not assign specific agents to be new
; caretakers (that is done in the choose-new-mom method).

to find-poss-fem-carer [poss-carers]
  let dying-agent self
  set female07-caretaker-found? false
  set female2569-caretaker-found? false
    let poss-fem-carers (turtle-set poss-carers with [household = [household] of dying-agent and sex = 1])
  if any? poss-fem-carers [
  ask poss-fem-carers [
      if (occ-type = 0 or occ-type = 7)
      [
        ask dying-agent
        [set female07-caretaker-found? true]
      ]
      if (occ-type = 2 or occupation = 551 or occ-type = 6 or occ-type = 9)
      [
        ask dying-agent
        [set female2569-caretaker-found? true]
      ]
    ]
  ]
end

; The find-poss-male-carer method identifies any adult males in a household who may be able to step in as caretakers if no
; female caretakers are available. Males of occ-type 3 (pastors or teachers) and occ-type 4 (doctors) may only become
; caretakers of school-aged children so that they are able to pursue their occupations throughout the epidemic. Thus,
; orphaned children in families with preschoolers get sent to the orphanage rather than forcing a pastor or doctor to
; become a stay-at-home dad. Unlike the poss-fem-carer-method, this method assigns specific agents to be the caretakers
; since only stay-at-home dads change their daily behavior and that is automatically done when their stay-at-home-dad? boolean
; is set to true in this method.

to find-poss-male-carer [poss-carers]
  let dying-agent self
  set male-caretaker-found? false
  let poss-male-carers (turtle-set poss-carers with [household = [household] of dying-agent and sex = 0])
     if any? poss-male-carers [
     ask poss-male-carers [
       if stay-at-home-dad? ; identifies whether there is already a stay-at-home-dad in the household
         [
           ask dying-agent [set male-caretaker-found? true]
           ] ; closes if SAHD
         ] ; closes ask poss-male-carers #1

  if not male-caretaker-found?
  [
    ask poss-male-carers
    [
      if not [male-caretaker-found?] of dying-agent ; The male-caretaker-found? component ensures that only one male will be designated as a caretaker in the event that a household
                                                    ; contains more than one adult male
      [
      ask dying-agent
      [set male-caretaker-found? true]
        if [children-under-five?] of dying-agent
        [
          ifelse (occ-type = 3 or occ-type = 4) ; pastors and doctors are not allowed to be caretakers of preschool-aged children
          [ask dying-agent [set male-caretaker-found? false]]
          [set stay-at-home-dad? true]
        ] ; closes children-under-five
    ] ; closes if not male-caretaker-found #2
  ] ; closes ask poss-male-carers #2
  ] ; closes if not male-caretaker-found #1
  ] ; closes if any?
end

; The send-to-orphanage method sends children to the orphanage and reassigns the agent's occupation and residence information.

to send-to-orphanage [new-orphans]
  ask new-orphans
  [
    ifelse age < 5 [set occupation 561]
    [set occupation 861]
    set occ-type floor (occupation / 100)
    set dwelling orphanage-id
    set household orphanage-hshld
  ]
end

; The choose-new-mom method first separates all adult women in a household into three sets on the basis of occ-type: 2, 5 & 6, and 9.
; Then a hierarchical strategy is used to select the substitute mother, with the choice first drawn from any available 9 agent,
; then a 2 agent, and then a 5 or 6.

to-report choose-new-mom [living-adults substitute-mom?]
  let dying-agent self
  let women-subs2 (turtle-set living-adults with [sex = 1 and age > 15 and household = [household] of dying-agent
      and occ-type = 2])
  let women-subs56 (turtle-set living-adults with [sex = 1 and age > 15 and household = [household] of dying-agent
      and (occ-type = 5 or occ-type = 6)])
  let women-subs9 (turtle-set living-adults with [sex = 1 and age > 15 and household = [household] of dying-agent
      and occ-type = 9])
  if any? women-subs9
  [
    ask one-of women-subs9
    [
      set occupation [occupation] of dying-agent
      set occ-type [occ-type] of dying-agent
      set substitute-mom? true
    ]
  ]
      if not substitute-mom?
      [
        if any? women-subs2
        [
          ask one-of women-subs2
          [
            set occupation [occupation] of dying-agent
            set occ-type [occ-type] of dying-agent
            set substitute-mom? true
          ]
        ]
      ]
      if not substitute-mom?
      [
        if any? women-subs56
        [
          ask one-of women-subs56
          [
            set occupation [occupation] of dying-agent
            set occ-type [occ-type] of dying-agent
            set substitute-mom? true
          ]
        ]
      ]
      report substitute-mom?
end

; The choose-pastor method chooses a fisherman over aged 30 from a boat with at least 3 fishermen in it. The new pastor must
; also be assigned to the same church.

to-report choose-pastor [living-adults substitute-pastor?]
  let dying-agent self
  let pastor-subs (turtle-set living-adults with [occ-type = 1 and age > 30 and church = [church] of dying-agent
      and not stay-at-home-dad?])
  if any? pastor-subs
  [
    ask pastor-subs
    [
      if not substitute-pastor? [
      let num-fishermen count living-adults with [sex = 0 and boat-id = [boat-id] of myself and occ-type = 1]
      if num-fishermen > 2
      [
        set occupation [occupation] of dying-agent
        set occ-type [occ-type] of dying-agent
        set substitute-pastor? true
      ]
      ]
    ]
  ]
    report substitute-pastor?
end

; The choose-from-fisherwomen picks a fisherwoman from any boat that has more than one fisherwoman currently assigned to it.
; The chosen fisherwoman's occupation is set to that of the calling agent.

to-report choose-from-fisherwomen [living-adults substitute-female-worker?]
  let dying-agent self
  let female-subs (turtle-set living-adults with [occ-type = 2])
   if any? female-subs
  [
    ask female-subs
    [
      if not substitute-female-worker? [
      let num-fisherwomen count living-adults with [sex = 1 and boat-id = [boat-id] of myself and (occ-type = 0 or occ-type = 2)]
      if num-fisherwomen > 1
      [
        set occupation [occupation] of dying-agent
        set occ-type [occ-type] of dying-agent
        set substitute-female-worker? true
      ]
      ]
    ]
  ]
    report substitute-female-worker?
end

; Replacement orphanage workers are first chosen from older girls already living at the orphanage. If a suitable one
; is not found, an available fisherwoman is chosen.

to-report choose-orph-worker [living-adults substitute-orph-worker?]
  let dying-agent self
  let orph-subs (turtle-set living-adults with [occupation = 561 and sex = 1])
  ifelse any? orph-subs
  [
    ask one-of orph-subs
    [
      set occupation [occupation] of dying-agent
        set occ-type [occ-type] of dying-agent
        set substitute-orph-worker? true
    ]
  ]
  [
    set substitute-orph-worker? choose-from-fisherwomen living-adults substitute-orph-worker?
    ]
  report substitute-orph-worker?
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Data Collection and Display Update Methods;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to update-daily-output
  tally
  record-ticks
  draw-plots
  write-to-daily-file
end

to tally
  set num-susceptible count SAagents with [disease-status = 0]
  set num-exposed count SAagents with [disease-status = 1]
  set num-infectious count SAagents with [disease-status = 2]
  set num-recovered count SAagents with [disease-status = 3]
  set num-dead count ghosts
  set RD num-recovered + num-dead ; size of epidemic
  set SRD num-susceptible + RD ; should equal total population size if the epidemic concluded by the time the simulation ended
end

to record-ticks
  let current-tick ticks + 1
  ifelse num-infectious > peak-number
    [set peak-number num-infectious
     set peak-tick-list [] ; clears list
     set peak-tick-list (list current-tick)] ; since only 1 number added here, (list ...) is needed to declare the variable type
    [if num-infectious = peak-number [set peak-tick-list lput current-tick peak-tick-list]]

  if SRD = pop-size and not final-tick-recorded? [
    set final-tick ticks ; the epidemic ended the previous tick, so the tick correction is not applied here
    set final-tick-recorded? true
  ]
end

to draw-plots
  set-current-plot "Course of epidemic"
  set-current-plot-pen "susceptibles"
  plot num-susceptible
  set-current-plot-pen "exposed"
  plot num-exposed
  set-current-plot-pen "infectious"
  plot num-infectious
  set-current-plot-pen "recovered"
  plot num-recovered
  set-current-plot-pen "dead"
  plot num-dead
end

to write-to-daily-file
  file-open "St_Anthony_flu_Daily.csv"
  file-type (word behaviorspace-run-number ", ")
  file-type (word (ticks + 1) ", ") ; The Netlogo clock starts at tick 0. One tick is added in data recording
                                    ; so that model events start at time 1 instead of time 0. For example, the
                                    ; first tick that the initial case is infectious is latent period + 1, i.e. tick 7
                                    ; if the latent period is 6 days. This also ensures that the data recording is
                                    ; consistent with the visualization.
  file-type (word pop-size ", ")
  file-type (word transmission-prob ", ")
  file-type (word death-prob ", ")
  file-type (word latent-period ", ")
  file-type (word infectious-period ", ")
  file-type (word first-case ", ")
  file-type (word first-case-occ ", ")
  file-type (word num-susceptible ", ")
  file-type (word count SAagents with [newly-infected?] ", ")
  file-type (word num-exposed ", ")
  file-type (word num-infectious ", ")
  file-type (word num-recovered ", ")
  file-type (word count ghosts with [newly-dead?] ", ")
  file-type (word num-dead ", ")
  file-print (word start-tick ", ")
  file-close
end

to update-final-output
  let earliest-peak min peak-tick-list
  let latest-peak max peak-tick-list
  set peak-tick (earliest-peak + latest-peak) / 2 ; Note: may think about averaging the entire list
;  write-to-cases-file
  write-to-final-file
end

to write-to-cases-file
  file-open "St_Anthony_flu_Cases.csv"
  foreach sort-on [agt-id] SAagents [ [?1] ->
  ask ?1 [
  file-type (word behaviorspace-run-number ", ")
  file-type (word (ticks + 1) ", ") ; See comment above in the write-to-daily-file method.
  file-type (word pop-size ", ")
  file-type (word transmission-prob ", ")
  file-type (word death-prob ", ")
  file-type (word latent-period ", ")
  file-type (word infectious-period ", ")
  file-type (word first-case ", ")
  file-type (word first-case-occ ", ")
  file-type (word agt-id ", ")
  file-type (word dwelling ", ")
  file-type (word occupation ", ")
  file-type (word infector-id ", ")
  file-type (word infector-dwelling ", ")
  file-type (word infector-occ ", ")
  file-type (word time-infected ", ")
  file-type (word place-infected ", ")
  file-type (word time-died ", ")
  file-type (word place-died ", ")
  file-print (word start-tick ", ")
  ]
  ]
  file-close
end

to write-to-final-file
  file-open "St_Anthony_flu_Final.csv"
  file-type (word behaviorspace-run-number ", ")
  file-type (word (ticks + 1) ", ") ; See comment above in the write-to-daily-file method.
  file-type (word pop-size ", ")
  file-type (word transmission-prob ", ")
  file-type (word death-prob ", ")
  file-type (word latent-period ", ")
  file-type (word infectious-period ", ")
  file-type (word first-case ", ")
  file-type (word first-case-occ ", ")
  file-type (word peak-number ", ")
  file-type (word peak-tick-list ", ")
  file-type (word peak-tick ", ")
  file-type (word final-tick ", ")
  file-type (word num-susceptible ", ")
  file-type (word num-recovered ", ")
  file-type (word num-dead ", ")
  file-type (word RD ", ")
  file-type (word SRD ", ")
  file-print (word start-tick ", ")
  file-close
end
@#$#@#$#@
GRAPHICS-WINDOW
271
11
979
720
-1
-1
7.0
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
99
0
99
1
1
1
ticks
30.0

BUTTON
26
89
92
122
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
108
90
171
123
step
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
191
90
254
123
run
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
53
141
226
174
latent-period
latent-period
0
60
6.0
6
1
ticks
HORIZONTAL

SLIDER
53
190
226
223
infectious-period
infectious-period
0
60
18.0
6
1
ticks
HORIZONTAL

SLIDER
53
239
226
272
transmission-prob
transmission-prob
0
1
0.042
0.001
1
NIL
HORIZONTAL

SLIDER
53
288
226
321
death-prob
death-prob
0
1
7.6E-4
0.00001
1
NIL
HORIZONTAL

PLOT
1014
93
1563
583
Course of epidemic
tick
number of agents
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"susceptibles" 1.0 0 -14439633 true "" ""
"exposed" 1.0 0 -1184463 true "" ""
"infectious" 1.0 0 -2674135 true "" ""
"recovered" 1.0 0 -13791810 true "" ""
"dead" 1.0 0 -11053225 true "" ""

SLIDER
58
349
230
382
church-density
church-density
0
1
1.0
.01
1
NIL
HORIZONTAL

SLIDER
55
415
227
448
run-length
run-length
0
1000
600.0
100
1
ticks
HORIZONTAL

SLIDER
56
480
228
513
start-tick
start-tick
1
42
1.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
# Netlogo version of SAmort model

Version date: June 2014

Authors: Lisa Sattenspiel, Jessica Dimka, Erin Miller, and Becca Lander,  University of Missouri Columbia, Department of Anthropology

Dana Schmidt also worked on this model in its early stages, and Carolyn Orbann helped develop the original agent-based model on which this model is based.


## INTRODUCTION

The SAmort model is an epidemiological model designed to test hypotheses related to the spread of the 1918 influenza pandemic among residents of a small fishing community in Newfoundland and Labrador. The model community is based on the 1921 census population of St. Anthony, NL, located on the tip of the Northern Peninsula of the island of Newfoundland. Model agents are placed on a map-like grid that consists of houses, two churches, a school, an orphanage, a hospital, and several boats. They engage in daily activities that reflect known ethnographic patterns of behavior in St. Anthony and other similar communities. A pathogen is introduced into the community and then it spreads throughout the population as a consequence of individual agent movements and interactions.


## MODEL INITIALIZATION

During the set-up procedure, the agent and map variable files are read in, the community layout and visualization are established, data output files are created, and variables for recording epidemic data are initialized. The first case (or cases, if desired) are selected. Users may decide whether to select a first case at random or according to certain criteria (e.g. an agent of a particular sex, age or occupation type).


## EXTERNAL INPUT FILES

The model requires the use of two external input files, one to read in essential agent characteristics, and one to read in building characteristics. To facilitate explorations of the impact of population size on epidemic outcomes, we have made a number of different agent files and associated building files corresponding to target population sizes. In making different sized agent populations, households are kept together. Each larger population includes all agents from the smaller population files, with newly added households chosen randomly from among remaining households included in the full population until the target population size is reached. Church membership is adjusted to retain about a 50:50 ratio in all population sizes. Building sizes (other than houses and boats) are also adjusted in proportion to the relative population size so that the population density within the buildings remains relatively constant. Because agents can repeatedly attempt to visit empty houses in small population runs, we eliminated from the building files all houses without any assigned agents. To retain average crew sizes for the boats and the possibility of contact between adjacent boats, we also reduced the number of boats proportionately and reassigned agents if necessary. The numbers of agents assigned to specialized occupations such as doctors, nurses, or teachers, are also, in general, kept proportional to the target population size. Specific agents assigned to these professions may vary across agent files. We always assume that there are two churches, however, so all population sizes include only two pastors.

### AGENT CHARACTERISTICS

Agent definition files (SAmortAgents500NL.txt and other similar files for different population sizes) include the following variables:

1. The first column of this file is the user-determined agent ID.

2. Column 2 is residence; this variable refers to the community in which an agent normally resides (e.g., 1 = St. Anthony). This variable is not used in the model at the present time because only a single community is being modeled. It is designed to facilitate the incorporation of additional communities at a future date.

3. Column 3 is an agent's disease status. Currently this variable is initialized at zero for all agents; the program picks an initial infected or exposed agent (or agents) and resets its disease status accordingly (0=susceptible, 1=exposed, 2=infected, 3=recovered, 4=dead).

4. Column 4 is the dwelling of an agent. This is the agent's home base. It is assigned sequentially based on information in the 1921 St. Anthony census data (but could be set arbitrarily if desired) and the assigned numbers correspond to particular buildings on the model space. For example, individuals assigned to dwelling #35 will use building #35 as their home unless no spaces are available, in which case the program reassigns a new permanent dwelling. Orphans indicated as such in the census are assigned to dwelling #85, which corresponds to the orphanage (building #85); children under age 15 who must be reassigned because of a lack of space in their assigned dwelling are assigned to the orphanage (adult agents are assigned randomly to another house).

5. Column 5 is the household of an agent and is an integer variable that corresponds to the family number to which an agent is assigned. This variable is assigned sequentially based on information in the 1921 St. Anthony census. In the census data, households may include individuals other than family members (e.g., servants, boarders, others living there). Multiple households may share a dwelling.

6. Column 6 designates extended family membership.  The variable allows connections between related individuals from different households. Since at this time we have little information on family connections beyond a household listed in the census, in the input data files, ext-family is set at 0 for all agents.

7. Column 7 indicates sex of an agent (0 = male, 1 = female). The assigned sex corresponds to information recorded in the census data.

8. Column 8 designates an agent's age in years.

9. Column 9 designates church membership of an agent. In the input data files, agents are arbitrarily and relatively equally divided by household into two church groups, with the exception that all orphans age 15 and older are assigned to the same church. However, the majority of orphans (all those < age 15) attend Sunday services within the orphanage and are assigned to neither of the other churches.

10. Column 10 corresponds to an agent's relative health status. This variable is designed to take into account different possible influences that may impact an agent's outcome when faced with a potential disease-transmitting contact. At present, this variable can range from -1 to 1, with -1 corresponding to a maximum negative impact (i.e., 100% reduction), 0 corresponding to no impact on health, and 1 corresponding to a maximum positive impact. In the current input data files, health-history is set at 0 for all agents because this is something that will be incorporated into the model later.

11. Column 11 designates an agent's occupation.  This variable is user-defined and influences the activity patterns of agents. All agents have been assigned a 3-digit occupation code.  The assignment rubric is described in the section on  occupation categories.

12. Column 12 designates the ID of the boat associated with an agent's household. All agents in households with some fishermen are assigned the specific boat ID of the family fishing boat, regardless of their occupation. In the case that no agents in a household are involved in fishing (e.g., orphanage workers or a house full of doctors), agents are assigned a boat ID of 999.


### BUILDING CHARACTERISTICS

The present model has seven building types that we have designed to reflect important places in St. Anthony, our study community: houses, orphanages, schools, hospitals, churches, and two boat types (to provide two colors for the boats). The number of buildings of each type is calculated by the program as the community map is initialized. Building definition files (SAmortBldgs500NL.txt and other similar files for different population sizes) include the following variables:

1. Columns 1 and 2 give the coordinates of the lower left hand cell of a building (x-coordinate, then y-coordinate).

2. Columns 3 and 4 give the dimensions of the building (width, then length). NOTE: SCHOOL DIMENSIONS SHOULD BE LARGE ENOUGH TO FIT NOT ONLY ALL CHILDREN ASSIGNED TO A SCHOOL, BUT ALSO ALL THE TEACHERS.

3. Column 5 is the building ID, assigned by the user. NOTE: THE BUILDING IDS OF THE BOATS MUST CORRESPOND TO THE BOAT ID GIVEN TO THE AGENTS  (column 12 of the agent files).

4. Column 6 designates the building type (house=1, orphanage=2, school=3, hospital=4, church=5, boat type 1 = 6, boat type 2 = 7).


## ESSENTIAL PARAMETERS

The model consists of a number of sliders that can be used to adjust the values of essential parameters. At the present time all parameters are set at constant values. Eventually some parameters other than run length and population size may be modeled using a probability distribution rather than constant values. The slider variables include the following:

1. Length of latent period: This is the number of time ticks that an agent remains in the exposed category. The slider is set up to range from 0 to 60 ticks (0 to 10 days in the present model). A reasonable baseline value of 6 ticks (1 day) was derived from an assessment of various values published in the influenza literature (e.g., Mills et al. 2004, Cori et al. 2012).

2. Length of infectious period: This is the number of time ticks that an agent remains infectious. This slider is also set up to range from 0 to 60 ticks (0 to 10 days in the present model). A baseline value of 18 ticks (3 days) was derived from an assessment of various values published in the influenza literature (e.g., Mills et al. 2004, Cori et al. 2012).

3. Transmission probability: This slider is set up to range between 0 and 1 and corresponds to the probability of transmission when a contact occurs between susceptible and infectious agents. A baseline value of 0.042 was chosen to achieve a target attack rate of 55% prevalence for simulation runs, as suggested for the 1918 influenza epidemic by Ferguson et al. (2004).

4. Probability of death: This slider also ranges from 0 to 1 and corresponds to the probability of death per tick. Death can only occur in the model during the infectious period. The baseline estimate of the death probability was derived by setting the observed case fatality rate (cfr) equal to (1- (1 - d)^i), where d is equal to the probability of death per tick and i is the length of the infectious period in ticks. The quantity (1-d)^i gives the overall probability of NOT dying throughout the period of risk. When this value is subtracted from 1 it gives the cfr (overall probability that an infected individual dies at some time during the infectious period). The equation is then solved for d to give the desired probability of dying PER TICK. For example, the observed death rate in Newfoundland during the 1918 flu was about 7.5 per thousand people. Using the attack rate of 55% estimated by Ferguson, et al. (2004), this converts to a cfr of 13.6 deaths per thousand cases (or 0.0136). So, assuming an infectious period of 18 ticks (3 days), 1 - (1 - d)^18 = 0.0136. The solution to this equation gives a per tick probability of death of 0.00076. NOTE: the model at present assumes that an agent is at risk of dying only when it is infectious and that the risk is equal for each tick it is infectious.

5. Church density: This parameter allows the user to adjust the packing in the church to better model heterogeneity in attendance at different times. A value of 1 means that every cell in the church can be occupied during a service; smaller values indicate the maximum proportion of seats taken up. At present, the model assumes that both churches have the same density of occupants; users who wish to change this would need to add church-specific parameters for the density.

6. Run length: This is the number of time ticks the simulation will be run.


##OCCUPATION CATEGORIES

All occupations have been assigned a 3-digit number.  The first digit corresponds to the general type of occupation (designated the occ-type); the other two digits identify individual groups within that general occ-type in some way. Agents are assigned to different occupations primarily on the basis of age and sex, but information found in archival records is also used. The overall classification is as follows:

0xx (occ-type 0) -- female with only school-aged children, at least some of whom are under age 10. They are associated with a male fisherman in boat xx and are assigned to the same boat as their associated male. They behave like 2xx females on weekdays, but like 7xx females on weekends.

1xx (occ-type 1) -- male fisherman; xx refers to the particular boat to which the agent is assigned. The full complement of agents is distributed into 23 boats; smaller population sizes incorporate a reduced number of actively used boats. Surname and/or proximity in the census data were used to assign agents to boats. Ethnographic data suggest that 4-8 men would cooperate for fishing purposes, so that was the target range for the number of men assigned to a particular boat.

2xx (occ-type 2) -- female associated with a male fisherman in boat xx. Agents in this category live in a fisherman's household and may include wives who only have children over age 10, unmarried daughters older than school age, or other adult females with no or grown children. Census data indicate that about 40 St. Anthony females were involved in the fishing activities in some way. All females fitting the criteria above who are not otherwise occupied (e.g., nurse, teacher, servant, or mother's helper) are assigned to this category. These females are not assumed to engage in fishing activities every day; thus, they move to the boats with some probability less than 1 (as specified in the code by the user). Other options during fishing time periods are staying at home or visiting other households.

3xx (occ-type 3) -- clergy and teachers. The census lists 3 clergy and 2 teachers, but since we only have modeled 2 churches, we have designated only 2 clergy, both of whom are male. These men have been given an occupational ID of 311, with the middle digit indicating their status as religious leaders.  One of the men is assigned to church 1, the other to church 2. During the week, both function as teachers at the school. One pastor is explicitly noted in the census data, the other was chosen on the basis of age (50+) and status as a boarder. We also chose additional teachers from among unmarried women in their 20s (total number of teachers based on population size). These women are assigned an occupational ID of 321. For now, we are assigning all pastors and teachers to school #1 since that is the only school we have. If, or when, we decide to add a second school, e.g., a high school, then we can change some of the occupational codes so that the third digit corresponds to the school at which the agent teaches.

4xx (occ-type 4) -- medical. Two known doctors (Grenfell and Curtis) were listed in the census; in addition, historical evidence indicates that Grenfell would recruit young medical students from the US and other places to assist in his medical mission.  These students would board with local families. Males fitting these criteria (i.e., young male boarders) were preferentially assigned to be doctors if they were among the agents chosen for a population sample of a particular size.  Doctors and med students were assigned an occupational ID of 411. Some young, unmarried women were designated to be nurses; these individuals were given an occupational ID of 421. The total number of doctors and nurses was adjusted as population size changed so that a fairly constant ratio of medical personnel to general population was retained.

5xx (occ-type 5)  -- associated with orphanage, not including school-aged kids. This group consists of four different subgroups: a) probable caretakers who lived outside the orphanage (evidence from historical sources indicates this status) -- code 551, b) orphans older than 15; almost all female - ethnographic evidence suggests they stayed at the orphanage to develop "homemaking" and other kinds of useful skills until they married or moved elsewhere -- code 561, c) children under 5 - too young for the school, assumed to stay at the orphanage under the care of the older girls -- code 561, d) industrial worker - designation given to last person listed in census; we do not know what this refers to exactly, so we assumed it involved activities at the orphanage training the older girls -- code 571.

6xx (occ-type 6) -- servants. All servants were indicated as such in the census; all except one were associated with a fisherman's household. These servants were given an occupational ID of 6xx, where xx is the boat number of the household. The remaining servant was at the end of the census and was placed in a group with Dr. Curtis, a nurse, and the industrial worker.  We assigned this servant an occupational ID of 671 to distinguish her from the other servants. NOTE: In Newfoundland and Labrador the word servant could refer to individuals indentured to others for various types of labor, although in the model, because of the small number of servants in the census data, we have assumed that all of them were household servants.

7xx (occ-type 7) -- female caretakers with at least one child under age 5; usually wives of fishermen. Also includes one single mother living in a dwelling that includes another household. The last two digits of the ID correspond to the household's assigned boat. Agents in this category move together every day with individuals in category 9xx who have the same xx assignment and household; school-aged children and fishermen from that household may also move with them under the appropriate conditions (e.g., church or Sunday visiting).

8xx (occ-type 8) -- school-aged children (aged 5-15). All school-aged children are assigned an occupational ID of 8xx. The xx indicates the fishing boat of their household, if it is a fishing household.  School-aged orphans are assigned an occupational ID of 861, corresponding to the 561 of the non-school-aged orphanage children; the xx of school-aged children in non-fishing households corresponds to the xx in the occupational code of the head of that household.

9xx (occ-type 9) -- this category includes preschool-aged children, unmarried daughters older than school age, sisters or sisters-in-law, and mothers or mothers-in-law of 7xx women; all of these category 9 agents live in the household of the associated 7xx woman. Adult females are given this code only if the number of small children in the family is large (under the assumption that they would help out with child care). The last two digits of the ID for individuals in this category corresponds to the xx in the occupational code of the head of that household.


## STEP-DEPENDENT PROCEDURES

The general structure of the go procedure follows. The information in quotes at the end of each component gives the section in which more information can be found.

1. a randomly chosen turtle determines the daily time block corresponding to the current tick of the model ("schedule");
2. all living SAagents update their disease status (susceptible, exposed, infectious, recovered, dead) ("disease-related procedures");
3. all living SAagents engage in appropriate activities determined by their occ-type and the specific time block corresponding to the current tick of the model ("schedule" and "movement-related procedures");
4. the SAagents with appropriate disease statuses determine to or from whom they might transmit the disease ("disease-related procedures");
5. newly dead ghosts find substitutes for their community roles (if necessary) and reassign any dependent children to new caretakers or the orphanage as appropriate ("death-related procedures");
6. data output files and interface plots are updated ("display and output procedures").


###SCHEDULE

The program is set up for six time ticks per day with each time tick 4 hours long. A series of statements using the variable timekeeper sets up a schedule within which agent activities will occur. A day is divided into the following time slots: 6-10am, 10am-2pm, 2-6pm, 6-10pm, 10pm-2am, and 2-6am. Values of timekeeper between 1 and 6 correspond to these 6 slots (in the order listed) on Mondays through Fridays; values of timekeeper between 7 and 12 correspond to these 6 slots on Saturdays; values of timeKeeper between 13 and 18 correspond to these 6 slots on Sundays.

The findDaysActivities method sends an agent to the proper activities for the specific time tick indicated by the timekeeper variable (and designated by the specific do…acts method for that time tick). Although there are 6 time slots per day, we do not include the last two for each day since no activity is occurring during those times in the present model (eventually at least some medical personnel may be active at night).


###MOVEMENT-RELATED PROCEDURES

The model contains a specific do…acts method for each of the time slots other than 10pm-2am and 2am-6am (when agents are assumed to sleep). These methods specify particular behaviors for agents based on their occ-type and sometimes specific occupation. These particular behaviors all involve some type of move method. The model contains 6 different basic move methods: move-home, move-school, move-hospital, move-orphanage, move-boat, move-Sunday, and a number of sub-methods required to complete those basic movements. The movement of occ-type 9 individuals is generally governed by the primary caretaker in the household, typically a female assigned to occ-type 7; other agents sometimes move on their own and sometimes move as part of a family group (see code for individual methods).


###DISEASE RELATED PROCEDURES

The underlying disease transmission model in this simulation is an SEIR epidemic process. All agents begin the simulation in the susceptible state, and then the status of one randomly chosen agent is set to "exposed". The specification of multiple initial infected individuals or specific types of initial cases can be made through simple adjustments of the "infect-first-case" method. Consistent with the SEIR epidemic process, exposed agents convert to the infectious state after a user-specified latent period, which they remain in until recovery (after a user-specified infectious period) or death (which occurs with a user-specified probability during each tick of the infectious period). Immunity is permanent upon recovery. The "update-disease-status" method governs this series of transitions.

Disease transmission can occur between susceptible-infectious pairs of agents that are adjacent to each other on the grid. Agents are considered to be adjacent if they are von Neumann neighbors, i.e., those to the north, south, east, or west. When an agent moves it checks its own disease status as well as that of its neighbors. If a moving agent is susceptible, it calls the method "transmit-from" for all infectious neighbors; if it is infectious, it calls "transmit-to" for all susceptibles. In both cases, transmission is determined by comparing the user-specified transmission probability to a randomly chosen number between 0 and 1. If transmission occurs, the status of the susceptible agent(s) is set to "exposed" and the clock for the disease process begins.


###DEATH-RELATED PROCEDURES

Death of an agent -- agents have a set probability of dying at each tick of the infectious period. Upon death, a ghost (a different turtle breed) with the same agent characteristics as the dying agent is made and data about where and when the agent died are collected. The agents move to a "cemetery" (lower left-hand corner of the grid); the ghosts remain at the location of death. Users can control whether the ghosts are visible or hidden. Each dying agent also takes the shape of a ghost, with the size proportional to the number of agents that have died. Thus, the ghost that appears in the cemetery gets larger as the epidemic progresses.

Reassigning occupation -- any dying caretakers must arrange for another adult member of the household to become the new caretaker for dependent children. If the new caretaker is a male who becomes responsible for preschool-aged children, he becomes a stay-at-home-dad. He retains his fisherman occupation, but does not go to the boats as long as he continues to be responsible for children under age 5. If no suitable caretaker replacement is identified, children are sent to the orphanage. Any dying children with a stay-at-home-dad (SAHD) need to determine whether they have surviving siblings under age 5 and if not, arrange for their SAHD to return to previous activities, e.g. fishing. Female caretakers retain their existing status throughout the rest of the simulation, even if all children die. Dying agents who are engaged in critical occupations (e.g., teachers, pastors, etc.) are also replaced by appropriate agents. The choice of replacement for a dying agent is governed by specific criteria determined by the occupation/status of both the dying agent and the potential replacement. See specific "choose…" and "find-poss…" methods for details. If no suitable replacement for critical occupations is found, no replacement is made and a statement to that effect is printed to the console. After a replacement is specified, occupation, occ-type, dwelling, and other relevant variables are adjusted as needed to reflect the new role of the agent.


###DISPLAY AND OUTPUT PROCEDURES

As the simulation proceeds, a graph showing the numbers of susceptible, exposed, infectious, recovered, and dead agents is created and updated each tick. In addition, three csv (comma-delimited) output files are produced (CasesData.csv, DailyData.csv, and FinalData.csv). In each file, run numbers, global parameters (e.g. transmission probability), and attributes of the first case are always recorded. The “Cases” file also records, for all individuals in the model population, the place and time the individual was infected (the default value of -1 is recorded if the individual escapes the simulated epidemic), and if applicable, the place and time it died as well as characteristics of the agent that infected this individual. The “Daily” file records the number of individuals in each disease status at each tick of the simulation and keeps track of the number of agents that are newly infected and newly dead. The “Final” file records the total number of individuals in each disease status at the end of the simulation, the total number of individuals ever infected [RD], and a count to verify all members of the model community were either susceptible or removed (recovered or dead) [SRD]. This last count provides an easy way to determine that the simulated epidemic finished in the allotted time; in that case the count will equal the total population size.


###SUGGESTED SOURCES

##REFERENCES CITED

Cori A, Valleron AJ, Carrat F, Scalia Tomba G, Thomas G, Boëlle PY (2012) Estimating
influenza latency and infectious period durations using viral excretion data. Epidemics
4:132–138

Ferguson NM, Cummings DAT, Cauchemez S, Fraser C, Riley S, Meeyai A, Iamsirithaworn S,
Burke DS (2005) Strategies for containing an emerging influenza pandemic in Southeast
Asia. Nature 437(7056):209–214

Mills CE, Robins JM, Lipsitch M (2004) Transmissibility of 1918 pandemic influenza. Nature 432:904–906


##PAPERS USING THE MODEL

Dimka, Jessica, Carolyn Orbann, and Lisa Sattenspiel (2014) Applications of agent-based modeling techniques to studies of historical epidemics: the 1918 flu in Newfoundland and Labrador. Journal of the Canadian Historical Association, New Series 25(2):265-296.

Sattenspiel, Lisa, Erin Miller, Jessica Dimka, Carolyn Orbann, and Amy Warren (2016) Epidemic models with and without mortality: when does it matter? In Mathematical and Statistical Modeling for Emerging and Re-emerging Infectious Diseases, Gerardo Chowell and James M Hyman (eds.) Switzerland: Springer International, pp. 313-327. http://dx.doi.org/10.1007/978-3-319-40413_2.

Orbann, Carolyn, Lisa Sattenspiel, Jessica Dimka, and Erin Miller (2017) Defining epidemics in computer simulation models: how do definitions influence conclusions? Epidemics 19:24-32. http://dx.doi.org/10.1016/j.epidem.2016.12.001

Orbann, Carolyn, Lisa Sattenspiel, Jessica Dimka, and Erin Miller (2014) Agent-based modeling and the second epidemiological transition. In Modern Environments and Human Health: Revisiting the Second Epidemiologic Transition, Molly K Zuckerman (ed). Hoboken, NJ: Wiley-Blackwell, pp. 105-122.


## ACKNOWLEDGEMENTS

The code for this model was adapted from a Repast model developed by Lisa Sattenspiel, Carolyn Orbann, Jessica Dimka, and Erin Miller at the University of Missouri. The code for reading in the external tab-delimited files that contain building and agent characteristics was modified from code written by Uri Wilensky and submitted to Netlogo's model library. He has waived all copyright and related or neighboring rights to the sample code.
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

ghost
false
0
Polygon -7500403 true true 30 165 13 164 -2 149 0 135 -2 119 0 105 15 75 30 75 58 104 43 119 43 134 58 134 73 134 88 104 73 44 78 14 103 -1 193 -1 223 29 208 89 208 119 238 134 253 119 240 105 238 89 240 75 255 60 270 60 283 74 300 90 298 104 298 119 300 135 285 135 285 150 268 164 238 179 208 164 208 194 238 209 253 224 268 239 268 269 238 299 178 299 148 284 103 269 58 284 43 299 58 269 103 254 148 254 193 254 163 239 118 209 88 179 73 179 58 164
Line -16777216 false 189 253 215 253
Circle -16777216 true false 102 30 30
Polygon -16777216 true false 165 105 135 105 120 120 105 105 135 75 165 75 195 105 180 120
Circle -16777216 true false 160 30 30

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

wolf
false
0
Polygon -7500403 true true 135 285 195 285 270 90 30 90 105 285
Polygon -7500403 true true 270 90 225 15 180 90
Polygon -7500403 true true 30 90 75 15 120 90
Circle -1 true false 183 138 24
Circle -1 true false 93 138 24

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
  <experiment name="Rep Set" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="latent-period">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infectious-period">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run-length">
      <value value="600"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission-prob">
      <value value="0.043"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="church-density">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-prob">
      <value value="7.6E-4"/>
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

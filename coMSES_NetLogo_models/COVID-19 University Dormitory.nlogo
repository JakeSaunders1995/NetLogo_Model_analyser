breed [students student]
breed [elevators elevator]
breed [hallways hallway]
breed [canteenLines canteenLine] ; assume 2 canteens, 15 lines total

globals [
  day
  hour
  minute
  current-time
  num-exposed
  num-infectious
  num-quarantined
  num-visits

  num-infected-from-elevator
  num-infected-from-roommate
  num-infected-from-ground-floor
  num-infected-from-hallway
  num-infected-from-canteen
  num-infected-from-visit
  visitsPerTick

  pBreakfast
  pLunch
  pDinner

  incubation-mean
  incubation-stdev
  calculated-incubation-time

  firstQuarantineTime
  dummyroom
  dummyfloor
  dummybuilding
  dummyelevator
  dummyline
  totalPopulation
  sigma
  mu
  #a
  #b
  #c
  FC
  U
  first-infection
  result
]


students-own [
  SEIQ ; Susceptible(normal), Exposed(incubation, might not have symptoms), Infectious(showing symptoms), and Quarantined(go to hospital)
  building-number
  floor-number
  room-number
  line-number
  eatenBreakfast?
  eatenLunch?
  eatenDinner?
  incubation-time
  infectious-duration
  mask?
  protectionLevel
  returned?
  group
  getTakeout?
  infectionChance
  visitToday?
]


elevators-own [building-number
  elevator-number
  virus?]
hallways-own [building-number
  floor-number
  virus?]
canteenLines-own [line-number
  virus?]


to setup ; set global variables
  clear-all
  reset-ticks
  set totalPopulation population * 3 * 984
  add-students
  add-elevators
  add-hallways
  add-canteenLines
  set num-quarantined 0 ; number of Q student
  set num-infectious 0  ; number of I student
  set num-exposed 0
  set num-infected-from-elevator 0 ; number of students infected in elevators
  set num-infected-from-canteen 0
  set num-infected-from-hallway 0
  set num-infected-from-ground-floor 0
  set num-infected-from-roommate 0
  set num-visits 0

  set pBreakfast 100 ; probability to eat breakfast
  set pLunch 100 ; probability to eat lunch
  set pDinner 100 ; probability to eat dinner

  set #a 0.8
  set #b 2.3
  set #c 3
  set first-infection -1
end

to add-students

  create-students totalPopulation  [setxy random-xcor random-ycor]

  ask students [set SEIQ "S"
                set building-number 0
                set floor-number 0
                set room-number 0
                set infectionChance 0
                set incubation-time "N/A"
                set infectious-duration "N/A"
                set line-number 0
                set eatenBreakfast? false
                set eatenLunch? false
                set eatenDinner? false
                set protectionLevel 1 ; 1 means no protection at all, 0 means best protection
                set returned? true]

  ask n-of round (percentMask * totalPopulation) students [set mask? true set protectionLevel 0.32] ; corresponds to 68% intervention effectivness


  if population = 1 [
  ifelse Density = 2 [ ; 18 * 2 = 36

    (foreach [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18] [[a] -> foreach [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26] [[b] ->
    ask n-of Density students with [building-number = 0] [set room-number a set floor-number b set building-number 1]]])  ; He 1: 25 floors, 12 rooms on each floor, 3 elevators

    (foreach [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18] [[a] -> foreach [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26] [[b] ->
    ask n-of Density students with [building-number = 0] [set room-number a set floor-number b set building-number 2]]])  ; He 2: 25 floors, 12 rooms on each floor, 3 elevators

    (foreach [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18] [[a] -> foreach [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17] [[b] ->
    ask n-of Density students with [building-number = 0] [set room-number a set floor-number b set building-number 4]]])  ; He 4: 16 floors, 12 rooms on each floor, 2 elevators

    (foreach [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18] [[a] -> foreach [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17] [[b] ->
    ask n-of Density students with [building-number = 0] [set room-number a set floor-number b set building-number 5]]])  ; He 5: 16 floors, 12 rooms on each floor, 2 elevators
   ]
   [ ; 12 * 3 = 36

    (foreach [1 2 3 4 5 6 7 8 9 10 11 12] [[a] -> foreach [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26] [[b] ->
    ask n-of 3 students with [building-number = 0] [set room-number a set floor-number b set building-number 1]]])  ; He 1: 25 floors, 12 rooms on each floor, 3 elevators

    (foreach [1 2 3 4 5 6 7 8 9 10 11 12] [[a] -> foreach [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26] [[b] ->
    ask n-of 3 students with [building-number = 0] [set room-number a set floor-number b set building-number 2]]])  ; He 2: 25 floors, 12 rooms on each floor, 3 elevators

    (foreach [1 2 3 4 5 6 7 8 9 10 11 12] [[a] -> foreach [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17] [[b] ->
    ask n-of 3 students with [building-number = 0] [set room-number a set floor-number b set building-number 4]]])  ; He 4: 16 floors, 12 rooms on each floor, 2 elevators

    (foreach [1 2 3 4 5 6 7 8 9 10 11 12] [[a] -> foreach [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17] [[b] ->
    ask n-of 3 students with [building-number = 0] [set room-number a set floor-number b set building-number 5]]])  ; He 5: 16 floors, 12 rooms on each floor, 2 elevators
  ]]



  if population = 0.5 [
    (foreach [1 2 3 4 5 6 7 8 9 10 11 12] [[a] -> foreach [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26] [[b] ->
    ask n-of 3 students with [building-number = 0] [set room-number a set floor-number b set building-number 1]]])  ; He 1: 25 floors, 12 rooms on each floor, 3 elevators, N2 students in each room

    (foreach [1 2 3 4 5 6 7 8 9 10 11 12] [[a] -> foreach [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17] [[b] ->
    ask n-of 3 students with [building-number = 0] [set room-number a set floor-number b set building-number 5]]])  ; He 5: 16 floors, 12 rooms on each floor, 2 elevators, N2 students in each room
  ]

  if population = 2 [
    (foreach [1 2 3 4 5 6 7 8 9 10 11 12] [[a] -> foreach [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26] [[b] ->
    ask n-of 3 students with [building-number = 0] [set room-number a set floor-number b set building-number 1]]])  ; He 1: 25 floors, 12 rooms on each floor, 3 elevators, N2 students in each room

    (foreach [1 2 3 4 5 6 7 8 9 10 11 12] [[a] -> foreach [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26] [[b] ->
    ask n-of 3 students with [building-number = 0] [set room-number a set floor-number b set building-number 2]]])  ; He 2: 25 floors, 12 rooms on each floor, 3 elevators, N2 students in each room

    (foreach [1 2 3 4 5 6 7 8 9 10 11 12] [[a] -> foreach [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17] [[b] ->
    ask n-of 3 students with [building-number = 0] [set room-number a set floor-number b set building-number 4]]])  ; He 4: 16 floors, 12 rooms on each floor, 2 elevators, N2 students in each room

    (foreach [1 2 3 4 5 6 7 8 9 10 11 12] [[a] -> foreach [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17] [[b] ->
    ask n-of 3 students with [building-number = 0] [set room-number a set floor-number b set building-number 5]]])  ; He 5: 16 floors, 12 rooms on each floor, 2 elevators, N2 students in each room

    (foreach [1 2 3 4 5 6 7 8 9 10 11 12] [[a] -> foreach [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26] [[b] ->
    ask n-of 3 students with [building-number = 0] [set room-number a set floor-number b set building-number 11]]])  ; He 1: 25 floors, 12 rooms on each floor, 3 elevators, N2 students in each room

    (foreach [1 2 3 4 5 6 7 8 9 10 11 12] [[a] -> foreach [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26] [[b] ->
    ask n-of 3 students with [building-number = 0] [set room-number a set floor-number b set building-number 22]]])  ; He 2: 25 floors, 12 rooms on each floor, 3 elevators, N2 students in each room

    (foreach [1 2 3 4 5 6 7 8 9 10 11 12] [[a] -> foreach [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17] [[b] ->
    ask n-of 3 students with [building-number = 0] [set room-number a set floor-number b set building-number 44]]])  ; He 4: 16 floors, 12 rooms on each floor, 2 elevators, N2 students in each room

    (foreach [1 2 3 4 5 6 7 8 9 10 11 12] [[a] -> foreach [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17] [[b] ->
    ask n-of 3 students with [building-number = 0] [set room-number a set floor-number b set building-number 55]]])  ; He 5: 16 floors, 12 rooms on each floor, 2 elevators, N2 students in each room
  ]


  ask n-of N1 students [be-infected]
end

to add-elevators
  create-elevators 10
  ask elevators
    [set virus? false ht]

  (foreach [1 2] [[a] -> foreach [1 2 3] [[b] ->
  ask one-of elevators with [building-number = 0] [set building-number a set elevator-number b]]])
  (foreach [4 5] [[a] -> foreach [1 2] [[b] ->
  ask one-of elevators with [building-number = 0] [set building-number a set elevator-number b]]])

  if population = 2 [
    create-elevators 10
    ask elevators
      [set virus? false ht]

    (foreach [11 22] [[a] -> foreach [1 2 3] [[b] ->
    ask one-of elevators with [building-number = 0] [set building-number a set elevator-number b]]])
    (foreach [44 55] [[a] -> foreach [1 2] [[b] ->
    ask one-of elevators with [building-number = 0] [set building-number a set elevator-number b]]])
  ]


end

to add-hallways
  create-hallways 86
  ask hallways
    [set virus? false ht]

  (foreach [1 2] [[a] -> foreach [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26] [[b] -> ; remember to create ground floors
  ask one-of hallways with [building-number = 0] [set building-number a set floor-number b]]])
  (foreach [4 5] [[a] -> foreach [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17] [[b] ->
  ask one-of hallways with [building-number = 0] [set building-number a set floor-number b]]])

  if population = 2 [
    create-hallways 86
    ask hallways
      [set virus? false ht]

    (foreach [11 22] [[a] -> foreach [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26] [[b] -> ; remember to create ground floors
    ask one-of hallways with [building-number = 0] [set building-number a set floor-number b]]])
    (foreach [44 55] [[a] -> foreach [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17] [[b] ->
    ask one-of hallways with [building-number = 0] [set building-number a set floor-number b]]])
  ]
end

to add-canteenLines
  create-canteenLines 15
  ask canteenLines
    [set virus? false ht]
  (foreach [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15] [[a] ->
  ask one-of canteenLines with [line-number = 0] [set line-number a]])
end

to go ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  update-time

  ifelse allStudentsGoEat? = true [
    get-breakfast
    get-lunch
    get-dinner][takeout] ; takeout is when only one student goes to get food for all roommates

  if Density > 1 [
    infectRoommates]

  if percentVisit > 0 [
    visit-friend]

  update-SEIQ
  sanitize

  if day > 56  [stop] ; 8 weeks
  tick
end

to update-time
  set day floor (ticks / 48) + 1
  set hour floor ((ticks - (day - 1) * 48) / 2)
  ifelse remainder (ticks - (day - 1) * 48)  2 > 0
  [set minute 30] [set minute 00]
  set current-time ((ticks - (day - 1) * 48) / 2)
end

to get-breakfast

  if hour > 7 and hour <= 9 [
  ask students with [returned? = true and line-number != 0][
    set eatenBreakfast? true
    set infectionChance 1
    set line-number 0]]

  if hour >= 7 and hour < 9 [
    ask students with [returned? = true and eatenBreakfast? = false and line-number = 0]
      [if random-float 100 < pBreakfast / 3
        [set line-number ((random 14) + 1) ; randomly choose 1-15, avoid line 0
         set dummyfloor floor-number
         set dummybuilding building-number
         set dummyline line-number
         ifelse dummybuilding = 1 or dummybuilding = 2 [set dummyelevator (random 3) + 1][set dummyelevator (random 2) + 1]
         if SEIQ = "I" [infectCommonAreas]
         if SEIQ = "S" [infectFromCommonAreas]
  ]]]
end

to get-lunch

  if hour > 11 and hour <= 13 [
  ask students with [returned? = true and line-number != 0][
    set line-number 0
    set infectionChance 1
    set eatenLunch? true]]

  if hour >= 11 and hour < 13 [
    ask students with [returned? = true and eatenLunch? = false and line-number = 0]
      [if random-float 100 < pLunch / 3
        [set line-number ((random 14) + 1)
         set dummyfloor floor-number
         set dummybuilding building-number
         set dummyline line-number
         ifelse dummybuilding = 1 or dummybuilding = 2 [set dummyelevator (random 3) + 1][set dummyelevator (random 2) + 1]
         if SEIQ = "I" [infectCommonAreas]
         if SEIQ = "S" [infectFromCommonAreas]
  ]]]
end

to get-dinner

  if hour > 17 and hour <= 19 [
  ask students with [returned? = true and line-number != 0][
    set line-number 0
    set infectionChance 1
    set eatenDinner? true]]

  if hour >= 17 and hour < 19 [
    ask students with [returned? = true and eatenDinner? = false and line-number = 0]
      [if random-float 100 < pDinner / 3
        [set line-number ((random 14) + 1)
         set dummyfloor floor-number
         set dummybuilding building-number
         set dummyline line-number
         ifelse dummybuilding = 1 or dummybuilding = 2 [set dummyelevator (random 3) + 1][set dummyelevator (random 2) + 1]
         if SEIQ = "I" [infectCommonAreas]
         if SEIQ = "S" [infectFromCommonAreas]
  ]]]
end

to takeout ; sends one random student from each room to get takeout from canteen

  if hour = 8 or hour = 12 or hour = 18 [ ; only get food during these times

  (foreach [1 2 3 4 5 6 7 8 9 10 11 12] [[a] -> foreach [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26] [[b] ->
  ask up-to-n-of 1 students with [building-number = 1 and room-number = a and floor-number = b] [set getTakeout? true infectCommonAreas infectCommonAreas]]])

  (foreach [1 2 3 4 5 6 7 8 9 10 11 12] [[a] -> foreach [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26] [[b] ->
  ask up-to-n-of 1 students with [building-number = 2 and room-number = a and floor-number = b] [set getTakeout? true infectCommonAreas infectCommonAreas]]])

  (foreach [1 2 3 4 5 6 7 8 9 10 11 12] [[a] -> foreach [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17] [[b] ->
  ask up-to-n-of 1 students with [building-number = 4 and room-number = a and floor-number = b] [set getTakeout? true infectCommonAreas infectCommonAreas]]])

  (foreach [1 2 3 4 5 6 7 8 9 10 11 12] [[a] -> foreach [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17] [[b] ->
  ask up-to-n-of 1 students with [building-number = 5 and room-number = a and floor-number = b] [set getTakeout? true infectCommonAreas infectCommonAreas]]])
  ]
end

to infectCommonAreas ; only sick student can infect common areas with their virus
  repeat 2 [ ; repeated twice since round trip
    if random-float 100 < virusTransmit * protectionLevel [
      ask hallways with [floor-number = dummyfloor and building-number = dummybuilding]
        [set virus? true]]
    if random-float 100 < virusTransmit * protectionLevel [
      ask hallways with [floor-number = 1 and building-number = dummybuilding] ; infect ground floor
        [set virus? true]]
    if random-float 100 < virusTransmit * protectionLevel [
      ask elevators with [building-number = dummybuilding and elevator-number = dummyelevator] ; infect elevator
        [set virus? true]]]

  if random-float 100 < virusTransmit * protectionLevel [
    ask canteenLines with [line-number = dummyline]
      [set virus? true]]

  repeat (2 * (num-in-elevator - 1)) [ ; assume max. n ppl per elevator, one infected could infect n-1 others, round trip
    if random-float 100 < virusTransmit * protectionLevel * protectionLevel [ ; since saliva will have to go through sick student's mask and then go into healthy student's mask
      ask up-to-n-of 1 students with [line-number != 0 and building-number = dummybuilding][
        if SEIQ = "S" [set num-infected-from-elevator num-infected-from-elevator + 1
          be-infected print("hi")]]]]
end

to infectFromCommonAreas
  repeat 2 [
    if count hallways with [floor-number = dummyfloor and building-number = dummybuilding and virus? = true] > 0 [
      if random-float 100 < virusTransmit * protectionLevel and SEIQ = "S" [
        set num-infected-from-hallway num-infected-from-hallway + 1 be-infected]]

    if count hallways with [floor-number = 1 and building-number = dummybuilding and virus? = true] > 0 [
      if random-float 100 < virusTransmit * protectionLevel and SEIQ = "S" [
        set num-infected-from-ground-floor num-infected-from-ground-floor + 1 be-infected]]

    if count elevators with [elevator-number = dummyelevator and building-number = dummybuilding and virus? = true] > 0 [
      if random-float 100 < virusTransmit * protectionLevel and SEIQ = "S" [
        set num-infected-from-elevator num-infected-from-elevator + 1 be-infected]]]


  if count canteenLines with [line-number = dummyline and virus? = true] > 0 [
    if random-float 100 < virusTransmit * protectionLevel and SEIQ = "S" [
      set num-infected-from-canteen num-infected-from-canteen + 1 be-infected]]
end

to infectRoommates ; 100% to infect roommates
  ask students with [SEIQ = "I"][
    set dummyroom room-number
    set dummyfloor floor-number
    set dummybuilding building-number
    ask students with [returned? = true and room-number = dummyroom and floor-number = dummyfloor and building-number = dummybuilding and SEIQ = "S"][
      set num-infected-from-roommate num-infected-from-roommate + 1 be-infected]]
end

to update-SEIQ
  set num-exposed 1 + num-infected-from-elevator + num-infected-from-roommate + num-infected-from-canteen + num-infected-from-hallway + num-infected-from-ground-floor + num-infected-from-visit

  ask students with [returned? = true and incubation-time != "N/A"][
    set incubation-time incubation-time - (1 / 48) ; incubation time is in days
    if incubation-time < infectious-duration and SEIQ = "E" [set SEIQ "I" set num-infectious num-infectious + 1] ; when E goes to I
    if incubation-time < 0 and SEIQ = "I" [
      set SEIQ "Q"
      set incubation-time "N/A"

      if density > 1 [ ; when roommates exist

        ; set quarantine extremity
        ; 0 only infected individual , 1 roommate, 2 floor, 3 building

        set dummyroom room-number
        set dummyfloor floor-number
        set dummybuilding building-number

        if quarantineLevel = "person" [] ; no extra work
        if quarantineLevel = "room" and density > 1 [
          ask students with [returned? = true and room-number = dummyroom and floor-number = dummyfloor and building-number = dummybuilding][
            set SEIQ "Q"]]
        if quarantineLevel = "floor" [
          ask students with [returned? = true and floor-number = dummyfloor and building-number = dummybuilding][
            set SEIQ "Q"]]
        if quarantineLevel = "building" [
          ask students with [returned? = true and building-number = dummybuilding][
            set SEIQ "Q"]]
  ]]]

  set num-quarantined num-quarantined + count students with [SEIQ = "Q"]
  ask students with [SEIQ = "Q"][die]
end

to be-infected
  set SEIQ "E"

  set sigma sqrt (ln (((9) / (25)) + 1))
  set mu ln (5) - (sigma / 2)
  set incubation-time exp (random-normal mu sigma)

  if incubation-time < 2 [ ;make sure it's between 2 and 14 days
    set incubation-time 2]
  if incubation-time > 14 [
    set incubation-time 14]

  ifelse incubation-time < 5
    [set infectious-duration (incubation-time / 2) - 0.2]
    [set infectious-duration 3 - 0.7 * (14 - incubation-time) / 9]
end

to visit-friend ; uniform chance of visiting a random friend at each tick, max one visit per person per day

  if hour = 1 and minute = 30 [ ; set the total number of visits for today at 1:30am
    ask n-of round (percentVisit * count students) students [
      set visitToday? true
      set visitsPerTick round (count students with [visitToday? = true] / 23)]]

  if hour > 9 and hour < 22 ; visit friends from 10am-10pm, 24 slots
    [ask up-to-n-of visitsPerTick students with [visitToday? = true][
      set num-visits num-visits + 1
      set visitToday? false

      set dummyfloor floor-number
      set dummybuilding building-number
      set dummyroom room-number
      set dummyline 100 ; fake number so it wont match with anything
      ifelse dummybuilding = 1 or dummybuilding = 2 [set dummyelevator (random 3) + 1][set dummyelevator (random 2) + 1]
      if SEIQ = "I" [infectCommonAreas]
      if SEIQ = "S" [infectFromCommonAreas]

      ; set target

      ask one-of students [ ; random friend
        set dummyfloor floor-number
        set dummybuilding building-number
        set dummyroom room-number
        set dummyline 100 ; fake number so it wont match with anything
        ifelse dummybuilding = 1 or dummybuilding = 2 [set dummyelevator (random 3) + 1][set dummyelevator (random 2) + 1]]

      if SEIQ = "I" [
        infectCommonAreas
        ask students with [returned? = true and room-number = dummyroom and floor-number = dummyfloor and building-number = dummybuilding and SEIQ = "S"][
          set num-infected-from-visit num-infected-from-visit + 1 be-infected]]

      if SEIQ = "S" [infectFromCommonAreas]
      if SEIQ = "S" [
        if count students with [returned? = true and room-number = dummyroom and floor-number = dummyfloor and building-number = dummybuilding and SEIQ != "S"] > 0 [
          set num-infected-from-visit num-infected-from-visit + 1 be-infected]
  ]]]
end

to sanitize
  if hour = 23 ; resets at midnight
    [ask students [set eatenBreakfast? false set eatenLunch? false set eatenDinner? false]]

  if sanitization = 1 [
    if hour = 10 ; suppose cleaning is done everytime after meal
      [ask hallways [set virus? false]
       ask elevators [set virus? false]
       ask canteenLines [set virus? false]]]

   if sanitization = 2 [
    if hour = 10 or hour = 15
      [ask hallways [set virus? false]
       ask elevators [set virus? false]
       ask canteenLines [set virus? false]]]

  if sanitization = 3 [
    if hour = 10 or hour = 15 or hour = 20
      [ask hallways [set virus? false]
       ask elevators [set virus? false]
       ask canteenLines [set virus? false]]]

   if sanitization = 4 [
    if hour = 7 or hour = 10 or hour = 15 or hour = 20
      [ask hallways [set virus? false]
       ask elevators [set virus? false]
       ask canteenLines [set virus? false]]]
end
@#$#@#$#@
GRAPHICS-WINDOW
1420
289
1495
365
-1
-1
2.0303030303030303
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
76
542
139
575
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
142
542
205
575
NIL
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
7
542
73
575
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

MONITOR
824
540
934
621
Day
day
17
1
20

MONITOR
939
539
1011
620
Hour
hour
17
1
20

MONITOR
1017
539
1094
620
Minute
Minute
17
1
20

SLIDER
7
581
99
614
N1
N1
1
30
1.0
1
1
NIL
HORIZONTAL

PLOT
6
11
1095
535
SEIQ model
Time
Number of students
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Exposed" 1.0 0 -955883 true "" "plot count students with [SEIQ = \"E\"]"
"Infectious" 1.0 0 -2674135 true "" "plot count students with [SEIQ = \"I\"]"
"Quarantined" 1.0 0 -10899396 true "" "plot num-quarantined"
"S" 1.0 0 -7500403 true "" "plot count students with [SEIQ = \"S\"]"

SLIDER
352
542
474
575
percentMask
percentMask
0
1
0.0
0.25
1
NIL
HORIZONTAL

MONITOR
481
544
563
589
I (total)
num-infectious
17
1
11

MONITOR
481
591
563
636
Q (hourly)
num-quarantined
17
1
11

MONITOR
1102
292
1384
337
Number of Floors with Virus (out of 82)
count hallways with [virus? = true and floor-number = 1]
17
1
11

MONITOR
1102
341
1433
386
Number of Canteen Lines with Virus (out of 15)
count canteenLines with [virus? = true]
17
1
11

PLOT
1103
10
1445
286
Infected Common Areas
Time
Amount
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Hallway" 1.0 0 -16777216 true "" "plot count hallways with [virus? = true]"
"Elevator" 1.0 0 -6459832 true "" "plot count elevators with [virus? = true]"

PLOT
1102
391
1448
622
Number of Students in School/Canteen
Time
Number
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count students with [returned? = true]"
"pen-1" 1.0 0 -7500403 true "" "plot count students with [line-number != 0]"

SLIDER
102
581
194
614
density
density
1
3
1.0
1
1
NIL
HORIZONTAL

SWITCH
824
658
999
691
allStudentsGoEat?
allStudentsGoEat?
0
1
-1000

MONITOR
566
592
745
637
First Quarantine Day
firstQuarantineTime / 48
17
1
11

SLIDER
7
618
179
651
Arrival-Interval
Arrival-Interval
1
14
10.0
1
1
NIL
HORIZONTAL

SLIDER
332
581
441
614
virusTransmit
virusTransmit
0.8
2
2.0
0.01
1
NIL
HORIZONTAL

MONITOR
686
543
803
588
NIL
num-visits
17
1
11

SLIDER
249
631
380
664
sanitization
sanitization
0
4
1.0
1
1
NIL
HORIZONTAL

SLIDER
249
667
380
700
num-in-elevator
num-in-elevator
4
10
6.0
2
1
NIL
HORIZONTAL

MONITOR
1102
626
1295
671
NIL
num-infected-from-elevator
17
1
11

MONITOR
1102
677
1295
722
NIL
num-infected-from-roommate
17
1
11

MONITOR
1102
726
1288
771
NIL
num-infected-from-hallway
17
1
11

MONITOR
1291
726
1511
771
NIL
num-infected-from-ground-floor
17
1
11

MONITOR
1299
626
1485
671
NIL
num-infected-from-canteen
17
1
11

MONITOR
565
544
675
589
E (total)
num-exposed
17
1
11

SLIDER
198
581
308
614
population
population
0.5
2
1.0
0.5
1
NIL
HORIZONTAL

CHOOSER
480
640
618
685
quarantineLevel
quarantineLevel
"person" "room" "floor" "building"
0

SLIDER
209
542
349
575
percentVisit
percentVisit
0
0.1
0.0
0.025
1
NIL
HORIZONTAL

MONITOR
927
728
1099
773
NIL
num-infected-from-visit
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
  <experiment name="mask" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count students with [SEIQ = "S"]</metric>
    <metric>count students with [SEIQ = "E"]</metric>
    <metric>count students with [SEIQ = "I"]</metric>
    <metric>num-quarantined</metric>
    <metric>num-infected-from-canteen</metric>
    <metric>num-infected-from-elevator</metric>
    <metric>num-infected-from-ground-floor</metric>
    <metric>num-infected-from-hallway</metric>
    <metric>num-infected-from-roommate</metric>
    <metric>num-infected-from-visit</metric>
    <enumeratedValueSet variable="density">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-in-elevator">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanitization">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentVisit">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentMask">
      <value value="0"/>
      <value value="0.25"/>
      <value value="0.5"/>
      <value value="0.75"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N1">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantineLevel">
      <value value="&quot;room&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="elevator" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count students with [SEIQ = "S"]</metric>
    <metric>count students with [SEIQ = "E"]</metric>
    <metric>count students with [SEIQ = "I"]</metric>
    <metric>num-quarantined</metric>
    <metric>num-infected-from-canteen</metric>
    <metric>num-infected-from-elevator</metric>
    <metric>num-infected-from-ground-floor</metric>
    <metric>num-infected-from-hallway</metric>
    <metric>num-infected-from-roommate</metric>
    <metric>num-infected-from-visit</metric>
    <enumeratedValueSet variable="density">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-in-elevator">
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanitization">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentVisit">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentMask">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N1">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantineLevel">
      <value value="&quot;room&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="visit" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count students with [SEIQ = "S"]</metric>
    <metric>count students with [SEIQ = "E"]</metric>
    <metric>count students with [SEIQ = "I"]</metric>
    <metric>num-quarantined</metric>
    <metric>num-infected-from-canteen</metric>
    <metric>num-infected-from-elevator</metric>
    <metric>num-infected-from-ground-floor</metric>
    <metric>num-infected-from-hallway</metric>
    <metric>num-infected-from-roommate</metric>
    <metric>num-infected-from-visit</metric>
    <enumeratedValueSet variable="density">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-in-elevator">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanitization">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentVisit">
      <value value="0"/>
      <value value="0.025"/>
      <value value="0.05"/>
      <value value="0.075"/>
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentMask">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N1">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantineLevel">
      <value value="&quot;room&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="san" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count students with [SEIQ = "S"]</metric>
    <metric>count students with [SEIQ = "E"]</metric>
    <metric>count students with [SEIQ = "I"]</metric>
    <metric>num-quarantined</metric>
    <metric>num-infected-from-canteen</metric>
    <metric>num-infected-from-elevator</metric>
    <metric>num-infected-from-ground-floor</metric>
    <metric>num-infected-from-hallway</metric>
    <metric>num-infected-from-roommate</metric>
    <metric>num-infected-from-visit</metric>
    <enumeratedValueSet variable="density">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-in-elevator">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanitization">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentVisit">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentMask">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N1">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantineLevel">
      <value value="&quot;room&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="den" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count students with [SEIQ = "S"]</metric>
    <metric>count students with [SEIQ = "E"]</metric>
    <metric>count students with [SEIQ = "I"]</metric>
    <metric>num-quarantined</metric>
    <metric>num-infected-from-canteen</metric>
    <metric>num-infected-from-elevator</metric>
    <metric>num-infected-from-ground-floor</metric>
    <metric>num-infected-from-hallway</metric>
    <metric>num-infected-from-roommate</metric>
    <metric>num-infected-from-visit</metric>
    <enumeratedValueSet variable="density">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-in-elevator">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanitization">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentVisit">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentMask">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N1">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantineLevel">
      <value value="&quot;room&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="pop" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count students with [SEIQ = "S"]</metric>
    <metric>count students with [SEIQ = "E"]</metric>
    <metric>count students with [SEIQ = "I"]</metric>
    <metric>num-quarantined</metric>
    <metric>num-infected-from-canteen</metric>
    <metric>num-infected-from-elevator</metric>
    <metric>num-infected-from-ground-floor</metric>
    <metric>num-infected-from-hallway</metric>
    <metric>num-infected-from-roommate</metric>
    <metric>num-infected-from-visit</metric>
    <enumeratedValueSet variable="density">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-in-elevator">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanitization">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentVisit">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentMask">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N1">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="0.5"/>
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantineLevel">
      <value value="&quot;room&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="qlevel" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count students with [SEIQ = "S"]</metric>
    <metric>count students with [SEIQ = "E"]</metric>
    <metric>count students with [SEIQ = "I"]</metric>
    <metric>num-quarantined</metric>
    <metric>num-infected-from-canteen</metric>
    <metric>num-infected-from-elevator</metric>
    <metric>num-infected-from-ground-floor</metric>
    <metric>num-infected-from-hallway</metric>
    <metric>num-infected-from-roommate</metric>
    <metric>num-infected-from-visit</metric>
    <enumeratedValueSet variable="density">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-in-elevator">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanitization">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentVisit">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentMask">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N1">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantineLevel">
      <value value="&quot;person&quot;"/>
      <value value="&quot;room&quot;"/>
      <value value="&quot;floor&quot;"/>
      <value value="&quot;building&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="opt" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count students with [SEIQ = "S"]</metric>
    <metric>count students with [SEIQ = "E"]</metric>
    <metric>count students with [SEIQ = "I"]</metric>
    <metric>num-quarantined</metric>
    <metric>num-infected-from-canteen</metric>
    <metric>num-infected-from-elevator</metric>
    <metric>num-infected-from-ground-floor</metric>
    <metric>num-infected-from-hallway</metric>
    <metric>num-infected-from-roommate</metric>
    <metric>num-infected-from-visit</metric>
    <enumeratedValueSet variable="density">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-in-elevator">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanitization">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentVisit">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentMask">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N1">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantineLevel">
      <value value="&quot;room&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="vanilla" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count students with [SEIQ = "S"]</metric>
    <metric>count students with [SEIQ = "E"]</metric>
    <metric>count students with [SEIQ = "I"]</metric>
    <metric>num-quarantined</metric>
    <metric>num-infected-from-canteen</metric>
    <metric>num-infected-from-elevator</metric>
    <metric>num-infected-from-ground-floor</metric>
    <metric>num-infected-from-hallway</metric>
    <metric>num-infected-from-roommate</metric>
    <metric>num-infected-from-visit</metric>
    <enumeratedValueSet variable="virusTransmit">
      <value value="0.9"/>
      <value value="0.92"/>
      <value value="0.94"/>
      <value value="0.96"/>
      <value value="0.98"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="density">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-in-elevator">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanitization">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentVisit">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentMask">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N1">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantineLevel">
      <value value="&quot;person&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="opt" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>num-exposed</metric>
    <enumeratedValueSet variable="density">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-in-elevator">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanitization">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentVisit">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentMask">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N1">
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="virusTransmit">
      <value value="0.82"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantineLevel">
      <value value="&quot;room&quot;"/>
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

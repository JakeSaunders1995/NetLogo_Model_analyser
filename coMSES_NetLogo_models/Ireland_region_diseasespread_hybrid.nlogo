 extensions [

  csv

  table

  rnd
   ]


globals [
  twns           ;;list of towns in region
  i
  %infected      ;;the percent of infected agents in the simulation
  %susceptible   ;;percent of susceptible agents
  %immune        ;;percent of immune agents
  %recovered     ;;percent of recovered agents
  %exposed       ;;percent of exposed agents
  NUM_HUMANS     ;;number of agents in the model

  time          ;;time of the day in the simulation
  day           ;;day number in the simulation
  week          ;;week number in the simulation
  x
  infected    ;;the number of infected individuals
  susceptible  ;;the number of susceptible individuals
  immune        ;;the number of immune individuals
   tot_contacts  ;; list of mean number of contacts for each turtle
   mean_tot_contacts ;;mean of number of contacts for all turtles
  count_list
   seconds  ;;seconds it takes the model to run
   exposed ;;count of turtles exposed
   sick_turts  ;;turtles who are infected at that timestep
   sick_turts_age ;;age of turtles infected at that timestep
   sick_turts_econ ;;econstatus of turtles infected at that timestep
  sick_turts_town  ;;town of tutles infected at that timestep
   seconds_to_run ;;seconds taken for model to run
   students  ;;agentset of students
   workers   ;;agent set of working individuals
   non-workers ;; agent set of individuals not working
   stay-at-home ;;agent set of individuals who are stay at home parents
  infants ;;agent set of infants
  schools ;;patches that are schools
  work ;;patches that represent work places
  community ;;patches with community
  town_patches ;;patches in the town
  pop ;; population dataset






   ]






patches-own [

  other_ed  ;;other patche in the same town
  turtsed   ;;turtles in the town
  switched  ;;has the patched switched to an equation based diseae component
  sm_area        ;;the geoid for small area
  town_name  ;; name of the town/electoral district the small area is a part of
  county ;;name of county
  primary_count ;; number of primary schools
  secondary_count ;;number of secondary schools
  distances ;;list of distances to other patches
  otherpatches  ;;other patches in the region
  move_prob   ;;probabiltiy agents on this patch will move to other patches
  label_sa

  ;;equation based disease component variables
  Si1  ;;number of susceptible in the town in the next time step
  Ei1  ;;number of exposesd in the town in the next time step
  Ii1  ;;number of infectious in the town in the next time step
  Ri1  ;;number of recovered in the town in the next time step
  Si  ;;current number of suseptibles in the town
  Ei  ;;current number of exposed in the town
  Ii  ;;current number of infectious in the town
  Ri  ;;current number of recovered in the town

]

turtles-own[
  small_area  ;;small area id of the turtles home patch
  home-patch ;; patch that is the turtles home
  where_sick  ;;where the turtle was infected: home, work, school or community
  work-patch  ;; patch where the turtle works
  age  ;;age of the turtle
  sex  ;;sex of the turtle
  patchon  ;;patch the turtle is on
  sick?          ;;is the agent sick
  immune?  ;;is the agent immune
  exposed?  ;;was the agent exposed
  contacts
  adult?  ;;is the agent an adult
  familyid   ;;number same for all agents in the same family
  econ_stat ;; economic status of the agent: work, student, retired etc.
  infant ;; is the agent an infant
  num_contacts
  dest-patch  ;;patch the agent is moving to
    immunity ;;level of immunity the individual has from vaccination or previosly having the disease
  avg_contacts ;list with average contacts each tick
    days_exposed ; number of days turtle will stay exposed but not infectious
  days_sick   ; number of days turtle will remain sick and infectious
  cont_table  ;; table of who numbers of turtles in contact with
  tick_exposed ;;time the agent was exposed
  ticks_exposed ;;testing variable
  ticks_when_sick ;;testing variables
  ticks_sick ;;testing variables
   my-contacts-table ;;table of contacts per tick
empty_tab ;; empty table
family_network ;;turtles family network
work_network ;;turtles work network
school_network ;; turtles school network
 class_network ;;students in classroom
school ;;school student goes to
workplace ;;work of turtle
location ;;location of turtle home, work or community

]

 breed [people person]

to setup-loadworld  ;;setup the model with a preexisting setup

  ca
  import-world (word "/data/" region "_measles.csv")
  random-seed new-seed
  set num_infected 1
  set start_week 9
  ask turtles [set immunity 0]
  set switch 0.1

   start-infection

  reset-ticks

end



to go  ;;steps to run the model
 if count turtles with [(sick? = TRUE or exposed? = TRUE) and immune? = FALSE] = 0 [
   stop
  ]
if count turtles with [(sick? = TRUE or exposed? = TRUE) and immune? = FALSE] = 0 and mean_tot_contacts = 0 [
   set seconds_to_run timer
   find_contacts
  ]

  clock
  move



  ask twns[
    set turtsed turtles with [[town_name] of patch-here = [town_name] of myself]
    ifelse count turtsed with [ (sick? or exposed?)] < (count turtsed  * switch) [
    set switched FALSE
      ask other_ed with [count turtles-here with [sick? or exposed?] > 0][
  infect
 recover
      ]
    ]

 [

   infect_seir

    set switched TRUE

  ]

  ]




 update-global-variables

 who-sick



  clear-links
  tick
end










to-report random-from-cum-pmf [cum-pmf]  ;;reports random value from a cumulative percentage distrbution
  let n random-float 1
  report length filter [ [?1] -> ?1 < n ] cum-pmf
end











to move  ;;code that defines agents movements
if ticks > 3 [  ;;movement starts after 3rd time step
  ask workers [
           ifelse time < 4 or time > 10 [
     if patch-here != home-patch[
        move-to home-patch
        set location "home"
        ;update-contacts
      ]
     ]
   [
   ifelse day = 6 or day = 7 [
          set patchon  patch-here
      ifelse sick? [
       ifelse random-float 1 < 0.25 [

              let dp first  rnd:weighted-one-of-list [distances] of patchon [ [p] -> last p]
              set dest-patch one-of town_patches with [sm_area =  dp]
        move-to dest-patch
            ;  show (word day " " patchon " " dest-patch)
        set location "community"
        ;update-contacts
        ]
            [];update-contacts]
      ]
      [ ifelse random-float 1 < 0.5 [


      let dp first  rnd:weighted-one-of-list [distances] of patchon [ [p] -> last p]
      set dest-patch one-of town_patches with [sm_area =  dp]
        move-to dest-patch
          ; show (word day " " patchon " " dest-patch)
        set location "community"
       ; update-contacts


            ] [];update-contacts]
      ]
   ]
   [
     ifelse sick? [
      ifelse random-float 1 < .3 [
        move-to work-patch
        set location "work"
       ; update-contacts
      ]
            [];update-contacts]
     ]
     [ifelse time = 4 [
        move-to work-patch
        set location "work"
       ; update-contacts
      ]
     [ifelse time = 10
        [
        move-to home-patch
        set location "work"
        ;update-contacts
            ][]];update-contacts]]

     ]
   ]

   ]
 ]




 ask students [
           ifelse time < 4 or time > 10 [
     if patch-here != home-patch[
        move-to home-patch
        set location "home"
        ;update-contacts
     ]
   ]
   [
   ifelse day = 6 or day = 7 or ((start_week + week) > 26 and  (start_week + week) < 36) [
          set patchon  patch-here
      ifelse sick? [
       ifelse random-float 1 < home_sick [

       let dp first  rnd:weighted-one-of-list [distances] of patchon [ [p] -> last p]
      set dest-patch one-of town_patches with [sm_area =  dp]
        move-to dest-patch
             ; show (word day " " patchon " " dest-patch)
        set location "community"

       ; update-contacts
        ]
            [];update-contacts]
      ]
      [ ifelse random-float 1 < 0.5 [



        let dp first  rnd:weighted-one-of-list [distances] of patchon [ [p] -> last p]
      set dest-patch one-of town_patches with [sm_area =  dp]
        move-to dest-patch
            ;show (word day " " patchon " " dest-patch)
        set location "community"


          ] [];update-contacts]
      ]
    if patch-here = dest-patch [
    ifelse random-float 1 < 0.33 [

        let dp first  rnd:weighted-one-of-list [distances] of patchon [ [p] -> last p]
      set dest-patch one-of town_patches with [sm_area =  dp]
        move-to dest-patch
              ;show (word day " " patchon " " dest-patch)
        set location "community"
    ]

     [if random-float 1 < 0.33 [

        move-to home-patch
        set location "home"

       ; update-contacts

     ]
    ]


   ]
   ]
   [

     ifelse time = 4 [
            ifelse sick? [
      ifelse random-float 1 < home_sick [

        move-to work-patch
        set location "school"

        ;update-contacts

      ]
              [];update-contacts]
     ][
        move-to work-patch
        set location "school"
; update-contacts

     ]][ifelse time = 8
        [
        move-to home-patch
        set location "home"

      ][]];update-contacts]]
     ]

     ]
   ]

   ;;movement for unemployed agents

 ask non-workers[
set patchon  patch-here
           ifelse not sick? or random-float 1 < .25[
    if patch-here = home-patch and time > 3 and time < 11 [
    ifelse random-float 1 < 0.5 [
     let dp first  rnd:weighted-one-of-list [distances] of patchon [ [p] -> last p]
      set dest-patch one-of town_patches with [sm_area =  dp]

        move-to dest-patch
            ;show (word day " " patchon " " dest-patch)
        set location "community"
        ;update-contacts


        ][];update-contacts]
   ]
        if patch-here = dest-patch and time < 10 [
          set patchon  patch-here
      ifelse random-float 1 < 0.33 [
        let dp first  rnd:weighted-one-of-list [distances] of patchon [ [p] -> last p]
      set dest-patch one-of town_patches with [sm_area =  dp]

      move-to dest-patch
            ;show (word day " " patchon " " dest-patch)
      set location "community"
        ;update-contacts

    ] [

     ifelse random-float 1 < 0.33 [

        move-to home-patch
        set location "home"
        ;update-contacts
        ]
            [];update-contacts]
    ]

   ]
    if patch-here != home-patch and time = 10 [
        move-to home-patch
        set location "home"
      ;  update-contacts

    ]

    ][];update-contacts]


  ]

 ;;stay at home parent movements


  ask stay-at-home[
   if work-patch != 0[
      ifelse not sick? or random-float 1 < .95 [
   ifelse time = 4 and day != 6 and day != 7[

        move-to work-patch
        set location "community"
        ;update-contacts
        if infant != FALSE[
        ask turtle infant[
          if econ_stat = "Infant" [
         move-to [work-patch] of myself
         set location "community"
         ;update-contacts
          ]
        ]
        ]

   ][
   ifelse time = 7 and day != 6 and day != 7[
          move-to work-patch
          set location "community"
       ; update-contacts
        if infant != FALSE[
        ask turtle infant[
          if econ_stat = "Infant" [
         move-to [work-patch] of myself
        set location "community"
         ;update-contacts
          ]
        ]
        ]

          ][];update-contacts]
      ]][];update-contacts]


ifelse not sick? or random-float 1 < .5 [
  ifelse time > 4 and time < 7 [
            set patchon  patch-here
    ifelse random-float 1 < 0.33 [
      let dp first  rnd:weighted-one-of-list [distances] of patchon [ [p] -> last p]
      set dest-patch one-of town_patches with [sm_area =  dp]

        move-to dest-patch
              ;show (word day " " patchon " " dest-patch)
        set location "community"
       ; update-contacts
        if infant != FALSE[
         ask turtle infant[
         move-to [dest-patch] of myself
        ; update-contacts
         set location "community"
        ]
        ]
    ]
    [

     ifelse random-float 1 < 0.33 [

        move-to home-patch
        set location "home"
        ;update-contacts
        if infant != FALSE[
         ask turtle infant[
           if econ_stat = "Infant" [
        move-to home-patch
        set location "home"
        ; update-contacts
        ]
         ]
        ]

            ][];update-contacts]
    ]



     if patch-here != home-patch and time = 8 [
        move-to home-patch
        set location "home"
       ; update-contacts
        if infant != FALSE[
         ask turtle infant[
           if econ_stat = "Infant" [
         move-to home-patch
         set location "home"
         ;update-contacts
        ]
         ]
        ]
        ]
        ][];update-contacts]



      ][];update-contacts]
   ]



 if work-patch = 0[
      ;if ticks > 3[
        ifelse not sick? or random-float 1 < .5[
    ifelse patch-here = home-patch and time > 3 and time < 8 [
            set patchon  patch-here
    ifelse random-float 1 < 0.5 [
  let dp first  rnd:weighted-one-of-list [distances] of patchon [ [p] -> last p]
      set dest-patch one-of town_patches with [sm_area =  dp]

        move-to dest-patch
              ;show (word day " " patchon " " dest-patch)
set location "community"
        ;update-contacts
        if infant != FALSE[
         ask turtle infant[
         move-to [dest-patch] of myself
         set location "community"
         ;update-contacts
         ]
        ]

      ][]][;update-contacts]][




    ifelse patch-here != home-patch and time > 3 and time < 8 [
    ifelse random-float 1 < 0.33 [
                set patchon  patch-here
     let dp first  rnd:weighted-one-of-list [distances] of patchon [ [p] -> last p]
      set dest-patch one-of town_patches with [sm_area =  dp]

        move-to dest-patch
               ; show (word day " " patchon " " dest-patch)
        set location "community"
       ; update-contacts
        if infant != FALSE[
         ask turtle infant[
         move-to [dest-patch] of myself
set location "community"
         ;update-contacts
        ]

        ]
               ][



     ifelse random-float 1 < 0.33 [

        move-to home-patch
        set location "home"
       ; update-contacts
        if infant != FALSE[
         ask turtle infant[
           if econ_stat = "Infant" [
        move-to home-patch
set location "home"
         ;update-contacts
        ]
         ]
        ]

              ][];update-contacts]
    ]
    ][

     ifelse patch-here != home-patch and time = 8 [

        move-to home-patch
        set location "home"
        ;update-contacts
        if infant != FALSE[
         ask turtle infant[
           if econ_stat = "Infant" [
         move-to home-patch
         set location "home"
         ;update-contacts
        ]
         ]
        ]

            ][];update-contacts]


    ] ]
        ]



        [];update-contacts]
 ]

















  ]



]

  ask turtles with [econ_stat = "Infant"][if num_contacts = [] []; update-contacts]
]


end


to update-contacts
  if contacts? [
set i 0
    let patchhere patch-here
if location = "home"[
  set i count family_network with [ location = "home"]
          ]


if  location = "community" [
  set i ceiling (count family_network with [location = "community" and patch-here = patchhere] * community_family)
  ifelse econ_stat = "student" or econ_stat = "work" [
  set i i + ceiling (count work_network with [location = "community" and patch-here = patchhere]* community_work)
  set i i + ceiling (count turtles-here with [member? self [family_network] of myself = FALSE and member? self [work_network] of myself = FALSE and location = "community"] * community_Cont)
          ]
  [ set i i + ceiling (count turtles-here with [member? self [family_network] of myself = FALSE  and location = "community"] * 0.2)
  ]
]

if location = "school" [
      set i ceiling (count work_network with [ location = "school" ] * work_cont ) + ceiling (count class_network with [location = "school"] * class_cont)
]


if location = "work" [
  set i ceiling (count work_network with [  location = "work" and patch-here = patchhere] * work_cont )
]


set num_contacts lput i num_contacts

  ]

end

to clock  ;;keeps track of real time, day and week

  set time ticks mod 12
  if time = 0 [
    set day day + 1
  ]
  if day = 8 [
    set week week + 1
    if week = 52 [
      set week 0
    ]
    set day 1
  ]

end

to find_contacts
  if contacts?[
  if ticks > 3 [
   set count_list []
   ask turtles [;with [sick? or immune?] [
   set  avg_contacts mean num_contacts
    ;set avg_contacts num_contacts / ticks
    set count_list lput avg_contacts count_list
  ]
 ;  if count turtles with [sick? or immune?] > 0 [
  set tot_contacts  lput mean count_list tot_contacts
  set mean_tot_contacts mean count_list
 ; ]
    ;  set mean_tot_contacts mean tot_contacts
  ]
  ]
end

to infect  ;;how an agent infects another agent
ask turtles-here with [sick? = TRUE and immune? = FALSE and location = "home"][
  ask turtles-here with [member? self [family_network] of myself = TRUE and location = "home"][
      if random-float 1 < (infectivity )[
          if random-float 1 > immunity [
              get-sick
          ]
      ]
  ]
]

ask turtles-here with [sick? = TRUE and immune? = FALSE and location = "community"][
  ask turtles-here with [member? self [family_network] of myself = TRUE and location = "community"][
    if random-float 1 < community_family [
      if random-float 1 < (infectivity )[
          if random-float 1 > immunity [
              get-sick
          ]
      ]
    ]
  ]
  ifelse member? self students or member? self workers [
    ask turtles-here with [member? self [work_network] of myself = TRUE and location = "community"][
      if random-float 1 < community_work [
      if random-float 1 < (infectivity)[
          if random-float 1 > immunity [
              get-sick
          ]
      ]
  ]
    ]
      ask turtles-here with [member? self [family_network] of myself = FALSE and member? self [work_network] of myself = FALSE and location = "community"][
        if random-float 1 < community_Cont [
      if random-float 1 < (infectivity  )[
          if random-float 1 > immunity [
              get-sick
          ]
      ]
  ]
      ]

][
        ask turtles-here with [member? self [family_network] of myself = FALSE and location = "community"][
          if random-float 1 < community_Cont [
      if random-float 1 < (infectivity )[
          if random-float 1 > immunity [
              get-sick
          ]
      ]
  ]
        ]
]


]


ask turtles-here with [sick? = TRUE and immune? = FALSE and location = "school" and member? self students][

      ask turtles-here with [member? self [work_network] of myself = TRUE and location = "school"][
      if random-float 1 < school_cont [
      if random-float 1 < (infectivity  )[
          if random-float 1 > immunity [
              get-sick
          ]

  ]
      ]
     ]
    ask turtles-here with [member? self [class_network] of myself = TRUE and location = "school"][
      if random-float 1 < class_cont [
              if random-float 1 < (infectivity  )[
          if random-float 1 > immunity [
              get-sick
          ]

  ]
      ]
    ]
  ]
ask turtles-here with [sick? = TRUE and immune? = FALSE and location = "work" and member? self workers][


      ask turtles-here with [member? self [work_network] of myself = TRUE and location = "work"][
      if random-float 1 < work_cont [
      if random-float 1 < (infectivity  )[
          if random-float 1 > immunity [
              get-sick
          ]
      ]
    ]]

]



  ask turtles-here with [exposed? = TRUE][
        ifelse days_exposed + tick_exposed <= ticks[
        set sick? TRUE
        set color red
        set days_sick round((random-normal 8 .5) * 12)
        set ticks_when_sick ticks  ;;testing variables
        set ticks_sick 1 ;;testing variables
      set exposed? FALSE
      ]
        [set ticks_exposed ticks_exposed + 1] ;;testing variables
  ]



end





to recover  ;;agent recovery
  ask turtles-here with [sick? = TRUE][
  ifelse days_sick + days_exposed + tick_exposed <= ticks [
    get-healthy
  ] [set ticks_sick ticks_sick + 1] ;;testing variables
  ]
end






to update-global-variables  ;;updates counts of global variables
  if count turtles > 0
    [ set infected count turtles with [ sick? ]
      set susceptible count turtles with [not sick? and not immune? and not exposed?]
      set immune count turtles with [immune?]
      set exposed count turtles with [exposed? and not sick? and not immune?]



      set %infected (infected / NUM_HUMANS) * 100
      set %susceptible (susceptible / NUM_HUMANS) * 100
      set %immune (immune / NUM_HUMANS * 100)
      set %exposed (exposed / NUM_HUMANS * 100)


      set seconds timer






      ]
 ; ifelse time = day-length [set time 0][set time time + 1]
end


to get-sick  ;;process for an agent to go from susceptible to expoed or sick
  ifelse SEIR [
    if days_exposed = 0 and exposed? = FALSE and sick? = FALSE[
      set days_exposed random-normal 10 .5   ;;normal distribution of days exposed should be about 10 days
      set days_exposed round (days_exposed * 12) ;;gets number of ticks exposed
      set color orange
      set exposed? TRUE
      set tick_exposed ticks
      set ticks_exposed 1 ;;testing variables
      set where_sick location
    ]

    ]
  [
  if immune? = FALSE [
  set sick? TRUE
  set color red
  ]
  ]
end








to get-healthy  ;;changing agents color and variables to show that recovered
  set sick? FALSE
  ifelse SIR [
    set color white
    set immune? TRUE
  ]
  [set color yellow]
end





to start-infection   ;;infects a given number of agents
  ask n-of num_infected turtles with [immunity = 0  ][set sick? TRUE
   set color red
   set days_sick round((random-normal 8 .5) * 12)
   set tick_exposed 0
   set days_exposed 0 ]
end

to setup-region  ;;setup the model for a new region
   ca

set  town_patches csv:from-file (word "/data/" region "_patches.csv")
  let j length town_patches  - 1
  let n floor sqrt j
  set i 1
  resize-world ( floor (n / -2)) (ceiling (n / 2)) ( floor (n / -2)) (ceiling (n / 2))
  while [i < length town_patches][
    ask patches with [pxcor = item 0 item i town_patches and pycor = item 1 item i town_patches] [
     ifelse length (word "" item  2 item i town_patches) = 8 [
     set label_sa item  2 item i town_patches
      set sm_area word "0" label_sa
      ][ ifelse length (word "" item  2 item i town_patches) = 9 [
        set sm_area (word "" item  2 item i town_patches)
      ]
      [set sm_area item 2 item i town_patches
        set label_sa substring sm_area 0 9
      ]]
      set town_name item 3 item i town_patches
      set county item 4 item i town_patches
      set pcolor blue
      set primary_count item 5 item i town_patches
      set secondary_count item 6 item i town_patches

      set distances read-from-string item 7 item i town_patches
      set otherpatches read-from-string item 8 item i town_patches
      set move_prob read-from-string  item 9 item i town_patches

      ifelse item 10 item i town_patches = 0 [
       set  other_ed 0
      ][
        set other_ed read-from-string item 10 item i town_patches]
    ]
   set i i + 1
    ]


  set town_patches patches with [pcolor = blue ]

  set twns town_patches with [other_ed != 0]

    set  pop csv:from-file (word "/data/" region "_population.csv")
  ask one-of patches with [pcolor = blue] [ sprout ((length pop) - 1)]

  ask town_patches [
    set x self
  foreach (range 1 length pop) [ row -> ;set i item 4 item row pop
       if read-from-string item 4 item row pop = x [
    ask turtle  item 0 item row pop [
      set small_area [sm_area] of x
      set home-patch x
      set age item 6 item row pop
      set sex  item 7 item row pop
      set sick? item 8 item row pop
      set immune? item 9 item row pop
       set exposed? item 10 item row pop
       set adult?  item 11 item row pop

        set familyid item 12 item row pop

        set econ_stat item 13 item row pop
         set infant item 14 item row pop
        if econ_stat = "Work" or econ_stat = "Student"[
      set work-patch read-from-string item 5 item row pop
        ]

        set immunity item 15 item row pop


        set family_network read-from-string item 16 item row pop
        if econ_stat = "Work"[
        set work_network read-from-string item 17 item row pop
      ;    set workplace item 28 item row pop
        ]
        if econ_stat = "Student" [
        set work_network read-from-string item 17 item row pop
        set class_network read-from-string item 18 item row pop
        ;set school item 27 item row pop
        set workplace item 19 item row pop


        ]
        move-to home-patch
        set contacts n-values NUM_HUMANS [0]
    set num_contacts []
    set color yellow
          set size 1
    ]]
  ]
  ]

  ask turtles with [home-patch = 0][die]

set students turtles with [econ_stat = "Student"]
set workers turtles with [econ_stat = "Work"]
set non-workers turtles with [econ_stat = "Unemployed" or econ_stat = "Looking for first job" or econ_stat = "Retired" or econ_stat ="Sick/disabled"]
 set stay-at-home turtles with [econ_stat = "Stay-at-home"]
  set infants turtles with [econ_stat = "infants"]


ask stay-at-home[
    if any? turtles with [familyid = [familyid] of myself and econ_stat = "Infant"][
      set infant [who] of one-of turtles with [familyid = [familyid] of myself and econ_stat = "Infant"]]]

    if count patches with [secondary_count > 0] = 0 [
  ask one-of patches with [sm_area = 0][
    set secondary_count 1]
]

if count patches with [primary_count > 0] = 0 [
  ask one-of patches with [sm_area = 0][
    set primary_count 1]
]





  set NUM_HUMANS count turtles

 start-infection

  set tot_contacts []

  reset-timer
  reset-ticks
end



to who-sick  ;;determines which agents are newly sick in a given timestep
  set sick_turts 0
  set sick_turts_age 0
  set sick_turts_econ 0
  set sick_turts_town 0
  ask turtles with [sick? and days_exposed + tick_exposed = ticks][
    let n [who] of self
    let a [age] of self
    let s [town_name] of [home-patch] of self
    ;let ns (list n a s)

    set sick_turts n
    set sick_turts_age a
    set sick_turts_town s
  ]

end




to infect_seir  ;the hybrid disease component





  if ticks = 1 or switched = FALSE  [

  set Si count turtsed with [not sick? and not immune? and not exposed?]
  set Ei count turtsed with [exposed?]
  set Ii count turtsed with [sick?]
  set Ri count turtsed with [immune?]
    ]
  if ticks > 1 and switched = TRUE
  [
    set Si Si1

    set Ei Ei1

    set Ii Ii1

    set Ri  Ri1


   ]
  if ticks > 4[
    if Si < 1 and count turtles-here with [not sick? and not immune? and not exposed?] > 0 [set Si count turtles-here with [not sick? and not immune? and not exposed?]]
    if Ei < 1 and count turtsed with [exposed?] > 0 [set Ei count turtsed with [ exposed?]]

    if Ii < 1 and count turtsed with [immune?] < Ri and count turtsed with [immune?] > 0 and count turtsed with [sick?] > 0 [set Ri count turtsed with [immune?]]
    if Ii < 1 and count turtsed with [sick?] > 0 [set Ii count turtsed with [sick?]]
    ;if Ri < 1 and count turtsed with [ immune?] > 0 [set Ri count turtsed with [immune?]]
  ]





  set Si1 Si  - 0.008 * Ii * Si / count turtsed
  set Ei1 (0.008 * Ii * Si ) / count turtsed + Ei - (Ei  * (1 / (10 * 12 * 2)))
   set Ii1 (Ei *  (1 / (10 * 12 * 2))) + Ii  - Ii / (8 * 12 * 2)
  set Ri1 Ri + Ii * (1 / (8 * 12 * 2))









    ifelse round (Ri1 - count turtsed with [immune?]) > 0 [


    ifelse  round (Ri1 - count turtsed with [immune?]) <= count turtsed with [sick?][
  ask n-of round  (Ri1 - count turtsed with [immune?]) turtsed with [ sick?][get-healthy]
    ][ask turtsed with [sick?][get-healthy]
    ]

  ][if count turtsed with [immune?] > 0 [set Ri1 count turtsed with [immune?]]]


    if round (Ii1 - count turtsed with [sick?]) > 0[

    ifelse round (Ii1 - count turtsed with [sick?]) <= count turtsed with [exposed?][
      ask n-of round (Ii1 - count turtsed with [ sick?]) turtsed with [exposed?][ set sick? TRUE
        set color red
        set exposed? FALSE
    set days_sick round((random-normal 8 .5) * 12)
        set ticks_when_sick ticks  ;;testing variables
        set ticks_sick 1 ;;testing variables
    ]][
      ask turtsed with [exposed?][ set sick? TRUE
        set color red
        set exposed? FALSE
      set days_sick round((random-normal 8 .5) * 12)
        set ticks_when_sick ticks  ;;testing variables
        set ticks_sick 1 ;;testing variables
      ]

    ]
    ]


 if round (Ei1 - count turtsed with [exposed?])  > 0 [
       ifelse round (Ei1 - count turtsed with [exposed?])  <= count turtsed with [not sick? and not immune? and not exposed? and immunity = 0] [
  ask n-of round (Ei1 - count turtsed with [ exposed?]) turtsed with [not sick? and not immune? and not exposed? and immunity = 0][
        get-sick]][ask turtsed with [not sick? and not immune? and not exposed? and immunity = 0] [get-sick]


      ]


    ]






end
@#$#@#$#@
GRAPHICS-WINDOW
321
23
404
107
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
-7
7
-7
7
0
0
1
ticks
30.0

BUTTON
106
147
169
180
NIL
go\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
63
274
201
319
region
region
"Leitrim" "example"
1

INPUTBOX
17
332
108
392
start_week
9.0
1
0
Number

INPUTBOX
23
409
98
469
home_sick
0.3
1
0
Number

INPUTBOX
18
654
119
714
community_Cont
0.01
1
0
Number

INPUTBOX
124
662
230
722
community_family
0.9
1
0
Number

INPUTBOX
611
753
858
813
community_work
0.1
1
0
Number

INPUTBOX
300
648
455
708
work_cont
0.2
1
0
Number

INPUTBOX
5
493
160
553
class_cont
0.7
1
0
Number

INPUTBOX
24
745
263
805
infectivity
0.002
1
0
Number

INPUTBOX
325
746
564
806
school_cont
0.2
1
0
Number

SWITCH
85
229
188
262
SEIR
SEIR
0
1
-1000

SWITCH
104
407
207
440
SIR
SIR
0
1
-1000

INPUTBOX
651
684
806
744
num_infected
1.0
1
0
Number

BUTTON
63
36
183
69
NIL
setup-loadworld\n
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
78
74
180
107
NIL
setup-region\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
297
351
452
411
switch
0.1
1
0
Number

SWITCH
86
189
195
222
contacts?
contacts?
0
1
-1000

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
NetLogo 6.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="300" runMetricsEveryStep="true">
    <setup>setup-loadworld</setup>
    <go>go</go>
    <metric>susceptible</metric>
    <metric>exposed</metric>
    <metric>infected</metric>
    <metric>immune</metric>
    <metric>sick_turts_town</metric>
    <metric>count patches with [switched = TRUE]</metric>
    <metric>count turtles with [where_sick = "community"]</metric>
    <metric>count turtles with [where_sick = "home"]</metric>
    <metric>count turtles with [where_sick = "school"]</metric>
    <metric>count turtles with [where_sick = "work"]</metric>
    <enumeratedValueSet variable="switch">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="community_family">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="class_cont">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="school_cont">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="home_sick">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infectivity">
      <value value="0.002"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SEIR">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="region">
      <value value="&quot;Leitrim&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="work_cont">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contacts?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="community_work">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="community_Cont">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_infected">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SIR">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="swtich">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="start_week">
      <value value="9"/>
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

breed [monsters monster]
breed [humans human]

;TODO :
;- Configurations d'équipes customisables
;- Gain de bois, ecart entre les nids, portée des torches, tolérance de délai adaptables

patches-own
[
  cell_type ;0 : earth, 1 : tree, 2 : nest, 3 : fire
  last_light
  nearest_nest
  delay ;for trees and nests

  checkpoint ;0 if no checkpoint
]

humans-own
[
  leader ; 0 if no responsability, 1 if leader of a group, 2 if main leader
  follows
  group

  task ; 0 No task, 1 Wood task, 2 Nest task, 3 Task done
  fulfillable ;false if not enough members in the group to succeed it
  target; patch to visit : if nest task, it is the patch with the nest, else it is a patch which permits to have a direction
  patch_wait ;for the task, make the group stop at a patch to let the one with the tool make use of it
  tool ; 0 No tool, 1 Bow, 2 Sword, 3 Axe, 4 Torch, 5 Wood

  cells_to_see ; list of the checkpoint cells seen
  health
  pain

  seen_nests
  destroyed_nests ; list of the nests destroyed during the expedition, or the patches noted as nests but safe
]

monsters-own
[
  health
  pain
  sound_target
]

globals
[
  checkpoints_number
  number_groups

  monsters_limit

  nests_to_destroy
  checkpoints_seen
  nests_asked ; list with nest targets
  nests_asked_delay ; list with the delays for the nests tasks
  checkpoints_asked
  checkpoints_asked_delay
  last_seen_humans ; list to compose with dead agents
]

to setup
  clear-all
  setup-constants
  setup-patches
  setup-humans
  update-patches
  ;update-display
  reset-ticks
end

to restart
  ask humans [die]
  ask monsters [die]
  setup-constants
  reinit-patches
  setup-humans
  update-patches
  reset-ticks
end


to setup-constants
  set monsters_limit 300
  set number_groups 0

  set nests_to_destroy []
  set checkpoints_seen []
  set nests_asked []
  set nests_asked_delay []; list with the delays for the nests tasks
  set checkpoints_asked []
  set checkpoints_asked_delay []
  set last_seen_humans []; list to compose with dead agents
end

to setup-patches
  ask patches [ set cell_type 0
    set delay 0
    set last_light 0
    set nearest_nest nobody
  ]
  ask patch 0 0 [set cell_type 3
  set delay fire_wood_init]
  set checkpoints_number 0
  ask patches with [pxcor mod checkpoints_distances = 0 and pycor mod checkpoints_distances = 0]
  [
    set checkpoints_number checkpoints_number + 1
    set checkpoint checkpoints_number
  ]
  set checkpoints_seen n-values checkpoints_number [0]
  ask n-of tree_number_init patches with [cell_type != 3] [set cell_type 1]

  print([delay] of patch 0 0)
  print([delay] of patch 1 0)
  print([delay] of patch 0 1)
end

to reinit-patches
  ask patches [
    set delay 0
    set last_light 0
    set nearest_nest nobody
  ]
  ask patches with [cell_type = 2]
  [
    set cell_type 0
  ]
  set checkpoints_seen n-values checkpoints_number [0]
  ask patch 0 0 [set cell_type 3
  set delay fire_wood_init]
end

to setup-humans
  ask patch 0 0
  [
    sprout-humans number_humans
    [
      set group 0
      set leader 0
      set follows nobody
      set task 0
      set tool 0
      set target nobody
      set patch_wait nobody
      set fulfillable true
      set health 10
      set pain false
      set cells_to_see []
      set seen_nests []
      set destroyed_nests []
    ]
  ]
  ask one-of humans [set leader 2]
end

to update-patches
  ask patches with [cell_type = 0 and last_light > 50]
  [
    if (nearest_nest = nobody)
    [
    set cell_type 2
    ask patches with [distance myself < nest_distances]
    [
      set nearest_nest myself
      set pcolor pink
    ]
    set pcolor blue
    ]
  ]
  ask patch 0 0 [print(delay)]
  ask patches with [delay > 0]
  [set delay (delay - 1)]
  ask patches with [delay = 0 and cell_type = 2]
  [
    if count monsters < monsters_limit
    [
      sprout-monsters 1
      [
        set health 1
        set pain false
        set sound_target nobody
      ]
    ]
    set delay delay_nests
  ]
end

to destroy-nest
  set cell_type 0
  set delay 0
  ask patches with [distance myself < nest_distances]
  [
    set nearest_nest one-of patches with [distance myself < nest_distances and cell_type = 2]
    set last_light 0
  ]
end

to update-display
  ask patches [set pcolor black
    set last_light last_light + 1
    if (cell_type = 1) [ifelse (delay = 0) [set pcolor 53] [set pcolor 32]]
    if (cell_type = 2) [set pcolor 15]
    if (cell_type = 3) [set pcolor 45]
  ]
  ask patch 0 0 [
    let light delay * ratio_light_wood
    ask other patches with [distance myself < light]
    [
      set last_light 0
      ifelse (pcolor = 0) [set pcolor 42]
      [
        ifelse (pcolor = 53) [set pcolor 65]
        [
          ifelse (pcolor = 32) [set pcolor 23]
          [
            if (pcolor = 15)
            [
              destroy-nest
              set pcolor 42
            ]
          ]
        ]
      ]
    ]
    ask monsters with [distance myself < light] [die]
  ]
  ask humans with [tool = 4]
  [
    let light range_light_torch
    ask patches with [distance myself < light]
    [
      set last_light 0
      ifelse (pcolor = 0) [set pcolor 42]
      [
        ifelse (pcolor = 53) [set pcolor 65]
        [
          ifelse (pcolor = 32) [set pcolor 23]
          [
            if (pcolor = 15)
            [
              set pcolor 42
            ]
          ]
        ]
      ]
    ]
    ask monsters with [distance myself < light] [die]

  ]
  ask humans
  [
    ifelse leader = 2
    [
      if shape != "star" [ set shape "star" ]
    ]
    [
      if tool = 0
      [
        if shape != "person" [ set shape "person" ]
      ]
      if tool = 1
      [
        if shape != "triangle 2" [ set shape "triangle 2" ]
      ]
      if tool = 2
      [
        if shape != "triangle" [ set shape "triangle" ]
      ]
      if tool = 3
      [
        if shape != "square" [ set shape "square" ]
      ]
      if tool = 4
      [
        if shape != "circle" [ set shape "circle" ]
      ]
    ]
    ifelse pain = true [set color red] [set color blue]
  ]
  ask monsters
  [
    if shape != "bug" [ set shape "bug" ]
    ifelse pain = true [set color red] [ifelse sound_target = nobody [set color green] [set color orange]]
  ]
end

to give-task-wood
  set number_groups number_groups + 1
  let point_to_check min-one-of patches with [checkpoint > 0 and not(member? self checkpoints_asked)] [item (checkpoint - 1) checkpoints_seen]
  if point_to_check = nobody
  [
    set point_to_check min-one-of patches with [checkpoint > 0] [item (checkpoint - 1) checkpoints_seen]
  ]
  ask n-of (team_wood_swords + team_wood_bows + team_wood_axes) humans with [task = 0 and leader = 0 and group = 0]
  [
    set task 1
    set fulfillable true
    set target point_to_check
    set group number_groups
    set cells_to_see n-values checkpoints_number [0]
    set follows nobody
    set leader 0
    set seen_nests []
  ]
  let tail nobody
  ask one-of humans with [group = number_groups]
  [
    set leader 1
    set tail self
  ]
  ask humans with [group = number_groups and leader = 0]
  [
    set follows tail
    set tail self
  ]
  ask n-of team_wood_bows humans with [group = number_groups and tool = 0] [set tool 1]
  ask n-of team_wood_swords humans with [group = number_groups and tool = 0] [set tool 2]
  ask n-of team_wood_axes humans with [group = number_groups and tool = 0] [set tool 3]

  set checkpoints_asked lput point_to_check checkpoints_asked
  set checkpoints_asked_delay lput 0 checkpoints_asked_delay
  print("wood task given")
  print(checkpoints_asked)
end

to give-task-nest
  set number_groups number_groups + 1
  let nest nobody
  foreach nests_to_destroy
  [
    x -> ask x
    [
      if nest = nobody and not (member? x nests_asked)
      [
        set nest self
      ]
    ]
  ]
  ask n-of (team_nest_swords + team_nest_bows + team_nest_torchs) humans with [task = 0 and leader = 0 and group = 0]
  [
    set task 2
    set fulfillable true
    set target nest
    set group number_groups
    set cells_to_see n-values checkpoints_number [0]
    set follows nobody
    set leader 0
    set seen_nests []
  ]
  let tail nobody
  ask one-of humans with [group = number_groups]
  [
    set leader 1
    set tail self
  ]
  ask humans with [group = number_groups and leader = 0]
  [
    set follows tail
    set tail self
  ]
  ask n-of team_nest_bows humans with [group = number_groups and tool = 0] [set tool 1]
  ask n-of team_nest_swords humans with [group = number_groups and tool = 0] [set tool 2]
  ask n-of team_nest_torchs humans with [group = number_groups and tool = 0] [set tool 4]

  set nests_asked lput nest nests_asked
  set nests_asked_delay lput 0 nests_asked_delay
  print("nest task given")
end

to update-groups
  ask humans with [leader = 0]
  [
    ifelse task = 0
    [
      set follows nobody
      set group 0
    ]
    [
      if follows != nobody
      [ if ((distance follows > 5) or ([group] of follows = 0)) [set follows nobody]]
      if follows = nobody ; for the ones which are lost
      [
        ;We create a new group
        let follower one-of humans with [follows = myself]
        set leader 1
        set number_groups number_groups + 1
        set group number_groups
        set patch_wait nobody
        while [follower != nobody]
        [
          ask follower
          [
            set group number_groups
            set follower one-of humans with [follows = myself]
            set patch_wait nobody
          ]
        ]
      ]
    ]
  ]
  ask humans with [leader = 1 and task != 3]
  [
    ;Check if the group has still enough members to achieve the task
    let bow 0
    let sword 0
    let othertool 0
    ask humans with [group = [group] of myself]
    [
      if tool = 1 [set bow bow + 1]
      if tool = 2 [set sword sword + 1]
      if tool = 3 and task = 1 [set othertool othertool + 1]
      if tool = 4 and task = 2 [set othertool othertool + 1]
    ]
    ask humans with [group = [group] of myself]
    [
      if task = 1 [set fulfillable (bow >= team_wood_bows and sword >= team_wood_swords and othertool >= team_wood_axes)]
      if task = 2 [set fulfillable (bow >= team_nest_bows and sword >= team_nest_swords and othertool >= team_nest_torchs)]
      if task = 3 [set fulfillable true]
    ]
  ]
  ask humans with [fulfillable = false] [set patch_wait nobody]
  ask humans with [leader = 1 and fulfillable = false] ;groups that can't achieve their goals will join their forces to another group
  [
    let nearest_human min-one-of humans with [distance myself <= 5 and group != 0 and group != [group] of myself and task = 3] [distance myself] ;priority for those who already did their task
    if nearest_human = nobody
    [
      set nearest_human min-one-of humans with [distance myself <= 5 and group != 0 and group != [group] of myself] [distance myself]
    ]
    if nearest_human != nobody ;merge the two groups !
    [
      set leader 0
      let follower one-of humans with [group = [group] of nearest_human and follows = nearest_human]
      while [follower != nobody]
      [
        set nearest_human follower
        set follower one-of humans with [group = [group] of nearest_human and follows = nearest_human]
      ]
      set follows nearest_human
      let common_task [task] of nearest_human
      let common_target [target] of nearest_human
      if common_task = 3
      [
        set common_task task
        set common_target target
      ]
      ask humans with [group = [group] of myself]
      [
        set group [group] of nearest_human
        set patch_wait [patch_wait] of nearest_human
      ]
      ask humans with [group = [group] of myself]
      [
        set task common_task
        set target common_target
      ]
    ]
  ]
end

to update_visibility
  let cells_seen cells_to_see
  let already_seen_nests seen_nests
  ask patches with [distance myself < 5 and checkpoint != 0]
  [
    set cells_seen (replace-item (checkpoint - 1) [cells_to_see] of myself ticks)
  ]
  ask patches with [distance myself < 5 and cell_type = 2]
  [
    if not (member? self already_seen_nests)
    [
      set already_seen_nests lput self already_seen_nests
    ]
  ]
  set cells_to_see cells_seen
  set seen_nests already_seen_nests
end

to make-noise
  ask monsters with [distance myself < 10]
  [
    set sound_target [patch-here] of myself
  ]
end

to move-humans
  let whoami self
  let nearest_monster min-one-of monsters with [distance myself < 5] [distance myself]
  let action_done false
  if (nearest_monster != nobody)
  [
    ifelse tool = 2
    [ifelse distance nearest_monster < 1 [sword-attack] [set heading (towards nearest_monster)
      forward 1]
      set action_done true
    ]
    [ifelse distance nearest_monster < 3 [
      if distance nearest_monster > 0 [set heading (towards nearest_monster + 180)]
      forward 1
      set action_done true
      ]
      [
        if tool = 1
        [
          bow-attack
          set action_done true
        ]
      ]
    ]
  ]
  if action_done = false
  [
    if (task = 3 or (task > 0 and fulfillable = false)) and patch-here = patch 0 0
    [
      print(whoami)
      print(task)
      if tool = 5 [ask patch 0 0 [set delay delay + 10]]
      set group 0
      set leader 0
      set follows nobody
      set task 0
      set tool 0
      set target nobody
      set patch_wait nobody
      set fulfillable true
      set pain false
      foreach seen_nests
      [
        x -> ask x
        [
          if not (member? (self) nests_to_destroy) [set nests_to_destroy lput self nests_to_destroy]
        ]
      ]
      foreach destroyed_nests
      [
        x -> ask x
        [
          if member? self nests_to_destroy
          [
            set nests_to_destroy remove self nests_to_destroy
            if member? self nests_asked
            [
              let index position self nests_asked
              set nests_asked remove-item index nests_asked
              set nests_asked_delay remove-item index nests_asked_delay
            ]
          ]
        ]
      ]
      set seen_nests []
      set destroyed_nests []

      foreach range checkpoints_number
      [
        x ->
        if item x cells_to_see > item x checkpoints_seen
        [
          set checkpoints_seen replace-item x checkpoints_seen (item x cells_to_see)
          let patch_x one-of patches with [checkpoint = x + 1]
          if member? patch_x checkpoints_asked
          [
            let index position patch_x checkpoints_asked
            print ("removed :")
            print(patch_x)
            set checkpoints_asked remove-item index checkpoints_asked
            set checkpoints_asked_delay remove-item index checkpoints_asked_delay
          ]
        ]
      ]
    ]

    ifelse task != 0
    [
      ifelse patch_wait != nobody
      [
        ifelse patch_wait != patch-here
        [
          set heading (towards patch_wait)
          fd 1
        ]
        [
          if tool = 3 and task = 1 and [cell_type] of patch_wait = 1
          [
            set tool 5
            make-noise
            ask patch_wait [set delay delay_trees]
            ask humans with [group = [group] of myself]
            [
              set task 3
              set target patch 0 0
              set patch_wait nobody
            ]
          ]
          if tool = 4 and task = 2
          [
            if [cell_type] of patch_wait = 2
            [
              set tool 0
              make-noise
              ask patch_wait [destroy-nest]
            ]
            ask humans with [group = [group] of myself]
            [
              set task 3
              set target patch 0 0
              set destroyed_nests lput patch_wait destroyed_nests
              set patch_wait nobody
            ]
            print("nest destroyed !")
          ]
        ]
      ]

      [
        ifelse leader = 0
        [
          if distance follows > 1
          [
            set heading (towards follows)
            fd 1
          ]
        ]
        [
          ifelse fulfillable = false
          [
            set heading (towards patch 0 0)
            fd 1
          ]
          [
            if task = 1
            [
              let nearest_tree min-one-of patches with [cell_type = 1 and delay = 0 and distance myself <= 5] [distance myself]
              if nearest_tree != nobody
              [
                ask humans with [group = [group] of myself]
                [
                  set patch_wait nearest_tree
                ]
                set action_done true
              ]
            ]
            if action_done = false
            [
              ifelse target != patch-here
              [
                set heading (towards target)
                fd 1
              ]
              [
                ifelse task = 2
                [
                  ask humans with [group = [group] of myself]
                  [
                    set patch_wait target
                  ]
                ]
                [
                  let unseen_checkpoints patches with [checkpoint != 0 and (item (checkpoint - 1) [cells_to_see] of myself) = 0]
                  ifelse count unseen_checkpoints = 0
                  [
                    let point_to_check one-of patches with [checkpoint = (position (min [cells_to_see] of myself) [cells_to_see] of myself) + 1]
                    ask humans with [group = [group] of myself]
                    [
                      set target point_to_check
                    ]
                  ]
                  [
                    ask humans with [group = [group] of myself]
                    [
                      set target min-one-of unseen_checkpoints [distance myself]
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]
      ]
    ]
    [
      if patch-here != patch 0 0
      [
        set heading (towards patch 0 0)
        forward 1
      ]
    ]
  ]
end

to move-monster
  let nearest min-one-of humans with [distance myself < 5] [distance myself]
  ifelse (nearest != nobody)
  [
    set sound_target nobody
    ifelse distance nearest < 1 [monster-attack] [set heading (towards nearest)
      forward 1]
  ]
  [
    if patch-here = sound_target [set sound_target nobody]
    ifelse sound_target != nobody [set heading (towards sound_target)] [set heading random 360]
    forward 1
  ]
  if distance patch 0 0 < [delay * ratio_light_wood] of patch 0 0
  [
    set heading (towards patch 0 0)
    forward -1
  ]
  let nearest_torch  min-one-of humans with [distance myself < range_light_torch and tool = 4] [distance myself]
  if nearest_torch != nobody
  [
    set heading (towards nearest_torch)
    forward -1
  ]
end

to sword-attack
  let attack_target min-one-of monsters with [distance myself < 1] [distance myself]
  if attack_target != nobody [ask attack_target [lose-health]]
end

to bow-attack
  let attack_target min-one-of monsters with [distance myself > 3 and distance myself < 5] [distance myself]
  if attack_target != nobody [ask attack_target [lose-health]]
end

to monster-attack
  let attack_target min-one-of humans with [distance myself < 1] [distance myself]
  if attack_target != nobody
  [ask attack_target [lose-health]]
end

to lose-health
  set health health - 1
  set pain true
  make-noise
  if health <= 0 [die]
end

to master-decisions
  set checkpoints_asked_delay map [x -> x + 1] checkpoints_asked_delay
  set nests_asked_delay map [x -> x + 1] nests_asked_delay
  let index 0
  while [index < length nests_asked_delay]
  [
    ifelse item index nests_asked_delay >= (distance (item index nests_asked)) * 2 + delay_for_nest_task
    [
      set nests_asked_delay remove-item index nests_asked_delay
      set nests_asked remove-item index nests_asked
    ]
    [
      set index index + 1
    ]
  ]
  set index 0
  while [index < length checkpoints_asked_delay]
  [
    ifelse item index checkpoints_asked_delay >= (distance (item index checkpoints_asked)) * 2 + delay_for_wood_task
    [
      set checkpoints_asked_delay remove-item index checkpoints_asked_delay
      set checkpoints_asked remove-item index checkpoints_asked
    ]
    [
      set index index + 1
    ]
  ]
  let count_for_wood team_wood_swords + team_wood_bows + team_wood_axes
  let count_for_nest team_nest_swords + team_nest_bows + team_nest_torchs
  if count humans with [group = 0 and leader = 0 and task = 0] >= count_for_nest and count_for_nest > 0
  [
    if length nests_to_destroy > length nests_asked and [delay] of (patch 0 0) >= wood_necessary_before_nests
    [
      give-task-nest
    ]
  ]
  if count humans with [group = 0 and leader = 0 and task = 0] >= count_for_wood and count_for_wood > 0
  [
    give-task-wood
  ]
end

to check-anomalies
  ask humans with [leader = 1]
  [
    if count humans with [leader = 1 and group = [group] of myself] > 1
    [
      print("Error detected !")
      print(group)
    ]
  ]
end

to go
  ask humans [set pain false]
  ask monsters [set pain false]
  update-groups
  ask humans with [leader = 2] [master-decisions]
  ask humans [ move-humans ]
  ask humans with [group != 0] [update_visibility]
  ask monsters [move-monster]
  update-patches
  update-display
  ;check-anomalies
  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
420
10
1043
634
-1
-1
15.0
1
10
1
1
1
0
0
0
1
-20
20
-20
20
1
1
1
ticks
30.0

BUTTON
10
25
85
70
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
200
25
275
70
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
0

BUTTON
105
25
180
70
NIL
restart
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
10
115
182
148
team_wood_swords
team_wood_swords
0
50
1.0
1
1
NIL
HORIZONTAL

SLIDER
10
155
182
188
team_wood_bows
team_wood_bows
0
50
5.0
1
1
NIL
HORIZONTAL

SLIDER
10
195
182
228
team_wood_axes
team_wood_axes
1
50
7.0
1
1
NIL
HORIZONTAL

SLIDER
10
275
182
308
team_nest_swords
team_nest_swords
0
50
2.0
1
1
NIL
HORIZONTAL

SLIDER
10
315
182
348
team_nest_bows
team_nest_bows
0
50
2.0
1
1
NIL
HORIZONTAL

SLIDER
10
355
182
388
team_nest_torchs
team_nest_torchs
1
50
1.0
1
1
NIL
HORIZONTAL

TEXTBOX
10
100
200
126
Team constitutions for wood tasks
10
0.0
1

TEXTBOX
10
260
175
286
Team constitutions for nest tasks
10
0.0
1

TEXTBOX
10
415
160
433
Parameters for simulation
10
0.0
1

SLIDER
10
450
185
483
tree_number_init
tree_number_init
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
10
490
185
523
number_humans
number_humans
0
200
33.0
1
1
NIL
HORIZONTAL

SLIDER
10
530
185
563
delay_nests
delay_nests
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
10
570
185
603
delay_trees
delay_trees
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
10
610
185
643
wood_necessary_before_nests
wood_necessary_before_nests
0
500
100.0
1
1
NIL
HORIZONTAL

SLIDER
220
570
392
603
ratio_light_wood
ratio_light_wood
0
1
0.01
0.01
1
NIL
HORIZONTAL

SLIDER
10
650
185
683
range_light_torch
range_light_torch
0
10
4.0
1
1
NIL
HORIZONTAL

SLIDER
220
450
392
483
nest_distances
nest_distances
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
220
490
392
523
delay_for_nest_task
delay_for_nest_task
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
220
530
392
563
delay_for_wood_task
delay_for_wood_task
0
100
50.0
1
1
NIL
HORIZONTAL

INPUTBOX
220
650
390
710
fire_wood_init
1000.0
1
0
Number

SLIDER
220
610
392
643
checkpoints_distances
checkpoints_distances
0
100
5.0
1
1
NIL
HORIZONTAL

PLOT
1070
25
1410
175
plot 1
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
"default" 1.0 0 -16777216 true "" "plot count humans"

@#$#@#$#@
## ACKNOWLEDGMENT

This model is an alternate visualization of the Virus model from the Biology section of the NetLogo Models Library. It uses visualization techniques as recommended in the paper:

* Kornhauser, D., Wilensky, U., & Rand, W. (2009). Design guidelines for agent based model visualization. Journal of Artificial Societies and Social Simulation (JASSS), 12(2), 1. http://ccl.northwestern.edu/papers/2009/Kornhauser,Wilensky&Rand_DesignGuidelinesABMViz.pdf.

## WHAT IS IT?

This model simulates the transmission and perpetuation of a virus in a human population. This version includes alternative visualizations of the model.

Ecological biologists have suggested a number of factors which may influence the survival of a directly transmitted virus within a population. (Yorke, et al. "Seasonality and the requirements for perpetuation and eradication of viruses in populations." Journal of Epidemiology, volume 109, pages 103-123)

## HOW IT WORKS

The model is initialized with 150 people, of which 10 are infected.  People move randomly about the world in one of three states: healthy but susceptible to infection (green), sick and infectious (red), and healthy and immune (gray). People may die of infection or old age.  When the population dips below the environment's "carrying capacity" (set at 300 in this model) healthy people may produce healthy (but susceptible) offspring.

Some of these factors are summarized below with an explanation of how each one is treated in this model.

### The density of the population

Population density affects how often infected, immune and susceptible individuals come into contact with each other. You can change the size of the initial population through the NUMBER-PEOPLE slider.

### Population turnover

As individuals die, some who die will be infected, some will be susceptible and some will be immune.  All the new individuals who are born, replacing those who die, will be susceptible.  People may die from the virus, the chances of which are determined by the slider CHANCE-RECOVER, or they may die of old age.

In this model, people die of old age at the age of 50 years.  Reproduction rate is constant in this model.  Each turn, if the carrying capacity hasn't been reached, every healthy individual has a 1% chance to reproduce.

### Degree of immunity

If a person has been infected and recovered, how immune are they to the virus?  We often assume that immunity lasts a lifetime and is assured, but in some cases immunity wears off in time and immunity might not be absolutely secure.  In this model, immunity is secure, but it only lasts for a year.

### Infectiousness (or transmissibility)

How easily does the virus spread?  Some viruses with which we are familiar spread very easily.  Some viruses spread from the smallest contact every time.  Others (the HIV virus, which is responsible for AIDS, for example) require significant contact, perhaps many times, before the virus is transmitted.  In this model, infectiousness is determined by the INFECTIOUSNESS slider.

### Duration of infectiousness

How long is a person infected before they either recover or die?  This length of time is essentially the virus's window of opportunity for transmission to new hosts. In this model, duration of infectiousness is determined by the DURATION slider.

### Hard-coded parameters

Four important parameters of this model are set as constants in the code (See `setup-constants` procedure). They can be exposed as sliders if desired. The turtles’ lifespan is set to 50 years, the carrying capacity of the world is set to 300, the duration of immunity is set to 52 weeks, and the birth-rate is set to a 1 in 100 chance of reproducing per tick when the number of people is less than the carrying capacity.

## HOW TO USE IT

Each "tick" represents a week in the time scale of this model.

The INFECTIOUSNESS slider determines how great the chance is that virus transmission will occur when an infected person and susceptible person occupy the same patch.  For instance, when the slider is set to 50, the virus will spread roughly once every two chance encounters.

The DURATION slider determines the number of weeks before an infected person either dies or recovers.

The CHANCE-RECOVER slider controls the likelihood that an infection will end in recovery/immunity.  When this slider is set at zero, for instance, the infection is always deadly.

The SETUP button resets the graphics and plots and randomly distributes NUMBER-PEOPLE in the view. All but 10 of the people are set to be green susceptible people and 10 red infected people (of randomly distributed ages).  The GO button starts the simulation and the plotting function.

The TURTLE-SHAPE chooser controls whether the people are visualized as person shapes or as circles.

When the SHOW-AGE? switch is on, each agent's age in years is displayed as its label.

When the WATCH-A-PERSON? switch is on, a single person at random, the subject, is selected for watching. The subject leaves a trail when it moves, green when the subject is healthy and red when it is sick. An inspector window is opened for that person. When the subject becomes infected, a link is created between the subject and the person who infected him. If one of those people dies, the link disappears. If the subject dies, a new subject is selected.

Three output monitors show the percent of the population that is infected, the percent that is immune, and the number of years that have passed.  The plot shows (in their respective colors) the number of susceptible, infected, and immune people.  It also shows the number of individuals in the total population in blue.

## THINGS TO NOTICE

The factors controlled by the three sliders interact to influence how likely the virus is to thrive in this population.  Notice that in all cases, these factors must create a balance in which an adequate number of potential hosts remain available to the virus and in which the virus can adequately access those hosts.

Often there will initially be an explosion of infection since no one in the population is immune.  This approximates the initial "outbreak" of a viral infection in a population, one that often has devastating consequences for the humans concerned. Soon, however, the virus becomes less common as the population dynamics change.  What ultimately happens to the virus is determined by the factors controlled by the sliders.

Notice that viruses that are too successful at first (infecting almost everyone) may not survive in the long term.  Since everyone infected generally dies or becomes immune as a result, the potential number of hosts is often limited.  The exception to the above is when the DURATION slider is set so high that population turnover (reproduction) can keep up and provide new hosts.

## THINGS TO TRY

Think about how different slider values might approximate the dynamics of real-life viruses.  The famous Ebola virus in central Africa has a very short duration, a very high infectiousness value, and an extremely low recovery rate. For all the fear this virus has raised, how successful is it?  Set the sliders appropriately and watch what happens.

The HIV virus, which causes AIDS, has an extremely long duration, an extremely low recovery rate, but an extremely low infectiousness value.  How does a virus with these slider values fare in this model?

## EXTENDING THE MODEL

Add additional sliders controlling the carrying capacity of the world (how many people can be in the world at one time), the average lifespan of the people and their birth-rate.

Build a similar model simulating viral infection of a non-human host with very different reproductive rates, lifespans, and population densities.

Add a slider controlling how long immunity lasts. You could also make immunity imperfect, so that immune turtles still have a small chance of getting infected. This chance could get higher over time.

## VISUALIZATION

The alternative visualization of the model comes from guidelines presented in
Kornhauser, D., Wilensky, U., & Rand, W. (2009). http://ccl.northwestern.edu/papers/2009/Kornhauser,Wilensky&Rand_DesignGuidelinesABMViz.pdf.

* The SHOW-AGE? visualization enables the user to track individual agents' lifespans.

* The WATCH-A-PERSON visualization enables the user to focus on one subject and to see the "micro-level" interactions, to view which agent infects the subject. You can observe the green trail of a healthy individual, which becomes red when the person gets infected. Additionally, you can see the individual who transmitted the virus linked to the subject by a line.

## RELATED MODELS

* HIV
* Virus
* Virus on a Network

## CREDITS AND REFERENCES

This model shows alternate visualizations of the Virus model. It uses visualization techniques as recommended in the paper:

Kornhauser, D., Wilensky, U., & Rand, W. (2009). Design guidelines for agent based model visualization. Journal of Artificial Societies and Social Simulation, JASSS, 12(2), 1.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1998).  NetLogo Virus - Alternative Visualization model.  http://ccl.northwestern.edu/netlogo/models/Virus-AlternativeVisualization.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1998 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227.

<!-- 1998 -->
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
NetLogo 6.3.0
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
1
@#$#@#$#@

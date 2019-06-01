;;Franzini Francesco 912857 FM2019 Project

(asdf:operate 'asdf:load-op 'ae2sbvzot)
(use-package :trio-utils)

(defvar *ncells* (loop for x from 1 to 12 collect x));;{1..12}

(defun adjacent (n1 n2) ;Returns true iff n1 and n2 are the indexes of two adjacent cells in the grid
   (||
        (= n1 n2) ;Each cell is adjacent to itself
        
        (&& (&& (/= n1 4) (/= n1 8) (/= n1 12)) (= n2 (+ n1 1))) ; if not on right border, one right
        (&& (&& (/= n1 1) (/= n1 5) (/= n1 9) ) (= n2 (- n1 1))) ; if not on left border, one left
        
        (= n2 (- n1 4)) ;up one column
        (= n2 (+ n1 4)) ;down one column
        
        (&& (&& (/= n1 4) ) (= n2 (+ n1 5))) ;if not in 4, go SouthEast
        (&& (&& (/= n1 9) ) (= n2 (- n1 5))) ;if not in 9, go NorthWest
        
        (&& (&& (/= n1 4) (/= n1 8) (/= n1 12)) (= n2 (- n1 3))) ;if not on right border, go NorthEast
        (&& (&& (/= n1 1) (/= n1 5) (/= n1 9) ) (= n2 (+ n1 3))) ;if not on left border, go SouthWest
   )
)


;;ROBOT Specification

(defconstant robotPredicates
       (alw 
           (<-> (-P- robotMoving)
            (-E- p1 *ncells* (-E- p2 *ncells* (&& (/= p1 p2) (-P- robotIn p1) (next (-P- robotIn p2))));The robot is moving iff current position and future position are different
           ))
           
        )
)

(defvar robotAlwaysSomewhere ;Asserts that there always exists an unique position for the robot
    (alw 
        (-E- a *ncells* 
            (&&
                (-P- robotIn a) ;Exists a valid position for the robot
                (!!(-E- b *ncells* 
                    (&& 
                        (/= b a)
                        (-P- robotIn b) ;This position is unique
                    )))
            )
        )
))
    
    
(defconstant realisticRobotMovement
    (-A- a *ncells* 
        (alw
            (-> (yesterday (-P- robotIn a)) (-E- b *ncells* ;If robot was in a cell a last time instant
                (&&
                  (-P- robotIn b)
                    (adjacent a b) ;robot can be in a position b only if it is adjacent to cell a
                ))
            )
            
        )
    )
)

(defconstant robotState ;Defines the automaton modeling the robot
    (alw (&&
            (!! (&& (-P- robotToL9) (-P- robotToL3)))
            (!! (&& (-P- robotWorking) (-P- robotToL9)))
            (!! (&& (-P- robotWorking) (-P- robotToL3)))
            (|| (-P- robotWorking) (-P- robotToL9) (-P- robotToL3)) ;exactly one of those propositions is true at each time
            
            (-> (&& (-P- robotToL9) (next (-P- robotIn 9)))  (next (-P- robotWorking))) ;If next time robot reaches 9, start working
            (-> (&& (-P- robotToL9) (next(!! (-P- robotIn 9)))) (next (-P- robotToL9))) ;If next time robot doesn't reach 9, keep going
            
            (-> (&& (-P- robotToL3) (next (-P- robotIn 3)))  (next (-P- robotWorking))) ;If next time robot reaches 3, start working
            (-> (&& (-P- robotToL3) (next(!! (-P- robotIn 3)))) (next (-P- robotToL3))) ;If next time robot doesn't reach 3, keep going
            
            (-> (&& (-P- robotWorking) (next (-P- robotWorking)) (-P- robotIn 3))  (next (-P- robotIn 3))) ; If robot is working in 3 and will work next time, stay in 3
            (-> (&& (-P- robotWorking) (next (-P- robotToL9)) (-P- robotIn 3))  (next (!!(-P- robotIn 3)))); If robot is working in 3 and change state, next time instant go away from 3
            (-> (&& (-P- robotWorking) (-P- robotIn 3))  (!! (next (-P- robotToL3)))) ; If robot is working in 3 it can only keep working or go to robotToL9 state
            
            (-> (&& (-P- robotWorking) (next (-P- robotWorking)) (-P- robotIn 9))  (next (-P- robotIn 9))) ; If robot is working in 9 and will work next time, stay in 9
            (-> (&& (-P- robotWorking) (next (-P- robotToL3)) (-P- robotIn 9))  (next (!!(-P- robotIn 9)))); If robot is working in 9 and change state, next time go away from 9
            (-> (&& (-P- robotWorking) (-P- robotIn 9))  (!! (next (-P- robotToL9)))) ; If robot is working in 9 it can only keep working or go to robotToL3 state
            
))) 


(defconstant robotController ;Defines a controller for the robot
    (alw (&&
            (!! (&& (-P- collision) (-P- robotMoving)));The controller stops the robot if an operator is in the same cell
            
            ;Entering an area where an operator is going is not acceptable
            (-A- p *ncells* (-> (&& (next (-P- operatorIn p)) (-P- robotMoving) )  (!!(next (-P- robotIn p))) ))
    
            ;If robot is going to 9 and it is in an adjacent cell to it, either it goes to destination or it is blocked by operator and stops, no useless deviation
            (-> 
                (-P- robotToL9) 
                (-> (-E- p *ncells* (&& (-P- robotIn p) (adjacent p 9))) #|implies|# (|| (next (-P- robotIn 9)) (&& (next(-P- operatorIn 9)) (!! (-P- robotMoving)) ) )  )
            )
            
            ;If robot is going to 3 and it is in an adjacent cell to it, either it goes to destination or it is blocked by operator and stops, no useless deviation
            (-> 
                (-P- robotToL3) 
                (-> (-E- p *ncells* (&& (-P- robotIn p) (adjacent p 3))) #|implies|# (|| (next (-P- robotIn 3)) (&& (next(-P- operatorIn 3)) (!! (-P- robotMoving)) ) )  )
            )

)))

;OPERATOR Specification
(defconstant operatorPredicates
       (alw 
           (<-> (-P- operatorMoving)
            (-E- p1 *ncells* (-E- p2 *ncells* (&& (/= p1 p2) (-P- operatorIn p1) (next (-P- operatorIn p2))))
           ))
           
           
        )
)

(defvar operatorAlwaysSomewhere ;Asserts that there always exists an unique position for the operator
    (alw 
        (-E- a *ncells* 
            (&&
                (-P- operatorIn a)
                (!!(-E- b *ncells* 
                    (&& 
                        (/= b a)
                        (-P- operatorIn b)
                    )))
            )
        )
))
    
(defconstant realisticOperatorMovement
    (-A- a *ncells* 
        (alw
            (-> (yesterday (-P- operatorIn a)) (-E- b *ncells* 
                (&&
                  (-P- operatorIn b)
                    (adjacent a b)
                ))
            )
            
        )
    )
)

(defconstant operatorState ;Defines the automaton modeling the operator
    (alw (&&
            (!! (&& (-P- operatorToL10) (-P- operatorToL8)))
            (!! (&& (-P- operatorWorking) (-P- operatorToL10)))
            (!! (&& (-P- operatorWorking) (-P- operatorToL8)))
            (|| (-P- operatorWorking) (-P- operatorToL10) (-P- operatorToL8)) ;exactly one of those propositions is true at each time
            
            (-> (&& (-P- operatorToL10) (next (-P- operatorIn 10)))  (next (-P- operatorWorking))) ;If next time operator reaches 10, start working
            (-> (&& (-P- operatorToL10) (next(!! (-P- operatorIn 10)))) (next (-P- operatorToL10))) ;If next time operator doesn't reach 10, keep going
            
            (-> (&& (-P- operatorToL8) (next (-P- operatorIn 8)))  (next (-P- operatorWorking))) ;If next time operator reaches 8, start working
            (-> (&& (-P- operatorToL8) (next(!! (-P- operatorIn 8)))) (next (-P- operatorToL8))) ;If next time operator doesn't reach 8, keep going
            
            (-> (&& (-P- operatorWorking) (next (-P- operatorWorking)) (-P- operatorIn 8))  (next (-P- operatorIn 8))) ; If operator is working in 8 and will work next time, stay in 8
            (-> (&& (-P- operatorWorking) (next (-P- operatorToL10)) (-P- operatorIn 8))  (next (!!(-P- operatorIn 8)))); If operator is working in 8 and change state, next time go away from 8
            (-> (&& (-P- operatorWorking) (-P- operatorIn 8))  (!! (next (-P- operatorToL8)))) ; If operator is working in 8 it can only keep working or go to operatorToL10 state
            
            (-> (&& (-P- operatorWorking) (next (-P- operatorWorking)) (-P- operatorIn 10))  (next (-P- operatorIn 10))) ; If operator is working in 10 and will work next time, stay in 10
            (-> (&& (-P- operatorWorking) (next (-P- operatorToL8)) (-P- operatorIn 10))  (next (!!(-P- operatorIn 10)))); If operator is working in 10 and change state, next time go away from 10
            (-> (&& (-P- operatorWorking) (-P- operatorIn 10))  (!! (next (-P- operatorToL10)))) ; If operator is working in 10 it can only keep working or go to operatorToL8 state
            
))) 


;Constraints imposed by location
(defconstant forbiddenPlaces
                (alw 
                    (&& 
                        (!!(-P- robotIn 4))
                        (!!(-P- operatorIn 4))
                    ))
)


;Initial conditions
(defconstant init
    (&&
            (-P- robotIn 3)
            (-P- operatorIn 10)
            (-P- robotWorking)
            (-P- operatorWorking)
            
            ;debug
            ;(-P- robotIn 5)
            ;(-P- operatorIn 6)
            ;(-P- robotToL9)
            ;(next(-P- robotIn 10))
            ;(next(-P- operatorIn 10))
            ;(next (next (-P- robotIn 3)))
            ))
    
;Objective property
(defconstant collision
    (alw 
        (<-> (-P- collision) (-E- p *ncells* (&& (-P- operatorIn p)(-P- robotIn p) )))
))

(defconstant collisionEnforcer ;Defines the property that must make the model unsatisfiable
    ;(somF (&& (-P- collision) (-P- robotMoving))) ;Moving collision
    (somF (|| 
            (&& (-P- collision) (-P- robotMoving))
            (&& (next (-P- collision)) (-P- robotMoving))  
        )) ;Moving collision or robot converging to operator position 
)

(defconstant niceSimulation ;Defines axioms that force the simulation to show a couple of iterations instead of random paths
    (&&
        (next (!! (-P- robotIn 3))) ;Next time instant go to robotToL9 state
        (next (somF (&& (-P- robotWorking) (-P- robotIn 3)))) ;Counting from next time instant, the robot does at least a full loop
        
        (next (!! (-P- operatorIn 10))) ;Next time instant go to operatorToL8 state
        (next (somF (&& (-P- operatorWorking) (-P- operatorIn 10)))) ;Counting from next time instant, the operator does at least a full loop

))


(ae2sbvzot:zot 30
        (yesterday(&&
                    
                    init
                    
                    ;Robot axioms
                    forbiddenPlaces
                    robotPredicates
                    realisticRobotMovement
                    robotAlwaysSomewhere
                    robotState
                    robotController
                    
                    ;Operator axioms
                    operatorPredicates
                    realisticOperatorMovement
                    operatorAlwaysSomewhere
                    operatorState
                    
                    ;Collision definition
                    collision
                    collisionEnforcer ;Comment this out to have a satisfiable model, leave it in to check safety property
                    
                    ;Simulation guiding
                    niceSimulation
                ))
    )

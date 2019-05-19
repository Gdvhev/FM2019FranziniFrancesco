;;Franzini Francesco 912857 FM2019 Project

(asdf:operate 'asdf:load-op 'ae2sbvzot)
(use-package :trio-utils)

(defvar *ncells* (loop for x from 1 to 12 collect x));;{1..12}

(defun adjacent (n1 n2)
   (||
        (= n1 n2)
        
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
            (-E- p1 *ncells* (-E- p2 *ncells* (&& (/= p1 p2) (-P- robotIn p1) (next (-P- robotIn p2))));the robot is moving if current position and future position are different
           ))
           
        )
)

(defvar robotAlwaysSomewhere
    (alw 
        (-E- a *ncells* 
            (&&
                (-P- robotIn a) ;;exists a valid position for the robot
                (!!(-E- b *ncells* 
                    (&& 
                        (/= b a)
                        (-P- robotIn b) ;;this position is unique
                    )))
            )
        )
))
    
    
(defconstant realisticRobotMovement
    (-A- a *ncells* 
        (alw
            (-> (yesterday (-P- robotIn a)) (-E- b *ncells* 
                (&&
                  (-P- robotIn b)
                    (adjacent a b) ;;robot can be in a position b only if it was in an adjacent cell a
                ))
            )
            
        )
    )
)

(defconstant robotState
    (alw (&&
            (!! (&& (-P- robotToL9) (-P- robotToL3)))
            (!! (&& (-P- robotWorking) (-P- robotToL9)))
            (!! (&& (-P- robotWorking) (-P- robotToL3)))
            (|| (-P- robotWorking) (-P- robotToL9) (-P- robotToL3)) ;exactly one of those proposition is true at each time
            
            (-> (&& (-P- robotToL9) (next (-P- robotIn 9)))  (next (-P- robotWorking))) ;If next time I reach 9, start working
            (-> (&& (-P- robotToL9) (next(!! (-P- robotIn 9)))) (next (-P- robotToL9))) ;If next time I don't reach 9, keep going
            
            (-> (&& (-P- robotToL3) (next (-P- robotIn 3)))  (next (-P- robotWorking))) ;If next time I reach 3, start working
            (-> (&& (-P- robotToL3) (next(!! (-P- robotIn 3)))) (next (-P- robotToL3))) ;If next time I don't reach 3, keep going
            
            (-> (&& (-P- robotWorking) (next (-P- robotIn 3)) (-P- robotIn 3))  (next (-P- robotWorking))) ;If I am working in 3 and I don't move, keep working
            (-> (&& (-P- robotWorking) (next (!!(-P- robotIn 3))) (-P- robotIn 3))  (next (-P- robotToL9))) ;If I am working in 3 and I  move, go to 9
            (-> (&& (-P- robotWorking) (next (!!(-P- robotIn 9))) (-P- robotIn 9))  (next (-P- robotToL3))) ;If I am working in 9 and I  move, go to 3
            (-> (&& (-P- robotWorking) (next (-P- robotIn 9)) (-P- robotIn 9))  (next (-P- robotWorking))) ;If I am working in 9 and I don't move, keep working
            
))) 


(defconstant robotController
    (alw (&&
            (!! (&& (-P- collision) (-P- robotMoving)));This means that the controller stops the robot if an operator is in the same cell
            
            ;Entering an area where an operator is going is not acceptable(assuming next operator position is known)
            (-A- p *ncells* (-> (&& (next (-P- operatorIn p)) (-P- robotMoving) )  (!!(next (-P- robotIn p))) ))
    
            ;If robot is going to 9 and it is in an adjacent cell to it, either it goes to destination or it is blocked by operator and stops, no useless deviation
            (-> (-P- robotToL9) (-> (-E- p *ncells* (&& (-P- robotIn p) (adjacent p 9))) #|implies|# (|| (next (-P- robotIn 9)) (&& (next(-P- operatorIn 9)) (!! (-P- robotMoving)) ) )  ))
            
            ;If robot is going to 3 and it is in an adjacent cell to it, either it goes to destination or it is blocked by operator and stops, no useless deviation
            (-> (-P- robotToL3) (-> (-E- p *ncells* (&& (-P- robotIn p) (adjacent p 3))) #|implies|# (|| (next (-P- robotIn 3)) (&& (next(-P- operatorIn 3)) (!! (-P- robotMoving)) ) )  ))

)))

;OPERATOR Specification
(defconstant operatorPredicates
       (alw 
           (<-> (-P- operatorMoving)
            (-E- p1 *ncells* (-E- p2 *ncells* (&& (/= p1 p2) (-P- operatorIn p1) (next (-P- operatorIn p2))))
           ))
           
           
        )
)

(defvar operatorAlwaysSomewhere
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
            
            ;debug
            ;(-P- robotIn 5)
            ;(-P- operatorIn 6)
            ;(-P- robotToL9)
            ;(next(-P- robotIn 10))
            ;(next(-P- operatorIn 10))
            ))
    
;Objective property
(defconstant collision
    (alw 
        (<-> (-P- collision) (-E- p *ncells* (&& (-P- operatorIn p)(-P- robotIn p) )))
))

(defconstant collisionEnforcer
    ;(somF (&& (-P- collision) (-P- robotMoving))) ;Moving collision
    ;(somF  (-P- collision) ) ;Simple collision
    (somF (|| (&& (-P- collision) (-P- robotMoving)) (&& (next (-P- collision)) (-P- robotMoving))  )) ;Moving collision and converging to operator position 
)
    
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
                    
                    ;Collision definition
                    collision
                    collisionEnforcer
                ))
    )

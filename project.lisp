(asdf:operate 'asdf:load-op 'ae2sbvzot)
(use-package :trio-utils)

(defvar *ncells* (loop for x from 1 to 12 collect x))

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

(defvar robotAlwaysSomewhere
    (alw 
        (-E- a *ncells* 
            (&&
                (-P- robotIn a)
                (!!(-E- b *ncells* 
                    (&& 
                        (/= b a)
                        (-P- robotIn b)
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
                    (adjacent a b)
                ))
            )
            
        )
    )
)

            
(defconstant init
    (-P- robotIn 3))
    
(ae2sbvzot:zot 10
        (yesterday(&&
                    robotAlwaysSomewhere
                    init
                    realisticRobotMovement
                ))
    )

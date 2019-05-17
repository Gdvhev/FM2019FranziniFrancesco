(asdf:operate 'asdf:load-op 'ae2sbvzot)
(use-package :trio-utils)


(defvar spec
	(alw ;invariant of our system is:
		( &&
			(!! (&& (-P- on) (-P- off)));not (on and off)
			 ; (<->  (-P- lamp) (since (!! (-P- off)) (-P- on)))
			 (-> (-P- on) (lasts (!!(-P- on)) 5));on implies not on for 5 instants
			 (-> (&& (!!(-P- lamp)) (yesterday(-P- lamp))) (|| (-P- off) (lasted (-P- lamp) 5))); lamp switched off implies button off or timeout
)))


(defconstant init
	(&& (!! (-P- lamp))));begins lamp off

; (format t "~S" *spec*)
(ae2sbvzot:zot 10
		(yesterday(&&
					spec
					init
					(SomF (lasts (-P- lamp) 5))
					(SomF (-P- off))
					(SomF (-P- on))
				))
	)

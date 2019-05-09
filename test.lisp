(asdf:operate 'asdf:load-op 'ae2sbvzot)
(use-package :trio-utils)


(defvar spec
	(alw
		( &&
			(!! (&& (-P- on) (-P- off)))
			 ; (<->  (-P- lamp) (since (!! (-P- off)) (-P- on)))
			 (-> (-P- on) (lasts (!!(-P- on)) 5))
			 (-> (&& (!!(-P- lamp)) (yesterday(-P- lamp))) (|| (-P- off) (lasted (-P- lamp) 5)))
)))


(defconstant init
	(&& (!! (-P- lamp))))

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

;;;;;;;;;;;;;;;;;;;;;;;;;;

(load "model-parm.lisp")
(load "rand_perm.lisp")


;;;;;;; Tools for work with trees in lists ;;;;;;;

;;; Create a node: to make a format fallow by all other functions
;;; That's way works very well to precessing trees as lists.

(defun make-node (data)
    (cons (cons data nil) nil)
)

;;; Returns a reference to the first child of the node passed in,
;;; or nil if this node does not have children.

(defun first-child (tree)
    (cdr (car tree))
)

;;; Returns a reference to the next sibling of the node passed in,
;;; or nil if this node does not have any siblings.

(defun next-sibling (tree)
    (cdr tree)
)

;;; Returns a reference to the next sibling of the node passed in,
;;; or nil if this node does not have any siblings.

(defun next-sibling-null (tree)
    (cond 
        (
            (null (cdr tree))
            (cdr tree)
        )
        (
            t
            (next-sibling-null (cdr tree))
        )
    )
)

;;; Returns the information contained in this node.

(defun data (tree)
    (car (car tree))
)

;;; Takes two nodes created with 'make-node' and adds the
;;; second node as a child of the first. Returns the first node,
;;; which will be modified. 

(defun add-child (tree child)
    (nconc (car tree) child)
    tree
)

;;; Takes two nodes created with 'make-node' and adds the
;;; second node as a child of the first. Returns the first node,
;;; which will be modified.
(defun add-brother (tree child)
    (nconc tree child)
    tree
)

;;;;;;;;;;;;;;; Sample processing ;;;;;;;;;;;;;;;;;

(defun rfs-gen-config (SS mSS)
    (lotto-select (+ mSS (random (+ (- SS mSS) 1))) SS)
)

(defun rfs-set-config (new-sample rfs-config sample)
    (setf new-sample (cons (nth (car rfs-config) sample) new-sample))
    (cond
        (
            (null (cdr rfs-config))
            (setf new-sample (cons (first sample) new-sample))
            new-sample
        )
        (
            t
            (rfs-set-config new-sample (cdr rfs-config) sample)
        )
    )
)

(defun load-samples (filename Ts)
 (let
        (
            (dataset '())
            (i 0)
            (file (open filename :direction :input))
        )
        (do
            (
                (row (read file nil :EOF) (read file nil :EOF))
            )
            (
                (equal row :EOF)
            )
            (incf i 1)
            (setf dataset (cons row dataset))
            (when (equal i Ts)
                (return-from load-samples dataset)
            )
        )
        dataset
    )
)

(defun random-access (lista)
    (nth (random (length lista)) lista)
)

;;;;;;;;;;;;;;;;; Load datasets ;;;;;;;;;;;;;;;;;;;


(defvar *filetest* (load-samples "dataset.test" *TSamples_test*))
(defvar *filetrain* (load-samples "dataset.training" *TSamples_train*))
(defvar *fileprune* (load-samples "dataset.training" *TSamples_train*))

;;;;;;;;;;;;;;;;;;; Tree part ;;;;;;;;;;;;;;;;;;;;;

;;; Create the branch if the value's feature not exist.

(defun create-branch (tree sample)
    (add-child tree (make-node (car sample)))
    (cond 
        (
            (null (cdr sample))
            (add-child tree (make-node '1))
            (if (equal (car sample) (car *targets*))
                (add-child tree (make-node (car (cdr *targets*))))
                (add-child tree (make-node (car *targets*)))
            )
            (add-child tree (make-node '0))
        )
        (
            t
            (create-branch (first-child tree) (cdr sample))
        )
    )
)

;;; If the tree is new, create a entaire branch with one sample.

(defun create-tree-rfs (sample rfs-config)
    (let ((tree (make-node rfs-config)))
        (create-branch tree sample)
        (car tree)
    )
)

;;; Make the branchs and add points for *targets* (if the branch
;;; already exist).

(defun grow-tree (tree sample)
    (cond
        (
            (null (cdr sample))
            (cond
                (
                    (equal (car (car tree)) (car sample))
                    (setf (caar (cdr tree)) (+ (caar (cdr tree)) 1))
                )
                (
                    t
                    (setf (caar (cdddr tree)) (+ (caar (cdddr tree)) 1))
                )
            )
        ) 
        (
            (equal (data tree) (car sample))
            (grow-tree (first-child tree) (cdr sample))
        )
        (
            (not (null (next-sibling tree)))
            (grow-tree (next-sibling tree) sample)

        )
        (
            t
            (add-brother tree (make-node (car sample)))
            (create-branch (next-sibling tree) (cdr sample))
        )

    )
)

;;; Build the tree given a Ts samples to use.

(defun build-tree-limt-rfs (Ts)
    (let
        (
            (tree '())
            (sample '())
            (rfs-config (rfs-gen-config *total-fetures* 2))
        )
        (do
            (
                (row (random-access *filetrain*) (random-access *filetrain*))
                (i 0 (+ i 1))
            )
            (
                (equal i Ts)
            )
            (setf sample (rfs-set-config (last row) rfs-config (cons 'ROOT row)))
            (cond
                (
                    (null tree)
                    (setf tree (create-tree-rfs sample rfs-config))
                )
                (
                    t
                    (grow-tree (cdr tree) sample)
                )
            )
        )
        tree
    )
)


(defun use-tree (tree sample)
    (cond
        (
            (null (cdr sample))
            (cond
                (
                    (equal (car (car tree)) (car sample))
                    (- (caar (cdr tree)) (caar (cdddr tree)))
                )
                (
                    t
                    (- (caar (cdddr tree)) (caar (cdr tree)))
                )
            )  
        )
        (
            (equal (data tree) (car sample))
            (use-tree (first-child tree) (cdr sample))
        )
        (
            (not (null (next-sibling tree)))
            (use-tree (next-sibling tree) sample)
        )
        (
            t
            '0
        )
    )
)

;;;;;;;;;;;;;;;;;;; Forest part ;;;;;;;;;;;;;;;;;;;

;;; Pruning

(defun use-tree-full-rfs (tree Ts database)
    (let
        (
            (i 0)
            (n 0)
            (sample '())
            (valor 0)
        )
        (do
            (
                (row (random-access database) (random-access database))
                (j 0 (+ j 1))
            )
            (
                (equal j Ts)
            )
            (setf sample (rfs-set-config (last row) (car tree) (cons 'ROOT row)))
            (setf valor (use-tree (cdr tree) sample))
            (if (> valor 0)
                (incf i 1)
            )
            (incf n 1)
        )
        (float (/ i n))
    )
)

;;; Build the forest

(defun build-forest (forest num-trees nsamples min-prec)
    (let*
        (
            (tree (build-tree-limt-rfs nsamples))
            (valor (use-tree-full-rfs tree nsamples *fileprune*))
        )
        (cond
            (
                (< num-trees 1)
                forest
            )
            (
                (< valor min-prec)
                (build-forest forest num-trees nsamples min-prec)
            )
            (
                t
                (format t "Remain trees: ~S, rec: ~S~%" num-trees valor)
                (build-forest (cons tree forest) (- num-trees 1) nsamples min-prec)
            )
        )
    )
)

(defun use-forest (forest row valor)
    (let
        (
            (sample (rfs-set-config (last row) (car (car forest)) (cons 'ROOT row)))
        )
        (cond
            (
                (null (cdr forest))
                ;(format t "~S~%" sample)
                (+ (use-tree (cdr (car forest)) sample) valor)
            )
            (
                t
                ;(format t "~S~%" sample)
                (use-forest (cdr forest) row (+ (use-tree (cdr (car forest)) sample) valor))
            )
        )
    )
)

;;;;;;;;;;;;;;;;; test functions ;;;;;;;;;;;;;

(defun use-tree-forest-full-rfs (forest Ts)
    (let
        (
            (i 0)
            (n 0)
            (valor 0)
        )
        (do
            (
                (row (random-access *filetest*) (random-access *filetest*))
                (j 0 (+ j 1))
            )
            (
                (equal j Ts)
            )
            ;(format t "~S~%" row)
            (setf valor (use-forest forest row 0))
            ;(format t "~S~%" valor)
            (if (> valor 0)
                (incf i 1)
            )
            (incf n 1)
        )
        (float (/ i n))
    )
)

(defun use-tree-forest-rfs-rounds (forest Ts R)
    (let
        (
            (results '())
        )
        (dotimes (n R)
            (setf results (cons (use-tree-forest-full-rfs forest Ts) results))
        )
        results
    )
)

; EOF
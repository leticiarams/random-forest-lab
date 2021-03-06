;;;;;;;;;;;;;
; Parameters file.

; Name for this dataset (or set of parameters).
(defvar *dataset-name* "; MNIST dataset.")

; Wich features are numeric? 
; Features position: '(1 3 4)
; All features are numeric: t
; No numeric features: nil
(defvar *num-fetures* t)
; Total features:
(defvar *total-fetures* '782) 
; Minimal quantities of features tu use to build the trees:
(defvar *min-fetures-sample* 2)
; Maximal quantities of features tu use to build the trees:
(defvar *max-fetures-sample* 150)
; Targets? 
(defvar *targets* '("0" "1" "2" "3" "4" "5" "6" "7" "8" "9"))

; Model parameters.

; Number os trees in the forest:
(defvar *NTrees* 210)
; How much samples will be used to build the trees?
(defvar *NSamples* 3000)
; To prune the worst trees with low rating accuracy.
; Prune below THPrec.
(defvar *THPrec* 0.99)
; N prunes limit to decrease THPrec
(defvar *n_prune_limit* 1000)

; Test rounds 
(defvar *TRounds* 20)
; Load the datasets to memory
(defvar *TSamples_train* 1000)
(defvar *TSamples_test* 1000)

; 16280 dataset.test.csv
; 32561 dataset.training.csv
; 48841 total
; Without samples with missing data:
; 15059 dataset.test.csv
; 30162 dataset.training.csv
; 45221 total

;EOF
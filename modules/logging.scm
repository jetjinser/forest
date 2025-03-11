(define-module (logging)
  #:export (log trace debug info warning err)
  #:use-module (srfi srfi-19) ; Date
  #:use-module (ice-9 hash-table))

;; ==== level ====

(define logging-level
  (string->symbol (or (getenv "LOGGING_LEVEL")
                      "DEBUG")))

(define level-prior
  (alist->hash-table
    '((TRACE . 5)
      (DEBUG . 4)
      (INFO . 3)
      (WARN . 2)
      (ERROR . 1))))

(define (on-level level)
  (<= (hash-ref level-prior level)
      (hash-ref level-prior logging-level)))

;; ==== color ====

(define (single-color text ansi-code)
  (string-append (string #\esc #\[) "0;" ansi-code "m"
                 (simple-format #f "~a" text)
                 (string #\esc #\[) "0m"))

(define (black text)
  (single-color text "30"))

(define (cyan text)
  (single-color text "36"))

(define (white text)
  (single-color text "37"))

(define (yellow text)
  (single-color text "33"))

(define (red text)
  (single-color text "31"))

;; ==== logging ====

(define (format-level level)
  (let ([level-string (symbol->string level)])
    (string-append "["
      (case level
        ((TRACE) => black)
        ((DEBUG) => cyan)
        ((INFO) => white)
        ((WARN) => yellow)
        ((ERROR) => red))
      "]"
      (make-string (- 5 (string-length level-string))
                   #\space))))

(define (log level message . args)
  (when (on-level level)
        (simple-format (current-error-port)
                       "[~a] ~a ~a~%"
                       (black (date->string (current-date) "~5"))
                       (format-level level)
                       (apply simple-format #f message args))))

(define (trace message . args)
  (apply log 'TRACE message args))

(define (debug message . args)
  (apply log 'DEBUG message args))

(define (info message . args)
  (apply log 'INFO message args))

(define (warning message . args)
  (apply log 'WARN message args))

(define (err message . args)
  (apply log 'ERROR message args))

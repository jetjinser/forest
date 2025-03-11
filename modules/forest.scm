(define-module (forest)
  #:export (all-trees)
  #:use-module (ice-9 ftw))

(define (all-trees file-path)
  (define *first-level* #t)
  (define (enter? name stat result)
    ;; dont enter recursively
    (and *first-level* (set! *first-level* #f)))

  (define (xml? filename)
    (string-suffix? ".xml" filename))
  (define (leaf name stat result) ; maybe process here? good idea?
    (if (xml? (basename name))
      (cons name result)
      result))

  (define (down name stat result) result)
  (define (up name stat result) result)
  (define (skip name stat result) result)
  (define (error name stat errno result)
    (warning "warning: ~a: ~a" name (strerror errno))
    result)

  (file-system-fold enter? leaf down up skip error
                    (list)
                    file-path))

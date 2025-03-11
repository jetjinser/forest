(define-module (forest)
  #:export (all-trees remove-unused-files!)
  #:use-module (logging)
  #:use-module (ice-9 ftw))

(define (all-files file-path pred)
  (define *first-level* #t)
  (define (enter? name stat result)
    ;; dont enter recursively
    (and *first-level* (set! *first-level* #f)))

  (define (leaf name stat result) ; maybe process here? good idea?
    (if (pred (basename name))
      (cons name result)
      result))

  (define (down name stat result) result)
  (define (up name stat result) result)
  (define (skip name stat result) result)
  (define (error name stat errno result)
    (warning "warning: ~a: ~a" name (strerror errno))
    result)

  (file-system-fold enter? leaf down up skip error
                    (list) file-path))

(define (all-trees file-path)
  (all-files file-path (λ (fn) (string-suffix? ".xml" fn))))

(define (all-unused-files-when-done file-path)
  (all-files file-path
             (λ (fn)
                (or (string-suffix? ".xml" fn)
                    (string-suffix? ".xsl" fn)
                    (member fn '("package.json"
                                 "package-lock.json"
                                 "pnpm-lock.yaml"))))))

(define (remove-unused-files! file-path)
  (let ([unused-files (append (all-unused-files-when-done file-path))])
    (for-each (λ (fn) (debug "`deleting ~a`" fn)
                      (delete-file fn))
              unused-files)))

#!/usr/bin/env -S nix shell nixpkgs#guile ./nix#x-rs --command guile -e 'main' -q -s
!#

(use-modules (ice-9 ftw)
             (ice-9 string-fun)
             (ice-9 match)
             (ice-9 regex)
             (rnrs io ports)
             (sxml simple)
             (sxml match)
             (sxml transform))

(define (stderr . args)
  (apply format (cons (current-error-port) args)))

;; highlight

;; TODO: guile-ts
(define (ts-highlight code lang)
  (let* ([input+output (pipe)]
         [pid (spawn "x-rs" `("x-rs" ,code ,lang)
                     #:output (cdr input+output))]
         [html (begin (close-port (cdr input+output))
                      (get-string-all (car input+output)))])
    (close-port (car input+output))
    (if (= 0 (cdr (waitpid pid)))
      html
      #f)))

(define (highlight)
  (let lp ([trees (all-trees "output")])
    (match trees
      [() (stderr "highlight done~%")]
      [(tree . trees)
       (stderr "highlighting ~a~%" (basename tree))
       (highlight-tree tree)
       (lp trees)])))

(define ns '((fr . "http://www.jonmsterling.com/jms-005P.xml")
             (html . "http://www.w3.org/1999/xhtml")))
(define (transform-ns ns)
  (map (λ (pair)
          (cons (symbol-append 'xmlns: (car pair))
                (cdr pair)))
       ns))

(define (highlight-tree tree-file)
  (let* ([port (open-input-file tree-file)]
         [tree (xml->sxml port
                          #:namespaces ns
                          #:declare-namespaces? #f)])
    (close-port port)
    (with-output-to-file tree-file
                         (λ () (sxml->xml (pre-post-order tree highlighter))))))

(define match-code
  (λ node
     (sxml-match node
        [(html:code (@ (lang ,lang) (class ,cls)) ,code)
         (guard (string=? cls "highlight"))
         (stderr "[~a]~%" lang)
         (let ([h (ts-highlight (string-trim-both code) lang)])
           (or (and h (html-span (xml->sxml (string-append "<html:code>" (string-trim-both h)
                                                           "</html:code>")
                                            #:namespaces ns)))
               code))]
        [,otherwise otherwise])))
(define highlighter
  `([html:code . ,match-code]
    [fr:tree . ,(λ (tag attr . content) (cons tag (cons (append attr (transform-ns ns)) content)))]
    [*text* . ,(λ (tag content) content)]
    [*default* . ,(λ args args)]))

(define (html-span sxml)
  (define transformer
    `([span . ,(λ (tag . content) (cons (string->symbol (string-append "html:" (symbol->string tag)))
                                        content))]
      [*text* . ,(λ (tag content) content)]
      [*default* . ,(λ args args)]))
  (pre-post-order sxml transformer))

;; xslt-transform

(define stylesheet-path "output/default.xsl")

(define (all-trees file-path)
  (define *first-level* #t)
  (define (enter? name stat result)
    (and *first-level* (set! *first-level* #f)))

  (define (xml? filename)
    (string-suffix? ".xml" filename))
  (define (leaf name stat result)
    (if (xml? (basename name))
      (cons name result)
      result))

  (define (down name stat result) result)
  (define (up name stat result) result)
  (define (skip name stat result) result)
  (define (error name stat errno result)
    (stderr "warning: ~a: ~a~%" name (strerror errno))
    result)

  (file-system-fold enter? leaf down up skip error
                    (list)
                    file-path))

(define (xslt-transform)
  (let lp ([trees (all-trees "output")])
    (match trees
      [() (stderr "xslt transform done~%")]
      [(tree . trees)
       (let ([tree-html (string-replace-substring tree ".xml" ".html")])
         (stderr "~a => ~a~%"
                 (basename tree)
                 (basename tree-html))
         (system* "xsltproc" "-o" tree-html
                  stylesheet-path tree)
         (lp trees))])))

(define (main args)
  (highlight))
  ; (xslt-transform))

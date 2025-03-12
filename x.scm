#!/usr/bin/env -S guile -L ./modules -e '(@ (x) main)' -q -s
!#

(define-module (x)
  #:export (main)
  #:use-module (logging)
  #:use-module (forest)
  #:use-module (parser)
  #:use-module (ice-9 string-fun)
  #:use-module (ice-9 match)
  #:use-module (ice-9 regex)
  #:use-module (rnrs io ports)
  #:use-module (sxml simple)
  #:use-module (sxml match)
  #:use-module (sxml transform)
  #:use-module (srfi srfi-171)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-1))

(define +forest+ "output")
(define +parsers-dir+ "parsers/")
(define +stylesheet-path+ "output/default.xsl")
(define +ns+ '((fr . "http://www.jonmsterling.com/jms-005P.xml")
               (html . "http://www.w3.org/1999/xhtml")))
(define +repo-triples+
  '(("alt-jinser"  "tree-sitter-bash"    "fad59bb")
    ("tree-sitter" "tree-sitter-c"       "2a265d6")
    ("tree-sitter" "tree-sitter-go"      "5e73f47")
    ("tree-sitter" "tree-sitter-rust"    "e86119b")
    ("tree-sitter" "tree-sitter-ocaml"   "91708de")
    ("tree-sitter" "tree-sitter-ruby"    "89bd7a8")
    ("tree-sitter" "tree-sitter-python"  "710796b")
    ("alt-jinser"  "tree-sitter-clojure" "2e5ad7a")
    ("alt-jinser"  "tree-sitter-erlang"  "ef7026b")
    ("alt-jinser"  "tree-sitter-scheme"  "33ef7cd")
    ("tree-sitter" "tree-sitter-haskell" "0975ef7")
    ("alt-jinser"  "tree-sitter-racket"  "2f14c15")
    ("alt-jinser"  "tree-sitter-julia"   "a0aaa43")
    ("alt-jinser"  "tree-sitter-nix"     "30e206c")
    ("alt-jinser"  "tree-sitter-kotlin"  "bb1d5d3")
    ("moonbitlang" "tree-sitter-moonbit" "f09031f")))
(define +repos+
  (map (cut apply make-reporef <>)
       +repo-triples+))


;; xslt-transform

;; TODO: rewrite it in apply-template
(define (xslt-transform)
  (let lp ([trees (all-trees +forest+)])
    (match trees
      [() (info "xslt transform done")]
      [(tree . trees)
       (let ([tree-html (string-replace-substring tree ".xml" ".html")])
         (debug "~a => ~a"
                (basename tree)
                (basename tree-html))
         (system* "xsltproc" "--encoding" "UTF8"
                  "-o" tree-html
                  +stylesheet-path+ tree)
         (lp trees))])))


;; save-tree

(define (save-tree tree)
  (let ([tree-fn (car tree)]
        [sxml (cdr tree)])
    (call-with-output-file tree-fn
                           (cut sxml->xml sxml <>))
    tree-fn))

;; highlight

;; TODO: rewrite it in guile-ts
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

(define (highlight tree)
  (define highlighter
    `([html:code . ,match-code]
      [*text* . ,(λ (tag content) content)]
      [*default* . ,(λ args args)]))
  (pre-post-order tree highlighter))

(define match-code
  (λ node
     (sxml-match node
        [(html:code (@ (lang ,lang) (class ,cls)) ,code)
         (guard (string=? cls "highlight"))
         (trace "highlighting lang `~a`" lang)
         (let ([h (ts-highlight (string-trim-both code) lang)])
           (or (and h (html-span (xml->sxml (string-append "<html:code>" (string-trim-both h)
                                                           "</html:code>")
                                            #:namespaces +ns+)))
               code))]
        [,otherwise otherwise])))

(define (html-span sxml)
  (define transformer
    `([span . ,(λ (tag . content) (cons (string->symbol (string-append "html:" (symbol->string tag)))
                                        content))]
      [*text* . ,(λ (tag content) content)]
      [*default* . ,(λ args args)]))
  (pre-post-order sxml transformer))


;; dotxml->html

(define (ext-xml->html xml-fn)
  (string-append (basename xml-fn "xml") "html"))

(define (dotxml->html tree)
  (define rewriter
    (λ node
       (sxml-match node
          [(href ,uri)
           (guard (string=? uri (basename uri))) ;; basename.ext
           `(href ,(ext-xml->html uri))]
          [(fr:route ,uri) `(fr:route ,(ext-xml->html uri))]
          [,otherwise otherwise])))
  (define matcher
    `([*text* . ,(λ (tag content) content)]
      [*default* . ,rewriter]))
  (pre-post-order tree matcher))


;; lift-namespaces

(define (ns-attrs ns)
  (map (match-lambda
         [(pref . uri)
          (cons (symbol-append 'xmlns: pref) (list uri))])
       ns))

(define (cleanup-xmlns attrs ns)
  (let* ([ns-prefix (map car ns)]
         [pred (λ (item)
                (if (pair? item)
                    (not (member (car item) ns-prefix))
                    #t))])
    (filter pred attrs)))

(define (lift-namespaces tree)
  (define (append-ns-attrs tag attrs . content)
    (let* ([ns-attrs-to-append (ns-attrs +ns+)]
           [cleaned-attrs (cleanup-xmlns attrs ns-attrs-to-append)]
           [new-attrs (append cleaned-attrs ns-attrs-to-append)])
      `(,tag ,new-attrs ,@content)))
  (define lifter
    `([fr:tree . ,append-ns-attrs]
      [*text* . ,(λ (tag content) content)]
      [*default* . ,(λ x x)]))
  (pre-post-order tree lifter))

;; transducer

(define (apply-tree tree f)
  (cons (car tree)
        (f (cdr tree))))
(define (pipe-tree f)
  (λ (tree) (apply-tree tree (cut f <>))))

(define (pipe-log label)
  (λ (tree) (debug "~a: ~a" label (car tree)) tree))


(define (read-tree tree-path)
  (let* ([port (open-input-file tree-path)]
         [sxml (xml->sxml port
                          #:namespaces +ns+
                          #:declare-namespaces? #f)])
    (close-port port)
    (cons tree-path sxml)))


(define transducer
  (compose
    (tmap read-tree)
    (tmap (pipe-tree lift-namespaces))
    (tmap (pipe-log "lifted"))
    (tmap (pipe-tree dotxml->html))
    (tmap (pipe-log "dotxml->html rewritten"))
    (tmap (pipe-tree highlight))
    (tmap (pipe-log "highlighted"))
    (tmap save-tree)))

;; main

(define (main args)
  (download-parsers +repos+ +parsers-dir+)
  (let ([tree-count (list-transduce transducer rcount
                                    (all-trees +forest+))])
    (info "transduced ~a trees" tree-count))

  (xslt-transform) ; TODO: in pipe
  (remove-unused-files! +forest+))

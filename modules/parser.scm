(define-module (parser)
  #:export (<reporef> make-reporef
            download-parsers)
  #:use-module (logging)
  #:use-module (srfi srfi-9)
  #:use-module (ice-9 binary-ports)
  #:use-module (web client)
  #:use-module (web response))

(define-record-type <reporef>
  (make-reporef owner name rev)
  reporef?
  (owner reporef-owner)
  (name  reporef-name)
  (rev   reporef-rev))

(define (github-archive-url reporef)
  (let ([owner (reporef-owner reporef)]
        [name  (reporef-name  reporef)]
        [rev   (reporef-rev   reporef)])
    (format #f "https://codeload.github.com/~a/~a/tar.gz/~a"
            owner name rev)))

;; TODO: looking for native way...
(define (unarchive file-path dest-dir)
  (let ([dir (string-append dest-dir (basename file-path ".tar.gz"))])
    (mkdir dir)
    (system* "tar" "xf" file-path
             "--strip-components" "1"
             "--directory" dir)
    (delete-file file-path)))

(define (download-parser reporef dest-dir)
  (let* ([url (github-archive-url reporef)]
         [output-file (string-append dest-dir
                                     (reporef-name reporef)
                                     ".tar.gz")] ; TODO: tempfile
         [response (begin (info "Downloading ~a to ~a... " url output-file)
                          (http-get url #:streaming? #t))])
    (if (= 200 (response-code response))
        (begin (call-with-output-file output-file
                 (λ (port) (put-bytevector port (read-response-body response))))
               (unarchive output-file dest-dir))
        (warning "Failed to download ~a: ~a" url response))))

(define (download-parsers lst dest-dir)
  (for-each (λ (reporef)
               (unless (file-exists? (string-append dest-dir (reporef-name reporef)))
                 (download-parser reporef dest-dir)))
            lst))

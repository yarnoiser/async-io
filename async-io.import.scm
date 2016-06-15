(module async-io (make-reader
                  reader?
                  reader-fd
                  reader-ready?
                  reader-has-token?
                  reader-get-token!
                  reader-read!
                  make-writer
                  writer?
                  writer-fd
                  writer-ready?
                  writer-finished?
                  writer-queue-output!
                  writer-write!
                  sep-scheme-expr
                  sep-line)

  (import chicken scheme)
  (use (srfi 13 14) posix)

  (define read-size 512)

  (define (fd-read-ready? fd)
    (receive (read-fds write-fds) (file-select (list fd) '() 0)
      (not (null? read-fds))))

  (define (fd-write-ready? fd)
    (receive (read-fds write-fds) (file-select '() (list fd) 0)
      (not (null? write-fds))))

  (define (whitespace? c)
    (char-set-contains? char-set:whitespace c))

  (define-record reader fd sep-proc token buff buff-chars)

  (define new-reader make-reader)

  (define (make-reader fd sep-proc)
    (file-control fd fcntl/setfl open/nonblock)
    (new-reader fd sep-proc "" "" 0))

  (define (reader-has-token? r)
    (not (zero? (string-length (reader-token r)))))

  (define (reader-get-token! r)
    (let ([token (reader-token r)])
      (reader-token-set! r "")
      token))

  (define (reader-ready? r)
    (fd-read-ready? (reader-fd r)))

  (define (reader-read! r)
    (receive (chars nchars) (apply values (file-read (reader-fd r) read-size))
      (if (zero? nchars)
        #!eof
        (let ([str (string-append (reader-buff r) (string-take chars nchars))])
          (receive (token rem) ((reader-sep-proc r) str)
            (reader-token-set! r token)
            (reader-buff-set! r rem))))))

  (define-record writer fd buff)

  (define new-writer make-writer)

  (define (make-writer fd)
    (file-control fd fcntl/setfl open/nonblock)
    (new-writer fd ""))

  (define (writer-queue-output! w str)
    (writer-buff-set! w (string-append (writer-buff w) str)))

  (define (writer-ready? w)
    (fd-write-ready? (writer-fd w)))

  (define (writer-finished? w)
    (zero? (string-length (writer-buff w))))

  (define (writer-buffer-add! w str)
    (writer-buff-set! w (string-append (writer-buff w) str)))

  (define (writer-write! w)
    (let ([nchars (file-write (writer-fd w) (writer-buff w))])
      (writer-buff-set! w (string-drop (writer-buff w) nchars))))

  (define (atom-sep-index str len index)
    (let loop ([i index])
      (cond
        [(= i len)
         i]
        [(eqv? (string-ref str i) #\()
         i]
        [(whitespace? (string-ref str i))
         i]
        [else
         (loop (add1 i))])))

  (define (list-sep-index str len index)
    (let loop ([i index] [open-par 0] [close-par 0])
      (cond
        [(and (= open-par close-par) (not (zero? open-par)))
         i]
        [(= i len)
         0]
        [(whitespace? (string-ref str i))
         (if (= open-par close-par)
          i
          (loop (add1 i) open-par close-par))]
        [(eqv? (string-ref str i) #\()
         (loop (add1 i) (add1 open-par) close-par)]
        [(eqv? (string-ref str i) #\))
         (loop (add1 i) open-par (add1 close-par))]
        [else
         (loop (add1 i) open-par close-par)])))

  (define (vector-sep-index str len index)
    (if (= len (sub1 index))
      0
      (list-sep-index str len (add1 index))))

  (define (ignore-comment str len index)
    (let loop ([i index])
      (cond
        [(eqv? i (sub1 len))
         #f]
        [(eqv? (string-ref str i) #\newline)
         i]
        [else
         (loop (add1 i))])))

  (define (scheme-expr-sep-index str)
    (let ([len (string-length str)])
      (let loop ([i 0])
        (cond
          [(= i len)
           0]
          [(whitespace? (string-ref str i))
           (loop (add1 i))]
          [(eqv? (string-ref str i) #\')
           (loop (add1 i))]
          [(eqv? (string-ref str i) #\`)
           (loop (add1 i))]
          [(eqv? (string-ref str i) #\()
           (list-sep-index str len i)]
          [(eqv? (string-ref str i) #\#)
           (vector-sep-index str len i)]
          [(eqv? (string-ref str i) #\;)
           (let ([after-comment (ignore-comment str len i)])
             (if after-comment
               (loop after-comment)
               0))]
          [else
            (atom-sep-index str len i)])) ))

  (define (sep-scheme-expr str)
    (let ([sep-index (scheme-expr-sep-index str)])
      (values (string-take str sep-index) (string-drop str sep-index))))

  (define (line-sep-index str)
    (let ([len (string-length str)])
      (let loop ([i 0])
        (cond
          [(= i len)
           0]
          [(eqv? (string-ref str i) #\newline)
           i]
          [else
           (loop (add1 i))] ))))

  (define (sep-line str)
    (let ([sep-index (line-sep-index str)])
      (values (string-take str sep-index) (string-drop str sep-index))))
)


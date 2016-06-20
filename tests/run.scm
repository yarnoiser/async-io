(use async-io posix)

(define-values (test-in test-out) (create-pipe))

(define (test-writer)
  (define writer (make-writer test-out))
  ; writer starts with no data
  (assert (writer-finished? writer))
  ; writer starts ready when pipe is open
  (assert (writer-ready? writer))
  ; writer properly enqueues data
  (writer-enqueue! writer "he")
  ; writer writes properly
  (writer-write! writer)
  ; we expect writer to have written all it's data to the pipe
  (assert (writer-finished? writer))
  ; sleep so reader does not get whole string right away
  (sleep 2)
  ; write the next string
  (writer-enqueue! writer "llo")
  (writer-write! writer)
  (assert (writer-finished? writer))
  ; send another token in 2 stages to make sure the reader can read multiple
  ; tokens
  (writer-enqueue! writer "h")
  (writer-write! writer)
  (sleep 1)
  (writer-enqueue! writer "el")
  (sleep 1)
  (writer-enqueue! writer "lo")
  ; clear write buffer
  (let loop ()
    (cond
      [(writer-finished? writer)
       (void)]
      [(writer-ready? writer)
       (begin (writer-write! writer)
              (loop))]
      [else
        (loop)])))

(define (sep-hello str)
  (if (equal? str "hello")
    (values str "")
    (values "" str)))

(define (reader-wait reader)
  (if (reader-ready? reader)
    (void)
    (reader-wait reader)))

; test basic reader
(define reader (make-reader test-in sep-hello))
; we should not be ready before writer process exists (no input yet)
(assert (not (reader-ready? reader)))
; fork so there is a running writer process
(let ([writer-pid (process-fork test-writer)])
  ; wait for input from writer
  (reader-wait reader)
  ; there should be input
  (assert (reader-ready? reader))
  (reader-read! reader)
  ; we should not have a token yet: writer only sends partial string
  (assert (not (reader-has-token? reader)))

  ; read until we get the token
  (let loop ()
    (cond
      [(reader-has-token? reader)
       (void)]
      [(reader-ready? reader)
       (begin (reader-read! reader)
              (loop))]
      [else
       (loop)]))
  ; we should have token now, writer should send the rest of it.
  (assert (reader-has-token? reader))
  (assert (equal? "hello" (reader-get-token! reader)))
  ; receive second token, in as many stages as it takes
  (let loop ()
    (cond
      [(reader-has-token? reader)
       (void)]
      [(reader-ready? reader)
       (begin (reader-read! reader)
              (loop))]
      [else
       (loop)]))
  (assert (equal? "hello" (reader-get-token! reader)))
  (file-close test-in)
  (receive (pid success status) (process-wait writer-pid)
    (assert (= status 0))))
; test sep-scheme-expr ======

; incomplete list expression
(receive (tok rem) (sep-scheme-expr "(+ 1")
  (assert (and (equal? tok "") (equal? rem "(+ 1"))))

; list expression
(receive (tok rem) (sep-scheme-expr "(+ 1 1)")
  (assert (and (equal? tok "(+ 1 1)") (equal? rem ""))))

; incomplete quoted list expression
(receive (tok rem) (sep-scheme-expr "'(+ 1")
  (assert (and (equal? tok "") (equal? rem "'(+ 1"))))

; quoted list expression
(receive (tok rem) (sep-scheme-expr "'(1 2 3)")
  (assert (and (equal? tok "'(1 2 3)") (equal? rem ""))))

; incomplete vector expression
(receive (tok rem) (sep-scheme-expr "#(1 2")
  (assert (and (equal? tok "") (equal? rem "#(1 2"))))

; vector expression
(receive (tok rem) (sep-scheme-expr "#(1 2 3)")
  (assert (and (equal? tok "#(1 2 3)") (equal? rem ""))))

; incomplete quoted vector expression
(receive (tok rem) (sep-scheme-expr "'#(1 2")
  (assert (and (equal? tok "") (equal? rem "'#(1 2"))))

; quoted vector expression
(receive (tok rem) (sep-scheme-expr "'#(1 2 3)")
  (assert (and (equal? tok "'#(1 2 3)") (equal? rem ""))))

; quoted atom
(receive (tok rem) (sep-scheme-expr "'hello")
  (assert (and (equal? tok "'hello") (equal? rem ""))))

; atom
(receive (tok rem) (sep-scheme-expr "hello")
  (assert (and (equal? tok "hello") (equal? rem ""))))

;two expressions
(receive (tok rem) (sep-scheme-expr "hello(world)")
  (assert (and (equal? tok "hello") (equal? rem "(world)"))))

; comment in the middle of partial expression
(receive (tok rem) (sep-scheme-expr "(hello ;world)")
  (assert (and (equal? tok "") (equal? rem "(hello ;world)"))))

; comment in the middle of whole expression
(receive (tok rem) (sep-scheme-expr "(hello ;world)\nworld)")
  (assert (and (equal? tok "(hello ;world)\nworld)") (equal? rem ""))))

; comment before expression
(receive (tok rem) (sep-scheme-expr ";hello\nworld")
  (assert (and (equal? tok ";hello\nworld") (equal? rem ""))))

; test sep-line =====
; test single line
(receive (tok rem) (sep-line "hello world\n")
  (assert (and (equal? tok "hello world\n") (equal? rem ""))))

; no new line
(receive (tok rem) (sep-line "hello world")
  (assert (and (equal? tok "") (equal? rem "hello world"))))

; test line plus more
(receive (tok rem) (sep-line "hello\n world")
  (assert (and (equal? tok "hello\n") (equal? rem " world"))))



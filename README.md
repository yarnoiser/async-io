# async-io
Asynchronous I/O Library for Chicken Scheme.

## Usage
```scheme
(use async-io)
```

### Readers
Readers are used to read strings from a file descriptor asynchronously and return tokens identified by a separator procedure.

#### make-reader
```
[procedure] (make-reader fd sep-proc)
```
Sets the file descriptor *fd* to non-blocking mode.
Returns a reader which is used to read input from the file descriptor *fd*.
This reader separates tokens using *sep-proc*.

#### reader?
```
[procedure] (reader? x)
```
Returns true if *x* is a reader object, otherwise returns false.

#### reader-fd
```
[procedure] (reader-fd x)
```
Returns the file descriptor belonging to reader *x*.

#### reader-ready?
```
[procedure] (reader-ready? x)
```
Returns true if there is input waiting to be read by the reader *x*.

#### thread-wait-for-reader!
```
[procedure] (thread-wait-for-reader! x)
```
Suspends the current thread until the file descriptor belonging to reader *x* is ready to be read.
Equivalent to:
```
(thread-wait-for-i/o! (reader-fd x))
```

#### reader-read!
```
[procedure] (reader-read! x)
```
Reads input from the file descriptor belonging to reader *x*.
Performs separation on any input read.
Throws an exception if there is no input to be read by the reader.

#### reader-has-token?
```
[procedure] (reader-has-token? x)
```
Returns true if the reader *x* has a complete token from it's input stream.
Otherwise returns false.

#### reader-get-token!
```
[procedure] (reader-get-token! x)
```
If reader *x* found a token using it's separator procedure during the last call to (reader-read! x),
then that token will be returned as a string. Otherwise an empty string is returned.

#### Example
Echo the first scheme expression from stdin.

```scheme
(define reader (make-reader fileno/stdin sep-scheme-expr))

(let loop ()
  (cond
    ((reader-has-token? reader)
     (print (reader-get-token! reader)))
    ((reader-ready? reader)
     (begin (reader-read! reader)
            (loop)))
    (else
     (loop))))
```

### Separator Procedures
Separator procedures are used by readers to identify tokens to be returned with *reader-get-token!*.
These procedures take a string to separate as an argument and return two values:
a token separated from the main string, and the remainder of the string after the token.
Token separation is done with every call to reader-read! before input is placed within a reader's buffer.
This egg comes with two pre-made separator procedure: sep-scheme-expr and sep-line.

### Example
The following separator procedure separates tokens delimited by commas.
```scheme
(use srfi-13)

(define (sep-comma str)
  (let ((len (string-length str)))
    (let loop ((i 0))
      (cond
        ((= i len)
         (values "" str))
        ((eqv? (string-ref str i) #\,)
         (values (string-take str (add1 i)) (string-drop str (add1 i))))
        (else
         (loop (add1 i)))))))

```

#### sep-scheme-expr
```
[procedure] (sep-scheme-expr str)
```
A separator procedure for scheme expressions (without chicken extensions). Returns two values:
The first value returned is the first complete scheme expression found in *str* or an empty string if no scheme
expressions were found. The second value returned is the remainder of the *str* after the first complete scheme expression,
or an empty string if there is no content after the first expression.

#### sep-line
```
[procedure] (sep-line str)
```
A separator procedure for lines. Returns two values:
The first value returned is the first line found in *str*, including the newline character.
The second value returned is the remainder of *str* after the first line, or an empty string if *str* only contained one line.

### Writers
Writers are used to asynchronously write strings to a file descriptor.

#### make-writer
```
[procedure] (make-writer fd)
```
Sets the file descriptor *fd* into non-blocking mode and returns a writer which is used to read input from *fd*.

#### writer?
```
[procedure] (writer? x)
```
Returns true if *x* is a writer. Otherwise returns false.

#### writer-fd
```
[procedure] (writer-fd x)
```
Returns the file descriptor belonging to the writer *x*.

#### writer-ready?
```
[procedure] (writer-ready? x)
```
Returns true if the file descriptor belonging to writer *x* is ready to be written to.
Otherwise returns false.

#### thread-wait-for-writer!
```
[procedure] (thread-wait-for-writer! x)
```
Suspends the current thread until the file descriptor belonging to writer *x* is ready to be written to.
Equivalent to:
```
(thread-wait-for-i/o! (writer-fd x))
```

#### writer-enqueue!
```
[procedure] (writer-enqueue! x str)
```
Places string *str* in writer *x*'s buffer. Portions of *str* will be written to *x*'s file descriptor on subsequent calls
to *writer-write!*.

#### writer-write!
```
[procedure] (writer-write! x)
```
Writes characters from writer *x*'s buffer to *x*'s file descriptor. Throws an exception if *x*'s file descriptor is not
ready to be written to.

#### writer-finished?
```
[procedure] (writer-finished? x)
```
Returns true if the writer *x* has nothing queued to be written to it's file descriptor.
Otherwise returns false.

#### Example
Write the string "hello, world!\n" to stdout using an async-io writer.

```scheme
(use async-io posix)

(define writer (make-writer fileno/stdout))

(writer-enqueue! writer "hello, world!\n")
(let loop ()
  (cond
    ((writer-finished? writer)
     (void))
    ((writer-ready? writer)
     (begin (writer-write! writer)
            (loop)))
    (else
     (loop))))
```

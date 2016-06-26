# async-io
Asynchronous I/O Library for Chicken Scheme.
This README is a work in progress

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

#### reader?
```
[procedure] (reader? x)
```

#### reader-fd
```
[procedure] (reader-fd x)
```

#### reader-ready?
```
[procedure] (reader-ready? x)
```

#### reader-read!
```
[procedure] (reader-read! x)
```

#### reader-has-token?
```
[procedure] (reader-has-token? x)
```

#### reader-get-token!
```
[procedure] (reader-get-token! x)
```

### Separator Procedures
Separator procedures are used by readers to identify tokens to be returned with *reader-get-token!*.
These procedures take a string to separate as an argument and return two values:
a token separated from the main string, and the remainder of the string after the token.
Token separation is done with every call to reader-read! before input is placed within a reader's buffer.
This egg comes with two pre-made separator procedure: sep-scheme-expr and sep-line.

#### sep-scheme-expr
```
[procedure] (sep-scheme-expr str)
```

#### sep-line
```
[procedure] (sep-line str)
```

### Writers
Writers are used to asynchronously write strings to a file descriptor.

#### make-writer
```
[procedure] (make-writer fd)
```

#### writer?
```
[procedure] (writer? x)
```

#### writer-fd
```
[procedure] (writer-fd x)
```

#### writer-ready?
```
[procedure] (writer-ready? x)
```

#### writer-finished?
```
[procedure] (writer-finished? x)
```

#### writer-enqueue!
```
[procedure] (writer-enqueue! x str)
```

#### writer-write!
```
[procedure] (writer-write! x)
```

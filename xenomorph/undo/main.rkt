#lang racket/base

(define-syntax-rule (r+p ID ...)
  (begin (require ID ...) (provide (all-from-out ID ...))))

(r+p "array.rkt"
     "base.rkt"
     "bitfield.rkt"
     "buffer.rkt"
     "enum.rkt"
     "lazy-array.rkt"
     "number.rkt"
     "optional.rkt"
     "pointer.rkt"
     "reserved.rkt"
     "string.rkt"
     "struct.rkt"
     "versioned-struct.rkt")
#lang debug racket/base
(require racket/dict
         racket/class
         racket/sequence
         racket/match
         racket/list
         racket/contract
         "base.rkt"
         "number.rkt"
         sugar/unstable/dict)
(provide (all-defined-out))

#|
approximates
https://github.com/mbutterick/restructure/blob/master/src/Struct.coffee
|#

(define (setup-private-fields port parent len)
  (define mheq (make-hasheq))
  (dict-set*! mheq
              x:parent-key parent
              x:start-offset-key (pos port)
              x:current-offset-key 0
              x:length-key len)
  mheq)

(define (parse-fields port mheq fields-arg)
  (define fields (if (x:dict? fields-arg) (get-field fields fields-arg) fields-arg))
  (unless (assocs? fields)
    (raise-argument-error 'x:dict-parse-fields "assocs" fields))
  (for ([(key type) (in-dict fields)])
    (define val (match type
                  [(? procedure? proc) (proc mheq)]
                  [_ (send type x:decode port mheq)]))
    (unless (void? val)
      (hash-set! mheq key val))
    (hash-set! mheq x:current-offset-key (- (pos port) (hash-ref mheq x:start-offset-key))))
  mheq)

(define x:dict%
  (class x:base%
    (super-new)
    (init-field [(@fields fields)])
    
    (when @fields (unless (dict? @fields)
                    (raise-argument-error '+xstruct "dict" @fields)))

    (define/augride (x:decode port parent [len 0])
      (define res (setup-private-fields port parent len))
      (parse-fields port res @fields))

    (define/override (post-decode val)
      (dict->mutable-hash val))

    (define/augride (x:encode field-data port [parent-arg #f])
      (unless (dict? field-data)
        (raise-result-error 'x:dict-encode "dict" field-data))
      ;; check keys, because `size` also relies on keys being valid
      (unless (andmap (λ (field-key) (memq field-key (dict-keys field-data))) (dict-keys @fields))
        (raise-argument-error 'x:dict-encode
                              (format "dict that contains superset of xstruct keys: ~a"
                                      (dict-keys @fields)) (dict-keys field-data))) 
      (define parent (mhasheq x:pointers-key null
                              x:start-offset-key (pos port)
                              x:parent-key parent-arg
                              x:val-key field-data
                              x:pointer-size-key 0)) 
      (hash-set! parent x:pointer-offset-key (+ (pos port) (x:size field-data parent #f))) 
      (for ([(key type) (in-dict @fields)])
        (send type x:encode (dict-ref field-data key) port parent))
      (for ([ptr (in-list (hash-ref parent x:pointers-key))])
        (match ptr
          [(x:ptr type val parent) (send type x:encode val port parent)])))
    
    (define/augride (x:size [val #f] [parent-arg #f] [include-pointers #t])
      (define parent (mhasheq x:parent-key parent-arg
                              x:val-key val
                              x:pointer-size-key 0))
      (define fields-size (for/sum ([(key type) (in-dict @fields)]
                                    #:when (xenomorphic-type? type))
                            (send type x:size (and val (send type pre-encode (dict-ref val key))) parent)))
      (define pointers-size (if include-pointers (dict-ref parent x:pointer-size-key) 0))
      (+ fields-size pointers-size))))

(define (x:dict? x) (is-a? x x:dict%))

(define/contract (x:dict #:pre-encode [pre-proc #f]
                           #:post-decode [post-proc #f]
                           #:base-class [base-class x:dict%]
                           . dicts)
  (()
   (#:pre-encode (or/c (any/c . -> . any/c) #false)
    #:post-decode (or/c (any/c . -> . any/c) #false)
    #:base-class (λ (c) (subclass? c x:dict%)))
    #:rest (listof any/c)
   . ->* .
   x:dict?)
  (define args (flatten dicts))
  (unless (even? (length args))
    (raise-argument-error 'x:dict "equal number of keys and values" dicts))
  (define fields (for/list ([kv (in-slice 2 args)])
                   (unless (symbol? (car kv))
                     (raise-argument-error '+xstruct "symbol" (car kv)))
                   (apply cons kv)))
  (new (generate-subclass base-class pre-proc post-proc) [fields fields]))

(module+ test
  (require rackunit "number.rkt" "base.rkt")
  (define (random-pick xs) (list-ref xs (random (length xs))))
  (check-exn exn:fail:contract? (λ () (x:dict 42)))
  (for ([i (in-range 20)])
    ;; make random structs and make sure we can round trip
    (define field-types
      (for/list ([i (in-range 40)])
        (random-pick (list uint8 uint16be uint16le uint32be uint32le double))))
    (define size-num-types
      (for/sum ([num-type (in-list field-types)])
        (send num-type x:size)))
    (define xs (x:dict (for/list ([num-type (in-list field-types)])
                           (cons (gensym) num-type))))
    (define bs (apply bytes (for/list ([i (in-range size-num-types)])
                              (random 256))))
    (check-equal? (encode xs (decode xs bs) #f) bs)))

;; bw compat
(define x:struct% x:dict%)
(define x:struct? x:dict?)
(define x:struct x:dict)
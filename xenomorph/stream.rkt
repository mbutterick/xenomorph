#lang racket/base
(require racket/class
         racket/contract
         "base.rkt" "util.rkt" "number.rkt" "list.rkt" racket/stream sugar/unstable/dict)
(provide (all-defined-out))

#|
approximates
https://github.com/mbutterick/restructure/blob/master/src/LazyArray.coffee
|#
 
(define x:stream%
  (class x:list%
    (super-new)
    (inherit-field [@type type] [@len len])

    (define/override (x:decode port parent)
      (define starting-pos (pos port)) ; ! placement matters. `resolve-length` will change `pos`
      (define len (resolve-length @len port parent))
      (define new-parent (if (x:int? @len)
                             (mhasheq x:parent-key parent
                                      x:start-offset-key starting-pos
                                      x:current-offset-key 0
                                      x:length-key @len)
                             parent))
      (define stream-starting-pos (pos port))
      (begin0
        (for/stream ([index (in-range len)])
          (define orig-pos (pos port))
          (pos port (+ stream-starting-pos (* (send @type x:size #f new-parent) index)))
          (begin0
            (send @type x:decode port new-parent)
            (pos port orig-pos)))
        (pos port (+ (pos port) (* len (send @type x:size #f new-parent))))))

    (define/override (x:encode val port [parent #f])
      (super x:encode (if (stream? val) (stream->list val) val) port parent))
    
    (define/override (x:size [val #f] [parent #f])
      (super x:size (if (stream? val) (stream->list val) val) parent))))

(define (x:stream? x) (is-a? x x:stream%))

(define/contract (x:stream
                  [type-arg #f]
                  [len-arg #f]
                  #:type [type-kwarg #f]
                  #:length [len-kwarg #f]
                  #:pre-encode [pre-proc #f]
                  #:post-decode [post-proc #f]
                  #:base-class [base-class x:stream%])
  (()
   ((or/c xenomorphic? #false)
    (or/c length-resolvable? #false)
    #:type (or/c xenomorphic? #false)
    #:length (or/c length-resolvable? #false)
    #:pre-encode (or/c (any/c . -> . any/c) #false)
    #:post-decode (or/c (any/c . -> . any/c) #false)
    #:base-class (λ (c) (subclass? c x:stream%)))
   . ->* .
   x:stream?)
  (define type (or type-arg type-kwarg))
    (unless (xenomorphic? type)
    (raise-argument-error 'x:stream "xenomorphic type" type))
  (define len (or len-arg len-kwarg))
   (unless (length-resolvable? len)
    (raise-argument-error 'x:stream "resolvable length" len))
  (new (generate-subclass base-class pre-proc post-proc) [type type]
       [len len]
       [count-bytes? #false]))

(define x:lazy-array% x:stream%)
(define x:lazy-array x:stream)

(module+ test
  (require rackunit "number.rkt" "base.rkt")
  (define bstr #"ABCD1234")
  (define ds (open-input-bytes bstr))
  (define la (x:stream uint8 4))
  (define ila (decode la ds))
  (check-equal? (pos ds) 4)
  (check-equal? (stream-ref ila 1) 66)
  (check-equal? (stream-ref ila 3) 68)
  (check-equal? (pos ds) 4)
  (check-equal? (stream->list ila) '(65 66 67 68))
  (define la2 (x:stream int16be (λ (t) 4))) 
  (check-equal? (encode la2 '(1 2 3 4) #f) #"\0\1\0\2\0\3\0\4")
  (check-equal? (stream->list (decode la2 (open-input-bytes #"\0\1\0\2\0\3\0\4"))) '(1 2 3 4)))
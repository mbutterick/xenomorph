#lang racket/base
(require rackunit
         "../helper.rkt"
         "../number.rkt"
         "../optional.rkt")

#|
approximates
https://github.com/mbutterick/restructure/blob/master/test/Optional.coffee
|#

(test-case
 "decode should not decode when condition is falsy"
 (parameterize ([current-input-port (open-input-bytes (bytes 0))])
   (define optional (+xoptional uint8 #f))
   (check-equal? (decode optional) (void))
   (check-equal? (pos (current-input-port)) 0)))

(test-case
 "decode should not decode when condition is a function and falsy"
 (parameterize ([current-input-port (open-input-bytes (bytes 0))])
   (define optional (+xoptional uint8 (λ _ #f)))
   (check-equal? (decode optional) (void))
   (check-equal? (pos (current-input-port)) 0)))

(test-case
 "decode should decode when condition is omitted"
 (parameterize ([current-input-port (open-input-bytes (bytes 0))])
   (define optional (+xoptional uint8))
   (check-not-equal? (decode optional) (void))
   (check-equal? (pos (current-input-port)) 1)))

(test-case
 "decode should decode when condition is truthy"
 (parameterize ([current-input-port (open-input-bytes (bytes 0))])
   (define optional (+xoptional uint8 #t))
   (check-not-equal? (decode optional) (void))
   (check-equal? (pos (current-input-port)) 1)))

(test-case
 "decode should decode when condition is a function and truthy"
 (parameterize ([current-input-port (open-input-bytes (bytes 0))])
   (define optional (+xoptional uint8 (λ _ #t)))
   (check-not-equal? (decode optional) (void))
   (check-equal? (pos (current-input-port)) 1)))

(test-case
 "size"
 (check-equal? (size (+xoptional uint8 #f)) 0))

(test-case
 "size should return 0 when condition is a function and falsy"
 (check-equal? (size (+xoptional uint8 (λ _ #f))) 0))

(test-case
 "size should return given type size when condition is omitted"
 (check-equal? (size (+xoptional uint8)) 1))

(test-case
 "size should return given type size when condition is truthy"
 (check-equal? (size (+xoptional uint8 #t)) 1))

(test-case
 "size should return given type size when condition is a function and truthy"
 (check-equal? (size (+xoptional uint8 (λ _ #t))) 1))

(test-case
 "encode should not encode when condition is falsy"
 (parameterize ([current-output-port (open-output-bytes)])
   (define optional (+xoptional uint8 #f))
   (encode optional 128)
   (check-equal? (dump (current-output-port)) (bytes))))

(test-case
 "encode should not encode when condition is a function and falsy"
 (parameterize ([current-output-port (open-output-bytes)])
   (define optional (+xoptional uint8 (λ _ #f)))
   (encode optional 128)
   (check-equal? (dump (current-output-port)) (bytes))))

(test-case
 "encode should encode when condition is omitted"
 (parameterize ([current-output-port (open-output-bytes)])
   (define optional (+xoptional uint8))
   (encode optional 128)
   (check-equal? (dump (current-output-port)) (bytes 128))))

(test-case
 "encode should encode when condition is truthy"
 (parameterize ([current-output-port (open-output-bytes)])
   (define optional (+xoptional uint8 #t))
   (encode optional 128)
   (check-equal? (dump (current-output-port)) (bytes 128))))

(test-case
 "encode should encode when condition is a function and truthy"
 (parameterize ([current-output-port (open-output-bytes)])
   (define optional (+xoptional uint8 (λ _ #t)))
   (encode optional 128)
   (check-equal? (dump (current-output-port)) (bytes 128))))
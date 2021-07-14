#lang racket

(require "grammar.rkt"
         brag/support)

(define run-ast-ns (make-base-namespace))
(eval '(require (for-syntax racket/base) (for-syntax racket/list) racket/list) run-ast-ns)
(eval '(begin
         (define (program . fs)
           (foldl (λ (f acc) (list (hash-set (first acc) (first f) (cadr f))
                                   (hash-set (cadr acc) (first f) (caddr f))))
                  (list (hash) (hash))
                  fs))
         (define-syntax (function stx)
           (let [[dtm (syntax->datum stx)]]
             (datum->syntax
              stx
              `(list ,(cadr dtm) ;; name
                     ,(caddr dtm) ;; initial value
                     (λ (previous-values) ,(cadddr dtm)))))) ;; body
         (define-syntax (conditional stx)
           (define dtm (syntax->datum stx))
           (define (into-pairs lst [result '()])
             (if (empty? lst)
                 (reverse result)
                 (into-pairs (cddr lst) (cons (list (car lst) (cadr lst)) result))))
           (let [[statement
                  (datum->syntax
                   stx
                   `(cond
                      ,@(into-pairs (cdr dtm))
                      [else (error (format "no condition was true out of: ~a\n" ',dtm))]))]]
             statement))
         (define (condition . args)
           (cond
             [(= (length args) 3) ((second args) (first args) (third args))]
             [(equal? (list-ref args 0) "otherwise") #t]))
         (define (subtract . args)
           (if (= (length args) 1)
               (first args)
               (- (first args) (second args))))
         (define (plus . args)
           (if (= (length args) 1)
               (first args)
               (+ (first args) (second args))))
         (define (mod . args)
           (if (= (length args) 1)
               (first args)
               (modulo (first args) (second args))))
         (define (divide . args)
           (if (= (length args) 1)
               (first args)
               (/ (first args) (second args))))
         (define (multiply . args)
           (if (= (length args) 1)
               (first args)
               (* (first args) (second args))))
         (define (index . args)
           (if (= (length args) 1)
               (first args)
               (expt (first args) (second args))))
         (define (inequality . args)
           (case args
             [((">")) >] [(("<")) <]
             [(("=")) =] [(("!" "=")) (λ (a b) (not (= a b)))]
             [((">" "=")) >=] [(("<" "=")) <=]
             [else args]))
         (define-syntax (name-ref stx)
           (define str (cadr (syntax->datum stx)))
           (datum->syntax
            stx
            `(if (hash-has-key? previous-values ,str)
                 (hash-ref previous-values ,str)
                 (error (format "no such value defined: ~a" ,str)))))
         (define (number num)
           (string->number num)))
      run-ast-ns)

(define (run code #:trace [trace-names '()])
  (define (run-processed current-values functions)
    (display (if (empty? trace-names)
                 ""
                 (string-append "TRACE: "
                                (string-join (map (λ (name)
                                                    (format "~a: ~a" name (hash-ref current-values name)))
                                                  trace-names)
                                             ", ")
                                "\n")))
    (if (= (hash-ref current-values "halt") 0)
          (hash-ref current-values "out")
          (let [[new-values (foldl
                       (λ (f acc)
                         (hash-set acc f ((hash-ref functions f) current-values)))
                       (hash)
                       (hash-keys functions))]]
      (run-processed new-values functions))))
  (let-values [[(current-values functions)
                (apply values (eval (parse (tokenise code)) run-ast-ns))]]
    (cond
      [(not (hash-has-key? functions "halt")) (error "no 'halt' function defined, program cannot halt")]
      [(not (hash-has-key? functions "out")) (error "no 'out' function defined, program cannot give output")]
      [else (run-processed current-values functions)])))

(define (tokenise code [tokens '()])
  (if (equal? code "")
      (reverse tokens)
      (let [[next-token
             (regexp-cond
              code
              [#rx"^[ \t\n]+" (token 'WS (first Match))]
              [#rx"^//[^\n]*" (token 'WS (first Match))]
              [#rx"^[0-9]+(\\.[0-9]+)?" (token 'NUMBER (first Match))]
              [#rx"^otherwise" (token 'OTHERWISE (first Match))]
              [#rx"^[a-zA-Z_]+" (token 'NAME (first Match))]
              [else (token (substring code 0 1) (substring code 0 1))])]]
        (if (equal? (token-struct-type next-token) 'WS)
            (tokenise (substring code (string-length (token-struct-val next-token)))
                      tokens)
            (tokenise (substring code (string-length (token-struct-val next-token)))
                      (cons next-token tokens))))))

(define-syntax (regexp-cond stx)
  (let* [[dtm (syntax->datum stx)]
         [str (cadr dtm)]
         [cases (cddr dtm)]]
    (datum->syntax
     stx
     `(cond ,@(map (λ (case)
                     (if (equal? (car case) 'else)
                         case
                         `[(regexp-match? ,(car case) ,str)
                           (let [[Match (regexp-match ,(car case) ,str)]]
                             ,@(cdr case))])) cases)))))

(provide run)
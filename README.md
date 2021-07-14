# Tock

An esolang/model of computation.

## Overview

There is a collection of functions taking an integer `t` to a real. These functions can depend on the values that the other functions take for `t-1`,
but not for any other input, so `f(t)` can be defined in terms of `g(t-1)` but not `g(t)`, `g(t-2)`, `g(t+1)` or `g(3)`. Two functions, called
`halt` and `out`, are special: the output of the program is the value of `out(t)` for the smallest `t` such that `halt(t)` is zero.

## Language

A program is a collection of functions, which must include functions called `halt` and `out`. Each function is defined as follows:
```
<function name> <initial value> {
  <expression>
}
```
or:
```
<function name> <initial value> {
  <condition> : <expression>;
  <condition> : <expression>;
  otherwise : <expression>
}
```
A function name can consist of alphabetical characters and underscores only. The initial value is a number. a condition consists of two expressions
related by one of `=`, `!=`, `>`, `<`, `>=` or `<=`. Clauses of a piecewise definition are checked sequentially, the `otherwise` clause is
optional (but the program will throw an error if no clause matches).

For example, the following is a simple program that outputs `10`:
```
halt 10 {
  halt - 1
}

out 0 {
  out + 1
}
```
While the following outputs `20`:
```
halt 1 {
  counter = 10: 0;
  otherwise: 1
}

out 0 {
  counter * 2
}

counter 0 {
  counter + 1
}
```

Line comments are permitted using double slashes. See `fractran.tock` for a more involved example.


## Using the Intepreter

`tock.rkt` provides the function `run`, which expects a string containing a tock program and returns the result as a number.
`run` also takes an optional keyword argument `#:trace` which expects a list of strings which are the names of functions in the program. If this
is provided (and nonempty) then `run` will print the values of those functions for each `t` up until the program halts. It won't handle nonexistant
function names well, I'm afraid.

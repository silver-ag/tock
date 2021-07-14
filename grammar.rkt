#lang brag

program: function*
function: NAME number /"{" (subtract | conditional) /";"? /"}"
conditional: condition /":" subtract (/";" condition /":" subtract)*
condition: (subtract inequality subtract) | OTHERWISE
subtract: plus | subtract /"-" plus
plus: mod | plus /"+" mod
mod: divide | mod /"%" divide
divide: multiply | divide /"/" multiply
multiply: index | multiply /"*" index
index: number | name-ref | /"(" subtract /")" | index /"^" index
inequality: ">" | "<" | ">" "=" | "<" "=" | "=" | "!" "="
name-ref : NAME
number: NUMBER

# Changelog

## v1.0.0
- changed: Renamed `JsonLogic.apply` to `JsonLogic.resolve` to remove conflicts with `Kernel.apply/2`.
- changed: All formerly public operations have been made private.
- fixed: Support for finding `min` and `max` values in a mixed array of numbers and strings.
- fixed: Support for using `cat` with `var`'s.
- fixed: Make `nil` comparisons become in line with how the javascript library is implemented.
- fixed: `max` returns `nil` if the list is empty.
- fixed: `max` returns `nil` if the list of values are not all numeric.
- fixed: `max` returning the original maximum value and not the coerced value.
- fixed: `min` returns `nil` if the list is empty.
- fixed: `min` returns `nil` if the list of values are not all numeric.
- fixed: `min` returning the original minimum value and not the coerced value.
- fixed: infinite recursive loop for ill formed `in` clauses.
- fixed: typespec for `resolve/2`.
- removed: optional dependencies for `jason` and `poison`.
- added: Support for `Decimal` to be used.

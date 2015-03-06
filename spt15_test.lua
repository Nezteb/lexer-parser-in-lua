#!/usr/bin/env lua
-- spt15_test.lua
-- Glenn G. Chappell
-- 23 Feb 2015
--
-- For CS 331 Spring 2015
-- Test Program for Module spt15
-- Used in Assignment 4, Exercise A

spt15 = require "spt15"  -- Import spt15 module


-- *********************************************
-- * YOU MAY WISH TO CHANGE THE FOLLOWING LINE *
-- *********************************************

exit_on_failure = true

-- If exit_on_failure is true, then:
-- - On first failing test, we print the input, expected output, and
--   actual output; then the test program terminates.
-- If exit_on_failure is false, then:
-- - All tests are performed, with a summary of results printed at the
--   end.


-- *********************************************************************
-- Testing Package
-- *********************************************************************


tester = {}
tester.countTests = 0
tester.countPasses = 0

function tester.test(self, success, testName)
    self.countTests = self.countTests+1
    io.write("    Test: " .. testName .. " - ")
    if success then
        self.countPasses = self.countPasses+1
        io.write("passed")
    else
        io.write("********** FAILED **********")
    end
    io.write("\n")
end

function tester.allPassed(self)
    return self.countPasses == self.countTests
end


-- *********************************************************************
-- Definitions for This Test Program
-- *********************************************************************


function printNoteAndExit()
    io.write("\n")
    io.write("NOTE: This program is set to terminate after the first\n")
    io.write("      failing test. If you would prefer to execute all\n")
    io.write("      tests, whether they pass or not, then set\n")
    io.write("      variable exit_on_failure to false. (See the\n")
    io.write("      beginning of the source code.)\n")
    io.write("\n")
    os.exit(1)
end


function check(t, prog, testName, expGood, expOutput)
    local function b2s(used,b)
        if not used then
           return "(ignored)"
        elseif b then
           return "true"
        else
           return "false"
        end
    end

    local good, output = spt15.interp(prog)
    local success = (good == expGood
                 and (not good or output == expOutput))
    t:test(success, testName)
    if exit_on_failure and not success then
        io.write("\n")
        io.write("Input for the last test above:\n")
        io.write(prog.."\n")

        io.write("\n")
        io.write("Expected results from spt15.interp:\n")
        io.write("Correct parse:  "..b2s(true,expGood).."\n")
        io.write("Output:")
        if expGood then
            io.write("\n")
            io.write(expOutput)
        else
            io.write("         (ignored)\n")
        end

        io.write("\n")
        io.write("Actual results from spt15.interp:\n")
        io.write("Correct parse:  "..b2s(true,good).."\n")
        io.write("Output:\n")
        io.write(output)
        io.write("\n")

        printNoteAndExit()
    end
end


-- *********************************************************************
-- Test Suite Functions
-- *********************************************************************


function test_trivial(t)
    io.write("Test Suite: Trivial Programs\n")
    local prog, out

    -- Empty or incomplete programs
    prog = ""
    out = ""
    check(t, prog, "empty program", true, out)

    prog = "/* Comment */"
    out = ""
    check(t, prog, "comment only", true, out)

    prog = "/* Comment */ /* Comment #2 */"
    out = ""
    check(t, prog, "2 comments only", true, out)

    prog = "123abc"
    check(t, prog, "gibberish", false)

    prog = "set"
    check(t, prog, "set only", false)

    -- assignment
    prog = "set x=3"
    out = ""
    check(t, prog, "assignment", true, out)

    prog = "set x=3 xyz"
    check(t, prog, "assignment + gibberish", false)

    prog = "x=3"
    check(t, prog, "assignment without 'set'", false)

    prog = "set=3"
    check(t, prog, "assignment without variable", false)

    prog = "set x 3"
    check(t, prog, "assignment without '='", false)

    prog = "set x="
    check(t, prog, "assignment without expression", false)
end


function test_print(t)
    io.write("Test Suite: Printing\n")
    local prog, out

    prog = "printnl"
    out = "\n"
    check(t, prog, "newline", true, out)

    prog = "printnl 'a'"
    check(t, prog, "newline with string", false)

    prog = "printnl printnl"
    out = "\n\n"
    check(t, prog, "2 newlines", true, out)

    prog = "printnl set x=4 printnl"
    out = "\n\n"
    check(t, prog, "newline set newline", true, out)

    prog = "printstr \"abc\""
    out = "abc"
    check(t, prog, "string, double quotes", true, out)

    prog = "printstr 'def'"
    out = "def"
    check(t, prog, "string, single quotes", true, out)

    prog = "printstr ''"
    out = ""
    check(t, prog, "string, empty", true, out)

    prog = "printstr"
    check(t, prog, "printstr without string", false)

    prog = "printstr 'ab' 'cd'"
    check(t, prog, "printstr with 2 strings", false)

    prog = "printstr \"abc\" printstr 'def'"
    out = "abcdef"
    check(t, prog, "2 strings", true, out)

    prog = "printstr \"abc\" printnl"
    out = "abc\n"
    check(t, prog, "string newline", true, out)

    prog = "set a=1printstr \"a\" set b=2printnl set c=3printstr'b'printstr'c'"
    out = "a\nbc"
    check(t, prog, "strings, newline, & set", true, out)
end


function test_nums(t)
    io.write("Test Suite: Numbers\n")
    local prog, out

    -- Print a number
    prog = "printnum 2"
    out = "2"
    check(t, prog, "print integer", true, out)

    prog = "printnum -3.7"
    out = "-3.7"
    check(t, prog, "print non-integer", true, out)

    prog = "printnum 2.81e+21"
    out = "2.81e+21"
    check(t, prog, "print sci notation #1", true, out)

    prog = "printnum 2.81e21"
    out = "2.81e+21"
    check(t, prog, "print sci notation #2", true, out)

    prog = "printnum 2.81e+5"
    out = "281000"
    check(t, prog, "print sci notation #3", true, out)

    prog = "printnum 2.81e-2"
    out = "0.0281"
    check(t, prog, "print sci notation #4", true, out)

    prog = "printnum 2.81 e+21"
    check(t, prog, "print, bad syntax", false)

    prog = "printnum 2.81e+21 x"
    check(t, prog, "print, gibberish @ end", false)

    -- Print multiple numbers
    prog = "printnum 1printnum 2"
    out = "12"
    check(t, prog, "two prints", true, out)

    prog = "printnum 1printnl printnum 2printnl"
    out = "1\n2\n"
    check(t, prog, "two prints with newlines", true, out)

    prog = "printnum 1printnl printnum 0printnl printnum-3.7printnl printnum 6.72e+14printnl"
    out = "1\n0\n-3.7\n6.72e+14\n"
    check(t, prog, "Several prints", true, out)
end


function test_vars(t)
    io.write("Test Suite: Variables\n")
    local prog, out

    -- Print a variable
    prog = "set a=3 printnum a"
    out = "3"
    check(t, prog, "print integer variable", true, out)

    prog = "set b=1.77 printnum b"
    out = "1.77"
    check(t, prog, "print non-integer variable", true, out)

    prog = "set c = -5.6e-13 printnum c printnl"
    out = "-5.6e-13\n"
    check(t, prog, "print sci-notation variable", true, out)

    -- Print multiple variables
    prog = "set a=1.2set bc =-34set d_e= 5.67e19set f=-4000printnum a printnl printnum bc\nprintnl printnum d_e printnl\nprintnum f printnl"
    out = "1.2\n-34\n5.67e+19\n-4000\n"
    check(t, prog, "Several assignments then prints", true, out)

    prog = "set a=1 printnum a printnl printnum a printnl set a=2 set a=3 printnum a printnl set a=4 printnum a printnl\nprintnum a printnl"
    out = "1\n1\n3\n4\n4\n"
    check(t, prog, "Several prints of single var", true, out)

    prog = "set a=1set b=2 printnum a printnl printnum b printnl printnum a printnl set a=3 set b=4 set a=5 printnum a printnl\nprintnum b printnl printnum a printnl"
    out = "1\n2\n1\n5\n4\n5\n"
    check(t, prog, "Several prints of two vars", true, out)

    -- Assign var to var
    prog = "set a=8set b=a printnum b printnl"
    out = "8\n"
    check(t, prog, "Assign var to var, simple", true, out)

    prog = "set a=4set b=3set a=b set b=1 set b=a set a=6 printnum a printnl printnum b printnl"
    out = "6\n3\n"
    check(t, prog, "Assign var to var, complicated", true, out)

    prog = "set a=4 set a=a-1 set a=a*a set a=2+a printnum a printnl"
    out = "11\n"
    check(t, prog, "Assign var to expressions involving itself", true, out)
end


function test_ops_nums(t)
    io.write("Test Suite: Simple Expressions with Operators & Numbers\n")
    local prog, out

    -- Operators & numbers
    prog = "printnum 2 == 3"
    out = "0"
    check(t, prog, "== op, a<b", true, out)

    prog = "printnum 3 == 3"
    out = "1"
    check(t, prog, "== op, a=b", true, out)

    prog = "printnum 4 == 3"
    out = "0"
    check(t, prog, "== op, a>b", true, out)

    prog = "printnum 2 != 3"
    out = "1"
    check(t, prog, "!= op, a<b", true, out)

    prog = "printnum 3 != 3"
    out = "0"
    check(t, prog, "!= op, a=b", true, out)

    prog = "printnum 4 != 3"
    out = "1"
    check(t, prog, "!= op, a>b", true, out)

    prog = "printnum 2 < 3"
    out = "1"
    check(t, prog, "< op, a<b", true, out)

    prog = "printnum 3 < 3"
    out = "0"
    check(t, prog, "< op, a=b", true, out)

    prog = "printnum 4 < 3"
    out = "0"
    check(t, prog, "< op, a>b", true, out)

    prog = "printnum 2 <= 3"
    out = "1"
    check(t, prog, "<= op, a<b", true, out)

    prog = "printnum 3 <= 3"
    out = "1"
    check(t, prog, "<= op, a=b", true, out)

    prog = "printnum 4 <= 3"
    out = "0"
    check(t, prog, "<= op, a>b", true, out)

    prog = "printnum 2 > 3"
    out = "0"
    check(t, prog, "> op, a<b", true, out)

    prog = "printnum 3 > 3"
    out = "0"
    check(t, prog, "> op, a=b", true, out)

    prog = "printnum 4 > 3"
    out = "1"
    check(t, prog, "> op, a>b", true, out)

    prog = "printnum 2 >= 3"
    out = "0"
    check(t, prog, ">= op, a<b", true, out)

    prog = "printnum 3 >= 3"
    out = "1"
    check(t, prog, ">= op, a=b", true, out)

    prog = "printnum 4 >= 3"
    out = "1"
    check(t, prog, ">= op, a>b", true, out)

    prog = "printnum 2 + 5"
    out = "7"
    check(t, prog, "binary + op", true, out)

    prog = "printnum 2 - 5"
    out = "-3"
    check(t, prog, "binary - op", true, out)

    prog = "printnum 2 * 5"
    out = "10"
    check(t, prog, "* op", true, out)

    prog = "printnum 2 / 5"
    out = "0.4"

    prog = "printnum + 5"
    out = "5"
    check(t, prog, "unary + op, positive argument", true, out)

    prog = "printnum + -5"
    out = "-5"
    check(t, prog, "unary + op, negative argument", true, out)

    prog = "printnum - 5"
    out = "-5"
    check(t, prog, "unary - op, positive argument", true, out)

    prog = "printnum - -5"
    out = "5"
    check(t, prog, "unary - op, negative argument", true, out)

    -- Parentheses
    prog = "printnum (2)"
    out = "2"
    check(t, prog, "parens #1", true, out)

    prog = "printnum (-4)"
    out = "-4"
    check(t, prog, "parens #2", true, out)

    -- preferOp
    prog = "printnum -1-1"
    out = "-2"
    check(t, prog, "preferOp check #1", true, out)

    prog = "printnum (3)-1"
    out = "2"
    check(t, prog, "preferOp check #2", true, out)
end


function test_ops_vars(t)
    io.write("Test Suite: Operators & Variables\n")
    local prog, out

    -- Operators & numbers
    prog = "set a=2 set b=3 printnum a == b"
    out = "0"
    check(t, prog, "== op, a<b, vars", true, out)

    prog = "set a=3 set b=3 printnum a == b"
    out = "1"
    check(t, prog, "== op, a=b, vars", true, out)

    prog = "set a=4 set b=3 printnum a == b"
    out = "0"
    check(t, prog, "== op, a>b, vars", true, out)

    prog = "set a=2 set b=3 printnum a != b"
    out = "1"
    check(t, prog, "!= op, a<b, vars", true, out)

    prog = "set a=3 set b=3 printnum a != b"
    out = "0"
    check(t, prog, "!= op, a=b, vars", true, out)

    prog = "set a=4 set b=3 printnum a != b"
    out = "1"
    check(t, prog, "!= op, a>b, vars", true, out)

    prog = "set a=2 set b=3 printnum a < b"
    out = "1"
    check(t, prog, "< op, a<b, vars", true, out)

    prog = "set a=3 set b=3 printnum a < b"
    out = "0"
    check(t, prog, "< op, a=b, vars", true, out)

    prog = "set a=4 set b=3 printnum a < b"
    out = "0"
    check(t, prog, "< op, a>b, vars", true, out)

    prog = "set a=2 set b=3 printnum a <= b"
    out = "1"
    check(t, prog, "<= op, a<b, vars", true, out)

    prog = "set a=3 set b=3 printnum a <= b"
    out = "1"
    check(t, prog, "<= op, a=b, vars", true, out)

    prog = "set a=4 set b=3 printnum a <= b"
    out = "0"
    check(t, prog, "<= op, a>b, vars", true, out)

    prog = "set a=2 set b=3 printnum a > b"
    out = "0"
    check(t, prog, "> op, a<b, vars", true, out)

    prog = "set a=3 set b=3 printnum a > b"
    out = "0"
    check(t, prog, "> op, a=b, vars", true, out)

    prog = "set a=4 set b=3 printnum a > b"
    out = "1"
    check(t, prog, "> op, a>b, vars", true, out)

    prog = "set a=2 set b=3 printnum a >= b"
    out = "0"
    check(t, prog, ">= op, a<b, vars", true, out)

    prog = "set a=3 set b=3 printnum a >= b"
    out = "1"
    check(t, prog, ">= op, a=b, vars", true, out)

    prog = "set a=4 set b=3 printnum a >= b"
    out = "1"
    check(t, prog, ">= op, a>b, vars", true, out)

    prog = "set a=2 set b=5 printnum a + b"
    out = "7"
    check(t, prog, "binary + op, vars", true, out)

    prog = "set a=2 set b=5 printnum a - b"
    out = "-3"
    check(t, prog, "binary - op, vars", true, out)

    prog = "set a=2 set b=5 printnum a * b"
    out = "10"
    check(t, prog, "* op, vars", true, out)

    prog = "set a=2 set b=5 printnum a / b"
    out = "0.4"

    prog = "set a=5 printnum + a"
    out = "5"
    check(t, prog, "unary + op, positive argument, vars", true, out)

    prog = "set a=-5 printnum + a"
    out = "-5"
    check(t, prog, "unary + op, negative argument, vars", true, out)

    prog = "set a=5 printnum - a"
    out = "-5"
    check(t, prog, "unary - op, positive argument, vars", true, out)
    prog = "set a=-5 printnum - a"
    out = "5"
    check(t, prog, "unary - op, negative argument, vars", true, out)

    -- Parentheses
    prog = "set a=2 printnum (a)"
    out = "2"
    check(t, prog, "parens, vars", true, out)

    -- preferOp
    prog = "set a=-1 printnum a-1"
    out = "-2"
    check(t, prog, "preferOp check, vars", true, out)
end


function test_associativity(t)
    io.write("Test Suite: Operator Associativity\n")
    local prog, out

    -- Associativity
    prog = "printnum 1 == 2 == 0"
    out = "1"
    check(t, prog, "== op, associativity #1", true, out)

    prog = "printnum (1 == 2) == 0"
    out = "1"
    check(t, prog, "== op, associativity #2", true, out)

    prog = "printnum 1 == (2 == 0)"
    out = "0"
    check(t, prog, "== op, associativity #3", true, out)

    prog = "printnum 1 != 2 != 0"
    out = "1"
    check(t, prog, "!= op, associativity #1", true, out)

    prog = "printnum (1 != 2) != 0"
    out = "1"
    check(t, prog, "!= op, associativity #2", true, out)

    prog = "printnum 1 != (2 != 0)"
    out = "0"
    check(t, prog, "!= op, associativity #3", true, out)

    prog = "printnum 1 < 1 < 1"
    out = "1"
    check(t, prog, "< op, associativity #1", true, out)

    prog = "printnum (1 < 1) < 1"
    out = "1"
    check(t, prog, "< op, associativity #2", true, out)

    prog = "printnum 1 < (1 < 1)"
    out = "0"
    check(t, prog, "< op, associativity #3", true, out)

    prog = "printnum 1 <= 2 <= 1"
    out = "1"
    check(t, prog, "<= op, associativity #1", true, out)

    prog = "printnum (1 <= 2) <= 1"
    out = "1"
    check(t, prog, "<= op, associativity #2", true, out)

    prog = "printnum 1 <= (2 <= 1)"
    out = "0"
    check(t, prog, "<= op, associativity #3", true, out)

    prog = "printnum 1 > 0.5 > 0"
    out = "1"
    check(t, prog, "> op, associativity #1", true, out)

    prog = "printnum (1 > 0.5) > 0"
    out = "1"
    check(t, prog, "> op, associativity #2", true, out)

    prog = "printnum 1 > (0.5 > 0)"
    out = "0"
    check(t, prog, "> op, associativity #3", true, out)

    prog = "printnum 0.5 >= 0 >= 0"
    out = "1"
    check(t, prog, ">= op, associativity #1", true, out)

    prog = "printnum (0.5 >= 0) >= 0"
    out = "1"
    check(t, prog, ">= op, associativity #2", true, out)

    prog = "printnum 0.5 >= (0 >= 0)"
    out = "0"
    check(t, prog, ">= op, associativity #3", true, out)

    prog = "printnum 1 + 1e100 + -1e100"
    out = "0"
    check(t, prog, "binary + op, associativity #1", true, out)

    prog = "printnum (1 + 1e100) + -1e100"
    out = "0"
    check(t, prog, "binary + op, associativity #2", true, out)

    prog = "printnum 1 + (1e100 + -1e100)"
    out = "1"
    check(t, prog, "binary + op, associativity #3", true, out)

    prog = "printnum 4 - 2 - 1"
    out = "1"
    check(t, prog, "binary - op, associativity #1", true, out)

    prog = "printnum (4 - 2) - 1"
    out = "1"
    check(t, prog, "binary - op, associativity #2", true, out)

    prog = "printnum 4 - (2 - 1)"
    out = "3"
    check(t, prog, "binary - op, associativity #3", true, out)

    -- How to test associativity of "*" op without overflow?

    prog = "printnum 16 / 4 / 2"
    out = "2"
    check(t, prog, "/ op, associativity #1", true, out)

    prog = "printnum (16 / 4) / 2"
    out = "2"
    check(t, prog, "/ op, associativity #2", true, out)

    prog = "printnum 16 / (4 / 2)"
    out = "8"
    check(t, prog, "/ op, associativity #3", true, out)

    prog = "printnum + + + 3"
    out = "3"
    check(t, prog, "unary + op, associativity", true, out)

    prog = "printnum - - - 3"
    out = "-3"
    check(t, prog, "unary - op, associativity", true, out)
end


function test_precedence(t)
    io.write("Test Suite: Operator Precedence\n")
    local prog, out

    -- Precedence
    prog = "printnum - 2 + 5"
    out = "3"
    check(t, prog, "unary - op above binary + op #1", true, out)

    prog = "printnum (- 2) + 5"
    out = "3"
    check(t, prog, "unary - op above binary + op #2", true, out)

    prog = "printnum - (2 + 5)"
    out = "-7"
    check(t, prog, "unary - op above binary + op #3", true, out)

    prog = "printnum - 2 - 5"
    out = "-7"
    check(t, prog, "unary - op above binary - op #1", true, out)

    prog = "printnum (- 2) - 5"
    out = "-7"
    check(t, prog, "unary - op above binary - op #2", true, out)

    prog = "printnum - (2 - 5)"
    out = "3"
    check(t, prog, "unary - op above binary - op #3", true, out)

    prog = "printnum - -2 == -2"
    out = "0"
    check(t, prog, "unary - op above == op #1", true, out)

    prog = "printnum (- -2) == -2"
    out = "0"
    check(t, prog, "unary - op above == op #2", true, out)

    prog = "printnum - (-2 == -2)"
    out = "-1"
    check(t, prog, "unary - op above == op #3", true, out)

    prog = "printnum - -2 != 2"
    out = "0"
    check(t, prog, "unary - op above != op #1", true, out)

    prog = "printnum (- -2) != 2"
    out = "0"
    check(t, prog, "unary - op above != op #2", true, out)

    prog = "printnum - (-2 != 2)"
    out = "-1"
    check(t, prog, "unary - op above != op #3", true, out)

    prog = "printnum - -2 < 2"
    out = "0"
    check(t, prog, "unary - op above < op #1", true, out)

    prog = "printnum (- -2) < 2"
    out = "0"
    check(t, prog, "unary - op above < op #2", true, out)

    prog = "printnum - (-2 < 2)"
    out = "-1"
    check(t, prog, "unary - op above < op #3", true, out)

    prog = "printnum - -2 <= 2"
    out = "1"
    check(t, prog, "unary - op above <= op #1", true, out)

    prog = "printnum (- -2) <= 2"
    out = "1"
    check(t, prog, "unary - op above <= op #2", true, out)

    prog = "printnum - (-2 <= 2)"
    out = "-1"
    check(t, prog, "unary - op above <= op #3", true, out)

    prog = "printnum - 2 > -2"
    out = "0"
    check(t, prog, "unary - op above > op #1", true, out)

    prog = "printnum (- 2) > -2"
    out = "0"
    check(t, prog, "unary - op above > op #2", true, out)

    prog = "printnum - (2 > -2)"
    out = "-1"
    check(t, prog, "unary - op above > op #3", true, out)

    prog = "printnum - 2 >= -2"
    out = "1"
    check(t, prog, "unary - op above >= op #1", true, out)

    prog = "printnum (- 2) >= -2"
    out = "1"
    check(t, prog, "unary - op above >= op #2", true, out)

    prog = "printnum - (2 >= -2)"
    out = "-1"
    check(t, prog, "unary - op above >= op #3", true, out)

    prog = "printnum 1 + 2 * 5"
    out = "11"
    check(t, prog, "* op above binary + op #1", true, out)

    prog = "printnum 1 + (2 * 5)"
    out = "11"
    check(t, prog, "* op above binary + op #2", true, out)

    prog = "printnum (1 + 2) * 5"
    out = "15"
    check(t, prog, "* op above binary + op #3", true, out)

    prog = "printnum 1 - 2 * 5"
    out = "-9"
    check(t, prog, "* op above binary - op #1", true, out)

    prog = "printnum 1 - (2 * 5)"
    out = "-9"
    check(t, prog, "* op above binary - op #2", true, out)

    prog = "printnum (1 - 2) * 5"
    out = "-5"
    check(t, prog, "* op above binary - op #3", true, out)

    prog = "printnum 1 + 2 / 5"
    out = "1.4"
    check(t, prog, "/ op above binary + op #1", true, out)

    prog = "printnum 1 + (2 / 5)"
    out = "1.4"
    check(t, prog, "/ op above binary + op #2", true, out)

    prog = "printnum (1 + 2) / 5"
    out = "0.6"
    check(t, prog, "/ op above binary + op #3", true, out)

    prog = "printnum 1 - 2 / 5"
    out = "0.6"
    check(t, prog, "/ op above binary - op #1", true, out)

    prog = "printnum 1 - (2 / 5)"
    out = "0.6"
    check(t, prog, "/ op above binary - op #2", true, out)

    prog = "printnum (1 - 2) / 5"
    out = "-0.2"
    check(t, prog, "/ op above binary - op #3", true, out)

    prog = "printnum 2 == 2 * 5"
    out = "0"
    check(t, prog, "* op above == op #1", true, out)

    prog = "printnum 2 == (2 * 5)"
    out = "0"
    check(t, prog, "* op above == op #2", true, out)

    prog = "printnum (2 == 2) * 5"
    out = "5"
    check(t, prog, "* op above == op #3", true, out)

    prog = "printnum 2 == 2 + 5"
    out = "0"
    check(t, prog, "binary + op above == op #1", true, out)

    prog = "printnum 2 == (2 + 5)"
    out = "0"
    check(t, prog, "binary + op above == op #2", true, out)

    prog = "printnum (2 == 2) + 5"
    out = "6"
    check(t, prog, "binary + op above == op #3", true, out)
end


function test_if(t)
    io.write("Test Suite: If Statements\n")
    local prog, out
    local line

    prog = "set a = 3 if a == 3 printnum a printnl"
    out = "3\n"
    check(t, prog, "If Statement #1", true, out)

    prog = "set a = 3 if a == 4 printnum a printnl"
    out = "\n"
    check(t, prog, "If Statement #2", true, out)

    prog = "set a = 2 printstr 'a is ' if a > 4 printstr 'big' if a <= 4 printstr 'small' printnl"
    out = "a is small\n"
    check(t, prog, "If Statement #3", true, out)

    prog = "set a = 6 printstr 'a is ' if a > 4 printstr 'BIG' if a <= 4 printstr 'small' printnl"
    out = "a is BIG\n"
    check(t, prog, "If Statement #4", true, out)
end


function test_complicated(t)
    io.write("Test Suite: Complicated Expressions\n")
    local prog, out
    local line

    prog = "set _=7-4*3set a=_*_+_ set b=a+a*-3+a==---20 printnum b"
    out = "1"
    check(t, prog, "Complicated expression #1", true, out)

    prog = "set a=2 set a=a-a*a*-(a<=a) printnum (a+6)/a"
    out = "2"
    check(t, prog, "Complicated expression #2", true, out)

    prog = "set a=2 set a=a-(-(-(-(-(-(-(-(-(-a)))))*(((3))))))) printnum a"
    out = "8"
    check(t, prog, "Complicated expression #3", true, out)
end


function test_practical(t)
    io.write("Test Suite: Practical Programs\n")
    local prog, out
    local line

    -- Fibo
    local n = 20
    line = "set c=a+b set a=b set b=c\n"
    prog = "set a=1 set b=0\n" .. line:rep(n) .. "printnum b printnl"
    out = "6765\n"
    check(t, prog, "Compute Fibonacci number F("..n..")", true, out)

    -- Approx e
    line = "set i=i+1 set x=x/i set e=e+x\n"
    prog = "printstr'e: 'set i=0 set x=1 set e=1\n" .. line:rep(20) .. "printnum e printnl"
    local function f1()
        local i, x, e = 0, 1, 1
        for k= 1, 20 do
            i=i+1 x=x/i e=e+x
        end
        return e
    end
    out = "e: "..f1().."\n"
    check(t, prog, "Approximate e", true, out)

    -- Approx sqrt(5)
    line = "set s = (s+n/s)/2\n"
    prog = "set n=5 set s=1\n" .. line:rep(12) .. "printstr 'Sqrt(5): ' printnum s printnl"
    local function f2()
        local n, s = 5, 1
        for k = 1, 12 do
            s = (s + n/s) / 2
        end
        return s
    end
    out = "Sqrt(5): "..f2().."\n"
    check(t, prog, "Approximate sqrt(5)", true, out)

    -- Print several squares
    code1 = "set n=0\n"
    code2 = "set n=n+1 printnum n printstr ' squared is ' printnum n*n printnl\n"
    prog = code1..code2:rep(8)
    out = "1 squared is 1\n2 squared is 4\n3 squared is 9\n4 squared is 16\n5 squared is 25\n6 squared is 36\n7 squared is 49\n8 squared is 64\n"
    check(t, prog, "Print several squares", true, out)
end


function test_spt15(t)
    io.write("TEST SUITES FOR MODULE spt15\n")
    test_trivial(t)
    test_print(t)
    test_nums(t)
    test_vars(t)
    test_ops_nums(t)
    test_ops_vars(t)
    test_associativity(t)
    test_precedence(t)
    test_if(t)
    test_complicated(t)
    test_practical(t)
end


-- *********************************************************************
-- Main Program
-- *********************************************************************


test_spt15(tester)
io.write("\n")
if tester:allPassed() then
    io.write("All tests successful\n")
else
    io.write("Tests ********** UNSUCCESSFUL **********\n")
    io.write("\n")
    io.write("NOTE: This program is set to execute all tests. If you\n")
    io.write("      would prefer to stop after the first failing\n")
    io.write("      test and see detailed results, then set variable\n")
    io.write("      exit_on_failure to true. (See the beginning of\n")
    io.write("      the source code.)\n")
end
io.write("\n")


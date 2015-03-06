#!/usr/bin/env lua
-- lexit_test.lua
-- Glenn G. Chappell
-- 15 Feb 2015
--
-- For CS 331 Spring 2015
-- Test Program for Module lexit
-- Used in Assignment 3, Exercise A

lexit = require "lexit"  -- Import lexit module


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


-- Lexeme Categories
ID = 1
KEY = 2
OP = 3
NUMLIT = 4
STRLIT = 5
PUNCT = 6
MAL = 7


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


-- arrayEq
-- Given two arrays, tests whether they are equal, using "==" operator
-- on all values.
function arrayEq(a1, a2)
    if #a1 ~= #a2 then
        return false
    end
    for k, v in ipairs(a1) do
        if a2[k] ~= v then
            return false
        end
    end
    return true
end


function checklex(t, prog, expectedOutput, testName, poTest)
    local poCalls = {}
    local function printResults(output, printPOC)
        if printPOC == true then
            io.write(
              "[* indicates lexit.preferOp() called before this lexeme]\n")
        end
        local blank = " "
        local i = 1
        while i*2 <= #output do
            local lexstr = '"'..output[2*i-1]..'"'
            if printPOC == true then
               if poCalls[i] then
                   lexstr = "* " .. lexstr
               else
                   lexstr = "  " .. lexstr
               end
            end
            local lexlen = lexstr:len()
            if lexlen < 8 then
                lexstr = lexstr..blank:rep(8-lexlen)
            end
            local catname = lexit.catnames[output[2*i]]
            print(lexstr, catname)
            i = i+1
        end
    end

    local actualOutput = {}

    local count = 1
    local poc = false
    if poTest ~= nil then
        poc = poTest(count, nil, nil)
        if poc then lexit.preferOp() end
    end
    table.insert(poCalls, poc)

    for lexstr, cat in lexit.lex(prog) do
        table.insert(actualOutput, lexstr)
        table.insert(actualOutput, cat)
        count = count+1
        poc = false
        if poTest ~= nil then
            poc = poTest(count, lexstr, cat)
            if poc then lexit.preferOp() end
        end
        table.insert(poCalls, poc)
    end

    local success = arrayEq(actualOutput, expectedOutput)
    t:test(success, testName)
    if exit_on_failure and not success then
        io.write("\n")
        io.write("Input for the last test above:\n")
        io.write('"'..prog..'"\n')
        io.write("\n")
        io.write("Expected output of lexit.lex:\n")
        printResults(expectedOutput)
        io.write("\n")
        io.write("Actual output of lexit.lex:\n")
        printResults(actualOutput, poTest ~= nil)
        printNoteAndExit()
   end
end


-- *********************************************************************
-- Test Suite Functions
-- *********************************************************************


function test_catnames(t)
    io.write("Test Suite: Member catnames\n")

    local success =
        #lexit.catnames == 7 and
        lexit.catnames[1] == "Identifier" and
        lexit.catnames[2] == "Keyword" and
        lexit.catnames[3] == "Operator" and
        lexit.catnames[4] == "NumericLiteral" and
        lexit.catnames[5] == "StringLiteral" and
        lexit.catnames[6] == "Punctuation" and
        lexit.catnames[7] == "Malformed"
    t:test(success, "Value of catnames member")
    if exit_on_failure and not success then
        io.write("\n")
        io.write("Array lexit.catnames does not have the required\n")
        io.write("values. See the assignment description, where the\n")
        io.write("proper values are listed in a table.\n")
        printNoteAndExit()
    end
end


function test_idkey(t)
    io.write("Test Suite: Identifiers & Keywords\n")

    checklex(t, "a", {"a",ID}, "single letter")
    checklex(t, "_", {"_",ID}, "single underscore")
    checklex(t, "9", {"9",NUMLIT}, "single digit")
    checklex(t, "ab", {"ab",ID}, "letter then letter")
    checklex(t, "a_", {"a_",ID}, "letter then underscore")
    checklex(t, "a5", {"a5",ID}, "letter then digit")
    checklex(t, "_b", {"_b",ID}, "underscore then letter")
    checklex(t, "__", {"__",ID}, "underscore then underscore")
    checklex(t, "_5", {"_5",ID}, "underscore then digit")
    checklex(t, "2b", {"2",NUMLIT,"b",ID}, "digit then letter")
    checklex(t, "2_", {"2",NUMLIT,"_",ID}, "digit then underscore")
    checklex(t, "25", {"25",NUMLIT}, "digit then digit")

    checklex(t, "_a3bb2984_d__", {"_a3bb2984_d__",ID}, "longer ID")
    local astr = "a"
    local longidstr = astr:rep(10000)
    checklex(t, longidstr, {longidstr,ID}, "very long ID #1")
    checklex(t, longidstr.."+", {longidstr,ID,"+",OP},
             "very long ID #2")
    checklex(t, "abc def", {"abc",ID,"def",ID}, "space-separated IDs")

    -- Keywords
    checklex(t, "set", {"set",KEY}, "Single keyword #1")
    checklex(t, "if", {"if",KEY}, "Single keyword #2")
    checklex(t, "printnum", {"printnum",KEY}, "Single keyword #3")
    checklex(t, "printstr", {"printstr",KEY}, "Single keyword #4")
    checklex(t, "printnl", {"printnl",KEY}, "Single keyword #5")
    checklex(t, "setx", {"setx",ID}, "ID starting with keyword #1")
    checklex(t, "ifx", {"ifx",ID}, "ID starting with keyword #2")
    checklex(t, "printnumx", {"printnumx",ID}, "ID starting with keyword #3")
    checklex(t, "printstrx", {"printstrx",ID}, "ID starting with keyword #4")
    checklex(t, "printnlx", {"printnlx",ID}, "ID starting with keyword #5")
    checklex(t, "xset", {"xset",ID}, "ID ending with keyword #1")
    checklex(t, "xif", {"xif",ID}, "ID ending with keyword #2")
    checklex(t, "xprintnum", {"xprintnum",ID}, "ID ending with keyword #3")
    checklex(t, "xprintstr", {"xprintstr",ID}, "ID ending with keyword #4")
    checklex(t, "xprintnl", {"xprintnl",ID}, "ID ending with keyword #5")
    checklex(t, "3set", {"3",NUMLIT,"set",KEY}, "digit keyword #1")
    checklex(t, "3if", {"3",NUMLIT,"if",KEY}, "digit keyword #2")
    checklex(t, "3printnum", {"3",NUMLIT,"printnum",KEY}, "digit keyword #3")
    checklex(t, "3printstr", {"3",NUMLIT,"printstr",KEY}, "digit keyword #4")
    checklex(t, "3printnl", {"3",NUMLIT,"printnl",KEY}, "digit keyword #5")
    checklex(t, "se t", {"se",ID,"t",ID}, "Space-broken keyword #1")
    checklex(t, "i f", {"i",ID,"f",ID}, "Space-broken keyword #2")
    checklex(t, "prin tnum", {"prin",ID,"tnum",ID}, "Space-broken keyword #3")
    checklex(t, "pri ntstr", {"pri",ID,"ntstr",ID}, "Space-broken keyword #4")
    checklex(t, "pr intnl", {"pr",ID,"intnl",ID}, "Space-broken keyword #5")
    checklex(t, "u set v if w printnum x printstr y printnl z",
             {"u",ID,"set",KEY,"v",ID,"if",KEY,"w",ID,"printnum",KEY,
              "x",ID, "printstr",KEY,"y",ID,"printnl",KEY,"z",ID},
             "IDs & keywords")
end


function test_oppunct(t)
    io.write("Test Suite: Operators & Punctuation\n")

    -- Operator alone
    checklex(t, "+",  {"+",OP}, "+ alone")
    checklex(t, "-",  {"-",OP}, "- alone")
    checklex(t, "*",  {"*",OP}, "* alone")
    checklex(t, "/",  {"/",OP}, "/ alone")
    checklex(t, "=",  {"=",OP}, "= alone")
    checklex(t, "==", {"==",OP}, "== alone")
    checklex(t, "!",  {"!",PUNCT}, "! alone")
    checklex(t, "!=", {"!=",OP}, "!= alone")
    checklex(t, "<",  {"<",OP}, "< alone")
    checklex(t, "<=", {"<=",OP}, "<= alone")
    checklex(t, ">",  {">",OP}, "> alone")
    checklex(t, ">=", {">=",OP}, ">= alone")

    -- Operator followed by digit
    checklex(t, "+1",  {"+1",NUMLIT}, "+ then 1")
    checklex(t, "-1",  {"-1",NUMLIT}, "- then 1")
    checklex(t, "*1",  {"*",OP,"1",NUMLIT}, "* then 1")
    checklex(t, "/1",  {"/",OP,"1",NUMLIT}, "/ then 1")
    checklex(t, "=1",  {"=",OP,"1",NUMLIT}, "= then 1")
    checklex(t, "==1", {"==",OP,"1",NUMLIT}, "== then 1")
    checklex(t, "!1",  {"!",PUNCT,"1",NUMLIT}, "! then 1")
    checklex(t, "!=1", {"!=",OP,"1",NUMLIT}, "!= then 1")
    checklex(t, "<1",  {"<",OP,"1",NUMLIT}, "< then 1")
    checklex(t, "<=1", {"<=",OP,"1",NUMLIT}, "<= then 1")
    checklex(t, ">1",  {">",OP,"1",NUMLIT}, "> then 1")
    checklex(t, ">=1", {">=",OP,"1",NUMLIT}, ">= then 1")

    -- Operator followed by letter
    checklex(t, "+a",  {"+",OP,"a",ID}, "+ then a")
    checklex(t, "-a",  {"-",OP,"a",ID}, "- then a")
    checklex(t, "*a",  {"*",OP,"a",ID}, "* then a")
    checklex(t, "/a",  {"/",OP,"a",ID}, "/ then a")
    checklex(t, "=a",  {"=",OP,"a",ID}, "= then a")
    checklex(t, "==a", {"==",OP,"a",ID}, "== then a")
    checklex(t, "!a",  {"!",PUNCT,"a",ID}, "! then a")
    checklex(t, "!=a", {"!=",OP,"a",ID}, "!= then a")
    checklex(t, "<a",  {"<",OP,"a",ID}, "< then a")
    checklex(t, "<=a", {"<=",OP,"a",ID}, "<= then a")
    checklex(t, ">a",  {">",OP,"a",ID}, "> then a")
    checklex(t, ">=a", {">=",OP,"a",ID}, ">= then a")

    -- Operator followed by "*"
    checklex(t, "+*",  {"+",OP,"*",OP}, "+ then *")
    checklex(t, "-*",  {"-",OP,"*",OP}, "- then *")
    checklex(t, "**",  {"*",OP,"*",OP}, "* then *")
    checklex(t, "/*",  {}, "/ then *")
    checklex(t, "=*",  {"=",OP,"*",OP}, "= then *")
    checklex(t, "==*", {"==",OP,"*",OP}, "== then *")
    checklex(t, "!*",  {"!",PUNCT,"*",OP}, "! then *")
    checklex(t, "!=*", {"!=",OP,"*",OP}, "!= then *")
    checklex(t, "<*",  {"<",OP,"*",OP}, "< then *")
    checklex(t, "<=*", {"<=",OP,"*",OP}, "<= then *")
    checklex(t, ">*",  {">",OP,"*",OP}, "> then *")
    checklex(t, ">=*", {">=",OP,"*",OP}, ">= then *")

    -- Eliminated operators
    checklex(t, "++",  {"+",OP,"+",OP}, "old operator: ++")
    checklex(t, "--",  {"-",OP,"-",OP}, "old operator: --")
    checklex(t, "--2", {"-",OP,"-2",NUMLIT}, "old operator: -- then 2")
    checklex(t, "+=",  {"+",OP,"=",OP}, "old operator: +=")
    checklex(t, "-=",  {"-",OP,"=",OP}, "old operator: -=")
    checklex(t, ".",   {".",PUNCT}, "old operator: .")
    checklex(t, "#",   {"#",PUNCT}, "old comment specifier: #")

    -- More complex stuff
    checklex(t, "=====",  {"==",OP,"==",OP,"=",OP}, "=====")
    checklex(t, "=<<==",  {"=",OP,"<",OP,"<=",OP,"=",OP}, "=<<==")
    checklex(t, "**/ ",  {"*",OP,"*",OP,"/",OP}, "**/ ")
    checklex(t, "= =", {"=",OP,"=",OP}, "= =")
    checklex(t, ".--2.-", {".",PUNCT,"-",OP,"-2.",NUMLIT,"-",OP}, ".--2.")

    -- Punctuation chars
    checklex(t, "(", {"(",PUNCT}, "left parenthesis")
    checklex(t, ")", {")",PUNCT}, "right parenthesis")
    checklex(t, "[", {"[",PUNCT}, "left bracket")
    checklex(t, "]", {"]",PUNCT}, "right bracket")
    checklex(t, "{", {"{",PUNCT}, "left brace")
    checklex(t, "}", {"}",PUNCT}, "right brace")
    checklex(t, "!@#$%^&*()",
             {"!",PUNCT,"@",PUNCT,"#",PUNCT,"$",PUNCT,"%",PUNCT,
              "^",PUNCT,"&",PUNCT,"*",OP,"(",PUNCT,")",PUNCT},
             "assorted punctuation & operators #1")
    checklex(t, ",.;:\\|=+-_`~/?",
             {",",PUNCT,".",PUNCT,";",PUNCT,":",PUNCT,"\\",PUNCT,
              "|",PUNCT,"=",OP,"+",OP,"-",OP,"_",ID,"`",PUNCT,"~",PUNCT,
              "/",OP,"?",PUNCT},
             "assorted punctuation & operators #2")
end


function test_num(t)
    io.write("Test Suite: Numeric Literals\n")

    checklex(t, "3", {"3",NUMLIT}, "single digit")
    checklex(t, "3a", {"3",NUMLIT,"a",ID}, "single digit then letter")

    checklex(t, "123456", {"123456",NUMLIT}, "num, no dot")
    checklex(t, ".123456", {".123456",NUMLIT}, "num, dot @ start")
    checklex(t, "123456.", {"123456.",NUMLIT}, "num, dot @ end")
    checklex(t, "123.456", {"123.456",NUMLIT}, "num, dot in middle")
    checklex(t, "1.2.3", {"1.2",NUMLIT,".3",NUMLIT}, "num, 2 dots")

    checklex(t, "+123456", {"+123456",NUMLIT}, "+num, no dot")
    checklex(t, "+.123456", {"+.123456",NUMLIT}, "+num, dot @ start")
    checklex(t, "+123456.", {"+123456.",NUMLIT}, "+num, dot @ end")
    checklex(t, "+123.456", {"+123.456",NUMLIT},
             "+num, dot in middle")
    checklex(t, "+1.2.3", {"+1.2",NUMLIT,".3",NUMLIT}, "+num, 2 dots")

    checklex(t, "-123456", {"-123456",NUMLIT}, "-num, no dot")
    checklex(t, "-.123456", {"-.123456",NUMLIT}, "-num, dot @ start")
    checklex(t, "-123456.", {"-123456.",NUMLIT}, "-num, dot @ end")
    checklex(t, "-123.456", {"-123.456",NUMLIT}, "-num, dot in middle")
    checklex(t, "-1.2.3", {"-1.2",NUMLIT,".3",NUMLIT}, "-num, 2 dots")

    checklex(t, "--123456", {"-",OP,"-123456",NUMLIT}, "--num, no dot")
    checklex(t, "--.123456", {"-",OP,"-.123456",NUMLIT},
             "--num, dot @ start")
    checklex(t, "--123456.", {"-",OP,"-123456.",NUMLIT},
             "--num, dot @ end")
    checklex(t, "--123.456", {"-",OP,"-123.456",NUMLIT},
             "--num, dot in middle")
    checklex(t, "--1.2.3", {"-",OP,"-1.2",NUMLIT,".3",NUMLIT},
             "--num, 2 dots")

    local onestr = "1"
    local longnumstr = onestr:rep(10000)
    checklex(t, longnumstr, {longnumstr,NUMLIT}, "very long num #1")
    checklex(t, longnumstr.."+", {longnumstr,NUMLIT,"+",OP},
             "very long num #2")
    checklex(t, "123 456", {"123",NUMLIT,"456",NUMLIT},
             "space-separated nums")

    -- Exponents
    checklex(t, "123e", {"123",NUMLIT,"e",ID}, "num e #1")
    checklex(t, "123.e", {"123.",NUMLIT,"e",ID}, "num e #2")
    checklex(t, "123E", {"123",NUMLIT,"E",ID}, "num e #3")
    checklex(t, "123.E", {"123.",NUMLIT,"E",ID}, "num e #4")
    checklex(t, "123ee", {"123",NUMLIT,"ee",ID}, "num ee #1")
    checklex(t, "123.ee", {"123.",NUMLIT,"ee",ID}, "num ee #2")
    checklex(t, "123Ee", {"123",NUMLIT,"Ee",ID}, "num ee #3")
    checklex(t, "123.Ee", {"123.",NUMLIT,"Ee",ID}, "num ee #4")
    checklex(t, "123eE", {"123",NUMLIT,"eE",ID}, "num ee #5")
    checklex(t, "123.eE", {"123.",NUMLIT,"eE",ID}, "num ee #6")
    checklex(t, "123EE", {"123",NUMLIT,"EE",ID}, "num ee #7")
    checklex(t, "123.EE", {"123.",NUMLIT,"EE",ID}, "num ee #8")
    checklex(t, "123e-", {"123",NUMLIT,"e",ID,"-",OP}, "num e- #1")
    checklex(t, "123.e-", {"123.",NUMLIT,"e",ID,"-",OP}, "num e- #2")
    checklex(t, "123E-", {"123",NUMLIT,"E",ID,"-",OP}, "num e- #3")
    checklex(t, "123.E-", {"123.",NUMLIT,"E",ID,"-",OP}, "num e- #4")
    checklex(t, "123e+", {"123",NUMLIT,"e",ID,"+",OP}, "num e+ #1")
    checklex(t, "123.e+", {"123.",NUMLIT,"e",ID,"+",OP}, "num e+ #2")
    checklex(t, "123E+", {"123",NUMLIT,"E",ID,"+",OP}, "num e+ #3")
    checklex(t, "123.E+", {"123.",NUMLIT,"E",ID,"+",OP}, "num e+ #4")
    checklex(t, "123e7", {"123e7",NUMLIT}, "num e7 #1")
    checklex(t, "123.e7", {"123.e7",NUMLIT}, "num e7 #2")
    checklex(t, "123E7", {"123E7",NUMLIT}, "num e7 #3")
    checklex(t, "123.E7", {"123.E7",NUMLIT}, "num e7 #4")
    checklex(t, "123ee7", {"123",NUMLIT,"ee7",ID}, "num ee7 #1")
    checklex(t, "123.ee7", {"123.",NUMLIT,"ee7",ID}, "num ee7 #2")
    checklex(t, "123Ee7", {"123",NUMLIT,"Ee7",ID}, "num ee7 #3")
    checklex(t, "123.Ee7", {"123.",NUMLIT,"Ee7",ID}, "num ee7 #4")
    checklex(t, "123eE7", {"123",NUMLIT,"eE7",ID}, "num ee7 #5")
    checklex(t, "123.eE7", {"123.",NUMLIT,"eE7",ID}, "num ee7 #6")
    checklex(t, "123EE7", {"123",NUMLIT,"EE7",ID}, "num ee7 #7")
    checklex(t, "123.EE7", {"123.",NUMLIT,"EE7",ID}, "num ee7 #8")
    checklex(t, "123e-7", {"123e-7",NUMLIT}, "num e-7 #1")
    checklex(t, "123.e-7", {"123.e-7",NUMLIT}, "num e-7 #2")
    checklex(t, "123E-7", {"123E-7",NUMLIT}, "num e-7 #3")
    checklex(t, "123.E-7", {"123.E-7",NUMLIT}, "num e-7 #4")
    checklex(t, "123e+7", {"123e+7",NUMLIT}, "num e+7 #1")
    checklex(t, "123.e+7", {"123.e+7",NUMLIT}, "num e+7 #2")
    checklex(t, "123E+7", {"123E+7",NUMLIT}, "num e+7 #3")
    checklex(t, "123.E+7", {"123.E+7",NUMLIT}, "num e+7 #4")
    checklex(t, "123e.", {"123",NUMLIT,"e",ID,".",PUNCT}, "num e. #1")
    checklex(t, "123.e.", {"123.",NUMLIT,"e",ID,".",PUNCT}, "num e. #2")
    checklex(t, "123E.", {"123",NUMLIT,"E",ID,".",PUNCT}, "num e. #3")
    checklex(t, "123.E.", {"123.",NUMLIT,"E",ID,".",PUNCT}, "num e. #4")
    checklex(t, "123e-.", {"123",NUMLIT,"e",ID,"-",OP,".",PUNCT},
             "num e-. #1")
    checklex(t, "123.e-.", {"123.",NUMLIT,"e",ID,"-",OP,".",PUNCT},
             "num e-. #2")
    checklex(t, "123E-.", {"123",NUMLIT,"E",ID,"-",OP,".",PUNCT},
             "num e-. #3")
    checklex(t, "123.E-.", {"123.",NUMLIT,"E",ID,"-",OP,".",PUNCT},
             "num e-. #4")
    checklex(t, "123e+.", {"123",NUMLIT,"e",ID,"+",OP,".",PUNCT},
             "num e+. #1")
    checklex(t, "123.e+.", {"123.",NUMLIT,"e",ID,"+",OP,".",PUNCT},
             "num e+. #2")
    checklex(t, "123E+.", {"123",NUMLIT,"E",ID,"+",OP,".",PUNCT},
             "num e+. #3")
    checklex(t, "123.E+.", {"123.",NUMLIT,"E",ID,"+",OP,".",PUNCT},
             "num e+. #4")
    checklex(t, "123e7.", {"123e7",NUMLIT,".",PUNCT}, "num e7. #1")
    checklex(t, "123.e7.", {"123.e7",NUMLIT,".",PUNCT}, "num e7. #2")
    checklex(t, "123E7.", {"123E7",NUMLIT,".",PUNCT}, "num e7. #3")
    checklex(t, "123.E7.", {"123.E7",NUMLIT,".",PUNCT}, "num e7. #4")
    checklex(t, "123e-7.", {"123e-7",NUMLIT,".",PUNCT}, "num e-7. #1")
    checklex(t, "123.e-7.", {"123.e-7",NUMLIT,".",PUNCT}, "num e-7. #2")
    checklex(t, "123E-7.", {"123E-7",NUMLIT,".",PUNCT}, "num e-7. #3")
    checklex(t, "123.E-7.", {"123.E-7",NUMLIT,".",PUNCT}, "num e-7. #4")
    checklex(t, "123e+7.", {"123e+7",NUMLIT,".",PUNCT}, "num e+7. #1")
    checklex(t, "123.e+7.", {"123.e+7",NUMLIT,".",PUNCT}, "num e+7. #2")
    checklex(t, "123E+7.", {"123E+7",NUMLIT,".",PUNCT}, "num e+7. #3")
    checklex(t, "123.E+7.", {"123.E+7",NUMLIT,".",PUNCT}, "num e+7. #4")
    checklex(t, "123e+e7", {"123",NUMLIT,"e",ID,"+",OP,"e7",ID},
             "num e+e7")
    checklex(t, "123e-e7", {"123",NUMLIT,"e",ID,"-",OP,"e7",ID},
             "num e-e7")
    checklex(t, "123e7e", {"123e7",NUMLIT,"e",ID}, "num e7e")
    checklex(t, "123e+7e", {"123e+7",NUMLIT,"e",ID}, "num e+7e")
    checklex(t, "123e-7e", {"123e-7",NUMLIT,"e",ID}, "num e-7e")
    checklex(t, "123f7", {"123",NUMLIT,"f7",ID}, "num f7 #1")
    checklex(t, "123.f7", {"123.",NUMLIT,"f7",ID}, "num f7 #2")
    checklex(t, "123F7", {"123",NUMLIT,"F7",ID}, "num f7 #3")
    checklex(t, "123.F7", {"123.",NUMLIT,"F7",ID}, "num f7 #4")
    checklex(t, "123e789", {"123e789",NUMLIT}, "multidigit exponent")

    checklex(t, "123. e+7.", {"123.",NUMLIT,"e",ID,"+7.",NUMLIT},
             "space-separated exponent #1")
    checklex(t, "123. e-7.", {"123.",NUMLIT,"e",ID,"-7.",NUMLIT},
             "space-separated exponent #2")
    checklex(t, "123e1 2", {"123e1",NUMLIT,"2",NUMLIT},
             "space-separated exponent #3")
    twostr = "2"
    longexp = twostr:rep(10000)
    checklex(t, "3e"..longexp, {"3e"..longexp,NUMLIT}, "long exponent #1")
    checklex(t, "3e"..longexp.."-", {"3e"..longexp,NUMLIT,"-",OP},
             "long exponent #2")
end


function test_illegal(t)
    io.write("Test Suite: Illegal Characters\n")

    checklex(t, "\001", {"\001",MAL}, "Single illegal character #1")
    checklex(t, "\031", {"\031",MAL}, "Single illegal character #2")
    checklex(t, "a\002bcd\003\004ef",
             {"a",ID,"\002",MAL,"bcd",ID,"\003",MAL,
              "\004",MAL,"ef",ID},
             "Various illegal characters")
    checklex(t, "a/*\001*/b", {"a",ID,"b",ID},
             "Illegal character in comment")
    checklex(t, "b'\001'", {"b",ID,"'\001'",STRLIT},
             "Illegal character in single-quoted string")
    checklex(t, "c\"\001\"", {"c",ID,"\"\001\"",STRLIT},
             "Illegal character in double-quoted string")
    checklex(t, "b'\001", {"b",ID,"'\001",MAL},
             "Illegal character in single-quoted partial string")
    checklex(t, "c\"\001", {"c",ID,"\"\001",MAL},
             "Illegal character in double-quoted partial string")
end


function test_comment(t)
    io.write("Test Suite: Space & Comments\n")

    -- Space
    checklex(t, " ", {}, "Single space character #1")
    checklex(t, "\t", {}, "Single space character #2")
    checklex(t, "\n", {}, "Single space character #3")
    checklex(t, "\r", {}, "Single space character #4")
    checklex(t, "\f", {}, "Single space character #5")
    checklex(t, "ab 12", {"ab",ID,"12",NUMLIT},
             "Space-separated lexemes #1")
    checklex(t, "ab\t12", {"ab",ID,"12",NUMLIT},
             "Space-separated lexemes #2")
    checklex(t, "ab\n12", {"ab",ID,"12",NUMLIT},
             "Space-separated lexemes #3")
    checklex(t, "ab\r12", {"ab",ID,"12",NUMLIT},
             "Space-separated lexemes #4")
    checklex(t, "ab\f12", {"ab",ID,"12",NUMLIT},
             "Space-separated lexemes #5")
    blankstr = " "
    longspace = blankstr:rep(10000)
    checklex(t, longspace.."abc"..longspace, {"abc",ID},
             "very long space")

    -- Comments
    checklex(t, "/*abcd*/", {}, "Comment")
    checklex(t, "12/*abcd*/ab", {"12",NUMLIT,"ab",ID},
             "Comment-separated lexemes")
    checklex(t, "12/*ab\ncd*/ab", {"12",NUMLIT,"ab",ID},
             "Newline in comment")
    checklex(t, "12/*ab\n\n\n\n\ncd*/ab", {"12",NUMLIT,"ab",ID},
             "Multiple newlines in comment")
    checklex(t, "12/*abcd", {"12",NUMLIT}, "Unterminated comment #1")
    checklex(t, "12/*abcd*", {"12",NUMLIT}, "Unterminated comment #2")
    checklex(t, "12/*a*//*b*//*c*/ab", {"12",NUMLIT,"ab",ID},
             "Multiple comments #1")
    checklex(t, "12/*a*/  /*b*/ \n /*c*/ab", {"12",NUMLIT,"ab",ID},
             "Multiple comments #2")
    checklex(t, "12/*a*/=/*b*/./*c*/ab",
             {"12",NUMLIT,"=",OP,".",PUNCT,"ab",ID},
             "Multiple comments #3")
    checklex(t, "a/**/b", {"a",ID,"b",ID}, "Mix of *, / #1")
    checklex(t, "a/*/b", {"a",ID}, "Mix of *, / #2")
    checklex(t, "a/*/b/*/c", {"a",ID,"c",ID}, "Mix of *, / #3")
    checklex(t, "a*//*//*b/**/c/**", {"a",ID,"*",OP,"/",OP,"c",ID},
             "Mix of *, / #4")
    checklex(t, "a*/*/*//*/*/**/*/*//*/*/*b",
             {"a",ID,"*",OP,"*",OP,"*",OP,"*",OP,"b",ID},
             "Mix of *, / #5")
    checklex(t, "a****////****////****b",
             {"a",ID,"*",OP,"*",OP,"*",OP,"*",OP,"/",OP,"/",OP,"/",OP,
              "/",OP,"/",OP},
             "Mix of *, / #6")
    checklex(t, "a///***///***///b",
             {"a",ID,"/",OP,"/",OP,"/",OP,"/",OP,"/",OP,"b",ID},
             "Mix of *, / #7")
    xstr = "x"
    longcmt = "/*"..xstr:rep(10000).."*/"
    checklex(t, "a"..longcmt.."b", {"a",ID,"b",ID}, "very long comment")
end


function test_string(t)
    io.write("Test Suite: String Literals\n")

    checklex(t, "''", {"''",STRLIT}, "Empty single-quoted string")
    checklex(t, "\"\"", {"\"\"",STRLIT}, "Empty double-quoted string")
    checklex(t, "'a'", {"'a'",STRLIT}, "1-char single-quoted string")
    checklex(t, "\"b\"", {"\"b\"",STRLIT}, "1-char double-quoted string")
    checklex(t, "'abc def'", {"'abc def'",STRLIT},
             "longer single-quoted string")
    checklex(t, "\"The quick brown fox.\"",
             {"\"The quick brown fox.\"",STRLIT},
             "longer double-quoted string")
    checklex(t, "'aa\"bb'", {"'aa\"bb'",STRLIT},
             "single-quoted string with double quote")
    checklex(t, "\"cc'dd\"", {"\"cc'dd\"",STRLIT},
             "double-quoted string with single quote")
    checklex(t, "'aabbcc", {"'aabbcc",MAL},
             "partial single-quoted string #1")
    checklex(t, "'aabbcc\"", {"'aabbcc\"",MAL},
             "partial single-quoted string #2")
    checklex(t, "\"aabbcc", {"\"aabbcc",MAL},
             "partial double-quoted string #1")
    checklex(t, "\"aabbcc'", {"\"aabbcc'",MAL},
             "partial double-quoted string #2")
    checklex(t, "'\"'\"'\"", {"'\"'",STRLIT,"\"'\"",STRLIT},
             "multiple strings")
    checklex(t, "'/*'/*'*/'*/'", {"'/*'",STRLIT,"'*/'",STRLIT},
             "strings & comments")
    checklex(t, "\"a\"a\"a\"a\"",
             {"\"a\"",STRLIT,"a",ID,"\"a\"",STRLIT,"a",ID,"\"",MAL},
             "strings & identifiers")
    xstr = "x"
    longstr = "'"..xstr:rep(10000).."'"
    checklex(t, "a"..longstr.."b", {"a",ID,longstr,STRLIT,"b",ID},
             "very long string")
end


function test_preferop(t)
    io.write("Test Suite: Using preferOp\n")

    local function po_false(n,s,c) return false end
    local function po_true(n,s,c) return true end
    local function po_two(n,s,c) return n==2 or n==5 end
    local function po_val(n,s,c)
        return c == NUMLIT or c == ID or (c == PUNCT and s == ")")
    end

    checklex(t, "-1-1-1-1", {"-1",NUMLIT,"-1",NUMLIT,"-1",NUMLIT,"-1",NUMLIT},
             "preferOp never called", po_false)
    checklex(t, "-1-1-1-1",
             {"-",OP,"1",NUMLIT,"-",OP,"1",NUMLIT,"-",OP,"1",NUMLIT,"-",OP,
              "1",NUMLIT},
             "preferOp always called", po_true)
    checklex(t, "-1-1-1-1",
             {"-1",NUMLIT,"-",OP,"1",NUMLIT,"-1",NUMLIT,"-",OP,"1",NUMLIT},
             "preferOp called on lexemes 2 & 5", po_two)
    checklex(t, "-1-1-1-1",
             {"-1",NUMLIT,"-",OP,"1",NUMLIT,"-",OP,"1",NUMLIT,"-",OP,"1",NUMLIT},
             "preferOp called after values", po_val)
end


function test_program(t)
    io.write("Test Suite: Complete Programs\n")

    local function po_val(n,s,c)
        return c == NUMLIT or c == ID or (c == PUNCT and s == ")")
    end

    checklex(t, "set a = -3.4 /* var */\nset bc=a+17e2\n" ..
                "printnum bc/3-7\nprintnl\n" ..
                "if a>2 printstr 'big'\nprintnl\n",
             {"set",KEY,"a",ID,"=",OP,"-3.4",NUMLIT,"set",KEY,"bc",ID,
              "=",OP,"a",ID,"+",OP,"17e2",NUMLIT,"printnum",KEY,"bc",ID,
              "/",OP,"3",NUMLIT,"-",OP,"7",NUMLIT,"printnl",KEY,
              "if",KEY,"a",ID,">",OP,"2",NUMLIT,"printstr",KEY,
              "'big'",STRLIT,"printnl",KEY},"Complete program", po_val)

end


function test_lexit(t)
    io.write("TEST SUITES FOR MODULE lex\n")
    test_catnames(t)
    test_idkey(t)
    test_oppunct(t)
    test_num(t)
    test_illegal(t)
    test_comment(t)
    test_string(t)
    test_preferop(t)
    test_program(t)
end


-- *********************************************************************
-- Main Program
-- *********************************************************************


test_lexit(tester)
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


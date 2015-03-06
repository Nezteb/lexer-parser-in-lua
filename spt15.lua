-- spt15.lua
-- Noah Betzen
-- Due 3 March 2015
-- CS 331 Spring 2015
-- Recursive-Descent Parser: Expression Evaluation
-- Requires lexit.lua

-- *****Requires Lua 5.2.3*****

-- the grammar:
--
--     program   -> {statement}$
--     statement -> "set" ID "=" numexpr
--                | "printnum" numexpr
--                | "printstr" STRLIT
--                | "printnl"
--                | "if" numexpr statement
--     numexpr   -> aexpr {("=="|"!="|"<"|"<="|">"|">=") aexpr}
--     aexpr     -> term {("+"|"-") term}
--     term      -> factor {("*"|"/") factor}
--     factor    -> ID
--                | NUMLIT
--                | "(" numexpr ")"
--                | ("+"|"-") factor


local spt15 = {}  -- module

lexit = require "lexit"


-- variables

-- for lexer iteration
local iter          -- iterator returned by lexit.lex
local state         -- state for above iterator (might not be used)
local lexer_out_string   -- return value #1 from above iterator
local lexer_out_category   -- return value #2 from above iterator

-- for current lexeme
local lexstr = ""   -- string form of current lexeme
local lexcat = 0    -- category of current lexeme:
                    -- one of categories below, or 0 for past the end

local vars = {} -- create table of SLL variables

-- lexeme Categories
    local ID = 1
    local KEY = 2
    local OP = 3
    local NUMLIT = 4
    local STRINGLIT = 5
    local PUNCT = 6
    local MALFORMED = 7

-- utility functions

-- advance:
-- go to next lexeme and load it into lexstr, lexcat
-- should be called once before any parsing is done
-- function init must be called before this function is called
local function advance()
    -- advance the iterator
    lexer_out_string, lexer_out_category = iter(state, lexer_out_string)

    -- if we're not past the end, copy current lexeme into vars
    if lexer_out_string ~= nil then
        lexstr, lexcat = lexer_out_string, lexer_out_category
        print("LEXEME: "..lexstr.."\tCATEGORY: "..lexcat)

        if lexcat==ID or lexcat==NUMLIT or lexstr==")" then
            lexit.preferOp();
        end
    else
        lexstr, lexcat = "", 0
    end
end

-- init:
-- initial call
-- sets input for parsing functions
local function init(prog)
    iter, state, lexer_out_s = lexit.lex(prog)
    advance()
    vars = {} -- initalize empty variable table
end

-- atEnd:
-- returns true if end of input reached
-- function init must be called before this function is called
local function atEnd()
    return lexcat == 0
end

-- strToNum:
-- convert given string to a number
local function strToNum(s)
    return 0+s
end

-- matchString:
-- given string, see if current lexeme string form is equal to it
-- if so, advance and return true and the string
-- if not, return false and the string
-- function init must be called before this function is called
function matchString(s)
    if lexstr == s then
        advance()
        return true, lexstr
    else
        return false, lexstr
    end
end

-- matchCat:
-- given lexeme category, see if current lexeme category is equal to it
-- if lexeme is a numlit, turn it into a number
-- if it matches, return true and string (or value if numlit)
-- if false, return true and string (or value if numlit)
-- function init must be called before this function is called
function matchCat(c)
    local returnvalue = lexstr
    if lexcat == NUMLIT then
            returnvalue = strToNum(returnvalue)
        end
    if lexcat == c then
        advance()
        return true, returnvalue
    else
        return false, returnvalue
    end
end

-- primary Function for client code

-- define local functions for later calling (like prototypes in C++)
local parse_program
local parse_statement
local parse_numexpr
local parse_aexpr
local parse_term
local parse_factor
-- one for each nonterimal

-- interp:
-- given program, initialize parser and call parsing function for start symbol
-- returns triple: two booleans and a number
-- first indicates successful parse or not
-- second indicates whether the parser reached the end of the input or not
-- number is numeric value of expression
-- valid only on successful parse.
function spt15.interp(prog)
    -- initialization
    init(prog)

    -- get results from parsing
    local success, value = parse_program()  -- parse start symbol

    -- and return them
    --return success, done, value
    return success, value
end

-- parsing functions

-- each of the following is a parsing function for a nonterminal in the grammar
-- each function parses the nonterminal in its name
-- a return value of true means a correct parse
-- and the current lexeme is just past the end of the string the nonterminal expanded into
-- a return value of false means an incorrect parse
-- in this case no guarantees are made about the current lexeme.

-- parse_program:
-- parsing function for nonterminal "program"
-- function init must be called before this function is called
-- rule: program -> {statement}$
-- returns boolean and string
function parse_program()
    if atEnd() then
        return true, "" -- blank program is valid
    end

    local all_output = ""
    local statement_success, statement_output
    while not atEnd() do
        statement_success, statement_output = parse_statement()
        if not statement_success then
            return false, statement_output
        else
            all_output = all_output..statement_output
        end
    end

    return true, all_output
end

-- parse_statement:
-- parsing function for nonterminal "statement"
-- function init must be called before this function is called
-- rule: statement -> "set" ID "=" numexpr
--                  | "printnum" numexpr
--                  | "printstr" STRLIT
--                  | "printnl"
--                  | "if" numexpr statement
-- returns boolean and string
function parse_statement()
    if matchString("set") then
        local matches, identifier = matchCat(ID)
        if matches then
            if matchString("=") then
                local numexpr_success, numexpr_output = parse_numexpr()
                if not numexpr_success then
                    return false, numexpr_output
                else
                    vars[identifier]=numexpr_output
                    return true, ""
                end
            else
                return false, "NO EQUAL SIGN AFTER SET ID"
            end
        else
            return false, "NO IDENTIFIER AFTER SET"
        end
    elseif matchString("printnum") then
        local numexpr_success, numexpr_output = parse_numexpr()
        if not numexpr_success then
            return false, numexpr_output
        else
            return true, numexpr_output
        end
    elseif matchString("printstr") then
        local matches, stringlit = matchCat(STRINGLIT)
        if matches then
            if stringlit == "''" or stringlit == '""' then
                return true, ""
            else
                --return true, string.gsub(stringlit, "[\'\"](%g+)[\'\"]", "%1")
                return true, stringlit:sub(2,-2) -- pull off quotes
            end
        else
            return false, "NO STRINGLIT AFTER PRINTSTR"
        end
    elseif matchString("printnl") then
        return true, "\n"
    elseif matchString("if") then
        local numexpr_success, numexpr_output = parse_numexpr()
        if not numexpr_success then
            return false, numexpr_output
        elseif numexpr_output ~= 0 then -- if true
            local statement_success, statement_output = parse_statement()
            if not statement_success then
                return false, statement_output
            else
                return true, statement_output
            end
        else
            local statement_success, statement_output = parse_statement()
            if not statement_success then
                return false, statement_output
            else
                return true, "" -- if statement is false, no need to evaluate statement
            end
        end
    else
        return false, "WRONG KEYWORD AT STATEMENT START"
    end
end

-- parse_numexpr:
-- parsing function for nonterminal "numexpr"
-- function init must be called before this function is called
-- rule: numexpr -> aexpr {("=="|"!="|"<"|"<="|">"|">=") aexpr}
-- returns boolean and number
function parse_numexpr()
    local aexpr_success, aexpr_value = parse_aexpr()

    if not aexpr_success then
        return false, aexpr_value
    else
        local op = lexstr
        local final_value = aexpr_value
        local second_aexpr_success, second_aexpr_value

        while not atEnd() do
            op = lexstr
            if not matchString("==") and
               not matchString("!=") and
               not matchString("<") and
               not matchString("<=") and
               not matchString(">") and
               not matchString(">=") then
                return true, final_value
            else
                second_aexpr_success, second_aexpr_value = parse_aexpr()
                if not second_aexpr_success then
                    return false, second_aexpr_value
                else
                    if (op == "==" and final_value == second_aexpr_value) or
                       (op == "!=" and final_value ~= second_aexpr_value) or
                       (op == "<" and final_value < second_aexpr_value) or
                       (op == "<=" and final_value <= second_aexpr_value) or
                       (op == ">" and final_value > second_aexpr_value) or
                       (op == ">=" and final_value >= second_aexpr_value) or
                       (op == "!=" and final_value ~= second_aexpr_value) then
                        final_value = 1
                    else
                        final_value = 0
                    end
                end
            end
        end

        return true, final_value
    end
end

-- parse_aexpr:
-- parsing function for nonterminal "aexpr"
-- function init must be called before this function is called
-- rule: aexpr -> term {("+"|"-") term}
-- returns boolean and number
function parse_aexpr()
    local term_success, term_value = parse_term()

    if not term_success then
        return false, term_value
    else
        local op = lexstr
        local total = term_value
        local second_term_success, second_term_value
        

        while not atEnd() do
            op = lexstr
            if not matchString("+") and not matchString("-") then
                return true, total
            else
                second_term_success, second_term_value = parse_term()
                if not second_term_success then
                    return false, second_term_value
                else
                    if op == "+" then
                        total = total + second_term_value
                    else
                        total = total - second_term_value
                    end
                end
            end
        end

        return true, total
    end
end

-- parse_term:
-- parsing function for nonterminal "term"
-- function init must be called before this function is called
-- rule: term -> factor {("*"|"/") factor}
-- returns boolean and number
function parse_term()
    local factor_success, factor_value = parse_factor()

    if not factor_success then
        return false, factor_value
    else
        local op = lexstr
        local total = factor_value
        local second_factor_success, second_factor_value
        

        while not atEnd() do
            op = lexstr
            if not matchString("*") and not matchString("/") then
                return true, total
            else
                second_factor_success, second_factor_value = parse_factor()
                if not second_factor_success then
                    return false, second_factor_value
                else
                    if op == "*" then
                        total = total * second_factor_value
                    else
                        total = total / second_factor_value
                    end
                end
            end
        end

        return true, total
    end
end

-- parse_factor:
-- parsing function for nonterminal "factor"
-- function init must be called before this function is called
-- rule: factor    -> ID
--                  | NUMLIT
--                  | "(" numexpr ")"
--                  | ("+"|"-") factor
-- returns boolean and number
function parse_factor()
    local matches, identifier = matchCat(ID)
    if matches then
        if vars[identifier] ~= nil then
            return true, vars[identifier]
        else
            return false, 0
        end
    else
        local number
        matches, number = matchCat(NUMLIT)
        if matches then
            return true, number
        else
            local op = lexstr -- grab lexstr in case it is an operator (plus or minus down below)
            if matchString("(") then
                local numexpr_success, numexpr_value = parse_numexpr()
                if numexpr_success then
                    if matchString(")") then
                        return true, numexpr_value
                    else
                        return false, "FACTOR IS MISSING RIGHT PARENTHESES"
                    end
                else
                    return false, "INVALID NUMEXPR IN PARENTHESES"
                end
            elseif matchString("+") or matchString("-") then
                local factor_success, factor_value = parse_factor()
                if not factor_success then
                    return false, factor_value
                else
                    if op == "+" then
                        return true, factor_value
                    else
                        return true, -1*factor_value
                    end
                end
            end
        end

        return false, "INVALID FACTOR"
    end
end

-- export module

return spt15
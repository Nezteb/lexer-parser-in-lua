-- Noah Betzen
-- CS 331 Programming Languages
-- Spring 2015
-- lexit.lua
-- Due Thursday February 19

local lexit = {} -- lexit module

-- categories of lexemes
lexit.catnames =
{
    "Identifier",
    "Keyword",
    "Operator",
    "NumericLiteral",
    "StringLiteral",
    "Punctuation",
    "Malformed"
}

local function isLetter(c)
    if c:len() ~= 1 then
        return false
    elseif c >= "A" and c <= "Z" then
        return true
    elseif c >= "a" and c <= "z" then
        return true
    else
        return false
    end
end

local function isDigit(c)
    if c:len() ~= 1 then
        return false
    elseif c >= "0" and c <= "9" then
        return true
    else
        return false
    end
end

local function isSpace(c)
    if c:len() ~= 1 then
        return false
    elseif c == " " or c == "\t" or c == "\n" or c == "\r"
      or c == "\f" then
        return true
    else
        return false
    end
end

local preferOp = false

function lexit.preferOp()
	preferOp = true
end

-- begin actual lexer

-- use lex (the lexer) in a for-in loop
-- like this: for lexstr, cat in lexer.lex(prog) do
function lexit.lex(prog)

    -- data member variables
    local pos -- index of next character in prog
    local state -- current state
    local ch -- current character
    local lexstr -- lexeme so far
    local category -- category of lexeme, set when state set to DONE
    local handlers -- dispatch table; value created later

    -- lexeme category constants
    local ID = 1
    local KEY = 2
    local OP = 3
    local NUMLIT = 4
    local STRINGLIT = 5
    local PUNCT = 6
    local MALFORMED = 7

    -- state constants
    local START = 1
    local LETTER = 2
    local DIGIT = 3
    local DIGDOT = 4
    local PLUS = 5
    local MINUS = 6
    local DOT = 7
    local EXCLAMATION = 8
    local LESSTHAN = 9
    local GREATERTHAN = 10
    local SCINOT = 11 -- scientific notation
    local SINGLEQUOTE = 12
    local DOUBLEQUOTE = 13
    local EQUAL = 14
    local SCINOTSIGN = 15
    local SCINOTDIG = 16
    local DONE = 0

    -- return current character at index pos in prog
    -- return single-character string
    -- or empty string if pos is past the end
    local function currChar()
        return prog:sub(pos, pos)
    end

    -- return next character at index pos+1 in prog
    -- returns single-character string
    -- or empty string if pos+1 is past the end
    local function nextChar()
        return prog:sub(pos+1, pos+1)
    end

    -- not sure if i'm allowed to look two ahead, but it seems like i have to 
    local function nextNextChar()
        return prog:sub(pos+2, pos+2)
    end

    -- move pos to the next character
    local function drop1()
        pos = pos+1
    end

    -- add current character to lexeme, move pos to next character
    local function add1()
        lexstr = lexstr .. currChar()
        drop1()
    end

    -- skip whitespace and comments, move pos to beginning of next lexeme
    -- or to prog:len()+1
    local function skipSpace()
        while true do
            while isSpace(currChar()) do
                drop1()
            end
            -- for some reason, the code below doesn't work if formatted like the old lexer.lua code...
            if currChar() == "/" and nextChar() == "*" then -- comments begin with `/*`
                drop1() -- skip the `/`
            	drop1() -- skip the `*`
            	while true do
                	if currChar() == "*" and nextChar() == "/" then
                    	drop1()
                    	drop1()
                    	break
                	elseif currChar() == "" then -- end of input
                    	return
                	else
                    	drop1()
                	end
            	end
            else
            	break
            end
        end
    end

    -- state handlers
    local function handle_START()
        if isLetter(ch) then
            add1()
            state = LETTER
        elseif ch == "_" then
            add1()
            state = LETTER
        elseif isDigit(ch) then
            add1()
            state = DIGIT
        elseif ch == "+" then
            add1()
            state = PLUS
        elseif ch == "-" then
            add1()
            state = MINUS
        elseif ch == "." then
            add1()
            state = DOT
        elseif ch == "*" then
            add1()
            state = DONE
            category = OP
        elseif ch == "!" then
            add1()
            state = EXCLAMATION
        elseif ch == "<" then
            add1()
            state = LESSTHAN
        elseif ch == ">" then
            add1()
            state = GREATERTHAN
        elseif ch == "=" then
            add1()
            state = EQUAL
         elseif ch == "/" then
            add1()
            state = DONE
            category = OP
        elseif ch == "'" then
        	add1()
        	state = SINGLEQUOTE
        elseif ch == '"' then
        	add1()
        	state = DOUBLEQUOTE
        elseif ch < " " or ch > "~" then -- anything outside of regular ascii range
            add1()
            state = DONE
            category = MALFORMED
        else
            add1()
            state = DONE
            category = PUNCT
        end
    end

    local function handle_LETTER()
        if isLetter(ch) then
            add1()
        elseif ch == "_" then
            add1()
        elseif isDigit(ch) then
            add1()
        else
            state = DONE
            category = ID
            if  lexstr == "set" or
                lexstr == "if" or
                lexstr == "printnum" or
                lexstr == "printstr" or
                lexstr == "printnl" then
                category = KEY
            end
        end
    end

    local function handle_DIGIT()
        if isDigit(ch) then
            add1()
        elseif ch == "." then
            add1()
            state = DIGDOT
        elseif ch == "e" or ch == "E" then
            state = SCINOT -- it's important to not add1() because we don't know if the scientific notation is valid yet
            -- we'll have to look ahead from SCINOT
        else
            state = DONE
            category = NUMLIT
        end
    end

    local function handle_DIGDOT()
        if isDigit(ch) then
            add1()
        elseif ch == "e" or ch == "E" then
            state = SCINOT -- it's important to not add1() because we don't know if the scientific notation is valid yet
            -- we'll have to look ahead from SCINOT
        else
            state = DONE
            category = NUMLIT
        end
    end

    local function handle_PLUS()
    	if preferOp then
    		state = DONE
    		category = OP
    		preferOp = false
        elseif isDigit(ch) then
            add1()
            state = DIGIT
        elseif ch == '.' then
            if isDigit(nextChar()) then
                add1()
                state = DIGDOT
            else
                state = DONE
                category = OP
            end
        else
            state = DONE
            category = OP
        end
    end

    local function handle_MINUS()
    	if preferOp then
    		state = DONE
    		category = OP
    		preferOp = false
        elseif isDigit(ch) then
            add1()
            state = DIGIT
        elseif ch == '.' then
            if isDigit(nextChar()) then
                add1()
                state = DIGDOT
            else
                state = DONE
                category = OP
            end
        else
            state = DONE
            category = OP
        end
    end

    local function handle_DOT()
        if isDigit(ch) then
            add1()
            state = DIGDOT
        else
            state = DONE
            category = PUNCT
        end
    end

    local function handle_EXCLAMATION()
    	if ch == '=' then
    		add1()
    		state = DONE
    		category = OP
    	else
    		state = DONE
    		category = PUNCT
    	end
    end

    local function handle_LESSTHAN()
        if ch == '=' then
    		add1()
    		state = DONE
    		category = OP
    	else
    		state = DONE
    		category = OP
    	end
    end

    local function handle_GREATERTHAN()
        if ch == '=' then
    		add1()
    		state = DONE
    		category = OP
    	else
    		state = DONE
    		category = OP
    	end
    end

    local function handle_SCINOT()
        if nextChar() == "+" or nextChar() == "-" then -- ch is still the e, so we have to look at the next one
        	state = SCINOTSIGN
        elseif isDigit(nextChar()) then
        	add1() -- add the e
    		add1() -- add the digit
    		state = SCINOTDIG
    	else -- otherwise the e is not part of lexeme and is an ID
    		state = DONE
    		category = NUMLIT
    	end
    end

    local function handle_SCINOTSIGN()
        if isDigit(nextNextChar()) then
            add1() -- add the e
            add1() -- add the sign
            add1() -- add the digit
            state = SCINOTDIG
        else
            state = DONE
            category = NUMLIT
        end
    end

    local function handle_SCINOTDIG()
        if isDigit(ch) then
            add1() -- add the new digit
        else
            state = DONE
            category = NUMLIT
        end
    end

    local function handle_SINGLEQUOTE()
        if ch == "" then
        	state = DONE
        	category = MALFORMED
        elseif ch ~= "'" then
        	add1()
        else
        	add1() -- add end quote
        	state = DONE
        	category = STRINGLIT
        end
    end

    local function handle_DOUBLEQUOTE()
        if ch == "" then
        	state = DONE
        	category = MALFORMED
        elseif ch ~= '"' then
        	add1()
        else
        	add1() -- add end quote
        	state = DONE
        	category = STRINGLIT
        end
    end

    local function handle_EQUAL()
        if ch == '=' then
    		add1()
    		state = DONE
    		category = OP
    	else
    		state = DONE
    		category = OP
    	end
    end

    local function handle_DONE()
        print("ERROR: 'DONE' state should not be handled")
        assert(0)
    end

    -- table of state handler functions, indices are from constants defined earlier
    handlers =
    {
        [START]=handle_START,
        [LETTER]=handle_LETTER,
        [DIGIT]=handle_DIGIT,
        [DIGDOT]=handle_DIGDOT,
        [PLUS]=handle_PLUS,
        [MINUS]=handle_MINUS,
        [DOT]=handle_DOT,
        [EXCLAMATION]=handle_EXCLAMATION,
        [LESSTHAN]=handle_LESSTHAN,
        [GREATERTHAN]=handle_GREATERTHAN,
        [SCINOT]=handle_SCINOT,
        [SINGLEQUOTE]=handle_SINGLEQUOTE,
        [DOUBLEQUOTE]=handle_DOUBLEQUOTE,
        [EQUAL]=handle_EQUAL,
        [SCINOTSIGN]=handle_SCINOTSIGN,
        [SCINOTDIG]=handle_SCINOTDIG,
        [DONE]=handle_DONE
    }

    -- called each time through the for-in loop
    -- returns a pair of lexeme (string) and category (int)
    -- or nil, nil if no more lexemes
    local function getLexeme(d1, d2) -- TODO: what do d1 and d2 do?
        if pos > prog:len() then
            preferOp = false -- make sure preferOp is back to false after we have the lexeme
            return nil, nil
        end
        lexstr = ""
        state = START
        while state ~= DONE do
            ch = currChar()
            handlers[state]()
        end

        skipSpace()
        preferOp = false -- make sure preferOp is back to false after we have the lexeme
        return lexstr, category
    end

    -- initialize and return the iterator function
    pos = 1
    skipSpace()
    return getLexeme, nil, nil -- TODO: why do we need the two nils?
end

return lexit -- return lexit module


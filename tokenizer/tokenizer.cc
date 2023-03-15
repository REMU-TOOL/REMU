#include "tokenizer.h"

#include <cctype>

using namespace REMU;

std::vector<std::string> Tokenizer::tokenize(const std::string &cmd)
{
    std::vector<std::string> tokens;
    std::string cur_tok;
    bool prev_backslash = false;
    char quote = 0;

    for (char c : cmd) {
        // Append the character as is if the previous one is a backslash
        if (prev_backslash) {
            cur_tok += c;
            prev_backslash = false;
            continue;
        }

        // Handle special characters (backslashes, quotes)
        switch (c) {
            case '\\':
                prev_backslash = true;
                continue;
            case '"':
            case '\'':
                if (quote == c) {
                    quote = 0;
                    continue;
                }
                else if (quote == 0) {
                    quote = c;
                    continue;
                }
                break;
        }

        // Append the character as is if we're in quotes
        if (quote) {
            cur_tok += c;
            continue;
        }

        // Handle whitespaces
        if (isspace(c)) {
            if (!cur_tok.empty()) {
                tokens.push_back(cur_tok);
                cur_tok = "";
            }
            continue;
        }

        // Append the character
        cur_tok += c;
    }

    // TODO: check prev_backslash & quote

    if (!cur_tok.empty())
        tokens.push_back(cur_tok);

    return tokens;
}

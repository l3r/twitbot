#pragma once

#include <eosiolib/eos.hpp>
#include <eosiolib/db.hpp>
#include <eosiolib/native_currency.hpp>
#include <eosiolib/table.hpp>

using namespace eosio;

namespace twitbot {

class contract {
     static const uint64_t code = N(twitbot);

public:
    /**
         *  @abi table
         */
    struct account {
        name twitter_account;
        uint64_t balance;

        EOSLIB_SERIALIZE(account, (twitter_account)(balance))
    };

    using accounts = table<
        code, // scope
        code, // code
        N(account), // table
        account, // record struct
        name // primary key
    >;

    using transfer = native_currency::transfer;

    ACTION(code, tip) {
        name from_twitter;
        name to_twitter;
        uint64_t quantity;

        EOSLIB_SERIALIZE(tip, (from_twitter)(to_twitter)(quantity));
    };

    ACTION(code, withdraw) {
        account_name to_eos;
        string from_twitter;

        EOSLIB_SERIALIZE(withdraw, (to_eos)(from_twitter));
    };

    static void on(const transfer &transfer);
    static void on(const tip &tip);
    static void on(const withdraw &withdraw);

private:
    static uint64_t string_to_name( const char* str );
};

} // namespace

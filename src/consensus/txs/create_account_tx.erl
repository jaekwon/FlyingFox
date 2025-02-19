-module(create_account_tx).
-export([doit/7, create_account/3]).
-record(ca, {from = 0, nonce = 0, pub = <<"">>, amount = 0, fee = 0}).

create_account(Pub, Amount, Fee) ->
    Id = keys:id(),
    Acc = block_tree:account(Id),
    Tx = #ca{from = Id, nonce = accounts:nonce(Acc) + 1, pub = Pub, amount = Amount, fee = Fee},
    tx_pool:absorb(keys:sign(Tx)).
next_top(DBroot, Accounts) -> 
    Array = accounts:array(),
    next_top_helper(Array, accounts:top(), DBroot, Accounts).
next_top_helper(Array, Top, DBroot, Accounts) when Top > size(Array) -> next_top_helper( <<Array/bitstring, <<0>>/binary>>, Top, DBroot, Accounts);
next_top_helper(Array, Top, DBroot, Accounts) ->
    EmptyAcc = accounts:empty(),
    case block_tree:account(Top, DBroot, Accounts) of
	EmptyAcc -> Top;
	_ ->
	    <<A:Top,_:1,B/bitstring>> = Array,
	    NewArray = <<A:Top,1:1,B/bitstring>>,
	    NewTop = accounts:walk(Top, NewArray),
	    next_top_helper(NewArray, NewTop, DBroot, Accounts)
    end.
    
doit(Tx, ParentKey, Channels, Accounts, TotalCoins, NS, NewHeight) ->
    F = block_tree:account(Tx#ca.from, ParentKey, Accounts),
    NewId = next_top(ParentKey, Accounts),
    true = NewId < constants:max_address(),
    NT = accounts:update(accounts:empty(Tx#ca.pub), NewHeight, Tx#ca.amount, 0, 0, TotalCoins),
    NF = accounts:update(F, NewHeight, (-Tx#ca.amount - constants:create_account_fee() - Tx#ca.fee), 0, 1, TotalCoins),
    Nonce = accounts:nonce(NF),
    Nonce = Tx#ca.nonce,
    Accounts2 = dict:store(NewId, NT, Accounts),
    Accounts3 = dict:store(Tx#ca.from, NF, Accounts2),
    MyId = keys:id(),
    MyPub = keys:pubkey(),
    if
	((Tx#ca.pub == MyPub) and (MyId == -1)) -> keys:update_id(NewId);
	true -> 1 = 1
    end,
    {Channels, Accounts3, TotalCoins - constants:create_account_fee(), NS}.


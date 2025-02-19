-module(channel_funds_limit_tx).
-export([doit/7, losses/3, make_tx/2]).
%add another type of transaction for closing channels. This one should allow you to instantly close the channel, and take all the money, but only if your partner is very low on funds, and will soon lose his account.
-record(channel_funds_limit, {acc = 0, nonce = 0, id = 0, fee = 0}).
make_tx(ChannelId, Fee) ->
    Id = keys:id(),
    Acc = block_tree:account(Id),
    Nonce = accounts:nonce(Acc),
    %Channel = block_tree:channel(ChannelId),
    %CAC1 = channels:acc1(Channel),
    %CAC2 = channels:acc2(Channel),
    %if
    %(CAC1 == Id) -> Part = CAC2;
    %(CAC2 == Id) -> Part = CAC1
    %end,
    %Partner = block_tree:account(Part),
    %true = low_balance(Partner, block_tree:total_coins(), block_tree:height()),
    tx_pool:absorb(keys:sign(#channel_funds_limit{acc = Id, nonce = Nonce + 1, id = ChannelId, fee = Fee})).
losses(Txs, Channels, ParentKey) -> losses(Txs, Channels, ParentKey, 0).
losses([], _, _, X) -> X;
losses([SignedTx|Txs], Channels, ParentKey, X) -> 
    Tx = sign:data(SignedTx),
    if
	is_record(Tx, channel_funds_limit) ->
	    ID = Tx#channel_funds_limit.id,
	    Channel = block_tree:channel(ID, ParentKey, Channels),
	    B = channels:bal1(Channel) + channels:bal2(Channel),
	    losses(Txs, Channels, ParentKey, X + B);
	true -> losses(Txs, Channels, ParentKey, X)
    end.
low_balance(Acc, TotalCoins, NewHeight) -> 
    UCost = accounts:unit_cost(Acc, TotalCoins),
    MinBalance = UCost * constants:max_reveal(),
    Gap = NewHeight - accounts:height(Acc),
    Cost = UCost * Gap,
    NewBalance = accounts:balance(Acc) - Cost,
    MinBalance > NewBalance.

doit(Tx, ParentKey, Channels, Accounts, TotalCoins, S, NewHeight) ->
    A = Tx#channel_funds_limit.acc,
    ID = Tx#channel_funds_limit.id,
    Channel = block_tree:channel(ID, ParentKey, Channels),
    B = channels:bal1(Channel) + channels:bal2(Channel),
    Acc = block_tree:account(A, ParentKey, Accounts),
    Type = channels:type(Channel),
    CAC1 = channels:acc1(Channel),
    CAC2 = channels:acc2(Channel),
    if
	(CAC1 == A) -> Part = CAC2;
	(CAC2 == A) -> Part = CAC1
    end,
    Partner = block_tree:account(Part, ParentKey, Accounts),
    true = low_balance(Partner, TotalCoins, NewHeight),
    if
	(Type == <<"delegated_1">>) and (CAC1 == A) ->
	    D2 = 0,
	    D = B;
	(Type == <<"delegated_1">>) and (CAC2 == A) ->
	    D2 = B,
	    D = 0;
	(Type == <<"delegated_2">>) and (CAC1 == A) ->
	    D2 = B,
	    D = 0;
	(Type == <<"delegated_2">>) and (CAC2 == A) ->
	    D2 = 0,
	    D = B;
	true -> 
	    D = 0, D2 = 0
    end,
    N = accounts:update(Acc, NewHeight, B - Tx#channel_funds_limit.fee, -D, 1, TotalCoins),
    N2 = accounts:update(Partner, NewHeight, 0, -D2, 0, TotalCoins, nocheck),
    Accounts1 = dict:store(Part, N2, Accounts),
    NewAccounts = dict:store(A, N, Accounts1),
    Nonce = accounts:nonce(N),
    Nonce = Tx#channel_funds_limit.nonce,
    NewChannels = dict:store(ID, channels:empty(), Channels),
    {NewChannels, NewAccounts, TotalCoins, S}.

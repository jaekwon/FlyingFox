-module(create_channel_tx).
-export([doit/4]).
-record(cc, {acc1 = 0, nonce = 0, acc2 = 1, delay = 10, bal1 = 0, bal2 = 0, consensus_flag = false, id = 0, fee = 0}).%id is used to decide how deep on the hard-drive to store it.
-record(channel, {height = 0, creator = 0, nonce = 0}).
-record(acc, {balance = 0, nonce = 0, pub = ""}).
doit(Tx, ParentKey, Channels, Accounts) ->
    From = Tx#cc.acc1,
    false = From == Tx#cc.acc2,
    Acc1 = block_tree:account(Tx#cc.acc1, ParentKey, Accounts),
    EmptyChannel = block_tree:channel(Tx#cc.id, ParentKey, Channels),
    EmptyChannel = #channel{},%You can only fill space in the database that are empty.
    if
	Tx#cc.id == 0 -> 1 = 1;
	true -> #channel{} = block_tree:channel(Tx#cc.id-1, ParentKey, Channels)%You can only fill a space if the space below you is already filled.
    end,
    true = Tx#cc.id < constants:max_channel(),
    N1 = #acc{balance = Acc1#acc.balance - Tx#cc.bal1 - Tx#cc.bal2 - Tx#cc.fee,
	      nonce = Acc1#acc.nonce + 1, 
	      pub = Acc1#acc.pub},
    true = N1#acc.balance > 0,
    Nonce = N1#acc.nonce,
    Nonce = Tx#cc.nonce,
    T = block_tree:read(top),
    Top = block_tree:height(T),
    Ch = #channel{height = Top, creator = Tx#cc.acc1, nonce = Tx#cc.nonce},
    NewAccounts = dict:store(Tx#cc.acc1, N1, Accounts),
    NewChannels = dict:store(Tx#cc.id, Ch, Channels),
    {NewChannels, NewAccounts}.

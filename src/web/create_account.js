create_account1();
function create_account1() {
    var create_pubkey = document.createElement("INPUT");
    create_pubkey.setAttribute("type", "text"); 
    var pubkey_info = document.createElement("h8");
    pubkey_info.innerHTML = "new account pubkey: ";
    document.body.appendChild(document.createElement("br"));
    document.body.appendChild(pubkey_info);
    document.body.appendChild(create_pubkey);
    
    var create_balance = document.createElement("INPUT");
    create_balance.setAttribute("type", "text"); 
    var balance_info = document.createElement("h8");
    balance_info.innerHTML = "new account balance: ";
    document.body.appendChild(balance_info);
    document.body.appendChild(create_balance);

    var spend_fee = document.createElement("INPUT");
    spend_fee.setAttribute("type", "text"); 
    var fee_info = document.createElement("h8");
    fee_info.innerHTML = "fee: ";
    document.body.appendChild(fee_info);
    document.body.appendChild(spend_fee);
    
    
    var create_button = document.createElement("BUTTON");
    create_button.id = "create_account_button";
    var button_text = document.createTextNode("create account");
    create_button.appendChild(button_text);
    create_button.onclick = function() {
	var to = create_pubkey.value;
	var amount = parseInt(create_balance.value, 10);
	var fee = parseInt(spend_fee.value, 10);
	local_get(["create_account", to, amount, fee]);
	local_get(["sync", [127,0,0,1], 3020]);
    };
    document.body.appendChild(create_button);
    
}

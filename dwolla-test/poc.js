var c = require('./config');
var dwolla = require('../node/lib/dwolla');

dwolla.balance(c.token, function(err, data) {
    if (err) { console.log(err); }
    console.log("Balance: $" + data);
});

dwolla.fullAccountInfo(c.token, function(err, data){
    console.log(data)
})

dwolla.transactions(c.token, {}, function(err, data){
    console.log(data);
})

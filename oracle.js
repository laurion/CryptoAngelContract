var soap = require('soap')
var OracleContract = require('./build/contracts/Crowdfunding.json')
var contract = require('truffle-contract')

var Web3 = require('web3');
var web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'));

var oracleContract = contract(OracleContract)
oracleContract.setProvider(web3.currentProvider)

if (typeof oracleContract.currentProvider.sendAsync !== "function") {
	oracleContract.currentProvider.sendAsync = function () {
		return oracleContract.currentProvider.send.apply(
			oracleContract.currentProvider, arguments
		);
	};
}

web3.eth.getAccounts((err, accounts) => {
	oracleContract.deployed()
		.then((oracleInstance) => {
			oracleInstance.CallbackGetRONtoUSD()
				.watch((err, event) => {
					var url = 'http://www.infovalutar.ro/curs.asmx?WSDL';
					soap.createClient(url, function (err, client) {
						var args = {
							"Moneda": "USD",
						};
						client.GetLatestValue(args, function (err, result) {
							console.log("---- data arrived ----")
							console.log("USDtoRON: ", parseFloat(result.GetLatestValueResult));
							console.log("---- data arrived ----")

							var USDtoRON = parseFloat(result.GetLatestValueResult);
							var RONtoUSD = 1 / USDtoRON

							console.log("---- data calculation ----")
							console.log("RONtoUSD:", RONtoUSD);
							console.log("---- data calculation ----")

							const btcMarketCap = parseInt(RONtoUSD * 1000) //random number solidity does not have floats
							oracleInstance.setRONToUSDRate(btcMarketCap, {from: accounts[0]})
						});
					});

				})
		})
		.catch((err) => {
			console.log(err)
		})
})

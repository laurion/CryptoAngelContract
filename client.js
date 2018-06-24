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
			const oraclePromises = [
				oracleInstance.getRonToUSDRate(),  // Get currently stored BTC Cap
				oracleInstance.updateRONtoUSD({from: accounts[0]})  // Request oracle to update the information
			]

			Promise.all(oraclePromises)
				.then((result) => {
					console.log('Conversion Rate: ' + result[0])
					console.log('Requesting Oracle to update RON TO USD Information...')
				})
				.catch((err) => {
					console.log(err)
				})
		})
		.catch((err) => {
			console.log(err)
		})
})

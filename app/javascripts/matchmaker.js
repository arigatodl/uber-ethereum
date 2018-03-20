// Import libraries we need.
import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract'

// Import our contract artifacts and turn them into usable abstractions.
import token_artifacts from '../../build/contracts/EIP20.json'
import registry_artifacts from '../../build/contracts/Registry.json'
import matchmaker_artifacts from '../../build/contracts/MatchMaker.json'

var Token = contract(token_artifacts);
var Registry = contract(registry_artifacts);
var MatchMaker = contract(matchmaker_artifacts);

var accounts;
var account;
window.App = {
  start: function() {
    var self = this;
    Token.setProvider(web3.currentProvider);
    Registry.setProvider(web3.currentProvider);
    MatchMaker.setProvider(web3.currentProvider);
    // Get the initial account balance so it can be displayed.
    web3.eth.getAccounts(function(err, accs) {
      if (err != null) {
        alert("There was an error fetching your accounts.");
        return;
      }
      if (accs.length == 0) {
        alert("Couldn't get any accounts! Make sure your Ethereum client is configured correctly.");
        return;
      }
      accounts = accs;
      account = accounts[0];
    });
  },
  setStatus: function(message) {
    var status = document.getElementById("status");
    status.innerHTML = message;
  },
  getListings: async function() {
      var self = this;

      var matchmaker = await MatchMaker.deployed();
      var listingSize = await matchmaker.getListingCount();
      this.setStatus("Current listings size: " + listingSize.toNumber());
  },
  completeTrip: async function() {
      var self = this;

      var id = parseInt(document.getElementById("endId").value);
      var km = parseInt(document.getElementById("endKM").value)
      var matchmaker = await MatchMaker.deployed();

      var price = MatchMaker.listings[id].farePerKM;
      await matchmaker.completeTrip(id, km);
  },
  startTrip: async function() {
      var self = this;

      var id = parseInt(document.getElementById("startId").value);
      var km = parseInt(document.getElementById("startKM").value)
      var matchmaker = await MatchMaker.deployed();
      var token = await Token.deployed();

      var price = matchmaker.listings[id].farePerKM;
      await token.approve(matchmaker.address, price);
      await matchmaker.startTrip(id, km, "test");
  }
};
window.addEventListener('load', function() {
  // Checking if Web3 has been injected by the browser (Mist/MetaMask)
  if (typeof web3 !== 'undefined') {
    console.warn("Using web3 detected from external source. If you find that your accounts don't appear, ensure you've configured that source properly. If using MetaMask, see the following link. Feel free to delete this warning. :) http://truffleframework.com/tutorials/truffle-and-metamask")
    // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider);
  } else {
    console.warn("No web3 detected. Falling back to http://localhost:8545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask");
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
  }
  App.start();
  App.getListings();
});

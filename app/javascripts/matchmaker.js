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
    Regulator.setProvider(web3.currentProvider);
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
  setAddress: function() {
      var self = this;
      var tollbooth = document.getElementById("tollbooth").value;
      this.setStatus("Setting tollBoothOperator contract address... (please wait)");
      TollBoothOperator = TollBoothOperator.at(tollbooth);
      TollBoothOperator.setProvider(web3.currentProvider);
      Regulator.deployed()
        .then(regulator => {
            return regulator.isOperator.call(TollBoothOperator);
        })
        .then(success => {
            self.setStatus("Setting tollBoothOperator contract address success");
        })
        .catch(e => {
            console.log(e);
            self.setStatus("Setting tollBoothOperator contract address failed; see log.");
        });
  },
  addTollBooth: function() {
      var self = this;
      var tollbooth = document.getElementById("tollbooth").value;
      this.setStatus("Adding tollbooth... (please wait)");
      TollBoothOperator.deployed()
        .then(tollBoothOpertor => {
            return tollBoothOpertor.addTollBooth.call(tollbooth);
        })
        .then(success => {
            self.setStatus("Tollbooth has been added successfully");
        })
        .catch(e => {
            console.log(e);
            self.setStatus("Error adding tollbooth; see log.");
        });
  },
  setRoutePrice: function() {
      var self = this;
      var entryBooth = document.getElementById("entryBooth").value;
      var exitBooth = document.getElementById("exitBooth").value;
      var price = parseInt(document.getElementById("price").value);
      this.setStatus("Setting route price... (please wait)");
      TollBoothOperator.deployed()
        .then(tollBoothOpertor => {
            return tollBoothOpertor.setRoutePrice.call(entryBooth, exitBooth, price);
        })
        .then(success => {
            self.setStatus("Route price has been set successfully!");
        })
        .catch(e => {
            console.log(e);
            self.setStatus("Error setting route price; see log.");
        });
  },
  setMultiplier: function() {
      var self = this;
      var type = parseInt(document.getElementById("type").value);
      var multiplier = parseInt(document.getElementById("multiplier").value);
      this.setStatus("Setting multiplier... (please wait)");
      TollBoothOperator.deployed()
        .then(tollBoothOpertor => {
            return tollBoothOpertor.setMultiplier.call(type, multiplier);
        })
        .then(success => {
            self.setStatus("Multiplier has been set successfully!");
        })
        .catch(e => {
            console.log(e);
            self.setStatus("Error setting multiplier; see log.");
        });
  }
};
window.addEventListener('load', function() {
  // Checking if Web3 has been injected by the browser (Mist/MetaMask)
  if (typeof web3 !== 'undefined') {
    console.warn("Using web3 detected from external source. If you find that your accounts don't appear or you have 0 MetaCoin, ensure you've configured that source properly. If using MetaMask, see the following link. Feel free to delete this warning. :) http://truffleframework.com/tutorials/truffle-and-metamask")
    // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider);
  } else {
    console.warn("No web3 detected. Falling back to http://localhost:8545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask");
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
  }
  App.start();
});

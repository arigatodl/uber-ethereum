# Uber Ethereum
[![Build Status](https://travis-ci.org/dulguunbatmunkh/uber-ethereum.svg?branch=master)](https://travis-ci.org/dulguunbatmunkh/uber-ethereum) 
[![Coverage Status](https://coveralls.io/repos/github/dulguunbatmunkh/uber-ethereum/badge.svg?branch=master)](https://coveralls.io/github/dulguunbatmunkh/uber-ethereum?branch=master)  

Decentralized uber-like system on ethereum  

## To run unit tests, clone this repository, and run:
```
$ npm install
$ npm test
```

## Defining the token properties
You'll need to modify a JSON file (`conf/config.json`):
```json
{
  "token": {
    "decimals": "5",
    "name": "DriverToken",
    "symbol": "DRT",
    "supply": "21000000"
  }
}
```

phantom-stats
=============

Use (PhantomJs) NetSniff.js to build a har file then build a summary according to [har-summary](https://github.com/furybyname/har-summary)

## Installation

`npm install phantom-stats`

or `npm install -g phantom-stats`

### Usage

`node_modules/.bin/phantom-stats http://www.somewebsite.com`

or `phantom-stats http://www.somewebsite.com`

### Usage as a module

```
require('phantom-stats').run('http://somewebsite.com', function(result) { console.log(result); });
```

# From source

## Installation

`git clone git@github.com:furybyname/phantom-stats.git`

`cd phantom-stats`

`npm install`

`grunt coffee`

### Usage

`node bin/phantom-stats http://somewebsite.com`
 

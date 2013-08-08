
/**
 * Module dependencies.
 */

var express = require('express')
  , routes = require('./routes')
  , http = require('http')
  , mongo = require('mongodb')
  , path = require('path')
  , fs = require("fs")
  , settings = require('./settings')
  , toobusy = require('toobusy').maxLag(100);

var config = settings.config;

console.log(config);

var app = exports.app = express();

// all environments
var toobusy = require('toobusy');

app.use(function(req, res, next) {
  if (toobusy()) {
      res.send(503, "I'm busy right now, sorry.");
  }else {
      next();
  }
});

app.set('port', config.server.port || 3000);
app.set('address', config.server.address || '0.0.0.0');
app.set('views', __dirname + '/views');
app.set('view engine', 'jade');
app.use(express.favicon());
app.use(express.logger('dev'));
app.use(express.bodyParser());
app.use(express.methodOverride());
app.use(app.router);
app.use(require('stylus').middleware(__dirname + '/public'));
app.use(express.static(path.join(__dirname, 'public')));

// development only
if (true == config.debug) {
    app.use(express.errorHandler());
}
 else
{
    app.use(function(err, req, res, next){
          console.error(err.stack);
          res.send(500, 'Something broke!');
        });
}

//display API readme
app.get('/', routes.index);
app.get('/dictionary', routes.dictionary);

//this is REST interface
require('./routes/rest');

http.createServer(app).listen(app.get('port'), app.get('address'), function(){
  console.log('Express server listening on ' + app.get('address') + ':' + app.get('port'));
});

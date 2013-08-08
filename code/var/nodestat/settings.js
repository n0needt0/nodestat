/*
 * this module keeps global settings
 */

var         fs = require("fs")
     , mongo = require('mongodb');

var  Server = mongo.Server,
             Db = mongo.Db,
         BSON = mongo.BSONPure;

//try to load config

try {
          config = JSON.parse(fs.readFileSync(process.cwd()+"/settings.json"));
      } catch(e) {
        // ignore
         console.log("Error: Can not parse config!");
         process.exit(1);
      }

exports.config = config;

var server = new Server(config.db.host, config.db.port, {auto_reconnect: true});
var db = new Db(config.db.dbname, server);

// Open your mongodb database and create collection if does not exists.
try{
    db.open(function (error, connection) {
            if (error) {
                console.log("Cannot connect to " +  JSON.stringify(config.db, null, 4) + " database : " + error);
            }
            
           connection.collection(config.db.collectionname, function (error, collection) {
               if (error) {
                   console.log("Cannot connect to " +  JSON.stringify(config.db, null, 4) + " collection: " + error);
               }
           });
         });
}catch(e){
    console.log(e);
}

//this is global connection
exports.db = db;
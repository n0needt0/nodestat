/*
 * generic add get data from lib
 */
var mongohost = 'localhost';
var mongoport = 27017;
var dbname = 'statsdb';
var collectionname = 'stats';

var mongo = require('mongodb');

var Server = mongo.Server,
      Db = mongo.Db,
      BSON = mongo.BSONPure;

var server = new Server(mongohost, mongoport, {auto_reconnect: true});
var db = new Db(dbname, server);

db.open(function(err,db) {
    if(!err){
        console.log ("Connected to '" + dbname + "' database");
        db.collection(collectionname, {strict:true}, function(err, collection){
            if(err){
                 console.log("The '"+collectionname+"' collection does not exists . Creating it...");
                 return;
            }
       });
   	}
});

//add data element



//delete data element

//get data query

//stitch data by date


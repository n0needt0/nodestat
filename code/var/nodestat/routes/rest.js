var check = require('validator').check,
    sanitize = require('validator').sanitize;
    
var settings = require(process.cwd()+"/settings");
var config = settings.config;
var db = settings.db;

var mongo = require("mongodb"),
    app = module.parent.exports.app,
    BSON = mongo.BSONPure,
    _ = require('underscore')._;

var debug = settings.debug;

/**
 * REST Methods
 */

/**
 *  Search
 */

app.get('/data', function(req, res, next){
    
    var query = req.query.query ? JSON.parse(req.query.query) : {};
    
    // Providing an id overwrites giving a query in the URL
    if (req.params.id) {
      query = {'_id': new BSON.ObjectID(req.params.id)};
    }
    
    var options = req.params.options || {};

    var test = ['limit','sort','fields','skip','hint','explain','snapshot','timeout'];

    for( o in req.query ) {
      if( test.indexOf(o) >= 0 ) {
        options[o] = req.query[o];
      } 
    }   
        
    debug('Searching query:' + query + " options: " + options);
    
    db.collection(config.db.collectionname, function(err, collection) {
        collection.find(query, options).toArray(function(err, items){
              res.header('Content-Type', 'application/json');
              res.send(items)
        });
   });
});

/**
 * Delete
 */
app.delete('/data/:id', function(req, res) {
    var id = req.params.id;
    debug('Deleting id: ' + id);
    db.collection(config.db.collectionname, function(err, collection) {
            collection.remove({'_id':new BSON.ObjectID(id)}, {safe:true}, function(err, result) {
                if (err) {
                    res.header('Content-Type', 'application/json');
                    res.send({'error':'An error has occurred - ' + err});
                } else {
                    debug('' + result + ' document(s) deleted');
                    res.header('Content-Type', 'application/json');
                    res.send(req.body);
                }
            });
        });
    });

/**
 * Update
 */
app.put('/data/:id', function(req, res) {
    var spec = {'_id': new BSON.ObjectID(req.params.id)};
  
    db.collection(config.db.collectionname, function(err, collection) {
        collection.update(spec, req.body, true, function(err, docs) {
            res.header('Content-Type', 'application/json');
            res.send('{"ok":1}');
        });
    });
});

/**
 * Insert/Update
 */
app.post('/data', function(req, res) {
    
    try{
            var item = req.body;
                
            /**check for required and limits
             * required{
             * bundle
             * metrics
             * location
             * datestamp
             * value
             */
            
            var required = ['bundle','metrics','location','datestamp','value'];
            
            var errcheck = [];
            
            _.each(required, function(v,k){
                if( !_.has(item, v) && item.v !== '' ) {
                    errcheck.push({'error': v + ' parameter required'});
                } 
            });
            
            if(!_.isEmpty(errcheck))
            {
                debug(JSON.stringify(errcheck));
                res.header('Content-Type', 'application/json');
                res.send(errcheck);
                return;
            }
            
            //makesure date stamp is valid
            var pattern=new RegExp("[1-2][0-9][0-9][0-9][0-1][0-9][0-3][0-9]");
            if(!pattern.test(item.datestamp)){
                errcheck.push({'error': ' datestamp parameter must be YYYYMMDD!'})
                debug(JSON.stringify(errcheck));
                res.header('Content-Type', 'application/json');
                res.send(errcheck);
                return;
            }
            
            //make sure locations are valid
            item.location = item.location.toLowerCase();
            
            if(!_.isEmpty(config.validator) && !_.isEmpty(config.validator.locations))
            {
                 if( _.indexOf(config.validator.locations, item.location) < 0 ) {
                     errcheck.push({'error': ' invalid location! valid locations: ' + config.validator.locations });
                     debug(JSON.stringify(errcheck));
                     res.header('Content-Type', 'application/json');
                     res.send(errcheck);
                     return;
                 } 
            }
            
            debug('Adding item: ' + JSON.stringify(item));
            
            db.collection(config.db.collectionname, function(err, collection) {
                
                var key = {'bundle':item.bundle,'metrics':item.metrics,'location':item.location,'datestamp':item.datestamp}
                
                collection.update(key, item, {upsert:true, safe:false }, function(err, result) {
                    if (err) {
                        debug(err);
                        res.header('Content-Type', 'application/json');
                        res.send('{"ok":0}');
                    } else {
                        debug('Success!');
                        res.header('Content-Type', 'application/json');
                        res.send('{"ok":1}');
                    }
                });
            });
    }catch(e){
        debug(e);
    }
});
var  request = require('request')
     , nodeunit = require('nodeunit')
     , s = require('string');

var validdata ={
        "location": "fresno",
        "metrics": "program",
        "bundle":"operations",
        "datestamp":"20010101",
        "value":22,
        "details":{"some":"data"}
    };

exports['api'] = nodeunit.testCase({
    
    
    'insert valid data' : function(test){
        test.expect(1);
        
        request({
                         uri: "http://localhost:3000/data",
                 method: "POST",
                      form: validdata
                   },
                   function(error, response, body) {
                       test.equal(body, '{"ok":1}');
                       test.done();
                  });
        
  
       
    },
        
        'get valid data' : function(test){
            test.expect(1);
            var searchdata = JSON.parse(JSON.stringify(validdata));
            delete searchdata.value;
            delete searchdata.details;
            
            console.log("http://localhost:3000/data?query=" + JSON.stringify(searchdata));
            
            request({
                             uri: "http://localhost:3000/data?query=" + JSON.stringify(searchdata),
                     method: "GET"
                       },
                       function(error, response, body) {
                           res = JSON.parse(body)[0];
                           delete res._id
                           delete res.value
                           delete res.details
                           test.equal(JSON.stringify(res), JSON.stringify(searchdata));
                           test.done();
                      });
            
      
           
        },

    
    'insert missing location': function(test){
        test.expect(1);
        
        var invaliddata = JSON.parse(JSON.stringify(validdata));
        delete invaliddata.location;
        
        request({
                    uri: "http://localhost:3000/data",
             method: "POST",
                 form: invaliddata
                },
                    function(error, response, body) {
                       res = JSON.parse(body);
                       test.equal(res[0]['error'], 'location parameter required');
                       test.done();
                   });
    },
    

    'insert bad location': function(test){
        test.expect(1);
        
        var invaliddata = JSON.parse(JSON.stringify(validdata));
        invaliddata.location = 'invalid location';
        
        request({
                    uri: "http://localhost:3000/data",
             method: "POST",
                 form: invaliddata
                },
                    function(error, response, body) {
                       res = JSON.parse(body);
                       test.equal( s(res[0]['error']).trim().s, 'invalid location! valid locations: san mateo,salinas,fresno,total');
                       test.done();
                   });
    },
    
    'insert missing bundle': function(test){
        test.expect(1);
        
        var invaliddata = JSON.parse(JSON.stringify(validdata));
        delete invaliddata.bundle;
        
        request({
                    uri: "http://localhost:3000/data",
             method: "POST",
                 form: invaliddata
                },
                    function(error, response, body) {
                       res = JSON.parse(body);
                       test.equal(res[0]['error'], 'bundle parameter required');
                       test.done();
                   });
    },
    
    'insert missing metrics': function(test){
        test.expect(1);
        
        var invaliddata = JSON.parse(JSON.stringify(validdata));
        delete invaliddata.metrics;
        
        request({
                    uri: "http://localhost:3000/data",
             method: "POST",
                 form: invaliddata
                },
                    function(error, response, body) {
                       res = JSON.parse(body);
                       test.equal(res[0]['error'], 'metrics parameter required');
                       test.done();
                   });
    },
    
    'insert missing value': function(test){
        test.expect(1);
        
        var invaliddata = JSON.parse(JSON.stringify(validdata));
        delete invaliddata.value;
        
        request({
                    uri: "http://localhost:3000/data",
             method: "POST",
                 form: invaliddata
                },
                    function(error, response, body) {
                       res = JSON.parse(body);
                       test.equal(res[0]['error'], 'value parameter required');
                       test.done();
                   });
    },
    
    'insert missing datestamp': function(test){
        test.expect(1);
        
        var invaliddata = JSON.parse(JSON.stringify(validdata));
        delete invaliddata.datestamp;
        
        request({
                    uri: "http://localhost:3000/data",
             method: "POST",
                 form: invaliddata
                },
                    function(error, response, body) {
                       res = JSON.parse(body);
                       test.equal(res[0]['error'], 'datestamp parameter required');
                       test.done();
                   });
    },
    'insert invalid date': function(test){
        test.expect(1);
        
        var invaliddata = JSON.parse(JSON.stringify(validdata));
        invaliddata.datestamp = '20131344';
        
        request({
                    uri: "http://localhost:3000/data",
             method: "POST",
                 form: invaliddata
                },
                    function(error, response, body) {
                       res = JSON.parse(body);
                       test.equal(res[0]['error'], 'datestamp parameter must be YYYYMMDD!');
                       test.done();
                   });
    },
});
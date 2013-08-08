/*
 * GET home page.
 */

var settings = require(process.cwd()+"/settings");
var config = settings.config;

exports.index = function(req, res){

    var content = {title: 'Nodestat API'}

    if(true == config.debug) {
        content.configuration = JSON.stringify(config, null, 4) 
    }
    
    res.render('index', content);
};

exports.dictionary = function(req, res){

    var content = {title: 'Nodestat Metrix'}

    if(true == config.debug) {
        content.configuration = JSON.stringify(config, null, 4) 
    }
    
    res.render('dictionary1', content);
 };
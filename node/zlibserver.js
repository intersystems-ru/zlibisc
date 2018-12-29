//zlibserver.js
const express = require('express');
const zlib = require('zlib');
 
var app = express();
 
 app.get('/zlibapi/:text', function(req, res) {
    res.type('application/json');
    
    var text=req.params.text;
    
    try {        
		zlib.deflate(text, (err, buffer) => {
		   if (!err) {
				res.status(200).send(buffer.toString('binary'));
			} else {
				res.status(500).json( { "error" : err.message});
			// handle error
			}
		});
     }
    catch(err) {
      res.status(500).json({ "error" : err.message});
      return;
    }
    
});
app.listen(3000, function(){
    console.log("zlibserver is ready captain.");
});
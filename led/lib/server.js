// server.js
const express = require('express');
const cors = require('cors');
const app = express();
app.use(cors());
app.use(express.json());

let leds = { red: false, yellow: false, green: false };
let alarmOn = false;
app.get('/status', (req, res) => {
    res.json({ leds, alarmOn });
  });
  
  app.post('/led/:color', (req, res) => {
    const color = req.params.color;
    const { state } = req.body; // Récupère l'état de la LED
    if (leds[color] !== undefined) {
      leds[color] = state; // Change l'état de la LED selon la valeur de "state"
      console.log(`LED ${color.toUpperCase()} is now ${leds[color] ? 'ON' : 'OFF'}`);
      res.sendStatus(200);
    } else {
      res.status(400).send('Invalid LED color');
    }
  });
  

  app.post('/alarm', (req, res) => {
    const { state } = req.body;
    alarmOn = state;
    console.log(`Alarm is now ${alarmOn ? 'ON' : 'OFF'}`);
    // Renvoi de l'état actuel de l'alarme dans la réponse
    //res.status(200).json({ alarm: alarmOn }); // Send back the updated alarm state
    res.sendStatus(200);

    
  });
  

app.listen(4000, () => {
  console.log('API running on http://localhost:4000');
});

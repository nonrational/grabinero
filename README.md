Ruby API
--------
https://github.com/Dwolla/dwolla-ruby

NodeJS API
---------
https://github.com/nanek/node-dwolla

Heroku Push to Production
-------------------------
We will use Heroku to get the website out to production. To do so, all you need to do is

git push heroku master

which will push all of your changes to the Heroku cloud. This will then get deployed automatically to 

centsyrup.herokuapp.com

Sinatra Web Framework
---------------------
I use the Sinatra Web Framework for fast hackathon development. You can start the webapp by simply running

./run.sh

This will start a new instance on your localhost:4567

The great thing about this is that when you make any changes to views or the back-end, the webapp will automatically restart. 
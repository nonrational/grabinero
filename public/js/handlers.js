Template.tmp.index_route = function () {
  if (Session.get("currentPage") == "main" && !Meteor.user()) {
    return true;
  }
}

Template.tmp.profile_route = function () {
  if (Meteor.user() && Session.get("currentPage") != "interviewee" 
  	&& Session.get("currentPage") != "interviewer") {
    return true;
  }
}

Template.tmp.interviewee_route = function() {
	if (Meteor.user() && Session.get("currentPage") == "interviewee") {
		return true;
	}
}

Template.tokBox.run_tokBox = function() {
	// Initialize API key, session, and token...
	// Think of a session as a room, and a token as the key to get in to the room
	// Sessions and tokens are generated on your server and passed down to the client
	var apiKey = "22601652";
	var sessionId = "1_MX4yMjYwMTY1Mn4xMjcuMC4wLjF-U3VuIEphbiAyMCAwMDoyODo1NSBQU1QgMjAxM34wLjI0ODI3NDQ1fg";
	var token = "T1==cGFydG5lcl9pZD0yMjYwMTY1MiZzaWc9YmFiOGM0MzYxMDRhODQ3M2ZlYzNmMWE2ZDIwYTUzMTliOWI3ODQ1MzpzZXNzaW9uX2lkPTFfTVg0eU1qWXdNVFkxTW40eE1qY3VNQzR3TGpGLVUzVnVJRXBoYmlBeU1DQXdNRG95T0RvMU5TQlFVMVFnTWpBeE0zNHdMakkwT0RJM05EUTFmZyZjcmVhdGVfdGltZT0xMzU4NjcwNTQzJmV4cGlyZV90aW1lPTEzNTg3NTY5NDMmcm9sZT1wdWJsaXNoZXImbm9uY2U9ODg4ODU3JnNka192ZXJzaW9uPXRiLWRhc2hib2FyZC1qYXZhc2NyaXB0LXYx";

	// Initialize session, set up event listeners, and connect
	var session = TB.initSession(sessionId);
	session.addEventListener('sessionConnected', sessionConnectedHandler);
	session.connect(apiKey, token);
	
	function sessionConnectedHandler(event) {
	    var publisher = TB.initPublisher(apiKey, 'myPublisherDiv');
	    session.publish(publisher);
	}
}

Template.profile._name = function() {
	console.log("hi");
	return Meteor.user().username;
}
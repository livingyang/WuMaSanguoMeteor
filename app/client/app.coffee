Template.hello.greeting = ->
	"Welcome to app."

Template.hello.events "click input": ->
	console.log "You pressed the button"

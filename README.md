# chat-on-rails
Chat app implemented following tutorial video on hotwired.dev

## Development steps
Build Rails app with Hotwire Rails Integration -- full setup for turbo and stimulus

## 0. Installs 

<!-- 
nao funcinou:
#### rvm
From https://rvm.io:
```bash
gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
\curl -sSL https://get.rvm.io | bash -s stable
sudo usermod -a -G rvm $USER
echo 'source "/etc/profile.d/rvm.sh"' >> ~/.bashrc

```
#### ruby

```bash
rvm pkg install openssl
rvm install ruby -C --with-openssl-dir=$HOME/.rvm/usr
``` -->

```bash
sudo apt-get install ruby-full
ruby -v
gem install rails
rails -v
```
>ruby 3.0.2p107 (2021-07-07 revision 0db68f0233) [x86_64-linux-gnu]
>Rails 7.0.4

- *gem command*: from RubyGems package manager

#### create app
`rails new chat`

- gems turbo-rails abd stimulus-rails comes by dafault
note: gem howire-rails is deprecated. 


## 1. commands for basic structure

```bash
rails g scaffold room name:string
rails g model message room:references content:text
```

- ROOM: Full scaffold, creates
	- migration (that is a schema for the db table..?)
	- model
	- controller file
	- views files (all the basic UI)
	- route
	- tests, fixtures, helper, jbuilder files
- MESSAGE: Only model cause it needs less stuff
   

   
- [ ] jbuilder 
		create      app/views/rooms/index.json.jbuilder
      create      app/views/rooms/show.json.jbuilder
      create      app/views/rooms/_room.json.jbuilder

## 2. 
7. [ ] rails db:migrate
8. connect room and messages together
	1. [ ] at routes.rb....
	2. [ ] search what that does
	```ruby
	Rails.application.routes.draw do
		resources :rooms do
			resources :messages
		end
	end
	```
	2. [ ] at room.rb, room model `has_many : messages`
9. [ ] create messages_controller.rb.. a lot fo boilerplate code
		![[Pasted image 20221121104304.png]]

11. [ ] create a views/messages
12. [ ] create the view new.html.erb and the create method for messages 
13. [ ] create partial template  `_message.html.erb` and call it a the show of a room
14. [ ] run it and test it!
	1. show room should have link for new message
	2. should have something llike ``/rooms/1/messages/new`

#### starting with Turbo frames
> decompose into contexts, that can be lazy loaded or scope interaction

helper: add border to frames at application.css
```css
turbo-frame {
	display: block;
	border: 2px doted pink;
}
```
1. [ ] at rooms's show.html.erb, wrap the name and the edit links in a turbo_frame_tag. 
2. [ ] do it also for the edit form at edit.html.erb
```ruby
<%= turbo_frame_tag "room" do %>
	...
<% end %>
```
	--> this makes a section o the page that is replaced by another
2. nothing happens (!) when clicking link within frame that doesnt hav emathing frame

-> entoa o Frame se usa criando uma parte da pagina que funciona inteiramente indenpendete do resto da pagina,tem navegacao e renderizacao independetes....
3. [ ] solve it by adding attribute to lin_to do Back:
		`"data-turbo-frame: "_top"`
	- that does whaaat? points to `_top` to breakout of the Frame


4. [ ] add inline lazy-loaded Frame for new messages
```ruby
<%= turbo_frame_tag "new_message", src: new_room_message_path(@room), target: "_top" %>
```
	- do it at room show (just the line^) and message's new (wrap)
- the important s the matching id!!!
-> note differences between the fisrt frame we did and this last one
> always inspect Network tab to see behaviour
> always inspect html on devtool tab to see behaviour


> o de room eh realmente independete
> o de message faz a pagina recarregar


#### turbo streams!
html and crud like actions
just DOM changes
no direct js invocation (how does it change the dom ..with indirect js?)

#### add turbo stream response
1. at msg controller, at create method, add: 
	`format.turbo_stream`
2. at msg views: create create.turbo_stream.erb
		template that invokes append action with the DOM id of target container
	```
	<%= turbo_stream.append "messafes", @message %>
	```

result -> add msg, only post request, no GET

#### stimulus
adding  a controler to fix the input of new msg that doenst clear out

1. create controller reset_form_controller.js 
```ruby
	import {Controller} from 'stimulus'
	export default class extends Controller {
	reset() {
	this.element.reset()
	}
}
```
2. just extend the html
- at form_with
`data: { controller: 'reset_form', action: "turbo:submit-end->reset_form#reset"}`

## actually web socket
-> stabilish websocket connection to the sream identified by the room we're in -> From tag

1. just add to show room html:
`<%= turbo_stream_from @room %>`
- [ ] tamper-safe signed identifier

- [ ] what exactly the other turbo stream tags were doing until now?

-> observe 101 request, action cable

2. broadcast call: at model message.rb:
```ruby
	after_create_commit -> { broadcast_append_to room }
```
-> observe

sender has double vision!
fix:
at the create.turbo_stream.erb previously created, edit:
dead end this will be done without  a cable connection


### stream deletions
`after_destroy_commit -> { broadcast_remove_to room }`

##### simplification: one liner
get a full menu of lifecycle updates
add to message.rb:
```ruby
broadcast_to :rooms
or just:
broadcasts
```

etc etc 
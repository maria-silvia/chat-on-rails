# Development notes
Steps taken to develop the app

- [Development notes](#development-notes)
  - [0. Install](#0-install)
      - [create app](#create-app)
  - [1. generate commands for basic structure](#1-generate-commands-for-basic-structure)
  - [2. Connect room and messages](#2-connect-room-and-messages)
    - [Make relation](#make-relation)
    - [Make nested routes:](#make-nested-routes)
    - [Create the MessagesController](#create-the-messagescontroller)
  - [3. Create views/messages](#3-create-viewsmessages)
  - [4. Starting with Turbo frames](#4-starting-with-turbo-frames)
    - [Framing the room editing (basic frame)](#framing-the-room-editing-basic-frame)
      - [add attribute to back link](#add-attribute-to-back-link)
    - [Framing the messages (eager load frame)](#framing-the-messages-eager-load-frame)
      - [Why not just render the form?](#why-not-just-render-the-form)
        - [tips/obs](#tipsobs)
  - [5. turbo streams](#5-turbo-streams)
      - [add turbo stream response](#add-turbo-stream-response)
      - [stimulus](#stimulus)
  - [actually web socket](#actually-web-socket)
    - [stream deletions](#stream-deletions)
        - [simplification: one liner](#simplification-one-liner)

## 0. Install

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

- gems turbo-rails and stimulus-rails comes by dafault
note: gem howire-rails is deprecated. 


## 1. generate commands for basic structure

```bash
rails g scaffold room name:string
rails g model message room:references content:text
rails db:migrate
```

- ROOM: Full scaffold, creates
	- migration (that is instructions for the db table schema..?)
	- model
	- controller file
	- views files (all the basic UI)
	- route
	- tests, fixtures, helper, jbuilder files
- MESSAGE: creates only model, migration and tests

   
- [ ] jbuilder 
		create      app/views/rooms/index.json.jbuilder
      create      app/views/rooms/show.json.jbuilder
      create      app/views/rooms/_room.json.jbuilder

## 2. Connect room and messages 
### Make relation 
At model room.rb add `has_many : messages`

### Make nested routes:
```ruby
# routes.rb
Rails.application.routes.draw do
	resources :rooms do
		resources :messages
	end
end
```
- [ ] add only: [:new, :show, :destroy] em messages?

> Create routes like `/rooms/:room_id/messages` and its children /new, /:id, /:id/edit.
> Run `rails routes`to check all existing routes now.
> This declaration automatically routes to a MessagesController, not created yet 

### Create the MessagesController
- just new and create methods
- To create message there must be a room to belong to:
	`before_action :set_room, only: %i[ new create ]`
- at create: 
      `@message = @room.messages.create!(message_params)`
	  the `!` modifies the object it's called on


## 3. Create views/messages
- create partial template  `_message.html.erb` 
	- show the content and created_at attributes
- at rooms's show.html display the associated messages:
```ruby
<%= render @room.messages %>
```

- add button for new message with the prefix seen at `rails routes`:
```ruby
<%= link_to "New message", new_room_message_path(@room) %>
```
	
- create new.html.erb at messages/ with a form_with thing....






## 4. Starting with Turbo frames
> decompose into contexts, that can be lazy loaded or scope interaction

- [ ] scope interaction?

**A helper: add border to frames at application.css**
```css
turbo-frame {
	display: block;
	border: 2px doted pink;
}
```
### Framing the room editing (basic frame)
Wrap in `turbo_frame_tag "room"`
- the name and edit link at rooms's show.html.erb 
- the edit form at room's edit.html.erb

```ruby
<%= turbo_frame_tag "room" do %>
	...
<% end %>
```

**Result:** When editing a room, the form replaces only the html wrapped by matching turbo_frame_tag, the rest of the page is unaffected

-> So framed HTMLs belongs to a same context of their own
-> navegacao e renderizacao independente
-> this makes these sections act independente from the rest of the page

> **the frame expects any followed link or form submission to return a .html.erb that includes a matching frame tag**  
https://turbo.hotwired.dev/reference/frames


#### add attribute to back link
Since the Back link do not navigate to page with matching frame, when clicked it loads everything again (all the scripts)
Adding `"data-turbo-frame: "_top"` makes it loads only the GET rooms request
 ? its like adding target="_top" ??
>  When target="_top", navigate the window.

*Not sure how it works
Maybe because there is no matching frame clicking the link makes link behave like a normal link, fully reloading of the page. While with `_top` frame is setted to target the whole page, so whole page is replaced...
Ends up being like Turbo Drive than?*

### Framing the messages (eager load frame)
Just like before, create a own context for the message creation by wrapping HTML with turbo_frame_tag but **now with src attribute**:

- Replace link_to for a turbo_frame_tag for the New Message button
```ruby
<%= turbo_frame_tag "new_message", src: new_room_message_path(@room), target: "_top" %>
```
- Wrap the new message form with turbo_frame_tag `<%= turbo_frame_tag "new_message" do %>`

-> This makes the new message form render directly into the room's show page. No link that redirects for a create page. Now looks like a real chat 
-> Now when sending message the request are: 
    a) POST rooms/ID/messages
    b) GET rooms/ID
    c) GET rooms/ID/messages/new (load the form again)

-> The same request as before but now 

#### Why not just render the form?
1. The create form requires code from the action `new()` to be runned before:
      `@message = @room.messages.new`
    And render method only *renders* the html, dont pass through controller
2. there is no partial messages/_form, there is a new.html.erb and `render` is to be used with partials

##### tips/obs
> - matching id is important
> - inspect Network tab to check behaviour
> - inspect html on devtool tab to check behaviour

______

## 5. turbo streams
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

- destroy room not working, at tutorial button was removed
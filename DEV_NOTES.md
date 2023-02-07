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
  - [5. Turbo Streams](#5-turbo-streams)
    - [Append a message HTML tag without JS (streams messages)](#append-a-message-html-tag-without-js-streams-messages)
    - [Actually WebSocket now](#actually-websocket-now)
    - [Sending messages to the stream](#sending-messages-to-the-stream)
    - [stream deletions](#stream-deletions)
        - [simplification: one liner](#simplification-one-liner)
  - [6. Stimulus](#6-stimulus)

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
    b) GET rooms/ID (reloads whole page)
    c) GET rooms/ID/messages/new (load the form again)

-> The same request as before but now rest of the pages is intact until necessary

#### Why not just render the form?
1. The create form requires code from the action `new()` to be runned before:
      `@message = @room.messages.new`
    And render method only *renders* the html, dont pass through controller
2. there is no partial messages/_form, there is a new.html.erb and `render` is to be used with partials

##### tips/obs
> - matching id is important
> - inspect Network tab to check behaviour
> - inspect html on devtool tab to check behaviour
> - The first frame, the Basic for Room editing, is really independent context. The second one is not because sending message makes whole page to reload. Like if you try to start editing the room name and send a message, the edit form resets.

## 5. Turbo Streams
*DOM changes with HTML tags that functions as crud-like actions (CREATE, UPDATE, DELETE, etc)*

### Append a message HTML tag without JS (streams messages)

- When a message is created, the action should return also a **turbo stream response** besides the default html (the redirect to @room) 
  So at the `messages_controller > create > respond_to` add	`format.turbo_stream`

- For this turbo stream response create a template that invokes an action to **append** a message at the target container indicated by DOM id:
    - create file create.turbo_stream.erb with:
    ```ruby
    <%= turbo_stream.append "messages", @message %>
    ```

**Result:**
> - At message sending, only POST request is executed.
> - Messages are updated (technically last one is appended) without needing a GET request for the room show
> - When a message is sent, page is not fully reloaded anymore (edit form not affected as before)
>
> **Essentially, now it makes the minimal necessary DOM changes and dismiss the fully refresh** (when the frontend knows there is one more message??)

But it still require refresh if you're on diffenrent session than the one that submitted the message. That is, is not yet properly communicating between users.

### Actually WebSocket now 

- Each room should have its own stream
- A stream can be identified where it is from by a **from tag with the room object**:

  `<%= turbo_stream_from @room %>`
  This stabilish a WebSocket connection to the stream identified by the room we're in

**Result**

-> Network tab has a GET **cable** request, initiated by websocket, with 101 status (Switching Protocols).
-> The request:
  - receives a welcome message `type: "welcome"`
  - then sends a subscribe message identifying the stream:
  ```
  {
    "command": "subscribe",
    "identifier": "{
        \"channel\":\"Turbo::StreamsChannel\",
        \"signed_stream_name\":\"Iloy...50a\"
      }"
  }
  ```
  - then receives a confirm_subscription message:
  ```
  {
    "identifier": "{
      \"channel\":\"Turbo::StreamsChannel\",
      \"signed_stream_name\":\"Ilo...50a\"
    }",
    "type":"confirm_subscription"
  }
  ```
  - *and then receives a ping message every 3 seconds*
    ```
    {
    "type": "ping",
    "message": 1675739649
    }
    ```


### Sending messages to the stream

- Add **broadcast call** when message is created. 
  At model message.rb:
  `after_create_commit -> { broadcast_append_to room }`

> mirrors what was already been done at the controller, but now over websocket.

That is, when message created sends a broadcast message.

**Result**

- When a message is created on server, everyone, every browser session receives on its cable request:
```
{
    "identifier": "{
      \"channel\":\"Turbo::StreamsChannel\",
      \"signed_stream_name\":\"Ilo...0a\"
    }",
    "message": 
    "<turbo-stream action=\"append\" target=\"messages\"><template><p id=\"message_32\">\n  [07 Feb 03:12] \n  Oi tudo bem \n</p>\n</template></turbo-stream>"
}
```

*(tutorial speask about a double vision that requires deleting the template created on previous step because cable would handle it.. but i don't get double vision)*
- [ ] searh why it did the first part then
*i think its because it does need to have something on controller saying a turbo stream will be returned, the template is just while there wasnt a proper turbo stream response*
____


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

## 6. Stimulus
After message is sent the input do not clear out, we add a stimulus controler to fix that.

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


- destroy room not working, at tutorial button was removed
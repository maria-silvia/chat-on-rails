class MessagesController < ApplicationController
    before_action :set_room, only: %i[ new create]
  
    def new
      @message = @room.messages.new
    end
  
    # POST /rooms or /rooms.json
    def create
      @message = @room.messages.create!(message_params)
  
      respond_to do |format|
        format.html { redirect_to @room}
      end
    end
  
    private
      # Use callbacks to share common setup or constraints between actions.
      def set_room
        @room = Room.find(params[:room_id])
      end
  
      # Only allow a list of trusted parameters through.
      def message_params
        params.require(:message).permit(:content)
      end
  end
  
class EventsController < ApplicationController

  def index
    @date = get_date + 1.day
    conds = {}
    conds[:eventable_type] = params[:eventable_type].keys if params[:eventable_type]
    conds[:transition] = params[:transition].keys if params[:transition]
    @events = @topic.events.
      where("event_date <= ?", @date).
      where(conds).
      order("event_date DESC").
      includes(:eventable).
      includes(:children => [:eventable])
    respond_to do |f|
      f.html
      f.xml  { render :xml  => @events.to_xml( :include => :eventable) }
      f.json { render :json => @events.to_json(:include => :eventable) }
    end
  end

  def open_extended
    @event = @topic.events.find(params[:id])
    render :partial => "extended", :object => @event, :as => :event
  end

  def show
    @event = @topic.events.find(params[:id])
    render @event
  end

  private

  def get_date
    if params[:date]
      if params[:date].kind_of? Hash
        Time.gm(*[:year,:month,:day].map{|x| params[:date][x].to_i})
      else
        Time.parse(params[:date])
      end
    else
      Time.now.midnight
    end
  end

end

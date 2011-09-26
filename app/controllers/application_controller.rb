# Leap - Electronic Individual Learning Plan Software
# Copyright (C) 2011 South Devon College

# Leap is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Leap is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

class ApplicationController < ActionController::Base

  protect_from_forgery

  layout proc{ |c| c.request.xhr? ? false : "application" }

  before_filter :maintenance_mode
  before_filter :set_user
  before_filter :set_topic
  before_filter :get_views

  def set_date(default_offset = 0)
    begin
      @date = if params[:date]
        if params[:date].kind_of? Hash
          Time.gm(*[:year,:month,:day].map{|x| params[:date][x].to_i})
        else
          Time.parse(params[:date])
        end
      else
        Time.now + default_offset
      end
    rescue
      flash.now[:notice] = "Incorrect date entered! Using today instead."
      @date=Time.now
    end
  end

  private

  def maintenance_mode
    render :file => "public/maintenance_mode.html.erb", :layout => nil, :locals => {:message => Settings.maintenance_mode} unless Settings.maintenance_mode.blank?
  end

  def set_user
    if Rails.env == "development"
      Person.user = @user = session[:user_id] ? Person.get(session[:user_id]) : nil
      Person.affiliation = @affiliation = session[:user_affiliation]
      redirect_to test_url unless @user && @affiliation
    else
      Person.affiliation = @affiliation = request.env["affiliation"] ? request.env["affiliation"].split("@").first.downcase : nil
      uname,domain = request.env["eppn"].downcase.split('@')
      uname = uname[1..-1] if @affiliation == "affiliate"
      unless Settings.sdc.blank?
        if @affiliation == "student" and uname.match(/^[sne]/) 
          uname.gsub!(/^s/,"10")
          uname.gsub!(/^n/,"20")
          uname.gsub!(/^e/,"30")
        end
      end
      Person.user = @user = Person.get(uname)
      raise "Authentication Error! username: '#{@user}' and affiliation: '#{@affiliation}'" unless @user && @affiliation
    end
  end

  def set_topic
    if @affiliation == "staff"
      if params[:person_id]
        @topic = Person.get(params[:person_id],params[:refresh]) or redirect_to "/404.html"
      elsif params[:course_id]
        @topic = Course.get(params[:course_id],params[:refresh]) or redirect_to "/404.html"
      else
        @topic = @user
      end
    else
      @topic = @user
    end
  end

  def get_views
    @views = View.order("position").in_list.for_user
  end

  def admin_only
    Settings.admin_users.split(/,/).include? @user.username or redirect_to "/404.html"
  end

  def staff_only
    redirect_to "/404.html" unless @affiliation == "staff"
  end

end

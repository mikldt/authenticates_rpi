module ControllerAuthentication
  # Setup for when we get mixed into ActionController::Base
  def self.included(base)
    base.before_filter "set_up_accessor"
    base.helper_method :logged_in, :admin_logged_in, :go_to_login, :logged_in_user
  end

  # Methods for interacting with session data
 
  def logged_in
    if session[:member_id].nil?
      false
    else
      true
    end
  end

  def admin_logged_in
    if session[:member_id].nil?
      false
    else
      member = Person.find(session[:member_id])
      if member.is_admin
        true
      else
        false
      end
    end
  end

  def logged_in_user
    if session[:member_id].nil?
      false
    else
      Person.find(session[:member_id])
    end
  end

  def go_to_login
    redirect_to :controller => 'sessions', :action => 'begin'
  end

  protected

  # Preparation for authenticates_access plugin
  def set_up_accessor
    ActiveRecord::Base.accessor = logged_in_user
  end

  def logged_in_filter
    unless logged_in
      go_to_login
    end
  end

  def admin_filter
    unless admin_logged_in
      forbidden
    end
  end

  # Error Handling

  protected
  #TODO: Real error handling
  def forbidden
    redirect_to :controller => 'sessions', :action => 'forbidden'
  end
end
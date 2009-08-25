# AuthenticatesRpi
module AuthenticatesRpi
  # This module gets mixed-in to ActionController::Base
  module ActMethods
    def authenticate_rpi ( user_class, opts={} )
      include InstanceMethods
      logger.info "----------------------------------------------"
      logger.info "HELLO! autheticates_rpi mixed in to "+self.class.name +
       " on Rails " + Rails::VERSION::STRING

      #Username field is required; used to look up the value from CAS.
      username_field = opts[:username_field] || "username"
      #Admin field is optional if the site has admins. If none specified,
      #all users recieve false for admin_logged_in.
      admin_field = opts[:admin_field]

      #Argument Validation
      #TODO: proper exceptions to raise, not just runtime junk
      unless user_class.instance_of?(Class)
        raise 'user_class must be a class'
      end
      unless user_class.new.respond_to?(username_field)
        raise 'username_field: no such method "' + username_field +
          '" on class ' + user_class.name
      end
      unless admin_field.nil? || user_class.new.respond_to?(admin_field)
        raise 'admin_field: no such method "' + admin_field +
          '" on class ' + user_class.name
      end

      #Argument Storage
      write_inheritable_attribute :user_class, user_class
      write_inheritable_attribute :username_field, username_field
      write_inheritable_attribute :admin_field, admin_field
      class_inheritable_reader :user_class, :username_field, :admin_field
    end
 end

  # Instance methods that are included when we run authenticates_rpi
  # in a controller (say, ApplicationController)
  # We use instance methods because the access the session, which
  # belongs to the ActionController instance.
  module InstanceMethods
    # Setup for when we get mixed into ActionController::Base
    def self.included(base)
      base.helper :all
      base.before_filter "set_up_accessor"
      base.helper_method :logged_in, :admin_logged_in, :go_to_login,
                         :logged_in_user
    end

    # Methods for interacting with session data
    def logged_in
      if session[:username].nil?
        false
      else
        true
      end
    end

    def admin_logged_in
      if session[:username].nil?
        #No current user
        logger.warn "No current user"
        false
      elsif admin_field.nil?
        #Site not configured for admin behavior
        logger.warn "No admin field"
        false
      else
        #Check the app-configured admin field
        if logged_in_user.send admin_field
          true
        else
          false
        end
      end
    end

    def logged_in_user
      if session[:username].nil?
        logger.warn "No current user"
        false
      else
        p = find_user_by_username(session[:username])
        if p.nil?
          raise "User not found, yo."
        else
          p
        end
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

    #Finds a person by username, using the configurable username field.
    def find_user_by_username(username)
      user_class.find(:first, :conditions => {username_field => username})
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
      logger.warn "FORBIDDEN - REDIRECTING"
      redirect_to :controller => 'sessions', :action => 'forbidden'
    end
  end
end


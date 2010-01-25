# AuthenticatesRpi
module AuthenticatesRpi
  # This module gets mixed-in to ActionController::Base
  module ActMethods
    def authenticate_rpi ( user_class, opts={} )
      include InstanceMethods
      # logger.info "----------------------------------------------"
      # logger.info "autheticates_rpi mixed in ( on Rails " + 
      #   Rails::VERSION::STRING + " )"

      #Username field is required; used to look up the value from CAS.
      username_field = opts[:username_field] || "username"
      
      #Fields that we'll fill in from LDAP, in addition to username_field
      fullname_field = opts[:fullname_field] || nil
      firstname_field = opts[:firstname_field] || nil
      lastname_field = opts[:lastname_field] || nil
      email_field = opts[:email_field] || nil

      #Admin field is optional if the site has admins. If none specified,
      #all users recieve false for admin_logged_in.
      admin_field = opts[:admin_field]

      autoadd = opts[:autoadd_users] || false
      sudo_enabled = opts[:sudo_enabled] || false

      ldap_address = opts[:ldap_address] || nil
      ldap_port = opts[:ldap_port] || 389
      ldap_dn = opts[:ldap_dn] || nil
      ldap_username_field = opts[:ldap_username_field] || 'uid'
      ldap_email_field = opts[:ldap_email_field] || 'mailAlternateAddress'

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
      write_inheritable_attribute :fullname_field, fullname_field
      write_inheritable_attribute :firstname_field, firstname_field
      write_inheritable_attribute :email_field, email_field
      write_inheritable_attribute :lastname_field, lastname_field
      write_inheritable_attribute :admin_field, admin_field
      write_inheritable_attribute :autoadd_users, autoadd
      write_inheritable_attribute :sudo_enabled, sudo_enabled
      write_inheritable_attribute :ldap_address, ldap_address
      write_inheritable_attribute :ldap_port, ldap_port
      write_inheritable_attribute :ldap_dn, ldap_dn
      write_inheritable_attribute :ldap_username_field, ldap_username_field
      write_inheritable_attribute :ldap_email_field, ldap_email_field
      class_inheritable_reader :user_class, :username_field, :fullname_field,
        :firstname_field, :lastname_field, :admin_field, :autoadd_users,
        :ldap_address, :ldap_port, :ldap_dn, :ldap_username_field, 
        :sudo_enabled, :email_field, :ldap_email_field
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
      base.helper_method :logged_in?, :admin_logged_in?, :go_to_login,
                         :current_user, :current_user_display_name
    end

    # Methods for interacting with session data
    def logged_in?
      if session[:username].nil?
        false
      else
        true
      end
    end

    def admin_logged_in?
      if session[:username].nil?
        #No current user
        false
      elsif admin_field.nil?
        #Site not configured for admin behavior
        logger.warn "AuthenticatesRpi checking for admin, " +
          "but no admin field is configured. "
        false
      else
        #Check the app-configured admin field
        if current_user.send admin_field
          true
        else
          false
        end
      end
    end

    # Method to return the object representing the logged in user,
    # or false if there's nobody logged in. For general use, and included
    # as a helper. This should be the only method used for getting the
    # current user.
    def current_user
      if session[:username].nil?
        false
      else
        p = find_user_by_username(session[:username])
        if p.nil?
          raise "User "+session[:username]+" not found!"
        else
          p
        end
      end
    end

    # Figures out a 'display name' for the user, in the following priority
    # 1. If there's a fullname field defined, use that
    # 2. If there are first and last names, use them
    # 3. Just use the username, because its unique.
    def current_user_display_name
      user = current_user
      if fullname_field
        n = user.send(fullname_field)
        return n unless n.blank?
      end

      if firstname_field && lastname_field
        f = user.send(firstname_field)
        l = user.send(lastname_field)
        return f + " " + l unless f.blank? || l.blank?
      end

      return user.send(username_field)
    end

    def go_to_login
      redirect_to :controller => 'sessions', :action => 'new'

      # Before we go, save the current (full) path.
      # This will allow us to get back to the requested page
      # once we've authenticated.
      session[:page_before_login] = request.request_uri
    end

    protected

    # Preparation for authenticates_access plugin
    def set_up_accessor
      #TODO: is this good enought of a check?
      if (Module.constants.include? 'AuthenticatesAccess'
        ActiveRecord::Base.accessor = current_user
      end
    end

    #Finds a person by username, using the configurable username field.
    def find_user_by_username(username)
      user_class.find(:first, :conditions => {username_field => username})
    end

    def logged_in_filter
      unless logged_in?
        go_to_login
      end
    end

    def admin_filter
      unless admin_logged_in?
        unless logged_in?
          go_to_login
        else
          forbidden
        end
      end
    end

    def new_user_action(username)
      # If the plugin is configured to auto-add new users, do it.
      if autoadd_users
        u = user_class.new
        # If we have authenticates_access, we need to bypass it in order
        # to change the username.
        # Use caution while auth is bypassed (the user can't just edit
        # their own rcsid, so its important that username comes from a
        # good source)
        if u.methods.include? 'bypass_auth'
          u.bypass_auth do
            u.send(username_field+'=', username)
          end
        else
          u.send(username_field+'=', username)
        end

        # Fetch additional data from LDAP if you like
        logger.info "created the user"
        unless(ldap_address.nil? || ldap_dn.nil?)
          require 'ldap'
          logger.info 'Making LDAP query for new user: '+username
          ldap_conn = LDAP::Conn.new(ldap_address, ldap_port)
          ldap_conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
          ldap_conn.bind
          results = ldap_conn.search2(ldap_username_field+"="+username+","+
                                      ldap_dn, LDAP::LDAP_SCOPE_SUBTREE, 
                                      '(cn=*)')
          # Add the data to the user if t
          unless(results.first.nil?)
            first = results.first['givenName'].first.split(' ').first
            last = results.first['sn'].first
            email = results.first[ldap_email_field]
            # full = results.first['gecos'].first
            if fullname_field
              u.send('attribute=', fullname_field, first + ' ' + last)
            end
            if firstname_field
              u.send('attribute=', firstname_field, first)
            end
            if lastname_field
              u.send('attribute=', lastname_field, last)
            end
            if email_field and !email.nil?
              u.send('attribute=', email_field, email)
            end
          end
        end

        u.save
      end
    end


    # Error Handling

    protected
    #TODO: Real error handling
    def forbidden
      logger.warn "User forbidden."
      flash[:notice] = "Sorry, you do not have permission to view that page."
      redirect_to root_path
    end
  end
end


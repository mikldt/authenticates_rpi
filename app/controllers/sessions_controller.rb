class SessionsController < ApplicationController
  before_filter CASClient::Frameworks::Rails::Filter, :only => :new
#  before_filter :require_login, :only => [ :destroy ]
#  before_filter :require_login_or_first_user, :except => [ :destroy, :new, :show ]
  unloadable
  #GET new_account_url
  def new
    # Will be forced to authenticate before getting here.

    if logged_in?
      # The user is already logged in, so let's not mess with the session.
      flash[:notice] = "You are already logged in!"
      redirect_to root_path
    else
      # The user needs to be logged in.
      user = find_user_by_username(session[:cas_user])

      # New user, the plugin knows what to do.
      if user.nil?
        # Delegate to authenticates_rpi.rb
        new_user_action(session[:cas_user])
        # See if they can log in now.
        user = find_user_by_username(session[:cas_user])
      end

      if user.nil?
        # We don't know this person.
        # TODO: What to do in this case.
        flash[:notice] = "Sorry, your login does not appear to be valid."
        redirect_to root_path
      else
        # This person is in the db, let them in.
        session[:username] = user.send(username_field)
        flash[:notice] = "Logged in successfully - #{session[:username]}"

        # This session variable may be set before redirecting to session/new
        # in order to get the user back to the page they were trying to get at.
        if session[:page_before_login]
          redirect_to session[:page_before_login]
          session[:page_before_login] = nil
        else
          redirect_to root_path
        end
      end
    end
#Tidbits of old code:

#      #logger.info("Redirecting to prev uri: " + session[:prev_uri])
#      if session[:prev_uri]
#        redirect_to session[:prev_uri]
#      else
#        redirect_to root_url
#      end

#    elsif User.find(:first)
#      flash[:notice] = ["Sorry, login is for admins only."]
#      redirect_to root_path
#    else
#      flash[:notice] = ['Congratulations! Fill out this form to become the first user!']
#      redirect_to new_user_path
#    end
  end


 #  #GET edit_account_url
   def edit
     #TODO: secure and make proper, use update
     if not params[:username].nil? and User.current=User.find_by_username(params[:username])
       flash[:notice] = ["Welcome", User.current.first].join(', ')
     elsif not params[:username].nil?
       flash[:notice] = ["Sorry - login error! Please see the webmaster... TODO"]
       redirect_to "/"
     end
   end

  #DELETE account_url
  def destroy
    # clear out the session and log out of CAS
    session[:username] = nil
    CASClient::Frameworks::Rails::Filter.logout(self)
  end

end

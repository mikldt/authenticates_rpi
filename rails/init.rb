# Include hook code here
ActionController::Base.send :extend, AuthenticatesRpi::ActMethods

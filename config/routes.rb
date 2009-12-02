ActionController::Routing::Routes.draw do |map|
  map.resource :session, :except => [ :create ], :member => {:sudo => :get, :change_user => :post }
end

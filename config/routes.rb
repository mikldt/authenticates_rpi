ActionController::Routing::Routes.draw do |map|
  map.resource :session, :except => [ :create ]
end

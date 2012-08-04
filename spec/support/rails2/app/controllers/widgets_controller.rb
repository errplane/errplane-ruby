class WidgetsController < ApplicationController
  def index; render :nothing => true; end
  def new; return 1/0; end
end

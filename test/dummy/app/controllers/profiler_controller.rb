class ProfilerController < ApplicationController
  def index
    Widget.limit(5).to_json
  end
end

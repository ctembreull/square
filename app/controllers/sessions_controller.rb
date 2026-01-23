class SessionsController < ApplicationController
  skip_before_action :require_admin, only: [:new, :create]

  def new
  end

  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to root_path, notice: "Logged in successfully"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "Logged out successfully"
  end

  def toggle_admin_tools
    session[:show_admin_tools] = !session[:show_admin_tools]
    redirect_back fallback_location: root_path
  end
end

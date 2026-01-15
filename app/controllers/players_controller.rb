class PlayersController < ApplicationController
  before_action :set_player, only: [ :show, :edit, :update, :destroy, :deactivate, :activate ]

  def index
    @singles = Player.singles.active.order(:name)
    @families = Player.families.active.includes(:members).order(:name)
    @inactive_players = Player.humans.inactive.includes(:family).order(:name)
    @charities = Player.charities.active.order(:name)
    @inactive_charities = Player.charities.inactive.order(:name)

    @total_active_players = Player.humans.active.count
    @total_chances = Player.total_active_chances

    # For bulk chances modal preview
    @singles_chances_sum = Player.singles.active.sum(:chances)
    @families_chances_sum = Player.families.active.sum(:chances)
    @individuals_chances_sum = Player.individuals.active.sum(:chances)
    @individuals_count = Player.individuals.active.count
  end

  def show
  end

  def new
    @player = Player.new(active: true)
  end

  def edit
  end

  def create
    @player = Player.new(player_params)

    if @player.save
      redirect_to players_path, notice: "Player was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @player.update(player_params)
      redirect_to players_path, notice: "Player was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @player.destroy
    redirect_to players_path, notice: "Player was successfully deleted."
  end

  def deactivate
    @player.update(active: false)
    redirect_to players_path, notice: "#{@player.name} has been deactivated."
  end

  def activate
    @player.update(active: true)
    redirect_to players_path, notice: "#{@player.name} has been activated."
  end

  def bulk_update_chances
    updated_count = 0

    if params[:single_chances].present?
      updated_count += Player.singles.active.update_all(chances: params[:single_chances].to_i)
    end

    if params[:family_chances].present?
      updated_count += Player.families.active.update_all(chances: params[:family_chances].to_i)
    end

    if params[:individual_chances].present?
      updated_count += Player.individuals.active.update_all(chances: params[:individual_chances].to_i)
    end

    redirect_to players_path, notice: "Updated chances for #{updated_count} players."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_player
      @player = Player.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def player_params
      params.require(:player).permit(:type, :email, :name, :display_name, :active, :chances, :family_id)
    end
end

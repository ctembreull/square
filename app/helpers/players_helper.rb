module PlayersHelper
  def player_type_color(player)
    case player.type
    when "Single"
      "primary"
    when "Individual"
      "info"
    when "Family"
      "warning"
    when "Charity"
      "success"
    else
      "secondary"
    end
  end

  def player_type_options
    [
      ["Single - One person, no family", "Single"],
      ["Individual - Part of a family group", "Individual"],
      ["Family - Group with members", "Family"],
      ["Charity - Fills unfilled squares", "Charity"]
    ]
  end

  def family_options_for_select
    Family.order(:name).pluck(:name, :id)
  end
end

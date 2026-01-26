# README

## Data Export/Import Tasks

```
rake seeds:export_structure    Export Leagues/Conferences → db/seeds.rb
rake seeds:export              Export Teams/Colors/Styles → db/seeds/teams.yml
rake seeds:import              Import from teams.yml
rake affiliations:export       Export Team-Conference links → db/seeds/affiliations.yml
rake affiliations:import       Import from affiliations.yml
rake players:export            Export Players → db/seeds/players.yml
rake players:import            Import from players.yml
```

## Full Rebuild Order

1. `rake db:seed` - Leagues and Conferences
2. `rake seeds:import` - Teams, Colors, Styles
3. `rake affiliations:import` - Team-Conference affiliations
4. `rake players:import` - Players (emails need manual re-entry)
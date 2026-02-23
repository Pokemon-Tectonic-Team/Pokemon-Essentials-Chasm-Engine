Events.onStepTaken += proc {
  if stealthSprayActive? && !$game_player.terrain_tag.ice   # Shouldn't count down if on ice
    $PokemonGlobal.stealthSpray -= 1
    if $PokemonGlobal.stealthSpray.zero?
      if $PokemonBag.pbHasItem?(:STEALTHSPRAY)
        if pbConfirmMessageSerious(_INTL("The stealth spray's effect wore off! Would you like to use another one?"))
          pbUseItem($PokemonBag,:STEALTHSPRAY)
        else
          refreshPlayerAndFollowerPokemon
        end
      else
        pbMessage(_INTL("The stealth spray's effect wore off!"))
        refreshPlayerAndFollowerPokemon
      end
    end
  end
}

def refreshPlayerAndFollowerPokemon
  $game_player.refresh
  refreshFollow(false)
end
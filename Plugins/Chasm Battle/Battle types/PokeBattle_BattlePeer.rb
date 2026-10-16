#===============================================================================
#
#===============================================================================
class PokeBattle_RealBattlePeer
    def pbStorePokemon(player,pkmn)
      if !player.party_full?
        player.party[player.party.length] = pkmn
        return -1
      end
      pkmn.heal
      oldCurBox = pbCurrentBox
      storedBox = $PokemonStorage.pbStoreCaught(pkmn)
      if storedBox<0
        # NOTE: Poké Balls can't be used if storage is full, so you shouldn't ever
        #       see this message.
        pbDisplayPaused(_INTL("Can't catch any more..."))
        return oldCurBox
      end
      return storedBox
    end
  
    def pbGetStorageCreatorName
      return nil
    end
  
    def pbCurrentBox
      return $PokemonStorage.currentBox
    end
  
    def pbBoxName(box)
      return (box<0) ? "" : $PokemonStorage[box].getName(box)
    end
  
    def pbOnEnteringBattle(_battle,pkmn,wild=false)
      f = MultipleForms.call("getFormOnEnteringBattle",pkmn,wild)
      pkmn.form = f if f
    end
  
    # For switching out, including due to fainting, and for the end of battle
    def pbOnLeavingBattle(battle,pkmn,usedInBattle,endBattle=false)
      return if !pkmn
      f = MultipleForms.call("getFormOnLeavingBattle",pkmn,battle,usedInBattle,endBattle)
      if f && pkmn.form != f
        old_hp    = pkmn.hp
        old_total = pkmn.totalhp
        pkmn.form = f
        if old_hp == 0
          pkmn.hp = 0
        elsif old_total > 0
        # Preserve HP percentage.
          pkmn.hp = (old_hp * pkmn.totalhp.to_f / old_total).round
          pkmn.hp = 1 if pkmn.hp < 1
          pkmn.hp = pkmn.totalhp if pkmn.hp > pkmn.totalhp
        end
      end
    end
  end
  
  
  
  #===============================================================================
  #
  #===============================================================================
  class PokeBattle_BattlePeer
    def self.create
      return PokeBattle_RealBattlePeer.new
    end
  end
  
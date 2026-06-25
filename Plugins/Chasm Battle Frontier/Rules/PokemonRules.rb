# PokemonRule classes specific to Battle Frontier's own Cup/Challenge
# presets (ChallengeRules.rb, Rulesets.rb) - they reproduce specific official
# rulesets based on old community standards and mechanics that don't fit
# Cable Club's freely-configurable PvP (see Cable Club's PokemonRules.rb for
# the classes shared with it instead). isValid?(pkmn) is checked once per
# Pokemon entered; errorMessage(pkmn) returns an Array of every distinct
# thing about that Pokemon which violates the rule, same contract as Cable
# Club's PokemonRules.rb.

# PokemonRules = StandardRestriction
# Bans Pokemon with a base stat total of 600 or more, and Wynaut/Wobbuffet
# specifically, but always allows Truant/Slow Start abilities and
# Dragonite/Salamence/Tyranitar by name despite their BST. Matches the
# Generation IV "Standard" ban list used by the Cup presets in Rulesets.rb.
# Eggs are already banned unconditionally by PokemonRuleSet#isPokemonValid?
# (Cable Club's Rulesets.rb), so this doesn't need to check for them itself.
class StandardRestriction
  def isValid?(pkmn)
    return false if !pkmn
    # Species with disadvantageous abilities are not banned
    pkmn.species_data.abilities.each do |a|
      return true if [:TRUANT, :SLOWSTART].include?(a)
    end
    # Certain named species are not banned
    return true if [:DRAGONITE, :SALAMENCE, :TYRANITAR].include?(pkmn.species)
    # Certain named species are banned
    return false if [:WYNAUT, :WOBBUFFET].include?(pkmn.species)
    # Species with total base stat 600 or more are banned
    bst = 0
    pkmn.baseStats.each_value { |s| bst += s }
    return false if bst >= 600
    # Is valid
    return true
  end

  def errorMessage(pkmn)
    return [_INTL("{1} is banned under the Standard ruleset.", pkmn.name)] if [:WYNAUT, :WOBBUFFET].include?(pkmn.species)
    bst = 0
    pkmn.baseStats.each_value { |s| bst += s }
    return [_INTL("{1} has a base stat total of {2}, which is 600 or more.", pkmn.name, bst)]
  end
end

# PokemonRules = LittleCupRestriction
# Bans a few items/moves/species that would otherwise undermine a Little
# Cup-style baby-Pokemon format: Berry Juice, Deep Sea Tooth, Sonic Boom,
# Dragon Rage, and species whose evolution doesn't depend on level (so it
# can't be capped by a level restriction alone).
class LittleCupRestriction
  BANNED_SPECIES = [:SCYTHER, :SNEASEL, :MEDITITE, :YANMA, :TANGELA, :MURKROW]

  def isValid?(pkmn)
    return false if pkmn.hasItem?(:BERRYJUICE)
    return false if pkmn.hasItem?(:DEEPSEATOOTH)
    return false if pkmn.hasMove?(:SONICBOOM)
    return false if pkmn.hasMove?(:DRAGONRAGE)
    return false if BANNED_SPECIES.any? { |s| pkmn.isSpecies?(s) }
    return true
  end

  def errorMessage(pkmn)
    errors = []
    errors << _INTL("{1} is holding a Berry Juice, which isn't allowed in Little Cup.", pkmn.name) if pkmn.hasItem?(:BERRYJUICE)
    errors << _INTL("{1} is holding a Deep Sea Tooth, which isn't allowed in Little Cup.", pkmn.name) if pkmn.hasItem?(:DEEPSEATOOTH)
    errors << _INTL("{1} knows {2}, which isn't allowed in Little Cup.", pkmn.name, GameData::Move.get(:SONICBOOM).name) if pkmn.hasMove?(:SONICBOOM)
    errors << _INTL("{1} knows {2}, which isn't allowed in Little Cup.", pkmn.name, GameData::Move.get(:DRAGONRAGE).name) if pkmn.hasMove?(:DRAGONRAGE)
    errors << _INTL("{1}'s species isn't allowed in Little Cup.", pkmn.name) if BANNED_SPECIES.any? { |s| pkmn.isSpecies?(s) }
    return errors
  end
end

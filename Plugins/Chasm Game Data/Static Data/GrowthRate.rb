module GameData
    class GrowthRate
        attr_reader :id
        attr_reader :real_name
        attr_reader :exp_values
        attr_reader :exp_formula

        DATA = {}

        extend ClassMethodsSymbols
        include InstanceMethods

        def self.load; end
        def self.save; end

        # Calculates the maximum level a Pokémon can attain. This can vary during a
        # game, and here is where you would make it do so. Note that this method is
        # called by the Compiler, which happens before anything (e.g. Game Switches/
        # Variables, the player's data) is loaded, so code in this method should
        # check whether the needed variables exist before using them; if they don't,
        # this method should return the maximum possible level ever.
        # @return [Integer] the maximum level attainable by a Pokémon
        def self.max_level
            return Settings::MAXIMUM_LEVEL
        end

        def initialize(hash)
            @id          = hash[:id]
            @real_name   = hash[:name] || "Unnamed"
            @exp_values  = hash[:exp_values]
            @exp_formula = hash[:exp_formula]
        end

        # @return [String] the translated name of this growth rate
        def name
            return _INTL(@real_name)
        end

        # @param level [Integer] a level number
        # @return [Integer] the minimum Exp needed to be at the given level
        def minimum_exp_for_level(level)
            return ArgumentError.new("Level #{level} is invalid.") if !level || level <= 0
            level = [level, GrowthRate.max_level].min
            return @exp_values[level] if level < @exp_values.length
            raise "No Exp formula is defined for growth rate #{name}" if !@exp_formula
            return @exp_formula.call(level)
        end

        # @return [Integer] the maximum Exp a Pokémon with this growth rate can have
        def maximum_exp
            return minimum_exp_for_level(GrowthRate.max_level)
        end

        # @param exp1 [Integer] an Exp amount
        # @param exp2 [Integer] an Exp amount
        # @return [Integer] the sum of the two given Exp amounts
        def add_exp(exp1, exp2)
            return (exp1 + exp2).clamp(0, maximum_exp)
        end

        # @param exp [Integer] an Exp amount
        # @return [Integer] the level of a Pokémon that has the given Exp amount
        def level_from_exp(exp)
            return ArgumentError.new("Exp amount #{level} is invalid.") if !exp || exp < 0
            max = GrowthRate.max_level
            return max if exp >= maximum_exp
            for level in 1..max
                return level - 1 if exp < minimum_exp_for_level(level)
            end
            return max
        end
    end
end

#===============================================================================

GameData::GrowthRate.register({
  :id          => :Medium, # Also known as Medium Fast
  :name        => _INTL("Medium"),
  :exp_values  => [-1,
                   0, 8, 27, 64, 125, 216, 343, 512, 729, 1000,
                   1331, 1728, 2197, 2744, 3375, 4096, 4913, 5832, 6859, 8000,
                   9261, 10_648, 12_167, 13_824, 15_625, 17_576, 19_683, 21_952, 24_389, 27_000,
                   29_791,  32_768,  35_937,  39_304,  42_875,  46_656, 50_653, 54_872, 59_319, 64_000,
                   68_921,  74_088,  79_507,  85_184,  91_125,  97_336, 103_823, 110_592, 117_649, 125_000,
                   132_651, 140_608, 148_877, 157_464, 166_375, 175_616, 185_193, 195_112, 205_379,  216_000,
                   226_981, 238_328, 250_047, 262_144, 274_625, 287_496, 300_763, 314_432, 328_509,  343_000,
                   357_911, 373_248, 389_017, 405_224, 421_875, 438_976, 456_533, 474_552, 493_039,  512_000,
                   531_441, 551_368, 571_787, 592_704, 614_125, 636_056, 658_503, 681_472, 704_969,  729_000,
                   753_571, 778_688, 804_357, 830_584, 857_375, 884_736, 912_673, 941_192, 970_299, 1_000_000],
  :exp_formula => proc { |level| next level**3 }
})

# Erratic (600000):
#   For levels 0-50:   n**3 * (100 - n) / 50
#   For levels 51-68:  n**3 * (150 - n) / 100
#   For levels 69-98:  n**3 * 1.274 - (n / 150) - p(n mod 3)
#                      where p(x) = array(0.000, 0.008, 0.014)[x]
#   For levels 99-100: n**3 * (160 - n) / 100
GameData::GrowthRate.register({
  :id          => :Erratic,
  :name        => _INTL("Erratic"),
  :exp_values  => [-1,
                   0, 15, 52, 122, 237, 406, 637, 942, 1326, 1800,
                   2369, 3041, 3822, 4719, 5737, 6881, 8155, 9564, 11_111, 12_800,
                   14_632,  16_610,  18_737,  21_012,  23_437,  26_012,  28_737,  31_610,  34_632,  37_800,
                   41_111,  44_564,  48_155,  51_881,  55_737,  59_719,  63_822,  68_041,  72_369,  76_800,
                   81_326,  85_942,  90_637,  95_406, 100_237, 105_122, 110_052, 115_015, 120_001, 125_000,
                   131_324, 137_795, 144_410, 151_165, 158_056, 165_079, 172_229, 179_503, 186_894, 194_400,
                   202_013, 209_728, 217_540, 225_443, 233_431, 241_496, 249_633, 257_834, 267_406, 276_458,
                   286_328, 296_358, 305_767, 316_074, 326_531, 336_255, 346_965, 357_812, 367_807, 378_880,
                   390_077, 400_293, 411_686, 423_190, 433_572, 445_239, 457_001, 467_489, 479_378, 491_346,
                   501_878, 513_934, 526_049, 536_557, 548_720, 560_922, 571_333, 583_539, 591_882, 600_000],
  :exp_formula => proc { |level| next (level**4) * 3 / 500 }
})

# Fluctuating (1640000):
#   For levels 0-15  : n**3 * (24 + ((n + 1) / 3)) / 50
#   For levels 16-35:  n**3 * (14 + n) / 50
#   For levels 36-100: n**3 * (32 + (n / 2)) / 50
GameData::GrowthRate.register({
  :id          => :Fluctuating,
  :name        => _INTL("Fluctuating"),
  :exp_values  => [-1,
                   0, 4, 13, 32, 65, 112, 178, 276, 393, 540,
                   745, 967, 1230, 1591, 1957, 2457, 3046, 3732, 4526, 5440,
                   6482, 7666, 9003, 10_506, 12_187, 14_060, 16_140, 18_439, 20_974, 23_760,
                   26_811,   30_146,   33_780,   37_731,   42_017, 46_656, 50_653, 55_969, 60_505, 66_560,
                   71_677,   78_533,   84_277,   91_998,   98_415, 107_069, 114_205, 123_863, 131_766, 142_500,
                   151_222,  163_105,  172_697,  185_807,  196_322,  210_739,  222_231,  238_036,  250_562,  267_840,
                   281_456,  300_293,  315_059,  335_544,  351_520,  373_744,  390_991,  415_050,  433_631,  459_620,
                   479_600,  507_617,  529_063,  559_209,  582_187,  614_566,  639_146,  673_863,  700_115,  737_280,
                   765_275,  804_997,  834_809,  877_201,  908_905,  954_084,  987_754, 1_035_837, 1_071_552, 1_122_660,
                   1_160_499, 1_214_753, 1_254_796, 1_312_322, 1_354_652, 1_415_577, 1_460_276, 1_524_731, 1_571_884, 1_640_000],
  :exp_formula => proc { |level|
      rate = [82 - ((level - 100) / 2.0), 40].max
      next (level**4) * rate / 5000
  }
})

GameData::GrowthRate.register({
  :id          => :Parabolic, # Also known as Medium Slow
  :name        => _INTL("Parabolic"),
  :exp_values  => [-1,
                   0,      9, 57, 96,    135, 179, 236,    314, 419, 560,
                   742, 973, 1261, 1612, 2035, 2535, 3120, 3798, 4575, 5460,
                   6458, 7577, 8825, 10_208, 11_735, 13_411, 15_244, 17_242, 19_411, 21_760,
                   24_294,  27_021,  29_949,  33_084,  36_435,  40_007,  43_808, 47_846, 52_127, 56_660,
                   61_450,  66_505,  71_833,  77_440,  83_335,  89_523,  96_012, 102_810, 109_923, 117_360,
                   125_126, 133_229, 141_677, 150_476, 159_635, 169_159, 179_056, 189_334,  199_999,  211_060,
                   222_522, 234_393, 246_681, 259_392, 272_535, 286_115, 300_140, 314_618,  329_555,  344_960,
                   360_838, 377_197, 394_045, 411_388, 429_235, 447_591, 466_464, 485_862,  505_791,  526_260,
                   547_274, 568_841, 590_969, 613_664, 636_935, 660_787, 685_228, 710_266,  735_907,  762_160,
                   789_030, 816_525, 844_653, 873_420, 902_835, 932_903, 963_632, 995_030, 1_027_103, 1_059_860],
  :exp_formula => proc { |level| next ((level**3) * 6 / 5) - (15 * (level**2)) + (100 * level) - 140 }
})

GameData::GrowthRate.register({
  :id          => :Fast,
  :name        => _INTL("Fast"),
  :exp_values  => [-1,
                   0,      6, 21, 51, 100, 172, 274, 409, 583, 800,
                   1064,   1382,   1757, 2195, 2700, 3276, 3930, 4665,   5487, 6400,
                   7408,   8518,   9733, 11_059, 12_500, 14_060, 15_746, 17_561, 19_511, 21_600,
                   23_832,  26_214,  28_749,  31_443,  34_300,  37_324,  40_522,  43_897,  47_455, 51_200,
                   55_136,  59_270,  63_605,  68_147,  72_900,  77_868,  83_058,  88_473,  94_119, 100_000,
                   106_120, 112_486, 119_101, 125_971, 133_100, 140_492, 148_154, 156_089, 164_303, 172_800,
                   181_584, 190_662, 200_037, 209_715, 219_700, 229_996, 240_610, 251_545, 262_807, 274_400,
                   286_328, 298_598, 311_213, 324_179, 337_500, 351_180, 365_226, 379_641, 394_431, 409_600,
                   425_152, 441_094, 457_429, 474_163, 491_300, 508_844, 526_802, 545_177, 563_975, 583_200,
                   602_856, 622_950, 643_485, 664_467, 685_900, 707_788, 730_138, 752_953, 776_239, 800_000],
  :exp_formula => proc { |level| (level**3) * 4 / 5 }
})

GameData::GrowthRate.register({
  :id          => :Slow,
  :name        => _INTL("Slow"),
  :exp_values  => [-1,
                   0, 10, 33, 80, 156, 270, 428, 640, 911, 1250,
                   1663, 2160, 2746, 3430, 4218, 5120, 6141, 7290, 8573, 10_000,
                   11_576,  13_310,   15_208,   17_280,   19_531,   21_970,   24_603,   27_440,   30_486,   33_750,
                   37_238,  40_960,   44_921,   49_130,   53_593,   58_320,   63_316,   68_590,   74_148,   80_000,
                   86_151,  92_610,   99_383, 106_480, 113_906, 121_670, 129_778, 138_240, 147_061, 156_250,
                   165_813, 175_760,  186_096,  196_830,  207_968,  219_520,  231_491,  243_890,  256_723,  270_000,
                   283_726, 297_910,  312_558,  327_680,  343_281,  359_370,  375_953,  393_040,  410_636,  428_750,
                   447_388, 466_560,  486_271,  506_530,  527_343,  548_720,  570_666,  593_190,  616_298,  640_000,
                   664_301, 689_210,  714_733,  740_880,  767_656,  795_070,  823_128,  851_840,  881_211,  911_250,
                   941_963, 973_360, 1_005_446, 1_038_230, 1_071_718, 1_105_920, 1_140_841, 1_176_490, 1_212_873, 1_250_000],
  :exp_formula => proc { |level| (level**3) * 5 / 4 }
})

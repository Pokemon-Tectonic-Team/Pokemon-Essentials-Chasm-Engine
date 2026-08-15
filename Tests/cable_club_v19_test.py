# Standalone tests for cable_club_v19.py's .rules file parser/compiler.
# Run with: python Tests/cable_club_v19_test.py

import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import cable_club_v19 as cc

REPO_ROOT = os.path.join(os.path.dirname(__file__), "..")


class RuleFileParsingTest(unittest.TestCase):
    def test_singles_rules_has_no_battle_mode(self):
        data = cc.parse_rule_file(os.path.join(REPO_ROOT, "OnlinePresets", "singles.rules"))
        self.assertEqual(data["Name"], ["Restricted Singles"])
        rule = cc.compile_rule(data)
        self.assertEqual(rule[0], "Restricted Singles")
        self.assertEqual(rule[6], "")  # battle mode field, empty = unset

    def test_doubles_rules_has_a_battle_mode(self):
        data = cc.parse_rule_file(os.path.join(REPO_ROOT, "OnlinePresets", "doubles.rules"))
        rule = cc.compile_rule(data)
        self.assertEqual(rule[6], "double")

    def test_repeated_keys_accumulate_into_a_list(self):
        path = os.path.join(os.path.dirname(__file__), "_tmp_multi_rule_test.rules")
        with open(path, "w") as f:
            f.write(
                "[Light Cup]\n"
                "Description = Max level 50\n"
                "PartySize = 3,3\n"
                "PokemonRules = MaximumLevelRestriction,50\n"
                "PokemonRules = BannedSpeciesRestriction,MEWTWO,MEW\n"
                "PokemonRules = NoLegendaryRestriction\n"
            )
        try:
            data = cc.parse_rule_file(path)
            self.assertEqual(len(data["PokemonRules"]), 3)
        finally:
            os.remove(path)


class ClauseEncodingTest(unittest.TestCase):
    def test_encode_rule_clause_with_int_arg(self):
        self.assertEqual(cc.encode_rule_clause("FixedLevelAdjustment,70"), "FixedLevelAdjustment;int;70")

    def test_encode_rule_clause_with_symbol_args(self):
        self.assertEqual(
            cc.encode_rule_clause("BannedSpeciesRestriction,MEWTWO,MEW"),
            "BannedSpeciesRestriction;sym;MEWTWO;sym;MEW",
        )

    def test_encode_rule_clause_with_no_args(self):
        self.assertEqual(cc.encode_rule_clause("NoLegendaryRestriction"), "NoLegendaryRestriction")

    def test_split_rule_fields_respects_quotes(self):
        self.assertEqual(cc.split_rule_fields('Foo,"a,b"'), ["Foo", '"a,b"'])

    def test_infer_rule_arg_types(self):
        self.assertEqual(cc.infer_rule_arg("70"), ("int", "70"))
        self.assertEqual(cc.infer_rule_arg("true"), ("bool", "true"))
        self.assertEqual(cc.infer_rule_arg('"hello"'), ("str", "hello"))
        self.assertEqual(cc.infer_rule_arg("MEWTWO"), ("sym", "MEWTWO"))


if __name__ == "__main__":
    unittest.main()

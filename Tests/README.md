# Tests

Unit tests, not part of game code. Maintained by senior programmers and run
automatically through GitHub actions, so most team members don't have to worry
about the specifics. If you're interested in learning though, writing your own
tests would save us effort in review!

## Usage

You'll need to install Ruby locally on your PC, separately from the RMXP engine.
Version 3.3 or later is required, 4.0 is recommended. The easiest way to install
Ruby on Windows is from RubyInstaller.org.

To set up tests and linting for the first time, open a command prompt in the
Tectonic folder (or use the integrated terminal in VS Code, etc.) and type
`bundle install`.

To run every test, run `bundle exec minitest Tests`. To run one test file,
`bundle exec minitest "Tests/[path]_test.rb"`.

To make lint warnings appear in VS Code, install the "Ruby LSP" plugin by
Shopify. To automatically fix safe lint errors in a particular file, run
`rubocop -A "Plugins/Path/To/File.rb"`.

## Standards

We're adding linting and testing to a codebase that's existed without them for a
long time. As such, we can't expect to bring the whole thing up to these new
standards all at once.

For old files, LunaFlare will apply lint rules for every file in a PR she
reviews or makes, and add tests where she can. Over time this should work
through the backlog. Do not run `rubocop -A` on the entire codebase - this will
bury you in an avalanche of changes.

For new changes, PRs will automatically receive a comment reporting test
coverage and lint status. This is only advisory - you do not have to write your
own tests. However, if you can get Ruby LSP installed, it would be nice if you
can tackle lint errors as they come, and if your change breaks a test that was
working before, that might point to an issue in your PR before anyone else has
to look at it (though sometimes it's intentionally changed behaviour and the
test needs updating).

## Layout

Tests are organised as mirrors to plugins. For example, a test that covers the
code in `Plugins/Chasm MoveDex/Entry/MoveDex_Entry_Scene.rb` should be found in
`Tests/Chasm MoveDex/Entry/MoveDex_Entry_Scene_test.rb`

`Tests/support` contains the scripts that help these tests run, and
`Tests/Harness` contains the tests _for_ those scripts. `Tests/Lint` tests our
custom lint rules.

Test files `require` the harness through a relative path to
`support/test_helper`.

## Test template

```ruby
require_relative "../../support/test_helper"

class MoveDexEntrySceneTest < Minitest::Test
    def test_something
        assert_equal 4, 2 + 2
    end
end
```

## Using game code

If your tests rely on game code from another file, add it to the `PLUGIN_FILES`
list in `Tests/support/plugin_files.rb`.

If the code you're testing relies on Essentials internals, either add a simple
fake version of that function to the appropriate stub file under
`Tests/support/`, or to load the real version, add its name to the
`CORE_SCRIPTS` list in `plugin_files.rb`.

Tests don't read the game's PBS data. Each test registers the records it needs,
types included, with the helpers in `Tests/support/record_factories.rb`:

```ruby
create_type(id: :FIRE, weaknesses: [:WATER])
create_move(id: :EMBER, type: :FIRE, base_damage: 40)
```

Give each record an `id` and whatever fields the code you're testing reads; the
rest get defaults. Everything a test registers is gone before the next test.

For battle code, the `TestBattler` and `TestBattle` classes let you set up
simple battle state, specifying only what you need. `make_move` creates a test
move object instead of only a test PBS record.

```ruby
target = TestBattler.new(hp: 50, totalhp: 100)
battle = TestBattle.new(battlers: [target])
quash = make_move(PokeBattle_Move_TargetActsLast, battle: battle)
```

If you're testing something that needs images (e.g. UI), you can use
`GraphicsFolder.with` to fake it. It can also create fake image files with given
names as a test needs.

```ruby
def run(...)
    GraphicsFolder.with("Graphics/Faces/Val" => [768, 512]) { super }
end
```

import QtTest
import "../models/ConfigModel.js" as ConfigModel

TestCase {
    name: "ConfigModel"

    function test_supportedVersion() {
        verify(ConfigModel.isSupportedVersion(1))
        verify(!ConfigModel.isSupportedVersion(2))
    }

    function test_missingOptionalSectionsUseDefaults() {
        var result = ConfigModel.normalizeConfig({ version: 1 })
        verify(result.valid)
        compare(result.value.position, "bottom")
        compare(result.value.appearance.iconSize, 28)
        compare(result.value.behavior.hideMode, "smart")
    }

    function test_theDockIsOnUnlessTheConfigurationSaysOtherwise() {
        compare(ConfigModel.defaultConfig().enabled, true)
        compare(ConfigModel.normalizeConfig({ version: 1 }).value.enabled, true)

        var off = ConfigModel.normalizeConfig({ version: 1, enabled: false })
        verify(off.valid)
        compare(off.value.enabled, false)
        compare(off.warnings.length, 0)
    }

    function test_aNonBooleanEnabledLeavesTheDockOn() {
        var result = ConfigModel.normalizeConfig({ version: 1, enabled: "no" })
        verify(result.valid)
        compare(result.value.enabled, true)
        compare(result.warnings.length, 1)
        compare(result.warnings[0], "config.enabled was reset to its default")
    }

    // A key missing from mergeKnownSettings is dropped from the file the next
    // time anything is written, so a dock switched off from the panel would
    // switch itself back on at the next save.
    function test_enabledSurvivesAWriteBack() {
        var off = { version: 1, enabled: false }
        compare(ConfigModel.mergeKnownSettings(off, ConfigModel.normalizeConfig(off).value).enabled, false)

        var bare = { version: 1 }
        compare(ConfigModel.mergeKnownSettings(bare, ConfigModel.normalizeConfig(bare).value).enabled, true)
    }

    function test_invalidVersionIsRejected() {
        var result = ConfigModel.normalizeConfig({ version: 2 })
        verify(!result.valid)
        compare(result.value.version, 1)
    }

    function test_numericValuesAreClamped() {
        var result = ConfigModel.normalizeConfig({
            version: 1,
            appearance: {
                iconSize: 100,
                itemSize: 1,
                gap: -4,
                edgeMargin: 100,
                backgroundOpacity: 0
            },
            behavior: {
                animationMs: 900
            }
        })
        compare(result.value.appearance.iconSize, 42)
        compare(result.value.appearance.itemSize, 50)
        compare(result.value.appearance.gap, 0)
        compare(result.value.appearance.edgeMargin, 32)
        compare(result.value.appearance.backgroundOpacity, 0.35)
        compare(result.value.behavior.animationMs, 500)
    }

    function test_pinsAreDeduplicatedAndUnknownKeysSurvive() {
        var source = {
            version: 1,
            futureOption: { enabled: true },
            pinned: [
                { desktopId: "Example.App.desktop" },
                { desktopId: "example.app" },
                { desktopId: "" }
            ]
        }
        var result = ConfigModel.normalizeConfig(source)
        var merged = ConfigModel.mergeKnownSettings(source, result.value)
        compare(result.value.pinned.length, 1)
        compare(result.value.pinned[0].desktopId, "Example.App.desktop")
        verify(merged.futureOption.enabled)
    }

    function test_insertPinnedUsesClampedIndexAndRejectsDuplicates() {
        var pins = [{ desktopId: "one" }, { desktopId: "three" }]
        var inserted = ConfigModel.insertPinned(pins, "two.desktop", 1)
        compare(inserted.length, 3)
        compare(inserted[1].desktopId, "two.desktop")

        var duplicate = ConfigModel.insertPinned(inserted, "TWO", 0)
        verify(ConfigModel.samePinnedOrder(inserted, duplicate))
        compare(pins.length, 2)
    }

    function test_reorderPinnedAllowsEndInsertionWithoutMutatingInput() {
        var pins = [{ desktopId: "one" }, { desktopId: "two" }, { desktopId: "three" }]
        var reordered = ConfigModel.reorderPinned(pins, 0, 3)
        compare(reordered[0].desktopId, "two")
        compare(reordered[2].desktopId, "one")
        compare(pins[0].desktopId, "one")
        verify(ConfigModel.reorderPinned(pins, 3, 0) === null)
    }
}

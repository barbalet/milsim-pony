#include "GameCore.h"

#include <math.h>
#include <stdio.h>

static GameThreatObserver makeObserver(void) {
    GameThreatObserver observer = {0};
    observer.positionX = 0.0f;
    observer.positionY = 1.65f;
    observer.positionZ = -10.0f;
    observer.yawDegrees = 180.0f;
    observer.pitchDegrees = 0.0f;
    observer.range = 80.0f;
    observer.fieldOfViewDegrees = 90.0f;
    observer.suspicionPerSecond = 0.5f;
    observer.groupIndex = 1;
    observer.groupRelayRangeMeters = 20.0f;
    observer.alertMemorySeconds = 4.0f;
    observer.alertedFieldOfViewDegrees = 120.0f;
    return observer;
}

static GameFrameSnapshot runDifficulty(GameDifficultyTuning tuning) {
    GameCoreBootstrap("cycle119-regression");
    GameCoreConfigureSpawn(0.0f, 1.65f, 0.0f, 180.0f, 0.0f);
    GameThreatObserver observer = makeObserver();
    GameCoreConfigureDetection(&observer, 1, 0.05f, 1.0f);
    GameCoreConfigureDifficulty(tuning);
    GameCoreTick(0.5);
    return GameCoreGetSnapshot();
}

static int verifyPressurePresetRaisesSuspicion(void) {
    GameDifficultyTuning baseline = {1.0f, 1.0f, 1.0f, 1.0f};
    GameDifficultyTuning pressure = {1.34f, 0.72f, 0.78f, 1.18f};
    GameFrameSnapshot baselineSnapshot = runDifficulty(baseline);
    GameFrameSnapshot pressureSnapshot = runDifficulty(pressure);

    if (!(pressureSnapshot.suspicionLevel > baselineSnapshot.suspicionLevel)) {
        fprintf(
            stderr,
            "cycle119_pressure_failed baseline=%.3f pressure=%.3f\n",
            baselineSnapshot.suspicionLevel,
            pressureSnapshot.suspicionLevel
        );
        return 1;
    }

    if (!(pressureSnapshot.weaponCycleSeconds > baselineSnapshot.weaponCycleSeconds)) {
        fprintf(
            stderr,
            "cycle119_weapon_cycle_failed baseline=%.3f pressure=%.3f\n",
            baselineSnapshot.weaponCycleSeconds,
            pressureSnapshot.weaponCycleSeconds
        );
        return 1;
    }

    return 0;
}

static int verifyScriptedFailureHook(void) {
    GameDifficultyTuning baseline = {1.0f, 1.0f, 1.0f, 1.0f};
    GameFrameSnapshot before = runDifficulty(baseline);
    GameCoreForceRouteFailure();
    GameFrameSnapshot after = GameCoreGetSnapshot();

    if (!after.routeFailed || after.failCount <= before.failCount) {
        fprintf(
            stderr,
            "cycle122_force_failure_failed before=%d after=%d failed=%d\n",
            before.failCount,
            after.failCount,
            after.routeFailed ? 1 : 0
        );
        return 1;
    }

    return 0;
}

int main(void) {
    int failures = 0;
    failures += verifyPressurePresetRaisesSuspicion();
    failures += verifyScriptedFailureHook();

    if (failures == 0) {
        puts("cycle119_122_regression_passed");
    }

    return failures == 0 ? 0 : 1;
}

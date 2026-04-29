#include "include/GameCore.h"

#include <math.h>
#include <stdio.h>
#include <string.h>

#define GAME_CORE_MAX_SECTORS 32
#define GAME_CORE_MAX_COLLISION_VOLUMES 256
#define GAME_CORE_MAX_GROUND_SURFACES 2048
#define GAME_CORE_MAX_ROUTE_CHECKPOINTS 16
#define GAME_CORE_MAX_THREAT_OBSERVERS 16
#define GAME_CORE_MAX_TICK_DELTA_SECONDS 0.25f
#define GAME_CORE_MAX_SIMULATION_STEP_SECONDS (1.0f / 60.0f)
#define GAME_CORE_MAX_MOVEMENT_STEP_DISTANCE 0.05f
#define GAME_CORE_LOS_SAMPLE_SPACING_METERS 0.10f
#define GAME_CORE_MAX_LOS_SAMPLES 256
#define GAME_CORE_BALLISTIC_SAMPLE_SPACING_METERS 0.50f
#define GAME_CORE_NPC_PROGRESS_EPSILON_METERS 0.05f
#define GAME_CORE_NPC_STUCK_TIMEOUT_SECONDS 6.0f
#define GAME_CORE_DEFAULT_BALLISTIC_MUZZLE_VELOCITY 820.0f
#define GAME_CORE_DEFAULT_BALLISTIC_GRAVITY 9.81f
#define GAME_CORE_DEFAULT_BALLISTIC_MAX_TIME_SECONDS 2.4f
#define GAME_CORE_DEFAULT_BALLISTIC_STEP_SECONDS (1.0f / 120.0f)
#define GAME_CORE_DEFAULT_SCOPED_SPREAD_DEGREES 0.10f
#define GAME_CORE_DEFAULT_HIP_SPREAD_DEGREES 0.65f
#define GAME_CORE_DEFAULT_MOVEMENT_SPREAD_DEGREES 1.10f
#define GAME_CORE_DEFAULT_SPRINT_SPREAD_DEGREES 1.80f
#define GAME_CORE_DEFAULT_SCOPE_SETTLE_SECONDS 0.60f
#define GAME_CORE_DEFAULT_BREATH_CYCLE_SECONDS 3.40f
#define GAME_CORE_DEFAULT_BREATH_AMPLITUDE_DEGREES 0.16f
#define GAME_CORE_DEFAULT_HOLD_BREATH_DURATION_SECONDS 2.60f
#define GAME_CORE_DEFAULT_HOLD_BREATH_RECOVERY_SECONDS 3.60f
#define GAME_CORE_DEFAULT_WEAPON_CYCLE_SECONDS 0.85f
#define GAME_CORE_DEFAULT_WEAPON_RECOIL_PITCH_DEGREES 0.9f
#define GAME_CORE_DEFAULT_WEAPON_RECOIL_YAW_DEGREES 0.24f
#define GAME_CORE_DEFAULT_OBSERVER_ALERT_MEMORY_SECONDS 2.40f
#define GAME_CORE_DEFAULT_OBSERVER_ALERTED_FOV_DEGREES 74.0f
#define GAME_CORE_DEFAULT_OBSERVER_TURN_RATE_DEGREES_PER_SECOND 78.0f
#define GAME_CORE_DEFAULT_OBSERVER_GROUP_RELAY_RANGE_METERS 28.0f
#define GAME_CORE_DEFAULT_OBSERVER_SCAN_ARC_DEGREES 28.0f
#define GAME_CORE_DEFAULT_OBSERVER_SCAN_CYCLE_SECONDS 5.2f
#define GAME_CORE_OBSERVER_TARGET_HORIZONTAL_RADIUS 0.55f
#define GAME_CORE_OBSERVER_TARGET_LOWER_OFFSET 1.30f
#define GAME_CORE_OBSERVER_TARGET_UPPER_OFFSET 0.40f

typedef struct GameResolvedWeaponAim {
    float stability;
    float spreadDegrees;
    float yawOffsetDegrees;
    float pitchOffsetDegrees;
    float holdBreathSecondsRemaining;
    bool steadyActive;
} GameResolvedWeaponAim;

typedef struct GameCoreState {
    double elapsedSeconds;
    float strafeIntent;
    float forwardIntent;
    float yawDegrees;
    float pitchDegrees;
    float cameraX;
    float cameraY;
    float cameraZ;
    float spawnX;
    float spawnY;
    float spawnZ;
    float spawnYawDegrees;
    float spawnPitchDegrees;
    float moveSpeed;
    float walkSpeed;
    float sprintSpeed;
    float lookSensitivity;
    float eyeHeight;
    float playerRadius;
    float groundHeight;
    float routeDistanceMeters;
    float distanceToNextCheckpointMeters;
    float suspicionLevel;
    float suspicionDecayPerSecond;
    float failThreshold;
    float ballisticMuzzleVelocityMetersPerSecond;
    float ballisticGravityMetersPerSecondSquared;
    float ballisticMaxSimulationTimeSeconds;
    float ballisticSimulationStepSeconds;
    float ballisticLaunchHeightOffsetMeters;
    float weaponScopedSpreadDegrees;
    float weaponHipSpreadDegrees;
    float weaponMovementSpreadDegrees;
    float weaponSprintSpreadDegrees;
    float weaponSettleDurationSeconds;
    float weaponBreathCycleSeconds;
    float weaponBreathAmplitudeDegrees;
    float weaponHoldBreathDurationSeconds;
    float weaponHoldBreathRecoverySeconds;
    float weaponCycleSeconds;
    float weaponCooldownSeconds;
    float weaponScopeSettleSecondsRemaining;
    float weaponHoldBreathSecondsRemaining;
    float weaponHoldBreathCooldownSeconds;
    float lastShotTravelDistanceMeters;
    float lastShotFlightTimeSeconds;
    float lastShotDropMeters;
    float lastShotObserverDistanceMeters;
    double lastShotElapsedSeconds;
    int activeSectorCount;
    int completedCheckpointCount;
    int activeObserverCount;
    int alertedObserverCount;
    int seeingObserverCount;
    int neutralizedObserverCount;
    int lastShotObserverIndex;
    int shotCount;
    int restartCount;
    int failCount;
    int lastSimulationStepCount;
    int lastMovementStepCount;
    int lastLineOfSightTestCount;
    int lastLineOfSightSampleCount;
    bool lastShotHitObserver;
    bool lastShotHitGround;
    bool lastShotHitCollisionVolume;
    bool weaponScoped;
    bool weaponSteadyRequested;
    bool sprinting;
    bool grounded;
    bool routeComplete;
    bool routeFailed;
    bool bootstrapped;
    char bootMode[64];
    GameSectorBounds sectors[GAME_CORE_MAX_SECTORS];
    int sectorCount;
    GameCollisionVolume collisionVolumes[GAME_CORE_MAX_COLLISION_VOLUMES];
    int collisionVolumeCount;
    GameGroundSurface groundSurfaces[GAME_CORE_MAX_GROUND_SURFACES];
    int groundSurfaceCount;
    GameRouteCheckpoint routeCheckpoints[GAME_CORE_MAX_ROUTE_CHECKPOINTS];
    int routeCheckpointCount;
    GameThreatObserver authoredThreatObservers[GAME_CORE_MAX_THREAT_OBSERVERS];
    GameThreatObserver threatObservers[GAME_CORE_MAX_THREAT_OBSERVERS];
    bool observerNeutralized[GAME_CORE_MAX_THREAT_OBSERVERS];
    GameObserverDebugState observerDebugStates[GAME_CORE_MAX_THREAT_OBSERVERS];
    float observerAlertSecondsRemaining[GAME_CORE_MAX_THREAT_OBSERVERS];
    float observerAlertTargetX[GAME_CORE_MAX_THREAT_OBSERVERS];
    float observerAlertTargetY[GAME_CORE_MAX_THREAT_OBSERVERS];
    float observerAlertTargetZ[GAME_CORE_MAX_THREAT_OBSERVERS];
    int observerAlertSourceIndex[GAME_CORE_MAX_THREAT_OBSERVERS];
    float observerScanPhaseSeconds[GAME_CORE_MAX_THREAT_OBSERVERS];
    int threatObserverCount;
    float authoredSuspicionDecayPerSecond;
    float authoredFailThreshold;
    float authoredWeaponCycleSeconds;
    GameDifficultyTuning difficultyTuning;
    float respawnX;
    float respawnY;
    float respawnZ;
    float respawnYawDegrees;
    float respawnPitchDegrees;
} GameCoreState;

static GameCoreState gameState = {
    .cameraY = 1.65f,
    .cameraZ = 4.5f,
    .spawnY = 1.65f,
    .spawnZ = 4.5f,
    .pitchDegrees = -12.0f,
    .spawnPitchDegrees = -12.0f,
    .walkSpeed = 4.2f,
    .sprintSpeed = 6.8f,
    .lookSensitivity = 0.08f,
    .eyeHeight = 1.65f,
    .playerRadius = 0.36f,
    .suspicionDecayPerSecond = 0.28f,
    .authoredSuspicionDecayPerSecond = 0.28f,
    .failThreshold = 1.0f,
    .authoredFailThreshold = 1.0f,
    .ballisticMuzzleVelocityMetersPerSecond = GAME_CORE_DEFAULT_BALLISTIC_MUZZLE_VELOCITY,
    .ballisticGravityMetersPerSecondSquared = GAME_CORE_DEFAULT_BALLISTIC_GRAVITY,
    .ballisticMaxSimulationTimeSeconds = GAME_CORE_DEFAULT_BALLISTIC_MAX_TIME_SECONDS,
    .ballisticSimulationStepSeconds = GAME_CORE_DEFAULT_BALLISTIC_STEP_SECONDS,
    .weaponScopedSpreadDegrees = GAME_CORE_DEFAULT_SCOPED_SPREAD_DEGREES,
    .weaponHipSpreadDegrees = GAME_CORE_DEFAULT_HIP_SPREAD_DEGREES,
    .weaponMovementSpreadDegrees = GAME_CORE_DEFAULT_MOVEMENT_SPREAD_DEGREES,
    .weaponSprintSpreadDegrees = GAME_CORE_DEFAULT_SPRINT_SPREAD_DEGREES,
    .weaponSettleDurationSeconds = GAME_CORE_DEFAULT_SCOPE_SETTLE_SECONDS,
    .weaponBreathCycleSeconds = GAME_CORE_DEFAULT_BREATH_CYCLE_SECONDS,
    .weaponBreathAmplitudeDegrees = GAME_CORE_DEFAULT_BREATH_AMPLITUDE_DEGREES,
    .weaponHoldBreathDurationSeconds = GAME_CORE_DEFAULT_HOLD_BREATH_DURATION_SECONDS,
    .weaponHoldBreathRecoverySeconds = GAME_CORE_DEFAULT_HOLD_BREATH_RECOVERY_SECONDS,
    .weaponCycleSeconds = GAME_CORE_DEFAULT_WEAPON_CYCLE_SECONDS,
    .authoredWeaponCycleSeconds = GAME_CORE_DEFAULT_WEAPON_CYCLE_SECONDS,
    .weaponHoldBreathSecondsRemaining = GAME_CORE_DEFAULT_HOLD_BREATH_DURATION_SECONDS,
    .difficultyTuning = {
        .observerSuspicionScale = 1.0f,
        .suspicionDecayScale = 1.0f,
        .failThresholdScale = 1.0f,
        .weaponCycleScale = 1.0f,
    },
    .lastShotElapsedSeconds = -1.0,
    .lastShotObserverIndex = -1,
};

static float GameCoreClamp(float value, float minimum, float maximum) {
    if (value < minimum) {
        return minimum;
    }
    if (value > maximum) {
        return maximum;
    }
    return value;
}

static float GameCoreLerp(float start, float end, float t) {
    return start + ((end - start) * t);
}

static float GameCoreDegreesToRadians(float degrees) {
    return degrees * (float)M_PI / 180.0f;
}

static float GameCoreNormalizeDegrees(float degrees) {
    while (degrees > 180.0f) {
        degrees -= 360.0f;
    }
    while (degrees < -180.0f) {
        degrees += 360.0f;
    }
    return degrees;
}

static float GameCoreAngleDeltaDegrees(float currentDegrees, float targetDegrees) {
    return GameCoreNormalizeDegrees(targetDegrees - currentDegrees);
}

static float GameCoreApproachDegrees(float currentDegrees, float targetDegrees, float maximumStepDegrees) {
    const float deltaDegrees = GameCoreAngleDeltaDegrees(currentDegrees, targetDegrees);

    if (!(maximumStepDegrees > 0.0f)) {
        return GameCoreNormalizeDegrees(currentDegrees);
    }

    if (fabsf(deltaDegrees) <= maximumStepDegrees) {
        return GameCoreNormalizeDegrees(targetDegrees);
    }

    return GameCoreNormalizeDegrees(
        currentDegrees + (deltaDegrees > 0.0f ? maximumStepDegrees : -maximumStepDegrees)
    );
}

static void GameCoreUpdateDetection(double deltaTime);
static void GameCoreApplyDifficultyTuning(void);
static GameResolvedWeaponAim GameCoreResolveWeaponAim(void);

static bool GameCorePointInsideObserverHitVolume(
    const GameThreatObserver *observer,
    float x,
    float y,
    float z
) {
    const float horizontalDeltaX = x - observer->positionX;
    const float horizontalDeltaZ = z - observer->positionZ;
    const float horizontalDistanceSquared = (horizontalDeltaX * horizontalDeltaX) + (horizontalDeltaZ * horizontalDeltaZ);

    if (horizontalDistanceSquared > (GAME_CORE_OBSERVER_TARGET_HORIZONTAL_RADIUS * GAME_CORE_OBSERVER_TARGET_HORIZONTAL_RADIUS)) {
        return false;
    }

    return y >= (observer->positionY - GAME_CORE_OBSERVER_TARGET_LOWER_OFFSET)
        && y <= (observer->positionY + GAME_CORE_OBSERVER_TARGET_UPPER_OFFSET);
}

static void GameCoreResetObserverDebugState(int index) {
    if (index < 0 || index >= GAME_CORE_MAX_THREAT_OBSERVERS) {
        return;
    }

    gameState.observerDebugStates[index] = (GameObserverDebugState){0};
}

static void GameCoreResetAllObserverDebugStates(void) {
    for (int index = 0; index < GAME_CORE_MAX_THREAT_OBSERVERS; index++) {
        GameCoreResetObserverDebugState(index);
    }
}

static void GameCoreResetObserverAlertState(int index) {
    if (index < 0 || index >= GAME_CORE_MAX_THREAT_OBSERVERS) {
        return;
    }

    gameState.observerAlertSecondsRemaining[index] = 0.0f;
    gameState.observerAlertTargetX[index] = 0.0f;
    gameState.observerAlertTargetY[index] = 0.0f;
    gameState.observerAlertTargetZ[index] = 0.0f;
    gameState.observerAlertSourceIndex[index] = -1;
}

static bool GameCoreObserverHasScanBehavior(const GameThreatObserver *observer) {
    if (observer == NULL) {
        return false;
    }

    return observer->groupIndex > 0 || observer->scanArcDegrees > 0.0f;
}

static float GameCoreObserverScanArcDegrees(const GameThreatObserver *observer) {
    if (!GameCoreObserverHasScanBehavior(observer)) {
        return 0.0f;
    }

    const float authoredArc = observer->scanArcDegrees > 0.0f
        ? observer->scanArcDegrees
        : GAME_CORE_DEFAULT_OBSERVER_SCAN_ARC_DEGREES;
    return GameCoreClamp(authoredArc, 0.0f, 90.0f);
}

static float GameCoreObserverScanCycleSeconds(const GameThreatObserver *observer) {
    if (!GameCoreObserverHasScanBehavior(observer)) {
        return 0.0f;
    }

    const float authoredCycle = observer->scanCycleSeconds > 0.0f
        ? observer->scanCycleSeconds
        : GAME_CORE_DEFAULT_OBSERVER_SCAN_CYCLE_SECONDS;
    return GameCoreClamp(authoredCycle, 1.2f, 20.0f);
}

static float GameCoreObserverPatrolCycleSeconds(const GameThreatObserver *observer) {
    if (observer == NULL || !observer->patrolEnabled || !(observer->patrolStrideMeters > 0.0f)) {
        return 0.0f;
    }

    const float authoredCycle = observer->patrolCycleSeconds > 0.0f
        ? observer->patrolCycleSeconds
        : (GameCoreObserverScanCycleSeconds(observer) * 2.0f);
    return GameCoreClamp(authoredCycle, 3.0f, 30.0f);
}

static float GameCoreObserverPatrolOffsetMeters(int observerIndex) {
    if (observerIndex < 0 || observerIndex >= gameState.threatObserverCount) {
        return 0.0f;
    }

    const GameThreatObserver *observer = &gameState.threatObservers[observerIndex];
    const GameThreatObserver *authoredObserver = &gameState.authoredThreatObservers[observerIndex];
    const float yawRadians = GameCoreDegreesToRadians(authoredObserver->yawDegrees);
    const float forwardX = sinf(yawRadians);
    const float forwardZ = -cosf(yawRadians);
    const float deltaX = observer->positionX - authoredObserver->positionX;
    const float deltaZ = observer->positionZ - authoredObserver->positionZ;
    return (deltaX * forwardX) + (deltaZ * forwardZ);
}

static bool GameCoreObserverPatrolMoving(int observerIndex) {
    if (observerIndex < 0 || observerIndex >= gameState.threatObserverCount) {
        return false;
    }

    const GameThreatObserver *observer = &gameState.threatObservers[observerIndex];
    const bool alerted = gameState.observerAlertSecondsRemaining[observerIndex] > 0.001f;
    return observer->patrolEnabled
        && observer->patrolStrideMeters > 0.0f
        && GameCoreObserverPatrolCycleSeconds(observer) > 0.0f
        && !gameState.observerNeutralized[observerIndex]
        && !alerted;
}

static void GameCoreUpdateObserverPatrolPosition(int observerIndex) {
    if (observerIndex < 0 || observerIndex >= gameState.threatObserverCount) {
        return;
    }

    GameThreatObserver *observer = &gameState.threatObservers[observerIndex];
    const GameThreatObserver *authoredObserver = &gameState.authoredThreatObservers[observerIndex];

    if (!GameCoreObserverPatrolMoving(observerIndex)) {
        return;
    }

    const float cycleSeconds = GameCoreObserverPatrolCycleSeconds(observer);
    const float normalizedPhase = (float)fmod(
        (gameState.elapsedSeconds / (double)cycleSeconds)
            + ((double)observer->patrolPhaseOffsetRadians / (2.0 * M_PI)),
        1.0
    );
    const float patrolOffset = sinf(normalizedPhase * 2.0f * (float)M_PI)
        * GameCoreClamp(observer->patrolStrideMeters, 0.0f, 32.0f);
    const float yawRadians = GameCoreDegreesToRadians(authoredObserver->yawDegrees);
    const float forwardX = sinf(yawRadians);
    const float forwardZ = -cosf(yawRadians);

    observer->positionX = authoredObserver->positionX + (forwardX * patrolOffset);
    observer->positionY = authoredObserver->positionY;
    observer->positionZ = authoredObserver->positionZ + (forwardZ * patrolOffset);
}

static void GameCorePrimeObserverAlert(
    int observerIndex,
    int sourceIndex,
    float targetX,
    float targetY,
    float targetZ
) {
    if (observerIndex < 0 || observerIndex >= gameState.threatObserverCount) {
        return;
    }

    if (gameState.observerNeutralized[observerIndex]) {
        GameCoreResetObserverAlertState(observerIndex);
        return;
    }

    const GameThreatObserver *observer = &gameState.threatObservers[observerIndex];
    const float alertMemorySeconds = observer->alertMemorySeconds > 0.0f
        ? observer->alertMemorySeconds
        : GAME_CORE_DEFAULT_OBSERVER_ALERT_MEMORY_SECONDS;

    if (!(alertMemorySeconds > 0.0f)) {
        return;
    }

    gameState.observerAlertSecondsRemaining[observerIndex] = GameCoreClamp(
        fmaxf(gameState.observerAlertSecondsRemaining[observerIndex], alertMemorySeconds),
        0.0f,
        30.0f
    );
    gameState.observerAlertTargetX[observerIndex] = targetX;
    gameState.observerAlertTargetY[observerIndex] = targetY;
    gameState.observerAlertTargetZ[observerIndex] = targetZ;
    gameState.observerAlertSourceIndex[observerIndex] = sourceIndex >= 0 ? sourceIndex : observerIndex;
}

static void GameCoreUpdateObserverFacing(int observerIndex, float deltaTime) {
    if (observerIndex < 0 || observerIndex >= gameState.threatObserverCount) {
        return;
    }

    GameThreatObserver *observer = &gameState.threatObservers[observerIndex];
    const GameThreatObserver *authoredObserver = &gameState.authoredThreatObservers[observerIndex];
    float targetYawDegrees = authoredObserver->yawDegrees;
    float targetPitchDegrees = authoredObserver->pitchDegrees;
    const bool alerted = gameState.observerAlertSecondsRemaining[observerIndex] > 0.001f;
    const float scanArcDegrees = GameCoreObserverScanArcDegrees(observer);
    const float scanCycleSeconds = GameCoreObserverScanCycleSeconds(observer);

    if (alerted) {
        const float deltaX = gameState.observerAlertTargetX[observerIndex] - observer->positionX;
        const float deltaY = gameState.observerAlertTargetY[observerIndex] - observer->positionY;
        const float deltaZ = gameState.observerAlertTargetZ[observerIndex] - observer->positionZ;
        const float horizontalDistance = sqrtf((deltaX * deltaX) + (deltaZ * deltaZ));

        if (horizontalDistance > 0.001f || fabsf(deltaY) > 0.001f) {
            targetYawDegrees = atan2f(deltaX, -deltaZ) * 180.0f / (float)M_PI;
            targetPitchDegrees = atan2f(deltaY, fmaxf(horizontalDistance, 0.001f)) * 180.0f / (float)M_PI;
        }
    } else if (scanArcDegrees > 0.0f && scanCycleSeconds > 0.0f) {
        if (deltaTime > 0.0f) {
            gameState.observerScanPhaseSeconds[observerIndex] = fmodf(
                gameState.observerScanPhaseSeconds[observerIndex] + deltaTime,
                scanCycleSeconds
            );
            if (gameState.observerScanPhaseSeconds[observerIndex] < 0.0f) {
                gameState.observerScanPhaseSeconds[observerIndex] += scanCycleSeconds;
            }
        }

        const float normalizedPhase = gameState.observerScanPhaseSeconds[observerIndex] / scanCycleSeconds;
        const float sweepOffset = sinf(normalizedPhase * 2.0f * (float)M_PI) * scanArcDegrees;
        targetYawDegrees = authoredObserver->yawDegrees + sweepOffset;
        targetPitchDegrees = authoredObserver->pitchDegrees;
    }

    const float turnRateDegreesPerSecond = observer->turnRateDegreesPerSecond > 0.0f
        ? observer->turnRateDegreesPerSecond
        : GAME_CORE_DEFAULT_OBSERVER_TURN_RATE_DEGREES_PER_SECOND;
    const float maximumYawStep = fmaxf(turnRateDegreesPerSecond * fmaxf(deltaTime, 0.0f), 0.0f);
    const float maximumPitchStep = maximumYawStep * 0.60f;

    observer->yawDegrees = GameCoreApproachDegrees(
        observer->yawDegrees,
        targetYawDegrees,
        maximumYawStep
    );
    observer->pitchDegrees = GameCoreApproachDegrees(
        observer->pitchDegrees,
        GameCoreClamp(targetPitchDegrees, -45.0f, 45.0f),
        maximumPitchStep
    );
}

static void GameCoreRelayObserverAlert(int sourceIndex) {
    if (sourceIndex < 0 || sourceIndex >= gameState.threatObserverCount) {
        return;
    }

    const GameThreatObserver *sourceObserver = &gameState.threatObservers[sourceIndex];
    if (sourceObserver->groupIndex <= 0) {
        return;
    }

    for (int observerIndex = 0; observerIndex < gameState.threatObserverCount; observerIndex++) {
        if (observerIndex == sourceIndex || gameState.observerNeutralized[observerIndex]) {
            continue;
        }

        const GameThreatObserver *observer = &gameState.threatObservers[observerIndex];
        if (observer->groupIndex != sourceObserver->groupIndex) {
            continue;
        }

        const float relayRangeMeters = sourceObserver->groupRelayRangeMeters > 0.0f
            ? sourceObserver->groupRelayRangeMeters
            : (observer->groupRelayRangeMeters > 0.0f
                ? observer->groupRelayRangeMeters
                : GAME_CORE_DEFAULT_OBSERVER_GROUP_RELAY_RANGE_METERS);
        const float deltaX = observer->positionX - sourceObserver->positionX;
        const float deltaY = observer->positionY - sourceObserver->positionY;
        const float deltaZ = observer->positionZ - sourceObserver->positionZ;
        const float distanceSquared = (deltaX * deltaX) + (deltaY * deltaY) + (deltaZ * deltaZ);

        if (distanceSquared > (relayRangeMeters * relayRangeMeters)) {
            continue;
        }

        if (gameState.observerAlertSourceIndex[observerIndex] == observerIndex) {
            continue;
        }

        GameCorePrimeObserverAlert(
            observerIndex,
            sourceIndex,
            gameState.cameraX,
            gameState.cameraY,
            gameState.cameraZ
        );
    }
}

static void GameCoreApplyDifficultyTuning(void) {
    const float observerSuspicionScale = GameCoreClamp(
        gameState.difficultyTuning.observerSuspicionScale,
        0.25f,
        3.0f
    );
    const float suspicionDecayScale = GameCoreClamp(
        gameState.difficultyTuning.suspicionDecayScale,
        0.25f,
        3.0f
    );
    const float failThresholdScale = GameCoreClamp(
        gameState.difficultyTuning.failThresholdScale,
        0.25f,
        3.0f
    );
    const float weaponCycleScale = GameCoreClamp(
        gameState.difficultyTuning.weaponCycleScale,
        0.50f,
        2.5f
    );

    gameState.suspicionDecayPerSecond = GameCoreClamp(
        gameState.authoredSuspicionDecayPerSecond * suspicionDecayScale,
        0.01f,
        10.0f
    );
    gameState.failThreshold = GameCoreClamp(
        gameState.authoredFailThreshold * failThresholdScale,
        0.10f,
        10.0f
    );
    gameState.weaponCycleSeconds = GameCoreClamp(
        gameState.authoredWeaponCycleSeconds * weaponCycleScale,
        0.18f,
        6.0f
    );
    if (gameState.weaponCooldownSeconds > gameState.weaponCycleSeconds) {
        gameState.weaponCooldownSeconds = gameState.weaponCycleSeconds;
    }

    for (int index = 0; index < gameState.threatObserverCount; index++) {
        gameState.threatObservers[index] = gameState.authoredThreatObservers[index];
        gameState.threatObservers[index].suspicionPerSecond = GameCoreClamp(
            gameState.authoredThreatObservers[index].suspicionPerSecond * observerSuspicionScale,
            0.0f,
            25.0f
        );
    }

    gameState.suspicionLevel = GameCoreClamp(
        gameState.suspicionLevel,
        0.0f,
        gameState.failThreshold
    );
}

static void GameCoreResetProfilingCounters(void) {
    gameState.lastSimulationStepCount = 0;
    gameState.lastMovementStepCount = 0;
    gameState.lastLineOfSightTestCount = 0;
    gameState.lastLineOfSightSampleCount = 0;
}

static void GameCoreRotateIntoLocalFrame(float x, float z, float yawDegrees, float *localX, float *localZ) {
    const float radians = (-yawDegrees) * (float)M_PI / 180.0f;
    const float cosine = cosf(radians);
    const float sine = sinf(radians);
    *localX = (x * cosine) - (z * sine);
    *localZ = (x * sine) + (z * cosine);
}

static float GameCoreSampleGroundHeight(float x, float z, float fallbackHeight, bool *foundSurface) {
    float highestHeight = fallbackHeight;
    bool found = false;

    for (int index = 0; index < gameState.groundSurfaceCount; index++) {
        const GameGroundSurface *surface = &gameState.groundSurfaces[index];
        float localX = 0;
        float localZ = 0;

        GameCoreRotateIntoLocalFrame(
            x - surface->centerX,
            z - surface->centerZ,
            surface->yawDegrees,
            &localX,
            &localZ
        );

        if (fabsf(localX) > surface->halfWidth || fabsf(localZ) > surface->halfDepth) {
            continue;
        }

        {
            const float u = surface->halfWidth > 0 ? (localX + surface->halfWidth) / (surface->halfWidth * 2.0f) : 0.5f;
            const float v = surface->halfDepth > 0 ? (localZ + surface->halfDepth) / (surface->halfDepth * 2.0f) : 0.5f;
            const float northHeight = GameCoreLerp(surface->northWestHeight, surface->northEastHeight, u);
            const float southHeight = GameCoreLerp(surface->southWestHeight, surface->southEastHeight, u);
            const float sampledHeight = GameCoreLerp(northHeight, southHeight, v);

            if (!found || sampledHeight > highestHeight) {
                highestHeight = sampledHeight;
                found = true;
            }
        }
    }

    if (foundSurface != NULL) {
        *foundSurface = found;
    }

    return highestHeight;
}

static bool GameCorePointInsideCollisionVolume(
    const GameCollisionVolume *volume,
    float x,
    float y,
    float z,
    float horizontalPadding
) {
    const float minY = volume->centerY - volume->halfHeight;
    const float maxY = volume->centerY + volume->halfHeight;
    float localX = 0;
    float localZ = 0;

    if (volume == NULL || y < minY || y > maxY) {
        return false;
    }

    GameCoreRotateIntoLocalFrame(
        x - volume->centerX,
        z - volume->centerZ,
        volume->yawDegrees,
        &localX,
        &localZ
    );

    return fabsf(localX) <= (volume->halfWidth + horizontalPadding) &&
        fabsf(localZ) <= (volume->halfDepth + horizontalPadding);
}

static bool GameCoreWouldCollideWithRadius(float x, float z, float groundHeight, float radius, float eyeHeightOffset) {
    const float eyeHeight = groundHeight + eyeHeightOffset;

    for (int index = 0; index < gameState.collisionVolumeCount; index++) {
        const GameCollisionVolume *volume = &gameState.collisionVolumes[index];
        const float minY = volume->centerY - volume->halfHeight;
        const float maxY = volume->centerY + volume->halfHeight;
        float localX = 0;
        float localZ = 0;

        if (groundHeight > maxY || eyeHeight < minY) {
            continue;
        }

        GameCoreRotateIntoLocalFrame(x - volume->centerX, z - volume->centerZ, volume->yawDegrees, &localX, &localZ);

        if (fabsf(localX) <= (volume->halfWidth + radius) && fabsf(localZ) <= (volume->halfDepth + radius)) {
            return true;
        }
    }

    return false;
}

static float GameCoreMoveBodyAlongVector(
    float *positionX,
    float *positionZ,
    float *groundHeight,
    float worldMoveX,
    float worldMoveZ,
    float travelDistance,
    float radius,
    float eyeHeightOffset
) {
    float movedDistance = 0;
    const float magnitude = sqrtf((worldMoveX * worldMoveX) + (worldMoveZ * worldMoveZ));

    if (!(travelDistance > 0.0f) || !(magnitude > 0.0001f)) {
        return 0;
    }

    {
        float normalizedMoveX = worldMoveX / magnitude;
        float normalizedMoveZ = worldMoveZ / magnitude;
        int movementSteps = (int)ceilf(travelDistance / GAME_CORE_MAX_MOVEMENT_STEP_DISTANCE);

        if (movementSteps < 1) {
            movementSteps = 1;
        }

        {
            const float stepMoveX = (normalizedMoveX * travelDistance) / (float)movementSteps;
            const float stepMoveZ = (normalizedMoveZ * travelDistance) / (float)movementSteps;

            gameState.lastMovementStepCount += movementSteps;

            for (int movementStep = 0; movementStep < movementSteps; movementStep++) {
                float nextX = *positionX + stepMoveX;
                float nextZ = *positionZ;
                float candidateGroundHeight = GameCoreSampleGroundHeight(nextX, nextZ, *groundHeight, NULL);
                const float beforeX = *positionX;
                const float beforeZ = *positionZ;

                if (!GameCoreWouldCollideWithRadius(nextX, nextZ, candidateGroundHeight, radius, eyeHeightOffset)) {
                    *positionX = nextX;
                    *groundHeight = candidateGroundHeight;
                }

                nextX = *positionX;
                nextZ = *positionZ + stepMoveZ;
                candidateGroundHeight = GameCoreSampleGroundHeight(nextX, nextZ, *groundHeight, NULL);

                if (!GameCoreWouldCollideWithRadius(nextX, nextZ, candidateGroundHeight, radius, eyeHeightOffset)) {
                    *positionZ = nextZ;
                    *groundHeight = candidateGroundHeight;
                }

                {
                    const float deltaX = *positionX - beforeX;
                    const float deltaZ = *positionZ - beforeZ;
                    movedDistance += sqrtf((deltaX * deltaX) + (deltaZ * deltaZ));
                }
            }
        }
    }

    return movedDistance;
}

static GameResolvedWeaponAim GameCoreResolveWeaponAim(void) {
    GameResolvedWeaponAim aim = {0};
    const float moveIntentMagnitude = GameCoreClamp(
        sqrtf((gameState.strafeIntent * gameState.strafeIntent) + (gameState.forwardIntent * gameState.forwardIntent)),
        0.0f,
        1.0f
    );
    const float settleFactor = gameState.weaponScoped && gameState.weaponSettleDurationSeconds > 0.0f
        ? 1.0f - (gameState.weaponScopeSettleSecondsRemaining / gameState.weaponSettleDurationSeconds)
        : 1.0f;
    const bool steadyAvailable = gameState.weaponHoldBreathCooldownSeconds <= 0.0001f
        && gameState.weaponHoldBreathSecondsRemaining > 0.02f;
    const bool steadyActive = gameState.weaponScoped
        && gameState.weaponSteadyRequested
        && !gameState.sprinting
        && steadyAvailable;
    const float baseSpread = gameState.weaponScoped
        ? gameState.weaponScopedSpreadDegrees
        : gameState.weaponHipSpreadDegrees;
    const float movementSpread = moveIntentMagnitude * gameState.weaponMovementSpreadDegrees;
    const float sprintSpread = gameState.sprinting ? gameState.weaponSprintSpreadDegrees : 0.0f;
    const float settleSpread = gameState.weaponScoped
        ? (1.0f - GameCoreClamp(settleFactor, 0.0f, 1.0f)) * (gameState.weaponMovementSpreadDegrees * 0.45f)
        : 0.0f;
    const float breathCycleSeconds = gameState.weaponBreathCycleSeconds > 0.01f
        ? gameState.weaponBreathCycleSeconds
        : GAME_CORE_DEFAULT_BREATH_CYCLE_SECONDS;
    const float breathPhase = (float)fmod(gameState.elapsedSeconds, breathCycleSeconds) / breathCycleSeconds;
    float spreadDegrees = baseSpread + movementSpread + sprintSpread + settleSpread;
    float breathAmplitude = gameState.weaponBreathAmplitudeDegrees > 0.0f
        ? gameState.weaponBreathAmplitudeDegrees
        : GAME_CORE_DEFAULT_BREATH_AMPLITUDE_DEGREES;

    if (gameState.weaponScoped) {
        breathAmplitude *= GameCoreLerp(1.70f, 1.0f, GameCoreClamp(settleFactor, 0.0f, 1.0f));
    } else {
        breathAmplitude *= 0.55f;
    }

    breathAmplitude += movementSpread * 0.12f;
    if (steadyActive) {
        breathAmplitude *= 0.24f;
        spreadDegrees *= 0.72f;
    }

    if (spreadDegrees < baseSpread) {
        spreadDegrees = baseSpread;
    }

    {
        const float maxSpread = baseSpread + gameState.weaponMovementSpreadDegrees + gameState.weaponSprintSpreadDegrees + (gameState.weaponBreathAmplitudeDegrees * 1.2f);
        const float spreadRange = fmaxf(maxSpread - baseSpread, 0.01f);
        aim.stability = GameCoreClamp(1.0f - ((spreadDegrees - baseSpread) / spreadRange), 0.05f, 1.0f);
    }

    aim.spreadDegrees = spreadDegrees;
    aim.yawOffsetDegrees =
        (sinf(breathPhase * (float)M_PI * 2.0f) * breathAmplitude)
        + (sinf((breathPhase * (float)M_PI * 4.4f) + 0.7f) * breathAmplitude * 0.18f);
    aim.pitchOffsetDegrees =
        (cosf((breathPhase * (float)M_PI * 2.0f) + 0.45f) * breathAmplitude * 0.82f)
        + (sinf((breathPhase * (float)M_PI * 3.4f) + 1.1f) * breathAmplitude * 0.12f);
    aim.holdBreathSecondsRemaining = GameCoreClamp(
        gameState.weaponHoldBreathSecondsRemaining,
        0.0f,
        gameState.weaponHoldBreathDurationSeconds > 0.0f
            ? gameState.weaponHoldBreathDurationSeconds
            : GAME_CORE_DEFAULT_HOLD_BREATH_DURATION_SECONDS
    );
    aim.steadyActive = steadyActive;
    return aim;
}

static int GameCoreCountActiveSectors(float x, float z) {
    int activeCount = 0;

    for (int index = 0; index < gameState.sectorCount; index++) {
        const GameSectorBounds *sector = &gameState.sectors[index];
        if (x >= (sector->minX - sector->activationPadding) &&
            x <= (sector->maxX + sector->activationPadding) &&
            z >= (sector->minZ - sector->activationPadding) &&
            z <= (sector->maxZ + sector->activationPadding)) {
            activeCount += 1;
        }
    }

    return activeCount;
}

static void GameCoreRefreshGrounding(void) {
    bool foundSurface = false;
    const float fallbackHeight = gameState.spawnY - gameState.eyeHeight;
    gameState.groundHeight = GameCoreSampleGroundHeight(
        gameState.cameraX,
        gameState.cameraZ,
        fallbackHeight,
        &foundSurface
    );
    gameState.grounded = foundSurface;
    gameState.cameraY = gameState.groundHeight + gameState.eyeHeight;
    gameState.activeSectorCount = GameCoreCountActiveSectors(gameState.cameraX, gameState.cameraZ);
}

static void GameCoreRefreshNPCGrounding(GameNPCState *npc, float fallbackHeight) {
    bool foundSurface = false;

    if (npc == NULL) {
        return;
    }

    npc->groundHeight = GameCoreSampleGroundHeight(
        npc->positionX,
        npc->positionZ,
        fallbackHeight,
        &foundSurface
    );
    npc->grounded = foundSurface;
    npc->positionY = npc->groundHeight + npc->eyeHeight;
}

static void GameCoreUpdateRespawnAnchorForProgress(void) {
    if (gameState.completedCheckpointCount <= 0 || gameState.routeCheckpointCount <= 0) {
        gameState.respawnX = gameState.spawnX;
        gameState.respawnY = gameState.spawnY;
        gameState.respawnZ = gameState.spawnZ;
        gameState.respawnYawDegrees = gameState.spawnYawDegrees;
        gameState.respawnPitchDegrees = gameState.spawnPitchDegrees;
        return;
    }

    {
        const int checkpointIndex = gameState.completedCheckpointCount - 1;
        const GameRouteCheckpoint *checkpoint = &gameState.routeCheckpoints[checkpointIndex];
        gameState.respawnX = checkpoint->positionX;
        gameState.respawnY = checkpoint->positionY;
        gameState.respawnZ = checkpoint->positionZ;
        gameState.respawnYawDegrees = checkpoint->yawDegrees;
        gameState.respawnPitchDegrees = checkpoint->pitchDegrees;
    }
}

static void GameCoreResetDetectionState(bool clearFailCount) {
    gameState.suspicionLevel = 0;
    gameState.activeObserverCount = 0;
    gameState.alertedObserverCount = 0;
    gameState.seeingObserverCount = 0;
    gameState.neutralizedObserverCount = 0;
    gameState.lastShotHitObserver = false;
    gameState.lastShotObserverIndex = -1;
    gameState.lastShotObserverDistanceMeters = 0;
    gameState.routeFailed = false;
    memset(gameState.observerNeutralized, 0, sizeof(gameState.observerNeutralized));
    GameCoreResetAllObserverDebugStates();
    for (int index = 0; index < gameState.threatObserverCount; index++) {
        gameState.threatObservers[index].positionX = gameState.authoredThreatObservers[index].positionX;
        gameState.threatObservers[index].positionY = gameState.authoredThreatObservers[index].positionY;
        gameState.threatObservers[index].positionZ = gameState.authoredThreatObservers[index].positionZ;
        gameState.threatObservers[index].yawDegrees = gameState.authoredThreatObservers[index].yawDegrees;
        gameState.threatObservers[index].pitchDegrees = gameState.authoredThreatObservers[index].pitchDegrees;
        const float scanCycleSeconds = GameCoreObserverScanCycleSeconds(&gameState.threatObservers[index]);
        gameState.observerScanPhaseSeconds[index] = fmodf(
            (float)index * 1.7f,
            scanCycleSeconds > 0.0f ? scanCycleSeconds : GAME_CORE_DEFAULT_OBSERVER_SCAN_CYCLE_SECONDS
        );
        GameCoreResetObserverAlertState(index);
    }

    if (clearFailCount) {
        gameState.failCount = 0;
    }
}

static void GameCoreResetRouteProgress(void) {
    gameState.routeDistanceMeters = 0;
    gameState.distanceToNextCheckpointMeters = gameState.routeCheckpointCount > 0 ? 0 : -1;
    gameState.completedCheckpointCount = 0;
    gameState.restartCount = 0;
    gameState.routeComplete = false;
    GameCoreUpdateRespawnAnchorForProgress();
}

static void GameCoreResetRuntimeState(void) {
    gameState.elapsedSeconds = 0;
    gameState.strafeIntent = 0;
    gameState.forwardIntent = 0;
    gameState.moveSpeed = 0;
    gameState.sprinting = false;
    gameState.weaponScoped = false;
    gameState.weaponSteadyRequested = false;
    gameState.weaponCooldownSeconds = 0;
    gameState.weaponScopeSettleSecondsRemaining = 0;
    gameState.weaponHoldBreathCooldownSeconds = 0;
    gameState.weaponHoldBreathSecondsRemaining = gameState.weaponHoldBreathDurationSeconds > 0.0f
        ? gameState.weaponHoldBreathDurationSeconds
        : GAME_CORE_DEFAULT_HOLD_BREATH_DURATION_SECONDS;
    gameState.shotCount = 0;
    gameState.lastShotTravelDistanceMeters = 0;
    gameState.lastShotFlightTimeSeconds = 0;
    gameState.lastShotDropMeters = 0;
    gameState.lastShotObserverDistanceMeters = 0;
    gameState.lastShotElapsedSeconds = -1.0;
    gameState.lastShotObserverIndex = -1;
    gameState.lastShotHitObserver = false;
    gameState.lastShotHitGround = false;
    gameState.lastShotHitCollisionVolume = false;
    gameState.cameraX = gameState.spawnX;
    gameState.cameraZ = gameState.spawnZ;
    gameState.yawDegrees = gameState.spawnYawDegrees;
    gameState.pitchDegrees = gameState.spawnPitchDegrees;
    GameCoreRefreshGrounding();
}

static void GameCoreRestartFromRespawnAnchor(void) {
    gameState.strafeIntent = 0;
    gameState.forwardIntent = 0;
    gameState.moveSpeed = 0;
    gameState.sprinting = false;
    gameState.weaponScoped = false;
    gameState.weaponSteadyRequested = false;
    gameState.weaponCooldownSeconds = 0;
    gameState.weaponScopeSettleSecondsRemaining = 0;
    gameState.weaponHoldBreathCooldownSeconds = 0;
    gameState.weaponHoldBreathSecondsRemaining = gameState.weaponHoldBreathDurationSeconds > 0.0f
        ? gameState.weaponHoldBreathDurationSeconds
        : GAME_CORE_DEFAULT_HOLD_BREATH_DURATION_SECONDS;
    gameState.cameraX = gameState.respawnX;
    gameState.cameraZ = gameState.respawnZ;
    gameState.yawDegrees = gameState.respawnYawDegrees;
    gameState.pitchDegrees = gameState.respawnPitchDegrees;
    GameCoreRefreshGrounding();
}

static void GameCoreUpdateRouteProgress(void) {
    if (gameState.routeFailed) {
        gameState.distanceToNextCheckpointMeters = 0;
        return;
    }

    if (gameState.routeComplete) {
        gameState.distanceToNextCheckpointMeters = 0;
        return;
    }

    if (gameState.routeCheckpointCount <= 0) {
        gameState.distanceToNextCheckpointMeters = -1;
        return;
    }

    {
        const int nextCheckpointIndex = gameState.completedCheckpointCount;
        if (nextCheckpointIndex >= gameState.routeCheckpointCount) {
            gameState.routeComplete = true;
            gameState.distanceToNextCheckpointMeters = 0;
            return;
        }

        const GameRouteCheckpoint *checkpoint = &gameState.routeCheckpoints[nextCheckpointIndex];
        const float deltaX = gameState.cameraX - checkpoint->positionX;
        const float deltaZ = gameState.cameraZ - checkpoint->positionZ;
        const float distance = sqrtf((deltaX * deltaX) + (deltaZ * deltaZ));

        gameState.distanceToNextCheckpointMeters = distance;

        if (distance > checkpoint->triggerRadius) {
            return;
        }

        gameState.completedCheckpointCount += 1;
        if (checkpoint->isGoal || gameState.completedCheckpointCount >= gameState.routeCheckpointCount) {
            gameState.routeComplete = true;
            gameState.distanceToNextCheckpointMeters = 0;
            return;
        }

        GameCoreUpdateRespawnAnchorForProgress();

        {
            const GameRouteCheckpoint *upcomingCheckpoint = &gameState.routeCheckpoints[gameState.completedCheckpointCount];
            const float nextDeltaX = gameState.cameraX - upcomingCheckpoint->positionX;
            const float nextDeltaZ = gameState.cameraZ - upcomingCheckpoint->positionZ;
            gameState.distanceToNextCheckpointMeters = sqrtf(
                (nextDeltaX * nextDeltaX) + (nextDeltaZ * nextDeltaZ)
            );
        }
    }
}

static bool GameCoreHasLineOfSightToPoint(
    float startX,
    float startY,
    float startZ,
    float endX,
    float endY,
    float endZ
) {
    const float deltaX = endX - startX;
    const float deltaY = endY - startY;
    const float deltaZ = endZ - startZ;
    const float distance = sqrtf((deltaX * deltaX) + (deltaY * deltaY) + (deltaZ * deltaZ));
    int sampleCount = (int)ceilf(distance / GAME_CORE_LOS_SAMPLE_SPACING_METERS);

    if (sampleCount < 2) {
        sampleCount = 2;
    } else if (sampleCount > GAME_CORE_MAX_LOS_SAMPLES) {
        sampleCount = GAME_CORE_MAX_LOS_SAMPLES;
    }

    gameState.lastLineOfSightTestCount += 1;
    gameState.lastLineOfSightSampleCount += sampleCount > 1 ? (sampleCount - 1) : 0;

    for (int sample = 1; sample < sampleCount; sample++) {
        const float t = (float)sample / (float)sampleCount;
        const float sampleX = startX + (deltaX * t);
        const float sampleY = startY + (deltaY * t);
        const float sampleZ = startZ + (deltaZ * t);

        for (int index = 0; index < gameState.collisionVolumeCount; index++) {
            const GameCollisionVolume *volume = &gameState.collisionVolumes[index];
            const float minY = volume->centerY - volume->halfHeight;
            const float maxY = volume->centerY + volume->halfHeight;
            float localX = 0;
            float localZ = 0;

            if (sampleY < minY || sampleY > maxY) {
                continue;
            }

            GameCoreRotateIntoLocalFrame(
                sampleX - volume->centerX,
                sampleZ - volume->centerZ,
                volume->yawDegrees,
                &localX,
                &localZ
            );

            if (fabsf(localX) <= volume->halfWidth && fabsf(localZ) <= volume->halfDepth) {
                return false;
            }
        }
    }

    return true;
}

static void GameCoreAdvanceSimulationStep(float deltaTime) {
    const float holdBreathDuration = gameState.weaponHoldBreathDurationSeconds > 0.0f
        ? gameState.weaponHoldBreathDurationSeconds
        : GAME_CORE_DEFAULT_HOLD_BREATH_DURATION_SECONDS;
    const float holdBreathRecovery = gameState.weaponHoldBreathRecoverySeconds > 0.0f
        ? gameState.weaponHoldBreathRecoverySeconds
        : GAME_CORE_DEFAULT_HOLD_BREATH_RECOVERY_SECONDS;
    const float holdBreathRechargeRate = holdBreathDuration / fmaxf(holdBreathRecovery, 0.01f);

    gameState.elapsedSeconds += deltaTime;
    gameState.weaponCooldownSeconds = GameCoreClamp(gameState.weaponCooldownSeconds - deltaTime, 0.0f, gameState.weaponCycleSeconds);
    gameState.weaponScopeSettleSecondsRemaining = GameCoreClamp(
        gameState.weaponScopeSettleSecondsRemaining - deltaTime,
        0.0f,
        gameState.weaponSettleDurationSeconds > 0.0f
            ? gameState.weaponSettleDurationSeconds
            : GAME_CORE_DEFAULT_SCOPE_SETTLE_SECONDS
    );

    if (
        gameState.weaponScoped
        && gameState.weaponSteadyRequested
        && !gameState.sprinting
        && gameState.weaponHoldBreathCooldownSeconds <= 0.0001f
        && gameState.weaponHoldBreathSecondsRemaining > 0.0f
    ) {
        gameState.weaponHoldBreathSecondsRemaining = GameCoreClamp(
            gameState.weaponHoldBreathSecondsRemaining - deltaTime,
            0.0f,
            holdBreathDuration
        );
        if (gameState.weaponHoldBreathSecondsRemaining <= 0.0001f) {
            gameState.weaponHoldBreathCooldownSeconds = holdBreathRecovery;
        }
    } else {
        gameState.weaponHoldBreathCooldownSeconds = GameCoreClamp(
            gameState.weaponHoldBreathCooldownSeconds - deltaTime,
            0.0f,
            holdBreathRecovery
        );
        if (gameState.weaponHoldBreathCooldownSeconds <= 0.0001f) {
            gameState.weaponHoldBreathSecondsRemaining = GameCoreClamp(
                gameState.weaponHoldBreathSecondsRemaining + (holdBreathRechargeRate * deltaTime),
                0.0f,
                holdBreathDuration
            );
        }
    }

    if (gameState.routeFailed) {
        gameState.moveSpeed = 0;
        GameCoreRefreshGrounding();
        GameCoreUpdateDetection(deltaTime);
        return;
    }

    {
        const float baseMoveSpeed = gameState.sprinting ? gameState.sprintSpeed : gameState.walkSpeed;
        float moveX = gameState.strafeIntent;
        float moveZ = gameState.forwardIntent;

        const float magnitude = sqrtf((moveX * moveX) + (moveZ * moveZ));
        if (magnitude > 1.0f) {
            moveX /= magnitude;
            moveZ /= magnitude;
        }

        gameState.moveSpeed = baseMoveSpeed * magnitude;

        if (magnitude > 0.0f) {
            const float yawRadians = gameState.yawDegrees * (float)M_PI / 180.0f;
            const float rightX = cosf(yawRadians);
            const float rightZ = sinf(yawRadians);
            const float forwardX = sinf(yawRadians);
            const float forwardZ = -cosf(yawRadians);
            const float worldMoveX = (rightX * moveX) + (forwardX * moveZ);
            const float worldMoveZ = (rightZ * moveX) + (forwardZ * moveZ);
            GameCoreMoveBodyAlongVector(
                &gameState.cameraX,
                &gameState.cameraZ,
                &gameState.groundHeight,
                worldMoveX,
                worldMoveZ,
                baseMoveSpeed * magnitude * deltaTime,
                gameState.playerRadius,
                gameState.eyeHeight
            );
        }
    }

    GameCoreRefreshGrounding();

    GameCoreUpdateRouteProgress();
    GameCoreUpdateDetection(deltaTime);
}

static void GameCoreForwardVector(float yawDegrees, float pitchDegrees, float *x, float *y, float *z) {
    const float yawRadians = GameCoreDegreesToRadians(yawDegrees);
    const float pitchRadians = GameCoreDegreesToRadians(pitchDegrees);

    if (x != NULL) {
        *x = sinf(yawRadians) * cosf(pitchRadians);
    }
    if (y != NULL) {
        *y = sinf(pitchRadians);
    }
    if (z != NULL) {
        *z = -cosf(yawRadians) * cosf(pitchRadians);
    }
}

static void GameCoreUpdateDetection(double deltaTime) {
    float suspicionDelta = 0;
    const float detectionDeltaTime = (float)fmax(deltaTime, 0.0);

    gameState.activeObserverCount = 0;
    gameState.alertedObserverCount = 0;
    gameState.seeingObserverCount = 0;

    for (int index = 0; index < GAME_CORE_MAX_THREAT_OBSERVERS; index++) {
        GameCoreResetObserverDebugState(index);
    }

    for (int index = 0; index < gameState.threatObserverCount; index++) {
        if (gameState.observerAlertSecondsRemaining[index] > 0.0f && detectionDeltaTime > 0.0f) {
            gameState.observerAlertSecondsRemaining[index] = GameCoreClamp(
                gameState.observerAlertSecondsRemaining[index] - detectionDeltaTime,
                0.0f,
                30.0f
            );
            if (!(gameState.observerAlertSecondsRemaining[index] > 0.001f)) {
                GameCoreResetObserverAlertState(index);
            }
        }

        GameCoreUpdateObserverPatrolPosition(index);
        GameCoreUpdateObserverFacing(index, detectionDeltaTime);

        const GameThreatObserver *observer = &gameState.threatObservers[index];
        const bool alerted = gameState.observerAlertSecondsRemaining[index] > 0.001f;
        const float effectiveFieldOfViewDegrees = alerted
            ? fmaxf(
                observer->fieldOfViewDegrees,
                observer->alertedFieldOfViewDegrees > 0.0f
                    ? observer->alertedFieldOfViewDegrees
                    : GAME_CORE_DEFAULT_OBSERVER_ALERTED_FOV_DEGREES
            )
            : observer->fieldOfViewDegrees;
        const float coneThreshold = cosf(GameCoreDegreesToRadians(effectiveFieldOfViewDegrees * 0.5f));
        const float scanArcDegrees = GameCoreObserverScanArcDegrees(observer);
        const float scanCycleSeconds = GameCoreObserverScanCycleSeconds(observer);

        if (alerted && !gameState.observerNeutralized[index]) {
            gameState.alertedObserverCount += 1;
        }

        gameState.observerDebugStates[index] = (GameObserverDebugState) {
            .positionX = observer->positionX,
            .positionY = observer->positionY,
            .positionZ = observer->positionZ,
            .rangeMeters = observer->range,
            .fieldOfViewDegrees = effectiveFieldOfViewDegrees,
            .yawDegrees = observer->yawDegrees,
            .pitchDegrees = observer->pitchDegrees,
            .viewDot = -1.0f,
            .coneThreshold = coneThreshold,
            .suspicionPerSecond = observer->suspicionPerSecond,
            .alertSecondsRemaining = gameState.observerAlertSecondsRemaining[index],
            .scanArcDegrees = scanArcDegrees,
            .scanCycleSeconds = scanCycleSeconds,
            .scanPhaseSeconds = gameState.observerScanPhaseSeconds[index],
            .patrolOffsetMeters = GameCoreObserverPatrolOffsetMeters(index),
            .neutralized = gameState.observerNeutralized[index],
            .alerted = alerted,
            .supportingGroup = alerted
                && gameState.observerAlertSourceIndex[index] >= 0
                && gameState.observerAlertSourceIndex[index] != index,
            .scanHalted = alerted && scanArcDegrees > 0.0f,
            .patrolMoving = GameCoreObserverPatrolMoving(index),
        };
    }

    if (gameState.routeComplete) {
        gameState.suspicionLevel = GameCoreClamp(
            gameState.suspicionLevel - (gameState.suspicionDecayPerSecond * detectionDeltaTime),
            0,
            gameState.failThreshold > 0 ? gameState.failThreshold : 1.0f
        );
        return;
    }

    for (int index = 0; index < gameState.threatObserverCount; index++) {
        const GameThreatObserver *observer = &gameState.threatObservers[index];
        GameObserverDebugState *debugState = &gameState.observerDebugStates[index];

        if (gameState.observerNeutralized[index]) {
            continue;
        }

        const float deltaX = gameState.cameraX - observer->positionX;
        const float deltaY = gameState.cameraY - observer->positionY;
        const float deltaZ = gameState.cameraZ - observer->positionZ;
        const float distanceSquared = (deltaX * deltaX) + (deltaY * deltaY) + (deltaZ * deltaZ);
        const float rangeSquared = observer->range * observer->range;
        const float distance = sqrtf(distanceSquared);

        debugState->distanceMeters = distance;
        debugState->inRange = distanceSquared <= rangeSquared;
        if (distanceSquared > rangeSquared) {
            continue;
        }

        gameState.activeObserverCount += 1;

        {
            const float yawRadians = GameCoreDegreesToRadians(observer->yawDegrees);
            const float pitchRadians = GameCoreDegreesToRadians(observer->pitchDegrees);
            const float coneThreshold = debugState->coneThreshold;
            const float inverseDistance = distance > 0.0001f ? 1.0f / distance : 0.0f;
            const float toPlayerX = deltaX * inverseDistance;
            const float toPlayerY = deltaY * inverseDistance;
            const float toPlayerZ = deltaZ * inverseDistance;
            const float facingX = sinf(yawRadians) * cosf(pitchRadians);
            const float facingY = sinf(pitchRadians);
            const float facingZ = -cosf(yawRadians) * cosf(pitchRadians);
            const float viewDot = (toPlayerX * facingX) + (toPlayerY * facingY) + (toPlayerZ * facingZ);

            debugState->viewDot = viewDot;
            debugState->inViewCone = viewDot >= coneThreshold;
            if (viewDot < coneThreshold) {
                continue;
            }

            debugState->hasLineOfSight = GameCoreHasLineOfSightToPoint(
                observer->positionX,
                observer->positionY,
                observer->positionZ,
                gameState.cameraX,
                gameState.cameraY,
                gameState.cameraZ
            );
            if (!debugState->hasLineOfSight) {
                continue;
            }

            debugState->seeingPlayer = true;
            gameState.seeingObserverCount += 1;
            GameCorePrimeObserverAlert(
                index,
                index,
                gameState.cameraX,
                gameState.cameraY,
                gameState.cameraZ
            );
            debugState->alertSecondsRemaining = gameState.observerAlertSecondsRemaining[index];
            debugState->alerted = true;
            debugState->supportingGroup = false;
            GameCoreRelayObserverAlert(index);
            suspicionDelta += observer->suspicionPerSecond * detectionDeltaTime;
        }
    }

    if (gameState.routeFailed) {
        return;
    }

    gameState.suspicionLevel = GameCoreClamp(
        gameState.suspicionLevel + suspicionDelta - (gameState.suspicionDecayPerSecond * detectionDeltaTime),
        0,
        gameState.failThreshold > 0 ? gameState.failThreshold : 1.0f
    );

    if (gameState.failThreshold > 0 && gameState.suspicionLevel >= gameState.failThreshold) {
        gameState.routeFailed = true;
        gameState.failCount += 1;
        gameState.moveSpeed = 0;
        gameState.distanceToNextCheckpointMeters = 0;
    }
}

void GameCoreBootstrap(const char *bootMode) {
    memset(&gameState, 0, sizeof(gameState));
    gameState.bootstrapped = true;
    gameState.eyeHeight = 1.65f;
    gameState.playerRadius = 0.36f;
    gameState.spawnY = 1.65f;
    gameState.spawnZ = 4.5f;
    gameState.spawnPitchDegrees = -12.0f;
    gameState.respawnY = 1.65f;
    gameState.respawnZ = 4.5f;
    gameState.respawnPitchDegrees = -12.0f;
    gameState.walkSpeed = 4.2f;
    gameState.sprintSpeed = 6.8f;
    gameState.lookSensitivity = 0.08f;
    gameState.suspicionDecayPerSecond = 0.28f;
    gameState.authoredSuspicionDecayPerSecond = 0.28f;
    gameState.failThreshold = 1.0f;
    gameState.authoredFailThreshold = 1.0f;
    gameState.ballisticMuzzleVelocityMetersPerSecond = GAME_CORE_DEFAULT_BALLISTIC_MUZZLE_VELOCITY;
    gameState.ballisticGravityMetersPerSecondSquared = GAME_CORE_DEFAULT_BALLISTIC_GRAVITY;
    gameState.ballisticMaxSimulationTimeSeconds = GAME_CORE_DEFAULT_BALLISTIC_MAX_TIME_SECONDS;
    gameState.ballisticSimulationStepSeconds = GAME_CORE_DEFAULT_BALLISTIC_STEP_SECONDS;
    gameState.weaponScopedSpreadDegrees = GAME_CORE_DEFAULT_SCOPED_SPREAD_DEGREES;
    gameState.weaponHipSpreadDegrees = GAME_CORE_DEFAULT_HIP_SPREAD_DEGREES;
    gameState.weaponMovementSpreadDegrees = GAME_CORE_DEFAULT_MOVEMENT_SPREAD_DEGREES;
    gameState.weaponSprintSpreadDegrees = GAME_CORE_DEFAULT_SPRINT_SPREAD_DEGREES;
    gameState.weaponSettleDurationSeconds = GAME_CORE_DEFAULT_SCOPE_SETTLE_SECONDS;
    gameState.weaponBreathCycleSeconds = GAME_CORE_DEFAULT_BREATH_CYCLE_SECONDS;
    gameState.weaponBreathAmplitudeDegrees = GAME_CORE_DEFAULT_BREATH_AMPLITUDE_DEGREES;
    gameState.weaponHoldBreathDurationSeconds = GAME_CORE_DEFAULT_HOLD_BREATH_DURATION_SECONDS;
    gameState.weaponHoldBreathRecoverySeconds = GAME_CORE_DEFAULT_HOLD_BREATH_RECOVERY_SECONDS;
    gameState.weaponCycleSeconds = GAME_CORE_DEFAULT_WEAPON_CYCLE_SECONDS;
    gameState.authoredWeaponCycleSeconds = GAME_CORE_DEFAULT_WEAPON_CYCLE_SECONDS;
    gameState.weaponHoldBreathSecondsRemaining = GAME_CORE_DEFAULT_HOLD_BREATH_DURATION_SECONDS;
    gameState.difficultyTuning = (GameDifficultyTuning) {
        .observerSuspicionScale = 1.0f,
        .suspicionDecayScale = 1.0f,
        .failThresholdScale = 1.0f,
        .weaponCycleScale = 1.0f,
    };
    gameState.lastShotElapsedSeconds = -1.0;
    gameState.lastShotObserverIndex = -1;

    if (bootMode != NULL) {
        snprintf(gameState.bootMode, sizeof(gameState.bootMode), "%s", bootMode);
    } else {
        snprintf(gameState.bootMode, sizeof(gameState.bootMode), "bootstrap");
    }

    GameCoreResetDetectionState(true);
    GameCoreResetRouteProgress();
    GameCoreResetRuntimeState();
    GameCoreResetProfilingCounters();
    printf("[GameCore] Bootstrap mode: %s\n", gameState.bootMode);
}

void GameCoreConfigureSpawn(float x, float y, float z, float yawDegrees, float pitchDegrees) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
    }

    gameState.spawnX = x;
    gameState.spawnY = y;
    gameState.spawnZ = z;
    gameState.spawnYawDegrees = yawDegrees;
    gameState.spawnPitchDegrees = pitchDegrees;
    GameCoreResetDetectionState(true);
    GameCoreResetRouteProgress();
    GameCoreResetRuntimeState();
    GameCoreUpdateRouteProgress();
    GameCoreResetProfilingCounters();
    printf("[GameCore] Spawn configured to %.2f %.2f %.2f (yaw %.1f pitch %.1f)\n", x, y, z, yawDegrees, pitchDegrees);
}

void GameCoreConfigureWorld(
    const GameSectorBounds *sectors,
    int sectorCount,
    const GameCollisionVolume *collisionVolumes,
    int collisionVolumeCount,
    const GameGroundSurface *groundSurfaces,
    int groundSurfaceCount
) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
    }

    const int requestedSectorCount = sectorCount;
    const int requestedCollisionVolumeCount = collisionVolumeCount;
    const int requestedGroundSurfaceCount = groundSurfaceCount;

    gameState.sectorCount = sectorCount > GAME_CORE_MAX_SECTORS ? GAME_CORE_MAX_SECTORS : sectorCount;
    gameState.collisionVolumeCount = collisionVolumeCount > GAME_CORE_MAX_COLLISION_VOLUMES
        ? GAME_CORE_MAX_COLLISION_VOLUMES
        : collisionVolumeCount;
    gameState.groundSurfaceCount = groundSurfaceCount > GAME_CORE_MAX_GROUND_SURFACES
        ? GAME_CORE_MAX_GROUND_SURFACES
        : groundSurfaceCount;

    if (sectors != NULL && gameState.sectorCount > 0) {
        memcpy(gameState.sectors, sectors, sizeof(GameSectorBounds) * (size_t)gameState.sectorCount);
    }
    if (collisionVolumes != NULL && gameState.collisionVolumeCount > 0) {
        memcpy(
            gameState.collisionVolumes,
            collisionVolumes,
            sizeof(GameCollisionVolume) * (size_t)gameState.collisionVolumeCount
        );
    }
    if (groundSurfaces != NULL && gameState.groundSurfaceCount > 0) {
        memcpy(
            gameState.groundSurfaces,
            groundSurfaces,
            sizeof(GameGroundSurface) * (size_t)gameState.groundSurfaceCount
        );
    }

    GameCoreRefreshGrounding();
    GameCoreUpdateRouteProgress();
    GameCoreUpdateDetection(0);
    GameCoreResetProfilingCounters();
    if (requestedSectorCount > gameState.sectorCount ||
        requestedCollisionVolumeCount > gameState.collisionVolumeCount ||
        requestedGroundSurfaceCount > gameState.groundSurfaceCount) {
        printf(
            "[GameCore] World data truncated to %d sectors, %d blockers, %d ground surfaces\n",
            gameState.sectorCount,
            gameState.collisionVolumeCount,
            gameState.groundSurfaceCount
        );
    }
    printf(
        "[GameCore] World configured with %d sectors, %d blockers, %d ground surfaces\n",
        gameState.sectorCount,
        gameState.collisionVolumeCount,
        gameState.groundSurfaceCount
    );
}

void GameCoreConfigureRoute(const GameRouteCheckpoint *checkpoints, int checkpointCount) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
    }

    gameState.routeCheckpointCount = checkpointCount > GAME_CORE_MAX_ROUTE_CHECKPOINTS
        ? GAME_CORE_MAX_ROUTE_CHECKPOINTS
        : checkpointCount;

    if (checkpoints != NULL && gameState.routeCheckpointCount > 0) {
        memcpy(
            gameState.routeCheckpoints,
            checkpoints,
            sizeof(GameRouteCheckpoint) * (size_t)gameState.routeCheckpointCount
        );
    }

    GameCoreResetDetectionState(true);
    GameCoreResetRouteProgress();
    GameCoreUpdateRouteProgress();
    GameCoreResetProfilingCounters();
    printf("[GameCore] Route configured with %d checkpoints\n", gameState.routeCheckpointCount);
}

void GameCoreConfigureDetection(
    const GameThreatObserver *observers,
    int observerCount,
    float suspicionDecayPerSecond,
    float failThreshold
) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
    }

    gameState.threatObserverCount = observerCount > GAME_CORE_MAX_THREAT_OBSERVERS
        ? GAME_CORE_MAX_THREAT_OBSERVERS
        : observerCount;
    gameState.authoredSuspicionDecayPerSecond = suspicionDecayPerSecond > 0 ? suspicionDecayPerSecond : 0.28f;
    gameState.authoredFailThreshold = failThreshold > 0 ? failThreshold : 1.0f;
    memset(gameState.authoredThreatObservers, 0, sizeof(gameState.authoredThreatObservers));
    memset(gameState.threatObservers, 0, sizeof(gameState.threatObservers));

    if (observers != NULL && gameState.threatObserverCount > 0) {
        memcpy(
            gameState.authoredThreatObservers,
            observers,
            sizeof(GameThreatObserver) * (size_t)gameState.threatObserverCount
        );
    }

    GameCoreResetDetectionState(true);
    GameCoreApplyDifficultyTuning();
    GameCoreUpdateDetection(0);
    GameCoreResetProfilingCounters();
    printf("[GameCore] Detection configured with %d observers\n", gameState.threatObserverCount);
}

void GameCoreConfigureBallistics(GameBallisticsConfiguration configuration) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
    }

    gameState.ballisticMuzzleVelocityMetersPerSecond = configuration.muzzleVelocityMetersPerSecond > 0.0f
        ? configuration.muzzleVelocityMetersPerSecond
        : GAME_CORE_DEFAULT_BALLISTIC_MUZZLE_VELOCITY;
    gameState.ballisticGravityMetersPerSecondSquared = configuration.gravityMetersPerSecondSquared > 0.0f
        ? configuration.gravityMetersPerSecondSquared
        : GAME_CORE_DEFAULT_BALLISTIC_GRAVITY;
    gameState.ballisticMaxSimulationTimeSeconds = configuration.maxSimulationTimeSeconds > 0.0f
        ? GameCoreClamp(configuration.maxSimulationTimeSeconds, 0.25f, 8.0f)
        : GAME_CORE_DEFAULT_BALLISTIC_MAX_TIME_SECONDS;
    gameState.ballisticSimulationStepSeconds = configuration.simulationStepSeconds > 0.0f
        ? GameCoreClamp(configuration.simulationStepSeconds, (1.0f / 480.0f), 0.05f)
        : GAME_CORE_DEFAULT_BALLISTIC_STEP_SECONDS;
    gameState.ballisticLaunchHeightOffsetMeters = configuration.launchHeightOffsetMeters;
    gameState.weaponScopedSpreadDegrees = configuration.scopedSpreadDegrees > 0.0f
        ? configuration.scopedSpreadDegrees
        : GAME_CORE_DEFAULT_SCOPED_SPREAD_DEGREES;
    gameState.weaponHipSpreadDegrees = configuration.hipSpreadDegrees > 0.0f
        ? configuration.hipSpreadDegrees
        : GAME_CORE_DEFAULT_HIP_SPREAD_DEGREES;
    gameState.weaponMovementSpreadDegrees = configuration.movementSpreadDegrees > 0.0f
        ? configuration.movementSpreadDegrees
        : GAME_CORE_DEFAULT_MOVEMENT_SPREAD_DEGREES;
    gameState.weaponSprintSpreadDegrees = configuration.sprintSpreadDegrees > 0.0f
        ? configuration.sprintSpreadDegrees
        : GAME_CORE_DEFAULT_SPRINT_SPREAD_DEGREES;
    gameState.weaponSettleDurationSeconds = configuration.settleDurationSeconds > 0.0f
        ? configuration.settleDurationSeconds
        : GAME_CORE_DEFAULT_SCOPE_SETTLE_SECONDS;
    gameState.weaponBreathCycleSeconds = configuration.breathCycleSeconds > 0.0f
        ? configuration.breathCycleSeconds
        : GAME_CORE_DEFAULT_BREATH_CYCLE_SECONDS;
    gameState.weaponBreathAmplitudeDegrees = configuration.breathAmplitudeDegrees > 0.0f
        ? configuration.breathAmplitudeDegrees
        : GAME_CORE_DEFAULT_BREATH_AMPLITUDE_DEGREES;
    gameState.weaponHoldBreathDurationSeconds = configuration.holdBreathDurationSeconds > 0.0f
        ? configuration.holdBreathDurationSeconds
        : GAME_CORE_DEFAULT_HOLD_BREATH_DURATION_SECONDS;
    gameState.weaponHoldBreathRecoverySeconds = configuration.holdBreathRecoverySeconds > 0.0f
        ? configuration.holdBreathRecoverySeconds
        : GAME_CORE_DEFAULT_HOLD_BREATH_RECOVERY_SECONDS;
    gameState.weaponHoldBreathSecondsRemaining = GameCoreClamp(
        gameState.weaponHoldBreathSecondsRemaining,
        0.0f,
        gameState.weaponHoldBreathDurationSeconds
    );
    gameState.weaponHoldBreathCooldownSeconds = GameCoreClamp(
        gameState.weaponHoldBreathCooldownSeconds,
        0.0f,
        gameState.weaponHoldBreathRecoverySeconds
    );
    printf(
        "[GameCore] Ballistics tuned to %.0f m/s / %.2f m/s2 / %.2fs / %.4fs step / %+0.2fm launch / %.2f scoped / %.2f hip / %.2f move / %.2f sprint / %.2fs settle / %.2fs breath / %.2fs hold\n",
        gameState.ballisticMuzzleVelocityMetersPerSecond,
        gameState.ballisticGravityMetersPerSecondSquared,
        gameState.ballisticMaxSimulationTimeSeconds,
        gameState.ballisticSimulationStepSeconds,
        gameState.ballisticLaunchHeightOffsetMeters,
        gameState.weaponScopedSpreadDegrees,
        gameState.weaponHipSpreadDegrees,
        gameState.weaponMovementSpreadDegrees,
        gameState.weaponSprintSpreadDegrees,
        gameState.weaponSettleDurationSeconds,
        gameState.weaponBreathCycleSeconds,
        gameState.weaponHoldBreathDurationSeconds
    );
}

void GameCoreConfigureDifficulty(GameDifficultyTuning tuning) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
    }

    gameState.difficultyTuning = (GameDifficultyTuning) {
        .observerSuspicionScale = GameCoreClamp(tuning.observerSuspicionScale, 0.25f, 3.0f),
        .suspicionDecayScale = GameCoreClamp(tuning.suspicionDecayScale, 0.25f, 3.0f),
        .failThresholdScale = GameCoreClamp(tuning.failThresholdScale, 0.25f, 3.0f),
        .weaponCycleScale = GameCoreClamp(tuning.weaponCycleScale, 0.50f, 2.5f),
    };

    GameCoreApplyDifficultyTuning();
    GameCoreUpdateDetection(0);
    GameCoreResetProfilingCounters();
    printf(
        "[GameCore] Difficulty tuning %.2f sus / %.2f decay / %.2f fail / %.2f cycle\n",
        gameState.difficultyTuning.observerSuspicionScale,
        gameState.difficultyTuning.suspicionDecayScale,
        gameState.difficultyTuning.failThresholdScale,
        gameState.difficultyTuning.weaponCycleScale
    );
}

bool GameCoreSampleGroundHeightAt(float x, float z, float fallbackHeight, float *groundHeight) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
    }

    bool foundSurface = false;
    const float sampledHeight = GameCoreSampleGroundHeight(x, z, fallbackHeight, &foundSurface);

    if (groundHeight != NULL) {
        *groundHeight = sampledHeight;
    }

    return foundSurface;
}

bool GameCoreCanOccupyPosition(float x, float z, float groundHeight, float radius) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
    }

    return !GameCoreWouldCollideWithRadius(
        x,
        z,
        groundHeight,
        radius > 0 ? radius : gameState.playerRadius,
        gameState.eyeHeight
    );
}

void GameCoreSetMoveIntent(float strafeIntent, float forwardIntent) {
    gameState.strafeIntent = strafeIntent;
    gameState.forwardIntent = forwardIntent;
}

void GameCoreSetSprint(bool sprinting) {
    gameState.sprinting = sprinting;
}

void GameCoreSetWeaponScoped(bool scoped) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
    }

    if (gameState.weaponScoped == scoped) {
        return;
    }

    gameState.weaponScoped = scoped;
    if (scoped) {
        gameState.weaponScopeSettleSecondsRemaining = gameState.weaponSettleDurationSeconds > 0.0f
            ? gameState.weaponSettleDurationSeconds
            : GAME_CORE_DEFAULT_SCOPE_SETTLE_SECONDS;
    } else {
        gameState.weaponScopeSettleSecondsRemaining = 0.0f;
        gameState.weaponSteadyRequested = false;
    }
}

void GameCoreSetWeaponSteady(bool steady) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
    }

    gameState.weaponSteadyRequested = steady;
}

void GameCoreConfigureTraversal(float walkSpeed, float sprintSpeed, float lookSensitivity) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
    }

    gameState.walkSpeed = walkSpeed > 0 ? walkSpeed : 4.2f;
    gameState.sprintSpeed = sprintSpeed >= gameState.walkSpeed ? sprintSpeed : gameState.walkSpeed + 1.8f;
    gameState.lookSensitivity = lookSensitivity > 0 ? lookSensitivity : 0.08f;
    printf(
        "[GameCore] Traversal tuned to %.2f walk / %.2f sprint / %.3f look\n",
        gameState.walkSpeed,
        gameState.sprintSpeed,
        gameState.lookSensitivity
    );
}

void GameCoreAddLookDelta(float deltaX, float deltaY) {
    gameState.yawDegrees += deltaX * gameState.lookSensitivity;
    gameState.pitchDegrees = GameCoreClamp(gameState.pitchDegrees - (deltaY * gameState.lookSensitivity), -89.0f, 89.0f);
}

GameShotFeedback GameCoreRequestFire(void) {
    GameShotFeedback feedback = {0};

    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
    }

    feedback.observerIndex = -1;
    feedback.shotCount = gameState.shotCount;
    feedback.cooldownSeconds = gameState.weaponCooldownSeconds;
    feedback.neutralizedObserverCount = gameState.neutralizedObserverCount;

    if (gameState.routeFailed || gameState.routeComplete || gameState.weaponCooldownSeconds > 0.0001f) {
        feedback.rejected = true;
        return feedback;
    }

    feedback.prediction = GameCoreGetBallisticPrediction();
    if (!feedback.prediction.valid) {
        feedback.rejected = true;
        return feedback;
    }

    gameState.shotCount += 1;
    gameState.weaponCooldownSeconds = gameState.weaponCycleSeconds;
    gameState.lastShotTravelDistanceMeters = feedback.prediction.travelDistanceMeters;
    gameState.lastShotFlightTimeSeconds = feedback.prediction.flightTimeSeconds;
    gameState.lastShotDropMeters = feedback.prediction.dropMeters;
    gameState.lastShotObserverDistanceMeters = 0;
    gameState.lastShotElapsedSeconds = gameState.elapsedSeconds;
    gameState.lastShotObserverIndex = -1;
    gameState.lastShotHitObserver = false;
    gameState.lastShotHitGround = feedback.prediction.hitGround;
    gameState.lastShotHitCollisionVolume = feedback.prediction.hitCollisionVolume;

    if (
        feedback.prediction.hitObserver
        && feedback.prediction.observerIndex >= 0
        && feedback.prediction.observerIndex < gameState.threatObserverCount
        && !gameState.observerNeutralized[feedback.prediction.observerIndex]
    ) {
        gameState.observerNeutralized[feedback.prediction.observerIndex] = true;
        GameCoreResetObserverAlertState(feedback.prediction.observerIndex);
        gameState.neutralizedObserverCount += 1;
        gameState.lastShotObserverDistanceMeters = feedback.prediction.travelDistanceMeters;
        gameState.lastShotObserverIndex = feedback.prediction.observerIndex;
        gameState.lastShotHitObserver = true;
        feedback.hitObserver = true;
        feedback.observerIndex = feedback.prediction.observerIndex;
        feedback.neutralizedObserverCount = gameState.neutralizedObserverCount;
    }

    gameState.pitchDegrees = GameCoreClamp(
        gameState.pitchDegrees + GAME_CORE_DEFAULT_WEAPON_RECOIL_PITCH_DEGREES,
        -89.0f,
        89.0f
    );
    gameState.yawDegrees = GameCoreNormalizeDegrees(
        gameState.yawDegrees + ((gameState.shotCount % 2 == 0) ? -GAME_CORE_DEFAULT_WEAPON_RECOIL_YAW_DEGREES : GAME_CORE_DEFAULT_WEAPON_RECOIL_YAW_DEGREES)
    );

    feedback.fired = true;
    feedback.shotCount = gameState.shotCount;
    feedback.cooldownSeconds = gameState.weaponCooldownSeconds;
    GameCoreUpdateDetection(0);
    return feedback;
}

void GameCoreTick(double deltaTime) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
    }

    if (!(deltaTime > 0.0)) {
        return;
    }

    {
        // Clamp hitch-sized frame times, then substep so movement and detection stay stable.
        float remainingTime = GameCoreClamp((float)deltaTime, 0, GAME_CORE_MAX_TICK_DELTA_SECONDS);

        GameCoreResetProfilingCounters();

        while (remainingTime > 0.0f) {
            const float stepTime = remainingTime > GAME_CORE_MAX_SIMULATION_STEP_SECONDS
                ? GAME_CORE_MAX_SIMULATION_STEP_SECONDS
                : remainingTime;
            const float startingX = gameState.cameraX;
            const float startingZ = gameState.cameraZ;

            gameState.lastSimulationStepCount += 1;
            GameCoreAdvanceSimulationStep(stepTime);

            {
                const float deltaX = gameState.cameraX - startingX;
                const float deltaZ = gameState.cameraZ - startingZ;
                gameState.routeDistanceMeters += sqrtf((deltaX * deltaX) + (deltaZ * deltaZ));
            }

            remainingTime -= stepTime;
        }
    }
}

bool GameCoreRestoreToCheckpointProgress(int completedCheckpointCount) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
        return false;
    }

    if (gameState.routeCheckpointCount <= 0) {
        return false;
    }

    if (completedCheckpointCount < 0 || completedCheckpointCount >= gameState.routeCheckpointCount) {
        return false;
    }

    GameCoreResetDetectionState(false);
    gameState.routeFailed = false;
    gameState.routeComplete = false;
    gameState.completedCheckpointCount = completedCheckpointCount;
    gameState.restartCount += 1;
    GameCoreUpdateRespawnAnchorForProgress();
    GameCoreRestartFromRespawnAnchor();
    GameCoreUpdateRouteProgress();
    GameCoreUpdateDetection(0);
    GameCoreResetProfilingCounters();
    printf(
        "[GameCore] Manual restore to progress %d at %.2f %.2f %.2f\n",
        completedCheckpointCount,
        gameState.respawnX,
        gameState.respawnY,
        gameState.respawnZ
    );
    return true;
}

static void GameCoreAdvanceNPCSimulationStep(GameNPCState *npc, float deltaTime) {
    static const float clockwiseOffsets[] = {0.0f, 22.5f, -22.5f, 45.0f, -45.0f, 67.5f, -67.5f, 90.0f, -90.0f, 135.0f, -135.0f, 180.0f};
    static const float counterOffsets[] = {0.0f, -22.5f, 22.5f, -45.0f, 45.0f, -67.5f, 67.5f, -90.0f, 90.0f, -135.0f, 135.0f, 180.0f};
    const float *offsets = npc->preferClockwise ? clockwiseOffsets : counterOffsets;
    const int offsetCount = (int)(sizeof(clockwiseOffsets) / sizeof(clockwiseOffsets[0]));
    const float deltaX = npc->targetX - npc->positionX;
    const float deltaZ = npc->targetZ - npc->positionZ;
    const float currentDistance = sqrtf((deltaX * deltaX) + (deltaZ * deltaZ));
    const float baseMoveSpeed = npc->sprinting ? npc->sprintSpeed : npc->walkSpeed;
    const float desiredYawDegrees = atan2f(deltaX, -deltaZ) * 180.0f / (float)M_PI;
    const float desiredTravelDistance = baseMoveSpeed * deltaTime;
    bool foundCandidate = false;
    float bestCandidateX = npc->positionX;
    float bestCandidateZ = npc->positionZ;
    float bestCandidateGroundHeight = npc->groundHeight;
    float bestCandidateDistance = currentDistance;
    float bestCandidateMovedDistance = 0;
    float bestOffset = 0;

    npc->elapsedSeconds += deltaTime;
    npc->distanceToTargetMeters = currentDistance;

    if (currentDistance <= npc->acceptanceRadius) {
        npc->targetReached = true;
        npc->hasTarget = false;
        npc->stuck = false;
        npc->moveSpeed = 0;
        npc->distanceToTargetMeters = 0;
        return;
    }

    if (!(desiredTravelDistance > 0.0f)) {
        npc->moveSpeed = 0;
        return;
    }

    for (int offsetIndex = 0; offsetIndex < offsetCount; offsetIndex++) {
        const float candidateYawDegrees = desiredYawDegrees + offsets[offsetIndex];
        const float candidateYawRadians = GameCoreDegreesToRadians(candidateYawDegrees);
        float candidateX = npc->positionX;
        float candidateZ = npc->positionZ;
        float candidateGroundHeight = npc->groundHeight;
        const float movedDistance = GameCoreMoveBodyAlongVector(
            &candidateX,
            &candidateZ,
            &candidateGroundHeight,
            sinf(candidateYawRadians),
            -cosf(candidateYawRadians),
            desiredTravelDistance,
            npc->radius,
            npc->eyeHeight
        );

        if (!(movedDistance > 0.001f)) {
            continue;
        }

        {
            const float candidateDeltaX = npc->targetX - candidateX;
            const float candidateDeltaZ = npc->targetZ - candidateZ;
            const float candidateDistance = sqrtf(
                (candidateDeltaX * candidateDeltaX) + (candidateDeltaZ * candidateDeltaZ)
            );
            const float candidateDistanceScore = candidateDistance + (fabsf(offsets[offsetIndex]) * 0.005f);
            const float bestDistanceScore = bestCandidateDistance + (fabsf(bestOffset) * 0.005f);

            if (!foundCandidate || candidateDistanceScore < bestDistanceScore) {
                foundCandidate = true;
                bestCandidateX = candidateX;
                bestCandidateZ = candidateZ;
                bestCandidateGroundHeight = candidateGroundHeight;
                bestCandidateDistance = candidateDistance;
                bestCandidateMovedDistance = movedDistance;
                bestOffset = offsets[offsetIndex];
            }
        }
    }

    if (!foundCandidate) {
        npc->moveSpeed = 0;
        npc->blockedStepCount += 1;
        npc->stuckSeconds += deltaTime;
        if ((npc->blockedStepCount % 12) == 0) {
            npc->preferClockwise = !npc->preferClockwise;
        }
    } else {
        npc->positionX = bestCandidateX;
        npc->positionZ = bestCandidateZ;
        npc->groundHeight = bestCandidateGroundHeight;
        npc->positionY = npc->groundHeight + npc->eyeHeight;
        npc->yawDegrees = GameCoreNormalizeDegrees(desiredYawDegrees + bestOffset);
        npc->moveSpeed = bestCandidateMovedDistance / deltaTime;
        npc->travelledDistanceMeters += bestCandidateMovedDistance;
        npc->distanceToTargetMeters = bestCandidateDistance;

        if (bestOffset > 1.0f) {
            npc->preferClockwise = true;
            npc->avoidanceTurnCount += 1;
        } else if (bestOffset < -1.0f) {
            npc->preferClockwise = false;
            npc->avoidanceTurnCount += 1;
        }

        if (bestCandidateDistance + GAME_CORE_NPC_PROGRESS_EPSILON_METERS < npc->bestDistanceToTargetMeters) {
            npc->bestDistanceToTargetMeters = bestCandidateDistance;
            npc->stuckSeconds = 0;
            npc->blockedStepCount = 0;
        } else if (bestCandidateDistance + GAME_CORE_NPC_PROGRESS_EPSILON_METERS < currentDistance) {
            npc->stuckSeconds = GameCoreClamp(npc->stuckSeconds - (deltaTime * 0.5f), 0, GAME_CORE_NPC_STUCK_TIMEOUT_SECONDS);
            if (npc->blockedStepCount > 0) {
                npc->blockedStepCount -= 1;
            }
        } else {
            npc->stuckSeconds += deltaTime * (fabsf(bestOffset) >= 89.0f ? 0.5f : 0.25f);
        }

        if (bestCandidateDistance <= npc->acceptanceRadius) {
            npc->targetReached = true;
            npc->hasTarget = false;
            npc->stuck = false;
            npc->moveSpeed = 0;
            npc->distanceToTargetMeters = 0;
            return;
        }
    }

    if (npc->stuckSeconds >= GAME_CORE_NPC_STUCK_TIMEOUT_SECONDS) {
        npc->stuck = true;
        npc->hasTarget = false;
        npc->moveSpeed = 0;
    }
}

void GameCoreInitializeNPC(GameNPCState *npc, float x, float y, float z, float yawDegrees, float pitchDegrees) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
    }

    if (npc == NULL) {
        return;
    }

    memset(npc, 0, sizeof(*npc));
    npc->positionX = x;
    npc->positionY = y;
    npc->positionZ = z;
    npc->yawDegrees = yawDegrees;
    npc->pitchDegrees = pitchDegrees;
    npc->walkSpeed = gameState.walkSpeed > 0 ? gameState.walkSpeed : 4.2f;
    npc->sprintSpeed = gameState.sprintSpeed > npc->walkSpeed ? gameState.sprintSpeed : npc->walkSpeed + 1.8f;
    npc->radius = gameState.playerRadius > 0 ? gameState.playerRadius : 0.36f;
    npc->eyeHeight = gameState.eyeHeight > 0 ? gameState.eyeHeight : 1.65f;
    npc->acceptanceRadius = 1.0f;
    npc->distanceToTargetMeters = -1.0f;
    npc->bestDistanceToTargetMeters = INFINITY;
    npc->preferClockwise = true;

    GameCoreRefreshNPCGrounding(npc, y - npc->eyeHeight);
    if (!npc->grounded || GameCoreWouldCollideWithRadius(npc->positionX, npc->positionZ, npc->groundHeight, npc->radius, npc->eyeHeight)) {
        npc->stuck = true;
        npc->blockedStepCount = 1;
    }
}

void GameCoreConfigureNPCTraversal(GameNPCState *npc, float walkSpeed, float sprintSpeed, float radius) {
    if (npc == NULL) {
        return;
    }

    npc->walkSpeed = walkSpeed > 0 ? walkSpeed : (gameState.walkSpeed > 0 ? gameState.walkSpeed : 4.2f);
    npc->sprintSpeed = sprintSpeed >= npc->walkSpeed ? sprintSpeed : npc->walkSpeed + 1.8f;
    npc->radius = radius > 0 ? radius : (gameState.playerRadius > 0 ? gameState.playerRadius : 0.36f);
}

void GameCoreSetNPCTarget(GameNPCState *npc, float x, float y, float z, float acceptanceRadius, bool sprinting) {
    if (npc == NULL) {
        return;
    }

    npc->targetX = x;
    npc->targetY = y;
    npc->targetZ = z;
    npc->acceptanceRadius = acceptanceRadius > 0 ? acceptanceRadius : 1.0f;
    npc->distanceToTargetMeters = sqrtf(
        ((x - npc->positionX) * (x - npc->positionX)) +
        ((z - npc->positionZ) * (z - npc->positionZ))
    );
    npc->bestDistanceToTargetMeters = npc->distanceToTargetMeters;
    npc->sprinting = sprinting;
    npc->hasTarget = true;
    npc->targetReached = npc->distanceToTargetMeters <= npc->acceptanceRadius;
    npc->stuck = !npc->grounded || GameCoreWouldCollideWithRadius(
        npc->positionX,
        npc->positionZ,
        npc->groundHeight,
        npc->radius,
        npc->eyeHeight
    );
    npc->stuckSeconds = 0;
    npc->blockedStepCount = 0;
    npc->moveSpeed = 0;
}

void GameCoreClearNPCTarget(GameNPCState *npc) {
    if (npc == NULL) {
        return;
    }

    npc->hasTarget = false;
    npc->targetReached = false;
    npc->moveSpeed = 0;
    npc->distanceToTargetMeters = -1.0f;
    npc->bestDistanceToTargetMeters = INFINITY;
}

void GameCoreTickNPC(GameNPCState *npc, double deltaTime) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
    }

    if (npc == NULL || !npc->hasTarget || npc->targetReached || npc->stuck || !(deltaTime > 0.0)) {
        return;
    }

    {
        float remainingTime = GameCoreClamp((float)deltaTime, 0, GAME_CORE_MAX_TICK_DELTA_SECONDS);

        while (remainingTime > 0.0f && npc->hasTarget && !npc->targetReached && !npc->stuck) {
            const float stepTime = remainingTime > GAME_CORE_MAX_SIMULATION_STEP_SECONDS
                ? GAME_CORE_MAX_SIMULATION_STEP_SECONDS
                : remainingTime;
            GameCoreAdvanceNPCSimulationStep(npc, stepTime);
            remainingTime -= stepTime;
        }
    }
}

GameFrameSnapshot GameCoreGetSnapshot(void) {
    const GameResolvedWeaponAim aim = GameCoreResolveWeaponAim();
    GameFrameSnapshot snapshot = {
        .elapsedSeconds = gameState.elapsedSeconds,
        .strafeIntent = gameState.strafeIntent,
        .forwardIntent = gameState.forwardIntent,
        .yawDegrees = gameState.yawDegrees,
        .pitchDegrees = gameState.pitchDegrees,
        .cameraX = gameState.cameraX,
        .cameraY = gameState.cameraY,
        .cameraZ = gameState.cameraZ,
        .moveSpeed = gameState.moveSpeed,
        .walkSpeed = gameState.walkSpeed,
        .sprintSpeed = gameState.sprintSpeed,
        .lookSensitivity = gameState.lookSensitivity,
        .weaponCycleSeconds = gameState.weaponCycleSeconds,
        .weaponCooldownSeconds = gameState.weaponCooldownSeconds,
        .groundHeight = gameState.groundHeight,
        .routeDistanceMeters = gameState.routeDistanceMeters,
        .distanceToNextCheckpointMeters = gameState.distanceToNextCheckpointMeters,
        .suspicionLevel = gameState.suspicionLevel,
        .weaponStability = aim.stability,
        .weaponSpreadDegrees = aim.spreadDegrees,
        .aimYawOffsetDegrees = aim.yawOffsetDegrees,
        .aimPitchOffsetDegrees = aim.pitchOffsetDegrees,
        .holdBreathSecondsRemaining = aim.holdBreathSecondsRemaining,
        .lastShotTravelDistanceMeters = gameState.lastShotTravelDistanceMeters,
        .lastShotFlightTimeSeconds = gameState.lastShotFlightTimeSeconds,
        .lastShotDropMeters = gameState.lastShotDropMeters,
        .lastShotObserverDistanceMeters = gameState.lastShotObserverDistanceMeters,
        .lastShotElapsedSeconds = gameState.lastShotElapsedSeconds,
        .activeSectorCount = gameState.activeSectorCount,
        .completedCheckpointCount = gameState.completedCheckpointCount,
        .totalCheckpointCount = gameState.routeCheckpointCount,
        .activeObserverCount = gameState.activeObserverCount,
        .alertedObserverCount = gameState.alertedObserverCount,
        .seeingObserverCount = gameState.seeingObserverCount,
        .neutralizedObserverCount = gameState.neutralizedObserverCount,
        .totalObserverCount = gameState.threatObserverCount,
        .lastShotObserverIndex = gameState.lastShotObserverIndex,
        .shotCount = gameState.shotCount,
        .restartCount = gameState.restartCount,
        .failCount = gameState.failCount,
        .lastShotHitObserver = gameState.lastShotHitObserver,
        .lastShotHitGround = gameState.lastShotHitGround,
        .lastShotHitCollisionVolume = gameState.lastShotHitCollisionVolume,
        .weaponScoped = gameState.weaponScoped,
        .steadyAimActive = aim.steadyActive,
        .sprinting = gameState.sprinting,
        .grounded = gameState.grounded,
        .routeComplete = gameState.routeComplete,
        .routeFailed = gameState.routeFailed,
    };

    return snapshot;
}

GameBallisticPrediction GameCoreGetBallisticPrediction(void) {
    GameBallisticPrediction prediction = {0};
    const GameResolvedWeaponAim aim = GameCoreResolveWeaponAim();
    float muzzleVelocity = 0;
    float gravity = 0;
    float maxSimulationTime = 0;
    float simulationStep = 0;
    float fallbackGroundHeight = 0;
    float forwardX = 0;
    float forwardY = 0;
    float forwardZ = 0;
    float velocityX = 0;
    float velocityY = 0;
    float velocityZ = 0;
    float initialVelocityY = 0;
    float currentX = 0;
    float currentY = 0;
    float currentZ = 0;
    float elapsedTime = 0;
    float travelDistance = 0;
    int executedStepCount = 0;

    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
    }

    muzzleVelocity = gameState.ballisticMuzzleVelocityMetersPerSecond > 0.0f
        ? gameState.ballisticMuzzleVelocityMetersPerSecond
        : GAME_CORE_DEFAULT_BALLISTIC_MUZZLE_VELOCITY;
    gravity = gameState.ballisticGravityMetersPerSecondSquared > 0.0f
        ? gameState.ballisticGravityMetersPerSecondSquared
        : GAME_CORE_DEFAULT_BALLISTIC_GRAVITY;
    maxSimulationTime = gameState.ballisticMaxSimulationTimeSeconds > 0.0f
        ? gameState.ballisticMaxSimulationTimeSeconds
        : GAME_CORE_DEFAULT_BALLISTIC_MAX_TIME_SECONDS;
    simulationStep = gameState.ballisticSimulationStepSeconds > 0.0f
        ? gameState.ballisticSimulationStepSeconds
        : GAME_CORE_DEFAULT_BALLISTIC_STEP_SECONDS;
    fallbackGroundHeight = gameState.spawnY - gameState.eyeHeight;
    currentX = gameState.cameraX;
    currentY = gameState.cameraY + gameState.ballisticLaunchHeightOffsetMeters;
    currentZ = gameState.cameraZ;

    prediction.originX = currentX;
    prediction.originY = currentY;
    prediction.originZ = currentZ;
    prediction.impactX = currentX;
    prediction.impactY = currentY;
    prediction.impactZ = currentZ;
    prediction.observerIndex = -1;

    if (!(muzzleVelocity > 0.0f) || !(maxSimulationTime > 0.0f) || !(simulationStep > 0.0f)) {
        return prediction;
    }

    GameCoreForwardVector(
        gameState.yawDegrees + aim.yawOffsetDegrees,
        gameState.pitchDegrees + aim.pitchOffsetDegrees,
        &forwardX,
        &forwardY,
        &forwardZ
    );
    velocityX = forwardX * muzzleVelocity;
    velocityY = forwardY * muzzleVelocity;
    velocityZ = forwardZ * muzzleVelocity;
    initialVelocityY = velocityY;

    while (elapsedTime < maxSimulationTime) {
        const float stepTime = (elapsedTime + simulationStep) > maxSimulationTime
            ? (maxSimulationTime - elapsedTime)
            : simulationStep;
        const float nextX = currentX + (velocityX * stepTime);
        const float nextY = currentY + (velocityY * stepTime) - (0.5f * gravity * stepTime * stepTime);
        const float nextZ = currentZ + (velocityZ * stepTime);
        const float segmentDeltaX = nextX - currentX;
        const float segmentDeltaY = nextY - currentY;
        const float segmentDeltaZ = nextZ - currentZ;
        const float segmentDistance = sqrtf(
            (segmentDeltaX * segmentDeltaX) +
            (segmentDeltaY * segmentDeltaY) +
            (segmentDeltaZ * segmentDeltaZ)
        );
        int sampleCount = (int)ceilf(segmentDistance / GAME_CORE_BALLISTIC_SAMPLE_SPACING_METERS);

        if (stepTime <= 0.0f) {
            break;
        }

        if (sampleCount < 1) {
            sampleCount = 1;
        }

        for (int sampleIndex = 1; sampleIndex <= sampleCount; sampleIndex++) {
            const float sampleT = (float)sampleIndex / (float)sampleCount;
            const float sampleX = currentX + (segmentDeltaX * sampleT);
            const float sampleY = currentY + (segmentDeltaY * sampleT);
            const float sampleZ = currentZ + (segmentDeltaZ * sampleT);
            const float sampleTime = elapsedTime + (stepTime * sampleT);
            const float sampleTravelDistance = travelDistance + (segmentDistance * sampleT);

            for (int collisionIndex = 0; collisionIndex < gameState.collisionVolumeCount; collisionIndex++) {
                if (GameCorePointInsideCollisionVolume(
                    &gameState.collisionVolumes[collisionIndex],
                    sampleX,
                    sampleY,
                    sampleZ,
                    0.0f
                )) {
                    prediction.valid = true;
                    prediction.hitCollisionVolume = true;
                    prediction.impactX = sampleX;
                    prediction.impactY = sampleY;
                    prediction.impactZ = sampleZ;
                    prediction.flightTimeSeconds = sampleTime;
                    prediction.travelDistanceMeters = sampleTravelDistance;
                    prediction.simulationStepCount = executedStepCount + 1;
                    prediction.dropMeters = GameCoreClamp(
                        (prediction.originY + (initialVelocityY * sampleTime)) - prediction.impactY,
                        0.0f,
                        INFINITY
                    );
                    return prediction;
                }
            }

            {
                for (int observerIndex = 0; observerIndex < gameState.threatObserverCount; observerIndex++) {
                    if (gameState.observerNeutralized[observerIndex]) {
                        continue;
                    }

                    if (GameCorePointInsideObserverHitVolume(
                        &gameState.threatObservers[observerIndex],
                        sampleX,
                        sampleY,
                        sampleZ
                    )) {
                        prediction.valid = true;
                        prediction.hitObserver = true;
                        prediction.observerIndex = observerIndex;
                        prediction.impactX = sampleX;
                        prediction.impactY = sampleY;
                        prediction.impactZ = sampleZ;
                        prediction.flightTimeSeconds = sampleTime;
                        prediction.travelDistanceMeters = sampleTravelDistance;
                        prediction.simulationStepCount = executedStepCount + 1;
                        prediction.dropMeters = GameCoreClamp(
                            (prediction.originY + (initialVelocityY * sampleTime)) - prediction.impactY,
                            0.0f,
                            INFINITY
                        );
                        return prediction;
                    }
                }
            }

            {
                bool foundGround = false;
                const float groundHeight = GameCoreSampleGroundHeight(
                    sampleX,
                    sampleZ,
                    fallbackGroundHeight,
                    &foundGround
                );

                if (foundGround && sampleY <= groundHeight) {
                    prediction.valid = true;
                    prediction.hitGround = true;
                    prediction.impactX = sampleX;
                    prediction.impactY = groundHeight;
                    prediction.impactZ = sampleZ;
                    prediction.flightTimeSeconds = sampleTime;
                    prediction.travelDistanceMeters = sampleTravelDistance;
                    prediction.simulationStepCount = executedStepCount + 1;
                    prediction.dropMeters = GameCoreClamp(
                        (prediction.originY + (initialVelocityY * sampleTime)) - prediction.impactY,
                        0.0f,
                        INFINITY
                    );
                    return prediction;
                }
            }
        }

        currentX = nextX;
        currentY = nextY;
        currentZ = nextZ;
        velocityY -= gravity * stepTime;
        elapsedTime += stepTime;
        travelDistance += segmentDistance;
        executedStepCount += 1;
    }

    prediction.valid = true;
    prediction.impactX = currentX;
    prediction.impactY = currentY;
    prediction.impactZ = currentZ;
    prediction.flightTimeSeconds = elapsedTime;
    prediction.travelDistanceMeters = travelDistance;
    prediction.simulationStepCount = executedStepCount;
    prediction.dropMeters = GameCoreClamp(
        (prediction.originY + (initialVelocityY * elapsedTime)) - prediction.impactY,
        0.0f,
        INFINITY
    );
    return prediction;
}

GameProfilingSnapshot GameCoreGetProfilingSnapshot(void) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
    }

    GameProfilingSnapshot snapshot = {
        .simulationStepCount = gameState.lastSimulationStepCount,
        .movementStepCount = gameState.lastMovementStepCount,
        .lineOfSightTestCount = gameState.lastLineOfSightTestCount,
        .lineOfSightSampleCount = gameState.lastLineOfSightSampleCount,
        .sectorCount = gameState.sectorCount,
        .collisionVolumeCount = gameState.collisionVolumeCount,
        .groundSurfaceCount = gameState.groundSurfaceCount,
    };

    return snapshot;
}

int GameCoreGetObserverDebugStates(GameObserverDebugState *states, int maxCount) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
    }

    if (states == NULL || maxCount <= 0) {
        return gameState.threatObserverCount;
    }

    const int copyCount = gameState.threatObserverCount < maxCount
        ? gameState.threatObserverCount
        : maxCount;
    memcpy(states, gameState.observerDebugStates, sizeof(GameObserverDebugState) * (size_t)copyCount);
    return gameState.threatObserverCount;
}

void GameCoreRestartRoute(void) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
        return;
    }

    if (gameState.routeComplete) {
    GameCoreResetDetectionState(true);
    GameCoreResetRouteProgress();
    GameCoreResetRuntimeState();
    GameCoreUpdateRouteProgress();
    GameCoreUpdateDetection(0);
    GameCoreResetProfilingCounters();
    printf("[GameCore] Route restart from initial spawn\n");
    return;
}

    if (gameState.routeFailed) {
        GameCoreResetDetectionState(false);
    }

    gameState.restartCount += 1;
    GameCoreRestartFromRespawnAnchor();
    GameCoreUpdateRouteProgress();
    GameCoreUpdateDetection(0);
    GameCoreResetProfilingCounters();
    printf("[GameCore] Route restart to %.2f %.2f %.2f\n", gameState.respawnX, gameState.respawnY, gameState.respawnZ);
}

void GameCoreForceRouteFailure(void) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
        return;
    }

    if (!gameState.routeComplete && !gameState.routeFailed) {
        gameState.routeFailed = true;
        gameState.failCount += 1;
    }

    gameState.moveSpeed = 0;
    gameState.distanceToNextCheckpointMeters = 0;
    GameCoreResetProfilingCounters();
    printf("[GameCore] Route failure forced by mission script\n");
}

void GameCoreClearFailure(void) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
        return;
    }

    GameCoreResetDetectionState(false);
    GameCoreUpdateDetection(0);
    GameCoreResetProfilingCounters();
    printf("[GameCore] Failure state cleared\n");
}

void GameCoreResetDebugState(void) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
        return;
    }

    GameCoreResetDetectionState(true);
    GameCoreResetRouteProgress();
    GameCoreResetRuntimeState();
    GameCoreUpdateRouteProgress();
    GameCoreUpdateDetection(0);
    GameCoreResetProfilingCounters();
    printf("[GameCore] Debug state reset\n");
}

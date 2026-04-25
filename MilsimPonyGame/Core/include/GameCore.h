#ifndef GAME_CORE_H
#define GAME_CORE_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct GameSectorBounds {
    float minX;
    float minZ;
    float maxX;
    float maxZ;
    float activationPadding;
} GameSectorBounds;

typedef struct GameCollisionVolume {
    float centerX;
    float centerY;
    float centerZ;
    float halfWidth;
    float halfHeight;
    float halfDepth;
    float yawDegrees;
} GameCollisionVolume;

typedef struct GameGroundSurface {
    float centerX;
    float centerZ;
    float halfWidth;
    float halfDepth;
    float yawDegrees;
    float northWestHeight;
    float northEastHeight;
    float southEastHeight;
    float southWestHeight;
} GameGroundSurface;

typedef struct GameRouteCheckpoint {
    float positionX;
    float positionY;
    float positionZ;
    float triggerRadius;
    float yawDegrees;
    float pitchDegrees;
    bool isGoal;
} GameRouteCheckpoint;

typedef struct GameThreatObserver {
    float positionX;
    float positionY;
    float positionZ;
    float yawDegrees;
    float pitchDegrees;
    float range;
    float fieldOfViewDegrees;
    float suspicionPerSecond;
    int groupIndex;
    float groupRelayRangeMeters;
    float alertMemorySeconds;
    float alertedFieldOfViewDegrees;
    float turnRateDegreesPerSecond;
    float scanArcDegrees;
    float scanCycleSeconds;
} GameThreatObserver;

typedef struct GameBallisticsConfiguration {
    float muzzleVelocityMetersPerSecond;
    float gravityMetersPerSecondSquared;
    float maxSimulationTimeSeconds;
    float simulationStepSeconds;
    float launchHeightOffsetMeters;
    float scopedSpreadDegrees;
    float hipSpreadDegrees;
    float movementSpreadDegrees;
    float sprintSpreadDegrees;
    float settleDurationSeconds;
    float breathCycleSeconds;
    float breathAmplitudeDegrees;
    float holdBreathDurationSeconds;
    float holdBreathRecoverySeconds;
} GameBallisticsConfiguration;

typedef struct GameBallisticPrediction {
    float originX;
    float originY;
    float originZ;
    float impactX;
    float impactY;
    float impactZ;
    float travelDistanceMeters;
    float flightTimeSeconds;
    float dropMeters;
    int observerIndex;
    int simulationStepCount;
    bool valid;
    bool hitObserver;
    bool hitGround;
    bool hitCollisionVolume;
} GameBallisticPrediction;

typedef struct GameProfilingSnapshot {
    int simulationStepCount;
    int movementStepCount;
    int lineOfSightTestCount;
    int lineOfSightSampleCount;
    int sectorCount;
    int collisionVolumeCount;
    int groundSurfaceCount;
} GameProfilingSnapshot;

typedef struct GameShotFeedback {
    GameBallisticPrediction prediction;
    float cooldownSeconds;
    int observerIndex;
    int neutralizedObserverCount;
    int shotCount;
    bool fired;
    bool hitObserver;
    bool rejected;
} GameShotFeedback;

typedef struct GameObserverDebugState {
    float distanceMeters;
    float rangeMeters;
    float fieldOfViewDegrees;
    float yawDegrees;
    float pitchDegrees;
    float viewDot;
    float coneThreshold;
    float suspicionPerSecond;
    float alertSecondsRemaining;
    float scanArcDegrees;
    float scanCycleSeconds;
    float scanPhaseSeconds;
    bool neutralized;
    bool alerted;
    bool supportingGroup;
    bool scanHalted;
    bool inRange;
    bool inViewCone;
    bool hasLineOfSight;
    bool seeingPlayer;
} GameObserverDebugState;

typedef struct GameDifficultyTuning {
    float observerSuspicionScale;
    float suspicionDecayScale;
    float failThresholdScale;
    float weaponCycleScale;
} GameDifficultyTuning;

typedef struct GameNPCState {
    double elapsedSeconds;
    float positionX;
    float positionY;
    float positionZ;
    float yawDegrees;
    float pitchDegrees;
    float groundHeight;
    float walkSpeed;
    float sprintSpeed;
    float moveSpeed;
    float radius;
    float eyeHeight;
    float targetX;
    float targetY;
    float targetZ;
    float acceptanceRadius;
    float distanceToTargetMeters;
    float travelledDistanceMeters;
    float stuckSeconds;
    float bestDistanceToTargetMeters;
    int blockedStepCount;
    int avoidanceTurnCount;
    bool grounded;
    bool sprinting;
    bool hasTarget;
    bool targetReached;
    bool stuck;
    bool preferClockwise;
} GameNPCState;

typedef struct GameFrameSnapshot {
    double elapsedSeconds;
    float strafeIntent;
    float forwardIntent;
    float yawDegrees;
    float pitchDegrees;
    float cameraX;
    float cameraY;
    float cameraZ;
    float moveSpeed;
    float walkSpeed;
    float sprintSpeed;
    float lookSensitivity;
    float weaponCycleSeconds;
    float weaponCooldownSeconds;
    float groundHeight;
    float routeDistanceMeters;
    float distanceToNextCheckpointMeters;
    float suspicionLevel;
    float weaponStability;
    float weaponSpreadDegrees;
    float aimYawOffsetDegrees;
    float aimPitchOffsetDegrees;
    float holdBreathSecondsRemaining;
    float lastShotTravelDistanceMeters;
    float lastShotFlightTimeSeconds;
    float lastShotDropMeters;
    float lastShotObserverDistanceMeters;
    double lastShotElapsedSeconds;
    int activeSectorCount;
    int completedCheckpointCount;
    int totalCheckpointCount;
    int activeObserverCount;
    int alertedObserverCount;
    int seeingObserverCount;
    int neutralizedObserverCount;
    int totalObserverCount;
    int lastShotObserverIndex;
    int shotCount;
    int restartCount;
    int failCount;
    bool lastShotHitObserver;
    bool lastShotHitGround;
    bool lastShotHitCollisionVolume;
    bool weaponScoped;
    bool steadyAimActive;
    bool sprinting;
    bool grounded;
    bool routeComplete;
    bool routeFailed;
} GameFrameSnapshot;

void GameCoreBootstrap(const char *bootMode);
void GameCoreConfigureSpawn(float x, float y, float z, float yawDegrees, float pitchDegrees);
void GameCoreConfigureWorld(
    const GameSectorBounds *sectors,
    int sectorCount,
    const GameCollisionVolume *collisionVolumes,
    int collisionVolumeCount,
    const GameGroundSurface *groundSurfaces,
    int groundSurfaceCount
);
void GameCoreConfigureRoute(const GameRouteCheckpoint *checkpoints, int checkpointCount);
void GameCoreConfigureDetection(
    const GameThreatObserver *observers,
    int observerCount,
    float suspicionDecayPerSecond,
    float failThreshold
);
void GameCoreConfigureBallistics(GameBallisticsConfiguration configuration);
void GameCoreConfigureDifficulty(GameDifficultyTuning tuning);
bool GameCoreSampleGroundHeightAt(float x, float z, float fallbackHeight, float *groundHeight);
bool GameCoreCanOccupyPosition(float x, float z, float groundHeight, float radius);
void GameCoreConfigureTraversal(float walkSpeed, float sprintSpeed, float lookSensitivity);
void GameCoreSetMoveIntent(float strafeIntent, float forwardIntent);
void GameCoreSetSprint(bool sprinting);
void GameCoreSetWeaponScoped(bool scoped);
void GameCoreSetWeaponSteady(bool steady);
void GameCoreAddLookDelta(float deltaX, float deltaY);
GameShotFeedback GameCoreRequestFire(void);
void GameCoreTick(double deltaTime);
bool GameCoreRestoreToCheckpointProgress(int completedCheckpointCount);
void GameCoreInitializeNPC(GameNPCState *npc, float x, float y, float z, float yawDegrees, float pitchDegrees);
void GameCoreConfigureNPCTraversal(GameNPCState *npc, float walkSpeed, float sprintSpeed, float radius);
void GameCoreSetNPCTarget(GameNPCState *npc, float x, float y, float z, float acceptanceRadius, bool sprinting);
void GameCoreClearNPCTarget(GameNPCState *npc);
void GameCoreTickNPC(GameNPCState *npc, double deltaTime);
GameFrameSnapshot GameCoreGetSnapshot(void);
GameBallisticPrediction GameCoreGetBallisticPrediction(void);
GameProfilingSnapshot GameCoreGetProfilingSnapshot(void);
int GameCoreGetObserverDebugStates(GameObserverDebugState *states, int maxCount);
void GameCoreRestartRoute(void);
void GameCoreClearFailure(void);
void GameCoreResetDebugState(void);

#ifdef __cplusplus
}
#endif

#endif

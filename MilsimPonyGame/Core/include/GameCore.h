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
} GameThreatObserver;

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
    float groundHeight;
    float routeDistanceMeters;
    float distanceToNextCheckpointMeters;
    float suspicionLevel;
    int activeSectorCount;
    int completedCheckpointCount;
    int totalCheckpointCount;
    int activeObserverCount;
    int seeingObserverCount;
    int restartCount;
    int failCount;
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
bool GameCoreSampleGroundHeightAt(float x, float z, float fallbackHeight, float *groundHeight);
bool GameCoreCanOccupyPosition(float x, float z, float groundHeight, float radius);
void GameCoreConfigureTraversal(float walkSpeed, float sprintSpeed, float lookSensitivity);
void GameCoreSetMoveIntent(float strafeIntent, float forwardIntent);
void GameCoreSetSprint(bool sprinting);
void GameCoreAddLookDelta(float deltaX, float deltaY);
void GameCoreTick(double deltaTime);
void GameCoreInitializeNPC(GameNPCState *npc, float x, float y, float z, float yawDegrees, float pitchDegrees);
void GameCoreConfigureNPCTraversal(GameNPCState *npc, float walkSpeed, float sprintSpeed, float radius);
void GameCoreSetNPCTarget(GameNPCState *npc, float x, float y, float z, float acceptanceRadius, bool sprinting);
void GameCoreClearNPCTarget(GameNPCState *npc);
void GameCoreTickNPC(GameNPCState *npc, double deltaTime);
GameFrameSnapshot GameCoreGetSnapshot(void);
void GameCoreRestartRoute(void);
void GameCoreClearFailure(void);
void GameCoreResetDebugState(void);

#ifdef __cplusplus
}
#endif

#endif

#include "include/GameCore.h"

#include <math.h>
#include <stdio.h>
#include <string.h>

#define GAME_CORE_MAX_SECTORS 32
#define GAME_CORE_MAX_COLLISION_VOLUMES 256
#define GAME_CORE_MAX_GROUND_SURFACES 128
#define GAME_CORE_MAX_ROUTE_CHECKPOINTS 16

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
    float eyeHeight;
    float playerRadius;
    float groundHeight;
    float routeDistanceMeters;
    float distanceToNextCheckpointMeters;
    int activeSectorCount;
    int completedCheckpointCount;
    int restartCount;
    bool sprinting;
    bool grounded;
    bool routeComplete;
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
    .eyeHeight = 1.65f,
    .playerRadius = 0.36f,
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

    if (foundSurface != NULL) {
        *foundSurface = found;
    }

    return highestHeight;
}

static bool GameCoreWouldCollide(float x, float z, float groundHeight) {
    const float eyeHeight = groundHeight + gameState.eyeHeight;

    for (int index = 0; index < gameState.collisionVolumeCount; index++) {
        const GameCollisionVolume *volume = &gameState.collisionVolumes[index];
        const float minY = volume->centerY - volume->halfHeight;
        const float maxY = volume->centerY + volume->halfHeight;
        float localX = 0;
        float localZ = 0;

        if (groundHeight > maxY || eyeHeight < minY) {
            continue;
        }

        GameCoreRotateIntoLocalFrame(
            x - volume->centerX,
            z - volume->centerZ,
            volume->yawDegrees,
            &localX,
            &localZ
        );

        if (fabsf(localX) <= (volume->halfWidth + gameState.playerRadius) &&
            fabsf(localZ) <= (volume->halfDepth + gameState.playerRadius)) {
            return true;
        }
    }

    return false;
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

static void GameCoreUpdateRespawnAnchorForProgress(void) {
    if (gameState.completedCheckpointCount <= 0 || gameState.routeCheckpointCount <= 0) {
        gameState.respawnX = gameState.spawnX;
        gameState.respawnY = gameState.spawnY;
        gameState.respawnZ = gameState.spawnZ;
        gameState.respawnYawDegrees = gameState.spawnYawDegrees;
        gameState.respawnPitchDegrees = gameState.spawnPitchDegrees;
        return;
    }

    const int checkpointIndex = gameState.completedCheckpointCount - 1;
    const GameRouteCheckpoint *checkpoint = &gameState.routeCheckpoints[checkpointIndex];
    gameState.respawnX = checkpoint->positionX;
    gameState.respawnY = checkpoint->positionY;
    gameState.respawnZ = checkpoint->positionZ;
    gameState.respawnYawDegrees = checkpoint->yawDegrees;
    gameState.respawnPitchDegrees = checkpoint->pitchDegrees;
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
    gameState.cameraX = gameState.respawnX;
    gameState.cameraZ = gameState.respawnZ;
    gameState.yawDegrees = gameState.respawnYawDegrees;
    gameState.pitchDegrees = gameState.respawnPitchDegrees;
    GameCoreRefreshGrounding();
}

static void GameCoreUpdateRouteProgress(void) {
    if (gameState.routeComplete) {
        gameState.distanceToNextCheckpointMeters = 0;
        return;
    }

    if (gameState.routeCheckpointCount <= 0) {
        gameState.distanceToNextCheckpointMeters = -1;
        return;
    }

    const int nextCheckpointIndex = gameState.completedCheckpointCount;
    if (nextCheckpointIndex >= gameState.routeCheckpointCount) {
        gameState.routeComplete = true;
        gameState.distanceToNextCheckpointMeters = 0;
        return;
    }

    const GameRouteCheckpoint *checkpoint = &gameState.routeCheckpoints[nextCheckpointIndex];
    const float deltaX = gameState.cameraX - checkpoint->positionX;
    const float deltaY = gameState.cameraY - checkpoint->positionY;
    const float deltaZ = gameState.cameraZ - checkpoint->positionZ;
    const float distance = sqrtf((deltaX * deltaX) + (deltaY * deltaY) + (deltaZ * deltaZ));

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
        const float nextDeltaY = gameState.cameraY - upcomingCheckpoint->positionY;
        const float nextDeltaZ = gameState.cameraZ - upcomingCheckpoint->positionZ;
        gameState.distanceToNextCheckpointMeters = sqrtf(
            (nextDeltaX * nextDeltaX) + (nextDeltaY * nextDeltaY) + (nextDeltaZ * nextDeltaZ)
        );
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

    if (bootMode != NULL) {
        snprintf(gameState.bootMode, sizeof(gameState.bootMode), "%s", bootMode);
    } else {
        snprintf(gameState.bootMode, sizeof(gameState.bootMode), "bootstrap");
    }

    GameCoreResetRouteProgress();
    GameCoreResetRuntimeState();
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
    GameCoreResetRouteProgress();
    GameCoreResetRuntimeState();
    GameCoreUpdateRouteProgress();
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

    GameCoreResetRouteProgress();
    GameCoreUpdateRouteProgress();
    printf("[GameCore] Route configured with %d checkpoints\n", gameState.routeCheckpointCount);
}

void GameCoreSetMoveIntent(float strafeIntent, float forwardIntent) {
    gameState.strafeIntent = strafeIntent;
    gameState.forwardIntent = forwardIntent;
}

void GameCoreSetSprint(bool sprinting) {
    gameState.sprinting = sprinting;
}

void GameCoreAddLookDelta(float deltaX, float deltaY) {
    gameState.yawDegrees += deltaX * 0.08f;
    gameState.pitchDegrees = GameCoreClamp(gameState.pitchDegrees - (deltaY * 0.08f), -89.0f, 89.0f);
}

void GameCoreTick(double deltaTime) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
    }

    gameState.elapsedSeconds += deltaTime;

    const float startingX = gameState.cameraX;
    const float startingZ = gameState.cameraZ;
    const float baseMoveSpeed = gameState.sprinting ? 6.8f : 4.2f;
    float moveX = gameState.strafeIntent;
    float moveZ = gameState.forwardIntent;

    const float magnitude = sqrtf((moveX * moveX) + (moveZ * moveZ));
    if (magnitude > 1.0f) {
        moveX /= magnitude;
        moveZ /= magnitude;
    }

    const float yawRadians = gameState.yawDegrees * (float)M_PI / 180.0f;
    const float rightX = cosf(yawRadians);
    const float rightZ = sinf(yawRadians);
    const float forwardX = sinf(yawRadians);
    const float forwardZ = -cosf(yawRadians);
    const float worldMoveX = (rightX * moveX) + (forwardX * moveZ);
    const float worldMoveZ = (rightZ * moveX) + (forwardZ * moveZ);
    const float stepDistance = baseMoveSpeed * (float)deltaTime;

    gameState.moveSpeed = baseMoveSpeed * magnitude;

    if (magnitude > 0.0f) {
        float nextX = gameState.cameraX + (worldMoveX * stepDistance);
        float nextZ = gameState.cameraZ;
        float candidateGroundHeight = GameCoreSampleGroundHeight(nextX, nextZ, gameState.groundHeight, NULL);

        if (!GameCoreWouldCollide(nextX, nextZ, candidateGroundHeight)) {
            gameState.cameraX = nextX;
            gameState.groundHeight = candidateGroundHeight;
        }

        nextX = gameState.cameraX;
        nextZ = gameState.cameraZ + (worldMoveZ * stepDistance);
        candidateGroundHeight = GameCoreSampleGroundHeight(nextX, nextZ, gameState.groundHeight, NULL);

        if (!GameCoreWouldCollide(nextX, nextZ, candidateGroundHeight)) {
            gameState.cameraZ = nextZ;
            gameState.groundHeight = candidateGroundHeight;
        }
    }

    GameCoreRefreshGrounding();

    {
        const float deltaX = gameState.cameraX - startingX;
        const float deltaZ = gameState.cameraZ - startingZ;
        gameState.routeDistanceMeters += sqrtf((deltaX * deltaX) + (deltaZ * deltaZ));
    }

    GameCoreUpdateRouteProgress();
}

GameFrameSnapshot GameCoreGetSnapshot(void) {
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
        .groundHeight = gameState.groundHeight,
        .routeDistanceMeters = gameState.routeDistanceMeters,
        .distanceToNextCheckpointMeters = gameState.distanceToNextCheckpointMeters,
        .activeSectorCount = gameState.activeSectorCount,
        .completedCheckpointCount = gameState.completedCheckpointCount,
        .totalCheckpointCount = gameState.routeCheckpointCount,
        .restartCount = gameState.restartCount,
        .sprinting = gameState.sprinting,
        .grounded = gameState.grounded,
        .routeComplete = gameState.routeComplete,
    };

    return snapshot;
}

void GameCoreRestartRoute(void) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
        return;
    }

    if (gameState.routeComplete) {
        GameCoreResetRouteProgress();
        GameCoreResetRuntimeState();
        GameCoreUpdateRouteProgress();
        printf("[GameCore] Route restart from initial spawn\n");
        return;
    }

    gameState.restartCount += 1;
    GameCoreRestartFromRespawnAnchor();
    GameCoreUpdateRouteProgress();
    printf("[GameCore] Route restart to %.2f %.2f %.2f\n", gameState.respawnX, gameState.respawnY, gameState.respawnZ);
}

void GameCoreResetDebugState(void) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
        return;
    }

    GameCoreResetRouteProgress();
    GameCoreResetRuntimeState();
    GameCoreUpdateRouteProgress();
    printf("[GameCore] Debug state reset\n");
}

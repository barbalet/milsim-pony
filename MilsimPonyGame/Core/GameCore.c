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
#define GAME_CORE_NPC_PROGRESS_EPSILON_METERS 0.05f
#define GAME_CORE_NPC_STUCK_TIMEOUT_SECONDS 6.0f

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
    int activeSectorCount;
    int completedCheckpointCount;
    int activeObserverCount;
    int seeingObserverCount;
    int restartCount;
    int failCount;
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
    GameThreatObserver threatObservers[GAME_CORE_MAX_THREAT_OBSERVERS];
    int threatObserverCount;
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
    .failThreshold = 1.0f,
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

static void GameCoreUpdateDetection(double deltaTime);

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

        GameCoreRotateIntoLocalFrame(
            x - volume->centerX,
            z - volume->centerZ,
            volume->yawDegrees,
            &localX,
            &localZ
        );

        if (fabsf(localX) <= (volume->halfWidth + radius) &&
            fabsf(localZ) <= (volume->halfDepth + radius)) {
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
    gameState.seeingObserverCount = 0;
    gameState.routeFailed = false;

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
    gameState.elapsedSeconds += deltaTime;

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

static void GameCoreUpdateDetection(double deltaTime) {
    float suspicionDelta = 0;

    gameState.activeObserverCount = 0;
    gameState.seeingObserverCount = 0;

    if (gameState.routeComplete) {
        gameState.suspicionLevel = GameCoreClamp(
            gameState.suspicionLevel - (gameState.suspicionDecayPerSecond * (float)deltaTime),
            0,
            gameState.failThreshold > 0 ? gameState.failThreshold : 1.0f
        );
        return;
    }

    for (int index = 0; index < gameState.threatObserverCount; index++) {
        const GameThreatObserver *observer = &gameState.threatObservers[index];
        const float deltaX = gameState.cameraX - observer->positionX;
        const float deltaY = gameState.cameraY - observer->positionY;
        const float deltaZ = gameState.cameraZ - observer->positionZ;
        const float distanceSquared = (deltaX * deltaX) + (deltaY * deltaY) + (deltaZ * deltaZ);
        const float rangeSquared = observer->range * observer->range;

        if (distanceSquared > rangeSquared) {
            continue;
        }

        gameState.activeObserverCount += 1;

        {
            const float distance = sqrtf(distanceSquared);
            const float yawRadians = GameCoreDegreesToRadians(observer->yawDegrees);
            const float pitchRadians = GameCoreDegreesToRadians(observer->pitchDegrees);
            const float coneThreshold = cosf(GameCoreDegreesToRadians(observer->fieldOfViewDegrees * 0.5f));
            const float inverseDistance = distance > 0.0001f ? 1.0f / distance : 0.0f;
            const float toPlayerX = deltaX * inverseDistance;
            const float toPlayerY = deltaY * inverseDistance;
            const float toPlayerZ = deltaZ * inverseDistance;
            const float facingX = sinf(yawRadians) * cosf(pitchRadians);
            const float facingY = sinf(pitchRadians);
            const float facingZ = -cosf(yawRadians) * cosf(pitchRadians);
            const float viewDot = (toPlayerX * facingX) + (toPlayerY * facingY) + (toPlayerZ * facingZ);

            if (viewDot < coneThreshold) {
                continue;
            }

            if (!GameCoreHasLineOfSightToPoint(
                observer->positionX,
                observer->positionY,
                observer->positionZ,
                gameState.cameraX,
                gameState.cameraY,
                gameState.cameraZ
            )) {
                continue;
            }

            gameState.seeingObserverCount += 1;
            suspicionDelta += observer->suspicionPerSecond * (float)deltaTime;
        }
    }

    if (gameState.routeFailed) {
        return;
    }

    gameState.suspicionLevel = GameCoreClamp(
        gameState.suspicionLevel + suspicionDelta - (gameState.suspicionDecayPerSecond * (float)deltaTime),
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
    gameState.failThreshold = 1.0f;

    if (bootMode != NULL) {
        snprintf(gameState.bootMode, sizeof(gameState.bootMode), "%s", bootMode);
    } else {
        snprintf(gameState.bootMode, sizeof(gameState.bootMode), "bootstrap");
    }

    GameCoreResetDetectionState(true);
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
    GameCoreResetDetectionState(true);
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
    gameState.suspicionDecayPerSecond = suspicionDecayPerSecond > 0 ? suspicionDecayPerSecond : 0.28f;
    gameState.failThreshold = failThreshold > 0 ? failThreshold : 1.0f;

    if (observers != NULL && gameState.threatObserverCount > 0) {
        memcpy(
            gameState.threatObservers,
            observers,
            sizeof(GameThreatObserver) * (size_t)gameState.threatObserverCount
        );
    }

    GameCoreResetDetectionState(true);
    GameCoreUpdateDetection(0);
    printf("[GameCore] Detection configured with %d observers\n", gameState.threatObserverCount);
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

        while (remainingTime > 0.0f) {
            const float stepTime = remainingTime > GAME_CORE_MAX_SIMULATION_STEP_SECONDS
                ? GAME_CORE_MAX_SIMULATION_STEP_SECONDS
                : remainingTime;
            const float startingX = gameState.cameraX;
            const float startingZ = gameState.cameraZ;

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
        .groundHeight = gameState.groundHeight,
        .routeDistanceMeters = gameState.routeDistanceMeters,
        .distanceToNextCheckpointMeters = gameState.distanceToNextCheckpointMeters,
        .suspicionLevel = gameState.suspicionLevel,
        .activeSectorCount = gameState.activeSectorCount,
        .completedCheckpointCount = gameState.completedCheckpointCount,
        .totalCheckpointCount = gameState.routeCheckpointCount,
        .activeObserverCount = gameState.activeObserverCount,
        .seeingObserverCount = gameState.seeingObserverCount,
        .restartCount = gameState.restartCount,
        .failCount = gameState.failCount,
        .sprinting = gameState.sprinting,
        .grounded = gameState.grounded,
        .routeComplete = gameState.routeComplete,
        .routeFailed = gameState.routeFailed,
    };

    return snapshot;
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
    printf("[GameCore] Route restart to %.2f %.2f %.2f\n", gameState.respawnX, gameState.respawnY, gameState.respawnZ);
}

void GameCoreClearFailure(void) {
    if (!gameState.bootstrapped) {
        GameCoreBootstrap("implicit");
        return;
    }

    GameCoreResetDetectionState(false);
    GameCoreUpdateDetection(0);
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
    printf("[GameCore] Debug state reset\n");
}

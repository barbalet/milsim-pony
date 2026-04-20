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
    float groundHeight;
    int activeSectorCount;
    bool sprinting;
    bool grounded;
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
void GameCoreSetMoveIntent(float strafeIntent, float forwardIntent);
void GameCoreSetSprint(bool sprinting);
void GameCoreAddLookDelta(float deltaX, float deltaY);
void GameCoreTick(double deltaTime);
GameFrameSnapshot GameCoreGetSnapshot(void);
void GameCoreResetDebugState(void);

#ifdef __cplusplus
}
#endif

#endif

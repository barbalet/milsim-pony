#ifndef GAME_CORE_H
#define GAME_CORE_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

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
    bool sprinting;
} GameFrameSnapshot;

void GameCoreBootstrap(const char *bootMode);
void GameCoreConfigureSpawn(float x, float y, float z, float yawDegrees, float pitchDegrees);
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

#include "include/GameCore.h"

#include <math.h>
#include <stdio.h>
#include <string.h>

typedef struct GameCoreState {
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
    bool bootstrapped;
    char bootMode[64];
} GameCoreState;

static GameCoreState gameState = {
    .cameraY = 1.65f,
    .cameraZ = 4.5f,
    .pitchDegrees = -12.0f,
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

void GameCoreBootstrap(const char *bootMode) {
    memset(&gameState, 0, sizeof(gameState));
    gameState.cameraY = 1.65f;
    gameState.cameraZ = 4.5f;
    gameState.pitchDegrees = -12.0f;
    gameState.bootstrapped = true;

    if (bootMode != NULL) {
        snprintf(gameState.bootMode, sizeof(gameState.bootMode), "%s", bootMode);
    } else {
        snprintf(gameState.bootMode, sizeof(gameState.bootMode), "bootstrap");
    }

    printf("[GameCore] Bootstrap mode: %s\n", gameState.bootMode);
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

    const float baseMoveSpeed = gameState.sprinting ? 7.0f : 3.5f;
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

    gameState.moveSpeed = baseMoveSpeed * magnitude;
    gameState.cameraX += worldMoveX * baseMoveSpeed * (float)deltaTime;
    gameState.cameraZ += worldMoveZ * baseMoveSpeed * (float)deltaTime;
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
        .sprinting = gameState.sprinting,
    };

    return snapshot;
}

void GameCoreResetDebugState(void) {
    char bootMode[64] = {0};
    memcpy(bootMode, gameState.bootMode, sizeof(gameState.bootMode));
    GameCoreBootstrap(bootMode[0] == '\0' ? "bootstrap" : bootMode);
    printf("[GameCore] Debug state reset\n");
}

#include <math.h>
#include <stdio.h>

#include "GameCore.h"

static void configureFlatWorld(float wallHalfWidth, float wallHalfDepth, float wallCenterX, float wallCenterZ) {
    GameSectorBounds sector = {
        .minX = -20.0f,
        .minZ = -20.0f,
        .maxX = 20.0f,
        .maxZ = 20.0f,
        .activationPadding = 2.0f,
    };
    GameGroundSurface ground = {
        .centerX = 0.0f,
        .centerZ = 0.0f,
        .halfWidth = 20.0f,
        .halfDepth = 20.0f,
        .yawDegrees = 0.0f,
        .northWestHeight = 0.0f,
        .northEastHeight = 0.0f,
        .southEastHeight = 0.0f,
        .southWestHeight = 0.0f,
    };
    GameCollisionVolume wall = {
        .centerX = wallCenterX,
        .centerY = 1.0f,
        .centerZ = wallCenterZ,
        .halfWidth = wallHalfWidth,
        .halfHeight = 1.0f,
        .halfDepth = wallHalfDepth,
        .yawDegrees = 0.0f,
    };

    if (wallHalfWidth > 0.0f && wallHalfDepth > 0.0f) {
        GameCoreConfigureWorld(&sector, 1, &wall, 1, &ground, 1);
    } else {
        GameCoreConfigureWorld(&sector, 1, NULL, 0, &ground, 1);
    }
}

static int verifyNPCReachesSimpleTarget(void) {
    GameNPCState npc;

    GameCoreBootstrap("npc-regression");
    configureFlatWorld(0.0f, 0.0f, 0.0f, 0.0f);
    GameCoreInitializeNPC(&npc, 0.0f, 1.65f, 0.0f, 0.0f, 0.0f);
    GameCoreConfigureNPCTraversal(&npc, 4.0f, 6.0f, 0.36f);
    GameCoreSetNPCTarget(&npc, 0.0f, 0.0f, -6.0f, 0.8f, false);

    for (int index = 0; index < 240 && npc.hasTarget && !npc.stuck; index++) {
        GameCoreTickNPC(&npc, 1.0 / 30.0);
    }

    if (!npc.targetReached || npc.distanceToTargetMeters > 0.8f) {
        fprintf(
            stderr,
            "npc_simple_target_failed reached=%d stuck=%d distance=%.3f position=(%.3f, %.3f)\n",
            npc.targetReached,
            npc.stuck,
            npc.distanceToTargetMeters,
            npc.positionX,
            npc.positionZ
        );
        return 1;
    }

    printf("npc_simple_target_ok\n");
    return 0;
}

static int verifyNPCStopsAtSolidWall(void) {
    GameNPCState npc;

    GameCoreBootstrap("npc-regression");
    configureFlatWorld(20.0f, 0.2f, 0.0f, -2.0f);
    GameCoreInitializeNPC(&npc, 0.0f, 1.65f, 0.0f, 0.0f, 0.0f);
    GameCoreConfigureNPCTraversal(&npc, 4.0f, 6.0f, 0.36f);
    GameCoreSetNPCTarget(&npc, 0.0f, 0.0f, -6.0f, 0.8f, false);

    for (int index = 0; index < 360 && npc.hasTarget && !npc.stuck; index++) {
        GameCoreTickNPC(&npc, 1.0 / 30.0);
    }

    if (npc.targetReached || npc.positionZ < -1.55f) {
        fprintf(
            stderr,
            "npc_solid_wall_failed reached=%d stuck=%d position=(%.3f, %.3f)\n",
            npc.targetReached,
            npc.stuck,
            npc.positionX,
            npc.positionZ
        );
        return 1;
    }

    printf("npc_solid_wall_ok\n");
    return 0;
}

int main(void) {
    int failures = 0;

    failures += verifyNPCReachesSimpleTarget();
    failures += verifyNPCStopsAtSolidWall();

    if (failures == 0) {
        printf("npc_regression_ok\n");
        return 0;
    }

    return 1;
}

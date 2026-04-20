#include <math.h>
#include <stdio.h>

#include "include/GameCore.h"

static void configureFlatWorldWithWall(float wallZ, float wallHalfDepth) {
    GameSectorBounds sector = {
        .minX = -10.0f,
        .minZ = -10.0f,
        .maxX = 10.0f,
        .maxZ = 20.0f,
        .activationPadding = 2.0f,
    };
    GameCollisionVolume wall = {
        .centerX = 0.0f,
        .centerY = 1.0f,
        .centerZ = wallZ,
        .halfWidth = 2.0f,
        .halfHeight = 1.0f,
        .halfDepth = wallHalfDepth,
        .yawDegrees = 0.0f,
    };
    GameGroundSurface ground = {
        .centerX = 0.0f,
        .centerZ = 5.0f,
        .halfWidth = 10.0f,
        .halfDepth = 15.0f,
        .yawDegrees = 0.0f,
        .northWestHeight = 0.0f,
        .northEastHeight = 0.0f,
        .southEastHeight = 0.0f,
        .southWestHeight = 0.0f,
    };

    GameCoreConfigureWorld(&sector, 1, &wall, 1, &ground, 1);
}

static int verifyMovementSubsteps(void) {
    GameCoreBootstrap("cycle8-regression");
    configureFlatWorldWithWall(1.0f, 0.10f);
    GameCoreConfigureSpawn(0.0f, 1.65f, 0.0f, 180.0f, 0.0f);
    GameCoreConfigureTraversal(4.2f, 6.8f, 0.08f);
    GameCoreSetMoveIntent(0.0f, 1.0f);
    GameCoreTick(0.5);

    {
        GameFrameSnapshot snapshot = GameCoreGetSnapshot();
        if (snapshot.cameraZ >= 0.75f) {
            fprintf(
                stderr,
                "movement_substeps_failed expected blocker stop before z=0.75 but got z=%.3f\n",
                snapshot.cameraZ
            );
            return 1;
        }
    }

    printf("movement_substeps_ok\n");
    return 0;
}

static int verifyThinOccluderSightBlock(void) {
    GameThreatObserver observer = {
        .positionX = 0.0f,
        .positionY = 1.65f,
        .positionZ = 0.0f,
        .yawDegrees = 180.0f,
        .pitchDegrees = 0.0f,
        .range = 20.0f,
        .fieldOfViewDegrees = 40.0f,
        .suspicionPerSecond = 1.0f,
    };

    GameCoreBootstrap("cycle8-regression");
    configureFlatWorldWithWall(4.375f, 0.05f);
    GameCoreConfigureSpawn(0.0f, 1.65f, 10.0f, 0.0f, 0.0f);
    GameCoreConfigureDetection(&observer, 1, 0.0f, 1.0f);
    GameCoreTick(0.1);

    {
        GameFrameSnapshot snapshot = GameCoreGetSnapshot();
        if (snapshot.seeingObserverCount != 0 || fabsf(snapshot.suspicionLevel) > 0.0001f) {
            fprintf(
                stderr,
                "thin_occluder_failed expected no sighting but got seeing=%d suspicion=%.3f\n",
                snapshot.seeingObserverCount,
                snapshot.suspicionLevel
            );
            return 1;
        }
    }

    printf("thin_occluder_ok\n");
    return 0;
}

int main(void) {
    int failures = 0;

    failures += verifyMovementSubsteps();
    failures += verifyThinOccluderSightBlock();

    if (failures == 0) {
        printf("cycle8_regression_ok\n");
        return 0;
    }

    return 1;
}

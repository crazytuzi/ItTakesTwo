import Vino.Trajectory.TrajectoryDrawer;

class AVacuumShootingActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UTrajectoryDrawer TrajectoryDrawer;
}
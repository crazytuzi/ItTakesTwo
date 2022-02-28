class ACreepyHand : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HandRoot;

	UPROPERTY(DefaultComponent, Attach = HandRoot)
	UPoseableMeshComponent HandMesh;
}
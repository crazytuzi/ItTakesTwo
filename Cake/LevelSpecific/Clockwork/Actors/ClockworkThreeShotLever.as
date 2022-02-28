
import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.TeleportableThreeShotInteraction;

class AClockworkThreeShotLever: ATeleportableThreeShotInteraction
{
	UPROPERTY(DefaultComponent, Attach = LeverBaseMesh)
	UHazeSkeletalMeshComponentBase LeverAnimActor;

	UPROPERTY(DefaultComponent, Attach = LeverAnimActor)
	UStaticMeshComponent LeverMesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LeverBaseMesh;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

}
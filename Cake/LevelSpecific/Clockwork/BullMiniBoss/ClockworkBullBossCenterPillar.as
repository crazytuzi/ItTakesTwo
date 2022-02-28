import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBossData;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;


class AClockworkBullBossPillar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent JumpToSidePosition;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent StatueMesh;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UTimeControlActorComponent TimeComponent;

	UPROPERTY(Category = "Events")
	FBullBossImpactPillarEventSignature OnChargeImpact;

	UPROPERTY()
	EClockworkBullBossPillarStatus PillarStatus;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	// UFUNCTION()
	// void OnImpact(EClockworkBullBossPillarStatus NewStatus)
	// {
	// 	// PillarStatus = NewStatus;
	// 	OnChargeImpact.Broadcast();
	// }
}
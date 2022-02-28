import Vino.Movement.Components.MovementComponent;

UCLASS(Abstract)
class AShadowLeech : AHazeCharacter
{
	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;

	UPROPERTY()
	bool bFollowFromStart = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp.Setup(CapsuleComponent);

		AddCapability(n"ShadowLeechFollowCapability");

		if (bFollowFromStart)
			SetCapabilityActionState(n"FollowPlayers", EHazeActionState::Active);
	}

	UFUNCTION()
	void StartFollowingPlayers()
	{
		SetCapabilityActionState(n"FollowPlayers", EHazeActionState::Active);
	}
}
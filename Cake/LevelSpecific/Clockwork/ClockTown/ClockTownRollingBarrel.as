import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.Movement.Components.MovementComponent;

class AClockTownRollingBarrel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BarrelRoot;

	UPROPERTY(DefaultComponent, Attach = BarrelRoot)
	UStaticMeshComponent BarrelMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlayerAttachmentPoint;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UCapsuleComponent CollisionComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> RequiredCapability;

	bool bPlayerOnBarrel = false;
	AHazePlayerCharacter PlayerOnBarrel;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp.Setup(CollisionComp);

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnPlatform");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"LeavePlatform");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);

		Capability::AddPlayerCapabilityRequest(RequiredCapability);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(RequiredCapability);
	}

	UFUNCTION(NotBlueprintCallable)
	void LandOnPlatform(AHazePlayerCharacter Player, FHitResult Hit)
	{
		if (bPlayerOnBarrel)
			return;

		PlayerOnBarrel = Player;
		Player.SetCapabilityAttributeObject(n"RollingBarrel", this);
		Player.SetCapabilityActionState(n"RollingBarrel", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION(NotBlueprintCallable)
	void LeavePlatform(AHazePlayerCharacter Player)
	{
		bPlayerOnBarrel = false;
		PlayerOnBarrel = nullptr;
	}
}
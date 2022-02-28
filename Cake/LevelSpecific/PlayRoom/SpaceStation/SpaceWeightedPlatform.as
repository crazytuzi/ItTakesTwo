import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

UCLASS(Abstract)
class ASpaceWeightedPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.bRenderWhileDisabled = true;
	default DisableComponent.AutoDisableRange = 15000.f;

	UPROPERTY(meta = (MakeEditWidget))
	FVector EndLocation;
	FVector StartLocation;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MovePlatformTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike VerticalOffsetSpeedMultiplierTimeLike;

	TArray<AHazePlayerCharacter> PlayersOnTop;
	TArray<AHazePlayerCharacter> PlayersOnBottom;

	FHazeConstrainedPhysicsValue PhysValue;
	default PhysValue.LowerBound = -600.f;
	default PhysValue.UpperBound = 600.f;
	default PhysValue.LowerBounciness = 0.f;
	default PhysValue.UpperBounciness = 0.f;
	default PhysValue.Friction = 1.5f;

	float LandingImpulse = 180.f;
	float AccelerationPerPlayer = 450.f;
	float CurrentAccelerationMultiplier = 1.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		EndLocation = ActorTransform.TransformPosition(EndLocation);

		MovePlatformTimeLike.BindUpdate(this, n"UpdateMovePlatform");
		VerticalOffsetSpeedMultiplierTimeLike.BindUpdate(this, n"UpdateVerticalOffsetSpeedMultiplier");

		if (HasControl())
		{
			MovePlatformTimeLike.PlayFromStart();
			VerticalOffsetSpeedMultiplierTimeLike.PlayFromStart();
		}

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"PlayerLanded");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"PlayerLeft");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateMovePlatform(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(StartLocation, EndLocation, CurValue);
		SetActorLocation(CurLoc);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateVerticalOffsetSpeedMultiplier(float CurValue)
	{
		CurrentAccelerationMultiplier = CurValue;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PhysValue.AccelerateTowards(0.f, 160.f);
		PhysValue.Update(DeltaTime);

		float PlayerAcceleration = AccelerationPerPlayer * CurrentAccelerationMultiplier;

		for (AHazePlayerCharacter Player : PlayersOnBottom)
		{
			PhysValue.AddAcceleration(PlayerAcceleration);
		}
		for (AHazePlayerCharacter Player : PlayersOnTop)
		{
			PhysValue.AddAcceleration(-PlayerAcceleration);
		}

		PlatformRoot.SetRelativeLocation(FVector(0.f, 0.f, PhysValue.Value));
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerLanded(AHazePlayerCharacter Player, FHitResult Hit)
	{
		if (Hit.ImpactNormal == FVector::UpVector)
			PlayersOnTop.AddUnique(Player);
		else
			PlayersOnBottom.AddUnique(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerLeft(AHazePlayerCharacter Player)
	{
		if (PlayersOnTop.Contains(Player))
			PlayersOnTop.Remove(Player);
		else if (PlayersOnBottom.Contains(Player))
			PlayersOnBottom.Remove(Player);
	}
}
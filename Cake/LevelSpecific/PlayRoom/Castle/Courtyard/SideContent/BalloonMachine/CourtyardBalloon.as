import Vino.Movement.Components.GroundPound.GroundPoundThroughComponent;
import Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonTargetOscillation;
class ACourtyardBalloon : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UCannonTargetOscillation OscillationComp;
	
	UPROPERTY(DefaultComponent, Attach = OscillationComp)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent BounceRoot;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UStaticMeshComponent BalloonMesh;

	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent ImpactedCallbackComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;

	FHazeAcceleratedFloat BounceOffsetAcceleratedFloat;

	UPROPERTY(Category = Setup)
	bool bFloatUpwards = false;

	UPROPERTY(Category = Setup)
	TSubclassOf<UHazeCapability> BouncePadCapabilityType;

	UPROPERTY(Category = Setup)
	bool bAddBalloonForceOnBounce = true;

	UPROPERTY(Category = Setup|Pop)
	bool bPopOnGroundPound = false;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PopAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BounceAudioEvent;
	
	UPROPERTY(Category = Setup|Pop)
	UNiagaraSystem PopEffect;

	UPROPERTY(Category = Setup)
	TArray<UMaterialInstance> Colors;

	UPROPERTY()
	bool bInflated = true;

	FVector Velocity;
	FVector SwayDirection;
	const float Drag = 0.5f;
	const float LiftAcceleration = 120.f;
	const float SwayAcceleration = 20.f;

	FVector StartLocation;

	UPROPERTY()
	float MaxHeight = 2000.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		if (BouncePadCapabilityType.IsValid())
			Capability::AddPlayerCapabilityRequest(BouncePadCapabilityType.Get());

		ImpactedCallbackComp.OnActorDownImpactedByPlayer.AddUFunction(this, n"OnPlayerLanded");
		ImpactedCallbackComp.OnActorForwardImpactedByPlayer.AddUFunction(this, n"OnPlayerImpacted");
		ImpactedCallbackComp.OnActorUpImpactedByPlayer.AddUFunction(this, n"OnPlayerImpacted");

		StartLocation = ActorLocation;

		if (!bInflated)
		{
			OscillationComp.bAllowOscillation = false;
			MeshRoot.SetRelativeScale3D(0.f);
			SetActorHiddenInGame(true);
			SetActorEnableCollision(false);
		}
	}

	UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason Reason)
	{
		if (BouncePadCapabilityType.IsValid())
			Capability::RemovePlayerCapabilityRequest(BouncePadCapabilityType.Get());
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		BounceOffsetAcceleratedFloat.SpringTo(0.f, 100.f, 0.15f, DeltaTime);
		BounceRoot.SetRelativeLocation(FVector::UpVector * BounceOffsetAcceleratedFloat.Value);

		FVector SpawnToBalloon = ActorLocation - StartLocation;
		float HeightFromSpawn = FVector::UpVector.DotProduct(SpawnToBalloon);

		if (bInflated && HeightFromSpawn >= MaxHeight)
			PopBalloon();
	}

	UFUNCTION()
	void OnPlayerLanded(AHazePlayerCharacter ImpactingPlayer, const FHitResult& Hit)
	{
		ImpactingPlayer.SetCapabilityAttributeValue(n"VerticalVelocity", 2600.f);
		ImpactingPlayer.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);
		ImpactingPlayer.PlayerHazeAkComp.HazePostEvent(BounceAudioEvent);

		if (bInflated && bAddBalloonForceOnBounce)
			BounceOffsetAcceleratedFloat.Velocity -= 2000.f;

		if (ImpactingPlayer.IsAnyCapabilityActive(n"CannonShoot") ||
			bPopOnGroundPound && ImpactingPlayer.IsAnyCapabilityActive(MovementSystemTags::GroundPound))
		{
			PopBalloon();
		}
	}

	UFUNCTION()
	void OnPlayerImpacted(AHazePlayerCharacter ImpactingPlayer, const FHitResult& Hit)
	{
		if (ImpactingPlayer.IsAnyCapabilityActive(n"CannonShoot"))
			PopBalloon();
	}

	void PopBalloon()
	{
		if (!HasControl())
			return;

		NetPopBalloon();
	}

	UFUNCTION(NetFunction)
	void NetPopBalloon()
	{
		Niagara::SpawnSystemAtLocation(PopEffect, ActorLocation, ActorRotation);
		UHazeAkComponent::HazePostEventFireForget(PopAudioEvent, this.GetActorTransform());
		bInflated = false;

		CleanupCurrentMovementTrail();
		
		SetActorHiddenInGame(true);
		SetActorEnableCollision(false);
	}

	UFUNCTION(CallInEditor)
	void RandomizeBalloonColour()
	{
		// Pick a random colour
		int Index = FMath::RandRange(0, Colors.Num() - 1);
		BalloonMesh.SetMaterial(0, Colors[Index]);
	}
}
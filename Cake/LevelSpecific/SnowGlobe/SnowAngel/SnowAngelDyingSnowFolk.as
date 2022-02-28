import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackComponent;
import Vino.BouncePad.BouncePadResponseComponent;

class ASnowAngelDyingSnowFolk : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.SetMobility(EComponentMobility::Static);

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent Collision;
	default Collision.SphereRadius = 180;
	default Collision.CollisionProfileName = n"BlockAll";
	default Collision.SetMobility(EComponentMobility::Static);

	UPROPERTY(DefaultComponent, Attach = Root)	
	UHazeCharacterSkeletalMeshComponent SkeletalMesh;
	default SkeletalMesh.SetMobility(EComponentMobility::Static);

	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent ImpactComponent;
	
	UPROPERTY(DefaultComponent)
	UBouncePadResponseComponent BouncePadResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.AutoDisableRange = 9000.f;
	default DisableComp.bAutoDisable = true;

	UPROPERTY(Category = "Bouncing")
	float BounceVelocity = 1000.f;

	UPROPERTY(Category = "Bouncing")
	float BounceHorizontalVelocityModifier = 0.5f;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayDyingAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopDyingAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BounceAudioEvent;

	bool bIsDead;
	bool bDyingStopped = false;
	float DyingAmount;
	float InterpSpeed = 0.011f;
	float SpeedIncreaseAmount = 1.03f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComponent.OnActorDownImpactedByPlayer.AddUFunction(this, n"HandlePlayerDownImpact");
		BouncePadResponseComp.OnBounce.AddUFunction(this, n"HandlePlayerBounce");
	}

	UFUNCTION()
	void HandlePlayerDownImpact(AHazePlayerCharacter Player, const FHitResult& Hit)
	{
		Player.SetCapabilityAttributeValue(n"VerticalVelocity", BounceVelocity);
		Player.SetCapabilityAttributeValue(n"HorizontalVelocityModifier", BounceHorizontalVelocityModifier);
		Player.SetCapabilityAttributeObject(n"BouncedObject", this);
		Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);
	}

	UFUNCTION()
	void HandlePlayerBounce(AHazePlayerCharacter Player, bool bGroundPounded)
	{
		if (BounceAudioEvent != nullptr)
			HazeAkComp.HazePostEvent(BounceAudioEvent);
	}

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		SkeletalMesh.SetCullDistance(Editor::GetDefaultCullingDistance(SkeletalMesh) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SkeletalMesh.SetAnimFloatParam(n"DyingAmount", DyingAmount);

		if (bIsDead)
		{
			DyingAmount = FMath::FInterpTo(DyingAmount, 1.f, DeltaTime, InterpSpeed);
			InterpSpeed *= SpeedIncreaseAmount;
		}
		if (bIsDead && !bDyingStopped)
		{
			HazeAkComp.HazePostEvent(StopDyingAudioEvent);
			bDyingStopped = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		if (!bDyingStopped)
			HazeAkComp.HazePostEvent(PlayDyingAudioEvent);
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		return false;
	}
}
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightResponseComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackComponent;
import Vino.BouncePad.BouncePadResponseComponent;

class ASnowAngelSnowFolk : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.SetMobility(EComponentMobility::Static);

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase SkeletalMeshComponent;
	default SkeletalMeshComponent.AnimationMode = EAnimationMode::AnimationSingleNode;

	UPROPERTY(DefaultComponent)
	USphereComponent SphereCollision;
	default SphereCollision.SphereRadius = 180;
	default SphereCollision.CollisionProfileName = n"BlockAll";
	default SphereCollision.SetMobility(EComponentMobility::Static);

	UPROPERTY(DefaultComponent)
	USnowballFightResponseComponent SnowballResponseComponent;

	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent ImpactComponent;

	UPROPERTY(DefaultComponent)
	UBouncePadResponseComponent BouncePadResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent AudioComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.AutoDisableRange = 9000.f;
	default DisableComp.bAutoDisable = true;

	UPROPERTY(Category = "Snow Angel")
	FHazePlaySlotAnimationParams IdleAnimation;
	default IdleAnimation.bLoop = true;

	UPROPERTY(Category = "Snow Angel")
	FHazePlaySlotAnimationParams HitReactAnimation;
	bool bIsHit = false;

	UPROPERTY(Category = "Snow Angel")
	TSubclassOf<ADecalActor> DecalActorClass;

	UPROPERTY(Category = "Snow Angel")
	float DecalOffsetZ = -90.f;

	UPROPERTY(Category = "Bouncing")
	float BounceVelocity = 1000.f;

	UPROPERTY(Category = "Bouncing")
	float BounceHorizontalVelocityModifier = 0.5f;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent BounceAudioEvent;

	ADecalActor DecalActor;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (IdleAnimation.Animation == nullptr)
			return;

		// Show animation pose in editor
		FSingleAnimationPlayData AnimationData;
		AnimationData.AnimToPlay = IdleAnimation.Animation;
		AnimationData.bSavedLooping = IdleAnimation.bLoop;
		AnimationData.SavedPlayRate = IdleAnimation.PlayRate;
		SkeletalMeshComponent.AnimationData = AnimationData;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SnowballResponseComponent.OnSnowballHit.AddUFunction(this, n"HandleSnowballHit");
		ImpactComponent.OnActorDownImpactedByPlayer.AddUFunction(this, n"HandlePlayerDownImpact");
		BouncePadResponseComp.OnBounce.AddUFunction(this, n"HandlePlayerBounce");
	}

	UFUNCTION()
	void HandleSnowballHit(AActor ProjectileOwner, FHitResult Hit, FVector Velocity)
	{
		if (bIsHit || HitReactAnimation.Animation == nullptr)
			return;
		
		bIsHit = true;

		// Play hit reaction animation
		SkeletalMeshComponent.PlaySlotAnimation(FHazeAnimationDelegate(),
			FHazeAnimationDelegate(this, n"HandleHitReactEnd"),
			HitReactAnimation);
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
	void HandleHitReactEnd()
	{
		if (IdleAnimation.Animation == nullptr)
			return;
	
		bIsHit = false;

		// Return to idle animation
		SkeletalMeshComponent.PlaySlotAnimation(FHazeAnimationDelegate(),
			FHazeAnimationDelegate(),
			IdleAnimation);
	}

	UFUNCTION()
	void HandlePlayerBounce(AHazePlayerCharacter Player, bool bGroundPounded)
	{
		if (BounceAudioEvent != nullptr)
			AudioComp.HazePostEvent(BounceAudioEvent);
	}

	void SpawnDecal()
	{
		if (!DecalActorClass.IsValid())
			return;

		FVector SpawnOffset = GetActorForwardVector() * 10.f + FVector::UpVector * DecalOffsetZ;
		FRotator RotationOffset = FRotator(0.f, -90.f, 0.f);

		DecalActor = Cast<ADecalActor>(SpawnActor(DecalActorClass, ActorLocation + SpawnOffset, ActorRotation + RotationOffset));
	}
}
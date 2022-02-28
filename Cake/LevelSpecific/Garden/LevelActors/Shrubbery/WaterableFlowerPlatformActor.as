import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackComponent;

class AWaterableFlowerPlatformActor : AHazeActor
{
	default SetActorTickEnabled(false);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent , Attach = RootComp)
	UStaticMeshComponent PlatformMesh;
	default PlatformMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CollisionRoot;

	UPROPERTY(DefaultComponent, Attach = CollisionRoot)
	UStaticMeshComponent PlatformCollision;
	default PlatformCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent ImpactCallbackComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent UnwitherAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent JumpOnAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent JumpOffAudioEvent;

	UPROPERTY(Category = "Settings")
	FHazeTimeLike WitherTimeLike;

	UPROPERTY(Category = "Setup")
	int DynamicMaterialIndex = 0;

	UPROPERTY(Category = "Settings")
	float BlendModPerPlayer = 0.05f;

	UPROPERTY(Category = "Settings")
	float BlendSpeed = 500.f;

	UPROPERTY(Category = "Settings")
	float RollPerPlayer = 2.f;

	UPROPERTY(Category = "Settings")
	float RollSpeed = 400.f;

	UPROPERTY(Category = "Settings")
	float HeightLossPerPlayer = 12.5f;

	UPROPERTY(Category = "Settings")
	float TranslationSpeed = 60.f;;

	float BlendTarget = 0.95f;

	float TargetHeight;

	float TargetRoll;

	float OriginalHeight;

	UMaterialInstanceDynamic DynMat;

	TArray<AHazePlayerCharacter> ImpactedPlayers;

	FHazeAcceleratedFloat AcceleratedBlend;

	FHazeAcceleratedFloat AcceleratedRoll;

	FHazeAcceleratedFloat AcceleratedHeight;

	FRotator OriginalRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DynMat = PlatformMesh.CreateDynamicMaterialInstance(DynamicMaterialIndex);
		DynMat.SetScalarParameterValue(n"BlendValue", 0.f);

		WitherTimeLike.BindUpdate(this, n"WitherTimeLikeUpdate");
		WitherTimeLike.BindFinished(this, n"WitherTimeLikeFinished");

		ImpactCallbackComp.OnActorDownImpactedByPlayer.AddUFunction(this, n"OnDownImpacted");
		ImpactCallbackComp.OnDownImpactEndingPlayer.AddUFunction(this, n"OnDownImpactEnded");

		OriginalRotation = CollisionRoot.RelativeRotation;


		OriginalHeight = CollisionRoot.RelativeLocation.Z;
		TargetHeight = OriginalHeight;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

		AcceleratedBlend.SpringTo(BlendTarget, BlendSpeed, 0.2f, DeltaSeconds);
		DynMat.SetScalarParameterValue(n"BlendValue", AcceleratedBlend.Value);

		//PrintToScreen("Blend: " + BlendTarget);

		AcceleratedRoll.SpringTo(TargetRoll, RollSpeed, 0.2f, DeltaSeconds);
		CollisionRoot.SetRelativeRotation(FRotator(CollisionRoot.RelativeRotation.Pitch, CollisionRoot.RelativeRotation.Yaw, AcceleratedRoll.Value));

		//PrintToScreen("Roll: " + AcceleratedRoll.Value);

		AcceleratedHeight.SpringTo(TargetHeight, TranslationSpeed, 0.2f, DeltaSeconds);
		CollisionRoot.SetRelativeLocation(FVector(CollisionRoot.RelativeLocation.X, CollisionRoot.RelativeLocation.Y, AcceleratedHeight.Value));

		//PrintToScreen("Height: " + AcceleratedHeight.Value);
	}

	UFUNCTION(BlueprintCallable)
	void UnWitherPlatform()
	{
		WitherTimeLike.PlayFromStart();
		UHazeAkComponent::HazePostEventFireForget(UnwitherAudioEvent, this.GetActorTransform());
	}

	UFUNCTION()
	void WitherTimeLikeUpdate(float CurrentValue)
	{
		DynMat.SetScalarParameterValue(n"BlendValue", CurrentValue);
	}

	UFUNCTION()
	void WitherTimeLikeFinished()
	{
		PlatformCollision.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

		AcceleratedBlend.Value = 0.95f;
		AcceleratedRoll.Value = CollisionRoot.RelativeRotation.Roll;
		AcceleratedHeight.Value = TargetHeight;
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void OnDownImpacted(AHazePlayerCharacter Player, FHitResult Hit)
	{
		if(Player != nullptr)
			ImpactedPlayers.AddUnique(Player);

		BlendTarget = 0.95f - (ImpactedPlayers.Num() * BlendModPerPlayer);

		TargetRoll = OriginalRotation.Roll + (ImpactedPlayers.Num() * RollPerPlayer);

		TargetHeight = OriginalHeight - (ImpactedPlayers.Num() * HeightLossPerPlayer);

		Player.PlayerHazeAkComp.HazePostEvent(JumpOnAudioEvent);
	}

	UFUNCTION()
	void OnDownImpactEnded(AHazePlayerCharacter Player)
	{
		if(Player != nullptr)
			ImpactedPlayers.Remove(Player);
		
		BlendTarget = 0.95f - (ImpactedPlayers.Num() * BlendModPerPlayer);

		TargetRoll = OriginalRotation.Roll + (ImpactedPlayers.Num() * RollPerPlayer);

		TargetHeight = OriginalHeight - (ImpactedPlayers.Num() * HeightLossPerPlayer);

		Player.PlayerHazeAkComp.HazePostEvent(JumpOffAudioEvent);
	}
}
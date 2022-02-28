import Effects.SlinkyTunnel;

event void FOnSlinkyEntered(AHazePlayerCharacter Player);
event void FOnSlinkyExited(AHazePlayerCharacter Player);

class AHopscotchSlinkyTunnel : ASlinkySpline
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent OnEnterCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LerpToLocation;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent SlinkyCamera;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ExtendTunnelAudioEvent;

	UPROPERTY()
	float EnterCollisionForwardExtent = 250.f;

	UPROPERTY()
	TSubclassOf<UHazeCapability> SlinkyCapability;

	UPROPERTY()
	FOnSlinkyEntered OnSlinkyEntered;

	UPROPERTY()
	FOnSlinkyExited OnSlinkyExited;

	UPROPERTY()
	bool bStartHidden = false;

	UPROPERTY()
	bool bStartWithEnterCollisionDisabled = false;

	UPROPERTY()
	FHazeTimeLike ScaleTunnelTimeline;
	default ScaleTunnelTimeline.Duration = 1.5f;

	UPROPERTY()
	UAkAudioEvent ScaleTunnelAudio;

	UPROPERTY()
	UAkAudioEvent EnterTunnelAudio;

	UPROPERTY()
	bool bBoolShouldUseSlinkyCamera = false;

	bool bHasBeenExtended = false;
	TPerPlayer<bool> bHasTriggered;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnEnterCollision.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");

		ScaleTunnelTimeline.BindUpdate(this, n"ScaleTunnelTimelineUpdate");

		if (bStartWithEnterCollisionDisabled)
			OnEnterCollision.CollisionEnabled = ECollisionEnabled::NoCollision;
		
		SetSlinky(0.9, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Super::Tick(DeltaTime);
	}

	UFUNCTION()
	void PlayerEnteredSlinky(AHazePlayerCharacter Player)
	{
		OnSlinkyEntered.Broadcast(Player);
		Player.PlayerHazeAkComp.HazePostEvent(EnterTunnelAudio);
		bHasBeenExtended = false;
	}

	UFUNCTION()
	void PlayerExitedSlinky(AHazePlayerCharacter Player)
	{
		OnSlinkyExited.Broadcast(Player);
	}

	UFUNCTION()
	void StartScalingTunnel()
	{
		ScaleTunnelTimeline.PlayFromStart();
		UHazeAkComponent::HazePostEventFireForget(ScaleTunnelAudio, GetActorTransform());
 		SetSlinkyTarget(0.0, 0.25);
	}

	UFUNCTION()
	void ExtendTunnel()
	{	
		if (!bHasBeenExtended)
		{
			NetExtendTunnel();
		}
	}

	UFUNCTION(NetFunction)
	void NetExtendTunnel()
	{
		bHasBeenExtended = true;
		SetSlinkyTarget(0.0, 1.0);
		UHazeAkComponent::HazePostEventFireForget(ExtendTunnelAudioEvent, FTransform()); 
	}

	UFUNCTION()
	void SetEnterCollisionEnabled()
	{
		OnEnterCollision.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();
		
		OnEnterCollision.SetRelativeLocation(FVector(-EnterCollisionForwardExtent, OnEnterCollision.RelativeLocation.Y, OnEnterCollision.RelativeLocation.Z));
		OnEnterCollision.SetBoxExtent(FVector(EnterCollisionForwardExtent, OnEnterCollision.BoxExtent.Y, OnEnterCollision.BoxExtent.Z));
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr && Player.HasControl())
		{
			NetActivateSlinkyCapability(Player);
		}
    }

	UFUNCTION()
	void ForcePlayerToTunnel(AHazePlayerCharacter Player)
	{
		if (bHasTriggered[Player])
			return;
		
		bHasTriggered[Player] = true;
		Player.AddCapability(SlinkyCapability);
		Player.SetCapabilityAttributeObject(n"SlinkyTunnel", this);
	}

	UFUNCTION(NetFunction)
	void NetActivateSlinkyCapability(AHazePlayerCharacter Player)
	{
		if (bHasTriggered[Player])
			return;
		
		bHasTriggered[Player] = true;
		Player.AddCapability(SlinkyCapability);
		Player.SetCapabilityAttributeObject(n"SlinkyTunnel", this);
	}

	UFUNCTION()
	void ScaleTunnelTimelineUpdate(float CurrentValue)
	{
		//SetActorScale3D(FMath::Lerp(FVector::ZeroVector, FVector(1.f, 1.f, 1.f), CurrentValue));
	}

	UFUNCTION()
	void ScaleTunnelManually(float LerpValue)
	{
		//SetActorScale3D(FMath::Lerp(FVector::ZeroVector, FVector(1.f, 1.f, 1.f), LerpValue));
	}
}
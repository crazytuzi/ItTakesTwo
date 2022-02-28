import Vino.PlayerHealth.PlayerHealthStatics;
class ALightRoomSwingingTruss : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UBoxComponent KillCollision;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent TrussMoveAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent KillPlayerAudioEvent;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> ElectricityDeathFX;

	UPROPERTY()
	float TimelineDuration = 2.f;

	UPROPERTY()
	FHazeTimeLike SwingTrussTimeline;
	default SwingTrussTimeline.bLoop = true;
	default SwingTrussTimeline.bFlipFlop = true;
	default SwingTrussTimeline.Duration = 1.f;
	default SwingTrussTimeline.bSyncOverNetwork = true;
	default SwingTrussTimeline.SyncTag = n"SwingTruss";

	UPROPERTY()
	FHazeTimeLike SpinTrussTimeline;
	default SpinTrussTimeline.bLoop = true;
	default SpinTrussTimeline.Duration = 1.f;

	UPROPERTY()
	float SwingStartDelay = 0.f;

	float StartingRoll = 35.f;
	float TargetRoll = -35.f;

	float Timer = 0.f;
	float YawRotationSpeed = 50.f;
	float TotalYawRotationToAdd = 180.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SwingTrussTimeline.BindUpdate(this, n"SwingTrussTimelineUpdate");
		SwingTrussTimeline.SetPlayRate(1/TimelineDuration);
		HazeAkComp.HazePostEvent(TrussMoveAudioEvent);
		
		if (SwingStartDelay <= 0)
			SwingTrussTimeline.Play();
		else
			System::SetTimer(this, n"SwingTrussWithDelay", SwingStartDelay, false);
		
		KillCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnKillCollisionOverlap");
	}

	UFUNCTION()
	void SwingTrussWithDelay()
	{
		SwingTrussTimeline.Play();
	}

	UFUNCTION()
	void OnKillCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (!Player.HasControl())
			return;

		Player.PlayerHazeAkComp.HazePostEvent(KillPlayerAudioEvent);
		KillPlayer(Player, ElectricityDeathFX);
	}

	UFUNCTION()
	void SwingTrussTimelineUpdate(float CurrentValue)
	{
		FRotator StartingRollRot = FRotator(MeshRoot.RelativeRotation.Pitch, MeshRoot.RelativeRotation.Yaw, StartingRoll);
		FRotator TargetRollRot = FRotator(MeshRoot.RelativeRotation.Pitch, MeshRoot.RelativeRotation.Yaw, TargetRoll);
		MeshRoot.SetRelativeRotation(FMath::LerpShortestPath(StartingRollRot, TargetRollRot, CurrentValue));
		HazeAkComp.SetRTPCValue("Rtpc_World_Music_Backstage_Platform_LightRoomSwingingTruss_Roll", CurrentValue);
	}
}
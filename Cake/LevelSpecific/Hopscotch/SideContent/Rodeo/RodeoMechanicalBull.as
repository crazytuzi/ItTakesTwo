import Vino.Interactions.InteractionComponent;
import Vino.MinigameScore.ScoreHud;

event void FRodeoPlayerThrownOffEvent(AHazePlayerCharacter Player);
event void FRodeoPlayerEvent(AHazePlayerCharacter Player);

UCLASS(Abstract)
class ARodeoMechanicalBull : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BullRoot;

	UPROPERTY(DefaultComponent, Attach = BullRoot)
	UHazeSkeletalMeshComponentBase BullMesh;

	UPROPERTY(DefaultComponent, Attach = BullMesh)
	USceneComponent PlayerJumpToPoint;

	UPROPERTY(DefaultComponent, Attach = BullMesh)
	USceneComponent PlayerAttachmentPoint;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> MountCapability;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> RequiredCapability;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlaySpinLoop_01_AudioEvent;
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlaySpinLoop_02_AudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopSpinLoopAudioEvent;

	UPROPERTY()
	FRodeoPlayerThrownOffEvent OnPlayerThrownOff;

	UPROPERTY()
	FRodeoPlayerEvent OnPlayerFail;

	UPROPERTY()
	FRodeoPlayerEvent OnPlayerSuccess;

	float CurrentYawRate = 0.f;
	float DesiredYawRate = 0.f;
	float MinYawRate = 180.f;
	float MaxYawRate = 400.f;
	FTimerHandle YawTimerHandle;

	bool bBucking = false;

	bool bMounted = false;
	AHazePlayerCharacter MountedPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Capability::AddPlayerCapabilityRequest(MountCapability);
		Capability::AddPlayerCapabilityRequest(RequiredCapability);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Capability::RemovePlayerCapabilityRequest(MountCapability);
		Capability::RemovePlayerCapabilityRequest(RequiredCapability);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CurrentYawRate = FMath::FInterpTo(CurrentYawRate, DesiredYawRate, DeltaTime, 1.5f);
		FRotator DesiredRotationRate = FRotator(0.f, CurrentYawRate, 0.f) * DeltaTime;

		BullRoot.AddLocalRotation(DesiredRotationRate);
		HazeAkComp.SetRTPCValue("Rtcp_World_SideContent_Playroom_MiniGame_RodeoMechanicalBull_CurrentYawRate", CurrentYawRate);
	}

	UFUNCTION()
	void StartYawTimer()
	{
		float Time = FMath::RandRange(2.5f, 6.f);
		YawTimerHandle = System::SetTimer(this, n"ChangeYawRate", Time, false);
	}

	UFUNCTION()
	void ChangeYawRate()
	{
		float NewYawRate = FMath::RandRange(MinYawRate, MaxYawRate);

		if (DesiredYawRate > 0.f)
			NewYawRate = -NewYawRate;

		DesiredYawRate = NewYawRate;

		StartYawTimer();
	}

	void PlayerDismounted()
	{
		bMounted = false;
		System::ClearAndInvalidateTimerHandle(YawTimerHandle);
		DesiredYawRate = 0.f;
		MountedPlayer = nullptr;
	}

	UFUNCTION()
	void PlayerThrownOff(AHazePlayerCharacter Player)
	{
		OnPlayerThrownOff.Broadcast(Player);
		HazeAkComp.HazePostEvent(StopSpinLoopAudioEvent);		
	}

	void StartBucking()
	{
		bBucking = true;
		ChangeYawRate();
		MountedPlayer.SetCapabilityActionState(n"Rodeo", EHazeActionState::Active);
		HazeAkComp.HazePostEvent(PlaySpinLoop_01_AudioEvent);
		HazeAkComp.HazePostEvent(PlaySpinLoop_02_AudioEvent);
	}
}
import Vino.Interactions.InteractionComponent;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeaturePlayRoomPinBall;
import Cake.LevelSpecific.PlayRoom.VOBanks.SpacestationVOBank;

event void FSpacePinballEvent();

UCLASS(Abstract)
class ASpacePinballSpring : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent MainAttachPoint;

	UPROPERTY(DefaultComponent, Attach = MainAttachPoint)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = MainAttachPoint)
	USceneComponent SpringRoot;

	UPROPERTY(DefaultComponent, Attach = MainAttachPoint)
	USceneComponent HandleRoot;

	UPROPERTY(DefaultComponent, Attach = HandleRoot)
	UStaticMeshComponent HandleBaseMesh;

	UPROPERTY(DefaultComponent, Attach = HandleBaseMesh)
	UStaticMeshComponent HandleMesh;

	UPROPERTY(DefaultComponent, Attach = SpringRoot)
	UStaticMeshComponent SpringMesh;

	UPROPERTY(DefaultComponent, Attach = SpringRoot)
	USceneComponent BallAttachPoint;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncFloatComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 6000.f;

	UPROPERTY(DefaultComponent, Attach = HandleMesh)
	UHazeAkComponent HandleHazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ExposeHandleAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ReverseHandleAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SpringReleaseAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SpringReturnToStartAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SpringParkedAtStartAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SpringMoveAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SpringStopAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SpringPullAudioEvent;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> SpringCapability;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> ControlCapability;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ReleaseRumble;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ToggleWallsRumble;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ExposeHandleTimeLike;
	default ExposeHandleTimeLike.Duration = 0.5f;

	UPROPERTY(EditDefaultsOnly)
	UCurveFloat ExposeHandleRotationCurve;

	UPROPERTY(EditDefaultsOnly)
	UCurveFloat ExposeHandleLocationCurve;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeaturePlayRoomPinBall Feature;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike GrabHandleTimeLike;
	default GrabHandleTimeLike.Duration = 0.5f;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence ExitAnimation;

	UPROPERTY(EditDefaultsOnly)
	USpacestationVOBank VOBank;

	UPROPERTY()
	FSpacePinballEvent OnSpringReleased;

	UPROPERTY()
	FSpacePinballEvent OnParkedAtStart;

	UPROPERTY(EditDefaultsOnly)
	FText ReleaseTutorialText;

	UPROPERTY(EditDefaultsOnly)
	FText ToggleWallsTutorialText;

	float Tension = 0.f;
	float SideInput = 0.f;
	float SideLoc = -255.f;

	bool bControlled = false;
	bool bParkedAtStart = true;
	bool bReturningToStart = false;
	bool bBallOccupied = false;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		SetControlSide(Game::GetMay());
		SyncFloatComp.SetValue(SideLoc);
		
		InteractionComp.OnActivated.AddUFunction(this, n"InteractionActivated");

		Capability::AddPlayerCapabilityRequest(SpringCapability, EHazeSelectPlayer::May);
		Capability::AddPlayerCapabilityRequest(ControlCapability, EHazeSelectPlayer::Cody);

		ExposeHandleTimeLike.BindUpdate(this, n"UpdateExposeHandle");
		ExposeHandleTimeLike.BindFinished(this, n"FinishExposeHandle");
		
		GrabHandleTimeLike.BindUpdate(this, n"UpdateGrabHandle");
    }

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Capability::RemovePlayerCapabilityRequest(SpringCapability, EHazeSelectPlayer::May);
		Capability::RemovePlayerCapabilityRequest(ControlCapability, EHazeSelectPlayer::Cody);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateExposeHandle(float CurValue)
	{
		float LocAlpha = ExposeHandleLocationCurve.GetFloatValue(CurValue);
		FVector CurLoc = FMath::Lerp(FVector(-45.f, 0.f, 0.f), FVector(-85.f, 0.f, 0.f), CurValue);
		HandleMesh.SetRelativeLocation(CurLoc);

		float RotAlpha = ExposeHandleRotationCurve.GetFloatValue(CurValue);
		FRotator CurRot = FMath::LerpShortestPath(FRotator(-90.f, 0.f, 0.f), FRotator(0.f, 0.f, 0.f), RotAlpha);
		HandleMesh.SetRelativeRotation(CurRot);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishExposeHandle()
	{
		if (bBallOccupied)
			EnableInteraction();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateGrabHandle(float CurValue)
	{
		float CurMeshScale = FMath::Lerp(1.f, 0.5f, CurValue);
		SpringMesh.SetWorldScale3D(FVector(1.f, 1.f, CurMeshScale));
		
		float CurBallAttachOffset = FMath::Lerp(148.f, 95.f, CurValue);
		BallAttachPoint.SetRelativeLocation(FVector(CurBallAttachOffset, 0.f, BallAttachPoint.RelativeLocation.Z));
	}

	void UpdateInput(float InputX)
	{
		SideInput = InputX;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (HasControl())
		{
			if (bControlled)
			{
				SideLoc += (SideInput * 160.f * DeltaTime);
			}
			else if (bReturningToStart)
			{
				SideLoc = FMath::FInterpConstantTo(SideLoc, -255.f, DeltaTime, 300.f);
				if (SideLoc == -255.f && !bParkedAtStart)
					NetParkAtStart();
			}
		}

		SideLoc = FMath::Clamp(SideLoc, -255.f, 255.f);

		if (HasControl())
			SyncFloatComp.Value = SideLoc;

		MainAttachPoint.SetRelativeLocation(FVector(0.f, SyncFloatComp.Value, 0.f));
	}

	void StartReturningToStart()
	{
		bReturningToStart = true;
		bParkedAtStart = false;
	}

	UFUNCTION(NetFunction)
	void NetParkAtStart()
	{
		bReturningToStart = false;
		bParkedAtStart = true;
		OnParkedAtStart.Broadcast();
		HandleHazeAkComp.HazePostEvent(SpringParkedAtStartAudioEvent);
	}

	void ExposeHandle()
	{
		bBallOccupied = true;
		ExposeHandleTimeLike.PlayFromStart();
		HandleHazeAkComp.HazePostEvent(ExposeHandleAudioEvent);
	}

	void EnableInteraction()
	{
		InteractionComp.Enable(n"HatchOpen");
	}

	UFUNCTION()
    void InteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		GrabHandleTimeLike.SetPlayRate(1.f);
		GrabHandleTimeLike.PlayFromStart();
		bControlled = true;
		InteractionComp.Disable(n"HatchOpen");
		Player.SetCapabilityAttributeObject(n"PinballSpring", this);
		Player.SetCapabilityActionState(n"ControlPinballSpring", EHazeActionState::Active);
		Player.PlayerHazeAkComp.HazePostEvent(SpringMoveAudioEvent);
		HandleHazeAkComp.HazePostEvent(SpringPullAudioEvent);

		Game::GetCody().ApplyViewSizeOverride(this, EHazeViewPointSize::Large, EHazeViewPointBlendSpeed::Slow);
    }

	void InteractionCancelled()
	{
		bBallOccupied = false;
		GrabHandleTimeLike.SetPlayRate(4.f);
		GrabHandleTimeLike.ReverseFromEnd();
		ExposeHandleTimeLike.ReverseFromEnd();
		bControlled = false;

		SideInput = 0.f;

		HandleHazeAkComp.HazePostEvent(ReverseHandleAudioEvent);
		HandleHazeAkComp.HazePostEvent(SpringReturnToStartAudioEvent);
		UHazeAkComponent::HazePostEventFireForget(SpringStopAudioEvent, FTransform());

		Game::GetCody().ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Slow);
	}

	UFUNCTION()
	void ReleaseBall()
	{
		SideInput = 0.f;
		OnSpringReleased.Broadcast();
		HandleHazeAkComp.HazePostEvent(SpringReleaseAudioEvent);
	}

	void BallCrashed()
	{
		bBallOccupied = false;
		GrabHandleTimeLike.ReverseFromEnd();
		ExposeHandleTimeLike.ReverseFromEnd();
		bControlled = false;

		SideInput = 0.f;
	}
}
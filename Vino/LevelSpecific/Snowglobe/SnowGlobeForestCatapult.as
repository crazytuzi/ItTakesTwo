import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;
import Vino.Trajectory.TrajectoryComponent;
import Vino.Movement.Helpers.BurstForceStatics;
import Peanuts.Audio.AudioStatics;

enum ESnowGlobeForestCatapultState 
{
	Idle,
	Cocked,
	Launching
}

class ASnowGlobeForestCatapult : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UMagnetGenericComponent Magnet;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UBoxComponent CrateCollision;

	UPROPERTY(DefaultComponent)
	UTrajectoryComponent Trajectory;

	UPROPERTY(DefaultComponent)
	USceneComponent FlagRoot;

	UPROPERTY(DefaultComponent, Attach = Magnet)
	UHazeAkComponent CatapultHazeAkComp;

	UPROPERTY(DefaultComponent, Attach = FlagRoot)
	UHazeAkComponent FlagHazeAkComp;

	UPROPERTY(Category = "Animation")
	UAnimSequence LaunchAnimation;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect LaunchForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> LaunchCamShake;

	UFUNCTION(BlueprintEvent)
	void BP_CatapultHitUpperBound(float Force)
	{}

	UFUNCTION(BlueprintEvent)
	void BP_CatapultHitLowerBound(float Force)
	{}

	UFUNCTION(BlueprintEvent)
	void BP_CatapultStartMove()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_CatapultStopMove()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_FlagHitUpperBound(float Force)
	{}

	UFUNCTION(BlueprintEvent)
	void BP_FlagHitLowerBound(float Force)
	{}

	UFUNCTION(BlueprintEvent)
	void BP_FlagStartMove()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_FlagStopMove()
	{}


	// Determines if Cody is pulling the catapult
	bool bIsPulling = false;
	ESnowGlobeForestCatapultState State = ESnowGlobeForestCatapultState::Idle;

	FHazeConstrainedPhysicsValue CatapultRotation;
	default CatapultRotation.Value = -5.f;
	default CatapultRotation.LowerBound = -85.f;
	default CatapultRotation.UpperBound = -0.f; // -0.5f
	default CatapultRotation.Friction = 1.2f;
	default CatapultRotation.LowerBounciness = 0.35f;
	default CatapultRotation.UpperBounciness = 0.5f;

	FHazeConstrainedPhysicsValue FlagRotation;
	default FlagRotation.Value = 0.f;
	default FlagRotation.LowerBound = 0.f;
	default FlagRotation.UpperBound = 90.f;
	default FlagRotation.Friction = 0.35f;
	default FlagRotation.LowerBounciness = 0.6f;
	default FlagRotation.UpperBounciness = 0.6f;

	const float ConstantAcceleration = 280.f; // 80.f
	const float LaunchExtraAcceleration = 680.f; // 180.f
	const float MagnetAcceleration = -320.f; // -120.f

	AHazePlayerCharacter PlayerInCrate = nullptr;
	AHazePlayerCharacter LaunchedPlayer = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Magnet.OnGenericMagnetInteractionStateChanged.AddUFunction(this, n"HandleMagnetStateChanged");
		CrateCollision.OnComponentBeginOverlap.AddUFunction(this, n"HandleCrateBeginOverlap");
		CrateCollision.OnComponentEndOverlap.AddUFunction(this, n"HandleCrateEndOverlap");

		SetControlSide(Game::GetCody());
	}

	UFUNCTION()
	void HandleMagnetStateChanged(bool bActive, UMagnetGenericComponent MagnetComponent, AHazePlayerCharacter Player)
	{
		bIsPulling = bActive;
		
		// If we let go when we should launch (we've hit the back-clamp)
		// Launch that bad boy!
		if (HasControl() && State == ESnowGlobeForestCatapultState::Cocked && !bIsPulling)
		{
			NetLaunchPlayer(PlayerInCrate);
		}
	}

    UFUNCTION()
    void HandleCrateBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
    	if (PlayerInCrate != nullptr)
    		return;

    	auto Player = Cast<AHazePlayerCharacter>(OtherActor);
    	if (Player != nullptr)
	    	PlayerInCrate = Player;
    }

    UFUNCTION()
    void HandleCrateEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
    	if (PlayerInCrate == nullptr)
    		return;

    	auto Player = Cast<AHazePlayerCharacter>(OtherActor);
    	if (Player == PlayerInCrate)
    		PlayerInCrate = nullptr;
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float TotalForce = 0.f;

		//Print("catapult velo" + CatapultRotation.Velocity);
		CatapultHazeAkComp.SetRTPCValue("Rtpc_SnowGlobe_Forest_Catapult_Velocity", CatapultRotation.Velocity);

		if (FMath::Abs(CatapultRotation.Velocity) == 0.0)
		{
			BP_CatapultStopMove();
		}

		else if (FMath::Abs(CatapultRotation.Velocity) > 1.0)
		{
			BP_CatapultStartMove();
		}

		// Acceleration towards the beam
		TotalForce += ConstantAcceleration;
		// Pull harding if we're launching, looks better
		if (State == ESnowGlobeForestCatapultState::Launching)
			TotalForce += LaunchExtraAcceleration;

		// Pull force!
		// Make sure this is higher than the constant acceleration :^)
		if (bIsPulling)
		{
			TotalForce += MagnetAcceleration;
		}

		CatapultRotation.AddAcceleration(TotalForce);
		CatapultRotation.Update(DeltaTime);

		// Collision with the beam
		if (CatapultRotation.HasHitUpperBound())
		{
			BP_OnBeamCollision(FMath::Abs(CatapultRotation.Velocity));
			BP_CatapultHitUpperBound(FMath::Abs(CatapultRotation.Velocity));
			FinishLaunch();
		}

		// Collision with the back-clamp thing
		else if (CatapultRotation.HasHitLowerBound())
		{
			BP_CatapultHitLowerBound(FMath::Abs(CatapultRotation.Velocity));
			// If cody is pulling, set the catapult to prepare launching!
			if (bIsPulling)
			{
				State = ESnowGlobeForestCatapultState::Cocked;
			}
		}

		RotationRoot.SetRelativeRotation(FRotator(CatapultRotation.Value, 0.f, 0.f));

		// Should-launch flag :^)
		bool bFlagUp = (State != ESnowGlobeForestCatapultState::Idle);
		FlagRotation.AddAcceleration(bFlagUp ? 300.f : -300.f);
		FlagRotation.Update(DeltaTime);
		FlagRoot.SetRelativeRotation(FRotator(FlagRotation.Value, 0.f, 0.f));

		FlagHazeAkComp.SetRTPCValue("Rtpc_SnowGlobe_Forest_CatapultFlag_Velocity", FlagRotation.Velocity);

		if (FlagRotation.Value == 90)
		{
			BP_FlagHitUpperBound(FMath::Abs(FlagRotation.Velocity));
		}

		else if (FlagRotation.Value == 0)
		{
			BP_FlagHitLowerBound(FMath::Abs(FlagRotation.Velocity));
		}

		if (FMath::Abs(FlagRotation.Velocity) < 5)
		{
			BP_FlagStopMove();
		}

		else if (FMath::Abs(FlagRotation.Velocity) > 5.0)
		{
			BP_FlagStartMove();
		}

	}

	UFUNCTION(BlueprintEvent)
	void BP_OnBeamCollision(float Force)
	{
	}

	UFUNCTION(NetFunction)
	void NetLaunchPlayer(AHazePlayerCharacter Player)
	{
		// Add some initial kick
		CatapultRotation.Velocity = -2.f;

		// If we get here with a non-null LaunchedPlayer, this has been called BEFORE a previously launched player
		// finished launching, which might cause bugs with not detaching etc.
		ensure(LaunchedPlayer == nullptr);

		if (Player != nullptr)
		{
			LaunchedPlayer = Player;

			LaunchedPlayer.RootOffsetComponent.FreezeAndResetWithTime(0.5f);
			LaunchedPlayer.TriggerMovementTransition(this);
			LaunchedPlayer.BlockMovementSyncronization(this);

			LaunchedPlayer.AttachToComponent(CrateCollision, NAME_None, EAttachmentRule::SnapToTarget);
			LaunchedPlayer.BlockCapabilities(CapabilityTags::Movement, this);
			LaunchedPlayer.BlockCapabilities(CapabilityTags::GameplayAction, this);
			LaunchedPlayer.BlockCapabilities(FMagneticTags::MagneticControl, this);

			LaunchedPlayer.PlaySlotAnimation(Animation = LaunchAnimation, bLoop = true);

			Magnet.SetActive(false);
		}

		State = ESnowGlobeForestCatapultState::Launching;
	}

	void FinishLaunch()
	{
		if (LaunchedPlayer != nullptr)
		{
			LaunchedPlayer.StopAllSlotAnimations();

			LaunchedPlayer.DetachRootComponentFromParent(true);
			LaunchedPlayer.UnblockCapabilities(CapabilityTags::Movement, this);
			LaunchedPlayer.UnblockCapabilities(CapabilityTags::GameplayAction, this);
			LaunchedPlayer.UnblockCapabilities(FMagneticTags::MagneticControl, this);
			LaunchedPlayer.SetActorLocation(Trajectory.WorldLocation);
			FRotator FacingRot = (ActorForwardVector * -1.f).Rotation();
			AddBurstForce(LaunchedPlayer, Trajectory.GetCalculatedVelocity(), FacingRot);

			LaunchedPlayer.PlayForceFeedback(LaunchForceFeedback, false, true, n"Catapult");
			LaunchedPlayer.PlayCameraShake(LaunchCamShake, 0.65f);
			
			FHazePointOfInterest PoISettings;
			PoISettings.FocusTarget.Actor = this;
			PoISettings.FocusTarget.LocalOffset = FVector(-15000.f, 0.f, -2000.f);
			PoISettings.Duration = 1.f;
			PoISettings.Blend.BlendTime = 1.f;
			LaunchedPlayer.ApplyPointOfInterest(PoISettings, this);

			LaunchedPlayer.UnblockMovementSyncronization(this);
			LaunchedPlayer.TriggerMovementTransition(this);
			LaunchedPlayer = nullptr;

			Magnet.SetActive(true);
		}

		State = ESnowGlobeForestCatapultState::Idle;
	}
}
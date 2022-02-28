import Peanuts.ButtonMash.ButtonMashHandleBase;
import Peanuts.ButtonMash.Default.ButtonMashDefault;
import Vino.Trajectory.TrajectoryComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Trajectory.TrajectoryStatics;
import Vino.Camera.Components.CameraUserComponent;

struct FPocketWatchEaterState
{
	UButtonMashHandleBase ButtonMash;
	float MashProgress = 0.f;
	bool bEating = false;

	bool bLaunching = false;
	float LaunchTimer = 0.f;

	UHazeSmoothSyncFloatComponent SyncIntensity;
};

class APocketWatchEater : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent EatSphere;

	// UHazeJumpToComponent

	UPROPERTY(DefaultComponent, Attach = Root)
	UTrajectoryComponent Trajectory;
	default Trajectory.TerminalSpeed = 10.f;
	default Trajectory.Gravity = 280.f * 6.1f;
	default Trajectory.LocalTargetHeight = FVector(0.f, 0.f, 9000.f);
	default Trajectory.TrajectoryMethod = ETrajectoryMethod::Calculation;

	// Amount of mashing required before the watch eater launches you
	UPROPERTY()
	float MashingRequired = 5.f;

	// Delay after completing the button mash before the player is launched
	UPROPERTY()
	float LaunchDelay = 0.25f;

	// Camera settings to use while being eaten
	UPROPERTY()
	UHazeCameraSettingsDataAsset CameraSettings;

	// Animation to play on the player when launched
	UPROPERTY()
	UAnimSequence CodyLaunchAnimation;

	// Animation to play on the player when launched
	UPROPERTY()
	UAnimSequence MayLaunchAnimation;

	UPROPERTY(meta = (MakeEditWidget))
	FTransform EndLocation;

	UPROPERTY(Category = "Capabilities")
	UHazeCapabilitySheet PlayerCapabilitySheet;

	private TPerPlayer<FPocketWatchEaterState> State;
	private int PlayersInEater;

	UCameraComponent CameraComp;
	UCameraUserComponent CameraUser;

	FHazeAcceleratedRotator AcceleratedTargetRotation;

	bool bCanCameraLook;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		EatSphere.OnComponentBeginOverlap.AddUFunction(this, n"OnEatOverlap");

		for (auto Player : Game::Players)
		{
			FPocketWatchEaterState& PlayerState = State[Player];
			PlayerState.SyncIntensity = UHazeSmoothSyncFloatComponent::Create(this, Player.IsCody() ? n"SyncCody" : n"SyncMay");
			PlayerState.SyncIntensity.OverrideControlSide(Player);
		}

		BP_Anim_MH();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		for (auto Player : Game::Players)
		{
			FPocketWatchEaterState& PlayerState = State[Player];
			if (PlayerState.bEating)
			{
				StartLaunchPlayer(Player);
				FinishLaunchPlayer(Player);
			}
		}
	}

    UFUNCTION()
    void OnEatOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr && Player.HasControl() && PlayersInEater == 0)
		{
			NetModPlayersInEater(+1);

			auto CrumbComp = UHazeCrumbComponent::Get(Player);

			FHazeDelegateCrumbParams CrumbParams;
			CrumbParams.AddObject(n"Player", Player);
			CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_StartEating"), CrumbParams);

			CameraComp = UCameraComponent::Get(Player);
			CameraUser = UCameraUserComponent::Get(Player);

			AcceleratedTargetRotation.Value = FRotator(0.f);

			bCanCameraLook = true;
		}
    }

	UFUNCTION()
	void Crumb_StartEating(const FHazeDelegateCrumbData& CrumbData)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"Player"));
		FPocketWatchEaterState& PlayerState = State[Player];
		PlayerState.bEating = true;
		PlayerState.MashProgress = 0.f;
		PlayerState.ButtonMash = StartButtonMashDefaultAttachToComponent(
			Player, Root, NAME_None, FVector::ZeroVector);

		Player.BlockCapabilities(n"Movement", this);
		Player.BlockCapabilities(n"Collision", this);

		Player.SmoothSetLocationAndRotation(ActorLocation, Player.ActorRotation);
		Player.SetActorHiddenInGame(true);

		Player.ApplyCameraSettings(CameraSettings, FHazeCameraBlendSettings(), Instigator = this);

		BP_Anim_Eat();
	}

	UFUNCTION()
	void Crumb_EatingDone(const FHazeDelegateCrumbData& CrumbData)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"Player"));
		StartLaunchPlayer(Player);
	}

	void StartLaunchPlayer(AHazePlayerCharacter Player)
	{
		FPocketWatchEaterState& PlayerState = State[Player];
		PlayerState.bEating = false;

		StopButtonMash(PlayerState.ButtonMash);
		PlayerState.ButtonMash = nullptr;

		PlayerState.bLaunching = true;
		PlayerState.LaunchTimer = LaunchDelay;

		BP_Anim_StartLaunch();
	}

	void LaunchPlayer(AHazePlayerCharacter Player)
	{
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player); 

		FVector WorldLoc = Root.RelativeTransform.TransformPosition(EndLocation.Location);

		float HeightDiff = WorldLoc.Z - ActorLocation.Z;
		float HeightValue = 0.f;

		if (HeightDiff > 0.f)
			HeightValue = HeightDiff;

		FVector JumpPath = CalculateVelocityForPathWithHeight(Player.ActorLocation, WorldLoc, MoveComp.GravityMagnitude, 400.f + HeightValue);

		Player.AddImpulse(JumpPath);

		System::SetTimer(this, n"SwitchCameraLookOff", 0.7f, false);
	}

	UFUNCTION()
	void SwitchCameraLookOff()
	{
		bCanCameraLook = false;
	}

	void FinishLaunchPlayer(AHazePlayerCharacter Player)
	{
		FPocketWatchEaterState& PlayerState = State[Player];

		Player.UnblockCapabilities(n"Movement", this);
		Player.UnblockCapabilities(n"Collision", this);

		Player.ClearFieldOfViewByInstigator(this);
		Player.ClearCameraSettingsByInstigator(Instigator = this);
		
		LaunchPlayer(Player);

		Player.SetActorHiddenInGame(false);

		Player.PlaySlotAnimation(
			Animation = Player.IsCody() ? CodyLaunchAnimation : MayLaunchAnimation
		);

		BP_Anim_FinishLaunch();
	}

	UFUNCTION(NetFunction)
	void NetModPlayersInEater(int Mod)
	{
		PlayersInEater += Mod;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (auto Player : Game::Players)
		{
			FPocketWatchEaterState& PlayerState = State[Player];

			if (Player.HasControl() && PlayerState.bEating)
			{
				// Progress goes up as the player mashes the button
				PlayerState.MashProgress += DeltaTime * PlayerState.ButtonMash.MashRateControlSide / MashingRequired;
				PlayerState.SyncIntensity.Value = PlayerState.ButtonMash.MashRateControlSide;

				// Update the player's view based on progress
				float FOV = 70.f - (20.f * PlayerState.MashProgress);
				Player.ApplyFieldOfView(FOV, FHazeCameraBlendSettings(1.f), Instigator = this);

				Print("PlayerState.MashProgress: " + PlayerState.MashProgress);

				// If final progress is reached, launch the player
				if (PlayerState.MashProgress >= 1.f)
				{
					auto CrumbComp = UHazeCrumbComponent::Get(Player);

					FHazeDelegateCrumbParams CrumbParams;
					CrumbParams.AddObject(n"Player", Player);
					CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_EatingDone"), CrumbParams);

					NetModPlayersInEater(-1);					
				}
			}

			// Take care of the delay before launching a player
			if (PlayerState.bLaunching)
			{
				PlayerState.LaunchTimer -= DeltaTime;
				if (PlayerState.LaunchTimer <= 0.f)
				{
					FinishLaunchPlayer(Player);
					PlayerState.bLaunching = false;
				}
			}

			if (PlayerState.MashProgress >= 0.35f && bCanCameraLook)
			{
				FVector WorldLoc = Root.RelativeTransform.TransformPosition(EndLocation.Location);
				FVector Direction =  WorldLoc - ActorLocation; 
				FRotator LookRotation = Math::MakeRotFromX(Direction);
				AcceleratedTargetRotation.Value = CameraUser.DesiredRotation;
				AcceleratedTargetRotation.AccelerateTo(LookRotation, 2.2f, DeltaTime);
				CameraUser.DesiredRotation = AcceleratedTargetRotation.Value;
			}
		}
	}

	UFUNCTION(BlueprintPure)
	float GetEatingIntensity()
	{
		float Value = 0.f;
		for (auto Player : Game::Players)
		{
			FPocketWatchEaterState& PlayerState = State[Player];
			if (PlayerState.SyncIntensity.Value > Value)
				Value = PlayerState.SyncIntensity.Value;
		}
		return Value;
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void BP_Anim_MH() {}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void BP_Anim_Eat() {}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void BP_Anim_StartLaunch() {}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void BP_Anim_FinishLaunch() {}
};
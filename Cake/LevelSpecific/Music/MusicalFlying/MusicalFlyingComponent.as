import Cake.LevelSpecific.Music.Classic.PlayerJetpackActor;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingSettings;
import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingVolume;
import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingExitVolumeBehavior;
import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingExclusionVolume;
import Peanuts.Spline.SplineComponent;

import void OnInfiniteFlyingDisabled() from "Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingBlockingVolume";
import void OnInfiniteFlyingEnabled() from "Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingBlockingVolume";
import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Cake.LevelSpecific.Music.MusicalFlying.MusicFlyingReturnToVolumeSettings;


#if !RELEASE
const FConsoleVariable CVar_DebugDrawMusicalFlyingPhysics("Music.DebugDrawFlying", 0);
#endif // !RELEASE

enum EMusicalFlyingBarrelRoll
{
	Left,
	Right,
	None
}

enum EMusicalFlyingTightTurn
{
	Left,
	Right,
	None
}

settings MusicalFlyingSettingsDefault for UMusicalFlyingSettings
{

}

settings MusicFlyingReturnToVolumeSettingsDefault for UMusicFlyingReturnToVolumeSettings
{

}

UFUNCTION()
void ActivateMusicFlying(AHazePlayerCharacter Player)
{
	if(Player == nullptr)
		return;

	if(!Player.HasControl())
		return;

	UMusicalFlyingComponent FlyingComp = UMusicalFlyingComponent::Get(Player);

	if(FlyingComp != nullptr && !FlyingComp.bIsFlying)
	{
		FlyingComp.bForceActivateFlying = true;
	}
}

UFUNCTION()
void DeactivateMusicFlying(AHazePlayerCharacter Player)
{
	if(Player == nullptr)
		return;

	if(!Player.HasControl())
		return;

	UMusicalFlyingComponent FlyingComp = UMusicalFlyingComponent::Get(Player);

	if(FlyingComp != nullptr && FlyingComp.bIsFlying)
	{
		FlyingComp.bForceDeactivateFlying = true;
	}
}

// Automatically calls ResumeFlyingInput when parameter Seconds has elapsed. Will not call Resume if a negative value was passed.
UFUNCTION()
void PauseFlyingInput(AHazePlayerCharacter Player, float Seconds = 1.0f)
{
	if(Player == nullptr)
		return;

	if(!Player.HasControl())
		return;

	UMusicalFlyingComponent FlyingComp = UMusicalFlyingComponent::Get(Player);

	if(FlyingComp != nullptr)
	{
		FlyingComp.PauseFlyingInput(Seconds);
	}
}

UFUNCTION()
void ResumeFlyingInput(AHazePlayerCharacter Player)
{
	if(Player == nullptr)
		return;

	if(!Player.HasControl())
		return;

	UMusicalFlyingComponent FlyingComp = UMusicalFlyingComponent::Get(Player);

	if(FlyingComp != nullptr)
	{
		FlyingComp.ResumeFlyingInput();
	}
}

void TrigerFlyingBoostOnActor(AActor Actor)
{
	UMusicalFlyingComponent FlyingComp = UMusicalFlyingComponent::Get(Actor);

	if(FlyingComp != nullptr)
	{
		FlyingComp.TriggerBoost();
	}
}

void OnFlyingVolumeEnter(AActor TargetActor, AMusicalFlyingVolume FlyingVolume)
{
	UMusicalFlyingComponent FlyingComp = UMusicalFlyingComponent::Get(TargetActor);
	if(FlyingComp != nullptr)
	{
		FlyingComp.EnteredFlyingVolume(FlyingVolume);
	}
}

void OnFlyingVolumeExit(AActor TargetActor, AMusicalFlyingVolume FlyingVolume, UPrimitiveComponent ExitingPrimitive)
{
	UMusicalFlyingComponent FlyingComp = UMusicalFlyingComponent::Get(TargetActor);
	if(FlyingComp != nullptr)
	{
		FlyingComp.LeftFlyingVolume(FlyingVolume, ExitingPrimitive);
	}
}

void OnFlyingExclusionVolumeEnter(AActor Owner, AMusicalFlyingExclusionVolume ExclusionVolume, UPrimitiveComponent EnterPrimitive)
{
	UMusicalFlyingComponent FlyingComp = UMusicalFlyingComponent::Get(Owner);
	if(FlyingComp != nullptr)
		FlyingComp.EnteredFlyingExclusionVolume(ExclusionVolume, EnterPrimitive);
}

void OnFlyingExclusionVolumeExit(AActor Owner, AMusicalFlyingExclusionVolume ExclusionVolume, UPrimitiveComponent ExitPrimitive)
{
	UMusicalFlyingComponent FlyingComp = UMusicalFlyingComponent::Get(Owner);
	if(FlyingComp != nullptr)
		FlyingComp.LeftFlyingExclusionVolume(ExclusionVolume, ExitPrimitive);
}

class AMusicalFlyingSpline : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;
	default Spline.AutoTangents = true;
}

UCLASS(Abstract, hidecategories = "ComponentTick ComponentReplication Activation Variable Cooking AssetUserData Collision Tags")
class UMusicalFlyingComponent : UActorComponent
{
	UPROPERTY()
	FText JumpText;
	UPROPERTY()
	FText FlyText;
	UPROPERTY()
	FText BoostText;
	UPROPERTY()
	FText UpText;
	UPROPERTY()
	FText DownText;
	UPROPERTY()
	UFoghornVOBankDataAssetBase VODataBankAsset;

	UPROPERTY(Category = Animation)
	UHazeLocomotionStateMachineAsset CodyFlyingStateMachine;

	UPROPERTY(Category = Animation)
	UHazeLocomotionStateMachineAsset MayFlyingStateMachine;

	UPROPERTY(Category = CameraSettings)
	UHazeCameraSpringArmSettingsDataAsset HoverCamSettings;

	UPROPERTY(Category = CameraSettings)
	UHazeCameraSpringArmSettingsDataAsset FlyingCamSettings;

	UPROPERTY(Category = CameraSettings)
	UHazeCameraSpringArmSettingsDataAsset ExitVolumeCameraSettings;

	UPROPERTY(Category = CameraSettings)
	UHazeCameraSpringArmSettingsDataAsset LoopCameraSettings;

	UPROPERTY(Category = Jetpack)
	TSubclassOf<APlayerJetpackActor> JetpackActor;

	APlayerJetpackActor JetpackInstance;

	AMusicalFlyingSpline ReturnToVolumeSpline;

	// Optional: Exchange the character mesh.
	UPROPERTY(Category = Mesh)
	USkeletalMesh FlyingSkeletalMesh;

	EMusicalFlyingState CurrentFlyingState = EMusicalFlyingState::Inactive;

	// Set this to something in order to activate a behavior when exiting a flying volume
	EMusicalFlyingExitVolumeBehavior ExitVolumeBehavior = EMusicalFlyingExitVolumeBehavior::Nothing;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	EMusicalFlyingBarrelRoll BarrellRollState = EMusicalFlyingBarrelRoll::None;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	EMusicalFlyingTightTurn TightTurnState = EMusicalFlyingTightTurn::None;

	// Relative to default settings.
	UPROPERTY()
	bool bInvertPitch = false;

	UPROPERTY()
	bool bDeactivateFlyingWhenGrounded = true;

	UPROPERTY()
	bool bMoveUpDownWithButtons = true;

	// This will only be true if the player is within a flying volume
	bool bFlyingValid = false;

	int FlyingVolumes = 0;
	int StopFlyingVolumes = 0;

	float PreventCancelTimeElapsed = 0.0f;
	float NoInputDelay = 0;

	// Used for animation purpose to turn up/down/left/right visually
	UPROPERTY(NotEditable, BlueprintReadOnly, Category = Flying)
	FVector2D TurningDirection;

	FVector MovementDirection;
	FVector HoverMovementDirection;
	FVector InputMovementPlane;
	FVector TurnInput;
	FVector MovementRaw;

	FVector ExitVolumeLocation;

	FVector YawAxis;
	FVector PitchAxis;

	float VerticalInput = 0;
	float FlyingVelocity = 0.0f;
	float AccumulatedPitchInput = 0.0f;
	float LoopingPitch = 0.0f;
	FVector2D FlyingTurningInput;
	float BrakingFactor = 0.0f;
	bool bFly = false;
	bool bFlyingPressed = false;
	bool bCancelFlying = false;
	bool bDoLoop = false;
	bool bWantsToFly = false;
	bool bWantsToStopFlying = false;
	bool bIsFlying = false;
	bool bIsReturningToVolume = false;
	bool bWantsToDoLoop = false;
	bool bIsPerformingLoop = false;
	private bool bInfiniteFlying = false;
	private bool bIsInsideFlyingVolume = false;

	// Additional velocity from outside forces
	FVector FlyingImpulse = FVector::ZeroVector;

	bool bForceActivateFlying = false;
	bool bForceDeactivateFlying = false;
	bool bForceActivateReturnToVolume = false;

	UPROPERTY(Category = Animation)
	UAnimSequence BoostAnimA;

	UPROPERTY(Category = Animation)
	UAnimSequence BoostAnimB;

	bool CanFly() const
	{
		if(bInfiniteFlying)
			return true;

		return FlyingVolumes > 0 && StopFlyingVolumes <= 0;
	}

	bool InfiniteFlying() const { return bInfiniteFlying; }

	void SetInfiniteFlying(bool bValue)
	{
		bInfiniteFlying = bValue;

		if(bValue)
		{
			OnInfiniteFlyingEnabled();
		}
		else
		{
			OnInfiniteFlyingDisabled();
		}
	}

	bool IsInfiniteFlying() const { return bInfiniteFlying; }

	// Returns the combined velocity including current boost.
	float GetFlyingVelocityTotal() const property { return FlyingVelocity + CurrentBoost; }

	UPROPERTY(Category = Settings)
	UMusicalFlyingSettings MusicalFlyingSettings = MusicalFlyingSettingsDefault;
	// This how the turning speed etc should behave when we return to volume.
	UPROPERTY(Category = Settings)
	UMusicalFlyingSettings ReturnToVolumePhysicsSettings = MusicalFlyingSettingsDefault;

	// These are specific settings for returning to volume, such as how far out we want to fly etc.
	UPROPERTY(Category = Settings)
	UMusicFlyingReturnToVolumeSettings ReturnToVolumeSettings = MusicFlyingReturnToVolumeSettingsDefault;

	UMusicFlyingReturnToVolumeSettings ReturnToVolumeDefault;

	FVector HoverBoost;

	float CurrentBoost = 0.0f;
	float CurrentBoostCooldown = 0.0f;
	float CurrentTurnRate = 0.0f;

	bool IsInsideFlyingVolume() const
	{
		if(StopFlyingVolumes > 0)
			return false;

		return FlyingVolumes > 0;
	}

	// Used when entering flying and waiting for the startup animation to play until we start accelerating.
	float FlyingStartupTime = 0.0f;

	FVector StartupMovementDirection;
	FVector StartupFacingDirection;

	// We want to know if we started flying on ground or not.
	bool bStartedOnGround = false;
	bool bWasHovering = false;
	bool bIsHovering = false;
	bool bEnableInput = true;

	// Used in return to volume to avoid getting into hover animations when follow spline point while adapting the speed.
	bool bAlwaysFly = false;
	private bool bDisableFlying = false;

	bool IsFlyingDisabled() const { return bDisableFlying; }
	void SetFlyingDisabled(bool bInValue) { bDisableFlying = bInValue; }

	bool IsInputEnabled() const { return bEnableInput; }

	// Used in Capabilities to prevent Enter hover / Exit Flying on the same frame.
	bool bCanSwitchFlyingState = false;

	UFUNCTION(BlueprintPure)
	float GetTurnRate() const { return CurrentTurnRate; }

	AHazePlayerCharacter Player;

	private TMap<AMusicalFlyingVolume, int> ActiveFlyingVolumes;
	// The last flying volume known to this player, right before exiting.
	AMusicalFlyingVolume LastActiveFlyingVolume;
	UPrimitiveComponent LastKnownFlyingVolume;

	FTimerHandle PauseFlyingInputHandle;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ReturnToVolumeSpline = AMusicalFlyingSpline::Spawn();

		devEnsure(BoostAnimA != nullptr);
		devEnsure(BoostAnimB != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		System::ClearAndInvalidateTimerHandle(PauseFlyingInputHandle);
	}

	UFUNCTION()
	void SetFlyingState(EMusicalFlyingState NewState)
	{
		CurrentFlyingState = NewState;
	}

	// Notify Blueprint so we can set vfx etc
	void OnEnterFlying()
	{
		if(JetpackInstance != nullptr)
		{
			JetpackInstance.BP_OnEnterFlying();
		}

		bWasHovering = false;
	}

	void OnEnterHover()
	{
		if(JetpackInstance != nullptr)
		{
			JetpackInstance.BP_OnEnterHover();
		}

		bWasHovering = true;
	}

	void OnExitFlying()
	{
		if(JetpackInstance != nullptr)
		{
			JetpackInstance.BP_OnExitFlying();
		}
	}

	UFUNCTION(BlueprintPure)
	EMusicalFlyingState GetCurrentState() const property { return CurrentFlyingState; }

	void EnteredFlyingVolume(AMusicalFlyingVolume InFlyingVolume)
	{
		if(!HasControl())
			return;

		if(ActiveFlyingVolumes.Contains(InFlyingVolume))
		{
			ActiveFlyingVolumes[InFlyingVolume]++;
		}
		else
		{
			ActiveFlyingVolumes.Add(InFlyingVolume, 1);
		}

		FlyingVolumes += 1;
	}

	void LeftFlyingVolume(AMusicalFlyingVolume InFlyingVolume, UPrimitiveComponent ExitingPrimitive)
	{
		if(!HasControl())
			return;

		AMusicalFlyingVolume TempVolume = nullptr;
		if(ActiveFlyingVolumes.Contains(InFlyingVolume))
		{
			ActiveFlyingVolumes[InFlyingVolume]--;
			if(ActiveFlyingVolumes[InFlyingVolume] <= 0)
			{
				ActiveFlyingVolumes.Remove(InFlyingVolume);
			}
		}

		FlyingVolumes -= 1;
		ExitVolumeLocation = Player.ActorCenterLocation;
		LastActiveFlyingVolume = InFlyingVolume;
		LastKnownFlyingVolume = ExitingPrimitive;

		if(FlyingVolumes == 0 && !bInfiniteFlying)
		{
			bForceActivateFlying = true;
			bForceActivateReturnToVolume = true;
		}
	}

	void GetAllActiveFlyingVolumes(TArray<AMusicalFlyingVolume>& OutFlyingVolumes) const
	{
		OutFlyingVolumes.Reset();

		for(auto It : ActiveFlyingVolumes)
		{
			OutFlyingVolumes.Add(It.Key);
		}
	}

	void EnteredFlyingExclusionVolume(AMusicalFlyingExclusionVolume InExclusionVolume, UPrimitiveComponent ExclusionPrimitive)
	{
		StopFlyingVolumes += 1;
		
		if(bIsFlying)
		{
			LastActiveFlyingVolume = nullptr;
			LastKnownFlyingVolume = nullptr;
		}
	}

	void LeftFlyingExclusionVolume(AMusicalFlyingExclusionVolume InExclusionVolume, UPrimitiveComponent ExclusionPrimitive)
	{
		StopFlyingVolumes -= 1;
	}

	void TriggerBoost()
	{
		UMusicalFlyingSettings Settings = UMusicalFlyingSettings::GetSettings(Player);

		if(bIsHovering)
			FlyingVelocity += Settings.BoostImpulse;
		
		CurrentBoost += Settings.BoostImpulse;

		if(BoostAnimA == nullptr || BoostAnimB == nullptr)
			return;

		int RandomInt = FMath::RandRange(0, 1);

		UAnimSequence BoostAnim = RandomInt == 0 ? BoostAnimA : BoostAnimB;
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = BoostAnim;

		if(Player.IsPlayingAnimAsSlotAnimation(BoostAnim))
		{
			BoostAnim = BoostAnim == BoostAnimA ? BoostAnimB : BoostAnimA;
			AnimParams.Animation = BoostAnim;
		}

		Player.PlaySlotAnimation(AnimParams);
		Player.SetCapabilityActionState(n"AudioStartBoost", EHazeActionState::ActiveForOneFrame);
	}

	FVector2D GetFlyingInput() const property
	{
		FVector2D Input = FlyingTurningInput;
		Input.X *= Player.IsSteeringPitchInverted() ? (bInvertPitch ? -1.0f : 1.0f) : (bInvertPitch ? 1.0f : -1.0f);
		return Input;
	}

	void UpdateFlyingInput(FVector2D NewInput)
	{
		FlyingTurningInput = NewInput;
	}

	void PauseFlyingInput(float Seconds = 1.0f)
	{
		if(!bEnableInput)
			return;

		if(Seconds > 0.0f)
			PauseFlyingInputHandle = System::SetTimer(this, n"ResumeFlyingInput", Seconds, false);
		
		NetSetInputEnabled(false);
	}

	UFUNCTION()
	void ResumeFlyingInput()
	{
		if(bEnableInput)
			return;

		NetSetInputEnabled(true);
		System::ClearAndInvalidateTimerHandle(PauseFlyingInputHandle);
	}

	// Because there might be capabilities that rely on thsi do activate/deactivate
	UFUNCTION(NetFunction)
	private void NetSetInputEnabled(bool bValue)
	{
		bEnableInput = bValue;
	}
}

enum EMusicalFlyingState
{
	Inactive,
	Hovering,
	Flying,
	HalfLoopExit,
	Loop
}

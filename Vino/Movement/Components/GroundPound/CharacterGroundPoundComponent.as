import Peanuts.Animation.Features.LocomotionFeatureGroundPound;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingVolume;
import Vino.Movement.Components.GroundPound.CharacterGroundPoundAnimationDataComponent;
import Vino.Movement.Capabilities.GroundPound.GroundPoundNames;
import Vino.Movement.Capabilities.GroundPound.GroundPoundSettings;
import Vino.Movement.Components.GroundPound.GroundPoundGuideComponent;

enum EGroundPoundState
{
    None,
    Starting,
	EnterDone,
    Falling,
    Landing,
    Jumping,
	Dashing,
    StandingUp
}

struct FGroundPoundAnimationData
{
	UPROPERTY()
	bool bIsFalling = false;

	UPROPERTY()
	bool bIsLanding = false;

	UPROPERTY()
	bool bIsStandingUp = false;

	UPROPERTY()
	bool bIsJumping = false;

	UPROPERTY()
	EGroundPoundJumpType JumpType = EGroundPoundJumpType::None;
}

class UCharacterGroundPoundComponent : UActorComponent
{
	EGroundPoundState ActiveState = EGroundPoundState::None;
	AHazePlayerCharacter PlayerOwner;
	float LandedTimer = 0.f;
	bool bLockLanding = false;

	float FallTime = 0.f;

	bool bWantsToActivate = false;

	UGroundPoundDynamicSettings DynamicSettings;

	UPROPERTY()
	FGroundPoundAnimationData AnimationData;

	UPROPERTY()
	UForceFeedbackEffect LandForceFeedbackEffect = Asset("/Game/Blueprints/ForceFeedback/FF_Medium.FF_Medium");

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> DefaultLandCameraShake = Asset("/Game/Blueprints/Cameras/CameraShakes/CamShake_Heavy.CamShake_Heavy_C");
	TSubclassOf<UCameraShakeBase> CurrentLandCameraShake;

	UPROPERTY()
	UForceFeedbackEffect DashForceFeedbackEffect = Asset("/Game/Blueprints/ForceFeedback/FF_Heavy.FF_Heavy");

	UGroundPoundGuideComponent GuideComp;
	int LandedFrameCounter = 0;

	FHazeCameraImpulse CurrentLandCameraImpulse;
	FHazeCameraImpulse DefaultLandCameraImpulse;
	default DefaultLandCameraImpulse.WorldSpaceImpulse =  -600.f;
	default DefaultLandCameraImpulse.Dampening = 0.15f;
	default DefaultLandCameraImpulse.ExpirationForce = 180.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		DynamicSettings = UGroundPoundDynamicSettings::GetSettings(PlayerOwner);

		CurrentLandCameraShake = DefaultLandCameraShake;
		CurrentLandCameraImpulse = DefaultLandCameraImpulse;

		ensure(PlayerOwner != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		ResetState();

		bLockLanding = false;

		CurrentLandCameraShake = DefaultLandCameraShake;
		CurrentLandCameraImpulse = DefaultLandCameraImpulse;
	}

	void ActiveGroundPound()
	{
		ensure(ActiveState == EGroundPoundState::None);
		ActiveState = EGroundPoundState::Starting;
		GuideComp = nullptr;
		ResetActivation();

		PlayerOwner.SetCapabilityActionState(GroundPoundEventActivation::System, EHazeActionState::Active);
	}

	void ResetState()
	{
		ActiveState = EGroundPoundState::None;
		ResetAnimationData();

		LandedTimer = 0.f;
		LandedFrameCounter = 0.f;

		PlayerOwner.SetCapabilityActionState(GroundPoundEventActivation::System, EHazeActionState::Inactive);
		PlayerOwner.SetCapabilityActionState(GroundPoundEventActivation::Landed, EHazeActionState::Inactive);

		GuideComp = nullptr;
		ResetActivation();
	}

	void ChangeToState(EGroundPoundState NewState)
	{
		ensure(NewState != EGroundPoundState::None);
		ensure(NewState != EGroundPoundState::Starting);

		ActiveState = NewState;
	}

	void GroundPoundLand()
	{
		ChangeToState(EGroundPoundState::Landing);
		AnimationData.bIsLanding = true;
		LandedTimer = 0.f;

		PlayerOwner.SetCapabilityActionState(GroundPoundEventActivation::Landed, EHazeActionState::Active);
	}

	bool IsAllowLandedAction(float TimeToCheck, bool bCareAboutStun = true) const
	{
		if (bLockLanding)
			return false;

		if (ActiveState != EGroundPoundState::Landing)
			return false;
		
		const float CheckTime = TimeToCheck + (bCareAboutStun ? GroundPoundSettings::Landing.StunDuration : 0.f);
		return LandedTimer >= CheckTime;
	}

	bool HasValidGuideTarget()
	{
		return GuideComp != nullptr;
	}

	void SetGuideTarget(UGroundPoundGuideComponent Target)
	{
		if (!ensure(Target != nullptr))
			return;

		if (!ensure(Target.HelperVolumeIsValid()))
			return;

		GuideComp = Target;
	}

	void SetToWantToActivate()
	{
		bWantsToActivate = true;
	}

	void ResetActivation()
	{
		bWantsToActivate = false;
	}

	bool WantsToActive() const
	{
		return bWantsToActivate;
	}

	void LockStayInLanding()
	{
		bLockLanding = true;
	}

	void UnlockStayInLanding()
	{
		bLockLanding = false;
	}

	bool IsCurrentState(EGroundPoundState CheckState) const
	{
		return ActiveState == CheckState;
	}

	void ResetAnimationData()
	{
		AnimationData = FGroundPoundAnimationData();
	}

	bool LandedThisFrame() const
	{
		return LandedFrameCounter == 1;
	}

	bool IsGroundPounding() const
	{
		return ActiveState != EGroundPoundState::None;
	}
}

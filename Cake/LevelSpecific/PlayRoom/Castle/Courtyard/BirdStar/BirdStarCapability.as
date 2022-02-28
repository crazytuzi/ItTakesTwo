import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Music.NightClub.RhythmDanceAreaActor;
import Vino.Movement.Components.MovementComponent;

class UBirdStarCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"LevelSpecific";

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	AHazePlayerCharacter Player;
	UPlayerRhythmComponent RhythmComp;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	bool bWasAnyButtonPressed = false;
	bool bMoveToCenter = false;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		RhythmComp = UPlayerRhythmComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(RhythmComp.RhythmDanceArea == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!RhythmComp.bRhythmActive)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		return RhythmComp != nullptr && RhythmComp.RhythmDanceArea != nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Owner.BlockCapabilities(MovementSystemTags::GroundMovement, this);
		// Owner.BlockCapabilities(MovementSystemTags::Jump, this);
		// Owner.BlockCapabilities(MovementSystemTags::Crouch, this);
		// Owner.BlockCapabilities(MovementSystemTags::Dash, this);
		// Owner.BlockCapabilities(MovementSystemTags::SlopeSlide, this);
		Player.AddLocomotionFeature(Player.IsMay() ? RhythmComp.MayDance : RhythmComp.CodyDance);
		bMoveToCenter = false;
		RhythmComp.StartDancing();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Owner.UnblockCapabilities(MovementSystemTags::GroundMovement, this);
		// Owner.UnblockCapabilities(MovementSystemTags::Jump, this);
		// Owner.UnblockCapabilities(MovementSystemTags::Crouch, this);
		// Owner.UnblockCapabilities(MovementSystemTags::Dash, this);
		// Owner.UnblockCapabilities(MovementSystemTags::SlopeSlide, this);
		Player.ClearLocomotionAssetByInstigator(this);
		RhythmComp.StopDancing();

		//Reset these
		RhythmComp.bLeftMiss = false;
		RhythmComp.bLeftHit = false;
		RhythmComp.bTopMiss = false;
		RhythmComp.bTopHit = false;
		RhythmComp.bRightMiss = false;
		RhythmComp.bRightHit = false;
	}	

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(RhythmComp.RhythmDanceArea == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!RhythmComp.bRhythmActive)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		RhythmComp.bLeftMiss = false;
		RhythmComp.bLeftHit = false;
		RhythmComp.bTopMiss = false;
		RhythmComp.bTopHit = false;
		RhythmComp.bRightMiss = false;
		RhythmComp.bRightHit = false;

		MoveComp.SetAnimationToBeRequested(n"Dance");
	}

	bool GetPlayerAnyInput() const property
	{
		return WasActionStarted(ActionNames::DanceLeft) || 
		WasActionStarted(ActionNames::DanceTop) || 
		WasActionStarted(ActionNames::DanceRight);
	}
}

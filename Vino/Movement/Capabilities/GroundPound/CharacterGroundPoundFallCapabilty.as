import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;
import Vino.Movement.Capabilities.GroundPound.GroundPoundNames;
import Vino.Movement.Capabilities.GroundPound.GroundPoundSettings;

class UCharacterGroundPoundFallCapability : UCharacterMovementCapability
{
	default RespondToEvent(GroundPoundEventActivation::System);

	default CapabilityTags.Add(MovementSystemTags::GroundPound);
	default CapabilityTags.Add(GroundPoundTags::Start);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);

	default BlockExclusionTags.Add(BlockExclusionTags::UsableDuringGroundPound);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 114;

	UCharacterGroundPoundComponent GroundPoundComp;

	float EnterDuration = 1.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		GroundPoundComp = UCharacterGroundPoundComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!GroundPoundComp.IsCurrentState(EGroundPoundState::EnterDone))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		GroundPoundComp.ChangeToState(EGroundPoundState::Falling);
		GroundPoundComp.AnimationData.bIsFalling = true;

		Owner.BlockCapabilities(MovementSystemTags::LedgeGrab, this);
		Owner.SetCapabilityActionState(GroundPoundEventActivation::Falling, EHazeActionState::Active);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();
		
		if (!GroundPoundComp.IsCurrentState(EGroundPoundState::Falling))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb; 

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		if (!GroundPoundComp.IsCurrentState(EGroundPoundState::Landing))
			GroundPoundComp.ResetState();

		GroundPoundComp.FallTime = 0.f;

		Owner.UnblockCapabilities(MovementSystemTags::LedgeGrab, this);
		Owner.SetCapabilityActionState(GroundPoundEventActivation::Falling, EHazeActionState::Inactive);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FallMove = MoveComp.MakeFrameMovement(n"GroundPoundFall");

		if(HasControl())
		{
			float Speed = FMath::GetMappedRangeValueClamped(FVector2D(0.f, GroundPoundSettings::Falling.FallTimeToReachMaxSpeed), FVector2D(GroundPoundSettings::Falling.FallStartSpeed, GroundPoundSettings::Falling.FallMaxSpeed), GroundPoundComp.FallTime);

			// Calculate delta location and move the character
			FVector DeltaMove = MoveComp.WorldUp * (-Speed * DeltaTime);
			FallMove.ApplyDelta(DeltaMove);
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			FallMove.ApplyConsumedCrumbData(CrumbData);
		}

		MoveCharacter(FallMove, FeatureName::GroundPound);
		CrumbComp.LeaveMovementCrumb();

		GroundPoundComp.FallTime += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
		GroundPoundComp.ResetState();
	}
}

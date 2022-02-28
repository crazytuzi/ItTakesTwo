import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;
import Vino.Movement.Capabilities.GroundPound.GroundPoundNames;
import Vino.Movement.Capabilities.GroundPound.GroundPoundSettings;

class UCharacterGroundPoundEnterCapability : UCharacterMovementCapability
{
	default RespondToEvent(MovementActivationEvents::Airbourne);

	default CapabilityTags.Add(MovementSystemTags::GroundPound);
	default CapabilityTags.Add(GroundPoundTags::Start);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 113;

	UCharacterGroundPoundComponent GroundPoundComp;
	AHazePlayerCharacter PlayerOwner = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		GroundPoundComp = UCharacterGroundPoundComponent::GetOrCreate(Owner);

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		ensure(PlayerOwner != nullptr);
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!GroundPoundComp.WantsToActive())
			return EHazeNetworkActivation::DontActivate;

		if (!IsHighEnough())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		GroundPoundComp.ActiveGroundPound();

		Owner.BlockCapabilities(MovementSystemTags::LedgeGrab, this);
		Owner.BlockCapabilitiesExcluding(CapabilityTags::GameplayAction, BlockExclusionTags::UsableDuringGroundPound, this);

		Owner.BlockCapabilities(ActionNames::WeaponAim, this);

		PlayerOwner.ApplyPivotLagSpeed(FVector(0.5f, 0.5f, 0.f), this, EHazeCameraPriority::Low);
		PlayerOwner.ApplyPivotLagMax(FVector(200.f, 200.f, 400.f), this, EHazeCameraPriority::Low);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();
		
		if (ActiveDuration >= GroundPoundSettings::Enter.Duration)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		Owner.UnblockCapabilities(MovementSystemTags::LedgeGrab, this);
		Owner.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		Owner.UnblockCapabilities(ActionNames::WeaponAim, this);

		if (IsBlocked() || MoveComp.IsGrounded())
			GroundPoundComp.ResetState();
		else
			GroundPoundComp.ChangeToState(EGroundPoundState::EnterDone);

		PlayerOwner.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement EnterMove = MoveComp.MakeFrameMovement(n"GroundPoundEnter");

		if(!HasControl())
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			EnterMove.ApplyConsumedCrumbData(CrumbData);
		}
		else
			EnterMove.OverrideStepDownHeight(0.f);

		MoveCharacter(EnterMove, FeatureName::GroundPound);
		CrumbComp.LeaveMovementCrumb();
	}

	bool IsHighEnough() const
	{
		// If you are moving downwards, you are always high enough to ground pound
		if (MoveComp.Velocity.DotProduct(MoveComp.WorldUp) < 0.f)
			return true;

		// Check distance to ground
		FHazeTraceParams GroundTrace;
		GroundTrace.InitWithMovementComponent(MoveComp);
		GroundTrace.From = Owner.ActorLocation;
		GroundTrace.To = GroundTrace.From - MoveComp.WorldUp * GroundPoundComp.DynamicSettings.MinHeight;
		FHazeHitResult Hit;

		if (GroundTrace.Trace(Hit))
			return false;
		
		return true;
	}
}

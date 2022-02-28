import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;

void RequestGroundPoundGuideCapability()
{
	Capability::AddPlayerCapabilityRequest(UCharacterGroundGroundPoundGuidedEnterCapability::StaticClass());
}

void UnrequestGroundPoundGuideCapability()
{
	Capability::RemovePlayerCapabilityRequest(UCharacterGroundGroundPoundGuidedEnterCapability::StaticClass());
}

class UCharacterGroundGroundPoundGuidedEnterCapability : UCharacterMovementCapability
{
	default RespondToEvent(MovementActivationEvents::Airbourne);

	default CapabilityTags.Add(MovementSystemTags::GroundPound);
	default CapabilityTags.Add(GroundPoundTags::Start);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 112;

	UCharacterGroundPoundComponent GroundPoundComp;
	AHazePlayerCharacter PlayerOwner = nullptr;

	UGroundPoundGuideComponent Target;

	float Speed = 0.f;

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

		if (!GroundPoundComp.HasValidGuideTarget())
			return EHazeNetworkActivation::DontActivate;

		if (!IsHighEnough())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		if (HasControl())
		{
			Target = GroundPoundComp.GuideComp;
			FVector DeltaToCenter = FMath::ClosestPointOnLine(Target.WorldLocation, Target.WorldLocation - (MoveComp.WorldUp * Target.VolumeHeight), MoveComp.OwnerLocation) - MoveComp.OwnerLocation;
			Speed = DeltaToCenter.Size() / GroundPoundSettings::Enter.Duration;
		}

		GroundPoundComp.ActiveGroundPound();

		Owner.BlockCapabilitiesExcluding(CapabilityTags::MovementAction, BlockExclusionTags::UsableDuringGroundPound, this);
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
		Owner.UnblockCapabilities(CapabilityTags::MovementAction, this);
		Owner.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		Owner.UnblockCapabilities(ActionNames::WeaponAim, this);

		if (IsBlocked())
			GroundPoundComp.ResetState();
		else
			GroundPoundComp.ChangeToState(EGroundPoundState::EnterDone);

		PlayerOwner.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement EnterMove = MoveComp.MakeFrameMovement(n"GroundPoundEnter");

		if(HasControl())
		{
			if (Target.LocationIsWithinActivationRegionOfVolume(MoveComp.OwnerLocation, MoveComp.WorldUp, IsDebugActive()))
			{
				FVector DeltaToCenter = FMath::ClosestPointOnLine(Target.WorldLocation, Target.WorldLocation - (MoveComp.WorldUp * Target.VolumeHeight), MoveComp.OwnerLocation) - MoveComp.OwnerLocation;
				FVector Delta = DeltaToCenter.SafeNormal * Speed * DeltaTime;
				EnterMove.ApplyDelta(Delta);
			}
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			EnterMove.ApplyConsumedCrumbData(CrumbData);
		}	

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


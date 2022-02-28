import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;
import Vino.Movement.Components.GroundPound.GroundPoundGuideComponent;

void RequestGroundPoundGuideEvaluateCapability()
{
	Capability::AddPlayerCapabilityRequest(UCharacterGroundPoundGuideEvaluateCapability::StaticClass());
}

void UnrequestGroundPoundGuideEvaluateCapability()
{
	Capability::RemovePlayerCapabilityRequest(UCharacterGroundPoundGuideEvaluateCapability::StaticClass());
}

class UCharacterGroundPoundGuideEvaluateCapability : UHazeCapability
{
	default RespondToEvent(MovementActivationEvents::Airbourne);

	default CapabilityTags.Add(MovementSystemTags::GroundPound);
	default CapabilityTags.Add(GroundPoundTags::Start);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 111;

	UHazeBaseMovementComponent MoveComp;
	UCharacterGroundPoundComponent GroundPoundComp;
	AHazePlayerCharacter PlayerOwner = nullptr;

	TArray<UGroundPoundGuideComponent> PotentialTargetComps;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		GroundPoundComp = UCharacterGroundPoundComponent::GetOrCreate(Owner);
		MoveComp = UHazeBaseMovementComponent::GetOrCreate(Owner);

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		ensure(PlayerOwner != nullptr);
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (!GroundPoundComp.WantsToActive())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		UpdatePotentialTargets();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!GroundPoundComp.WantsToActive())
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		if (MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for (UGroundPoundGuideComponent Target : PotentialTargetComps)
		{
			if (Target == nullptr)
				continue;

			if (Target.LocationIsWithinActivationRegionOfVolume(MoveComp.OwnerLocation, MoveComp.WorldUp, IsDebugActive()))
			{
				GroundPoundComp.SetGuideTarget(Target);
				break;
			}
		}
	}

	void UpdatePotentialTargets()
	{
		FHazeTraceParams CloseActors;
		CloseActors.InitWithMovementComponent(MoveComp);
		CloseActors.SetToSphere(1500.f);
		CloseActors.DebugDrawTime = IsDebugActive() ? 2.f : -1.f;

		TArray<FOverlapResult> Overlaps;
		if (CloseActors.Overlap(Overlaps))
		{
			for (FOverlapResult& Overlap : Overlaps)
			{
				if (Overlap.Actor == nullptr)
					continue;

				auto PotentionalTarget = UGroundPoundGuideComponent::Get(Overlap.Actor);
				if (PotentionalTarget == nullptr)
					continue;
				
				if (!PotentionalTarget.HelperVolumeIsValid())
					continue;

				if (IsDebugActive())
					PotentionalTarget.RenderVolume(FLinearColor::Teal, 2.f);
				PotentialTargetComps.Add(PotentionalTarget);
			}
		}
	}
}

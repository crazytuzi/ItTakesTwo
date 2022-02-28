import Cake.LevelSpecific.SnowGlobe.SkiLift.SkiLift;

enum ESkiLiftBarInteractionState
{
	None,
	BlendingIn,
	Holding,
	BlendingOut
}

class UPlayerSkiLiftBarInteractionCapability : UHazeCapability
{
	default CapabilityTags.Add(n"LevelSpecific");
	default CapabilityTags.Add(n"SnowglobeSkiLiftBarInteraction");

	default TickGroup = ECapabilityTickGroups::ActionMovement;

	default CapabilityDebugCategory = n"LevelSpecific";

	AHazePlayerCharacter PlayerOwner;
	ASkiLift SkiLift;

	ESkiLiftBarInteractionState InteractionState;

	const float BlendInTime = 0.2f;
	const float BlendOutTime = 0.2f;
	const float HoldDuration = 1.f;

	float TargetTimestamp;
	float BlendAlpha = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!PlayerOwner.IsAnyCapabilityActive(n"SnowglobeSkiLift"))
			return EHazeNetworkActivation::DontActivate;

		if(!IsActioning(ActionNames::InteractionTrigger))
			return EHazeNetworkActivation::DontActivate;

		if(GetAttributeObject(n"SkiLift") == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{
		SyncParams.AddObject(n"SkiLift", GetAttributeObject(n"SkiLift"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SkiLift = Cast<ASkiLift>(ActivationParams.GetObject(n"SkiLift"));

		InteractionState = ESkiLiftBarInteractionState::BlendingIn;
		PlayerOwner.SetAnimFloatParam(n"ReadyAmount", 0.f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		switch(InteractionState)
		{
			case ESkiLiftBarInteractionState::BlendingIn:

				BlendAlpha = Math::Saturate(ActiveDuration / BlendInTime);
				PlayerOwner.SetAnimFloatParam(n"ReadyAmount", FMath::Square(BlendAlpha));

				if(BlendAlpha >= 1.f)
				{
					BlendAlpha = 0.f;
					TargetTimestamp = ActiveDuration + HoldDuration;
					InteractionState = ESkiLiftBarInteractionState::Holding;

					SkiLift.StartInteracting(PlayerOwner.Player);
				}

				break;

			case ESkiLiftBarInteractionState::Holding:

				// Check if other player is also holding
				if(HasControl() && SkiLift.HasControl() && SkiLift.BothPlayersAreInteracting())
				{
					// Fire exit event with crumb and deactivate capability
					TriggerSkiLiftExitFromCrumb();
					// NetTriggerSkiLiftExit();

					InteractionState = ESkiLiftBarInteractionState::None;
				}

				PlayerOwner.SetAnimFloatParam(n"ReadyAmount", 1.f);

				if(ActiveDuration >= TargetTimestamp)
				{
					SkiLift.StopInteracting(PlayerOwner.Player);

					BlendAlpha = 1.f;
					TargetTimestamp = ActiveDuration + BlendOutTime;
					InteractionState = ESkiLiftBarInteractionState::BlendingOut;
				}

				break;

			case ESkiLiftBarInteractionState::BlendingOut:

				BlendAlpha = Math::Saturate((TargetTimestamp - ActiveDuration) / BlendOutTime);
				PlayerOwner.SetAnimFloatParam(n"ReadyAmount", BlendAlpha);

				if(BlendAlpha <= 0.f)
					InteractionState = ESkiLiftBarInteractionState::None;

				break;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(InteractionState == ESkiLiftBarInteractionState::None)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(GetAttributeObject(n"SkiLift") == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SkiLift = nullptr;
		InteractionState = ESkiLiftBarInteractionState::None;
		BlendAlpha = 0.f;
		TargetTimestamp = 0.f;
	}

	void TriggerSkiLiftExitFromCrumb()
	{
		UHazeCrumbComponent CrumbComponent = UHazeCrumbComponent::Get(PlayerOwner);
		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddObject(n"SkiLift", SkiLift);
		CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_OnTriggerSkiLiftExit"), CrumbParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_OnTriggerSkiLiftExit(const FHazeDelegateCrumbData& CrumbData)
	{
		ASkiLift CrumbedSkiLift = Cast<ASkiLift>(CrumbData.GetObject(n"SkiLift"));
		CrumbedSkiLift.OnSkiLiftExitEvent.Broadcast();
	}

	UFUNCTION(NetFunction)
	void NetTriggerSkiLiftExit()
	{
		SkiLift.OnSkiLiftExitEvent.Broadcast();
	}
}
import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.Capabilities.TrapezeMarbleCatchTimeDilationCapabilityBase;

class UTrapezeMarbleCatchTimeDilationEnterCapability : UTrapezeMarbleCatchTimeDilationCapabilityBase
{
	default CapabilityTags.Add(TrapezeTags::MarbleCatchTimeDilationEnter);

	const float DilationFactor = 0.1f;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::DontActivate;

		// if(!HasControl())
		// 	return EHazeNetworkActivation::DontActivate;

		// if(!TrapezeInteractionComponent.IsSwinging())
		// 	return EHazeNetworkActivation::DontActivate;

		// if(IsActioning(n"EnteredTrapezeTimeDilation"))
		// 	return EHazeNetworkActivation::DontActivate;

		// if(!TrapezeInteractionComponent.GetMarbleWithinReach(MarbleActor))
		// 	return EHazeNetworkActivation::DontActivate;

		// if(IsActioning(n"JustThrewMarble"))
		// 	return EHazeNetworkActivation::DontActivate;

		// return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		LerpAlpha = 0.f;
		LerpStart = 1.f;
		LerpTarget = DilationFactor;
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return LerpAlpha >= 1.f || PlayerOwner.IsAnyCapabilityActive(TrapezeTags::MarbleCatchTimeDilationExit) ?
			EHazeNetworkDeactivation::DeactivateLocal :
			EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.SetCapabilityActionState(n"EnteredTrapezeTimeDilation", EHazeActionState::Active);
	}
}
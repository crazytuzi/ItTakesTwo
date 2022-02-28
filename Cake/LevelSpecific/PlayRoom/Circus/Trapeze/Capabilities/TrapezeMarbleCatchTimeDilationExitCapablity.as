import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.Capabilities.TrapezeMarbleCatchTimeDilationCapabilityBase;

class UTrapezeMarbleCatchTimeDilationExitCapability : UTrapezeMarbleCatchTimeDilationCapabilityBase
{
	default CapabilityTags.Add(TrapezeTags::MarbleCatchTimeDilationExit);

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!IsActioning(n"EnteredTrapezeTimeDilation"))
			return EHazeNetworkActivation::DontActivate;

		if(!TrapezeInteractionComponent.IsSwinging()		 				||
		   !TrapezeInteractionComponent.GetMarbleWithinReach(MarbleActor) 	||
		    PickupComponent.CurrentPickup != nullptr					||
			IsActioning(ActionNames::InteractionTrigger))
			{
				return EHazeNetworkActivation::ActivateFromControl;
			}
		
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerOwner.SetCapabilityActionState(n"EnteredTrapezeTimeDilation", EHazeActionState::Inactive);

		LerpAlpha = 0.f;
		LerpStart = Time::GetWorldTimeDilation();
		LerpTarget = 1.f;
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return LerpAlpha >= 1.f ?
			EHazeNetworkDeactivation::DeactivateLocal :
			EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Time::SetWorldTimeDilation(1.f);
	}
}
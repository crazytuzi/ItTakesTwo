import Cake.LevelSpecific.Tree.Larvae.Behaviours.LarvaBehaviourCapability;

class ULarvaBehaviourHoldCapability : ULarvaBehaviourCapability
{
    default State = ELarvaState::Idle;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		Owner.PlaySlotAnimation(Animation = BehaviourComponent.AnimFeature.Idle_Mh, bLoop = true);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaSeconds)
    {
        if (BehaviourComponent.CanEatSap())
        {
            // Sapped, nom nom!
            BehaviourComponent.State = ELarvaState::Stunned; 
            return;
        }

        if (BehaviourComponent.GetTarget() != nullptr)
		{
			// We've found a target, engage!
            BehaviourComponent.State = ELarvaState::Pursue; 
            return;
        }
    }
}

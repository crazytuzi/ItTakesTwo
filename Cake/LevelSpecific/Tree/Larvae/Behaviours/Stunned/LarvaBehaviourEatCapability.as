import Cake.LevelSpecific.Tree.Larvae.Behaviours.LarvaBehaviourCapability;
import Cake.Weapons.Sap.SapManager;

class ULarvaBehaviourEatCapability : ULarvaBehaviourCapability
{
    default State = ELarvaState::Stunned;

    float EatSapTime = 0.f;
	float EatEffectTime = 0.f;
	const float EatAmount = 0.5f;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
        EatSapTime = Time::GetGameTimeSeconds() + (Settings.EatSapDuration * EatAmount);
		EatEffectTime = Time::GetGameTimeSeconds();

		Owner.PlaySlotAnimation(Animation = BehaviourComponent.AnimFeature.Eat, bLoop = true);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaSeconds)
    {
        if (!BehaviourComponent.CanEatSap())
        {
            // Done eating. Skip straight to pursue if we have a target, to avoid extra activation crumb
		 	if (BehaviourComponent.GetTarget() != nullptr)
				BehaviourComponent.State = ELarvaState::Pursue; 
			else 
				BehaviourComponent.State = ELarvaState::Idle;
            return;
        }

		if (Time::GetGameTimeSeconds() > EatEffectTime)
		{
            Niagara::SpawnSystemAtLocation(BehaviourComponent.EatEffect, BehaviourComponent.EatLocation);
			EatEffectTime += FMath::RandRange(0.4f, 0.7f); 
		}

        if (Time::GetGameTimeSeconds() > EatSapTime)
        {
            // Remove some sap
            if (FMath::IsNearlyZero(RemoveSapMassFrom(Owner.RootComponent, EatAmount)))
				RemoveSapMassNear(BehaviourComponent.EatLocation, Settings.EatRadius + 60.f, EatAmount);

            EatSapTime += (Settings.EatSapDuration * EatAmount);
			BehaviourComponent.EatSap(EatAmount);
	    }

		if ((BehaviourComponent.AttachedSap == 0.f) && 
			(BehaviourComponent.EatableSap != nullptr))
		{
			// Move to external sap
			FVector SapLoc = BehaviourComponent.EatableSap.ActorLocation;
			float RadiusSqr = FMath::Square(40.f);
			if ((BehaviourComponent.EatLocation.DistSquared2D(SapLoc) > RadiusSqr) && 
				(Owner.ActorLocation.DistSquared2D(SapLoc) > RadiusSqr))
			{
				BehaviourMoveComp.CrawlTo(SapLoc);
			}
		}
    }
}

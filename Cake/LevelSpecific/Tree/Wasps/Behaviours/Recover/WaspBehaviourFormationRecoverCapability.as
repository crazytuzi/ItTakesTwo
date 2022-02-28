import Cake.LevelSpecific.Tree.Wasps.Scenepoints.WaspFormationScenepoint;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspLocalBehaviourCapability;

class UWaspBehaviourFormationRecoverCapability : UWaspLocalBehaviourCapability
{
    default State = EWaspState::Recover;

	UWaspFormationScenepointComponent Scenepoint = nullptr;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		Scenepoint = Cast<UWaspFormationScenepointComponent>(BehaviourComponent.CurrentScenepoint);
		BehaviourComponent.UseScenepoint(Scenepoint);

        UGentlemanFightingComponent GentlemanComp = BehaviourComponent.GetGentlemanComponent();
        if (GentlemanComp != nullptr)  
            GentlemanComp.ReleaseAction(n"WaspAttack", Owner);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaSeconds)
    {
		FVector RecoverDestination = Scenepoint.GetFormationDestination();
		if (HasReachedDestination(RecoverDestination))
		{
            BehaviourComponent.State = EWaspState::Flee; 
			return;
		}

		float HeightDelta = RecoverDestination.Z - Owner.ActorLocation.Z;
		if (HeightDelta > 0.f)
			RecoverDestination.Z += HeightDelta * 1.f;

		float VelocityTowardsDest = (BehaviourComponent.GetVelocity().DotProduct(Scenepoint.GetFormationDirection()));
		float Alpha = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 500.f), FVector2D(1.f, 0.5f), VelocityTowardsDest);
		FVector Dest = FMath::VLerp(Owner.ActorLocation, RecoverDestination, FVector(Alpha, Alpha, 1.f));
        BehaviourComponent.MoveTo(Dest, Settings.AttackRunAcceleration * 0.5f);
    }

	bool HasReachedDestination(const FVector& Destination)
	{
        FVector ToDest = Destination - Owner.GetActorLocation();
		if (ToDest.SizeSquared() < FMath::Square(Scenepoint.Radius))
			return true;
		if (ToDest.DotProduct(Scenepoint.FormationDirection) < 0.f)
			return true;
		return false;
	}
}

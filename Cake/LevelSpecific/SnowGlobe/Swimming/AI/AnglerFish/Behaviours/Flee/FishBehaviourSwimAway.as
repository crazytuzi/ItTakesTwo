import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourCapability;

class UFishBehaviourSwimAwayCapability : UFishBehaviourCapability
{
    default State = EFishState::Flee;
 	FHazeAcceleratedFloat VerticalBias;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		EffectsComp.SetEffectsMode(EFishEffectsMode::Idle);
		AnimComp.SetGapingPercentage(0.f);
		AnimComp.SetAgitated(true);
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaSeconds)
    {
		bool bStuck = (Owner.GetActualVelocity().SizeSquared() < FMath::Square(50.f));
		VerticalBias.AccelerateTo(bStuck ? 100.f : 1.f, 3.f, DeltaSeconds);		

		// Just repulse from player center location
		FVector RepulseLoc = (Game::GetCody().ActorLocation + Game::GetMay().ActorLocation) * 0.5f;
		FVector FleeDir = (Owner.ActorLocation - RepulseLoc).GetSafeNormal2D();
		FleeDir.Z = VerticalBias.Value;  
		BehaviourComponent.MoveTo(Owner.ActorLocation + FleeDir * 1000.f, Settings.FleeAcceleration, Settings.FleeTurnDuration);

		// Fish should get disabled by disable range at some point...
    }
}

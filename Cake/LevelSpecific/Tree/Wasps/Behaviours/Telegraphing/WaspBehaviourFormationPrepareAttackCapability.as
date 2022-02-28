import Cake.LevelSpecific.Tree.Wasps.Scenepoints.WaspFormationScenepoint;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspLocalBehaviourCapability;

class UWaspBehaviourFormationPrepareAttackCapability : UWaspLocalBehaviourCapability
{
    default State = EWaspState::Telegraphing;

    float AttackTime;
	UWaspFormationScenepointComponent Scenepoint = nullptr;
	int TauntIndex = 0;
	float TauntTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

        // Set time for attack
        AttackTime = Time::GetGameTimeSeconds() + Settings.PrepareAttackDuration;
		Scenepoint = Cast<UWaspFormationScenepointComponent>(BehaviourComponent.CurrentScenepoint);
		ensure(Scenepoint != nullptr);
		BehaviourComponent.UseScenepoint(Scenepoint);
		EffectsComp.ShowAttackEffect(Scenepoint.GetFormationDestination());
		TauntIndex = (TauntIndex + 1) % AnimComp.AnimFeature.Taunts.Num();
        TauntTime = Time::GameTimeSeconds + Settings.PrepareAttackDuration - Settings.TauntDuration;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if (Time::GetGameTimeSeconds() > AttackTime)
        {
            BehaviourComponent.State = EWaspState::Attack;
            return;
        }

		if ((TauntTime > 0.f) && (Time::GameTimeSeconds > TauntTime)) 
		{
			TauntTime = 0.f;
			AnimComp.PlayAnimation(EWaspAnim::Taunts, TauntIndex, 0.2f);
		}

		// Accelerate back to scenepoint if we've overshot
		FVector ScenePointOffsetLoc = Scenepoint.WorldLocation;
		FVector SpawnDir = ScenePointOffsetLoc - Scenepoint.GetFormationSpawnLocation();
		FVector ToDest = ScenePointOffsetLoc - Owner.ActorLocation;
		if (ToDest.DotProduct(SpawnDir) < 0.f)
		{
			FVector PredictVelocity = BehaviourComponent.Velocity + BehaviourComponent.TargetGroundVelocity.Value;
			FVector ToDestPredicted = ScenePointOffsetLoc - (Owner.ActorLocation + PredictVelocity * 0.5f);
			if (ToDestPredicted.DotProduct(SpawnDir) < 0.f)
			{
				float Acc = Settings.EngageAcceleration * ToDest.Size() * 0.002f;
				BehaviourComponent.MoveTo(ScenePointOffsetLoc, Acc);
			}
		}

        // Face formation direction
        BehaviourComponent.RotateTowards(Owner.ActorLocation + Scenepoint.FormationDirection * 1000.f);
    }
}


import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAI.Teleporter.CastleEnemyTeleporterComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;

class UCastleEnemyTeleporterPhaseCapability : UHazeCapability
{
	ACastleEnemy Enemy;
	UCastleEnemyTeleporterComponent TeleportComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		Enemy = Cast<ACastleEnemy>(Owner);
		Enemy.bCanDie = false;

		TeleportComp = UCastleEnemyTeleporterComponent::Get(Enemy);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (TeleportComp.Phases.IsValidIndex(TeleportComp.CurrentPhase + 1))
		{
			float HealthPct = float(Enemy.Health) / float(Enemy.MaxHealth);
			if (HealthPct < TeleportComp.Phases[TeleportComp.CurrentPhase + 1].HealthThreshold)
				Enemy.bUnhittable = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!TeleportComp.Phases.IsValidIndex(TeleportComp.CurrentPhase + 1))
			return EHazeNetworkActivation::DontActivate;
		
		float HealthPct = float(Enemy.Health) / float(Enemy.MaxHealth);
		if (HealthPct > TeleportComp.Phases[TeleportComp.CurrentPhase + 1].HealthThreshold)
			return EHazeNetworkActivation::DontActivate;

		if (DeactiveDuration < 1.f)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TeleportComp.CurrentPhase += 1;

		FCastleEnemyTeleporterPhase& Phase = TeleportComp.Phases[TeleportComp.CurrentPhase];
		FVector TeleportLocation = Phase.TargetLocation.ActorLocation;

		Enemy.SetCapabilityActionState(n"Teleport", EHazeActionState::Active);
		Enemy.SetCapabilityAttributeVector(n"TeleportLocation", TeleportLocation);
		Enemy.SetCapabilityAttributeVector(n"TeleportRotation", Phase.TargetLocation.ActorForwardVector);

		Enemy.SetEnemyHealth(Phase.HealthThreshold * Enemy.MaxHealth);
		Enemy.bCanDie = (TeleportComp.CurrentPhase == (TeleportComp.Phases.Num() - 1));

		for (auto OtherEnemy : Phase.EnemiesToTeleportIn)
			TeleportComp.TeleportInEnemy(OtherEnemy);
	}
};
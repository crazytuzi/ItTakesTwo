import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBossTags;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;


class UClockworkBullBossUpdateImpactCapability : UHazeCapability
{
	default CapabilityTags.Add(ClockworkBullBossTags::ClockworkBullBoss);
	default CapabilityTags.Add(ClockworkBullBossTags::ClockworkBullBossPlayerCollisionImpact);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 200;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AClockworkBullBoss BullOwner;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BullOwner = Cast<AClockworkBullBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!BullOwner.bIsInCombat)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!BullOwner.bIsInCombat)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		BullOwner.UpdateCollisionBonusDistances(DeltaTime);

		TArray<AHazePlayerCharacter> AvailableTargets;
		TArray<FHazeIntersectionCapsule> PlayerCapsules;
		for(auto Player : BullOwner.AvailableTargets)
		{
			if(!BullOwner.CanTargetPlayer(Player, false))
				continue;

			if(Player.IsPlayerInIFrame())
				continue;

			UCapsuleComponent PlayerCapsule = Player.CapsuleComponent;
			FHazeIntersectionCapsule Capsule;
			Capsule.MakeUsingOrigin(
				PlayerCapsule.WorldLocation, 
				PlayerCapsule.WorldRotation, 
				PlayerCapsule.CapsuleHalfHeight, 
				PlayerCapsule.CapsuleRadius);

			PlayerCapsules.Add(Capsule);
			AvailableTargets.Add(Player);
		}

		for(FBullAttackCollisionData& collision : BullOwner.CollisionData)
		{	
			if(collision.CollisionComponent == nullptr)
				continue;

			if(!collision.bEnabled)
				continue;

		

			for(int i = 0; i < PlayerCapsules.Num(); ++i)
			{
				const FHazeIntersectionCapsule& PlayerCapsule = PlayerCapsules[i];
				FHazeIntersectionResult Result;
				FVector2D impactCollisionSize = collision.GetCollisionSize();
				if(impactCollisionSize.Y > 0)
					Result.QueryCapsuleCapsule(PlayerCapsule, collision.GetCapsule());
				else
					Result.QueryCapsuleSphere(PlayerCapsule, collision.GetSphere());

				if(Result.bIntersecting)
				{
					BullOwner.TriggerDamageStartCollisionWithPlayer(collision, AvailableTargets[i], false);
				}
			}
		}
	}
}
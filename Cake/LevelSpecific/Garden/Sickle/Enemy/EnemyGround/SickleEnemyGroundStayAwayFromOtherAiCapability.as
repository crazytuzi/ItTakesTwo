import Cake.LevelSpecific.Garden.Sickle.Player.SickleComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyGround.SickleEnemyGroundComponent;

class USickleEnemyGroundStayAwayFromOtherAiCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SickleEnemyAlive");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 100;

  	ASickleEnemy AiOwner;
	USickleEnemyGroundComponent AiComponent;

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiComponent = USickleEnemyGroundComponent::Get(AiOwner);
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(AiComponent.KeepDistanceToOtherEnemies <= 0)
			return EHazeNetworkActivation::DontActivate;

		if(!AiComponent.IsGrounded())
			return EHazeNetworkActivation::DontActivate;
		
		if(AiOwner.AreaToMoveIn == nullptr)
			return EHazeNetworkActivation::DontActivate;
			
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(AiComponent.KeepDistanceToOtherEnemies <= 0)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!AiComponent.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(AiOwner.AreaToMoveIn == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Handle the getting to close to other enemies
		AiOwner.InitializeMovementForNextFrame();
		const FVector MyLocation = AiOwner.GetActorLocation();

		bool bTheWayForwardIsBlocked = false;
		for(ASickleEnemy OtherEnemy : AiOwner.AreaToMoveIn.SickleEnemiesControlled)
		{
			if(OtherEnemy == nullptr)
				continue;

			if(OtherEnemy == AiOwner)
				continue;
	
			if(OtherEnemy.IsActorDisabled())
				continue;

			auto OtherComp = USickleEnemyGroundComponent::Get(OtherEnemy);
			if(OtherComp == nullptr)
				continue;

			if(OtherComp.KeepDistanceToOtherEnemies <= 0)
				continue;

			if(!OtherComp.IsGrounded())
				continue;

			FVector DirToOther = (OtherEnemy.GetActorLocation() - MyLocation).ConstrainToPlane(AiComponent.WorldUp);
		
			const float TriggerDistance = AiComponent.KeepDistanceToOtherEnemies + OtherComp.KeepDistanceToOtherEnemies;
			const float DistanceToOther = DirToOther.Size();
			if(DistanceToOther > TriggerDistance)
				continue;

			if(DirToOther.IsNearlyZero())
				DirToOther = FRotator(0.f, FMath::RandRange(360.f, 0.f), 0.f).Vector();
			DirToOther.Normalize();

			// If the other one is moving towards us, we step aside
			const float OtherMoveDir = FMath::Max(OtherEnemy.GetActorVelocity().GetSafeNormal().DotProduct(-DirToOther), 0.f);
			if(OtherMoveDir > 0.5f)
			{
				const float RightVectorAlpha = DirToOther.DotProduct(OtherEnemy.GetActorRightVector());
				if(RightVectorAlpha >= 0)
					DirToOther = FMath::Lerp(DirToOther, OtherEnemy.GetActorRightVector(), RightVectorAlpha);
				else
					DirToOther = FMath::Lerp(DirToOther, -OtherEnemy.GetActorRightVector(), FMath::Abs(RightVectorAlpha));
			}

			float InFrontOfAmount = 1.f;
			const FVector CurrentVelocity = AiComponent.GetVelocity();
			if(!CurrentVelocity.IsNearlyZero())
			{
				InFrontOfAmount = FMath::Max(CurrentVelocity.ConstrainToPlane(FVector::ZeroVector).GetSafeNormal().DotProduct(DirToOther), 0.f);
				if(InFrontOfAmount <= 0.3f)
					continue;
			}
			else if(AiOwner.CurrentTarget != nullptr 
				&& OtherEnemy.CurrentTarget != AiOwner.CurrentTarget
				&& Time::GetGameTimeSince(OtherEnemy.LastAttackTime) > 5.f)
			{
				FVector DirToTarget = (AiOwner.CurrentTarget.GetActorCenterLocation() - AiOwner.GetActorCenterLocation()).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
				InFrontOfAmount = DirToOther.DotProduct(DirToTarget);
				if(InFrontOfAmount <= 0.9f)
				{
					continue;
				}
				// Push away the other ai can be bad	
				// else if(InFrontOfAmount <= 0.9f)
				// {
				// 	if(DirToOther.DotProduct(AiOwner.GetActorRightVector()) > 0)
				// 	{
				// 		FVector MoveAwayAmount = AiOwner.GetActorRightVector();
				// 		OtherEnemy.FinalMovement.ApplyDeltaWithCustomVelocity(MoveAwayAmount * DeltaTime * 10.f, FVector::ZeroVector);
				// 	}
				// }
			}

			float PushAwayAlpha = 1.f - (DistanceToOther /TriggerDistance);
			PushAwayAlpha *= InFrontOfAmount;
			PushAwayAlpha = FMath::EaseOut(0.f, 1.f, PushAwayAlpha, 1.5f);
			if(PushAwayAlpha <= KINDA_SMALL_NUMBER)
				continue;
						
			// Something is really in the way so we block the movement
			if(AiOwner.CanMove() && InFrontOfAmount > 0.8f)
				AiOwner.BlockMovement(0.25f);

			FVector MoveAwayAmount = -DirToOther;
			MoveAwayAmount *= AiComponent.KeepDistanceToOtherEnemies;
			MoveAwayAmount *= PushAwayAlpha;
			AiOwner.TotalCollectedMovement.ApplyDeltaWithCustomVelocity(MoveAwayAmount * DeltaTime * 10.f, FVector::ZeroVector);
		}
    }
}
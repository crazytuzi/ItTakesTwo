import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Garden.Sickle.Player.SickleComponent;
import Cake.LevelSpecific.Garden.Sickle.SickleTags;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyGround.SickleEnemyGroundComponent;
import Cake.LevelSpecific.Garden.Sickle.Animation.SickleEnemy_AnimNotifys;

class USickleEnemyGroundSlamCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SickleEnemyAlive");
	default CapabilityTags.Add(n"SickleEnemyAttack");

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;
	
	ASickleEnemy AiOwner;
	USickleEnemyGroundComponent AiComponent;
	USickleCuttableHealthComponent EnemyHealthComp;
	UHazeCrumbComponent CrumbComp;
	float StayActiveTime = 0.f;
	bool bCanTriggerImpact = false;
	float NetworkLagTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiComponent = USickleEnemyGroundComponent::Get(AiOwner);
		EnemyHealthComp = AiOwner.SickleCuttableComp;
		CrumbComp = UHazeCrumbComponent::Get(AiOwner);

		AiOwner.SickleCuttableComp.OnCutWithSickle.AddUFunction(this, n"OnSickleDamageReceived");

		FHazeAnimNotifyDelegate OnTriggerImpact;
		OnTriggerImpact.BindUFunction(this, n"OnTriggerImpact");
		AiOwner.BindAnimNotifyDelegate(UAnimNotify_GardenSickleEnemyTriggerImpact::StaticClass(), OnTriggerImpact);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!AiOwner.CanAttack())
			return EHazeNetworkActivation::DontActivate;

		AHazePlayerCharacter Target = AiOwner.GetCurrentTarget();
		if(Target == nullptr)
			return EHazeNetworkActivation::DontActivate;

		// We add a small safety to the distance
		const float Distance = Target.GetHorizontalDistanceTo(AiOwner) - AiOwner.GetCollisionSize().X - Target.GetCollisionSize().X - 20.f;
		const float AttackDistance = AiComponent.AttackDistance;
		//if(Distance - AiComponent.AttackImpactRadius > AttackDistance)
		if(Distance > AttackDistance)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!EnemyHealthComp.bInvulnerable)
		{
			if(AiOwner.GetIsTakingDamage())
			{
				AiOwner.SetCapabilityActionState(n"AudioStopSlamAttack", EHazeActionState::ActiveForOneFrame);
				if(HasControl())
					return EHazeNetworkDeactivation::DeactivateUsingCrumb;
				else
					return EHazeNetworkDeactivation::DeactivateLocal;
			}

			if(AiOwner.bIsBeeingHitByVine)
			{
				AiOwner.SetCapabilityActionState(n"AudioStopSlamAttack", EHazeActionState::ActiveForOneFrame);
				if(HasControl())
					return EHazeNetworkDeactivation::DeactivateUsingCrumb;
				else
					return EHazeNetworkDeactivation::DeactivateLocal;
			}
		}
		
 		if(StayActiveTime <= 0)
		{
			if(HasControl())
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			else
				return EHazeNetworkDeactivation::DeactivateLocal;
		}
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {	
		SetMutuallyExclusive(n"SickleEnemyAttack", true);
		AiOwner.BlockMovementWithInstigator(this);
		
		NetworkLagTime = 0.f;
		if(HasControl() && Network::IsNetworked())
		{
			NetworkLagTime += CrumbComp.UpdateSettings.OptimalCount * (1.f/60.f);
			NetworkLagTime += Network::GetPingRoundtripSeconds();
			System::SetTimer(this, n"ActivateInternally", NetworkLagTime, false);
		}
		else
		{
			ActivateInternally();
		}

		StayActiveTime = 5.f;
		bCanTriggerImpact = true;

		auto CurrenPlayerTarget = AiOwner.GetCurrentTarget();
		if(CurrenPlayerTarget != nullptr)
		{
			FVector DirToTarget = CurrenPlayerTarget.GetActorLocation() - AiOwner.GetActorLocation();
			DirToTarget.Normalize();
			if(!DirToTarget.IsNearlyZero())
				AiComponent.SetTargetFacingDirection(DirToTarget, 10.f);
		}		
	}

	UFUNCTION(NotBlueprintCallable)
	void ActivateInternally()
	{
		if(IsActive())
		{
			AiOwner.bAttackingPlayer = true;
			AiOwner.LastAttackTime = Time::GetGameTimeSeconds();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(n"SickleEnemyAttack", false);
		AiOwner.UnblockMovementWithInstigator(this);
		AiOwner.BlockAttack(0.2f);
		AiOwner.BlockMovement(0.7f);
		AiOwner.bAttackingPlayer = false;
		StayActiveTime = 0;
	}  

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(AiOwner.bAttackingPlayer)
		{
			// as long as this capability is active, it will keep requesting the attack animation
			StayActiveTime = FMath::Max(StayActiveTime - DeltaTime, 0.f);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnTriggerImpact(AHazeActor Actor, UHazeSkeletalMeshComponentBase MeshComp, UAnimNotify AnimNotify)
	{
		StayActiveTime = 0.f;
		
		if(AiComponent.GroundSlamEffect != nullptr)
			Niagara::SpawnSystemAtLocation(AiComponent.GroundSlamEffect, GetWorldImpactLocation() + (AiOwner.GetMovementWorldUp() * 10));

		ConditionalAddImpactToPlayer(Game::GetMay());
		ConditionalAddImpactToPlayer(Game::GetCody());
	}

	void ConditionalAddImpactToPlayer(AHazePlayerCharacter Player)
	{
		if(!Player.HasControl())
			return;

		const FVector ImpactLocation = GetWorldImpactLocation();
		const FVector WorldUp = AiOwner.GetMovementWorldUp();
		const FVector PlayerLocation = Player.GetActorLocation();
		const float ValidOffsetAmount = AiOwner.GetCollisionSize().Y * 1.5f;

		// No collision if the player is to far away
		if(ImpactLocation.DistSquared2D(PlayerLocation, WorldUp) > FMath::Square(AiComponent.AttackImpactRadius))
			return;

		// No collision of the player is to high up
		FVector VerticalDeltaToPlayer = (PlayerLocation - ImpactLocation).ConstrainToDirection(FVector::UpVector);
		if(VerticalDeltaToPlayer.SizeSquared() > FMath::Square(ValidOffsetAmount))
			return;

		auto HealthSettings = UPlayerHealthSettings::GetSettings(Player);
		const float DamageAmount = float(AiComponent.DamageAmount) / float(HealthSettings.HealthChunks);

		if(Player.IsCody())
		{	
			auto PlantComp = UControllablePlantsComponent::Get(Player);
			auto TurretPlant = Cast<ATurretPlant>(PlantComp.CurrentPlant);
		 	if(TurretPlant != nullptr)
		 	{
				FCapabilityNotificationSendParams Params;
				Params.AddVector(n"EffectLocation", TurretPlant.GetActorLocation());
				Params.AddObject(n"ImpactEffect", TurretPlant.AttackedByGardenEnemyEffect);
				TriggerNotification(n"SpawnCactusEffect", Params);

				// Before we die, we force the player out of the plant
				if(TurretPlant.CanExitPlant() && AiOwner.SetupPendingExitTurretPlantDamage(Player, DamageAmount))
				{
					PlantComp.OnExitSoilComplete.AddUFunction(this, n"ApplyPendingExitTurretPlantDamage");
					PlantComp.CurrentPlant.ExitPlant();
					return;
				}
		 	}
		}

		Player.DamagePlayerHealth(DamageAmount, AiComponent.DamageEffect, AiComponent.DeathEffect);
	}

	UFUNCTION(NotBlueprintCallable)
	void ApplyPendingExitTurretPlantDamage()
	{
		float DamageAmount = 0;
		if(AiOwner.ConsumeExitTurretPlantDamage(DamageAmount))
		{
			Game::GetCody().DamagePlayerHealth(DamageAmount, AiComponent.DamageEffect, AiComponent.DeathEffect);
		}
	}

	UFUNCTION(BlueprintOverride)
	void NotificationReceived(FName Notification, FCapabilityNotificationReceiveParams NotificationParams)
	{
		if(Notification == n"SpawnCactusEffect")
		{
			auto Player = Game::GetCody();
			if(Player != nullptr)
			{
				FVector SpawnLocation = NotificationParams.GetVector(n"EffectLocation");
				UNiagaraSystem AttackedByGardenEnemyEffect = Cast<UNiagaraSystem>(NotificationParams.GetObject(n"ImpactEffect"));
				if(AttackedByGardenEnemyEffect != nullptr)
					Niagara::SpawnSystemAtLocation(AttackedByGardenEnemyEffect, SpawnLocation);
			}		
		}
	}

	FVector GetWorldImpactLocation() const
	{
		return AiOwner.GetActorLocation() + AiOwner.GetActorQuat().RotateVector(AiComponent.ImpactOffset);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnSickleDamageReceived(int DamageAmount)
	{
		if(DamageAmount == 0)
		{						
			AiOwner.BlockAttack(1.f);
			if(IsActive())
			{
				// This will force the deactivation
				StayActiveTime = 0;
			}
		}
	}
}
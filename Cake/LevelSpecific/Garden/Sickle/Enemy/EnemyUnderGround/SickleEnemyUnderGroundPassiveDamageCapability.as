import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyUnderGround.SickleEnemyUnderGroundComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemyPickTargetCapability;


struct FSickleEnemyUnderGroundPassiveDamagePlayerData
{
	EHazePlayer PlayerName;
	float ReleaseInputCooldownTime = 0;
	FVector CurrentActorLocation;
}

class USickleEnemyUnderGroundPassiveDamageCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	UPROPERTY()
	FHazePlaySlotAnimationParams CodyTakeDamageAnimation;

	UPROPERTY()
	FHazePlaySlotAnimationParams MayTakeDamageAnimation;

	const int Damage = 4;
	const float Radius = 300.f;
	const float ImpactLifeTime = 1.4f;
	
	ASickleEnemy AiOwner;
	USickleEnemyUnderGroundComponent AiComponent;
	UCapsuleComponent PlayerCollision;
	USickleCuttableHealthComponent Health;

	FVector LastDroppedLocation;
	
	TArray<FSickleEnemyUnderGroundPassiveDamagePlayerData> PlayerInfos;
	float DropDamageDelay = 0;
	bool bCanApplyDamage = true;
	bool bIgoreDistanceWhenDropping = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiComponent = USickleEnemyUnderGroundComponent::Get(Owner);
		Health = USickleCuttableHealthComponent::Get(Owner);
		TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
		for(auto Player : Players)
		{
			FSickleEnemyUnderGroundPassiveDamagePlayerData NewPlayerData;
			NewPlayerData.PlayerName = Player.Player;
			PlayerInfos.Add(NewPlayerData);
		}

		PlayerCollision = UCapsuleComponent::Get(AiOwner, n"PlayerCollision");
		ensure(PlayerCollision != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		LastDroppedLocation = Owner.GetActorLocation();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AiComponent.PassiveGroundDamageLocations.Reset();
		for(int i = 0; i < PlayerInfos.Num(); ++i)
		{
			FSickleEnemyUnderGroundPassiveDamagePlayerData& PlayerInfo = PlayerInfos[i];
			if(PlayerInfo.ReleaseInputCooldownTime > 0)
			{
				PlayerInfo.ReleaseInputCooldownTime = 0;
				auto Player = Game::GetPlayer(PlayerInfo.PlayerName);
				if(Player != nullptr)
				{
					Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
					Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(AiOwner.bIsBeeingHitByVine)
		{
			DropDamageDelay = 0.3f;
			LastDroppedLocation = Owner.GetActorLocation();
		}
		else if(!AiComponent.IsShowingBody())
		{
			if(DropDamageDelay > 0)
			{
				DropDamageDelay -= DeltaTime;
				if(DropDamageDelay <= 0 
					|| LastDroppedLocation.DistSquared(Owner.GetActorLocation()) > FMath::Square(Radius * 2.f))
				{
					DropDamageDelay = 0.f;
				}
			}
		}

		if(bCanApplyDamage)
			bCanApplyDamage = Health.Health > 0;

							
		auto VineImpactComp = UVineImpactComponent::Get(AiOwner);
		const bool bIsLockedByVine = VineImpactComp != nullptr && VineImpactComp.bVineAttached;
	
		if(bCanApplyDamage && DropDamageDelay <= 0)
		{
			if(LastDroppedLocation.DistSquared(Owner.GetActorLocation()) > FMath::Square(Radius * 0.5f))
			{
				FSickleEnemyUnderGroundPassiveDamageData NewData;
				NewData.ImpactLocation = Owner.GetActorLocation();
				NewData.StartRadius = Radius;
				NewData.Radius = NewData.StartRadius;
				NewData.StartLifeTime = ImpactLifeTime;
				NewData.LifeTimeLeft = NewData.StartLifeTime;
				AiComponent.PassiveGroundDamageLocations.Add(NewData);
				LastDroppedLocation = Owner.GetActorLocation();
			}
		}

		TArray<int> ValidPlayer;
		for(int i = 0; i < PlayerInfos.Num(); ++i)
		{	
			FSickleEnemyUnderGroundPassiveDamagePlayerData& PlayerInfo = PlayerInfos[i];
			auto Player = Game::GetPlayer(PlayerInfo.PlayerName);
			if(!Player.HasControl())
				continue;

			if(PlayerInfo.ReleaseInputCooldownTime > 0)
			{
				PlayerInfo.ReleaseInputCooldownTime -= DeltaTime;
				if(PlayerInfo.ReleaseInputCooldownTime <= 0)
				{
					Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
					Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
					PlayerInfo.ReleaseInputCooldownTime = 0;
				}
			}

			if(!Player.CanPlayerBeDamaged())
				continue;
			
			if(UHazeMovementComponent::Get(Player).IsAirborne())
				continue;

			// if(Player.IsMay())
			// {
			// 	if(AiOwner.bIsBeeingHitBySickle)
			// 	{
			// 		Player.AddPlayerInvulnerabilityDuration(1.f);
			// 		continue;
			// 	}
			// }

			if(bIsLockedByVine)
				continue;

			PlayerInfo.CurrentActorLocation = Player.GetActorLocation();
			ValidPlayer.Add(i);
		}

		if(bCanApplyDamage)
		{
			for(int i = AiComponent.PassiveGroundDamageLocations.Num() - 1; i >= 0; --i)
			{
				FSickleEnemyUnderGroundPassiveDamageData& ImpactData = AiComponent.PassiveGroundDamageLocations[i];
				
				//System::DrawDebugSphere(ImpactData.ImpactLocation, ImpactData.Radius);

				for(int ii = ValidPlayer.Num() - 1; ii >= 0; --ii)
				{
					FSickleEnemyUnderGroundPassiveDamagePlayerData& PlayerInfo = PlayerInfos[ValidPlayer[ii]];

					auto Player = Game::GetPlayer(PlayerInfo.PlayerName);

					// if(Player.IsMay())
					// {
					// 	System::DrawDebugArrow(Player.GetActorCenterLocation(), ImpactData.ImpactLocation, Thickness = 10);
					// 	System::DrawDebugSphere(ImpactData.ImpactLocation, ImpactData.Radius, 6);
					// }
				
					if(PlayerInfo.CurrentActorLocation.DistSquared(ImpactData.ImpactLocation) < FMath::Square(ImpactData.Radius))
					{	
						if(PlayerInfo.ReleaseInputCooldownTime <= 0)
						{
							Player.BlockCapabilities(CapabilityTags::MovementInput, this);
							Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
						}
						
						if(Player.IsCody())
							PlayerInfo.ReleaseInputCooldownTime = FMath::Max(CodyTakeDamageAnimation.GetPlayLength() - 0.1f, KINDA_SMALL_NUMBER);
						else
							PlayerInfo.ReleaseInputCooldownTime = FMath::Max(MayTakeDamageAnimation.GetPlayLength() - 0.1f, KINDA_SMALL_NUMBER);

						FHazeDelegateCrumbParams Params;
						Params.AddObject(n"Player", Player);
						UHazeCrumbComponent::Get(Player).LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_AddPassiveDamage"), Params);
						
						ValidPlayer.RemoveAtSwap(ii); // this player is no longer valid
					}
				}
				
				ImpactData.LifeTimeLeft -= DeltaTime;
				if(ImpactData.LifeTimeLeft <= 0)
				{
					AiComponent.PassiveGroundDamageLocations.RemoveAtSwap(i);
				}
				else
				{
					ImpactData.Radius = FMath::Lerp(ImpactData.StartRadius * 0.1f, ImpactData.StartRadius, ImpactData.LifeTimeLeft / ImpactData.StartLifeTime);
				}
			}

			if(AiComponent.IsShowingBody())
			{
				auto Players = Game::GetPlayers();
				for(auto Player : Players)
				{
					if(!Player.HasControl())
						continue;

					if(!Trace::ComponentOverlapComponent(
						Player.CapsuleComponent,
						PlayerCollision,
						PlayerCollision.WorldLocation, 
						PlayerCollision.WorldRotation.Quaternion()))
						continue;

					FVector ImpactForce = (Player.GetActorLocation() - AiOwner.GetActorLocation()).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
					if(ImpactForce.IsNearlyZero())
						ImpactForce = -Player.GetActorForwardVector();

					if(!Player.IsMay() || !AiOwner.bIsBeeingHitBySickle)
					{
						if(bIsLockedByVine)
						{
							ImpactForce *= (Player.GetActorLocation() - AiOwner.GetActorLocation()).ConstrainToPlane(FVector::UpVector);
							ImpactForce.Z = 50.f;
						}
						else
						{
							ImpactForce *= 1000.f;
							ImpactForce.Z = 100.f;
						}
						
						Player.AddImpulse(ImpactForce, n"BurrowerBodyImpact");
					}

					if(!bIsLockedByVine && Player.CanPlayerBeDamaged())
					{
						FHazeDelegateCrumbParams Params;
						Params.AddObject(n"Player", Player);
						UHazeCrumbComponent::Get(Player).LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_AddPassiveDamage"), Params);	
					}
				}
			}
		}		
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_AddPassiveDamage(const FHazeDelegateCrumbData& CrumbData)
	{
		auto Player = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"Player"));

		auto HealthSettings = UPlayerHealthSettings::GetSettings(Player);
		const float DamageAmount = float(Damage) / float(HealthSettings.HealthChunks);
		Player.DamagePlayerHealth(DamageAmount, AiComponent.DamageEffect, AiComponent.DeathEffect);

		if(!CrumbData.IsStale())
		{
			if(Player.IsCody())
				Player.PlaySlotAnimation(CodyTakeDamageAnimation);
			else
				Player.PlaySlotAnimation(MayTakeDamageAnimation);
		}
	}
}

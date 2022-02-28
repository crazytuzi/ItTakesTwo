import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemyComponent;

class USickleEnemyPickTargetCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SickleEnemyAlive");
	default CapabilityTags.Add(n"PickTarget");

	ASickleEnemy AiOwner;
	USickleEnemyComponentBase AiBaseComponent;
	AHazePlayerCharacter LastTarget = nullptr;

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	float CooldownTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiBaseComponent = USickleEnemyComponentBase::Get(AiOwner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(HasControl())
		{
			if(AiOwner.GetCurrentTarget() == nullptr)
			{
				CooldownTime = 0.f;
			}
			else
			{
				CooldownTime = FMath::Max(CooldownTime - DeltaTime, 0.f);

				// System::DrawDebugArrow(
				// 	AiOwner.GetActorCenterLocation(), 
				// 	AiOwner.CurrentTarget.GetActorCenterLocation(), 
				// 	30, 
				// 	FLinearColor::Teal,
				// 	0, 
				// 	20);
			}
		}	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(AiOwner.AreaToMoveIn == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(CooldownTime > 0)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(AiOwner.AreaToMoveIn == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		if(CooldownTime > 0)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(!HasControl())
		{
			LastTarget = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		float RandomValue = 0;
		if(AiOwner.AreaToMoveIn.PlayersTriggeredCombat.Num() >= 2)
			RandomValue = AiOwner.RandRange(0.f, 100.f);
			
		CooldownTime = 1.f;
		AHazePlayerCharacter WantedTarget = PickBestTarget();
		
		if(AiOwner.CurrentTarget == nullptr)
		{
			// Always get a target if we don't have one
			AiOwner.SetPlayerAsTarget(WantedTarget);	
		}
		else if(WantedTarget != AiOwner.CurrentTarget)
		{
			// There is a chance to not change the target even if we want to
			if(RandomValue > 20.f)
			{
				AiOwner.SetPlayerAsTarget(WantedTarget);
				NetSetCooldown(2.5f);
			}		
		}
		else if(WantedTarget != nullptr && LastTarget == WantedTarget)
		{
			// There is chance to not change the target even if we don't want to
			AHazePlayerCharacter OtherTarget = WantedTarget.GetOtherPlayer();
			if(RandomValue < 5 && Time::GetGameTimeSince(AiOwner.LastAttackTime) > 20.f)
			{
				auto AvailablePlayers = AiOwner.AreaToMoveIn.PlayersTriggeredCombat;
				if(AvailablePlayers.Contains(OtherTarget))
				{
					float DistanceMultiplier = 1.f;
					if (AiOwner.CanBeTargeted(OtherTarget, DistanceMultiplier))
					{
						if(Math::GetDirectionNormalized(AiOwner, WantedTarget).DotProduct(Math::GetDirectionNormalized(AiOwner, OtherTarget)) < 0.f)
						{
							AiOwner.SetPlayerAsTarget(OtherTarget);
							NetSetCooldown(5.f);
						}
					}
				}		
			}	
			else if(Time::GetGameTimeSince(AiOwner.LastAttackTime) > 5.f
				&& AiBaseComponent.GetVelocity().Size() < 10.f)
			{
				RandomValue = FMath::RandRange(0, 10);
				if(RandomValue < 5)
				{
					//System::DrawDebugSphere(AiOwner.GetActorCenterLocation(), 200.f, LineColor = FLinearColor::Red, Duration = 2.f);
					auto AvailablePlayers = AiOwner.AreaToMoveIn.PlayersTriggeredCombat;
					if(AvailablePlayers.Contains(OtherTarget))
					{
						float DistanceMultiplier = 1.f;
						if (AiOwner.CanBeTargeted(OtherTarget, DistanceMultiplier))
						{
							AiOwner.SetPlayerAsTarget(OtherTarget);
							NetSetCooldown(5.f);
						}
					}
				}
				else
				{
					//System::DrawDebugSphere(AiOwner.GetActorCenterLocation(), 200.f, LineColor = FLinearColor::Blue, Duration = 2.f);
					NetSetCooldown(2.f);
				}
			}
		}

		LastTarget = WantedTarget;

		if(AiOwner.GetCurrentTarget() == nullptr)
			AiOwner.SetFreeTargeting();
	}

	AHazePlayerCharacter PickBestTarget() const
	{
		ASickleEnemyMovementArea AreaToMoveIn = AiOwner.AreaToMoveIn;
		if(AreaToMoveIn == nullptr)
			return nullptr;

		auto AvailablePlayers = AreaToMoveIn.PlayersTriggeredCombat;
		if(AvailablePlayers.Num() == 0)
			return nullptr;

		const FVector MyLocation = AiOwner.GetActorLocation();
		float CodyDistAlpha = -1;
		float MayDistAlpha = -1;
	
		for(auto Player : AvailablePlayers)
		{
			if(Player == nullptr)
				continue;

			float Multiplier = 1.f;
			if (!AiOwner.CanBeTargeted(Player, Multiplier))
				continue;

			if(Player.IsCody())
			{
				const float CodyDist = Player.GetHorizontalDistanceTo(AiOwner) * Multiplier;
				CodyDistAlpha = CodyDist / AiBaseComponent.DetectCodyDistance;
			}
			else
			{
				const float MayDist = Player.GetHorizontalDistanceTo(AiOwner) * Multiplier;
				MayDistAlpha = MayDist / AiBaseComponent.DetectMayDistance;
			}
		}

		// Both players can be detected
		if(CodyDistAlpha >= 0 && MayDistAlpha >= 0)
		{
			return MayDistAlpha <= CodyDistAlpha ? Game::GetMay() : Game::GetCody();
		}
		else if(CodyDistAlpha >= 0)
		{
			return Game::GetCody();
		}
		else if(MayDistAlpha >= 0)
		{
			return Game::GetMay();
		}
		else
		{
			return nullptr;
		}	
	}

	UFUNCTION(NetFunction)
	void NetSetCooldown(float NewCooldown)
	{
		CooldownTime = NewCooldown;
	}
}
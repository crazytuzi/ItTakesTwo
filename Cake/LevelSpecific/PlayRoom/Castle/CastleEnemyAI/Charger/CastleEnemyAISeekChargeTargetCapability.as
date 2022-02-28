import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAI.Charger.CastleEnemyChargerComponent;
import Rice.Math.MathStatics;
import Rice.TemporalLog.TemporalLogStatics;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleChargableComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemyCharger;

class UCastleEnemyAISeekChargeTargetCapability : UHazeCapability
{
    default CapabilityDebugCategory = n"Castle";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 51;

    default CapabilityTags.Add(n"CastleEnemyAI");
    default CapabilityTags.Add(n"CastleEnemyCharge");
    default CapabilityTags.Add(n"CastleEnemyChargeSeek");

	ACastleEnemyCharger Charger;
	UCastleEnemyChargerComponent ChargerComp;

	AHazeActor ForcedChargeTarget;
	AHazeActor WantedChargeTarget;

	bool bNaturalTargetSelection = false;
	AHazePlayerCharacter PreviouslyChargedPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Charger = Cast<ACastleEnemyCharger>(Owner);
		ChargerComp = UCastleEnemyChargerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (HasControl() && !IsBlocked())
		{
			if (ChargerComp.ChargeTarget == nullptr)
			{
				UObject PotentialForcedTarget;
				if (ConsumeAttribute(n"ForceChargeTarget", PotentialForcedTarget))
				{
					AHazeActor HazeActor = Cast<AHazeActor>(PotentialForcedTarget);
					if (HazeActor != nullptr)
					{
						WantedChargeTarget = HazeActor;
						bNaturalTargetSelection = true;
					}
				}

				if (WantedChargeTarget == nullptr && bNaturalTargetSelection)
				{
					WantedChargeTarget = GetValidChargeTarget();
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WantedChargeTarget == nullptr)
			return EHazeNetworkActivation::DontActivate;
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"ChargeTarget", WantedChargeTarget);
		WantedChargeTarget = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ChargerComp.ChargeTarget = Cast<AHazeActor>(ActivationParams.GetObject(n"ChargeTarget"));
		ChargerComp.bHasTelegraphed = false;	

		auto ChargePlayer = Cast<AHazePlayerCharacter>(ChargerComp.ChargeTarget);
		if (ChargePlayer != nullptr)
			PreviouslyChargedPlayer = ChargePlayer;
	}

	bool IsValidChargeTarget(AHazePlayerCharacter Player)
	{
		float Distance = (Player.ActorLocation - Owner.ActorLocation).Size();
		if (Player.IsPlayerDead())
			return false;
		return true;
	}

	private TPerPlayer<float> PlayerPriority;
	private TArray<AActor> OverlapActors;
	AHazePlayerCharacter GetValidChargeTarget()
    {
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!IsValidChargeTarget(Player))
			{
				PlayerPriority[Player] = -1.f;
				continue;
			}

			float Priority = 1.f;
			bool bUnhitChargeables = false;
			for (auto Chargeable : Charger.Chargeables)
			{
				auto ChargeComp = Cast<UCastleChargableComponent>(Chargeable);
				if (ChargeComp == nullptr)
					continue;
				if (ChargeComp.bWasHit)
					continue;

				bUnhitChargeables = true;

				float Distance = Player.ActorLocation.Distance(ChargeComp.Owner.ActorLocation);
				if (Distance < Charger.NearbyChargeablePriorityRange)
					Priority = FMath::Max(Priority, 3.f);
			}

			if (!bUnhitChargeables)
			{
				OverlapActors.Reset();
				Player.GetOverlappingActors(OverlapActors);

				for (auto Overlap : OverlapActors)
				{
					if (Cast<ACastleChargerLowPriorityVolume>(Overlap) != nullptr)
					{
						Priority = FMath::Min(Priority, 0.5f);
					}
				}
			}

			PlayerPriority[Player] = Priority;
		}

		// If one player has higher priority than the other, choose that one
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (PlayerPriority[Player] < 0.f)
				continue;
			if (PlayerPriority[Player] > PlayerPriority[Player.OtherPlayer])
				return Player;
		}

		// Alternate players if both have the same priority
		if (PreviouslyChargedPlayer != nullptr)
		{
			if (IsValidChargeTarget(PreviouslyChargedPlayer.OtherPlayer))
				return PreviouslyChargedPlayer.OtherPlayer;
			else if (IsValidChargeTarget(PreviouslyChargedPlayer))
				return PreviouslyChargedPlayer;
		}

		// Pick a random player if we can't alternate
		AHazePlayerCharacter RandomPlayer = Game::Players[FMath::RandRange(0, 1)];
		if (IsValidChargeTarget(RandomPlayer))
			return RandomPlayer;
		else if (IsValidChargeTarget(RandomPlayer.OtherPlayer))
			return RandomPlayer.OtherPlayer;
		else
			return nullptr;
    }
}

UFUNCTION()
void ForceChargerTarget(ACastleEnemy Charger, AHazeActor Target)
{
	Charger.SetCapabilityAttributeObject(n"ForceChargeTarget", Target);
}
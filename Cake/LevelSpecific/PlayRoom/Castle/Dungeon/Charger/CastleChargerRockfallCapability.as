import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAI.Charger.CastleEnemyChargerComponent;
import Rice.Math.MathStatics;
import Rice.TemporalLog.TemporalLogStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleChargableComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;

class UCastleChargerRockfallCapability : UHazeCapability
{
    default CapabilityDebugCategory = n"Castle";
	default TickGroup = ECapabilityTickGroups::GamePlay;

	ACastleEnemy Charger;
	UCastleEnemyChargerComponent ChargerComp;

	const float RockfallRadius = 500.f;
	FCastleChargerRockfalls ChargerRockfalls;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Charger = Cast<ACastleEnemy>(Owner);
		ChargerComp = UCastleEnemyChargerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!ChargerComp.bShouldTriggerRockfall)
			return EHazeNetworkActivation::DontActivate;

		if (ChargerComp.CenterOfArena == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (ChargerComp.bDead)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ChargerRockfalls.RockfallLocations.Num() <= 0)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (ChargerComp.bDead)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ChargerRockfalls.RockfallLocations = GetRockFallLocationsRandom(1, 3, RockfallRadius, RockfallRadius / 3.f);
		ChargerRockfalls.RockfallLocations.Append(GetRockFallLocationsRandom(1, 5, RockfallRadius, RockfallRadius * 1.25f));
		ChargerRockfalls.RockfallLocations.Append(GetRockFallLocationsRandom(3, 10, RockfallRadius, RockfallRadius * 2.2f));		

		//RockfallLocations.Locations = GetRockFallLocationsCircle(10, RockfallRadius);

		StaggerLocationSpawns(ChargerRockfalls);

		ActivationParams.AddStruct(n"RockfallLocations", ChargerRockfalls);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ChargerComp.bShouldTriggerRockfall = false;
		ActivationParams.GetStruct(n"RockfallLocations", ChargerRockfalls);

		UHazeAkComponent::HazePostEventFireForget(ChargerComp.RoofRumbleEvent, Charger.RootComponent.GetWorldTransform());

		// for (FCastleChargerRockfallLocation RockfallLocation : ChargerRockfalls.RockfallLocations)
		// {
		// 	System::DrawDebugCircle(RockfallLocation.Location, RockfallRadius, 30, FLinearColor::Red, ChargerSettings::RockfallTelegraphTime, 5.f, FVector::RightVector, FVector::ForwardVector, false);
		// }	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// for (AHazePlayerCharacter Player : Game::GetPlayers())
		// {
		// 	if (!Player.HasControl())
		// 		continue;
		// 	if (!Player.CanPlayerBeDamaged())
		// 		continue;

		// 	for (FCastleChargerRockfallLocation RockfallLocation : ChargerRockfalls.RockfallLocations)
		// 	{
		// 		FVector ToPlayer = Player.ActorLocation - RockfallLocation.Location;
		// 		float Distance = ToPlayer.Size();

		// 		if (Distance > RockfallRadius)
		// 			continue;

		// 		FCastlePlayerDamageEvent Damage;
		// 		Damage.DamageDealt = 50.f;
		// 		Damage.DamageDirection = ToPlayer;
		// 		Damage.DamageSource = Owner;
		// 		Damage.DamageLocation = Player.ActorLocation;
		// 		Damage.DamageSpeed = 500.f;
		// 		Player.DamageCastlePlayer(Damage);
		// 	}

		// 	// if (Player.IsAnyCapabilityActive(n"KnockDown"))
		// 	// 	continue;

		// 	// FVector KnockDirection;
		// 	// if (!CalculateChargeKnock(Player, KnockDirection))
		// 	// 	continue;

		// 	// float KnockForce = 600.f;
		// 	// FVector KnockImpulse = KnockDirection * KnockForce + FVector(0.f, 0.f, 2000.f);
		// 	// Player.KnockdownActor(KnockImpulse);
		// 	// Player.DamagePlayerHealth(Charger.ChargePlayerDamage, Charger.ChargePlayerDamageEffect);

		// 	// if (Charger.ChargePlayerDamageForceFeedback != nullptr)
		// 	// 	Player.PlayForceFeedback(Charger.ChargePlayerDamageForceFeedback, false, false, n"Damage");

		// 	// HitDuringThisCharge.Add(Player);
		// }

		for (auto& Rockfall : ChargerRockfalls.RockfallLocations)
		{
			if (Rockfall.Rockfall != nullptr)
				Rockfall.Rockfall.DestroyActor();
		}

		ChargerRockfalls.RockfallLocations.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		for (int Index = ChargerRockfalls.RockfallLocations.Num() - 1; Index >= 0; Index--)
		{
			ChargerRockfalls.RockfallLocations[Index].CurrentDuration += DeltaTime;

			if (ChargerRockfalls.RockfallLocations[Index].CurrentDuration >= 0.f && ChargerRockfalls.RockfallLocations[Index].CurrentDuration <= ChargerSettings::RockfallTelegraphTime)
			{
				// Spawn the rockfall
				if (ChargerRockfalls.RockfallLocations[Index].Rockfall == nullptr)
				{
					if (ChargerComp.RockfallType.IsValid())
					{
						FVector Location = ChargerRockfalls.RockfallLocations[Index].Location;
						ChargerRockfalls.RockfallLocations[Index].Rockfall = Cast<ACastleChargerRockfall>(SpawnActor(ChargerComp.RockfallType, Location));
					}
				}
				else
				{
					const float Progress = FMath::Clamp(ChargerRockfalls.RockfallLocations[Index].CurrentDuration / ChargerSettings::RockfallTelegraphTime, 0.f, 1.f);
					ACastleChargerRockfall Rockfall = ChargerRockfalls.RockfallLocations[Index].Rockfall;
					Rockfall.UpdateDecal(Progress);
				}

			}
			else if (ChargerRockfalls.RockfallLocations[Index].CurrentDuration > ChargerSettings::RockfallTelegraphTime)
			{
				for (AHazePlayerCharacter Player : Game::GetPlayers())
				{
					if (!Player.HasControl())
						continue;
					if (!Player.CanPlayerBeDamaged())
						continue;

					FVector ToPlayer = Player.ActorLocation - ChargerRockfalls.RockfallLocations[Index].Location;
					float Distance = ToPlayer.Size();

					if (Distance > RockfallRadius)
						continue;

					FCastlePlayerDamageEvent Damage;
					Damage.DamageDealt = 40.f;
					Damage.DamageDirection = ToPlayer;
					Damage.DamageSource = Owner;
					Damage.DamageLocation = Player.ActorLocation;
					Damage.DamageSpeed = 500.f;
					Player.DamageCastlePlayer(Damage);
				}

				Niagara::SpawnSystemAtLocation(ChargerComp.RockfallImpact, ChargerRockfalls.RockfallLocations[Index].Location);
				FTransform LocationTransform = FTransform(ChargerRockfalls.RockfallLocations[Index].Location);
				UHazeAkComponent::HazePostEventFireForget(ChargerComp.RockFallImpactEvent, LocationTransform);
				
				ChargerRockfalls.RockfallLocations[Index].Rockfall.DestroyActor();
				ChargerRockfalls.RockfallLocations.RemoveAt(Index);
			}
		}
	}

	TArray<FCastleChargerRockfallLocation> GetRockFallLocationsRandom(int Amount, int Segments, float Radius, float DistanceFromMiddle, FLinearColor Colour = FLinearColor::Red)
	{
		TArray<FCastleChargerRockfallLocation> RockfallLocations;

		if (Amount == 0)
			return RockfallLocations;

		float SegmentSize = 360 / Segments;
		for (int Index = 0; Index < Segments; Index++)
		{
			FVector Location = FRotator(0.f, SegmentSize * Index, 0.f).ForwardVector * DistanceFromMiddle;
			Location += ChargerComp.CenterOfArena.ActorLocation + FVector(0.f, 0.f, 10.f);

			FCastleChargerRockfallLocation RockfallLocation = FCastleChargerRockfallLocation(Location);
			RockfallLocations.Add(RockfallLocation);
		}

		if (Amount >= Segments)
			return RockfallLocations;

		int AmountToRemove = Segments - Amount;
		for (int Index = 0; Index < AmountToRemove; Index++)
		{
			RockfallLocations.Shuffle();
			RockfallLocations.RemoveAt(RockfallLocations.Num() - 1);
		}
		
		return RockfallLocations;
	}

	TArray<FVector> GetRockFallLocationsCircle(int Segments, float Radius, FLinearColor Colour = FLinearColor::Red)
	{
		const float SegmentSize = 360.f / Segments;
		const float MinDistance = 200.f;
		const float MaxDistance = 1320.f;

		TArray<FVector> Locations;

		for (int Index = 0; Index < Segments; Index++)
		{
			float DistanceFromMiddle = FMath::Lerp(MinDistance, MaxDistance, FMath::RandRange(0.f, 1.f));

			FVector Location = FRotator(0.f, SegmentSize * Index, 0.f).ForwardVector * DistanceFromMiddle;
			Location += ChargerComp.CenterOfArena.ActorLocation + FVector(0.f, 0.f, 10.f);
			Locations.Add(Location);
		}

		return Locations;
	}

	void StaggerLocationSpawns(FCastleChargerRockfalls& ChargerRockfalls, float StaggerAmount = 0.15f)
	{
		ChargerRockfalls.RockfallLocations.Shuffle();

		for (int Index = 0; Index < ChargerRockfalls.RockfallLocations.Num(); Index++)
		{
			ChargerRockfalls.RockfallLocations[Index].CurrentDuration = -StaggerAmount * Index;
		}
	}
}

struct FCastleChargerRockfalls
{
	TArray<FCastleChargerRockfallLocation> RockfallLocations;
}

struct FCastleChargerRockfallLocation
{
	ACastleChargerRockfall Rockfall;
	FVector Location;
	float CurrentDuration = 0.f;

	FCastleChargerRockfallLocation(FVector InLocation)
	{
		Location = InLocation;
	}
}
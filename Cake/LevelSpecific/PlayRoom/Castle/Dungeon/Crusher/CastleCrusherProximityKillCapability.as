import Cake.LevelSpecific.PlayRoom.Castle.Dungeon.Crusher.CastleCrusher;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Cake.LevelSpecific.PlayRoom.Castle.Dungeon.Crusher.CastleEnemyBreakableWall;
import Cake.LevelSpecific.PlayRoom.Castle.CastleLevelScripts.CastleSpinningBlade;

class UCastleCrusherProximityKillCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Castle");
	default CapabilityTags.Add(n"Crusher");
	default CapabilityTags.Add(n"Damage");

	default CapabilityDebugCategory = n"Castle";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	ACastleCrusher Crusher;
	UHazeMovementComponent MoveComp;

	const float SmashCooldown = 0.2f;
	float SmashCooldownCurrent = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Crusher = Cast<ACastleCrusher>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Crusher.bEnabled)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Crusher.bEnabled)
        	return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FTransform BoxTransform;
		FVector BoxExtent;
		GetKillBoxData(BoxTransform, BoxExtent);

		FVector StartLocation = Crusher.ActorLocation + (-Crusher.ActorForwardVector * 5000.f);
		StartLocation.Z = Crusher.ActorLocation.Z;
		FVector EndLocation = Crusher.Mesh.GetSocketLocation(n"Roller") + (Crusher.ActorForwardVector * 120.f);
		EndLocation.Z = Crusher.ActorLocation.Z;

		TArray<AHazeActor> HitActors = GetActorsInBox(StartLocation, EndLocation, 1400.f);


		int Hits = 0;
		for (AHazeActor HitActor : HitActors)
		{
			ACastleSpinningBlade SpinningBlade = Cast<ACastleSpinningBlade>(HitActor);
			if (SpinningBlade != nullptr)
			{
				FBreakableHitData BreakData;
				BreakData.HitLocation = SpinningBlade.ActorLocation;
				BreakData.DirectionalForce = Owner.ActorForwardVector;
				BreakData.NumberOfHits = 4;
				SpinningBlade.BreakableComponent.Break(BreakData);
				
				Hits++;
				continue;
			}

			ACastleEnemy CastleEnemy = Cast<ACastleEnemy>(HitActor);
			if (CastleEnemy != nullptr)
			{
				CastleEnemy.Kill(OverrideKillDirection = Owner.ActorForwardVector);

				Hits++;
				continue;
			}
		}

		TArray<AHazePlayerCharacter> HitPlayers = GetPlayersInBox(BoxTransform, BoxExtent);
		for (AHazePlayerCharacter Player : HitPlayers)
		{
			KillPlayer(Player);

			Hits++;
			continue;			
		}
		SmashCooldownCurrent -= DeltaTime;

		
		// if (Hits > 0 && Crusher.Mesh.CanRequestLocomotion())
		// 	NetRequestSmash();
	

		if (HasControl() &&
				SmashCooldownCurrent <= 0.f &&
				Hits > 0)
			{
				SmashCooldownCurrent = SmashCooldown;
				NetRequestSmash();
			}
	}

	UFUNCTION(NetFunction)
	void NetRequestSmash()
	{
		RequestSmash();
	}

	void RequestSmash()
	{
		if (Crusher.Mesh.CanRequestLocomotion())
		{
			FHazeRequestLocomotionData Request;
			Request.AnimationTag = n"CastleEnemyCrusher";
			Request.SubAnimationTag = n"Smash";
			Crusher.Mesh.RequestLocomotion(Request);
		}
	}

	void GetKillBoxData(FTransform& BoxTransform, FVector& BoxExtent, bool bShowDebug = false)
	{
		FVector StartLocation = Crusher.ActorLocation + (-Crusher.ActorForwardVector * 5000.f);
		StartLocation.Z = Crusher.ActorLocation.Z;

		FVector EndLocation = Crusher.Mesh.GetSocketLocation(n"Roller") + (Crusher.ActorForwardVector * 120.f);
		EndLocation.Z = Crusher.ActorLocation.Z;
		
		FVector TraceLocation;
		TraceLocation = (StartLocation + EndLocation) / 2;

		float HalfLength = (StartLocation - EndLocation).Size() * .5f;
		float HalfWidth = 1400.f * .5f;
		float HalfHeight = 500.f;

		FVector Direction = EndLocation - StartLocation;
		Direction.Normalize();
		FRotator Rotation = Math::MakeRotFromX(Direction);

		BoxTransform = FTransform(Rotation, TraceLocation);
		BoxExtent = FVector(HalfLength, HalfWidth, HalfHeight);

	#if EDITOR
		if (bShowDebug)
		{
			System::DrawDebugBox(TraceLocation, BoxExtent, FLinearColor::White, Rotation, Duration = 0.f);
		}
	#endif
	}

	TArray<ACastleEnemy> GetCastleEnemiesInBox(FTransform BoxTransform, FVector BoxExtent)
	{
		TArray<ACastleEnemy> ValidWalls;

		for (ACastleEnemy CastleEnemy : GetAllCastleEnemies())
		{
			if (CastleEnemy == nullptr)
				continue;

			UShapeComponent ShapeToTest;

			ACastleEnemyBreakableWall BreakableWall = Cast<ACastleEnemyBreakableWall>(CastleEnemy);
			if (BreakableWall != nullptr)
				ShapeToTest = BreakableWall.OverlapBox;
			else
				ShapeToTest = CastleEnemy.CapsuleComponent;

			FVector EnemyLocation;
			ShapeToTest.GetClosestPointOnCollision(BoxTransform.Location, EnemyLocation);

			if (!FMath::IsPointInBoxWithTransform(EnemyLocation, BoxTransform, BoxExtent))
				continue;

			ValidWalls.AddUnique(CastleEnemy);
		}

		return ValidWalls;
	}

	TArray<AHazePlayerCharacter> GetPlayersInBox(FTransform BoxTransform, FVector BoxExtent)
	{
		TArray<AHazePlayerCharacter> ValidPlayer;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (Player == nullptr)
				continue;

			if (Player.IsPlayerDead())
				continue;

			FVector Location;
			Player.CapsuleComponent.GetClosestPointOnCollision(BoxTransform.Location, Location);

			if (!FMath::IsPointInBoxWithTransform(Location, BoxTransform, BoxExtent))
				continue;

			ValidPlayer.AddUnique(Player);
		}

		return ValidPlayer;
	}
}
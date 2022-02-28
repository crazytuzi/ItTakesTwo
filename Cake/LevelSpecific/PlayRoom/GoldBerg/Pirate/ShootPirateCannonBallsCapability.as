import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.PirateCannonBallActor;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.ShootPirateCannonBallsComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.PirateShipActor;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.StaticCannonEnemyActor;
import Vino.Trajectory.TrajectoryStatics;

class UShootPirateCannonBallsCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PirateEnemy");
	default CapabilityTags.Add(n"PirateCannonCapability");
	
    default TickGroup = ECapabilityTickGroups::ActionMovement;

	AActor OwningPirate;
	UShootPirateCannonBallsComponent ShootComp;
	UPirateEnemyComponent EnemyComponent;
	UCannonBallDamageableComponent DamageableComponent;

	int CurrentCannonBallIndex = 0;	

	int AmountOfSpawnedCannonBalls = 0;
	int ActiveCanonBalls = 0;

	bool bAllCannonBallsAreSpawned = false;
	bool bAllCannonBallsAreExploded = true;

	FTimerHandle TimerHandle;
	FTimerHandle StartAgainTimerHandle;

	FVector LastTargetLocation;
	
	float CannonBallOffset = 500.0f;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
		OwningPirate = Cast<AActor>(Owner);
		ShootComp = UShootPirateCannonBallsComponent::Get(Owner);
		EnemyComponent = UPirateEnemyComponent::Get(Owner);
		DamageableComponent = UCannonBallDamageableComponent::Get(Owner);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if(EnemyComponent.WheelBoat == nullptr)
            return EHazeNetworkActivation::DontActivate;
		if(!EnemyComponent.bAlerted)
            return EHazeNetworkActivation::DontActivate;
		if(!HasControl())
            return EHazeNetworkActivation::DontActivate;
        else
			return EHazeNetworkActivation::ActivateLocal;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if(EnemyComponent.WheelBoat == nullptr)
            return EHazeNetworkDeactivation::DeactivateLocal;
		if(DamageableComponent != nullptr && DamageableComponent.GetIsExploding())
           	return EHazeNetworkDeactivation::DeactivateLocal;
		if(!EnemyComponent.bAlerted && bAllCannonBallsAreSpawned)
            return EHazeNetworkDeactivation::DeactivateLocal;
        else
            return EHazeNetworkDeactivation::DontDeactivate;
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		StartAttackSequence();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		StopAttackSequence();
		System::ClearAndInvalidateTimerHandle(TimerHandle);
		System::ClearAndInvalidateTimerHandle(StartAgainTimerHandle);
	}

	UFUNCTION()
	void StartAttackSequence()
	{
		if(EnemyComponent.WheelBoat != nullptr)
		{
			ShootComp.bShooting = true;

			float LaunchDelay;
			if(ShootComp.bRandomizeLaunchDelay)
				LaunchDelay = ShootComp.GetRandomizedLaunchDelay();
			else
				LaunchDelay = ShootComp.LaunchDelay;

			TimerHandle = System::SetTimer(this, n"ShootCannonBall", LaunchDelay, true);
		}
	}

	UFUNCTION(BlueprintCallable)
    void StopAttackSequence()
    {
        ShootComp.bShooting = false;
    }

	UFUNCTION()
    void ShootCannonBall()
    {
		if(!ShootComp.bShooting || EnemyComponent.WheelBoat == nullptr)
			return;

		if(ShootComp.SpawnLocationComponent == nullptr)
			return;

		FVector TargetLocation;

		if(SpawnCannonBallInLine())
			TargetLocation = LastTargetLocation + (ShootComp.SpawnLocationComponent.RightVector * CannonBallOffset);
		else
			TargetLocation = CalculateTargetLocation();

		FVector SpawnLocation = ShootComp.SpawnLocationComponent.WorldLocation;
		if(HasControl())
			NetShootCannonBall(CurrentCannonBallIndex, SpawnLocation, TargetLocation);

		CurrentCannonBallIndex++;

		if(CurrentCannonBallIndex >= ShootComp.CannonBallContainer.Num())
			CurrentCannonBallIndex = 0;   

		bAllCannonBallsAreExploded = false;
		AmountOfSpawnedCannonBalls = AmountOfSpawnedCannonBalls + 1;

		if(AmountOfSpawnedCannonBalls >= ShootComp.AmountOfCannonBallsToShoot)
		{
			System::ClearAndInvalidateTimerHandle(TimerHandle);
			AllCannonBallsSpawned();
		}
    }

	UFUNCTION(NetFunction)
	void NetShootCannonBall(int ContainerIndex, FVector SpawnLocation, FVector TargetLocation)
	{
		ActiveCanonBalls++;

		if(EnemyComponent == nullptr || EnemyComponent.WheelBoat == nullptr)
		{
			Print("Enemy component or wheel boat wasn't found, aborting shooting cannonball");
			return;
		}

		if(ShootComp == nullptr)
		{
			Print("Invalid cannonball");
			return;
		}

		if(ShootComp.CannonBallContainer.Num() == 0)
		{
			ShootComp.SpawnCannonBalls();
			ShootComp.SetupExplosionEvent(this, n"CannonBallExploded");
		}
		
		FVector TargetActorLocation = EnemyComponent.WheelBoat.ActorLocation;

		FVector DirectionToTarget = GetDirectionToTarget(SpawnLocation);
		FRotator RotationToFaceTarget = Math::MakeRotFromX(DirectionToTarget);

		APirateCannonBallActor CannonBall = ShootComp.CannonBallContainer[ContainerIndex];
		LastTargetLocation = TargetLocation;

		if (CannonBall != nullptr)
		{
			CannonBall.ActivateBall(SpawnLocation, RotationToFaceTarget, FVector::ZeroVector, 980.f, TargetLocation, EnemyComponent.WheelBoat);
			ShootComp.OnCannonBallsLaunched.Broadcast(SpawnLocation, RotationToFaceTarget, CannonBall);
			Niagara::SpawnSystemAtLocation(ShootComp.FireEffect, SpawnLocation + ShootComp.SpawnEffectLocationOffset, RotationToFaceTarget);
		}
	}

	bool SpawnCannonBallInLine()
	{
		if(AmountOfSpawnedCannonBalls > 0)
		{
			if(ShootComp.ShootPattern == EPirateCannonBallShootPattern::Line)
			{
				return true;
			}
			return false;
		}
		return false;
	}

	UFUNCTION(NotBlueprintCallable)
    void CannonBallExploded(APirateCannonBallActor CannonBall)
    {
		ActiveCanonBalls--;

		if(ActiveCanonBalls > 0)
			return;

		if(!bAllCannonBallsAreSpawned)
			return;

		bAllCannonBallsAreSpawned = false;
		bAllCannonBallsAreExploded = true;
		if(ShootComp.bShooting && HasControl())
			StartAgainTimerHandle = System::SetTimer(this, n"StartAttackSequence", ShootComp.AttackSequencePause, false);
	}

		
	UFUNCTION()
	void AllCannonBallsSpawned()
	{
		AmountOfSpawnedCannonBalls = 0;
		bAllCannonBallsAreSpawned = true;

		if(HasControl())
		{
			AHazePlayerCharacter VOPLayer = Game::Players[FMath::RandRange(0, 1)];
			NetPlayVOBark(VOPLayer);		
		}
	}

	UFUNCTION(NetFunction)
	void NetPlayVOBark(AHazePlayerCharacter VOPLayer)
	{
		if(ShootComp.VOBank != nullptr)
		{
			FName EventName = VOPLayer.IsMay() ? n"FoghornDBPlayRoomGoldbergIncomingFireMay" : n"FoghornDBPlayRoomGoldbergIncomingFireCody";

			PlayFoghornVOBankEvent(ShootComp.VOBank, EventName);
		}
	}
	

	UFUNCTION()
	FVector GetDirectionToTarget(FVector StartLocation)
	{
		FVector Direction = StartLocation - EnemyComponent.WheelBoat.ActorLocation;
		Direction.Normalize();
		return Direction;
	}
	
	UFUNCTION()
	FVector CalculateTargetLocation()
	{
		AActor Target = EnemyComponent.WheelBoat;

		FVector CannonTargetLocation = FindOffsettedLocationCloseToTarget();
	
		CannonTargetLocation = FVector(CannonTargetLocation.X, CannonTargetLocation.Y, Target.ActorLocation.Z);

		return CannonTargetLocation;
	}

	UFUNCTION()
	FVector FindOffsettedLocationCloseToTarget()
	{
		AActor Target = EnemyComponent.WheelBoat;
		float MaxTargetOffsetDistance = ShootComp.MaxTargetOffsetDistance;

		float RandX = FMath::RandRange(-MaxTargetOffsetDistance, MaxTargetOffsetDistance);
		float RandY = FMath::RandRange(-MaxTargetOffsetDistance, MaxTargetOffsetDistance);
		FVector TargetOffset = FVector(RandX, RandY, 0);
		FVector TargetLocationWithOffset = Target.ActorLocation + TargetOffset;
		return FVector(TargetLocationWithOffset.X, TargetLocationWithOffset.Y, Target.ActorLocation.Z);
	}
};
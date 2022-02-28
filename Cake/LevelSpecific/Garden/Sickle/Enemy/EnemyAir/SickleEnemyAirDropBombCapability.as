
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyAir.SickleEnemyAirComponent;
import Vino.PlayerHealth.PlayerHealthSettings;


class USickleEnemyAirDropBompCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SickleEnemyAlive");
	default TickGroup = ECapabilityTickGroups::ActionMovement;
		
	ASickleEnemy AiOwner;
	USickleEnemyAirComponent AiComponent;
	float CooldownTimeLeft = 0.f;

	AHazePlayerCharacter CurrentTarget;
 
	int CurrentBombContainerIndex = 0;
	int BombsLeftToDrop = 0;
	float CooldownToNextBomb = 0;

	FRotator AttackDirection = FRotator::ZeroRotator;
	bool bDroppingBombs = false;
	float AttackTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiComponent = USickleEnemyAirComponent::Get(AiOwner);

		auto May = Game::GetMay();
		auto Cody = Game::GetCody();

		// Create the bombs and make them networked
		for(int i = 0; i < AiComponent.BombAmount; ++i)
		{
			auto Projectile = Cast<ASickleAirEnemyBomb>(SpawnActor(AiComponent.BombClass, AiOwner.GetActorLocation(), Level = Owner.GetLevel(), bDeferredSpawn = true));
			Projectile.MakeNetworked(this, i);
			Projectile.SetActorEnableCollision(false);
			Projectile.TraceParams.InitWithMovementComponent(AiComponent);
			Projectile.TraceParams.UnmarkToTraceWithOriginOffset();
			Projectile.TraceParams.IgnoreActor(AiOwner);
			Projectile.Initialize();
			Projectile.FinishSpawningActor();
			Projectile.AiOwner = AiOwner;
			Projectile.OnBombImpact.AddUFunction(this, n"OnBombImpact");
			AiComponent.BombContainer.Add(Projectile);
			Projectile.DisableActor(AiOwner);
			AiComponent.StartIgnoringActor(Projectile);

		}

		// Setup the ignore toward eachother
		for(int i = 0; i < AiComponent.BombContainer.Num(); ++i)
		{
			for(int ii = 0; ii < AiComponent.BombContainer.Num(); ++ii)
			{
				AiComponent.BombContainer[i].TraceParams.IgnoreActor(AiComponent.BombContainer[ii]);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		for(int i = 0; i < AiComponent.BombContainer.Num(); ++i)
		{
			AiComponent.BombContainer[i].DestroyActor();
		}

		AiComponent.BombContainer.Empty();
	}


	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		CooldownTimeLeft = FMath::Max(CooldownTimeLeft - DeltaTime, 0.f);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(CurrentTarget != nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!AiComponent.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(!AiOwner.CanMove())
			return EHazeNetworkActivation::DontActivate;

		if(AiComponent.CurrentFlyHeight < AiComponent.FlyHeight - 50.f)
			return EHazeNetworkActivation::DontActivate;

		AHazePlayerCharacter WantedTarget = AiOwner.GetCurrentTarget();
		if(WantedTarget == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(CooldownTimeLeft > 0)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		return AiComponent.CanCalculateMovement();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!AiComponent.CanCalculateMovement())
		{
			if(HasControl())
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			else
				return EHazeNetworkDeactivation::DeactivateLocal;
		}

		if(!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;

		if(CurrentTarget == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(CurrentTarget != AiOwner.GetCurrentTarget())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!AiOwner.CanMove())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(BombsLeftToDrop <= 0)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			
		if(CooldownTimeLeft > 0)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(bDroppingBombs)
		{
			const float Distance = AiOwner.GetActorLocation().Dist2D(CurrentTarget.GetActorLocation(), AiOwner.GetMovementWorldUp());
			if(Distance >= AiComponent.AttackDistance + AiComponent.StopBombingAttackBonusDistance)
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

		auto AvailablePlayers = AiOwner.AreaToMoveIn.PlayersTriggeredCombat;
		if(!AvailablePlayers.Contains(CurrentTarget))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		CurrentTarget = AiOwner.GetCurrentTarget();
		// This will change the controlside of the object
		AiOwner.LockPlayerAsTarget(CurrentTarget);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {	
		CurrentTarget = AiOwner.GetCurrentTarget();
		//AiOwner.bAttackingPlayer = true;

		// Fly atleast 1 second
		CooldownTimeLeft = 1.f;
		BombsLeftToDrop = AiComponent.BombAmount;
		CooldownToNextBomb = AiComponent.InitialBombDelay;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// How long until we can attack again
    	CooldownTimeLeft = 1;
		AiOwner.bAttackingPlayer = false;
		bDroppingBombs = false;
		CooldownToNextBomb = 0;

		if(CurrentTarget != nullptr)
		{
			// We relase from the remote side so we know that side is done
			if(CurrentTarget.OtherPlayer.HasControl())
				NetReleaseCurrentTarget();
		}
	}  

	UFUNCTION(NetFunction)
	void NetReleaseCurrentTarget()
	{
		AiOwner.LockPlayerAsTarget(CurrentTarget.GetOtherPlayer());
		CurrentTarget = nullptr;		
	}

	UFUNCTION(BlueprintOverride)
	void NotificationReceived(FName Notification, FCapabilityNotificationReceiveParams NotificationParams)
	{
		if(Notification == n"DroppingBombs" && IsActive())
		{
			bDroppingBombs = true;
			AiOwner.bAttackingPlayer = true;
			AiOwner.LastAttackTime = Time::GetGameTimeSeconds();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FinalMovement = AiComponent.MakeFrameMovement(n"BombRun");
		FinalMovement.OverrideStepDownHeight(0.f);

		if(HasControl())
		{
			FVector MovementDelta = FVector::ZeroVector;
			GetDeltaMovementAndFaceDirectionToTarget(MovementDelta, AttackDirection, GetActiveDuration() <= 0);
			const float DistanceToAttackPosition = MovementDelta.Size();

			if(IsDebugActive())
			{
				FVector DebugLoc = AiOwner.GetActorLocation();
				System::DrawDebugArrow(DebugLoc, DebugLoc + (MovementDelta));
			}

			if(!bDroppingBombs)
			{	
				AiComponent.SetTargetFacingRotation(AttackDirection, AiComponent.AttackMovementRotationSpeed);
				
				const float MoveSpeedMul = FMath::Lerp(0.f, 1.f, (AiOwner.GetActorForwardVector().DotProduct(AttackDirection.ForwardVector) + 1) * 0.5f);
				const float MovementSpeed = AiComponent.AttackMovementSpeed.GetFloatValue(GetActiveDuration(), AiComponent.MovementSpeed) * MoveSpeedMul;

				if(DistanceToAttackPosition <= MovementSpeed * DeltaTime || DistanceToAttackPosition < AiComponent.AttackDistance)
					TriggerNotification(n"DroppingBombs");
					

				FinalMovement.ApplyTargetRotationDelta();
				FinalMovement.ApplyVelocity(FinalMovement.Rotation.Vector() * MovementSpeed);
			}
			else
			{
				const float MovementSpeed = AiComponent.DropBombMovementSpeed.GetFloatValue(GetActiveDuration(), AiComponent.MovementSpeed);
				if(AttackDirection.Vector().DotProduct(AiOwner.GetActorForwardVector()) > 0.5f)
				{
					AiComponent.SetTargetFacingRotation(AttackDirection, AiComponent.DropBombMovementRotationSpeed);;
				}	

				FinalMovement.ApplyTargetRotationDelta();
				FinalMovement.ApplyVelocity(FinalMovement.Rotation.Vector() * MovementSpeed);

				CooldownToNextBomb -= DeltaTime;
				if(BombsLeftToDrop > 0 && CooldownToNextBomb <= 0)
				{
					CooldownToNextBomb += AiComponent.DelayBetweenBombs;
					BombsLeftToDrop--;

					FHazeDelegateCrumbParams CrumbParams;
					CrumbParams.AddNumber(n"BombIndex", CurrentBombContainerIndex);
					
					// Since the controlside of the ai can change during the bombfalling. We pick a side that the bomb is most likely to hit
					if(Game::GetMay().HasControl())
						CrumbParams.AddObject(n"ControlSide", Game::GetMay());
					else
						CrumbParams.AddObject(n"ControlSide", Game::GetCody());


					AiOwner.CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_DropBomb"), CrumbParams);

					CurrentBombContainerIndex++;
					if(CurrentBombContainerIndex >= AiComponent.BombContainer.Num())
						CurrentBombContainerIndex = 0;
				}	
			}

			FVector WantedFlyLocation = AiOwner.GetActorLocation();
			AiComponent.ApplyFlyHeightMovement(DeltaTime, WantedFlyLocation, FinalMovement);

			AiComponent.Move(FinalMovement);
			AiOwner.CrumbComponent.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ReplicationData;
			AiOwner.CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, ReplicationData);
			FinalMovement.ApplyConsumedCrumbData(ReplicationData);
			AiComponent.Move(FinalMovement);
		}	
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_DropBomb(const FHazeDelegateCrumbData& CrumbData)
	{
		CurrentBombContainerIndex = CrumbData.GetNumber(n"BombIndex");
		auto BombToDrop = AiComponent.BombContainer[CurrentBombContainerIndex];
		BombToDrop.DropBomb(AiComponent, Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"ControlSide")));
		AiOwner.Mesh.SetAnimBoolParam(n"DropBomb", true);
	}

	UFUNCTION(NotBlueprintCallable)
    void OnBombImpact(ASickleAirEnemyBomb Bomb, FVector ImpactPoint)
    {
		Bomb.AkComponent.HazePostEvent(Bomb.BlobExploAudioEvent);
		if(AiComponent.ImpactEffect != nullptr)
			Niagara::SpawnSystemAtLocation(AiComponent.ImpactEffect, ImpactPoint, PoolingMethod = ENCPoolMethod::AutoRelease);

		ConditionalAddImpactToPlayer(ImpactPoint, Game::GetMay());
        ConditionalAddImpactToPlayer(ImpactPoint, Game::GetCody());
    }

	void ConditionalAddImpactToPlayer(FVector ImpactPoint, AHazePlayerCharacter Player)
	{
		if(!Player.HasControl())
			return;

	 	FVector PlayerLocation = Player.GetActorLocation();
	 	if(ImpactPoint.DistSquared(PlayerLocation) > FMath::Square(AiComponent.AttackImpactRadius))
			 return;

		auto HealthSettings = UPlayerHealthSettings::GetSettings(Player);
		const float DamageAmount = float(AiComponent.DamageAmount) / float(HealthSettings.HealthChunks);

		if(Player.IsCody())
		{	
			auto PlantComp = UControllablePlantsComponent::Get(Player);
			auto TurretPlant = Cast<ATurretPlant>(PlantComp.CurrentPlant);
		 	if(TurretPlant != nullptr)
		 	{
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

	void GetDeltaMovementAndFaceDirectionToTarget(FVector& Delta, FRotator& FaceRotation, bool bRandomRotation = false) const
	{
		Delta = (CurrentTarget.GetActorLocation()  - AiOwner.GetActorLocation()).ConstrainToPlane(FVector::UpVector);
		if(Delta.SizeSquared() < 1.f)
		{
			if(bRandomRotation)
				FaceRotation = FRotator(0.f, FMath::RandRange(0.f, 360.f), 0.f);
			else
				FaceRotation = AiOwner.GetActorRotation();
		}	
		else 
		{
			FaceRotation = Delta.ToOrientationRotator();
		}
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString() const
	{
		FString DebugText = "";

		if(IsActive())
		{
			FVector MovementDelta = FVector::ZeroVector;
			FRotator WantedFacingRotation = FRotator::ZeroRotator;
			GetDeltaMovementAndFaceDirectionToTarget(MovementDelta, WantedFacingRotation);

			DebugText += "Distance to bomb location: " + MovementDelta.Size() + " / " + AiComponent.AttackDistance + "\n";

			if(bDroppingBombs)
				DebugText += "<Red>Dropping Bombs</>" + "\n";
			else
				DebugText += "Dropping Bombs" + "\n";

			DebugText += "Time to next bomb: " + CooldownToNextBomb  + "\n";
		}

        return DebugText;
	}
}


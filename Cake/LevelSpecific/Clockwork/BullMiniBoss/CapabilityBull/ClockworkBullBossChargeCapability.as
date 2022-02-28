import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBossTags;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.CapabilityBull.ClockworkBullBossMoveCapability;

class UClockworkBullBossChargeCapability : UClockworkBullBossMoveCapability
{
 	default CapabilityTags.Add(ClockworkBullBossTags::ClockworkBullBoss);
 	default CapabilityTags.Add(ClockworkBullBossTags::ClockworkBullBossChargeTarget);
 	default CapabilityTags.Add(CapabilityTags::Movement);
 	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
 	default CapabilityTags.Add(MovementSystemTags::BasicFloorMovement);
	default CapabilityTags.Add(ClockworkBullBossTags::ClockworkBullBossPlayerCollisionImpact);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 70;
 	default CapabilityDebugCategory = CapabilityTags::Movement;

	const float TimeUntilActivationAfterLightIsLit = 0.5f;

	float BlockedUntilTime = 0;
	FVector LastDirToTarget;
	FVector LastFrameLocation;
	EBullBossChargeStateType LastState;
	float TimeWhenActivated;
	int ChargedTimes = 0;
	bool bCanActivate = false;
	float ActivationDelay = 0.f;
	float ExpectedTimeToReachTarget = 0.f;
	float MoveSpeedToReachTarget = 0.f;
	int ActiveFrames = 0;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		BlockedUntilTime = Time::GetGameTimeSeconds() + BullOwner.Settings.InitialChargeCooldown;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		bCanActivate = EvaluateActivation();
		if(bCanActivate)
			ActivationDelay += DeltaTime;
		else
			ActivationDelay = 0;

		if(Time::GetGameTimeSeconds() >= BlockedUntilTime && BlockedUntilTime > 0 && bCanActivate)
		{
			// Every time we could charge, we evaluate the random chance, else we trigger the delay once more
			const float RandomValue = FMath::RandRange(0.f, 1.f);
			if(BullOwner.Settings.ChargeChance < RandomValue && BullOwner.Settings.ChargeChance < 1.f)
				BlockedUntilTime = Time::GetGameTimeSeconds() + BullOwner.Settings.ChargeCooldown.GetRandomValue();
			else
				BlockedUntilTime = 0.f;
		}

		// DEBUG
	#if TEST
		if(Owner.GetDebugFlag(n"BullBossDebug"))
		{
			const float TimeLeft = FMath::Max(BlockedUntilTime - Time::GetGameTimeSeconds(), 0.f);
			BullOwner.AddDebugText("TimeLeftToCharge: " + TimeLeft);

			if(BullOwner.bPlayerWantsBullToCharge)
				BullOwner.AddDebugText("<Green>Wants to charge</>");
			else
				BullOwner.AddDebugText("<Red>Charge inactive</>");
		}
	#endif

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{		
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!bCanActivate)
			return EHazeNetworkActivation::DontActivate;

		if(Time::GetGameTimeSeconds() < BlockedUntilTime)
			return EHazeNetworkActivation::DontActivate;

		if(ActivationDelay < TimeUntilActivationAfterLightIsLit)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;	
	}

	bool EvaluateActivation()const
	{
		if(!BullOwner.bPlayerWantsBullToCharge)
			return false;

		if(!BullOwner.CanInitializeMovement(MoveComp))
			return false;

		auto CharacterAnimInstance = Cast<UHazeCharacterAnimInstance>(BullOwner.Mesh.GetAnimInstance());
		if(CharacterAnimInstance.CurFeatureSubAnimInstanceEval != nullptr 
			&& CharacterAnimInstance.CurFeatureSubAnimInstanceEval.Feature != nullptr)
		{
			// The charge request has to finish before we activate it again, else we get stuck
			if(CharacterAnimInstance.CurFeatureSubAnimInstanceEval.Feature.Tag == n"Charge")
				return false;
		}

		if(BullOwner.CurrentTargetPlayer != Game::GetMay() && BullOwner.Settings.bChargeRequiresMayToBeCurrentTarget)
			return false;

		if(!BullOwner.CanTargetPlayer(Game::GetMay(), false))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!BullOwner.bPlayerWantsBullToCharge && BullOwner.ChargeState == EBullBossChargeStateType::TargetingMay)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(BullOwner.ChargeState == EBullBossChargeStateType::Inactive)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(BullOwner.ChargeState == EBullBossChargeStateType::ImpactWithMay)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(BullOwner.ChargeState == EBullBossChargeStateType::ImpactWithPillar)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(BullOwner.ChargeState == EBullBossChargeStateType::ImpactWithWall)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(BullOwner.CurrentTargetPlayer != Game::GetMay())
		{
			if(HasControl())
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			else
				return EHazeNetworkDeactivation::DeactivateLocal;
		}

		return EHazeNetworkDeactivation::DontDeactivate;	
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		BullOwner.SetPlayerTargetFromControl(Game::GetMay());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{	
		if(!BullOwner.Settings.bChargeRequiresMayToBeCurrentTarget)
			SetMutuallyExclusive(ClockworkBullBossTags::ClockworkBullBossChargeTarget, true);

		SetMutuallyExclusive(ClockworkBullBossTags::ClockworkBullBossPlayerCollisionImpact, true);
			
		BullOwner.BlockCapabilities(ClockworkBullBossTags::ClockworkBullBossAttackTarget, this);

		BullOwner.ChargeState = EBullBossChargeStateType::MovingToChargePosition;
		LastState = BullOwner.ChargeState;

		FVector CustomTarget = BullOwner.MovementActor.ChargeFromPosition.WorldLocation;
		BullOwner.SetCustomTargetLocationForFrame(CustomTarget);
		LastFrameLocation = BullOwner.ActorLocation;
		LastDirToTarget = (CustomTarget - BullOwner.ActorLocation).GetSafeNormal();
		if(LastDirToTarget.IsNearlyZero())
			LastDirToTarget = BullOwner.ActorForwardVector;

		BullOwner.BlockChangeTargetTimeLeft = -1;
		TimeWhenActivated = Time::GetGameTimeSeconds();
		ChargedTimes++;

		float RealDistanceToTarget = BullOwner.GetDistanceToTarget();
		float DistanceToTarget = FMath::Clamp(RealDistanceToTarget, BullOwner.ChargeMinDistance, BullOwner.ChargeMaxDistance);
		float LerpAlpha = (DistanceToTarget - BullOwner.ChargeMinDistance) / (BullOwner.ChargeMaxDistance - BullOwner.ChargeMinDistance);
		ExpectedTimeToReachTarget = FMath::Lerp(BullOwner.ChargeMinLerpTime, BullOwner.ChargeMaxLerpTime, FMath::Clamp(LerpAlpha, 0.f, 1.f));
		if(ExpectedTimeToReachTarget > 0)
			MoveSpeedToReachTarget = RealDistanceToTarget / ExpectedTimeToReachTarget;
		else
			MoveSpeedToReachTarget = MoveComp.MoveSpeed;

		BullOwner.SetMoveToChargeMovementSpeed(MoveSpeedToReachTarget);

		// FHazeCameraBlendSettings Blend;
		// Blend.BlendTime = 1.5f;
		// Blend.Type = EHazeCameraBlendType::BlendInThenFollow;
		// Game::GetMay().ActivateCamera(BullOwner.ChargeCamera, Blend, this);
	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(!BullOwner.Settings.bChargeRequiresMayToBeCurrentTarget)
			SetMutuallyExclusive(ClockworkBullBossTags::ClockworkBullBossChargeTarget, false);
		
		SetMutuallyExclusive(ClockworkBullBossTags::ClockworkBullBossPlayerCollisionImpact, false);
		BullOwner.UnblockCapabilities(ClockworkBullBossTags::ClockworkBullBossAttackTarget, this);

		if(ChargedTimes >= BullOwner.Settings.ChargeTimes || BullOwner.ChargeState != EBullBossChargeStateType::ImpactWithMay)
		{
			BlockedUntilTime = Time::GetGameTimeSeconds() + BullOwner.Settings.ChargeCooldown.GetRandomValue();
			BullOwner.ClearCurrentTarget();
			BullOwner.BlockChangeTargetTimeLeft = 2.f;
			ChargedTimes = 0;
		}
		else
		{
			BullOwner.BlockChangeTargetTimeLeft = 0;
		}

		BullOwner.ChargeState = EBullBossChargeStateType::Inactive;
		LastState = EBullBossChargeStateType::Inactive;
		BullOwner.bPlayerDodgeCharge = false;
		ActiveFrames = 0;

		//Game::GetMay().DeactivateCameraByInstigator(this, 0.5f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FinalMovement = MoveComp.MakeFrameMovement(n"BullSplineMove");
		const FName MovementType = n"Charge";

#if TEST
		if(BullOwner.HasControl())
		{
			if(BullOwner.bValidEscapeWindowIsActive)
				BullOwner.AddDebugText("Teleport escape window is <Green>open</>\n");
			else
				BullOwner.AddDebugText("Teleport escape window is <Red>closed</>\n");
		}
#endif

		FVector CustomTarget = BullOwner.GetActorLocation();
		if(BullOwner.bHasLockedTeleportPosition)
		{
			CustomTarget = BullOwner.ValidEscapePosition;
		}
		else
		{
			switch(BullOwner.ChargeState)
			{
				case EBullBossChargeStateType::MovingToChargePosition:
				CustomTarget = BullOwner.MovementActor.ChargeFromPosition.WorldLocation;
				break;

				case EBullBossChargeStateType::TargetingMay:
				case EBullBossChargeStateType::RushingMay:
				CustomTarget = Game::GetMay().ActorLocation;
				break;

				default:
				CustomTarget = BullOwner.ActorLocation + (BullOwner.ActorForwardVector * 1000.f);
				break;
			}
		}

		BullOwner.SetCustomTargetLocationForFrame(CustomTarget);

		if(HasControl())
		{	
			BullOwner.UpdateCollisionBonusDistances(DeltaTime);

			FVector CurrentDirToTarget = (BullOwner.MovementActor.ChargeFromPosition.WorldLocation - BullOwner.ActorLocation).GetSafeNormal();
			if(CurrentDirToTarget.IsNearlyZero())
				CurrentDirToTarget = BullOwner.ActorForwardVector;

			const float ActiveAlpha = FMath::Min((Time::GetGameTimeSeconds() - TimeWhenActivated) / 0.5f, 1.f);
			if(BullOwner.ChargeState == EBullBossChargeStateType::MovingToChargePosition)
			{
				const float CurrentDeltaMove = BullOwner.ActualVelocity.DotProduct(BullOwner.ActorForwardVector) * DeltaTime;
				const float TraceDistance = 150.f + CurrentDeltaMove; 
				if(BullOwner.TargetIsInRange(CustomTarget, TraceDistance)
				|| ((LastDirToTarget.DotProduct(CurrentDirToTarget) < -0.8f) && ActiveDuration > 10.f))
				{
					BullOwner.ChangeChargeState(EBullBossChargeStateType::TargetingMay);
				}
			}
			else if(BullOwner.ChargeState == EBullBossChargeStateType::RushingMay 
			|| BullOwner.ChargeState == EBullBossChargeStateType::RushingForward)
			{
				UpdateImpact();
			}

			if(LastState != BullOwner.ChargeState)
			{
				LastState = BullOwner.ChargeState;
				TimeWhenActivated = Time::GetGameTimeSeconds();
			}

			// Give animation a chance to override the rotation
			if(ActiveFrames >= 1)
			{
				FVector TargetFacingDirection = (CustomTarget - BullOwner.ActorLocation).GetSafeNormal();
				if(TargetFacingDirection.IsNearlyZero())
					TargetFacingDirection = BullOwner.ActorForwardVector;

				float LerpSpeed;
				if(BullOwner.ChargeState == EBullBossChargeStateType::RushingMay)
					LerpSpeed = 0;
				else
					LerpSpeed = FMath::Lerp(2.f, 10.f, ActiveAlpha);
				const float RotationSpeed = BullOwner.GetRotationSpeed(LerpSpeed);
				MoveComp.SetTargetFacingDirection(TargetFacingDirection, RotationSpeed);
			}
		
		 	ApplyControlMovement(DeltaTime, FinalMovement, CustomTarget, MovementType);	
			LastDirToTarget = CurrentDirToTarget;
		}
		else
		{
			if(LastState != BullOwner.ChargeState)
			{
				LastState = BullOwner.ChargeState;
				TimeWhenActivated = Time::GetGameTimeSeconds();
			}

			ApplyRemoteMovement(DeltaTime, FinalMovement, CustomTarget, MovementType);
		}

		LastFrameLocation = BullOwner.ActorLocation;
		ActiveFrames++;
	}

	void UpdateImpact()
	{
		const FVector MovementDelta = BullOwner.ActorLocation - LastFrameLocation;
		FHazeTraceParams MoveQuery;

		MoveQuery.InitWithMovementComponent(MoveComp);
		MoveQuery.InitWithCollisionProfile(n"BlockAll");
		MoveQuery.OverrideOriginOffset(FVector(0.f, 0.f, BullOwner.CapsuleComponent.CapsuleRadius * 0.75f));
		MoveQuery.IgnoreActor(BullOwner);
		
		MoveQuery.From = LastFrameLocation;

		const float SearchAheadDistance = FMath::Max(BullOwner.Settings.ChargeImpactOffsetDistance, 0.f);
		MoveQuery.To = BullOwner.ActorLocation + (BullOwner.GetActorForwardVector() * SearchAheadDistance);

	#if TEST
		if(BullOwner.GetDebugFlag(n"BullBossDebug"))
			MoveQuery.DebugDrawTime = 0;
	#endif
		
		bool bHasCollisionWithMay = false;

		AActor ImpactActor = nullptr;
		TArray<FHitResult> HitResults;
		if(MoveQuery.OverlapSweep(HitResults))
		{	
			for(const FHitResult& Index : HitResults)
			{
				auto Player = Cast<AHazePlayerCharacter>(Index.Actor);
				if(Player != nullptr)
				{
					if(!BullOwner.CanTargetPlayer(Player, false))
						continue;

					if(Player.IsMay())
					{
						bHasCollisionWithMay = true;
						break;
					}
					else if(Player.IsPlayerInIFrame())
					{
						// Cody can dodge, may cant
						continue;
					}
				}
				else if(Index.bBlockingHit && Index.Actor == BullOwner.CenterPillar)
				{
					ImpactActor = BullOwner.CenterPillar;
				}
			}
		}

		if(bHasCollisionWithMay)
		{
			const FBullAttackCollisionData& Headcollision = BullOwner.CollisionData[int(EBullBossDamageInstigatorType::Head)];
			if(Headcollision.IsCollisionEnabled())
			{
				FHazeDelegateCrumbParams CrumbParams;
				CrumbParams.AddNumber(n"ImpactType", EBullBossChargeStateType::ImpactWithMay);
				BullOwner.CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_Impacting"), CrumbParams);		
			}
		}
		else if(BullOwner.ChargeState == EBullBossChargeStateType::RushingForward
			|| BullOwner.ChargeState == EBullBossChargeStateType::RushingMay)
		{
			if(ImpactActor == nullptr && MoveComp.ForwardHit.bBlockingHit)
				ImpactActor = MoveComp.ForwardHit.Actor;

			if(ImpactActor != nullptr)
			{
				FHazeDelegateCrumbParams CrumbParams;
				if(ImpactActor == BullOwner.CenterPillar)
					CrumbParams.AddNumber(n"ImpactType", EBullBossChargeStateType::ImpactWithPillar);
				else
					CrumbParams.AddNumber(n"ImpactType", EBullBossChargeStateType::ImpactWithWall);
		
				BullOwner.CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_Impacting"), CrumbParams);
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_Impacting(const FHazeDelegateCrumbData& CrumbData)
	{
		const EBullBossChargeStateType ImpactType = EBullBossChargeStateType(CrumbData.GetNumber(n"ImpactType"));
		BullOwner.ChargeState = ImpactType;
		BullOwner.OnChargeStateChange.Broadcast(ImpactType);

		if(ImpactType == EBullBossChargeStateType::ImpactWithMay)
		{	
			BullOwner.OnChargeImpact.Broadcast(Game::GetMay());
			BullOwner.TriggerDamageStartCollisionWithPlayer(BullOwner.CollisionData[int(EBullBossDamageInstigatorType::Head)], Game::GetMay(), true);
		}
		else if(ImpactType == EBullBossChargeStateType::ImpactWithPillar)
		{
			BullOwner.OnChargeImpact.Broadcast(BullOwner.CenterPillar);
			BullOwner.CenterPillar.OnChargeImpact.Broadcast();
		}	
		else if(ImpactType == EBullBossChargeStateType::ImpactWithWall)
		{
			BullOwner.OnChargeImpact.Broadcast(nullptr);
		}
	}

	void JumpToSide()
	{
		const FVector TargetLocation = BullOwner.CenterPillar.JumpToSidePosition.GetWorldLocation();
		BullOwner.MeshOffsetComponent.FreezeAndResetWithTime(1.f);
		BullOwner.SetActorLocation(TargetLocation);
	}


	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{	
		FString Str = "";

		return Str;
	} 
};

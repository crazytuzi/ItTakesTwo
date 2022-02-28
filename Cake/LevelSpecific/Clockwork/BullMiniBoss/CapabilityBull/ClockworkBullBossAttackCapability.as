import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBossTags;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.CapabilityBull.ClockworkBullBossMoveCapability;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.LocomotionFeature.LocomotionFeatureClockworkBullBossSubAnimInstance;

class UClockworkBullBossAttackCapabilityBase : UClockworkBullBossMoveCapability
{
	default CapabilityTags.Add(ClockworkBullBossTags::ClockworkBullBoss);
	default CapabilityTags.Add(ClockworkBullBossTags::ClockworkBullBossAttackTarget);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(MovementSystemTags::BasicFloorMovement);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 90;

	default CapabilityDebugCategory = CapabilityTags::Movement;
	
	const float IntersectionSphereRadius = 200.f;

	AHazePlayerCharacter WantedTarget;
	//float HasReachedTargetTime = 0;
	bool bCanDeactivate = true;

	bool bHasAddedPlayer;
	float RemovedPlayerGameTime;
	float DisableSameTargetTime;

	TArray<FBullBossAttackReplicationParams> PendingReplicationParams;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		BullOwner.AvailableTargets.Add(WantedTarget);
		bHasAddedPlayer = true;

		DisableSameTargetTime = -1;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!bHasAddedPlayer && Time::GetGameTimeSeconds() > RemovedPlayerGameTime + DisableSameTargetTime)
		{
			bHasAddedPlayer = true;
			BullOwner.AvailableTargets.Add(WantedTarget);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!BullOwner.CanInitializeMovement(MoveComp))
			return EHazeNetworkActivation::DontActivate;

		if(BullOwner.CurrentTarget != WantedTarget.RootComponent)
			return EHazeNetworkActivation::DontActivate;

		if(BullOwner.bPlayerWantsBullToCharge)
			return EHazeNetworkActivation::DontActivate;

		auto CharacterAnimInstance = Cast<UHazeCharacterAnimInstance>(BullOwner.Mesh.GetAnimInstance());
		if(CharacterAnimInstance.CurFeatureSubAnimInstanceEval != nullptr 
			&& CharacterAnimInstance.CurFeatureSubAnimInstanceEval.Feature != nullptr)
		{
			// As long as we are still attacking, we can't attack again
			if(CharacterAnimInstance.CurFeatureSubAnimInstanceEval.Feature.Tag == n"Attack")
				return EHazeNetworkActivation::DontActivate;
		}

		return EHazeNetworkActivation::ActivateUsingCrumb;	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		if(!BullOwner.CanInitializeMovement(MoveComp))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(GetActiveDuration() < 0.5f)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(BullOwner.CurrentTarget != WantedTarget.RootComponent)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!bCanDeactivate)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(!BullOwner.CanChangeTarget())
			return EHazeNetworkDeactivation::DontDeactivate;
			
		const FVector Target = WantedTarget.GetActorLocation();
		if(CanSee(Target))
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		FBullBossAttackReplicationParams Replication;
		FillAttackReplicationData(Replication, BullOwner, WantedTarget);
		NetSendReplicationData(Replication);
	}

	UFUNCTION(NotBlueprintCallable, NetFunction)
	void NetSendReplicationData(FBullBossAttackReplicationParams RepData)
	{
		PendingReplicationParams.Insert(RepData);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		// Break out of old capabilities
		SetMutuallyExclusive(MovementSystemTags::GroundMovement, true);
		SetMutuallyExclusive(MovementSystemTags::GroundMovement, false);
		SetMutuallyExclusive(ClockworkBullBossTags::ClockworkBullBossAttackTarget, true);
		bCanDeactivate = false;

		const int LastIndex = PendingReplicationParams.Num() - 1;
		BullOwner.AttackReplicationParams = PendingReplicationParams[LastIndex];
		PendingReplicationParams.RemoveAt(LastIndex);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(ClockworkBullBossTags::ClockworkBullBossAttackTarget, false);
		bCanDeactivate = true;
		if(DeactivationParams.DeactivationReason == ECapabilityStatusChangeReason::Natural && BullOwner.CurrentTargetPlayer == WantedTarget)
		{
			bHasAddedPlayer = false;
				BullOwner.AvailableTargets.RemoveSwap(WantedTarget);
			RemovedPlayerGameTime = Time::GetGameTimeSeconds();
		}

		auto CurrentPlayerTarget = BullOwner.GetCurrentTargetPlayer();
		if(CurrentPlayerTarget == WantedTarget)
			BullOwner.ClearCurrentTarget();

		DisableSameTargetTime = BullOwner.Settings.DisableSameTargetTime.GetRandomValue();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FinalMovement = MoveComp.MakeFrameMovement(n"BullAttackMove");
		//const FName MovementType = HasReachedTargetTime > 0 ? n"Attack" : n"Movement";
		const FName MovementType = n"Attack";

		FVector TargetWorldLocation = WantedTarget.ActorLocation;
		FVector	TargetFacingDirection = (TargetWorldLocation - BullOwner.ActorLocation).GetSafeNormal();
		if(TargetFacingDirection.IsNearlyZero())
			TargetFacingDirection = BullOwner.ActorForwardVector;

		if(HasControl())
		{	
			//const float CurrentDuration = HasReachedTargetTime > 0 ? Time::GetGameTimeSeconds() - HasReachedTargetTime : 0.f;
			const float LerpSpeedAlpha = FMath::Min(GetActiveDuration() / 1.f, 1.f);
			const float RotationSpeed = BullOwner.GetRotationSpeed(FMath::Lerp(4.f, 10.f, LerpSpeedAlpha));
			MoveComp.SetTargetFacingDirection(TargetFacingDirection, RotationSpeed);

			if(!bCanDeactivate)
			{
				const bool bTimeHasPassed = GetActiveDuration() >= 5.f;
				if(!BullOwner.CanChangeTarget() || bTimeHasPassed)
				{
					bCanDeactivate = true;
				}
			}

			ApplyControlMovement(DeltaTime, FinalMovement, TargetWorldLocation, MovementType);


			// Debug
		#if TEST
			if(BullOwner.GetDebugFlag(n"BullBossDebug"))
			{
				FLinearColor ConeColor = CanSee(TargetWorldLocation) ? FLinearColor::White : FLinearColor::Black;
				FHazeIntersectionCone SearchCone;
				BullOwner.GetAttackIntersectionCone(SearchCone);
				System::DrawDebugConeInDegrees(SearchCone.Origin, SearchCone.Direction, 
					SearchCone.MaxLength, 
					SearchCone.AngleDegrees, SearchCone.AngleDegrees,
					LineColor = ConeColor);

				//System::DrawDebugSphere(TargetWorldLocation, IntersectionSphereRadius);
			}
		#endif

		}
		else
		{
			ApplyRemoteMovement(DeltaTime, FinalMovement, TargetWorldLocation, MovementType);
		}
	}

	bool CanSee(FVector Target)const
	{
		FHazeIntersectionCone Cone;
		BullOwner.GetAttackIntersectionCone(Cone);
		return BullOwner.CanSeeTarget(Target, Cone, IntersectionSphereRadius);
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{	
		FString Str = "";

		return Str;
	} 
};


class UClockworkBullBossAttackMayCapability : UClockworkBullBossAttackCapabilityBase
{
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		WantedTarget = Game::GetMay();
		Super::Setup(SetupParams);
		
	}
}

class UClockworkBullBossAttackCodyCapability : UClockworkBullBossAttackCapabilityBase
{
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		WantedTarget = Game::GetCody();
		Super::Setup(SetupParams);		
	}
}

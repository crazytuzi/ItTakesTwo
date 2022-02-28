import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBossTags;
import Vino.Movement.Helpers.BurstForceStatics;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlParams;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockWorkBullBossPlayerComponent;
import Vino.PlayerHealth.PlayerHealthComponent;
import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.PlayerTimeSequenceComponent;

class UClockworkBullBossPlayerTakeDamageCapability : UHazeCapability
{
	default CapabilityTags.Add(ClockworkBullBossTags::ClockworkBullBoss);
	default CapabilityTags.Add(ClockworkBullBossTags::ClockworkBullBossTakeDamage);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 1;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter PlayerOwner;
	UHazeMovementComponent MoveComp;
	UClockWorkBullBossPlayerComponent BullBossComponent;
	UHazeBurstForceComponent BurstForceComponent;
	UHazeCrumbComponent CrumbComp;
	UTimeControlSequenceComponent SeqComp;

	bool bIsFirstFrame = false;
	bool bIsOverlappingBoss = false;
	bool bMovementIsBlocked = false;

	float ApplyForceTime = 0;

	float DebugTime = 0;
	int DebugFrameCount = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		BullBossComponent = UClockWorkBullBossPlayerComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		BurstForceComponent = UHazeBurstForceComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		SeqComp = UTimeControlSequenceComponent::Get(Owner);
		PlayerOwner.AddLocomotionFeature(BullBossComponent.TakeDamageFeaure);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		PlayerOwner.RemoveLocomotionFeature(BullBossComponent.TakeDamageFeaure);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(SeqComp != nullptr && SeqComp.bIsCurrentlyTeleporting)
		{
			BullBossComponent.ClearImpact();
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!BullBossComponent.bIsTakingDamageFromBoss)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bIsFirstFrame)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(BullBossComponent.bIsTakingDamageFromBoss)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(BullBossComponent.bIsAttachedToBoss)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(FMath::Abs(BullBossComponent.LockedIntoTakeDamageTime) > KINDA_SMALL_NUMBER)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(ApplyForceTime > 0)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(bIsOverlappingBoss)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateUsingCrumb;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{	
		SetMutuallyExclusive(ClockworkBullBossTags::ClockworkBullBossTakeDamage, true);
		SetMutuallyExclusive(ClockworkBullBossTags::ClockworkBullBossTakeDamage, false);

		PlayerOwner.BlockCapabilities(TimeControlCapabilityTags::TimeControlCapability, this);
		PlayerOwner.BlockCapabilities(TimeControlCapabilityTags::TimeDiliationCapability, this);
		PlayerOwner.BlockCapabilities(TimeControlCapabilityTags::TimeSequenceCapability, this);
		PlayerOwner.BlockCapabilities(ClockworkBullBossTags::ClockworkBullBossFocus, this);
		SetMovementBlocked(true);
		bIsFirstFrame = true;
	
		BullBossComponent.IgnoreBullBossInMovement(this, true);

		PlayerOwner.DamagePlayerHealth(BullBossComponent.ActiveDamage.DamageAmount, BullBossComponent.BullBoss.DamageEffect);
		BurstForceComponent.ClearAllForces();
		ApplyForceTime = BullBossComponent.ActiveDamage.ApplyForceTime;

		DebugTime = 0;
		DebugFrameCount = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{	
		// if(DebugTime < 0.5f)
		// {
		// 	TickActive(Owner.GetActorDeltaSeconds());
		// }

		PlayerOwner.UnblockCapabilities(TimeControlCapabilityTags::TimeControlCapability, this);
		PlayerOwner.UnblockCapabilities(TimeControlCapabilityTags::TimeDiliationCapability, this);
		PlayerOwner.UnblockCapabilities(TimeControlCapabilityTags::TimeSequenceCapability, this);
		PlayerOwner.UnblockCapabilities(ClockworkBullBossTags::ClockworkBullBossFocus, this);
		SetMovementBlocked(false);

		BullBossComponent.IgnoreBullBossInMovement(this, false);

		if(BullBossComponent.bIsAttachedToBoss)
		{
			BullBossComponent.DetachFromBull();
		}

		BurstForceComponent.ClearAllForces();
		BullBossComponent.bIsTakingDamageFromBoss = false;
	}

	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DebugTime += DeltaTime;
		DebugFrameCount++;

		FHazeFrameMovement FinalMovement = MoveComp.MakeFrameMovement(n"BullBossTakeDamage");
		FinalMovement.OverrideStepDownHeight(0.f);

		FHazeTraceParams TraceParams;
		TraceParams.InitWithMovementComponent(MoveComp);
		TraceParams.InitWithCollisionProfile(n"PlayerCharacter");
		
		// Check if we are overlapping the billboss
		bIsOverlappingBoss = false;
		TArray<FOverlapResult> Overlaps;
		if (TraceParams.Overlap(Overlaps))
		{
			for(const FOverlapResult& Overlap : Overlaps)
			{
				if(Overlap.Actor == BullBossComponent.BullBoss)
				{
					bIsOverlappingBoss = true;
					break;
				}
			}
		}

		// Handle attachment
		if(BullBossComponent.bShouldBeAttachedToBoss && !BullBossComponent.bIsAttachedToBoss)
		{
			if(BullBossComponent.RequiredAttachmentInstigator == EBullBossDamageInstigatorType::None)
				BullBossComponent.AttachToBull(BullBossComponent.ActiveDamage.DamageInstigator);
			else if(BullBossComponent.RequiredAttachmentInstigator == BullBossComponent.ActiveDamage.DamageInstigator)
				BullBossComponent.AttachToBull(BullBossComponent.ActiveDamage.DamageInstigator);
		}
		else if(!BullBossComponent.bShouldBeAttachedToBoss && BullBossComponent.bIsAttachedToBoss)
		{
			BullBossComponent.DetachFromBull();
		}

		if(HasControl())
		{
			if(!BullBossComponent.bIsAttachedToBoss)
			{
				ApplyForce(DeltaTime, FinalMovement);

				if(!bIsFirstFrame && BullBossComponent.ActiveDamage.DamageForce.IsNearlyZero())
				{
					ApplyForceTime = 0;
					if(FMath::Abs(BullBossComponent.LockedIntoTakeDamageTime) <= KINDA_SMALL_NUMBER)
					{
						BullBossComponent.bIsTakingDamageFromBoss = false;
						BullBossComponent.LockedIntoTakeDamageTime = 0;
					}
					
					if(MoveComp.IsGrounded())
					{
						BullBossComponent.bIsTakingDamageFromBoss = false;
						BullBossComponent.LockedIntoTakeDamageTime = 0;
					}
				}
			}
			else
			{
				FinalMovement.OverrideGroundedState(EHazeGroundedState::Airborne);	
			}
	
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FinalMovement.ApplyConsumedCrumbData(ConsumedParams);
		}

		if(MoveComp.CanCalculateMovement())
		{
			MoveCharacter(FinalMovement, n"TakeBullBossDamage");
			CrumbComp.LeaveMovementCrumb();
		}
	
#if TEST
		BullBossComponent.BullBoss.AddDebugText("" + PlayerOwner.GetName() + " <Red>Taking Damage</>" + 
		"\n" + BullBossComponent.ActiveDamage.DamageType +
		"\nLocked: " + BullBossComponent.LockedIntoTakeDamageTime + 
		"\nAttached: " +  BullBossComponent.bIsAttachedToBoss +
		"\n");
#endif

		bIsFirstFrame = false;
	}

    void MoveCharacter(const FHazeFrameMovement& MoveData, FName AnimationRequestTag, FName SubAnimationRequestTag = NAME_None)
    {
		if(bMovementIsBlocked)
		{
			if(AnimationRequestTag != NAME_None)
			{
				SendMovementAnimationRequest(MoveData, AnimationRequestTag, SubAnimationRequestTag);
			}
			MoveComp.Move(MoveData);
		}
		else
		{
			MoveComp.SetAnimationToBeRequested(AnimationRequestTag);
		}
    }
    
    void SendMovementAnimationRequest(const FHazeFrameMovement& MoveData, FName AnimationRequestTag, FName SubAnimationRequestTag)
    {
        FHazeRequestLocomotionData AnimationRequest;
 
        AnimationRequest.LocomotionAdjustment.DeltaTranslation = MoveData.MovementDelta;
		AnimationRequest.LocomotionAdjustment.WorldRotation = MoveData.Rotation;
 		AnimationRequest.WantedVelocity = MoveData.Velocity;
		AnimationRequest.WantedWorldTargetDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
        AnimationRequest.WantedWorldFacingRotation = MoveComp.GetTargetFacingRotation();
		AnimationRequest.MoveSpeed = MoveComp.MoveSpeed;
		
		if(!MoveComp.GetAnimationRequest(AnimationRequest.AnimationTag))
		{
			AnimationRequest.AnimationTag = AnimationRequestTag;
		}

        if (!MoveComp.GetSubAnimationRequest(AnimationRequest.SubAnimationTag))
        {
            AnimationRequest.SubAnimationTag = SubAnimationRequestTag;
        }

        PlayerOwner.RequestLocomotion(AnimationRequest);
    }

	void ApplyForce(float DeltaTime, FHazeFrameMovement& FinalMovement)
	{
		bool bHasAppliedForce = false;
		if(!BullBossComponent.ActiveDamage.DamageForce.IsNearlyZero())
		{
			FinalMovement.AddActorToIgnore(BullBossComponent.BullBoss);
			if(BullBossComponent.ActiveDamage.ApplyForceTime <= 0)
			{
				FinalMovement.ApplyVelocity(BullBossComponent.ActiveDamage.DamageForce);
				FinalMovement.OverrideGroundedState(EHazeGroundedState::Airborne);
				FinalMovement.OverrideStepDownHeight(0.f);
				bHasAppliedForce = true;

			#if TEST
				if(BullBossComponent.BullBoss.GetDebugFlag(n"BullBossDebug"))
				{
					FVector ForceDir = BullBossComponent.ActiveDamage.DamageForce.GetSafeNormal();
					System::DrawDebugArrow(PlayerOwner.ActorCenterLocation, PlayerOwner.ActorCenterLocation + (ForceDir * 500.f), 25.f, FLinearColor::Red, 5.f, 8.f);
				}
			#endif

				//PlayerOwner.AddBurstForce(BullBossComponent.ActiveDamage.DamageForce, BullBossComponent.ActiveDamage.DamageForce.Rotation());
				BullBossComponent.ActiveDamage.DamageForce = FVector::ZeroVector;
			}
			else
			{
				const float MovementPercentage = FMath::Min(ApplyForceTime, DeltaTime) / BullBossComponent.ActiveDamage.ApplyForceTime;
				FinalMovement.ApplyDelta(BullBossComponent.ActiveDamage.DamageForce * MovementPercentage);
				FinalMovement.OverrideGroundedState(EHazeGroundedState::Airborne);
				
				bHasAppliedForce = true;

				ApplyForceTime -= DeltaTime;
				if(ApplyForceTime <= 0)
				{
					ApplyForceTime = 0;
					BullBossComponent.ActiveDamage.DamageForce = FVector::ZeroVector;
		
			#if TEST
				if(BullBossComponent.BullBoss.GetDebugFlag(n"BullBossDebug"))
				{
					FVector ForceDir = BullBossComponent.ActiveDamage.DamageForce.GetSafeNormal();
					System::DrawDebugArrow(PlayerOwner.ActorCenterLocation, PlayerOwner.ActorCenterLocation + (ForceDir * 500.f), 25.f, FLinearColor::Red, 5.f, 8.f);
				}
			#endif

				}
				else
				{
					
			#if TEST
				if(BullBossComponent.BullBoss.GetDebugFlag(n"BullBossDebug"))
				{
					FVector ForceDir = BullBossComponent.ActiveDamage.DamageForce.GetSafeNormal();
					System::DrawDebugArrow(PlayerOwner.ActorCenterLocation, PlayerOwner.ActorCenterLocation + (ForceDir * 500.f), 25.f, FLinearColor::Red, 0.f, 8.f);
				}
			#endif

				}
			}
		}

		if(!bHasAppliedForce)
		{
			FinalMovement.ApplyActorVerticalVelocity();
			FinalMovement.ApplyActorHorizontalVelocity();
			FinalMovement.ApplyGravityAcceleration();	
		}
	}

	void SetMovementBlocked(bool bStatus)
	{
		if(bMovementIsBlocked == bStatus)
			return;

		if(bStatus)
		{
			PlayerOwner.BlockCapabilities(CapabilityTags::Movement, this);
			PlayerOwner.BlockCapabilities(CapabilityTags::MovementInput, this);
			PlayerOwner.BlockCapabilities(CapabilityTags::MovementAction, this);
			PlayerOwner.BlockCapabilities(CapabilityTags::GameplayAction, this);
		}
		else
		{
			PlayerOwner.UnblockCapabilities(CapabilityTags::Movement, this);
			PlayerOwner.UnblockCapabilities(CapabilityTags::MovementInput, this);
			PlayerOwner.UnblockCapabilities(CapabilityTags::MovementAction, this);
			PlayerOwner.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		}

		bMovementIsBlocked = bStatus;
	}


	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{	
		FString Str = "\n";
		return Str;
	} 
};

// // This is so you can take damage while taking damage
// class UClockworkBullBossPlayerTakeDamageComboCapability : UClockworkBullBossPlayerTakeDamageCapability
// {
	
// }

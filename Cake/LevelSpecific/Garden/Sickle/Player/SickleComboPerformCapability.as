import Cake.LevelSpecific.Garden.Sickle.Player.SickleComponent;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Cake.LevelSpecific.Garden.Sickle.Animation.AnimNotify_SickleTriggerImpact;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseComponent;
import Cake.LevelSpecific.Garden.Sickle.SickleTags;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyGround.SickleEnemyGroundComponent;
import Vino.Movement.Jump.AirJumpsComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyAir.SickleEnemyAirComponent;

class USickleComboPerformCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(GardenSickle::Sickle);
	default CapabilityTags.Add(GardenSickle::SickleAttack);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(n"BlockedWhileGrinding");
	default CapabilityTags.Add(n"BlockedWhileCrouching");

	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 1;

	// How fast we will turn to face the target
	const float FaceTargetSpeed = 30.f;

	UCharacterAirJumpsComponent AirJumpsComp;
	AHazePlayerCharacter Player;
	USickleComponent SickleComp;
	ASickleTargetAttachment LerpToTargetActor;
	UCharacterGroundPoundComponent GroundPoundComp;
	FName MovementName = n"SickleAttack";

	float TranslateToTargetTime = 0;
	bool bLerpingToTarget = false;

	FVector ControlSideActivationLocation;
	FVector LastLerpToLocation = FVector::ZeroVector;
	FVector ControlSideUpForce = FVector::ZeroVector;

	float TimeLeftToDisableAlertedStance = 0;
	USickleCuttableComponent TargetComponent = nullptr;
	bool bHasAttachedAttachmentActor = false;
	UAnimSequence AnimationToStopAtEnd = nullptr;

	bool bHasBlockedMovement = false;
	TArray<ASickleEnemy> ActiveDamageTakers;
	bool bForceApplyGravity = false;
	bool bAppliedGravityLastFrame = false;
	bool bCanApplyUpwardsRootmotion = false;


	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString Debug = "";
		Debug += "Current Combo: " + SickleComp.ComboCurrent + "\n";

		if(SickleComp.CurrentAttackAsset != nullptr)
		{
			Debug += "Attack: " + SickleComp.CurrentAttackAsset.GetName() + "\n";
		}

		if(TargetComponent != nullptr)
		{
			Debug += "Current Target: " + TargetComponent.GetOwner().GetName() + "\n";
		}
			
		return Debug;
	}

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		SickleComp = USickleComponent::Get(Player);
		LerpToTargetActor = SickleComp.SickleTargetAttachmentActor;

		auto BackPack = UWaterHoseComponent::Get(Player);
		SickleComp.SickleActor.AttachToComponent(BackPack.WaterHose.GetGunMesh(), n"LeftAttach");
		SickleComp.SickleActor.OnAttachedToWaterHose();
		AirJumpsComp = UCharacterAirJumpsComponent::GetOrCreate(Owner);

		GroundPoundComp = UCharacterGroundPoundComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		SickleComp.SickleActor.DetachRootComponentFromParent();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(TimeLeftToDisableAlertedStance > 0)
		{
			TimeLeftToDisableAlertedStance -= DeltaTime;
			if(TimeLeftToDisableAlertedStance <= 0)
			{
				SickleComp.DisableCombatStance();
			}
		}

		if(ConsumeAction(n"SickleAttackBlockedUntilGrounded") == EActionStateStatus::Active)
		{
			SickleComp.bBlockAttackUntilGrounded = true;
		}

	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(IsActioning(CapabilityTags::Interaction))
			return EHazeNetworkActivation::DontActivate;

		if(!SickleComp.bCanActiveNextAttack)
			return EHazeNetworkActivation::DontActivate;

		if(SickleComp.bBlockAttackUntilGrounded)
			return EHazeNetworkActivation::DontActivate;

		if(GroundPoundComp.IsGroundPounding())
			return EHazeNetworkActivation::DontActivate;
			
		if(IsActioning(GardenSickle::SickleAttack))
			return EHazeNetworkActivation::ActivateUsingCrumb;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(IsActioning(CapabilityTags::Interaction))
			return RemoteLocalControlCrumbDeactivation();

		if(TargetComponent != nullptr)
		{
			if(Player.CurrentActivationInstigatorIs(this) == false)
				return RemoteLocalControlCrumbDeactivation();
		}

		if(SickleComp.CurrentAttackAsset == nullptr)
			return RemoteLocalControlCrumbDeactivation();

		if (AnimationToStopAtEnd == nullptr)
		     return RemoteLocalControlCrumbDeactivation();

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ConsumeAction(GardenSickle::SickleAttack);

		TargetComponent = Cast<USickleCuttableComponent>(Player.GetActivePoint());
		if(TargetComponent == nullptr || TargetComponent.bOwnerIsDead)
		{
			TargetComponent = Cast<USickleCuttableComponent>(Player.GetTargetPoint(USickleCuttableComponent::StaticClass()));
		}

		ActivationParams.AddObject(n"AttackTarget", TargetComponent);

		USickleAttackDataAsset AttackAsset;
		if(!SickleComp.GetDataAssetComboRequest(TargetComponent, SickleComp.ComboCurrent + 1, AttackAsset))
		{
			SickleComp.ResetComboCounter();
			SickleComp.GetDataAssetComboRequest(TargetComponent, SickleComp.ComboCurrent + 1, AttackAsset);
		}

		ActivationParams.AddObject(n"AttackAsset", AttackAsset);
		ActivationParams.AddNumber(n"ComboIndex", SickleComp.ComboCurrent + 1);
		
		if(AttackAsset != nullptr)
		{
			// Make the player stand at the correct location and face the target
			if(TargetComponent != nullptr)
			{
				// Apply the Target rotation
				FVector DirToTarget = TargetComponent.GetWorldLocation() - Player.GetActorLocation();
				if(DirToTarget.SizeSquared() > 1)
				{
					DirToTarget.Normalize();
					MoveComp.SetTargetFacingDirection(DirToTarget, FaceTargetSpeed);
				}

				if(AttackAsset.MovementTranslationType == ESickleAttackTranslationType::TranslateToTarget)
				{
					InitializeTranslationToTarget(TargetComponent, AttackAsset);
				}
			}

			if(AttackAsset.MovementTranslationType == ESickleAttackTranslationType::ApplySmallUpForce)
			{
				ApplyUpForce(AttackAsset);
			}
		}	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		bCanApplyUpwardsRootmotion = AirJumpsComp.CanJump();
		if(TimeLeftToDisableAlertedStance > 0)
		{
			TimeLeftToDisableAlertedStance = 0;
		}
		else
		{
			SickleComp.EnableCombatStance(false);
		}

		TargetComponent = Cast<USickleCuttableComponent>(ActivationParams.GetObject(n"AttackTarget"));
	
		// Clear the old data
		SetMutuallyExclusive(GardenSickle::SickleAttack, true);
		SetMutuallyExclusive(GardenSickle::SickleAttack, false);
		Player.BlockCapabilities(n"WaterHoseAim", this);

		if(HasControl())
		{
			Player.BlockCapabilities(MovementSystemTags::GroundPound, this);			
		}

		BlockMovement(true);
		Player.CleanupCurrentMovementTrail();

		// Setup the attack asset
		SickleComp.CurrentAttackAsset = Cast<USickleAttackDataAsset>(ActivationParams.GetObject(n"AttackAsset"));

		if(SickleComp.CurrentAttackAsset != nullptr)
		{
			SickleComp.ComboCurrent = ActivationParams.GetNumber(n"ComboIndex");
			SickleComp.bCanActiveNextAttack = false;
			Player.AddLocomotionFeature(SickleComp.CurrentAttackAsset);

			bForceApplyGravity = SickleComp.CurrentAttackAsset.bForceApplyGravity;
			// Setup the target
			
			if(TargetComponent != nullptr)
			{
				Player.ActivatePoint(TargetComponent, this);

				// Experimental
				//SickleComp.bResetBlockOnNewTarget = true;
				SickleComp.bResetBlocksOnAirAction = true;

				auto Enemy = Cast<ASickleEnemy>(TargetComponent.Owner);
				if(Enemy != nullptr)
				{
					auto GroundEnemy = USickleEnemyGroundComponent::Get(Enemy);
					if(GroundEnemy != nullptr)
					{
						// Non 
						if(!GroundEnemy.bHasShield)
						{
							auto VineImpact = UVineImpactComponent::Get(Enemy);
							if(VineImpact != nullptr)
							{
								auto AiGrondComp = USickleEnemyGroundComponent::Get(Enemy);
								if(AiGrondComp != nullptr && !AiGrondComp.bHasShield)
									VineImpact.SetCanActivate(false, this);
							}
						}
					}
					else
					{
						auto AirEnemy = USickleEnemyAirComponent::Get(Enemy);
						if(AirEnemy != nullptr)
						{
							if(!Enemy.bIsBeeingHitByVine)
							{
								auto VineImpact = UVineImpactComponent::Get(Enemy);
								if(VineImpact != nullptr)
								{
									auto AiGrondComp = USickleEnemyGroundComponent::Get(Enemy);
									if(AiGrondComp != nullptr && !AiGrondComp.bHasShield)
										VineImpact.SetCanActivate(false, this);
								}
							}
						}
					}
	
					// Stop the movement of the enemy we are moving towards
					auto EnemyMovement = UHazeMovementComponent::Get(Enemy);
					if(EnemyMovement != nullptr)
						EnemyMovement.StopMovement(true);

					StartAttackingEnemy(Enemy, SickleComp.CurrentAttackAsset.ComboTag);	
				}
			}
			
			// Setup the animation
			auto AttackAnimationData = SickleComp.CurrentAttackAsset.AttackAnimation;
			if(AttackAnimationData.Animation != nullptr)
			{
				FHazeAnimationDelegate OnAnimEnd;
				OnAnimEnd.BindUFunction(this, n"AnimationFinished");

				Player.PlaySlotAnimation(FHazeAnimationDelegate(), OnAnimEnd, AttackAnimationData);
				Player.BindOrExecuteOneShotAnimNotifyDelegate(AttackAnimationData.Animation, UAnimNotify_SickleTriggerImpact::StaticClass(), FHazeAnimNotifyDelegate(this, n"TriggerImpact"));	
				AnimationToStopAtEnd = AttackAnimationData.Animation;
			}
		}		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(AnimationToStopAtEnd != nullptr)
		{
			// We must force the deactivation to happen if we dont deactivate normally
			AnimationFinished();
		}

		if(HasControl())
		{
			Player.UnblockCapabilities(MovementSystemTags::GroundPound, this);			
		}

		Player.DeactivateCurrentPoint(this);
		Player.UnblockCapabilities(n"WaterHoseAim", this);
		BlockMovement(false);
		bForceApplyGravity = false;

		SickleComp.ResetActiveCombo();
		Player.RemoveLocomotionFeature(SickleComp.CurrentAttackAsset);

		for(int i = 0; i < ActiveDamageTakers.Num(); ++i)
		{
			if(ActiveDamageTakers[i] != nullptr)
				StopAttackingEnemy(ActiveDamageTakers[i]);
		}
		ActiveDamageTakers.Reset();

		SickleComp.bCanActiveNextAttack = true;
		SickleComp.CurrentAttackAsset = nullptr;
		TargetComponent = nullptr;
		bLerpingToTarget = false;
		TranslateToTargetTime = 0;
		TimeLeftToDisableAlertedStance = 2.f;
		bAppliedGravityLastFrame = false;

		// Force the update so we might get a new point going into the next attack
		Player.UpdateActivationPointAndWidgets(USickleCuttableComponent::StaticClass());
	}  

	void StartAttackingEnemy(ASickleEnemy Enemy, FName CurrentComboTag)
	{
		// Enable the current combo tag on the enemy
		if(Enemy != nullptr && !Enemy.bIsBeeingHitBySickle)
		{
			Enemy.ActiveSickleComboTag = CurrentComboTag;
			Enemy.bIsBeeingHitBySickle = true;
			ActiveDamageTakers.Add(Enemy);
		}
	}

	void StopAttackingEnemy(ASickleEnemy Enemy)
	{
		if(Enemy != nullptr)
		{
			Enemy.ActiveSickleComboTag = NAME_None;
			Enemy.bIsBeeingHitBySickle = false;
			Enemy.bIsTakingSickleDamage = false;

			// Enable Vine impact if it was diabled by this
			auto VineImpact = UVineImpactComponent::Get(Enemy);
			if(VineImpact != nullptr)
				VineImpact.SetCanActivate(true, this);	
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void TriggerImpact(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMesh, UAnimNotify AnimNotify)
	{
		auto ImpactNotify = Cast<UAnimNotify_SickleTriggerImpact>(AnimNotify);
		FSickleImpactArc Arc;
		bool bDetach = true;

		if(ImpactNotify != nullptr)
		{
			Arc = ImpactNotify.IncludeAllEnemiesInRange;
			bDetach = ImpactNotify.bDetachPlayerIfAttached;
		}
		
		// Make Damage
		SickleComp.TriggerPendingControlImpact(Arc, this, n"Crumb_TriggerImpact");
		
		// Detach
		if(bDetach)
			DetachAttachmentActor();

		// Audio
		SickleComp.SickleActor.SetCapabilityActionState(n"AudioSickleSwing", EHazeActionState::ActiveForOneFrame);
		Player.MovementComponent.StopMovement();
	}

	UFUNCTION(NotBlueprintCallable)
	private void Crumb_TriggerImpact(const FHazeDelegateCrumbData& CrumbData)
	{	
		FSickleReplicatedImpact ReplicatedImpactData;
		CrumbData.GetStruct(n"ImpactData", ReplicatedImpactData);

		for(int i = 0; i < ReplicatedImpactData.Targets.Num(); ++i)
		{
			auto Target = ReplicatedImpactData.Targets[i];
			if(Target != nullptr)
			{
				auto EnemyComponent = USickleEnemyComponentBase::Get(Target.Owner);
				const bool bInvulerable = ReplicatedImpactData.Invulerable[i];
				const bool bCouldApplyDamage = Target.ApplyDamage(ReplicatedImpactData.DamageAmount, Player, bInvulerable);

				if(EnemyComponent != nullptr)
				{
					if(bCouldApplyDamage)
					{
						FRotator ImpactRotation = ReplicatedImpactData.ImpactDirections[i].Rotation();
						EnemyComponent.ApplyHitWithRotation(EnemyComponent.SickleImpact, ImpactRotation);
					}

					StartAttackingEnemy(Cast<ASickleEnemy>(EnemyComponent.Owner), ReplicatedImpactData.ComboTag);
				}			
			}
		}
	}

	void BlockMovement(bool bStatus)
	{
		if(bStatus)
		{
			bHasBlockedMovement = true;
			Player.BlockCapabilities(CapabilityTags::MovementInput, this);
			Player.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		}
		else if(bHasBlockedMovement)
		{
			bHasBlockedMovement = false;
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
			Player.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void AnimationFinished()
	{
		if(AnimationToStopAtEnd != nullptr)
		{	
			// Store in temp to fix recursion
			UAnimSequence Temp = AnimationToStopAtEnd;
			AnimationToStopAtEnd = nullptr;
			Player.StopAnimationByAsset(Temp);
			DetachAttachmentActor();
		}	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// We cant calculate movement the 1 frame because the other component has calculated movement
		if(MoveComp.CanCalculateMovement() && SickleComp.CurrentAttackAsset != nullptr)
		{
			FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(MovementName);
			MoveData.OverrideStepDownHeight(0.f);

			if(HasControl())
			{
				FHazeLocomotionTransform RootMotion;
				Player.RequestRootMotion(DeltaTime, RootMotion);

				// We only apply not forward rootmotion
				if(bLerpingToTarget)
				{
					AirJumpsComp.ResetJumpAndDash();
					FVector LocalRootMotion = Player.GetActorQuat().UnrotateVector(RootMotion.DeltaTranslation);
					if(LocalRootMotion.DotProduct(FVector::ForwardVector) < 0.5f)	
						MoveData.ApplyRootMotion(RootMotion, bApplyRotation = false);
				}
				else
				{
					if(!bCanApplyUpwardsRootmotion)
						RootMotion.DeltaTranslation.Z = 0;
			
					MoveData.ApplyRootMotion(RootMotion, bApplyRotation = false);
				}

				// Move the character to the target
				if(bLerpingToTarget)
				{
					const FVector TranslationDelta = UpdateTranslateToTarget(SickleComp.CurrentAttackAsset, DeltaTime);
					MoveData.ApplyDelta(TranslationDelta);
					MoveData.ApplyTargetRotationDelta();
					if(!bLerpingToTarget)
					{
						DetachAttachmentActor();
					}
				}
				else if(TargetComponent == nullptr)
				{
					MoveData.ApplyGravityAcceleration();
					MoveData.ApplyActorVerticalVelocity();
					MoveData.ApplyTargetRotationDelta();

					MoveData.ApplyVelocity(ControlSideUpForce);
					ControlSideUpForce = FVector::ZeroVector;
				}
				else if(TargetComponent.AttackMovementType == ESickleAttackMovementType::TranslateToAttackDistanceAndApplyGravity)
				{
					MoveData.ApplyGravityAcceleration();
					MoveData.ApplyActorVerticalVelocity();	
					MoveData.OverrideStepDownHeight(1.f);	
				}
				else if(bForceApplyGravity)
				{
					if(!bAppliedGravityLastFrame)
					{
						bAppliedGravityLastFrame = true;
						MoveComp.SetVelocity(FVector::ZeroVector);
					}

					MoveData.ApplyGravityAcceleration();
					MoveData.ApplyActorVerticalVelocity();	
					MoveData.OverrideStepDownHeight(1.f);	
				}

				MoveData.ApplyTargetRotationDelta();
			}
			else
			{
				FHazeActorReplicationFinalized Replication;
				CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, Replication);
				MoveData.ApplyConsumedCrumbData(Replication);
			}

			if(bHasBlockedMovement)
			{
				MoveComp.Move(MoveData);
				CrumbComp.LeaveMovementCrumb();
			}
		}

		if(IsActioning(n"SickleBreakOutIfDashing"))
		{
			if(WasActionStarted(ActionNames::MovementDash))
			{
				//BlockMovement(false);
				AnimationFinished();
			}
		}

		if(IsActioning(n"SickleBreakOutIfSteering"))
		{
			FVector2D InputRawStick = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
			if(InputRawStick.Size() > 0.5f)
			{
				//BlockMovement(false);
				AnimationFinished();
			}
		}
    }

	void InitializeTranslationToTarget(USickleCuttableComponent TargetComponent, USickleAttackDataAsset AttackAsset)
	{
		AHazeActor Target = Cast<AHazeActor>(TargetComponent.GetOwner());	
		if(Target == nullptr)
			return;

		TranslateToTargetTime = FMath::Max(AttackAsset.TranslateToTagetTime, KINDA_SMALL_NUMBER);
	
		// Start transform
		ControlSideActivationLocation = Player.GetActorLocation();
		LastLerpToLocation = ControlSideActivationLocation;
		const FVector TargetLocation = TargetComponent.GetPlayerAttackPosition(Player);
		
		bLerpingToTarget = true;
		bHasAttachedAttachmentActor = true;
		LerpToTargetActor.SetActorLocation(TargetLocation);	
	}	

	FVector UpdateTranslateToTarget(USickleAttackDataAsset AttackAsset, float DeltaTime)
	{
		const float CurrentTranslationTime = FMath::Min(ActiveDuration, TranslateToTargetTime);
		float LerpAlpha = CurrentTranslationTime / TranslateToTargetTime;
		bLerpingToTarget = LerpAlpha < 1.f;

		// Modify the lerp alpha if we have a curve
		if(AttackAsset.TranslationCruve.GetNumKeys() > 0)
		{
			// Translate the current time into cruve time
			FVector2D CurveTime;
			AttackAsset.TranslationCruve.GetTimeRange(CurveTime.X, CurveTime.Y);

			const FVector2D RealTime(0.f, 1.f);
			const float CurveTimeAlpha = FMath::GetMappedRangeValueUnclamped(RealTime, CurveTime, LerpAlpha);
			LerpAlpha = AttackAsset.TranslationCruve.GetFloatValue(CurveTimeAlpha);
		}

		const FVector ControlSideTargetLocation = LerpToTargetActor.GetActorLocation();
		const FVector WantedLocation = FMath::Lerp(ControlSideActivationLocation, ControlSideTargetLocation, LerpAlpha); 
		const FVector DeltaMove = WantedLocation - Player.GetActorLocation();
		LastLerpToLocation = WantedLocation;
		return DeltaMove;
	}

	void DetachAttachmentActor()
	{
		if(bHasAttachedAttachmentActor)
		{
			bHasAttachedAttachmentActor = false;
			bLerpingToTarget = false;
			auto Parent = LerpToTargetActor.GetAttachParentActor();
			if(Parent != nullptr)
			{
				Parent.OnEndPlay.UnbindObject(this);
				LerpToTargetActor.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);	
			}
		}	
	}

	void ApplyUpForce(USickleAttackDataAsset AttackAsset)
	{
		ControlSideUpForce = MoveComp.WorldUp * AttackAsset.UpForce;
	}
}


class USickleComboPerformNextCapability : USickleComboPerformCapability
{
	default TickGroupOrder = TickGroupOrder + 1;
	default MovementName = n"SickleAttackCombo";
}
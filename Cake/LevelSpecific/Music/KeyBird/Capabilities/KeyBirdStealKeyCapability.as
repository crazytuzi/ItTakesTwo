import Cake.LevelSpecific.Music.KeyBird.KeyBird;
import Vino.Movement.Components.MovementComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

/*
Triggered by KeyBirdApproachPlayerCapability, play the attack player animation and if it hits, take the key.
*/

class UKeyBirdStealKeyCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"KeyBirdStealKey");
	default CapabilityTags.Add(n"KeyBird");
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 3;

	FHazeAcceleratedVector AcceleratedTargetLocation;
	FVector TargetDirection;
	FVector StartLocation;

	AHazePlayerCharacter TargetPlayer;
	UKeyBirdBehaviorComponent BehaviorComp;
	USteeringBehaviorComponent Steering;
	UPatrolActorAudioComponent PatrolAudioComp;
	AKeyBird KeyBird;
	
	// This is basically the time in the animation until the hand has done enough of a swing motion.
	float TimeUntilAttack = 0.5f;
	float ElapsedAttack = 0.0f;
	float ElapsedTotal = 0.0f;
	float DistanceToTarget = 0.0f;

	bool bHitPlayer = false;
	bool bHasPerformedAttack = false;
	bool bTookKey = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		KeyBird = Cast<AKeyBird>(Owner);
		BehaviorComp = UKeyBirdBehaviorComponent::Get(Owner);
		Steering = USteeringBehaviorComponent::Get(Owner);
		PatrolAudioComp = UPatrolActorAudioComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(KeyBird.AttackAnim == nullptr)
			return EHazeNetworkActivation::DontActivate;
		
		if(KeyBird.TargetPlayer == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!KeyBird.bStartAttack)
			return EHazeNetworkActivation::DontActivate;

		if(KeyBird.IsDead())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"TargetPlayer", KeyBird.TargetPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PatrolAudioComp.HandleInteruption(false);
		StartLocation = Owner.ActorLocation;
		AcceleratedTargetLocation.SnapTo(Owner.ActorLocation);
		bHitPlayer = false;
		bTookKey = false;
		bHasPerformedAttack = false;
		ElapsedAttack = 0.0f;
		TargetPlayer = KeyBird.TargetPlayer;
		devEnsure(TargetPlayer != nullptr);
		const FVector DirectionTo = (TargetPlayer.ActorCenterLocation - KeyBird.ActorLocation);
		DistanceToTarget = DirectionTo.Size();
		const FRotator TargetFacingRotation = DirectionTo.GetSafeNormal().Rotation();
		KeyBird.MeshOffset.OffsetRotationWithTime(TargetFacingRotation, 0.1f);

		FHazePlaySlotAnimationParams Params;
		Params.Animation = KeyBird.AttackAnim;
		Params.BlendTime = 0.f;
		Params.BlendType = EHazeBlendType::BlendType_Crossfade;
		KeyBird.MeshBody.PlaySlotAnimation(Params);

		ElapsedTotal = KeyBird.AttackAnim.SequenceLength + 0.5f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ElapsedTotal -= DeltaTime;
		ElapsedAttack = FMath::Min(ElapsedAttack + DeltaTime, TimeUntilAttack);

		if(!bHasPerformedAttack)
		{
			const FVector TargetLocation = TargetPlayer.ActorCenterLocation;
			const float DistanceTotal = TargetLocation.Distance(StartLocation);
			const float TimeFraction = ElapsedAttack / TimeUntilAttack;
			const FVector DirectionToTarget = (TargetPlayer.ActorCenterLocation - StartLocation).GetSafeNormal();

			float DirectionDot = DirectionToTarget.DotProduct(KeyBird.MeshBody.ForwardVector);

			// Make sure that we have not been placed ahead of our target yet.
			if(DirectionDot > 0.0f)
			{
				const FVector NewLocation = StartLocation + DirectionToTarget * (DistanceToTarget * TimeFraction);
				Owner.SetActorLocation(NewLocation);
				KeyBird.MeshOffset.OffsetRotationWithTime(DirectionToTarget.Rotation(), 0.05f);
			}
			else
			{
				ElapsedAttack = TimeUntilAttack;
			}
		}
		else
		{
			Steering.VelocityMagnitude *= FMath::Pow(0.5f, DeltaTime);
			const FVector NewLocation = Owner.ActorLocation + KeyBird.MeshBody.ForwardVector * Steering.VelocityMagnitude * DeltaTime;
			Owner.SetActorLocation(NewLocation);
			if(!IsInsideCombatArea() || IsOverlappingObstacle())
				ElapsedTotal = 0.0f;
		}

		if(FMath::IsNearlyEqual(ElapsedAttack, TimeUntilAttack) && !bHasPerformedAttack && !KeyBird.IsDead())
		{
			Steering.bEnableLimitsBehavior = true;
			bHasPerformedAttack = true;
			if(!IsInsideCombatArea() || IsOverlappingObstacle())
				ElapsedTotal = 0.0f;
#if TEST
			if(KeyBird.CombatArea != nullptr && KeyBird.CombatArea.bCanStealKey)
#endif // TEST
			TakeKeyFromPlayer();
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ElapsedTotal <= 0.0f)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(KeyBird.IsDead())
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		KeyBird.bStartAttack = false;
		KeyBird.StartRandomMovement();
		PatrolAudioComp.FinishInteruption();

		if(HasControl() && !bTookKey)
		{
			NetFinishTakeKeyFromPlayer(TargetPlayer, false);
		}
	}

	private void TakeKeyFromPlayer()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = KeyBird.TargetPlayer.IsMay() ? KeyBird.HitMayAnim : KeyBird.HitCodyAnim;
		KeyBird.TargetPlayer.PlaySlotAnimation(Params);
		

		if(HasControl())	// Still same control side as the target player.
		{
			UMusicKeyComponent PlayerKeyComp = UMusicKeyComponent::Get(TargetPlayer);
			AMusicalFollowerKey KeyTarget = PlayerKeyComp.FirstKey;
			
			if(KeyTarget != nullptr && KeyTarget.MusicKeyState != EMusicalKeyState::GoToLocation)
			{
				PlayerKeyComp.DropAllKeys();	// This will also clear follow target on the MusicalFollowerKey.

				if(KeyTarget != nullptr)
				{
					KeyTarget.AddPendingFollowTarget(Owner);
				}
				
				TargetPlayer.PlayForceFeedback(KeyBird.HitPlayerFeedback, false, false, NAME_None);
				float DamageAmount = KeyBird.DamageAmount;
#if TEST
				EGodMode GodMode = GetGodMode(TargetPlayer);
				if(GodMode != EGodMode::Mortal)
				{
					DamageAmount = 0.0f;
				}
#endif // TEST

				TargetPlayer.DamagePlayerHealth(DamageAmount, KeyBird.PlayerDamageEffect, KeyBird.PlayerDeathEffect);
				bTookKey = true;
				NetFinishTakeKeyFromPlayer(TargetPlayer, true);
			}
		}
	}

	UFUNCTION(NetFunction)
	private void NetFinishTakeKeyFromPlayer(AHazePlayerCharacter InPlayer, bool bSuccess)
	{
		BehaviorComp.OnKeyBirdStealKeyStop.Broadcast(KeyBird, InPlayer, true);
		KeyBird.CombatArea.Handle_KeyBirdStealKeyStop(KeyBird, InPlayer, true);
	}

	bool IsOverlappingObstacle() const
	{
		return IsPointOverlappingBoidObstacle(Owner.ActorCenterLocation);
	}

	bool IsInsideCombatArea() const
	{
		return KeyBird.CombatArea.Shape.IsPointOverlapping(Owner.ActorCenterLocation);
	}
}

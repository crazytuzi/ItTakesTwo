import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusArm;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusActor;

event void FOnSlamActivated();
event void FOnSlamDeactivated();
event void FOnSlamCharged();

UCLASS(Abstract)
class APirateOctopusSlam : APirateOctopusArm
{
	// UPROPERTY(DefaultComponent, Attach = OctoArm)
	// UStaticMeshComponent MeshCompTemp;

	UPROPERTY(DefaultComponent, Attach = OctoArm)
	UNiagaraComponent DynamiteSystem;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent PirateOctopusSlamHitPlayerEvent;

	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams SlamAnim;

	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams MoveDownAnim;

	UPROPERTY(Category = "Slam")
	int AnticipationLoopTimes = 2;

	UPROPERTY(Category = "Slam")
	float SlamImpactDelay = 2.15f;

	UPROPERTY(Category = "Slam")
	float DamageAmount = 5.f;

	float CustomDamageAmount = 4.0f;

	UPROPERTY(Category = "Slam")
	float SlamRange = 6000.f;

	bool bWaitingForHit;

	UPROPERTY(NotEditable)
	bool bGettingReadyToSlam;

	float ChargingTimer;
	float DefaultChargingTimer = 9.f;

	UPROPERTY(Category = "Events")
	FOnSlamActivated OnSlamActivated;

	UPROPERTY(Category = "Events")
	FOnSlamActivated OnSlamCharged;

	UPROPERTY(Category = "Events")
	FOnSlamDeactivated OnSlamDeactivated;

	APirateOctopusThirdArmSlamLocation ChosenLoc;

	// If 0.f - 1.f, it will make the arm stop facing the boat
	UPROPERTY(Category = "Slam")
	float StopFacingBoatAnimationAlpha = -1;

	APirateOctopusActor Boss;
	FTimerHandle FaceBoatStopTimer;
	FTimerHandle SlamImpactTimer;
	FTimerHandle DoneChargingTimer;
	FHazePlaySlotAnimationParams CurrentAnimPlaying;

	bool bCanCount;
	UPROPERTY(NotEditable)
	float AnimationTime;

	bool bIsBeingHit = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay() override
	{
		Super::BeginPlay();
		AddCapability(n"PirateOctopusArmFollowBoatCapability");
		ChargingTimer = DefaultChargingTimer;
		bWaitingForHit = true;
		CannonBallDamageableComponent.OnCannonBallHit.AddUFunction(this, n"OnTentacleHit");

		if(!FollowBoatComponent.bFollowBoat)
			DamageAmount = CustomDamageAmount;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bIsRepeatableSlam)
			ChargingPlayerRangeCheck(DeltaTime);

		if (bCanCount)
		{
			AnimationTime -= DeltaTime;

			if (AnimationTime <= 0.f)
			{
				bCanCount = false;
				DoneCharging();
			}
		}
	}

	UFUNCTION()
	void OnTentacleHit(FHitResult Hit)
	{
		if (HitAnim.Animation != nullptr && CannonBallDamageableComponent.CurrentHealth > 0 && !bGettingReadyToSlam)
			OctoArm.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"AnticipationAnimation"), HitAnim);
	}

	void ChargingPlayerRangeCheck(float DeltaTime)
	{
		if (!bWaitingForHit)
			return;

		if(bIsBeingHit)
			return;

		ChargingTimer -= DeltaTime;


		if (ChargingTimer <= 0.f)
		{
			if (CanApplyDamage() && HasControl())
			{
				NetSetDoneCharing();
			}
			else
			{
				ChargingTimer = DefaultChargingTimer;
			}
		}
	}

	

	void Initialize(AHazeActor BossActor, UHazeSplineComponent Stream) override
	{
		Boss = Cast<APirateOctopusActor>(BossActor);
		Super::Initialize(BossActor, Stream);
	}

	void ActivateArm() override
	{
		Super::ActivateArm();
		Boss.ArmAttackStarted(this);
		OnSlamActivated.Broadcast();

		FollowBoatComponent.bFollowBoat = true;

		CannonBallDamageableComponent.DisableDamageTaking();

		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;

		CurrentAnimPlaying = ChargeAnim;

		//If first time, play this, otherwise play a different blend
		OctoArm.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"AnticipationAnimation"), ChargeAnim);
		ChargingTimer = DefaultChargingTimer;

	}

	UFUNCTION(NotBlueprintCallable)
	void AnticipationAnimation()
	{
		if(bGettingReadyToSlam)
			return;

		CannonBallDamageableComponent.EnableDamageTaking();
		ArmCollider.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;

		if(bIsBeingHit)
			return;

		bAttacking = true;
		
		if(AnticipationLoopTimes >= 0)
		{
			AnimationTime = MHAnim.PlayLength * AnticipationLoopTimes;
			AnimationTime -= GetActorDeltaSeconds();

			if (!bIsRepeatableSlam)
			{
				bCanCount = true;
			}

			if(StopFacingBoatAnimationAlpha >= 0)
			{
				FaceBoatStopTimer = System::SetTimer(this, n"StopFacingBoat", AnimationTime * FMath::Min(StopFacingBoatAnimationAlpha , 1.f), false);
			}
		}

		CurrentAnimPlaying = MHAnim;
		OctoArm.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), MHAnim);
	}

	UFUNCTION(NetFunction)
	void NetSetDoneCharing()
	{
		DoneCharging();
		bWaitingForHit = false;
	}

	UFUNCTION(NotBlueprintCallable)
	void StopFacingBoat()
	{
		FollowBoatComponent.bFaceBoat = false;
	}

	UFUNCTION(NotBlueprintCallable)
	void DoneCharging()
	{
		Boss.PlaySlammingAnim();

		bGettingReadyToSlam = true;
		
		CurrentAnimPlaying = SlamAnim;	

		OctoArm.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"DoneSlamming"), SlamAnim);

		SlamImpactTimer = System::SetTimer(this, n"TriggerArmEffect", SlamImpactDelay, false);
		OnSlamCharged.Broadcast();
	}

	UFUNCTION(NotBlueprintCallable)
	void DoneSlamming()
	{
		bGettingReadyToSlam = false;

		if(bIsBeingHit)
			return;

		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;

		CurrentAnimPlaying = MoveDownAnim;	

		if (bIsRepeatableSlam)
		{
			OctoArm.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"AnticipationAnimation"), MHAnim);
			FollowBoatComponent.bFaceBoat = true;
			ArmCollider.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
			ArmOverlapCollider.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
			CannonBallDamageableComponent.EnableDamageTaking();
			bWaitingForHit = true;
			ChargingTimer = DefaultChargingTimer;
		}		
		else
		{
			ArmCollider.CollisionEnabled = ECollisionEnabled::NoCollision;
			ArmOverlapCollider.CollisionEnabled = ECollisionEnabled::NoCollision;
			OctoArm.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"FinishAttack"), MoveDownAnim);
		}

	}

	void OnArmEffectTriggered() override
	{
		Super::OnArmEffectTriggered();
		
		if(CanApplyDamage() && HasControl())
		{
			NetApplyDamageToBoat();
		}
	}

	UFUNCTION(NetFunction)
	void NetApplyDamageToBoat()
	{
		if(PlayerTarget != nullptr)
		{
			PlayerTarget.BoatWasHit(DamageAmount, EWheelBoatHitType::TentacleSlam);
			Boss.ArmAttackHitPlayer(this);

			if(PirateOctopusSlamHitPlayerEvent != nullptr)
			{
				HazeAkComp.HazePostEvent(PirateOctopusSlamHitPlayerEvent);
			}
		}
	}

	bool CanApplyDamage()const
	{
		float DistanceToPlayer = (ActorLocation - PlayerTarget.ActorLocation).Size();

		if (PlayerTarget.bIsAirborne)
			return false;
		else
			return DistanceToPlayer > SlamRange ? false : true;
	}

	void HitByCannonBall() override
	{
		bIsBeingHit = true;
		ChargingTimer = DefaultChargingTimer;

		CannonBallDamageableComponent.DisableDamageTaking();

		System::ClearAndInvalidateTimerHandle(DoneChargingTimer);
		System::ClearAndInvalidateTimerHandle(FaceBoatStopTimer);
		System::ClearAndInvalidateTimerHandle(SlamImpactTimer);
		
		ClearSlotAnimBlendingOutDelegate(CurrentAnimPlaying.Animation);

		Boss.ArmHitByCannonBall(this);

		bCanCount = false;
				
		ArmCollider.CollisionEnabled = ECollisionEnabled::NoCollision;
		ArmOverlapCollider.CollisionEnabled = ECollisionEnabled::NoCollision;

		OctoArm.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), HitAnim);
		
		System::SetTimer(this, n"DelayedMoveDownAnim", 0.5f, false);

		System::ClearTimer(this, n"DoneCharging");
		System::ClearTimer(this, n"TriggerArmEffect");

		bIsBeingHit = false;
	}

	UFUNCTION()
	void DelayedMoveDownAnim()
	{
		OctoArm.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"FinishAttack"), MoveDownAnim);
	}

	void FinishAttack() override
	{
		System::ClearAndInvalidateTimerHandle(FaceBoatStopTimer);
		OnSlamDeactivated.Broadcast();
		OnSlamCharged.Clear();
		Super::FinishAttack();

		bGettingReadyToSlam = false;

		System::ClearAndInvalidateTimerHandle(DoneChargingTimer);
		System::ClearAndInvalidateTimerHandle(FaceBoatStopTimer);
		System::ClearAndInvalidateTimerHandle(SlamImpactTimer);

		System::ClearTimer(this, n"DelayedMoveDownAnim");
		System::ClearTimer(this, n"DoneCharging");
		System::ClearTimer(this, n"TriggerArmEffect");

		if (Boss != nullptr)
			Boss.ArmAttackFinished(this);
		
		if (ChosenLoc != nullptr)
			ChosenLoc.bIsActive = false;

		if (bIsRepeatableSlam)
		{
			if (!Boss.SlamPhaseThreeComplete())
				Boss.IncrementSlamPhaseThreeKillCount();
			else
				Boss.OnThirdPhaseAllArmsKilled.Broadcast();
		}
	}
}

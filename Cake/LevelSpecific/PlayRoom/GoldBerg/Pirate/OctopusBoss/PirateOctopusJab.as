import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusArm;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusActor;

event void FOnJabActivated();
event void FOnJabDeactivated();

UCLASS(Abstract)
class APirateOctopusJab : APirateOctopusArm
{
	UPROPERTY(Category = "Audio")
	UAkAudioEvent PirateOctopusJabHitPlayerEvent;

	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams JabAnim;
	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams MoveDownAnim;

	UPROPERTY(Category = "Jab")
	int AnticipationLoopTimes = 2;

	UPROPERTY(Category = "Jab")
	float JabImpactDelay = 1.50f;

	UPROPERTY(Category = "Jab")
	float DamageAmount = 0.f;

	UPROPERTY(Category = "Jab")
	float SpinForce = 200.f;

	UPROPERTY(Category = "Jab")
	float SpinAmount = 500.f;

	UPROPERTY()
	FOnJabActivated OnJabActivated;
	UPROPERTY()
	FOnJabDeactivated OnJabDeactivated;

	APirateOctopusActor Boss;
	bool bSkipAnticipation = false;
	FTimerHandle JabImpactTimer;
	FTimerHandle DoneChargingTimer;
	FHazePlaySlotAnimationParams CurrentAnimPlaying;

	UFUNCTION(BlueprintOverride)
	void BeginPlay() override
	{
		Super::BeginPlay();
		AddCapability(n"PirateOctopusArmFollowBoatCapability");
	}

	UFUNCTION()
	void Initialize(AHazeActor BossActor, UHazeSplineComponent Stream) override
	{
		Boss = Cast<APirateOctopusActor>(BossActor);
		Super::Initialize(BossActor, Stream);
	}

	void ActivateArm() override
	{
		Super::ActivateArm();
		Boss.ArmAttackStarted(this);	
		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		float AnimationTime = ChargeAnim.PlayLength - ChargeAnim.BlendTime;
		//AnimationTimerHandler = System::SetTimer(this, n"AnticipationAnimation", AnimationTime, false);
		CurrentAnimPlaying = ChargeAnim;
		OctoArm.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"AnticipationAnimation"), ChargeAnim);
		OnJabActivated.Broadcast();
	}
	
	UFUNCTION(NotBlueprintCallable)
	void AnticipationAnimation()
	{
		CannonBallDamageableComponent.EnableDamageTaking();
		bAttacking = true;

		if(bSkipAnticipation)
		{
			DoneCharging();
		}
		else
		{
			CannonBallDamageableComponent.EnableDamageTaking();
			float AnimationTime = MHAnim.PlayLength * AnticipationLoopTimes;
			AnimationTime -= GetActorDeltaSeconds();
			DoneChargingTimer = System::SetTimer(this, n"DoneCharging", AnimationTime, false);
			CurrentAnimPlaying = MHAnim;
			OctoArm.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), MHAnim);
		}
	}
	
	UFUNCTION(NotBlueprintCallable)
	void DoneCharging()
	{
		Boss.PlayJabbingAnim();

		//AnimationTimerHandler = System::SetTimer(this, n"DoneJabbing", JabAnim.PlayLength, false);
		CurrentAnimPlaying = JabAnim;
		OctoArm.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"DoneJabbing"), JabAnim);
		JabImpactTimer = System::SetTimer(this, n"TriggerArmEffect", JabImpactDelay, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void DoneJabbing()
	{
		//AnimationTimerHandler = System::SetTimer(this, n"FinishAttack", MoveDownAnim.PlayLength, false);

		OnJabDeactivated.Broadcast();

		ArmCollider.CollisionEnabled = ECollisionEnabled::NoCollision;
		ArmOverlapCollider.CollisionEnabled = ECollisionEnabled::NoCollision;
		CurrentAnimPlaying = MoveDownAnim;
		OctoArm.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"FinishAttack"), MoveDownAnim);
	}

	void OnArmEffectTriggered() override
	{
		//bCanTakeDamage = false;
		Super::OnArmEffectTriggered();

		if(!bSkipAnticipation)
			PlayerTarget.BoatWasHit(DamageAmount, EWheelBoatHitType::NoReaction);
			
		PlayerTarget.StartSpinning(bPositionedLeft, SpinForce, SpinAmount);
		Boss.ArmAttackHitPlayer(this);

		if(PirateOctopusJabHitPlayerEvent != nullptr)
		{
			HazeAkComp.HazePostEvent(PirateOctopusJabHitPlayerEvent);
		}
	}

	void HitByCannonBall() override
	{	
		CannonBallDamageableComponent.DisableDamageTaking();
		System::ClearAndInvalidateTimerHandle(DoneChargingTimer);
		System::ClearAndInvalidateTimerHandle(JabImpactTimer);
		ClearSlotAnimBlendingOutDelegate(CurrentAnimPlaying.Animation);

		OnJabDeactivated.Broadcast();

		Boss.ArmHitByCannonBall(this);
		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		//AnimationTimerHandler = System::SetTimer(this, n"FinishAttack", MoveDownAnim.PlayLength, false);
		ArmCollider.CollisionEnabled = ECollisionEnabled::NoCollision;
		ArmOverlapCollider.CollisionEnabled = ECollisionEnabled::NoCollision;
		OctoArm.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"FinishAttack"), MoveDownAnim);
	}

	void FinishAttack() override
	{
		bSkipAnticipation = false;
		Super::FinishAttack();
		Boss.ArmAttackFinished(this);
	}
}
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusArm;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusActor;
import Peanuts.Spline.SplineComponent;

UCLASS(Abstract)
class APirateOctopusStreamArm : APirateOctopusArm
{
	UPROPERTY(Category = "Audio")
	UAkAudioEvent PirateOctopusStreamArmHitPlayerEvent;

	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams MoveDownAnim;

	default FollowBoatComponent.DistanceOffset = 14500;

	float DamageAmount = 3.f;

	APirateOctopusActor Boss;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay() override
	{
		Super::BeginPlay();
		AddCapability(n"PirateOctopusArmFollowBoatCapability");

	}

	void Initialize(AHazeActor BossActor, UHazeSplineComponent Stream) override
	{
		Boss = Cast<APirateOctopusActor>(BossActor);
		Super::Initialize(BossActor, Stream);
		//TotalDistance = StreamSpline.GetSplineLength();
	}

	void ActivateArm() override
	{
		Super::ActivateArm();
		Boss.ArmAttackStarted(this);
		FollowBoatComponent.bFollowBoat = false;
		CannonBallDamageableComponent.DisableDamageTaking();

		//AnimationTimerHandler = System::SetTimer(this, n"DoneCharging", ChargeAnim.PlayLength, false);
		OctoArm.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"DoneCharging"), ChargeAnim);
	}

	UFUNCTION(NotBlueprintCallable)
	void DoneCharging()
	{
		bAttacking = true;
		CannonBallDamageableComponent.EnableDamageTaking();
		OctoArm.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), MHAnim);
	}

	// UFUNCTION()
	// void FindTargetPositionAndRotation()
	// {
	// 	FHazeSplineSystemPosition StreamPosition = TargetBoat.StreamComponent.LockedStream.Spline.GetPositionClosestToWorldLocation(TargetBoat.ActorLocation, true);
	// 	StreamPosition.Move(TargetDistanceOffset);
	// 	TargetLocation = StreamPosition.WorldLocation;
	// 	TargetLocation.Z -= ZOffset;
	// 	TargetRotation = StreamPosition.WorldRotation;
	// 	FVector Backwards = -TargetRotation.GetForwardVector();
	// 	TargetRotation = Backwards.Rotation();
	// }

	void OnArmEffectTriggered() override
	{
		Super::OnArmEffectTriggered();
		PlayerTarget.BoatWasHit(DamageAmount, EWheelBoatHitType::TentacleSlam);
		Boss.ArmAttackHitPlayer(this);

		if(PirateOctopusStreamArmHitPlayerEvent != nullptr)
		{
			HazeAkComp.HazePostEvent(PirateOctopusStreamArmHitPlayerEvent);
		}

		FollowBoatComponent.bFollowBoat = true;
		//AnimationTimerHandler = System::SetTimer(this, n"FinishAttack", MoveDownAnim.PlayLength, false);
		OctoArm.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"FinishAttack"), MoveDownAnim);
	}


	void HitByCannonBall() override
	{	
		Boss.ArmHitByCannonBall(this);
		CannonBallDamageableComponent.DisableDamageTaking();
		FollowBoatComponent.bFollowBoat = true;
		
		//AnimationTimerHandler = System::SetTimer(this, n"FinishAttack", MoveDownAnim.PlayLength, false);
		OctoArm.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"FinishAttack"), MoveDownAnim);
	}	

	void FinishAttack() override
	{
		Super::FinishAttack();
		Boss.ArmAttackFinished(this);
		FollowBoatComponent.bFollowBoat = false;
	}

}
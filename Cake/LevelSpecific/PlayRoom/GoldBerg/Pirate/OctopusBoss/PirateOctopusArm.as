import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.CannonBallDamageableComponent;
import Peanuts.Aiming.AutoAimTarget;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusArmFollowBoatComponent;

//import void OnPointTargeted(UTimeControlActorComponent) from "Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlLinkedActor";
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.PirateEnemyComponent;

// event void FOnOctopusArmAttackFinished();
// event void FOnOctopusArmHitPlayer();
// event void FOnOctopusArmHitByCannonBall();
// event void FOnOctopusArmChargeDone();

UCLASS(Abstract)
class APirateOctopusArm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ArmBase;

	UPROPERTY(DefaultComponent, Attach = ArmBase)	
	UHazeOffsetComponent ArmVisualOffset;

	UPROPERTY(DefaultComponent, Attach = ArmVisualOffset)
	UHazeSkeletalMeshComponentBase OctoArm;

	UPROPERTY(DefaultComponent, Attach = ArmBase)
	UCapsuleComponent ArmCollider;
	default ArmCollider.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = ArmBase)
	UCapsuleComponent ArmOverlapCollider;
	default ArmOverlapCollider.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UCannonBallDamageableComponent CannonBallDamageableComponent;
	default CannonBallDamageableComponent.MaximumHealth = 3;

	UPROPERTY(DefaultComponent)
	UAutoAimTargetComponent AutoAimTarget;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UPirateOctopusArmFollowBoatComponent FollowBoatComponent;

	UPROPERTY(DefaultComponent)
	UPirateEnemyComponent EnemyComponent;

	float EmergeOffset = 2000.f;
	AHazeActor OctopusBoss;
		
	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams ChargeAnim;

	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams RepeatableChargeAnim;

	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams MHAnim;
	default MHAnim.bLoop = true;

	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams HiddenAnim;

	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams HitAnim;

	bool bAttacking = false;

	// Network
	float ExpectedTriggerEffectTime = 0;
	int EffectAmount = 0;
	int OtherSideEffectAmount = 0;

	UPROPERTY(NotEditable)
	bool bPositionedLeft = false;

	bool bIsRepeatableSlam;

	UHazeSplineComponent ActivatedStreamSpline = nullptr;

	//FTimerHandle AnimationTimerHandler;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CannonBallDamageableComponent.HealthWidgetAttachComponent = ArmBase;
		CannonBallDamageableComponent.OnExploded.AddUFunction(this, n"HitByCannonBall");
		HazeAkComp.SetStopWhenOwnerDestroyed(false);
		AutoAimTarget.AttachToComponent(OctoArm, n"Tentacle5", EAttachmentRule::SnapToTarget);
		EnemyComponent.AddBeginOverlap(ArmOverlapCollider, this, n"OnComponentBeginOverlap");
		AddCapability(n"PirateShipHealthBarCapability");
		FName TentacleSocket = OctoArm.GetSocketBoneName(n"Tentacle8");
		const bool Attached = HazeAkComp.AttachTo(OctoArm, TentacleSocket);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		
	}

	UFUNCTION()
	void Initialize(AHazeActor BossActor, UHazeSplineComponent Stream)
	{
		OctopusBoss = BossActor;
		
		if (Stream != nullptr)
		{
			FollowBoatComponent.ActivateSplineMovement(Stream, true);
			ActivatedStreamSpline = Stream;
		}
		
		HideArm();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(OtherSideEffectAmount > EffectAmount)
		{
			if(Time::GetGameTimeSeconds() >= ExpectedTriggerEffectTime)
			{
				TriggerInvalidArmEffectInternal();
			}
		}
	}

	void SetArmPosition(bool PositionedLeft, float CustomOffsetDistance = -1, float CustomLerpTime = -1)	
	{
		bPositionedLeft = PositionedLeft;
		FHazeSplineSystemPosition FoundPosition;
		FollowBoatComponent.UpdateSplineMovement(EnemyComponent.WheelBoat.GetActorLocation(), FoundPosition);

		float DistanceToPeek = FollowBoatComponent.DistanceOffset;
		if(CustomOffsetDistance >= 0)
			DistanceToPeek = CustomOffsetDistance;

		if(!bPositionedLeft)
			DistanceToPeek = -DistanceToPeek;

		EHazeUpdateSplineStatusType PeekStatus;
		FoundPosition = FollowBoatComponent.PeekPosition(DistanceToPeek, PeekStatus);
		SetArmPosition(FoundPosition.WorldLocation, CustomLerpTime);
		FollowBoatComponent.UpdateSplineMovementFromPosition(FoundPosition);
	}

	void SetArmPosition(FVector WorldPosition, float CustomLerpTime = -1)
	{
		FVector WantedWorldLocation = GetWantedWorldPosition(WorldPosition);
		FVector OffsetVector = WantedWorldLocation;
		OffsetVector.Z -= EmergeOffset + FollowBoatComponent.ZOffset;

		FRotator WantedRotation = FollowBoatComponent.FindRotationTowardsTarget(WantedWorldLocation, EnemyComponent.WheelBoat);
		SetActorLocationAndRotation(OffsetVector, WantedRotation);
		if(CustomLerpTime != 0.f)
		{
			if(CustomLerpTime > 0)
				ArmVisualOffset.FreezeAndResetWithTime(CustomLerpTime);
			else
				ArmVisualOffset.FreezeAndResetWithTime(0.5f);
		}


		FVector FinalWorldLocation = WantedWorldLocation;
		FinalWorldLocation.Z -= FollowBoatComponent.ZOffset;
		SetActorLocation(FinalWorldLocation);
	}

	FVector GetWantedWorldPosition(FVector WorldPosition) const
	{
		return WorldPosition;
	}

	void ActivateArm()
	{
		ArmOverlapCollider.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
		ArmCollider.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
		ArmOverlapCollider.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
		AutoAimTarget.bIsAutoAimEnabled = true;
		CannonBallDamageableComponent.EnableDamageTaking();
		
		if (IsActorDisabled())
			EnableActor(this);
	}

	
	UFUNCTION(NotBlueprintCallable)
	protected void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AWheelBoatActor Boat)
	{	
		if(bAttacking)
		{
			TriggerArmEffect();
		}
	}

	// Will call the effect localy and if not happend on the other side, there too
	UFUNCTION(NotBlueprintCallable)
	void TriggerArmEffect()
	{
		NetTriggerValidArmEffectInternal(HasControl(), EffectAmount + 1);
	}

	// Override in the arms
	void OnArmEffectTriggered()
	{
		ArmOverlapCollider.CollisionEnabled = ECollisionEnabled::NoCollision;
		CannonBallDamageableComponent.DisableDamageTaking();
	}

	UFUNCTION(NetFunction)
	void NetTriggerValidArmEffectInternal(bool bSendFromControl, int WantedArmEffectCount)
	{
		if(HasControl() == bSendFromControl)
		{
			if(WantedArmEffectCount == EffectAmount + 1)
			{
				EffectAmount++;
				
				// if (!bIsRepeatableSlam)
				OnArmEffectTriggered();
			}	
		}
		else
		{
			if(WantedArmEffectCount == EffectAmount + 1)
			{
				ExpectedTriggerEffectTime = Time::GetGameTimeSeconds() + 3.f;
			}

			OtherSideEffectAmount++;
		}	
	}

	void TriggerInvalidArmEffectInternal()
	{
		EffectAmount++;
		OnArmEffectTriggered();
		ExpectedTriggerEffectTime = Time::GetGameTimeSeconds() + 3.f;
	}

	UFUNCTION(NotBlueprintCallable)
	void HitByCannonBall()
	{
		ArmOverlapCollider.CollisionEnabled = ECollisionEnabled::NoCollision;
		FinishAttack();
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishAttack()
	{
		bAttacking = false;
		FollowBoatComponent.bFollowBoat = true;
		FollowBoatComponent.bFaceBoat = true;
		HideArm();		
	}

	private void HideArm()
	{
		ArmCollider.CollisionEnabled = ECollisionEnabled::NoCollision;
		ArmOverlapCollider.CollisionEnabled = ECollisionEnabled::NoCollision;
		AutoAimTarget.bIsAutoAimEnabled = false;
				
		OctoArm.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), HiddenAnim);
		CannonBallDamageableComponent.ResetAfterExploding();
		CannonBallDamageableComponent.DisableDamageTaking();
		OctoArm.HazeForceUpdateAnimation(true);
		
		if (!IsActorDisabled())
			DisableActor(this);
	}

	AWheelBoatActor GetPlayerTarget() const property
	{
		return EnemyComponent.WheelBoat;
	}
}
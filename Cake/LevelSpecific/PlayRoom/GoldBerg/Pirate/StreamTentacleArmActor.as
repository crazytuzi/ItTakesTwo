
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.CannonBallDamageableComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.PirateEnemyComponent;


event void FOnStreamArmActivated();
event void FOnStreamArmDeactivated();


UCLASS(Abstract)
class AStreamTentacleArmActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ArmBase;

	UPROPERTY(DefaultComponent, Attach = ArmBase)
	UHazeSkeletalMeshComponentBase OctoArm;

	UPROPERTY(DefaultComponent, Attach = ArmBase)
	UCapsuleComponent ArmCollider;
	default ArmCollider.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent DetectionCollider;
	default DetectionCollider.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UCannonBallDamageableComponent CannonBallDamageableComponent;
	default CannonBallDamageableComponent.HealthBarDisappearDelay = 1.0f;

	UPROPERTY(DefaultComponent)
	UPirateEnemyComponent EnemyComponent;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 20000.f;
	default DisableComponent.bRenderWhileDisabled = false;

	UPROPERTY(DefaultComponent, NotEditable)
	UHazeAkComponent HazeAkComp;

	UPROPERTY()
	APirateOceanStreamActor StreamSpline;

	UPROPERTY()
	bool bBoundToStreamSpline = false;	

	UPROPERTY(NotEditable)
	bool bActive = false;

	UPROPERTY()
	FOnStreamArmActivated OnStreamArmActivated;

	UPROPERTY()
	FOnStreamArmDeactivated OnStreamArmDeactivated;

	// FTimerHandle AnimationTimerHandler;
	
	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams EmergeAnim;
	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams SubmergeAnim;
	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams MHAnim;
	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams SlamAnim;

	bool bAttacking = false;

	// UPROPERTY(Category = "Slam")
	// int AnticipationLoopTimes = 2;

	// UPROPERTY(Category = "Slam")
	// float SlamImpactDelay = 2.1f;

	UPROPERTY(Category = "Slam")
	float DamageAmount = 3.f;

	bool bSubmerging = false;

	FHazeAnimationDelegate OnBlendingOutSlam;	

	FHazeAcceleratedRotator AccelRot;

	TArray<AWheelBoatActor> LookTargetArray;
	AWheelBoatActor BoatLookTarget;

	bool bCanTimer;
	float Timer = 2.15f;
	float SlamRange = 6000.f;
	float StartingSlamMinRange = 6500.f;/*4750.f;*/

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
	{
		EnemyComponent.Shapes.Reset(1);
		EnemyComponent.AddBeginOverlap(DetectionCollider, this, n"OnDetected");
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OctoArm.SetHiddenInGame(true, false);
		CannonBallDamageableComponent.OnExploded.AddUFunction(this, n"HitByCannonBall");

		EnemyComponent.RotationRoot = Root;
		AddCapability(n"PirateEnemyFaceWheelBoatCapability");
		AddCapability(n"PirateTowerHealthBarCapability");

		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		FHazePlaySlotAnimationParams HiddenAnim;
		HiddenAnim = EmergeAnim;
		HiddenAnim.PlayRate = 0.0f;

		OctoArm.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, HiddenAnim);	

		AccelRot.SnapTo(ActorRotation);

		GetAllActorsOfClass(LookTargetArray);
		
		if (LookTargetArray.Num() > 0)
			BoatLookTarget = LookTargetArray[0];

		FName TentacleSocket = OctoArm.GetSocketBoneName(n"Tentacle8");
		const bool Attached = HazeAkComp.AttachTo(OctoArm, TentacleSocket);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnDetected(UPrimitiveComponent OverlappedComponent, AWheelBoatActor Boat)
	{
		if(Boat == nullptr)
			return;

		if(bBoundToStreamSpline)
		{
			if(Boat.StreamComponent.LockedStream != StreamSpline)
				return;
		}
		
		DetectionCollider.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		ActivateArm();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!bActive)
			return;

		FVector LookDirection = BoatLookTarget.ActorLocation - ActorLocation;
		LookDirection.Normalize();
		FRotator LookRot = FRotator::MakeFromX(LookDirection);
		AccelRot.AccelerateTo(LookRot, 1.f, DeltaTime);
		SetActorRotation(AccelRot.Value);

		if(!bAttacking)
		{
			float DistanceToBoat = (EnemyComponent.WheelBoat.ActorLocation - ActorLocation).DotProduct(ActorForwardVector);

			if(DistanceToBoat <= StartingSlamMinRange)
			{
				bAttacking = true;
				Slam();
			}
		}

		if (bCanTimer)
		{
			Timer -= DeltaTime;

			if (Timer <= 0.f)
			{
				bCanTimer = false;
				if(CanApplyDamage())
					HitBoat();
			}
		}
	}

	UFUNCTION()
	void ActivateArm()
	{
		if(!bActive)
		{
			OctoArm.SetHiddenInGame(false, false);

			CannonBallDamageableComponent.DisableDamageTaking();
			FHazeAnimationDelegate OnBlendingIn;
			FHazeAnimationDelegate OnBlendingOut;
			OnBlendingOut.BindUFunction(this, n"AnticipationAnimation");
			OctoArm.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, EmergeAnim);
			bActive = true;
			EnemyComponent.bFacePlayer = true;
			bCanTimer = false;
			OnStreamArmActivated.Broadcast();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void AnticipationAnimation()
	{
		CannonBallDamageableComponent.EnableDamageTaking();

		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;

		OctoArm.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, MHAnim);
	}

	UFUNCTION()
	void Slam()
	{
		// if(CannonBallDamageableComponent.CanTakeDamage())
		// 	return;

		FHazeStopSlotAnimationParams Params;
		OctoArm.StopSlotAnimation(Params);
		
		FHazeAnimationDelegate OnBlendingIn;

		OnBlendingOutSlam.BindUFunction(this, n"DoneSlamming");
		OctoArm.PlaySlotAnimation(OnBlendingIn, OnBlendingOutSlam, SlamAnim);
		
		//Timer = SlamAnim.PlayLength;
		bCanTimer = true;
		// AnimationTimerHandler = System::SetTimer(this, n"HitBoat", SlamImpactDelay, false);
	}

	bool CanApplyDamage()const
	{
		float DistanceToPlayer = (ActorLocation - EnemyComponent.WheelBoat.ActorLocation).Size();
		
			return DistanceToPlayer > SlamRange ? false : true;
	}

	UFUNCTION()
	void HitBoat()
	{
		EnemyComponent.WheelBoat.BoatWasHit(DamageAmount, EWheelBoatHitType::TentacleSlam);
		ArmCollider.SetCollisionResponseToChannel(ECollisionChannel::ECC_Vehicle, ECollisionResponse::ECR_Ignore);
	}

	UFUNCTION(NotBlueprintCallable)
	void DoneSlamming()
	{
		if(!bSubmerging)
		{
			bSubmerging = true;
			CannonBallDamageableComponent.DisableDamageTaking();

			FHazeAnimationDelegate OnBlendingIn;
			FHazeAnimationDelegate OnBlendingOut;
			OnBlendingOut.BindUFunction(this, n"FinishAttack");
			OctoArm.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, SubmergeAnim);
			SetActorEnableCollision(false);
			OctoArm.SetCollisionEnabled(ECollisionEnabled::NoCollision);

			OnStreamArmDeactivated.Broadcast();
		}
	}

	UFUNCTION()
	void HitByCannonBall()
	{
		if(!bSubmerging)
		{
			bSubmerging = true;
			CannonBallDamageableComponent.DisableDamageTaking();

			if(OnBlendingOutSlam.IsBound())
				OnBlendingOutSlam.Clear();

			// System::ClearAndInvalidateTimerHandle(AnimationTimerHandler);
			FHazeAnimationDelegate OnBlendingIn;
			FHazeAnimationDelegate OnBlendingOut;
			//Calls too early
			OnBlendingOut.BindUFunction(this, n"FinishAttack");
			// System::SetTimer(this, n"FinishAttack", SubmergeAnim.PlayLength, false);
			OctoArm.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, SubmergeAnim);

			OnStreamArmDeactivated.Broadcast();

			ArmCollider.SetCollisionResponseToChannel(ECollisionChannel::ECC_Vehicle, ECollisionResponse::ECR_Ignore);

			bCanTimer = false;
		}
	}

	UFUNCTION()
	void FinishAttack()
	{
		if(bActive)
		{
			bActive = false;
			OctoArm.SetHiddenInGame(true);
			this.SetActorEnableCollision(false);
			//DisableActor(this);
		}
	}
}

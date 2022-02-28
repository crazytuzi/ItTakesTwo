import Vino.Characters.AICharacter;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboonPathSpline;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboonIntersectionPoint;
import Vino.Movement.Components.MovementComponent;

event void FOnMoonBaboonLanded(AMoonBaboon Baboon);

UCLASS(Abstract)
class AMoonBaboon : AHazeCharacter
{
	UPROPERTY(DefaultComponent)
	USphereComponent LaserHitBox;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ShieldMesh;
	default ShieldMesh.bHiddenInGame = true;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent ShieldEffect;
	default ShieldEffect.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.ControlSideDefaultCollisionSolver = n"AICharacterSolver";
	default MoveComp.RemoteSideDefaultCollisionSolver = n"AICharacterRemoteCollisionSolver";

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bDisabledAtStart = true;

	default CapsuleComponent.SetCollisionProfileName(n"PlayerCharacter");
	default CapsuleComponent.CanCharacterStepUpOn = ECanBeCharacterBase::ECB_No;
	FCollisionProfileName Deactivated;

	UPROPERTY()
	AMoonBaboonIntersectionPoint InitialIntersectionPoint;
	UPROPERTY()
	TArray<AMoonBaboonIntersectionPoint> AllIntersectionPoints;
	UPROPERTY()
	TArray<AMoonBaboonIntersectionPoint> ValidIntersectionPoints;

	UPROPERTY()
	AActor MoonMid;

	bool bActive = false;

	bool bShieldActive = false;

	UPROPERTY()
	bool bHitByLaser = false;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ActivateJetpackAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DeactivateJetpackAudioEvent;

	UPROPERTY()
	FOnMoonBaboonLanded OnMoonBaboonLanded;

	FTimerHandle TauntTimerHandle;
	float DelayBetweenTaunts = 5.f;

	FRotator TargetUpRotation = FVector::UpVector.Rotation();
	FVector PreviousTargetUp;
	FVector TraversalPlaneNormal;
    FHazeAcceleratedRotator UpRotation;
    default UpRotation.Value = TargetUpRotation;
    default UpRotation.Velocity = FRotator::ZeroRotator;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetControlSide(Game::GetMay());

		MoveComp.Setup(CapsuleComponent);
		
		if (InitialIntersectionPoint != nullptr)
		{
			// InitialIntersectionPoint.ChooseNewSpline(this);
		}

		SetCapabilityAttributeObject(n"MoonMid", MoonMid);
		SetCapabilityAttributeObject(n"MoonBaboon", this);

		TArray<AActor> TempActors;
		Gameplay::GetAllActorsOfClass(AMoonBaboonIntersectionPoint::StaticClass(), TempActors);

		for (AActor TempActor : TempActors)
		{
			AMoonBaboonIntersectionPoint CurPoint = Cast<AMoonBaboonIntersectionPoint>(TempActor);
			if (CurPoint != nullptr)
			{
				AllIntersectionPoints.Add(CurPoint);
			}
		}
	}

	UFUNCTION()
	void StartMoving()
	{
		if (InitialIntersectionPoint != nullptr)
		{
			InitialIntersectionPoint.ChooseNewSpline(this);
		}
		
		System::SetTimer(this, n"PlayInitialTaunt", 2.f, false);
		

		if (IsActorDisabled())
			EnableActor(nullptr);

		StartTauntTimer();
	}

	void StartTauntTimer()
	{
		TauntTimerHandle = System::SetTimer(this, n"PlayTaunt", DelayBetweenTaunts, true);
	}

	void StopTauntTimer()
	{
		System::ClearAndInvalidateTimerHandle(TauntTimerHandle);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayInitialTaunt()
	{
		SetCapabilityActionState(n"FoghornMoonBaboonTauntOnMoonInitial", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayTaunt()
	{
		SetCapabilityActionState(n"FoghornMoonBaboonTauntOnMoon", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION()
	void HitByLaser()
	{
		if (bShieldActive)
			return;

		TriggerJetpackJump();
		bShieldActive = true;

		ShieldEffect.Activate(true);
		ShieldMesh.SetHiddenInGame(false);

		SetCapabilityActionState(n"FoghornMoonBaboonHitReactionOnMoon", EHazeActionState::ActiveForOneFrame);
		SetCapabilityActionState(n"FoghornMoonBaboonShieldOnMoon", EHazeActionState::ActiveForOneFrame);

		StopTauntTimer();
	}

	UFUNCTION()
	void TriggerJetpackJump()
	{
		if (Game::GetMay().HasControl())
		{
			BP_FindValidIntersectionPoints();

			int RandPointIndex = FMath::RandRange(0, ValidIntersectionPoints.Num() - 1);
			AMoonBaboonIntersectionPoint DesiredPoint = ValidIntersectionPoints[RandPointIndex];
			NetTriggerJetpackJump(DesiredPoint);
		}
	}

	UFUNCTION(NetFunction)
	void NetTriggerJetpackJump(AMoonBaboonIntersectionPoint IntersectionPoint)
	{
		SetCapabilityAttributeObject(n"TargetLandingPoint", IntersectionPoint);
		SetCapabilityActionState(n"JetpackJumping", EHazeActionState::Active);
		BP_ActivateJetpackFlame();
		HazeAkComp.HazePostEvent(ActivateJetpackAudioEvent);
	}

	UFUNCTION(BlueprintEvent)
	void BP_FindValidIntersectionPoints()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateJetpackFlame()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_DeactvateJetpackFlame()
	{}

	void Landed()
	{
		BP_DeactvateJetpackFlame();
		HazeAkComp.HazePostEvent(DeactivateJetpackAudioEvent);

		ShieldEffect.Deactivate();
		ShieldMesh.SetHiddenInGame(true);
		
		bShieldActive = false;
		OnMoonBaboonLanded.Broadcast(this);

		StartTauntTimer();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FHazeHitResult Hit;
		if (MoveComp.LineTrace(ActorLocation, MoonMid.ActorLocation, Hit))
		{
			TargetUpRotation = Hit.Normal.Rotation();
		}

		FRotator CurUpRot = UpRotation.AccelerateTo(TargetUpRotation, 0.5f, DeltaTime);
		FVector TargetUpVector = TargetUpRotation.Vector();
		if (FMath::Abs(TraversalPlaneNormal.DotProduct(TargetUpVector)) > 0.01f) 
		{
			TraversalPlaneNormal = TargetUpVector.CrossProduct(PreviousTargetUp).GetSafeNormal(); 
		}

		FVector NewUp = CurUpRot.Vector();
		NewUp = NewUp.ConstrainToPlane(TraversalPlaneNormal);

		PreviousTargetUp = TargetUpVector;
        ChangeActorWorldUp(NewUp);
	}
}
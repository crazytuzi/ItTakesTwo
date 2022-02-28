import Vino.Trajectory.TrajectoryStatics;
import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingTarget;
import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingStartInteraction;

enum EIceAxeState
{
	Initiating,
	Ready
}

class AIceAxeActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TempAxeHolder;

	UPROPERTY(DefaultComponent, Attach = TempAxeHolder)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent, Attach = TempAxeHolder)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = TempAxeHolder)
	UNiagaraComponent NiagaraTrailComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ImpactLoc;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent AkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent GenericHit;
	
	UPROPERTY(Category = "Audio")
	UAkAudioEvent TargetNormalHit;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent TargetDoubleHit;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.AutoDisableRange = 1500.f;

	AAxeThrowingStartInteraction MayStart;
	
	AAxeThrowingStartInteraction CodyStart;

	UPROPERTY(Category = "Niagara")
	UNiagaraSystem NiagaraImpactSystemStandard;

	EIceAxeState IceAxeState;

	AHazePlayerCharacter PlayerOwner;
	UObject TargetToWatch;
	AHazeActor AttachActor;

	bool bIsActive = false;
	bool bIsMoving = false;
	bool bHasBeenThrown = false;

	bool bCanInitiationTimer;
	float InitiationTimer;
	float MaxInitiationTimer = 1.f;

	FVector Velocity;

	bool bIsDoublePoints;
	float DisableTime;

	const float Gravity = 1200.f;
	const float LifeDuration = 12.f;

	UPROPERTY(Category = "Setup")
	UHazeCapabilitySheet CapabilitySheet;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapabilitySheet(CapabilitySheet);
		DeactivateAxe();

		NiagaraTrailComp.SetActive(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bCanInitiationTimer)
		{
			InitiationTimer -= DeltaTime;

			if (InitiationTimer <= 0.f)
			{
				bCanInitiationTimer = false;
				IceAxeState = EIceAxeState::Ready;
			}
		}

		if (bHasBeenThrown && Time::GameTimeSeconds >= DisableTime)
			DeactivateAxe();

		if (AttachActor != nullptr && AttachActor.IsActorDisabled())
			DeactivateAxe();
	}

	void ActivateAxe(AHazePlayerCharacter Player)
	{
		bIsActive = true;

		EnableActor(this);

		bIsMoving = false;
		bHasBeenThrown = false;

		System::SetTimer(this, n"TimedNiagaraActivation", 0.5f, false);

		NiagaraTrailComp.SetActive(false);

		FVector Loc;
		FQuat Rot;

		//Axe Manager Should set locations instead
		//If GetAvailableAxe is valid, or on deactivate maybe, set locations and rotation back to starting point

		if (Player == Game::May)
		{
			Loc = MayStart.IcicleSpawnPoint.WorldLocation;
			Rot = MayStart.IcicleSpawnPoint.WorldRotation.Quaternion();
		}
		else
		{
			Loc = CodyStart.IcicleSpawnPoint.WorldLocation;
			Rot = CodyStart.IcicleSpawnPoint.WorldRotation.Quaternion();			
		}

		SetActorLocationAndRotation(Loc, Rot);

		IceAxeState = EIceAxeState::Initiating;

		InitiationTimer = MaxInitiationTimer;
		bCanInitiationTimer = true;

		HazeAudio::SetPlayerPanning(AkComp, Player);
	}


	UFUNCTION()
	void TimedNiagaraActivation()
	{
		NiagaraTrailComp.SetActive(true);
	}

	void DeactivateAxe()
	{
		DisableActor(this);

		bIsActive = false;
		AttachActor = nullptr;
		bIsDoublePoints = false;
		DetachRootComponentFromParent(true);

		NiagaraTrailComp.SetActive(false);
	}

	void ThrowAxe(FVector Target, float Force, UObject AimTarget)
	{
		bIsMoving = true;
		bHasBeenThrown = true;

		Velocity = CalculateVelocityForPathWithHorizontalSpeed(
			ActorLocation, Target,
			Gravity, Force
		);

		TargetToWatch = AimTarget;
		DisableTime = Time::GameTimeSeconds + LifeDuration;
	}

	UFUNCTION(NetFunction)
	void NetHandleControlHit(FHitResult Hit, FTransform RelativeTransform, bool bDoublePoints)
	{
		AAxeThrowingTarget Target = Cast<AAxeThrowingTarget>(Hit.Actor);

		if (Target != nullptr)
		{
			Niagara::SpawnSystemAtLocation(NiagaraImpactSystemStandard, ImpactLoc.GetWorldLocation(), FRotator(0.f)); 
			Target.TargetHit(bDoublePoints);

			if (bDoublePoints)
				AudioTargetDoubleHit();
			else
				AudioTargetNormalHit();
		}
		else
		{
			AudioGenericHit();
		}

		// This can happen if this message comes in before the Throw capability activation
		// In this case, just ignore... The target hit is still networked, so we dont care.
		if (!bIsActive)
			return;

		AttachActor = Cast<AHazeActor>(Hit.Actor);
		HandleHit(Hit, RelativeTransform);
	}

	void HandleHit(FHitResult Hit, FTransform RelativeTransform)
	{
		AttachToComponent(Hit.Component, NAME_None, EAttachmentRule::KeepWorld);
		ActorRelativeTransform = RelativeTransform;
		NiagaraTrailComp.SetActive(false);
	
		bIsMoving = false;
	}

	UFUNCTION()
	void HandleParentDisabled()
	{
		DeactivateAxe();
	}

	void AudioGenericHit()
	{
		AkComp.HazePostEvent(GenericHit);
	}

	void AudioTargetNormalHit()
	{
		AkComp.HazePostEvent(TargetNormalHit);
	}

	void AudioTargetDoubleHit()
	{
		AkComp.HazePostEvent(TargetDoubleHit);
	}
}
import Peanuts.Spline.SplineComponent;
import Cake.FlyingMachine.FlyingMachineNames;
import Cake.FlyingMachine.FlyingMachineOrientation;
import Cake.FlyingMachine.Turret.FlyingMachineTurret;
import Vino.Camera.Components.CameraDetacherComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Cake.FlyingMachine.FlyingMachineHealthWidget;
import Vino.PlayerHealth.PlayerHealthStatics;

event void FFlyingMachineCollisionEvent(FHitResult Hit);
event void FFlyingMachineBoostEvent();
event void FFlyingMachineTakeDamage(float Amount);
event void FFlyingMachineDeath();

struct FFlyingMachineWeight
{
	UPROPERTY()
	FVector RelativeLocation;

	UPROPERTY()
	float Weight;
}

class UFlyingMachineEventHandler : UObjectInWorld
{
	UPROPERTY(BlueprintReadOnly)
	AFlyingMachine Machine;

	void InitInternal(AFlyingMachine InMachine)
	{
		SetWorldContext(InMachine);
		Machine = InMachine;

		Init();
	}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void Init() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnStartDriving() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnStopDriving() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnStartBoosting() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnStopBoosting() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnFatalImpact(FHitResult Hit) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnTakeDamage(float Damage) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnDeath() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnTick(float DeltaTime) {}
}

class AFlyingMachine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase Mesh;
	default Mesh.bUpdateOverlapsOnAnimationFinalize = false;
	default Mesh.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = "Mesh")
	USceneComponent PilotAttach;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent MovementCollision;
	default MovementCollision.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;
	default CrumbComponent.SyncIntervalType = EHazeCrumbSyncIntervalType::VeryHigh;
	default CrumbComponent.IncludeCustomParamsInActorReplication(FVector::ZeroVector, FRotator::ZeroRotator, this);
	default CrumbComponent.CrumbDebugSize = 500.f;
	default ReplicateAsMovingActor();

	UPROPERTY(DefaultComponent)
	UBoxComponent ProjectileCollision;
	default ProjectileCollision.bGenerateOverlapEvents = false;

	// Camera root; detaches components to make sure they only move when updated
	UPROPERTY(DefaultComponent, Attach = "Mesh")
	UCameraDetacherComponent PilotCameraDetacher;
	default PilotCameraDetacher.bFollowRotation = true;

	// Handles input, pivot lag and camera blocking
	UPROPERTY(DefaultComponent, Attach = "PilotCameraDetacher")
	UCameraSpringArmComponent PilotCameraSpringArm;
	default PilotCameraSpringArm.StartPivotVelocity = FVector(3000.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = "PilotCameraSpringArm")
	UHazeCameraComponent PilotCamera;

	// Need this for outside systems to be able to handle our velocity
	UPROPERTY(DefaultComponent)
	UHazeActualVelocityComponent ActualVelocityComp; 

	UPROPERTY(Category = "Turret")
	AFlyingMachineTurret AttachedTurret;

	UPROPERTY(Category = "Capabilities")
	TArray<TSubclassOf<UHazeCapability>> DefaultCapabilities;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionFeatureBase PilotFeature;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent FrontHazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent RearHazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent Disable;
	default Disable.bDisabledAtStart = true;

	// Event handlers
	UPROPERTY(Category = "Events")
	TArray<TSubclassOf<UFlyingMachineEventHandler>> EventHandlerTypes;
	TArray<UFlyingMachineEventHandler> EventHandlers;

#if TEST
	bool bDebugLockedSpeed = false;
#endif

	/* EVENTS */
	void CallOnStartDrivingEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnStartDriving();
	}
	void CallOnStopDrivingEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnStopDriving();
	}
	void CallOnStartBoostingEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnStartBoosting();
	}
	void CallOnStopBoostingEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnStopBoosting();
	}
	void CallOnImpactEvent(FHitResult Hit)
	{
		for(auto Handler : EventHandlers)
			Handler.OnImpact(Hit);
	}
	void CallOnFatalImpactEvent(FHitResult Hit)
	{
		for(auto Handler : EventHandlers)
			Handler.OnFatalImpact(Hit);
	}
	void CallOnTakeDamageEvent(float Damage)
	{
		for(auto Handler : EventHandlers)
			Handler.OnTakeDamage(Damage);
	}
	void CallOnDeathEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnDeath();
	}
	void CallOnTickEvent(float DeltaTime)
	{
		for(auto Handler : EventHandlers)
			Handler.OnTick(DeltaTime);
	}
	/* EVENTS */

	// Current pilot of the flying machine
	AHazePlayerCharacter Pilot;

	// Orientation (rotation) used by all capabilities revolving movement
	UPROPERTY(BlueprintReadOnly)
	FFlyingMachineOrientation Orientation;

	// Speed of the flying machine
	UPROPERTY()
	float Speed;

	UPROPERTY()
	float SpeedPercent = 0.f;

	// Called when colliding with some surface
	UPROPERTY()
	FFlyingMachineCollisionEvent OnCollision;

	UPROPERTY()
	FFlyingMachineTakeDamage OnTakeDamage;

	UPROPERTY()
	FFlyingMachineBoostEvent OnBoost;

	UPROPERTY()
	FFlyingMachineDeath OnDeath;

	// Used to limit how much the plane rotated when turning (only visual)
	float TurnAngleModifier = 1.f;

	// Used to limit how fast the plane turns (only gameplay)
	float TurnRateModifier = 1.f;

	// Health, we cant use the normal health system since its one health for both players
	UPROPERTY()
	float Health = 5.f;

	// Widget class for the health bar
	UPROPERTY(Category = "Widget")
	TSubclassOf<UFlyingMachineHealthWidget> HealthWidgetClass;

	// If the player can boost
	UPROPERTY(BlueprintReadOnly)
	float BoostCharge = 1.f;

	UPROPERTY(BlueprintReadOnly)
	bool bIsInMeleeFight = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetControlSide(Game::GetCody());
		if (AttachedTurret != nullptr)
		{
			AttachedTurret.AttachToComponent(Mesh, n"TurretBase");
		}

		for(TSubclassOf<UHazeCapability> Capability : DefaultCapabilities)
		{
			AddCapability(Capability);
		}

		for(auto HandlerClass : EventHandlerTypes)
		{
			auto Handler = Cast<UFlyingMachineEventHandler>(NewObject(this, HandlerClass));
			Handler.InitInternal(this);

			EventHandlers.Add(Handler);
		}

		OnPreSequencerControl.AddUFunction(this, n"HandlePreSequenceControl");
		OnPostSequencerControl.AddUFunction(this, n"HandlePostSequenceControl");

		AddCapability(n"FullscreenSharedHealthAudioCapability");
	}

	UFUNCTION()
	void HandlePreSequenceControl(FHazePreSequencerControlParams Params)
	{
		BlockCapabilities(FlyingMachineTag::Machine, this);
		TriggerMovementTransition(this, n"Cutscene");
	}

	UFUNCTION()
	void HandlePostSequenceControl(FHazePostSequencerControlParams Params)
	{
		UnblockCapabilities(FlyingMachineTag::Machine, this);
		TriggerMovementTransition(this, n"CutsceneStop");
	}

	UFUNCTION()
	void SetMeleeFightActive(bool bStatus)
	{
		bIsInMeleeFight = bStatus;
	}

	UFUNCTION()
	void SetupSplineAttachment(UHazeSplineComponent Spline)
	{
		Spline.AttachToComponent(Mesh, n"Base", EAttachmentRule::KeepRelative);
	}

	bool HasPilot()
	{
		return Pilot != nullptr;
	}

	// Weight system
	TArray<FFlyingMachineWeight> ExtraWeights;
	void AddWeight(FFlyingMachineWeight Weight)
	{
		ExtraWeights.Add(Weight);
	}
	void ClearWeights()
	{
		ExtraWeights.Empty();
	}

	UFUNCTION(BlueprintCallable, Category="Vehicles|FlyingMachine")
	void TakeDamage(float Amount)
	{
		if (HasControl())
		{
			NetTakeDamage(Amount);
		}
	}

	UFUNCTION(NotBlueprintCallable, NetFunction)
	void NetTakeDamage(float Amount)
	{
		if (!CanPlayerBeDamaged(Game::GetCody()))
			return;

		Health -= Amount;
		OnTakeDamage.Broadcast(Amount);
		CallOnTakeDamageEvent(Amount);

		if (HasControl() && Health <= 0.f && CanPlayerBeKilled(Game::GetCody()))
		{
			NetDie();
		}
	}

	UFUNCTION(NotBlueprintCallable, NetFunction)
	void NetDie()
	{
		Health = 0.f;
		OnDeath.Broadcast();

		MovementCollision.SetGenerateOverlapEvents(false);

		CallOnDeathEvent();
	}

	void ConsumeBoostCharge(float Amount)
	{
		BoostCharge = Math::Saturate(BoostCharge - Amount);
	}

	void RegainBoostCharge(float Amount)
	{
		BoostCharge = Math::Saturate(BoostCharge + Amount);
	}

	UFUNCTION(Category = "Vehicles|FlyingMachine")
	void AddWeightForFrame(FFlyingMachineWeight Weight)
	{
		AddWeight(Weight);
	}

	// Sets turn modifier on the flying machine
	// AngleModifier dictates how much the plane will roll/pitch visually when turning
	// RateModifier dictates how fast the plane will actually turn
	UFUNCTION(Category = "Vehicles|FlyingMachine")
	void SetTurnModifier(float AngleModifier, float RateModifier)
	{
		TurnAngleModifier = AngleModifier;
		TurnRateModifier = RateModifier;
	}
}
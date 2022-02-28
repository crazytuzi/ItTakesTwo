import Peanuts.Spline.SplineComponent;
import Cake.FlyingMachine.Glider.FlyingMachineGliderComponent;
import Vino.Camera.Components.CameraDetacherComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.Camera.Settings.CameraVehicleChaseSettings;

settings FlyingMachineGliderChaseSettings for UCameraVehicleChaseSettings
{
	FlyingMachineGliderChaseSettings.CameraInputDelay = 0.f;
	FlyingMachineGliderChaseSettings.MovementInputDelay = 0.f;
	FlyingMachineGliderChaseSettings.AccelerationDuration = 4.f;
	FlyingMachineGliderChaseSettings.bOnlyChaseAfterMovementInput = false;
};

class UFlyingMachineGliderEventHandler : UObjectInWorld
{
	UPROPERTY(BlueprintReadOnly)
	AFlyingMachineGlider Glider;

	void InitInternal(AFlyingMachineGlider InGlider)
	{
		SetWorldContext(InGlider);
		Glider = InGlider;

		Init();
	}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void Init() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnStartDriving() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnStopDriving() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnFatalImpact(FHitResult Hit) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnWindBlow(FVector Direction, float Strength) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnTick(float DeltaTime) {}
}

class AFlyingMachineGlider : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent LeftSpline;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent RightSpline;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;
	default CrumbComponent.SyncIntervalType = EHazeCrumbSyncIntervalType::VeryHigh;
	default CrumbComponent.UpdateSettings.OptimalCount = 5;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UHazeCameraRootComponent CameraRoot;

	UPROPERTY(DefaultComponent, Attach = CameraRoot)
	UCameraDetacherComponent CameraDetacher;
	default CameraDetacher.bFollowRotation = true;

	UPROPERTY(DefaultComponent, Attach = CameraDetacher)
	UCameraSpringArmComponent SpringArm;
	default SpringArm.StartPivotVelocity = FVector(3000.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = SpringArm)
	UHazeCameraComponent Camera;

	UPROPERTY(DefaultComponent)
	UFlyingMachineGliderComponent GliderComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	// Need this for outside systems to be able to handle our velocity
	UPROPERTY(DefaultComponent)
	UHazeActualVelocityComponent ActualVelocityComp; 

	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY(Category = "Camera")
	UCameraVehicleChaseSettings CameraChaseSettings = FlyingMachineGliderChaseSettings;

	UPROPERTY(Category = "Events")
	TArray<TSubclassOf<UFlyingMachineGliderEventHandler>> EventHandlerTypes;
	TArray<UFlyingMachineGliderEventHandler> EventHandlers;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent Disable;
	default Disable.bDisabledAtStart = true;

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
	void CallOnImpactEvent(FHitResult ImpactHit)
	{
		for(auto Handler : EventHandlers)
			Handler.OnImpact(ImpactHit);
	}
	void CallOnFatalImpactEvent(FHitResult ImpactHit)
	{
		for(auto Handler : EventHandlers)
			Handler.OnFatalImpact(ImpactHit);
	}
	void CallOnWindBlowEvent(FVector Direction, float Strength)
	{
		for(auto Handler : EventHandlers)
			Handler.OnWindBlow(Direction, Strength);
	}
	void CallOnTickEvent(float DeltaTime)
	{
		for(auto Handler : EventHandlers)
			Handler.OnTick(DeltaTime);
	}
	/* EVENTS */

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(n"FlyingMachineGliderSpeedCapability");
		AddCapability(n"FlyingMachineGliderMovementCapability");
		AddCapability(n"FlyingMachineGliderImpactCapability");
		AddCapability(n"FlyingMachineGliderWindCapability");

		for(auto HandlerClass : EventHandlerTypes)
		{
			auto Handler = Cast<UFlyingMachineGliderEventHandler>(NewObject(this, HandlerClass));
			Handler.InitInternal(this);

			EventHandlers.Add(Handler);
		}
	}

	UFUNCTION(BlueprintCallable, Category = "Vehicles|FlyingMachine|Glider")
	void TransitionToSpeed(float NewSpeed, float Duration)
	{
		GliderComp.TransitionToSpeed(NewSpeed, Duration);
	}

	UFUNCTION(Category = "Vehicles|FlyingMachine|Glider")
	void AddSplineToFollow(UHazeSplineComponent Spline)
	{
		GliderComp.FollowSplines.Add(Spline);
	}

	UFUNCTION(Category = "Vehicles|FlyingMachine|Glider")
	void AddSplinesToFollow(TArray<UHazeSplineComponent> Splines)
	{
		GliderComp.FollowSplines.Append(Splines);
	}
}
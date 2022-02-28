import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Vino.ActivationPoint.DummyActivationPoint;

class AWhippableSapWheelActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent WheelMesh;

	UPROPERTY(DefaultComponent, Attach = WheelMesh)
	UBoxComponent WhipTrigger;
	default WhipTrigger.RelativeLocation = FVector(0.f, 1180.f, 2070.f);
	default WhipTrigger.RelativeRotation = FRotator(0.f, 0.f, 30.f);
	default WhipTrigger.BoxExtent = FVector(100.f, 75.f, 160.f);
	default WhipTrigger.SetCollisionProfileName(n"BlockAll");
	//Add HazeTag VineImpact

	UPROPERTY(DefaultComponent, Attach = WhipTrigger)
	UVineImpactComponent VineImpactComp; 
	default VineImpactComp.ValidationType = EHazeActivationPointActivatorType::None;
	default VineImpactComp.InitializeDistance(EHazeActivationPointDistanceType::Visible, 5500.f);
	default VineImpactComp.InitializeDistance(EHazeActivationPointDistanceType::Targetable, 5500.f);
	default VineImpactComp.InitializeDistance(EHazeActivationPointDistanceType::Selectable, 5500.f);

	UPROPERTY(DefaultComponent, Attach = WheelMesh)
	UStaticMeshComponent WheelSpiderCollisionMesh;
	//Disable Sap/Weapon/WaterTrace/Camera.

	UPROPERTY(DefaultComponent, Attach = VineImpactComp)
	UDummyActivationPointBase DummyVinePoint;
	default DummyVinePoint.ChangeValidActivator(EHazeActivationPointActivatorType::May);

	UPROPERTY(DefaultComponent, Attach = WheelMesh)
	UHazeAkComponent AkComp;
	default AkComp.RelativeLocation = FVector(0.f, -2140.f, 1070.f);

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 16000.f;

	UPROPERTY(Category = "VOStates")
	bool bHasBeenWhipped = false;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncRotationComponent SmoothSyncRotComp;

	UPROPERTY(Category = "Settings")
	bool bPreviewEndRoll = false;

	UPROPERTY(Category = "Settings")
	float EndRoll = 45.f;

	float ErrorTolerance = 0.5f;

	FHazeConstrainedPhysicsValue PhysValue;
	default PhysValue.UpperBound = 45.f;
	default PhysValue.LowerBound = 0.f;
	default PhysValue.LowerBounciness = 0.3f;
	default PhysValue.UpperBounciness = 0.3f;
	default PhysValue.Friction = 1.f;

	FHazeAcceleratedRotator AccRotator;

	UPROPERTY(Category = "Setup")
	UAkAudioEvent StartForward;

	UPROPERTY(Category = "Setup")
	UAkAudioEvent StopForward;

	UPROPERTY(Category = "Setup")
	UAkAudioEvent StartBackwards;

	UPROPERTY(Category = "Setup")
	UAkAudioEvent StopBackwards;

	bool bMovingForwards = false;
	bool bMovingBackwards = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(bPreviewEndRoll)
			RotationRoot.SetRelativeRotation(FRotator(0.f, 0.f, EndRoll));
		else
			RotationRoot.SetRelativeRotation(FRotator::ZeroRotator);

	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(Network::IsNetworked())
			SetControlSide(Game::Cody);

		if(HasControl())
		{
			VineImpactComp.OnVineConnected.AddUFunction(this, n"OnWhipConnected");
			VineImpactComp.OnVineDisconnected.AddUFunction(this, n"OnWhipDisconnected");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AccRotator.AccelerateTo(SmoothSyncRotComp.Value, 5.f, DeltaSeconds);
		RotationRoot.SetRelativeRotation(AccRotator.Value);

		if(!bMovingForwards && AccRotator.Velocity.Roll > ErrorTolerance)
		{
			bMovingForwards = true;
			bMovingBackwards = false;
			AkComp.HazePostEvent(StartForward);
		}
		else if(bMovingForwards && FMath::IsNearlyZero(AccRotator.Velocity.Roll,ErrorTolerance))
		{
			bMovingForwards = false;
			AkComp.HazePostEvent(StopForward);
		}
		else if(!bMovingBackwards && AccRotator.Velocity.Roll < -ErrorTolerance)
		{
			bMovingBackwards = true;
			bMovingForwards = false;
			AkComp.HazePostEvent(StartBackwards);
		}
		else if(bMovingBackwards && FMath::IsNearlyZero(AccRotator.Velocity.Roll,ErrorTolerance))
		{
			bMovingBackwards = false;
			AkComp.HazePostEvent(StopBackwards);
		}
	}

	UFUNCTION(NetFunction)
	void NetHazePostEvent(UAkAudioEvent AudioEvent)
	{
		AkComp.HazePostEvent(AudioEvent);
	}

	UFUNCTION()
	void OnWhipConnected()
	{
		SmoothSyncRotComp.SetValue(FRotator(0.f,0.f, EndRoll));

		if(!bHasBeenWhipped)
			SetHasBeenWhipped();

		DummyVinePoint.ChangeValidActivator(EHazeActivationPointActivatorType::None);

	}

	UFUNCTION()
	void OnWhipDisconnected()
	{
		SmoothSyncRotComp.SetValue(FRotator(0.f,0.f,0.f));
		DummyVinePoint.ChangeValidActivator(EHazeActivationPointActivatorType::May);
	}

	UFUNCTION(NetFunction)
	void SetHasBeenWhipped()
	{
		bHasBeenWhipped = true;
	}
}
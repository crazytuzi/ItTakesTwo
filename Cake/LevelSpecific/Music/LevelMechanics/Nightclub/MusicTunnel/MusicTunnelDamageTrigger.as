import Cake.LevelSpecific.Music.LevelMechanics.Nightclub.MusicTunnel.MusicTunnelVehicle;
import Cake.LevelSpecific.Music.LevelMechanics.Nightclub.MusicTunnel.MusicTunnelComponent;
import Peanuts.Audio.HazeAudioEffects.DopplerEffect;

UCLASS(Abstract, HideCategories = "Rendering Debug Collision Replication Input Actor LOD Cooking")
class AMusicTunnelDamageTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent DamageMesh;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMusicTunnelComponent TunnelComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartLoopEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopLoopEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OpenCloseEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PassbyEvent;

	UPROPERTY()
    bool bUseDopplerRTPC = false;

    UPROPERTY(meta = (EditCondition = "bUseDopplerRTPC"))
    float DopplerScale = 1.f;

    UPROPERTY(meta = (EditCondition = "bUseDopplerRTPC"))
    float DopplerSmoothing = 0.5f;

	UPROPERTY(EditDefaultsOnly, Category = "Properties")
	UStaticMesh DefaultMesh;

	UPROPERTY(Category = "Properties")
	float DefaultMeshOffset = 0.f;

	UPROPERTY(Category = "Properties")
	float RotationRate = 0.f;

	UPROPERTY(Category = "Properties")
	float RotationOffset = 0.f;

	UPROPERTY(Category = "Properties")
	UStaticMesh Mesh;

	UPROPERTY(Category = "Properties")
	bool RythmObstacle = false;
	
	UPROPERTY(Category = "Properties")
	float RythmOffset = 0.f;

	float NewRythmOffset = 0.f;

	bool FlipFlop = false;

	float CurrentMeshOffset = 0.f;
	
	bool bActive = true;

	default bRunConstructionScriptOnDrag = false;

	UDopplerEffect MusicTunnelObstacleDoppler;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(TunnelComp != nullptr && TunnelComp.TargetSplineActor != nullptr)
		{
			if (Mesh != nullptr)
				DamageMesh.SetStaticMesh(Mesh);
			else if (DefaultMesh != nullptr)
				DamageMesh.SetStaticMesh(DefaultMesh);

			USplineComponent TargetSplineComp = USplineComponent::Get(TunnelComp.TargetSplineActor);
			FTransform ClosestTransformOnSpline = TargetSplineComp.FindTransformClosestToWorldLocation(GetActorLocation(), ESplineCoordinateSpace::World);
			// SetActorTransform(ClosestTransformOnSpline);
			SetActorLocationAndRotation(ClosestTransformOnSpline.Location, ClosestTransformOnSpline.Rotation);

			DamageMesh.SetRelativeLocation(FVector(0.f, 0.f, DefaultMeshOffset));
			SetActorRotation(FRotator(GetActorRotation().Pitch, GetActorRotation().Yaw, RotationOffset));
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DamageMesh.OnComponentBeginOverlap.AddUFunction(this, n"EnterDamageTrigger");

		MusicTunnelObstacleDoppler = Cast<UDopplerEffect>(HazeAkComp.AddEffect(UDopplerEffect::StaticClass()));
		MusicTunnelObstacleDoppler.SetObjectDopplerValues(true, 5000, 500.f, 0.f, DopplerScale, DopplerSmoothing, Driver = EHazeDopplerDriverType::Observer);
		//MusicTunnelObstacleDoppler.PlayPassbySound(PassbyEvent, 0.1f, 0.3f);
		HazeAkComp.HazePostEvent(StartLoopEvent);
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterDamageTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if (!bActive)
			return;

		AMusicTunnelVehicle Vehicle = Cast<AMusicTunnelVehicle>(OtherActor);
		if (Vehicle != nullptr)
		{
			Vehicle.TakeDamage();
			// SetActorHiddenInGame(true);
			// System::SetTimer(this, n"ShowTrigger", 4.f, false);
			// bActive = false;
		}
	}

	// UFUNCTION(NotBlueprintCallable)
	// void ShowTrigger()
	// {
	// 	SetActorHiddenInGame(false);
	// 	bActive = true;
	// }

	UFUNCTION(BlueprintCallable)
	void MoveRythmObstacle()
	{
		if(FlipFlop)
		{
			NewRythmOffset = RythmOffset;
		}
			else
			NewRythmOffset = 0.f;
		
		FlipFlop = !FlipFlop;

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AddActorLocalRotation(FRotator(0.f, 0.f, RotationRate * DeltaTime));
		
		if(RythmObstacle)
		{
			CurrentMeshOffset = FMath::FInterpTo(CurrentMeshOffset, DefaultMeshOffset + NewRythmOffset, DeltaTime, 10.f);
			DamageMesh.SetRelativeLocation(FVector(0.f, 0.f, CurrentMeshOffset));
			// Print("NewRythmOffset: " + NewRythmOffset);
			//HazeAkComp.HazePostEvent(OpenCloseEvent);
		}

	}
}
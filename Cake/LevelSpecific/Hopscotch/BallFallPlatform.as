import Vino.Bounce.BounceComponent;

event void BallFallPlatformMoveUp();

class ABallFallPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent ImpulseRoot;

	UPROPERTY(DefaultComponent, Attach = ImpulseRoot)
	USceneComponent BounceRoot;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UBounceComponent BounceComp; 

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UStaticMeshComponent Mesh;
	default Mesh.RelativeRotation = FRotator(-90.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MovePlatformAudioEvent;

	UPROPERTY()
	BallFallPlatformMoveUp AudioBallFallPlatformMoveUp;

	UPROPERTY()
	FHazeTimeLike MovePlatformTimeline;

	UPROPERTY()
	float TargetHeight = 2700.f;

	UPROPERTY()
	bool bShowTargetHeight = false;

	UPROPERTY()
	float MovePlatformDelay = 0.f;

	UPROPERTY()
	bool bShouldBeNumberCube = false;

	UPROPERTY()
	UStaticMesh DefaultMesh;

	UPROPERTY()
	UStaticMesh NumberCubeMesh;

	UPROPERTY()
	UMaterialInterface DefaultMaterial01;

	UPROPERTY()
	UMaterialInterface DefaultMaterial02;

	UPROPERTY()
	UMaterialInterface NumberCubeMaterial;

	UPROPERTY()
	TArray<UMaterialInterface> NumberCubeMaterialsArray; 

	FVector StartingLoc = FVector::ZeroVector;
	FVector TargetLoc;

	FHazeConstrainedPhysicsValue PhysValue;	FVector ImpulseDirection;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovePlatformTimeline.BindUpdate(this, n"MovePlatformTimelineUpdate");
		MovePlatformTimeline.BindFinished(this, n"MovePlatformTimelineFinished");
		MeshRoot.SetRelativeLocation(StartingLoc);
		TargetLoc = FVector(0.f, 0.f, TargetHeight);

		PhysValue.LowerBound = -750.f;
		PhysValue.UpperBound = 1500.f;
		PhysValue.LowerBounciness = 1.f;
		PhysValue.UpperBounciness = 0.65f;
		PhysValue.Friction = 3.f;

		ImpulseDirection = FVector::UpVector;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PhysValue.SpringTowards(0.f, 100.f);
		PhysValue.Update(DeltaTime);
		ImpulseRoot.SetRelativeLocation(ImpulseDirection * -PhysValue.Value);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bShowTargetHeight)
			MeshRoot.SetRelativeLocation(FVector(0.f, 0.f, TargetHeight));
		else
			MeshRoot.SetRelativeLocation(StartingLoc);

		if (bShouldBeNumberCube)
		{
			Mesh.SetStaticMesh(NumberCubeMesh);
			Mesh.SetMaterial(0, NumberCubeMaterial);
			Mesh.SetMaterial(1, NumberCubeMaterialsArray[FMath::RandRange(0, NumberCubeMaterialsArray.Num() - 1)]);
		} else 
		{
			Mesh.SetStaticMesh(DefaultMesh);
			Mesh.SetMaterial(0, DefaultMaterial01);
			Mesh.SetMaterial(1, DefaultMaterial02);
		}
	}

	UFUNCTION()
	void StartMovingPlatform()
	{
		SetActorTickEnabled(true);
		
		MovePlatformTimeline.SetPlayRate(1/0.5f);

		if (MovePlatformDelay <= 0.f)
			MovePlatform();
		else
			System::SetTimer(this, n"MovePlatform", MovePlatformDelay, false);
	}

	UFUNCTION()
	void MovePlatform()
	{
		MovePlatformTimeline.Play();
		AudioBallFallPlatformMoveUp.Broadcast();
		UHazeAkComponent::HazePostEventFireForget(MovePlatformAudioEvent, this.GetActorTransform());
	}

	UFUNCTION()
	void MovePlatformTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(FMath::Lerp(StartingLoc, TargetLoc, CurrentValue));
	}

	UFUNCTION()
	void MovePlatformTimelineFinished(float CurrentValue)
	{
		PhysValue.AddImpulse(-2000.f);
		SetActorTickEnabled(true);
	}
}
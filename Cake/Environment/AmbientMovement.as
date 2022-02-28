UCLASS(hidecategories="StaticMesh Materials Physics  Collision Lighting Physics Activation Cooking Replication Input Actor HLOD Mobile AssetUserData")
class UAmbientMovementComponent : UActorComponent
{
	UPROPERTY()
	FName TargetComponentName;
	
	UPROPERTY(Category = "zzDO NOT TOUCH")
	USceneComponent TargetComponent;

    UPROPERTY(Category = "zzDO NOT TOUCH")
	FVector ActualRotateAxis = FVector::OneVector;


    UPROPERTY(Category = "Swing")
	FVector SwingAxis = FVector(1.0f, 0.0f, 0.0f);
    UPROPERTY(Category = "Swing")
	float SwingAngle = 45;
    UPROPERTY(Category = "Swing")
	float SwingSpeed = 0;


    UPROPERTY(Category = "Rotate")
	FVector RotateAxis = FVector(0.0f, 0.0f, 1.0f);
    UPROPERTY(Category = "Rotate")
	float RotateSpeed = 0;
    UPROPERTY(Category = "Rotate")
	bool RotateLocalSpace = false;


    UPROPERTY(Category = "Bob")
	FVector BobAxis = FVector(0.0f, 0.0f, 1.0f);
    UPROPERTY(Category = "Bob")
	float BobDistance = 50;
    UPROPERTY(Category = "Bob")
	float BobSpeed = 0;


    UPROPERTY(Category = "Scale")
	float ScaleOffset = 2.0f;
    UPROPERTY(Category = "Scale")
	float ScaleSpeed = 0;


    UPROPERTY(Category = "BallPit")
	bool BallPitOffset = false;

	FRotator StartRotation;
	FVector StartLocation;
	FVector StartScale;

	// To match the shader this exact code is also implemented in BallPitOscean.usf
	FVector GerstnerWave(FVector WorldPos, float T, float Random1, float Random2)
	{
		FVector2D Angle = FVector2D(FMath::Sin(7.0 * Random1), FMath::Cos(7.0 * Random1));// UtilPS.AngleToVector(7.0 * Random1);
		float Scale = 600 * Random2;
		float Gradient = Angle.DotProduct(FVector2D(WorldPos.X, WorldPos.Y)) / Scale;
		float Time = T + Gradient;
		FVector2D Rotation = FVector2D(FMath::Cos(Time), FMath::Sin(Time)) * Scale * 0.1;
		return FVector((Angle * Rotation.X).X, (Angle * Rotation.X).Y, Rotation.Y);
	}

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		StartLocation = Owner.ActorLocation;
		StartRotation = Owner.ActorRotation;
		StartScale = Owner.ActorRelativeScale3D;

		ActualRotateAxis = RotateAxis;
		if(RotateLocalSpace)
			ActualRotateAxis = Owner.ActorTransform.TransformVectorNoScale(RotateAxis);

		TArray<UActorComponent> ChildComps = Owner.GetComponentsByClass(USceneComponent::StaticClass());
		for(int i = 0; i < ChildComps.Num(); i++)
		{
			if(ChildComps[i].Name == TargetComponentName)
			{
				TargetComponent = Cast<USceneComponent>(ChildComps[i]);
			}
		}

		if (TargetComponent != nullptr)
		{
			StartLocation = TargetComponent.GetWorldLocation();
			StartRotation = TargetComponent.GetWorldRotation();
			StartScale = TargetComponent.GetRelativeScale3D();
		}
    }
	FRotator AxisAngleToRotator(FVector Axis, float Angle)
	{
		return FQuat(Axis.X * FMath::Sin(FMath::DegreesToRadians(Angle) / 2.0f),
					 Axis.Y * FMath::Sin(FMath::DegreesToRadians(Angle) / 2.0f),
					 Axis.Z * FMath::Sin(FMath::DegreesToRadians(Angle) / 2.0f),
					 FMath::Cos(FMath::DegreesToRadians(Angle) / 2.0f)).Rotator();
	}


    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
		float Time = System::GetGameTimeInSeconds();

		FRotator SwingRotation = AxisAngleToRotator(SwingAxis, FMath::Sin(Time * SwingSpeed) * SwingAngle);

		FRotator CurrentRotate = AxisAngleToRotator(ActualRotateAxis, Time * RotateSpeed);
		
		FVector BobLocation = BobAxis * FMath::Sin(Time * BobSpeed) * BobDistance;

		// Waves
		FVector Offset = FVector::ZeroVector;
		if(BallPitOffset)
		{
			// To match the shader this exact code is also implemented in BallPitOscean.usf
			Offset += GerstnerWave(StartLocation, Time, 0.6753220067f, 0.6753220067f);
			Offset += GerstnerWave(StartLocation, Time, 0.7218623255f, 0.7218623255f);
			Offset += GerstnerWave(StartLocation, Time, 0.4856229147f, 0.4856229147f);
			Offset += GerstnerWave(StartLocation, Time, 0.0479901888f, 0.0479901888f);
			Offset += GerstnerWave(StartLocation, Time, 0.1864599408f, 0.1864599408f);
			Offset += GerstnerWave(StartLocation, Time, 0.4931565006f, 0.4931565006f);
			Offset += GerstnerWave(StartLocation, Time, 0.4632785125f, 0.4632785125f);
			Offset += GerstnerWave(StartLocation, Time, 0.8781050279f, 0.8781050279f);
			Offset += GerstnerWave(StartLocation, Time, 0.5870849275f, 0.5870849275f);
			Offset += GerstnerWave(StartLocation, Time, 0.2446723913f, 0.2446723913f);
		}

		FVector CurrentScale = FMath::Sin(Time * ScaleSpeed) * ScaleOffset;
		
		FVector NewLocation = StartLocation + BobLocation + Offset;
		FRotator NewRotation = StartRotation.Compose(CurrentRotate).Compose(SwingRotation);
		FVector NewScale = StartScale + CurrentScale;

		if (TargetComponentName == "")
		{
			Owner.ActorLocation = NewLocation;
			Owner.ActorRotation = NewRotation;
			Owner.ActorRelativeScale3D = NewScale;
		}
		else
		{
			if(TargetComponent != nullptr)
			{
				TargetComponent.WorldLocation = NewLocation;
				TargetComponent.WorldRotation = NewRotation;
				TargetComponent.RelativeScale3D = NewScale;
			}
		}
    }
}


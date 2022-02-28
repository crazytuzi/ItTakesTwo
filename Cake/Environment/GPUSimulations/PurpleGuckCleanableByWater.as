import Rice.RenderTextureDrawing.RenderTextureDrawing;
import Cake.Environment.GPUSimulations.Simulation;
import Cake.Environment.GPUSimulations.PaintablePlane;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseComponent;
import Cake.LevelSpecific.Garden.Greenhouse.PaintablePlaneContainer;

class ACleanableSurface : APaintablePlaneContainer
{
	UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazePropComponent Prop;

	UPROPERTY(EditInstanceOnly)
	APaintablePlane CurveSystem = nullptr;

	UPROPERTY(DefaultComponent)
	UWaterHoseImpactComponent WaterImpact;
	default WaterImpact.bShowWaterWidget = false;

	UPROPERTY(Category = "Water")
	FLinearColor WaterColor = FLinearColor(0.f, 0.f, 0.1f);

	UPROPERTY(Category = "Water")
	float ImpactCleanRadius = 800.f;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WaterImpact.OnWaterProjectileImpact.AddUFunction(this, n"Watered");
		PaintablePlane = CurveSystem;
		UseLargeGoopSplashEffect = true; // Indicates another particle effect should be used when spraying water on this surface.
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
		//Only update the widget if we are going to show it
		if(WaterImpact.bShowWaterWidget)
		{
			auto May = Game::GetMay();
			auto WaterHoseComp = UWaterHoseComponent::Get(May);
		
			auto Collision = UPrimitiveComponent::Get(this);

			FVector FoundLocation;
			UHazeViewPoint ViewPoint = May.GetViewPoint();

			const float ExtraTraceDistance = ViewPoint.ViewLocation.Dist2D(GetActorLocation());
			FQuat FinalRotation =  ViewPoint.GetViewRotation().Quaternion() * (WaterHoseComp.ShootOffsetRotation * 0.25f).Quaternion();
			FVector ViewDirection = FinalRotation.Vector();

			FVector TraceLocation = ViewPoint.ViewLocation;
			TraceLocation += ViewDirection * ExtraTraceDistance;

			if(Collision.GetClosestPointOnCollision(TraceLocation, FoundLocation) > 0)
			{
				FVector CurrentLoctation = WaterImpact.GetWorldLocation();
				CurrentLoctation = FMath::VInterpTo(CurrentLoctation, FoundLocation, DeltaTime, 10.f);
				WaterImpact.SetWorldLocation(CurrentLoctation);
			}
		}
	}

	bool CanStandOn(FVector WorldLocation) const
	{
		if(CurveSystem == nullptr)
			return true;

		const FWitherSimulationArrayQueryData Query = CurveSystem.QueryData(WorldLocation);
		return Query.bHasBeenPainted;
	}

	UFUNCTION(NotBlueprintCallable)
	void Watered(FHitResult Impact)
	{
		if(CurveSystem != nullptr && Impact.bBlockingHit)
			CurveSystem.LerpAndDrawTexture(Impact.ImpactPoint, ImpactCleanRadius, WaterColor, WaterColor);
	}
}

class ACleanableCurve : APaintablePlane
{
	UPROPERTY(Category = "Options")
	ACleanableSurface WallMesh;

	UPROPERTY(Category = "Options", meta = (MakeEditWidget))
	FVector CenterPoint;

	UPROPERTY(Category = "Options")
	float FlowSpeed = -100;
	
	UPROPERTY(Category = "Options")
	float Radius = 3000;
	
	UPROPERTY(Category = "Options")
	float Height = 1000;

	UPROPERTY(Category = "Options")
	float Width = 0;

	UPROPERTY(Category = "Options")
	float StartAngle = 0;

	UPROPERTY(Category = "Debug|Misc")
	bool DebugCurve = false;
	
	UPROPERTY(Category = "Options")
	bool Flat = false;

	

	FVector WorldLocationToTextureLocation(FVector WorldLocation) const override
	{
		if(Flat)
			return Super::WorldLocationToTextureLocation(WorldLocation);
		FVector WSCenterPoint = GetActorTransform().TransformPosition(CenterPoint);

		FVector Delta = (WSCenterPoint - WorldLocation);
		
		float Angle = (FMath::Atan2(Delta.Y, Delta.X) + 3.14152128f) / (3.14152128f * 2.0f);
		
		Angle -= FMath::Frac(StartAngle);
		Angle /= Width;

		float h = Delta.Z / -Height;
		
		bool OutOfRange = ((Angle < 0.0) || (Angle > 1.0) || (h < 0.0) || (h > 1.0));

		return FVector(FMath::Clamp(Angle, 0.0f, 1.0f), FMath::Clamp(h, 0.0f, 1.0f), (OutOfRange ? 1.0 : 0.0));
	}

	FVector TextureLocationToWorldLocation(FVector TextureLocation) const override
	{
		if(Flat)
			return Super::TextureLocationToWorldLocation(TextureLocation);

		FVector WSCenterPoint = GetActorTransform().TransformPosition(CenterPoint);

		float angle = TextureLocation.X;
		angle *= 3.14152128f * 2.0f;
		angle *= Width;
		angle += FMath::Frac(StartAngle) * 3.14152128f * 2.0f;

		FVector Offset = FVector(FMath::Cos(angle), FMath::Sin(angle), 0) * Radius;
		
		Offset = WSCenterPoint + Offset + FVector(0, 0, Height * TextureLocation.Y);

		return Offset;
	}

	float WorldRadiusToTextureRadius(float WorldRadius) const override
	{
		if(Flat)
			return Super::WorldRadiusToTextureRadius(WorldRadius);
			
		float Circumference = (Width * Radius * 3.14152128f * 2.0f);
		float XRad = WorldRadius / Circumference;
		float YRad = WorldRadius / Height;
		return (XRad + YRad) / 2.0f;
	}

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		FVector WSCenterPoint = GetActorTransform().TransformPosition(CenterPoint);

		Super::ConstructionScript();
		DrawDebug();
	}
	void DrawDebug()
	{
#if EDITOR
		System::FlushPersistentDebugLines();
		
		if(DebugCPUSideData)
		{
			for(int i = 0; i < CPUSideData.Num(); i++)
			{
				const FLinearColor color = CPUSideData[i].bHasBeenPainted ? FLinearColor(1,1,1,1) : FLinearColor(1,0,0,1);
				const FVector WorldPosition = TextureLocationToWorldLocation(ArrayLocationToTextureLocation(i));
				System::DrawDebugPoint(WorldPosition, 3.0f, color, 1.0f);	
			}
		}
		
		if(DebugCurve)
		{
			FVector TexturePosition = WorldLocationToTextureLocation(GetActorTransform().TransformPosition(TestDrawLocation));
			FVector SnappedWorldPosition = TextureLocationToWorldLocation(TexturePosition);

			System::DrawDebugPoint(SnappedWorldPosition, 50, FLinearColor(1, 1, 1, 1), 5.0f);

			TexturePosition = WorldLocationToTextureLocation(GetActorTransform().TransformPosition(TestQueryLocation));
			SnappedWorldPosition = TextureLocationToWorldLocation(TexturePosition);

			System::DrawDebugPoint(SnappedWorldPosition, 50, FLinearColor(1, 1, 1, 1), 5.0f);
			float LineSize = 25.0f;
			int Lines = 16;
			for(int i = 0; i < Lines; i++)
			{
				float angle = (i / float(Lines));
				float angle2 = ((i + 1) / float(Lines));
				
				FVector LowerStart = TextureLocationToWorldLocation(FVector(angle, 0, 0));
				FVector LowerEnd = TextureLocationToWorldLocation(FVector(angle2, 0, 0));

				FVector UpperStart = TextureLocationToWorldLocation(FVector(angle, 1, 0));
				FVector UpperEnd = TextureLocationToWorldLocation(FVector(angle2, 1, 0));
				
				System::DrawDebugLine(LowerStart, LowerEnd, FLinearColor(1, 1, 1, 1), 5.0f, LineSize);
				System::DrawDebugLine(UpperStart, UpperEnd, FLinearColor(1, 1, 1, 1), 5.0f, LineSize);

				System::DrawDebugLine(LowerStart, UpperStart, FLinearColor(1, 1, 1, 1), 5.0f, LineSize);
				System::DrawDebugLine(LowerEnd, UpperEnd, FLinearColor(1, 1, 1, 1), 5.0f, LineSize);
			}
		}
#endif
	}
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		Super::BeginPlay();
		Clear();
	}

	FVector PaintLocationTS;
	float PaintRadiusTS;
	FLinearColor TargetColor;
	FLinearColor Opacity;

    UFUNCTION(BlueprintPure)
	FWitherSimulationArrayQueryData QueryData(FVector WorldLocation) const override
	{
		const FVector TexturePosition = WorldLocationToTextureLocation(WorldLocation);
		FWitherSimulationArrayQueryData Result = QueryDataTS(TexturePosition);
		if (TexturePosition.Z > 0.5)
			Result.bHasBeenPainted = true; // has not been painted if you are outside.
		return Result;
	}
	
	float PaintTime = 0.25f;
	//bool LerpWasCalledThisFrame = false;
	// If you want to draw more than once per tick, this function won't work.
	UFUNCTION()
	void LerpAndDrawTexture(FVector WorldLocation, float WorldRadius, FLinearColor TargetColor, FLinearColor Opacity, 
	bool bHasBeenPaintedStatus = true, UTexture2D TextureOverride = nullptr, bool OverrideCPU = true, 
	FLinearColor CPUSideOpacityMultiplier = FLinearColor(1,1,1,1), bool CPUsideCircle = true, float CPUSideRadiusMultiplier = 1.0f) override
	{
		// This function only edits state indicating where LerpAndDrawTextureTS() should be called in Tick().
		// This is because LerpAndDrawTextureTS() needs to be called every tick to make the goop flow anyways.
		// A more correct (but also potentially more expensive) solution would be to have both this and Tick call LerpAndDrawTextureTS().
		// Current solution should be fine as long as you don't call this function more than once per tick.
		PaintLocationTS = WorldLocationToTextureLocation(WorldLocation);
		PaintRadiusTS = WorldRadiusToTextureRadius(WorldRadius);
		this.TargetColor = TargetColor;
		this.Opacity = Opacity;
		//LerpWasCalledThisFrame = true;
		PaintTime = 0.25f;
	}

    float MoveTowards(float Current, float Target, float StepSize)
    {
        return Current + FMath::Clamp(Target - Current, -StepSize, StepSize);
    }

	float TimeToNextCpuStep = 0;
	float PixelCounter = 0;
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
		FVector WSCenterPoint = GetActorTransform().TransformPosition(CenterPoint);
		Material::SetVectorParameterValue(WorldShaderParameters, n"ShrubberyGoopPlaneCenterPoint", FLinearColor(WSCenterPoint.X, WSCenterPoint.Y, WSCenterPoint.Z, 0));

		Material::SetScalarParameterValue(WorldShaderParameters, n"ShrubberyGoopStartAngle", FMath::Frac(StartAngle));
		Material::SetScalarParameterValue(WorldShaderParameters, n"ShrubberyGoopWidth", Width);
		Material::SetScalarParameterValue(WorldShaderParameters, n"ShrubberyGoopHeight", Height);

		Super::Tick(DeltaTime);
		
		DrawDebug();

		float WSSizeOfGPUPixel = float(Height) / float(512);

		float WorldFlowDistanceThisFrame = FlowSpeed * DeltaTime;
		float PixelFlowDistanceThisFrame = (WorldFlowDistanceThisFrame / float(Height)) * float(512);
		PixelCounter += (PixelFlowDistanceThisFrame * 0.65); // increases all the way to 1 then is reset to 0
		float Pixels = FMath::FloorToFloat(PixelCounter); // will be 1 on the frames where it moved.
		PixelCounter -= Pixels;
		

		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"FlowOffset", (Pixels / 512));
		if((WallMesh != nullptr) && (WallMesh.Prop != nullptr))
		{
			float PixelCounterWS = ((PixelCounter / 1.0) / float(512)) * float(Height);
			WallMesh.Prop.SetScalarParameterValueOnMaterials(n"PixelCounterWS", PixelCounterWS);
		}

		PaintTime -= DeltaTime;
		if(PaintTime < 0)
		{
			PaintLocationTS = FVector::ZeroVector;
			PaintRadiusTS = 0.0f;
		}
		//LerpWasCalledThisFrame = false;
		float alpha = 0.1f;
		LerpAndDrawTextureTS(PaintLocationTS, PaintRadiusTS, FLinearColor(1, 1, 1, 1), FLinearColor(alpha, alpha, alpha, alpha), true);

		float WSSizeOfCPUPixel = float(Height) / float(CPUSideResolution);
		
		TimeToNextCpuStep -= DeltaTime;
		if(TimeToNextCpuStep <= 0)
		{
			TimeToNextCpuStep = FMath::Abs(FlowSpeed * 2.0f) / WSSizeOfCPUPixel;
		
			// CPU-Side flowing. (expensive?)
			for(int i = 0; i < CPUSideData.Num(); i++)
			{
				int stride = CPUSideResolution;
				int aboveIndex = i + stride;

				FWitherSimulationArrayData Current = CPUSideData[i];
				FWitherSimulationArrayData Above;
				if(aboveIndex > CPUSideData.Num() - 1) // we are above the top of the Array
				{
					Above.Color.R = -1;
					Above.bHasBeenPainted = false;
				}
				else
				{
					Above = CPUSideData[aboveIndex];
				}

				Current.Color = Above.Color;
				Current.bHasBeenPainted = Above.bHasBeenPainted;
				CPUSideData[i] = Current;
			}
		}
	}
}
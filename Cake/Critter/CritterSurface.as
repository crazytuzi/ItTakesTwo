import Peanuts.Spline.SplineComponent;

// Todo: shape presets

enum ECritterSurfaceShapePresets
{
	Square,
	Circle,
	Test,
}

struct CritterSurfaceCritter
{
	UPROPERTY()
	UStaticMeshComponent MeshComp;

	UPROPERTY()
	float MoveTimer = 0.f;

	UPROPERTY()
	float MoveDuration = 0.f;

	UPROPERTY()
	FVector2D StartSurfacePosition;

	UPROPERTY()
	FVector StartRelativePosition;

	UPROPERTY()
	FRotator StartRotation;

	UPROPERTY()
	FVector2D DestSurfacePosition;

	UPROPERTY()
	FVector DestRelativePosition;

	UPROPERTY()
	FRotator DestRotation;

	UPROPERTY()
	bool bIsRunningAway = false;
}

struct CritterSurfacePointArray
{
	UPROPERTY()
	TArray<FVector> Points;
}

struct MeshSampleData
{
	FVector P0;
	FVector P1;
	FVector P2;
	FVector P3;
	FVector2D Fraction;
	bool Valid;
}

class ACritterSurface : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
	default Root.bVisualizeComponent = true;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 6000.f;
	
    UPROPERTY(DefaultComponent)
	UBoxComponent PreviewBox;
	default PreviewBox.bIsEditorOnly = true;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent LoopingSoundComp;	
	default LoopingSoundComp.bIsStatic = true;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LoopingSoundEvent;
	
	FHazeAudioEventInstance LoopingSoundInstance;

    UPROPERTY()
	UStaticMesh Mesh;

    UPROPERTY()
	float CritterSpeed = 0.1f;

	UPROPERTY()
	int NumberOfCritters = 10;

    UPROPERTY(Category="Surface")
	ECritterSurfaceShapePresets ShapePreset;

	UPROPERTY(Category="Surface", meta = (ClampMin = 0.0, ClampMax = 1.0), Meta = (EditCondition="ShapePreset == ECritterSurfaceShapePresets::Square", EditConditionHides))
	float SquareRoundness = 0.2;

	UPROPERTY(Category="Surface", meta = (ClampMin = 0.0, ClampMax = 1.0), Meta = (EditCondition="ShapePreset == ECritterSurfaceShapePresets::Circle", EditConditionHides))
	float CircleAngle = 0.4f;

	UPROPERTY(Category="Surface", meta = (ClampMin = 0.0, ClampMax = 1.0), Meta = (EditCondition="ShapePreset == ECritterSurfaceShapePresets::Circle", EditConditionHides))
	float CircleHole = 0.5f;

	UPROPERTY(Category="Surface", meta = (ClampMin = 2.0, ClampMax = 32.0))
	int ResolutionX = 8;

	UPROPERTY(Category="Surface", meta = (ClampMin = 2.0, ClampMax = 32.0))
	int ResolutionY = 8;

	UPROPERTY(Category="Surface")
	float Width = 500;

	UPROPERTY(Category="Surface")
	float Height = 500;
	
	UPROPERTY(Category="Surface")
	float Perspective = 0.0f;
	
	UPROPERTY(Category="Surface")
	float PushDistance = 0.25f;
	
	UPROPERTY(Category="zzInternal")
	TArray<CritterSurfaceCritter> Critters;

	UPROPERTY(Category="zzInternal")
	TArray<FVector> Points;

    UPROPERTY(Category="zzInternal")
	FTransform ProjectedTransform;

	FVector2D Pattern_Square(FVector2D Coordinate)
	{
		float t = FMath::Clamp(SquareRoundness, 0.0f, 1.0f);
		float tweak = FMath::Pow(t, 0.25f);
		tweak = FMath::GetMappedRangeValueClamped(FVector2D(1, 0),FVector2D(1.4, 10.0f),tweak);
		float dist = tweak - Coordinate.Distance(FVector2D::ZeroVector);
		return Coordinate * dist * (1.0f/tweak) * ((t*0.5) + 1);
	}

	FVector2D Pattern_Circle(FVector2D Coordinate)
	{
		float x = Coordinate.X + 0.5f;
		float y = Coordinate.Y + 0.5f;
		y = FMath::GetMappedRangeValueClamped(FVector2D(0, 1), FVector2D(CircleHole, 1), y);
		
		float angle = x * 3.14152128f * 2.0f * CircleAngle;
		float X = FMath::Sin(angle);
		float Y = FMath::Cos(angle);

		return FVector2D(X, Y) * y * 0.5f;
	}

	UFUNCTION(CallInEditor)
	void RecalculateAllCritterSurfaces()
	{
		TArray<ACritterSurface> AllSurfaces;
		GetAllActorsOfClass(AllSurfaces);

		for (auto OtherSurface : AllSurfaces)
		{
			OtherSurface.Construction_UpdateSurface();
			OtherSurface.Modify();
			OtherSurface.RerunConstructionScripts();
		}
	}

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
#if EDITOR
		if (!Editor::IsCooking() && Level.IsVisible() && Editor::IsSelected(this))
			Construction_UpdateSurface();

		Construction_DebugLines();
#endif

		Construction_CreateCritters();
    }

	void Construction_UpdateSurface()
	{
		FVector ScaleDiff = GetActorScale3D() - FVector::OneVector;
		SetActorScale3D(FVector::OneVector);
		
		Width += ScaleDiff.X * 100.0f;
		Height += ScaleDiff.Y * 100.0f;
		PreviewBox.SetBoxExtent(FVector(Width, Height, 0));
		
		ProjectedTransform = GetActorTransform();
		Points.SetNum(ResolutionX * ResolutionY);

		if(ResolutionX < 2 || ResolutionY < 2)
			return;

		for (int x = 0; x < ResolutionX; x++)
		{
			for (int y = 0; y < ResolutionY; y++)
			{
				float X = (float(x) / float(ResolutionX-1)) - 0.5f;
				float Y = (float(y) / float(ResolutionY-1)) - 0.5f;
				
				FVector2D Pattern = FVector2D(X, Y);;

				if(ShapePreset == ECritterSurfaceShapePresets::Square)
				 	Pattern = Pattern_Square(FVector2D(X, Y));
				else if(ShapePreset == ECritterSurfaceShapePresets::Circle)
				 	Pattern = Pattern_Circle(FVector2D(X, Y));

				X = Pattern.X;
				Y = Pattern.Y;

				FVector ForwardVector = GetActorForwardVector() * X * Width * 2.0f;
				FVector RightVector = GetActorRightVector() * Y * Height * 2.0f;
				FVector OffsetVector = (ForwardVector + RightVector);

				float TraceLength = 10000;
				float persp = Perspective / 1000.0f;
				FHitResult result;
				System::LineTraceSingle((ActorLocation + OffsetVector), (ActorLocation + OffsetVector + (OffsetVector) * (persp*TraceLength)) - GetActorUpVector()*TraceLength, ETraceTypeQuery::Visibility, true, TArray<AActor>(), EDrawDebugTrace::ForOneFrame,result, false);
				if(result.bBlockingHit)
				{
					Points[x + y * ResolutionX] = ProjectedTransform.InverseTransformPosition(result.Location);
				}
				else
				{
					Points[x + y * ResolutionX] = ProjectedTransform.InverseTransformPosition(ActorLocation+OffsetVector);
				}
			}
		}
	}

	void Construction_DebugLines()
	{
		System::FlushPersistentDebugLines();
		for (int x = 1; x < ResolutionX; x++)
		{
			for (int y = 1; y < ResolutionY; y++)
			{
				FVector Start = ProjectedTransform.TransformPosition(Points[x + y * ResolutionX]);
				FVector End1 = ProjectedTransform.TransformPosition(Points[(x) + (y-1) * ResolutionX]);
				FVector End2 = ProjectedTransform.TransformPosition(Points[(x-1) + (y) * ResolutionX]);
				System::DrawDebugLine(Start, End1, FLinearColor::White, 10.0f);
				System::DrawDebugLine(Start, End2, FLinearColor::White, 10.0f);
			}
		}
	}

	void Construction_CreateCritters()
	{
		// Make preview splines
		Critters.Reset();
		for (int i = 0; i < NumberOfCritters; i++)
		{
			auto NewMesh = Cast<UStaticMeshComponent>(CreateComponent(UStaticMeshComponent::StaticClass()));
			NewMesh.StaticMesh = Mesh;
			NewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
			NewMesh.CollisionProfileName = n"NoCollision";

			CritterSurfaceCritter NewCritter = CritterSurfaceCritter();
			
			NewCritter.MeshComp = NewMesh;
			FVector2D RandPosition = FVector2D(FMath::RandRange(0.0f, 1.0f), FMath::RandRange(0.0f, 1.0f));
			NewCritter.StartSurfacePosition = RandPosition;
			NewCritter.StartRelativePosition = RelativePosFromSurfacePos(RandPosition);
			NewCritter.StartRotation = FRotator::MakeFromZ(RelativeUpVectorFromSurfacePos(RandPosition));
			MakeNewCritterDestination(NewCritter);

			NewMesh.SetWorldLocation(ActorTransform.TransformPosition(NewCritter.StartRelativePosition));
			Critters.Add(NewCritter);
		}

		if(Points.Num() > 0)
		{
			int idx = (ResolutionX-1) / 2 + ((ResolutionY-1) / 2) * ResolutionX; // Thanks lucas <3

			if (Points.IsValidIndex(idx))
				LoopingSoundComp.SetRelativeLocation(Points[idx]);
		}
	}

	void CritterReachDestination(CritterSurfaceCritter& Critter)
	{
		Critter.StartRelativePosition = Critter.DestRelativePosition;
		Critter.StartSurfacePosition = Critter.DestSurfacePosition;
		Critter.StartRotation = Critter.DestRotation;
	}

	void MakeNewCritterDestination(CritterSurfaceCritter& Critter)
	{
		FVector2D RandPosition = FVector2D(FMath::RandRange(0.0f, 1.0f), FMath::RandRange(0.0f, 1.0f));
		FVector2D SurfacePos = RandPosition;

		Critter.DestSurfacePosition = SurfacePos;
		Critter.DestRelativePosition = RelativePosFromSurfacePos(SurfacePos);

		FVector Direction = (Critter.DestRelativePosition - Critter.StartRelativePosition).GetSafeNormal();
		Critter.StartRotation = FRotator::MakeFromXZ(Direction, Critter.StartRotation.UpVector);
		Critter.DestRotation = FRotator::MakeFromXZ(Direction, RelativeUpVectorFromSurfacePos(SurfacePos));
		Critter.bIsRunningAway = false;

		Critter.MoveTimer = 0.f;

		float Distance = Critter.DestRelativePosition.Distance(Critter.StartRelativePosition);
		float Speed = FMath::Max(CritterSpeed * float(Width + Height) * 0.5f, 0.01f);
		Critter.MoveDuration = FMath::Max(Distance / Speed, 0.1f);
	}

	void CritterRunawayFrom(CritterSurfaceCritter& Critter, FVector DangerPositionRelative)
	{
		float MovePct = Critter.MoveTimer / Critter.MoveDuration;
		Critter.StartRelativePosition = Critter.MeshComp.RelativeLocation;
		Critter.StartRotation = Critter.MeshComp.RelativeRotation;
		Critter.StartSurfacePosition = FMath::Lerp(Critter.StartSurfacePosition, Critter.DestSurfacePosition, MovePct);

		FVector RelativeDirection = (Critter.StartRelativePosition - DangerPositionRelative).GetSafeNormal();

		FVector2D SurfacePos = Critter.StartSurfacePosition;
		SurfacePos.X += RelativeDirection.X * CritterSpeed * 1.5f;
		SurfacePos.Y += RelativeDirection.Y * CritterSpeed * 1.5f;

		// If we're going too far outside the surface, try the opposite direction
		if (FMath::Max(FMath::Abs(SurfacePos.X) - 1.f, 0.f) + FMath::Max(FMath::Abs(SurfacePos.Y) - 1.f, 0.f) > CritterSpeed * 0.75f)
		{
			SurfacePos = Critter.StartSurfacePosition;
			SurfacePos.X -= RelativeDirection.X * CritterSpeed * 1.5f;
			SurfacePos.Y -= RelativeDirection.Y * CritterSpeed * 1.5f;
		}

		SurfacePos.X = FMath::Clamp(SurfacePos.X, 0.f, 1.f);
		SurfacePos.Y = FMath::Clamp(SurfacePos.Y, 0.f, 1.f);

		Critter.DestSurfacePosition = SurfacePos;
		Critter.DestRelativePosition = RelativePosFromSurfacePos(SurfacePos);

		FVector Direction = (Critter.DestRelativePosition - Critter.StartRelativePosition).GetSafeNormal();
		Critter.StartRotation = FRotator::MakeFromXZ(Direction, Critter.StartRotation.UpVector);
		Critter.DestRotation = FRotator::MakeFromXZ(Direction, RelativeUpVectorFromSurfacePos(SurfacePos));
		Critter.bIsRunningAway = true;

		Critter.MoveTimer = 0.f;
		Critter.MoveDuration = 0.75f;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LoopingSoundInstance = LoopingSoundComp.HazePostEvent(LoopingSoundEvent);
    }

	// points are in localspace
	MeshSampleData GetPositionsFromSurfacePos(FVector2D p)
	{
		MeshSampleData Result = MeshSampleData();

		if(Points.Num() == 0)
		{
			Result.Valid = false;
			return Result;
		}

		FVector2D Pos = FVector2D(FMath::Clamp(p.X, 0.001f, 0.999f), FMath::Clamp(p.Y, 0.001f, 0.999f));

		// Convert 0-1 position to 0-with / 0-ResolutionY position
		int X    = Pos.X * (ResolutionX  - 1);
		int Y 	 = Pos.Y * (ResolutionY - 1);
		float Xf = FMath::Frac(Pos.X * (ResolutionX  - 1));
		float Yf = FMath::Frac(Pos.Y * (ResolutionY - 1));
		
		Result.Fraction = FVector2D(Xf, Yf);

		// get four neighbours
		Result.P0 = Points[ X      +  Y      * ResolutionX];
		Result.P1 = Points[ X      + (Y + 1) * ResolutionX];
		Result.P2 = Points[(X + 1) +  Y      * ResolutionX];
		Result.P3 = Points[(X + 1) + (Y + 1) * ResolutionX];
		
		Result.Valid = true;
		return Result;
	}

	FVector RelativePosFromSurfacePos(FVector2D p)
	{
		auto P = GetPositionsFromSurfacePos(p);

		if(!P.Valid)
			return GetActorLocation();

		FVector PP1 = FMath::Lerp(P.P0, P.P1, P.Fraction.Y);
		FVector PP0 = FMath::Lerp(P.P2, P.P3, P.Fraction.Y);
		FVector Result = FMath::Lerp(PP1, PP0, P.Fraction.X);
		return Result;
	}

	FVector WorldPosFromSurfacePos(FVector2D p)
	{
		return ProjectedTransform.TransformPosition(RelativePosFromSurfacePos(p));
	}

	FVector RelativeUpVectorFromSurfacePos(FVector2D p)
	{
		auto P = GetPositionsFromSurfacePos(p);

		if(!P.Valid)
			return FVector(0, 0, 1);
			
		FVector D1 = P.P0 - P.P1;
		FVector D2 = P.P0 - P.P2;

		FVector Result = D2.CrossProduct(D1);
		Result.Normalize();

		return Result;
	}

	FVector WorldUpVectorFromSurfacePos(FVector2D p)
	{
		return ProjectedTransform.TransformVector(RelativeUpVectorFromSurfacePos(p));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (int i = 0; i < NumberOfCritters; i++)
		{
			CritterSurfaceCritter& Critter = Critters[i];
			Critter.MoveTimer += DeltaTime;

			// Pick a new destination if 
			if (Critter.MoveTimer > Critter.MoveDuration)
			{
				CritterReachDestination(Critter);
				MakeNewCritterDestination(Critter);
			}

			// Check if this critter should run away
			if (!Critter.bIsRunningAway && Critter.MeshComp != nullptr)
			{
				// Only check one critter per frame for running away
				if (GFrameNumber % NumberOfCritters == i)
				{
					float ClosestDist = MAX_flt;
					FVector ClosestPosition;
					for (auto Player : Game::Players)
					{
						FVector PlayerRelativePosition = ActorTransform.InverseTransformPosition(Player.ActorLocation);
						float Distance = PlayerRelativePosition.Distance(Critter.MeshComp.RelativeLocation);
						if (Distance < ClosestDist)
						{
							ClosestDist = Distance;
							ClosestPosition = PlayerRelativePosition;
						}
					}

					if (ClosestDist < PushDistance * (Width + Height) * 0.5f)
						CritterRunawayFrom(Critter, ClosestPosition);
				}
			}

			// Update the actual critter mesh
			if (Critter.MeshComp != nullptr)
			{
				float MovePct = Critter.MoveTimer / Critter.MoveDuration;
				Critter.MeshComp.SetRelativeLocationAndRotation(
					FMath::Lerp(Critter.StartRelativePosition, Critter.DestRelativePosition, MovePct),
					FMath::RInterpConstantTo(
						Critter.MeshComp.RelativeRotation,
						FMath::LerpShortestPath(Critter.StartRotation, Critter.DestRotation, MovePct),
						DeltaTime, Critter.bIsRunningAway ? 500.f : 180.f)
				);
			}
		}
    }
}
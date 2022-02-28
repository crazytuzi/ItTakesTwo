import Peanuts.Spline.SplineComponent;
import Peanuts.Triggers.PlayerTrigger;
import Peanuts.Spline.AutoScaleSplineBoxComponent;
import Vino.Movement.Components.MovementComponent;
import Rice.Math.MathStatics;

event void FOnStreamActivated();
event void FOnStreamDeactivated();

class ASwimmingStream : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	UStreamComponent StreamComponent;

	UPROPERTY(DefaultComponent, Attach = StreamComponent)
	UAutoScaleSplineBoxComponent StreamBox;
	default StreamBox.BoxMargin = FVector(2000.f, 2000.f, 2000.f);
	default StreamBox.SetCollisionProfileName(n"TriggerOnlyPlayer");

	UPROPERTY()
	FOnStreamActivated OnStreamActivated;
	UPROPERTY()
	FOnStreamDeactivated OnStreamDeactivated;

	UPROPERTY(DefaultComponent, NotEditable, Attach = SplineComponent)
    UBillboardComponent BillboardComponent;
    default BillboardComponent.SetRelativeLocation(FVector(0, 0, 150));
    default BillboardComponent.Sprite = Asset("/Engine/EditorResources/Spline/T_Loft_Spline.T_Loft_Spline");

	UPROPERTY()
	bool bAdjustBoxManually = false;
	
#if EDITOR
    default bRunConstructionScriptOnDrag = true;
#endif

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		if (bAdjustBoxManually)
			return;

		float LargestSplineScale = GetLargestSplineScaleValue();
		StreamBox.BoxMargin = StreamComponent.StreamDistance * LargestSplineScale;
	}

	float GetLargestSplineScaleValue()
	{
		float LargestScale = 4.f;
		for (int Index = 0, Count = StreamComponent.NumberOfSplinePoints; Index < Count; Index++)
		{			
			float SplinePointScale = StreamComponent.GetDistanceScaleAtSplinePoint(Index);
			LargestScale = FMath::Max(LargestScale, SplinePointScale);		
		}
		
		return LargestScale;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StreamBox.OnComponentBeginOverlap.AddUFunction(this, n"StreamBoxBeginOverlap");
		StreamBox.OnComponentEndOverlap.AddUFunction(this, n"StreamBoxEndOverlap");

		StreamComponent.OnStreamActivated.AddUFunction(this, n"StreamActivated");
		StreamComponent.OnStreamDeactivated.AddUFunction(this, n"StreamDeactivated");
	}

	UFUNCTION()
	void StreamBoxBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		StreamComponent.PlayerEnteredTrigger(Player);		
	}

	UFUNCTION()
	void StreamBoxEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		StreamComponent.PlayerLeftTrigger(Player);	
	}

	UFUNCTION()
	void StreamActivated()
	{
		OnStreamActivated.Broadcast();
	}
	UFUNCTION()
	void StreamDeactivated()
	{
		OnStreamDeactivated.Broadcast();
	}

	UFUNCTION()
	void SetStreamActive(bool bActive)
	{
		StreamComponent.SetStreamActive(bActive);
	}
	
	UFUNCTION(BlueprintPure)
	bool IsStreamActive()
	{
		return StreamComponent.bStreamActive;
	}
}

class UStreamComponent : UHazeSplineComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;
	default SetHiddenInGame(true);

	UPROPERTY(Category = "Stream Settings", NotEditable)
	TArray<AHazePlayerCharacter> OverlappingPlayers;

	UPROPERTY()
	FOnStreamActivated OnStreamActivated;
	UPROPERTY()
	FOnStreamDeactivated OnStreamDeactivated;

	UPROPERTY(Category = "Stream Settings")
	bool bStreamActive = true;

	UPROPERTY(Category = "Stream Settings")
	bool bLockPlayersInside = false;
	
	// Base strength of the stream. Scaled by scaling the spline points
	UPROPERTY(Category = "Settings")
	float StreamStrength = 6000.f;

	// The default size of the stream
	UPROPERTY(EditConst, Category = "Settings")
	float StreamDistance = 1000.f;

	UPROPERTY(Category = "Settings", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))))
	float StreamStrengthAtEdge = 0.5f;

	// The acceleration given to the players to the center of the spline
	UPROPERTY(EditConst, Category = "Settings", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0")))
	float StreamVortexStrength = 0.f;


#if EDITOR
    default bShouldVisualizeScale = true;
    default ScaleVisualizationWidth = StreamDistance;
#endif
	// UPROPERTY(Category = "Stream Settings")
	// float StreamStrengthScaleModifier = .1f;


	UPROPERTY(Category = "Settings|Debug")
	bool bDrawDebugInPIE = false;

	UPROPERTY(Category = "Settings|Debug")
	FHazeMinMax DebugScaleColorRange;
	default DebugScaleColorRange.Min = 1.f;
	default DebugScaleColorRange.Max = 3.f;	

	UPROPERTY(NotEditable, Category = "EditorOnly")
	TArray<USplineMeshComponent> SplineMeshes;

	UPROPERTY(NotEditable, Category = "EditorOnly")
	UStaticMesh SplineDebugMesh = Asset("/Game/Editor/Visualizers/SplineCylinder.SplineCylinder");

	UPROPERTY(NotEditable, Category = "EditorOnly")
	UMaterial SplineDebugMaterial = Asset("/Game/Editor/Visualizers/SwimmingStreamDebugMaterial.SwimmingStreamDebugMaterial");

	UPROPERTY(Category = "Stream Settings")
	bool bBlockStreamCamera = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SplineMeshes.Empty();

		int SplineMeshCount = GetNumberOfSplinePoints() - 1;
		if (IsClosedLoop())
			SplineMeshCount += 1;

#if EDITOR
		for (int Index = 0, Count = SplineMeshCount; Index < Count; ++ Index)
		{
			USplineMeshComponent SplineMesh = USplineMeshComponent::Create(this.Owner);
			SplineMesh.SetStaticMesh(SplineDebugMesh);
			SplineMesh.SetMaterial(0, SplineDebugMaterial);
			SplineMesh.SetCastShadow(false);
			SplineMesh.bIsEditorOnly = true;

			if (bDrawDebugInPIE)
				SplineMesh.SetHiddenInGame(false);	
			else
				SplineMesh.SetHiddenInGame(true);				

			SplineMeshes.Add(SplineMesh);
		}
#endif

		UpdateSplineMeshes();
	}

	void UpdateSplineMeshes()
	{
		for (USplineMeshComponent SplineMesh : SplineMeshes)
		{
			int StartIndex = SplineMeshes.FindIndex(SplineMesh);
			int EndIndex = StartIndex + 1;

			if (IsClosedLoop() && EndIndex >= GetNumberOfSplinePoints())
				EndIndex = 0;

			FVector StartLocation = GetLocationAtSplinePoint(StartIndex, ESplineCoordinateSpace::Local);
			FVector StartTangent = GetTangentAtSplinePoint(StartIndex, ESplineCoordinateSpace::Local);
			FVector EndLocation = GetLocationAtSplinePoint(EndIndex, ESplineCoordinateSpace::Local);
			FVector EndTangent = GetTangentAtSplinePoint(EndIndex, ESplineCoordinateSpace::Local);
			SplineMesh.SetStartAndEnd(StartLocation, StartTangent, EndLocation, EndTangent, true);

			// Update mesh scale by scale
			float DistanceScale = StreamDistance / 500.f;
			float StartScale = GetDistanceScaleAtSplinePoint(StartIndex);
			float EndScale = GetDistanceScaleAtSplinePoint(EndIndex);
			SplineMesh.SetStartScale(FVector2D(StartScale, StartScale) * 0.5f * DistanceScale);
			SplineMesh.SetEndScale(FVector2D(EndScale, EndScale) * 0.5f * DistanceScale);

			// Update colour by strength
			float StartStrength = GetStrengthScaleAtSplinePoint(StartIndex);
			float EndStrength = GetStrengthScaleAtSplinePoint(EndIndex);
			SplineMesh.SetColorParameterValueOnMaterialIndex(0, n"StartColor", GetColorByScale(StartStrength));
			SplineMesh.SetColorParameterValueOnMaterialIndex(0, n"EndColor", GetColorByScale(EndStrength));
		}
	}

	// Resets all spline points Y and Z scale to 1
	UFUNCTION(CallInEditor)
	void ResetSplinePointScale()
	{
		//for ()
		for (int Index = 0; Index < NumberOfSplinePoints - 1; Index++)
		{
			SetScaleAtSplinePoint(Index, FVector::OneVector);
		}

		UpdateSplineMeshes();		
	}

	UFUNCTION(BlueprintPure)
	bool IsStreamActive()
	{
		return bStreamActive;
	}

	UFUNCTION()
	void SetStreamActive(bool bActive)
	{
		if (!bStreamActive && bActive)
			OnStreamActivated.Broadcast();
		if (bStreamActive && !bActive)
			OnStreamDeactivated.Broadcast();

		bStreamActive = bActive;
	}	

	UFUNCTION()
	void PlayerEnteredTrigger(AHazePlayerCharacter Player)
	{
		OverlappingPlayers.Add(Player);
		SetComponentTickEnabled(true);
	}
	
	UFUNCTION()
	void PlayerLeftTrigger(AHazePlayerCharacter Player)
	{
		OverlappingPlayers.Remove(Player);

		if (OverlappingPlayers.Num() == 0)
			SetComponentTickEnabled(false);
	}

	FLinearColor GetColorByScale(float Scale)
	{		
		return Math::LerpColor(FLinearColor::Green, FLinearColor::Red, FMath::GetMappedRangeValueClamped(FVector2D(DebugScaleColorRange.Min, DebugScaleColorRange.Max), FVector2D(0.f, 1.f), Scale));
	}

	float GetDistanceScaleAtSplinePoint(int Index)
	{
		return GetScaleAtSplinePoint(Index).Y;
	}

	float GetDistanceScaleAtDistance(float DistanceAlongSpline) const
	{
		return GetScaleAtDistanceAlongSpline(DistanceAlongSpline).Y;
	}

	float GetStrengthScaleAtSplinePoint(int Index)
	{
		float StrengthScale = GetScaleAtSplinePoint(Index).Z;

		if (StrengthScale <= 1)
			return FMath::Max(StrengthScale, 1.f);
		else
			return 1 + (StrengthScale - 1);// * StreamStrengthScaleModifier);
	}

	float GetStrengthScaleAtDistance(float DistanceAlongSpline)
	{
		float StrengthScale = GetScaleAtDistanceAlongSpline(DistanceAlongSpline).Z;	

		if (StrengthScale <= 1)
			return FMath::Max(StrengthScale, 1.f);
		else
			return 1 + (StrengthScale - 1);// * StreamStrengthScaleModifier);
	}	

	float GetStreamDistanceAtDistance(float DistanceAlongSpline)
	{
		return StreamDistance * GetDistanceScaleAtDistance(DistanceAlongSpline);
	}

	float GetStreamStrengthAtDistance(float DistanceAlongSpline)
	{
		return StreamStrength * GetStrengthScaleAtDistance(DistanceAlongSpline);
	}
}
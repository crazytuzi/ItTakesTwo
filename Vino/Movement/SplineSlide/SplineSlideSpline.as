import Peanuts.Spline.SplineMeshCreation;
import Peanuts.Spline.SplineActor;
import Vino.Movement.SplineSlide.SplineSlideSettings;
import Peanuts.Spline.AutoScaleSplineBoxComponent;
import Peanuts.Visualization.DummyVisualizationComponent;
import Vino.Camera.Settings.CameraLazyChaseSettings;

event void FOnSlidingStarted(AHazePlayerCharacter Player);
event void FOnSlidingStopped(AHazePlayerCharacter Player);
event void FOnSlideLanded(AHazePlayerCharacter Player);
event void FOnSlideJump(AHazePlayerCharacter Player);

struct FSplineSlideSplineJumpDestination
{
	// The spline we expect to be able to land on after jumping from this spline
	UPROPERTY()
	ASplineSlideSpline Spline;

	// Distance along spline where a jump would propel us. Useful when end of 
	// current spline would pass near an inaccessble part of spline.
	UPROPERTY()
	float ExpectedEntryDistance = 0.f;

	// Maximum allowed distance along spline past entry distance to where a landing 
	// is considered valid.
	UPROPERTY()
	float MaxDistancePastEntry = 8000.f;

	// Additional distance outside of spline used when considering we're going to land on spline
	UPROPERTY()
	float LandingSlack = 200.f;
}

UCLASS(Meta = (AutoExpandCategories = "Settings"))
class ASplineSlideSpline : ASplineActor
{
	UPROPERTY(DefaultComponent, Attach = Spline)
	UAutoScaleSplineBoxComponent NearbySplineBox;
	default NearbySplineBox.BoxMargin = 5000.f;

	UPROPERTY(DefaultComponent, Attach = Spline)
	UHazeSplineRegionContainerComponent RegionContainer;

	UPROPERTY()
	bool bEnabled = true;

	UPROPERTY()
	FSplineMeshData SplineMeshData;
	default SplineMeshData.Mesh = Asset("/Game/Environment/Props/Fantasy/Tree/Tree_Interior/Tree_SlideFloor_01.Tree_SlideFloor_01");
	default SplineMeshData.CollisionProfile = n"BlockAll";
	default SplineMeshData.CollisionType = ECollisionEnabled::QueryAndPhysics;
	default SplineMeshData.bSmoothInterpolate = true;

	UPROPERTY(NotEditable)
	FSplineMeshRangeContainer SplineMeshContainer;
	UPROPERTY(Category = Settings)
	const float SplineWidth = 2200.f;

	UPROPERTY(Category = Settings)
	const bool bLockToSplineWidth = true;

	UPROPERTY()
	FOnSlidingStarted OnSlidingStarted;

	UPROPERTY()
	FOnSlidingStopped OnSlidingStopped;

	UPROPERTY()
	FOnSlideLanded OnSlideLanded;

	UPROPERTY()
	FOnSlideJump OnSlideJump;

	// How long past the end of the spline are you still considered sliding
	// Fixes a bug where you would stop immediately at the end of a spline, when you should fall
	UPROPERTY(Category = Settings|Bounds)
	float SplineEndMargin = 50.f;

	// Slide will only activate if you are within the specified vertical distance
	UPROPERTY(Category = Settings|Bounds)
	bool bLimitActivationUpwards = true;

	UPROPERTY(Category = Settings|Bounds, Meta = (EditCondition = "bLimitActivationUpwards", EditConditionHides))
	float UpwardsLimit = 500.f;

	// Slide will only activate if you are within the specified vertical distance
	UPROPERTY(Category = Settings|Bounds)
	bool bLimitActivationDownwards = true;

	UPROPERTY(Category = Settings|Bounds, Meta = (EditCondition = "bLimitActivationDownwards", EditConditionHides))
	float DownwardsLimit = 500.f;

	UPROPERTY(Category = Settings)
	USplineSlideSettingsDataAsset Settings;
	default Settings = Asset("/Game/Blueprints/Movement/SplineSlide/SplineSlideDataAsset_Default.SplineSlideDataAsset_Default");

	UPROPERTY(Category = Settings)
	UHazeCapabilitySheet Sheet;
	default Sheet = Asset("/Game/Blueprints/Movement/SplineSlide/SplineSlideCapabilitySheet.SplineSlideCapabilitySheet");

	UPROPERTY(Category = Settings)
	bool bAllowJump = true;
	
	UPROPERTY(Category = Settings)
	bool bActivateCamera = true;

	UPROPERTY(Category = Settings, 	Meta = (EditCondition = "bActivateCamera", EditConditionHides))
	UCameraLazyChaseSettings CameraChaseSettings = nullptr;

	UPROPERTY(Category = Settings, 	Meta = (EditCondition = "bActivateCamera", EditConditionHides))
	UHazeCameraSettingsDataAsset CameraSettings = nullptr;

	// Add any splines we can jump to from this spline, so expected rotation of camera etc can update properly
	UPROPERTY(Category = Destinations)
	TArray<FSplineSlideSplineJumpDestination> JumpDestinations;

    UPROPERTY(DefaultComponent)
    UDummyVisualizationComponent JumpEntryDummyVisualizer;
    default JumpEntryDummyVisualizer.Color = FLinearColor::Yellow;
    default JumpEntryDummyVisualizer.DashSize = 50.f;
	default JumpEntryDummyVisualizer.ConnectionBase = Spline;

    UPROPERTY(DefaultComponent)
    UDummyVisualizationComponent JumpMaxDummyVisualizer;
    default JumpMaxDummyVisualizer.Color = FLinearColor::Red;
    default JumpMaxDummyVisualizer.DashSize = 50.f;
	default JumpMaxDummyVisualizer.ConnectionBase = Spline;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		Spline.ScaleVisualizationWidth = SplineWidth;

		FVector JumpVisLoc = Spline.GetLocationAtSplinePoint(Spline.LastSplinePointIndex, ESplineCoordinateSpace::Local);
		JumpEntryDummyVisualizer.ConnectionBaseOffset = JumpVisLoc;
		JumpEntryDummyVisualizer.ConnectedLocalLocations.Empty(JumpDestinations.Num());
		JumpMaxDummyVisualizer.ConnectionBaseOffset = JumpVisLoc;
		JumpMaxDummyVisualizer.ConnectedLocalLocations.Empty(JumpDestinations.Num());
		FTransform InverseSplineTransform = Spline.WorldTransform.Inverse();
		for (FSplineSlideSplineJumpDestination JumpDest : JumpDestinations)
		{
			if ((JumpDest.Spline == nullptr) || (JumpDest.Spline.Spline == nullptr))
				continue;
			FVector EntryLocalLoc = InverseSplineTransform.TransformPosition(JumpDest.Spline.Spline.GetLocationAtDistanceAlongSpline(JumpDest.ExpectedEntryDistance, ESplineCoordinateSpace::World));
			JumpEntryDummyVisualizer.ConnectedLocalLocations.Add(EntryLocalLoc);
			FVector MaxDistLocalLoc = InverseSplineTransform.TransformPosition(JumpDest.Spline.Spline.GetLocationAtDistanceAlongSpline(JumpDest.ExpectedEntryDistance + JumpDest.MaxDistancePastEntry, ESplineCoordinateSpace::World));
			JumpMaxDummyVisualizer.ConnectedLocalLocations.Add(MaxDistLocalLoc);
		}
#endif

		BuildMeshes();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (Sheet != nullptr)
			Capability::AddPlayerCapabilitySheetRequest(Sheet, EHazeCapabilitySheetPriority::Normal, EHazeSelectPlayer::Both);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		if (Sheet != nullptr)
			Capability::RemovePlayerCapabilitySheetRequest(Sheet, EHazeCapabilitySheetPriority::Normal, EHazeSelectPlayer::Both);
	}

	void BuildMeshes()
	{		
		FSplineMeshBuildData BuildData = MakeSplineMeshBuildData(this, Spline, SplineMeshData);

		if (!BuildData.IsValid())
			return;

		BuildSplineMeshes(BuildData, SplineMeshContainer);
	}

	float GetWidthAtDistanceAlongSpline(float DistanceAlongSpline) const
	{
		return Spline.GetScaleAtDistanceAlongSpline(DistanceAlongSpline).Y * SplineWidth;
	}

	FVector GetSplineForward(float DistanceAlongSpline) property
	{
		return Spline.GetTangentAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World).GetSafeNormal();
	}

	FVector GetSplineRight(float DistanceAlongSpline) property
	{
		return Spline.GetRightVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
	}

	FVector GetSplineUp(float DistanceAlongSpline) property
	{
		return Spline.GetUpVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
	}

	FSplineSlideSettings GetSplineSettings() property
	{
		if (Settings == nullptr)
			return FSplineSlideSettings();

		return Settings.Settings;
	}

	UFUNCTION()
	void SetSplineEnabled()
	{
		bEnabled = true;
	}

	UFUNCTION()
	void SetSplineDisabled()
	{
		bEnabled = false;
	}
}
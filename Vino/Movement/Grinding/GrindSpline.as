import Peanuts.Spline.SplineComponent;
import Peanuts.Spline.AutoScaleSplineBoxComponent;
import Peanuts.Spline.SplineMeshCreation;
import Vino.Movement.Grinding.GrindingReasons;
import Vino.Movement.Grinding.GrindSettings;
import Vino.Movement.Grinding.GrindSplineAutoConnectComponent;
import Vino.Movement.Grinding.Capabilities.GrindingEffectsData;
import Vino.Audio.PhysMaterials.PhysicalMaterialAudio;

// event void FOnGrindPlayerJumped(AHazePlayerCharacter Player);
event void FOnGrindPlayerAttached(AHazePlayerCharacter Player, EGrindAttachReason Reason);
event void FOnGrindPlayerTargeted(AHazePlayerCharacter Player, EGrindTargetReason Reason);
event void FOnGrindPlayerDetached(AHazePlayerCharacter Player, EGrindDetachReason Reason);

enum EGrindUser
{
	May,
	Cody,
	Both,
	None,
}

class AGrindspline : AHazeSplineActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeSplineComponent Spline;
#if Editor
	default Spline.bShouldVisualizeScale = true;
    default Spline.ScaleVisualizationWidth = 100.f;
#endif

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent LockSpline;
#if Editor
	default LockSpline.bHazeIsEditable = false;
#endif

	UPROPERTY(DefaultComponent, Attach = Spline)
	UAutoScaleSplineBoxComponent NearbySplineBox;
	default NearbySplineBox.BoxMargin = 3500.f;
	default NearbySplineBox.bVisible = false;

	UPROPERTY(DefaultComponent, Attach = Spline)
	UGrindSplineAutoConnectComponent StartConnection;
	default StartConnection.SetupSplines(Spline, LockSpline);
	default StartConnection.BoxExtent = FVector(50.f, 50.f, 50.f);
	default StartConnection.bConnectForward = false;
	default StartConnection.bConnectBackward = true;
	default StartConnection.bEnterFacingForward = true;
	
	UPROPERTY(DefaultComponent, Attach = Spline)
	UGrindSplineAutoConnectComponent EndConnection;
	default EndConnection.SetupSplines(Spline, LockSpline);
	default EndConnection.BoxExtent = FVector(50.f, 50.f, 50.f);
	default EndConnection.bConnectForward = true;
	default EndConnection.bConnectBackward = false;
	default EndConnection.bEnterFacingForward = false;

	UPROPERTY(DefaultComponent, Attach = Spline)
	UHazeSplineRegionContainerComponent RegionContainer;
	default RegionContainer.RegisterRegionTypeFromName(n"GrindingBlockJumpRegionComponent");
	default RegionContainer.RegisterRegionTypeFromName(n"GrindJumpToLocationRegionComponent");
	default RegionContainer.RegisterRegionTypeFromName(n"GrindingCustomSpeedRegionComponent");
	default RegionContainer.RegisterRegionTypeFromName(n"GrindJumpToGrindSplineRegionComponent");

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY()
	AActor IgnoreActorWhileGrinding = nullptr;

	// Only some movement is allowed for grindspline actors.
	UPROPERTY()
	bool bImMovableAndIKnowWhatImDoing = false;

	UPROPERTY(NotEditable)
	FSplineMeshRangeContainer SplineMeshContainer;

	UPROPERTY(Category = "Spline")
	float OverrideLength = 0.f;

	UPROPERTY(Category = "Spline")
	float HeightOffset = 0.f;

	UPROPERTY(Category = "SplineMesh")
	UStaticMesh Mesh;

	UPROPERTY(Category = "SplineMesh")
	TArray<UStaticMesh> ReplacementMeshes;

	UPROPERTY(Category = "Audio")
	UPhysicalMaterialAudio AudioPhysmatOverride;

	UPROPERTY(Category = "Audio", meta = (EditCondition = "AudioPhysmatOverride == nullptr"))
	int AudioMaterialIndex = 0;
	
	UPROPERTY(Category = "Audio")
	bool bAudioSetSplineLengthRTPC = true;

	UPROPERTY(Category = "Audio")
	bool bAudioSplineLengthRtpcAbsolute = false;
	
	UPROPERTY(Category = "Audio")
	bool bAudioSplineDirectionRtpcInvert = false;

	UPROPERTY(Category = "Audio")
	bool bSeekOnLength = false;
	
	UPROPERTY(Category = "Audio")
	bool bRetriggerOnDirectionChange = false;
		
	UPROPERTY(Category = "Audio")
	float InterpolateDirectionRtpc = 0.f;

	// Value between 0 - 1 to subtract from calculated seek values, to make them less extreme
	UPROPERTY(Category = "Audio")
	float SeekSlewValue = 0.f;

	UPROPERTY(Category = "Audio")
	bool bSpatializeDismount = false;

	UPROPERTY(Category = "SplineMesh")
	FName CollisionProfile = NAME_None;

	UPROPERTY(Category = "SplineMesh")
	bool bIsQueryOnly = true;

	UPROPERTY(Category = "Spline")
	TArray<UMaterialInstance> MaterialOverride;

	UPROPERTY(Category = "Spline")
	float CullingDistanceMultiplier = 1.0f;

	UPROPERTY(Category = "Spline")
	bool bCastShadow = true;

	UPROPERTY(Category = Settings)
	EGrindSplineTravelDirection TravelDirection;

	UPROPERTY(Category = Settings)
	EGrindUser AllowedUsers = EGrindUser::Both;

	UPROPERTY(Category = Settings)
	TArray<FName> CapabilityBlocks;
	default CapabilityBlocks.Add(CapabilityTags::Interaction);

	UPROPERTY(Category = Settings)
	UGrindingEffectsData GrindingEffectsData = Asset("/Game/Blueprints/Movement/Grinding/DA_GrindingEffects_Default.DA_GrindingEffects_Default");

	UPROPERTY(Category = "Settings|Enters")
	bool bCanWalkOn = true;
	UPROPERTY(Category = "Settings|Enters")
	bool bCanLandOn = true;
	UPROPERTY(Category = "Settings|Enters")
	bool bCanGrappleTo = true;
	UPROPERTY(Category = "Settings|Enters")
	EGrindSplineTransferDirection TransferDirection = EGrindSplineTransferDirection::TransferBidirectional;
	UPROPERTY(Category = "Settings|Enters")
	bool bTransferIgnoreCollisionTest = false;
	UPROPERTY(Category = "Settings|Enters")
	float GrappleRange = GrindSettings::Grapple.MaxRange;
	// How many units at the start of the spline is not allowed to be grappled to
	UPROPERTY(Category = "Settings|Enters")
	float GrappleBlockMarginStart = 0.f;
	// How many units at the end of the spline is not allowed to be grappled to
	UPROPERTY(Category = "Settings|Enters")
	float GrappleBlockMarginEnd = 0.f;

	UPROPERTY(Category = "Settings|Grinding")
	bool bGrindingAllowed = true;
	UPROPERTY(Category = "Settings|Grinding")
	FGrindBasicSpeedSettings CustomSpeed;
	UPROPERTY(Category = "Settings|Grinding")
	bool bCanJump = true;
	UPROPERTY(Category = "Settings|Grinding")
	bool bCanDash = true;
	UPROPERTY(Category = "Settings|Grinding")
	bool bCanTurnAround = true;
	UPROPERTY(Category = "Settings|Grinding")
	bool bCanCancel = true;
	UPROPERTY(Category = "Settings|Grinding")
	bool bOnlyStickInputBreakLock = false;
	UPROPERTY(Category = "Settings|Grinding")
	bool bHardSplineLock = false;

	// How far ahead the camera will look to calculate the camera desired direction
	UPROPERTY(Category = "Settings|Camera")
	float DesiredDirectionProjectionDistance = 1800.f;
	UPROPERTY(Category = "Settings|Camera")
	bool bAllowHorizontalCameraOffset = true;
	
	// Camera pivot is offset by this when grinding along this spline
	UPROPERTY(Category = "Settings|Camera")
	FVector CameraAdditionalPivotOffset = FVector(0.f, 0.f, -100.f);

	UPROPERTY()
	FOnGrindPlayerAttached OnPlayerAttached;
	UPROPERTY()
	FOnGrindPlayerTargeted OnPlayerTargeted;
	UPROPERTY()
	FOnGrindPlayerDetached OnPlayerDetached;

	UPROPERTY()
	bool bBoolToForceConstructionScript;

	default UpdateOverlapsMethodDuringLevelStreaming = EActorUpdateOverlapsMethod::AlwaysUpdate;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		BuildMeshes();
		SetSplineMeshComponentSettings();
		
		LockSpline.CopyOtherSpline(Spline);
		LockSpline.FlattenSpline();

		if (Spline.IsClosedLoop())
		{
			StartConnection.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			EndConnection.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			StartConnection.SetVisibility(false);
			EndConnection.SetVisibility(false);
		}
		else
		{
			StartConnection.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
			EndConnection.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
			StartConnection.SetVisibility(true);
			EndConnection.SetVisibility(true);
			
			UpdateAutoConnectLocations();
		}

		if (bImMovableAndIKnowWhatImDoing)
			Spline.SetMobility(EComponentMobility::Movable);
		else
			Spline.SetMobility(EComponentMobility::Static);
	}

	UFUNCTION(BlueprintOverride)
	void PostEditChangeProperties()
	{
		SetSplineMeshComponentSettings();
	}

	UFUNCTION(BlueprintPure)
	TArray<USplineMeshComponent> GetSplineMeshComponents()
	{
		TArray<USplineMeshComponent> Result;
		for (int i = 0; i < SplineMeshContainer.SplinesMeshes.Num(); i++)
		{
			Result.Add(SplineMeshContainer.SplinesMeshes[i].SplineMesh);
		}
		return Result;
	}

	void UpdateAutoConnectLocations()
	{		
		// Move the connections to end/start of spline
		FTransform StartTransform = Spline.GetTransformAtTime(0.f, ESplineCoordinateSpace::Local);
		FTransform EndTransform = Spline.GetTransformAtTime(Spline.Duration, ESplineCoordinateSpace::Local);
		StartConnection.SetRelativeTransform(StartTransform);
		EndConnection.SetRelativeTransform(EndTransform);

		StartConnection.EntryDistance = 0.f;
		StartConnection.FlatEntryDistance = 0.f;

		EndConnection.EntryDistance = Spline.SplineLength;
		EndConnection.FlatEntryDistance = LockSpline.SplineLength;
	}

	void SetSplineMeshComponentSettings()
	{
		// Get all mesh components, will also include spline mesh components,
		TArray<UStaticMeshComponent> MeshComponents;
		this.GetComponentsByClass(MeshComponents);

		// add exposed setting.
		for (UStaticMeshComponent MeshComponent : MeshComponents)
			MeshComponent.SetCastShadow(bCastShadow);
	}

	void BuildMeshes()
	{
		// If artists have created a merged spline mesh, allow using that one instead of generating new components
		// along the spline
		if (ReplacementMeshes.Num() > 0)
		{
			for (UStaticMesh ReplacementMesh : ReplacementMeshes)
			{
				if (ReplacementMesh == nullptr)
					continue;
				UHazePropComponent Component = Cast<UHazePropComponent>(this.CreateComponent(UHazePropComponent::StaticClass(), ReplacementMesh.GetName()));
				Component.StaticMesh = ReplacementMesh;

				// Apply inverse rotation of the owning actor to the component to once again match the xform,
				Component.SetRelativeRotation(this.GetActorRotation().GetInverse());
				// Component.SetWorldRotation(FRotator::ZeroRotator);
			}
			return;
		}

		if (Mesh == nullptr)
			return;
		
		FSplineMeshBuildData BuildData;
		BuildData.OwningActor = this;
		BuildData.Mesh = Mesh;		
		BuildData.MaterialOverride = MaterialOverride;
		BuildData.Spline = Spline;

		BuildData.SegmentLength = Mesh.BoundingBox.Extent.X * 2.f;
		if (OverrideLength > BuildData.SegmentLength)
			 BuildData.SegmentLength = OverrideLength;

		BuildData.CollisionProfile = CollisionProfile;
		BuildData.CollisionType = ECollisionEnabled::QueryAndPhysics;
		if (bIsQueryOnly || CollisionProfile == NAME_None)
			BuildData.CollisionType = ECollisionEnabled::QueryOnly;

		BuildData.CullingDistanceMultiplier = CullingDistanceMultiplier;

		BuildSplineMeshes(BuildData, SplineMeshContainer);
	}

	UFUNCTION()
	void EnableGrindsplineForPlayer(AHazePlayerCharacter Player)
	{
		if (AllowedUsers == EGrindUser::None)
			AllowedUsers = Player.IsCody() ? EGrindUser::Cody : EGrindUser::May;
		else if (Player.IsCody() && AllowedUsers == EGrindUser::May)
			AllowedUsers = EGrindUser::Both;
		else if (Player.IsMay() && AllowedUsers == EGrindUser::Cody)
			AllowedUsers = EGrindUser::Both;
	}

	UFUNCTION()
	void DisableGrindsplineForPlayer(AHazePlayerCharacter Player)
	{
		if (AllowedUsers == EGrindUser::Both)
			AllowedUsers = Player.IsCody() ? EGrindUser::May : EGrindUser::Cody;
		else if (Player.IsCody() && AllowedUsers == EGrindUser::Cody)
			AllowedUsers = EGrindUser::None;
		else if (Player.IsMay() && AllowedUsers == EGrindUser::May)
			AllowedUsers = EGrindUser::None;
	}

	UFUNCTION()
	bool PlayerIsAllowdToUse(AHazePlayerCharacter Player) const
	{
		if (AllowedUsers == EGrindUser::Both)
			return true;

		if (Player.IsCody())
			return AllowedUsers == EGrindUser::Cody;
		else
			return AllowedUsers == EGrindUser::May;
	}

	UFUNCTION(BlueprintPure)
	bool IsLockedSpline() const
	{
		if (TravelDirection != EGrindSplineTravelDirection::Bidirectional)
			return true;

		return false;
	}

	UFUNCTION(BlueprintPure)
	bool IsFreeformSpline() const
	{
		if (TravelDirection == EGrindSplineTravelDirection::Bidirectional)
			return true;

		return false;
	}

	UFUNCTION()
	void EnableGrinding()
	{
		bGrindingAllowed = true;
	}

	UFUNCTION()
	void DisableGrinding()
	{
		bGrindingAllowed = false;
	}
}

struct FGrindActorSwitchData
{
	UPROPERTY()
	AActor OldActor = nullptr;

	UPROPERTY()
	UStaticMesh Mesh = nullptr;
	
	UPROPERTY()
	float OverrideLength = 0.f;

	UPROPERTY()
	float HeightOffset = 0.f;

	UPROPERTY()
	TArray<UMaterialInstance> MaterialOverrides;

	UPROPERTY()
	UHazeSplineComponent SplineComponentToCopy = nullptr;

	bool IsValid() const
	{
		return OldActor != nullptr && Mesh != nullptr && SplineComponentToCopy != nullptr;
	}
}

UFUNCTION()
void SwitchActorToNewGrindActor(FGrindActorSwitchData Data)
{
#if Editor
	if (!ensure(Data.IsValid()))
		return;

	AGrindspline GrindActor = Cast<AGrindspline>(SpawnActor(AGrindspline::StaticClass(), Level = Data.OldActor.Level));
	if (Data.OldActor.AttachParentActor != nullptr)	
		GrindActor.AttachToActor(Data.OldActor.AttachParentActor, Data.OldActor.AttachParentSocketName, EAttachmentRule::SnapToTarget);

	GrindActor.Mesh = Data.Mesh;
	GrindActor.Spline.CopyFromOtherSpline(Data.SplineComponentToCopy);
	GrindActor.SetActorTransform(GrindActor.ActorTransform);
	GrindActor.MaterialOverride = Data.MaterialOverrides;
	GrindActor.OverrideLength = Data.OverrideLength;
	GrindActor.HeightOffset = Data.HeightOffset;
	GrindActor.RerunConstructionScripts();

	if (!Data.OldActor.ActorLabel.Contains("BP_SplineMesh"))
		GrindActor.SetActorLabel(Data.OldActor.ActorLabel);
#endif
}

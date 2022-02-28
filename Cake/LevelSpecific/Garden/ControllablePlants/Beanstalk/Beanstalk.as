import Vino.Movement.Components.MovementComponent;
import Peanuts.Spline.SplineComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.Camera.Components.CameraDetacherComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.BeanstalkLeafPair;
import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.BeanstalkRoot;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlant;
import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.BeanstalkTags;
import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.BeanstalkSettings;
import Cake.LevelSpecific.Garden.ControllablePlants.Soil.SubmersibleSoilBeanstalk;
import Vino.Movement.Components.LedgeGrab.LedgeGrabComponent;
import Cake.LevelSpecific.Garden.VOBanks.GardenVegetablePatchVOBank;

#if !RELEASE
const FConsoleVariable CVar_BeanstalkDebugDraw("Garden.BeanstalkDebugDraw", 0);
#endif // !RELEASE

settings UBeanstalkSettingsDefault for UBeanstalkSettings
{

}

settings BeanStalkCameraLazyChaseSettings for UCameraLazyChaseSettings
{
	BeanStalkCameraLazyChaseSettings.AccelerationDuration = 2.5f;

};


class UBeanstalkCameraSpringArmSettingsDataAsset : UHazeCameraSpringArmSettingsDataAsset
{

}

enum EBeanstalkState
{
	Emerging,
	Submerging,
	Hurt,
	Active,
	Inactive
}

FRotator GetClampedLeafRotation(AActor Owner, FRotator InRotation)
{
	ABeanstalk Beanstalk = Cast<ABeanstalk>(Owner);

	if(Beanstalk != nullptr)
		return Beanstalk.GetClampedLeafRotation(InRotation);

	return InRotation;
}



UCLASS(Abstract)
class ABeanstalk : AControllablePlant
{
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USphereComponent CollisionComp;
	default CollisionComp.SphereRadius = 50.f;
	default CollisionComp.CollisionProfileName = n"NoCollision";
	default CollisionComp.bGenerateOverlapEvents = true;

	UPROPERTY(DefaultComponent, Attach = CollisionComp)
	USceneComponent HeadRotationNode;

	UPROPERTY(DefaultComponent, Attach = HeadRotationNode)
	USceneComponent RotationOffsetNode;

	UPROPERTY(DefaultComponent, Attach = RotationOffsetNode)
	USceneComponent YawAxis;

	UPROPERTY(DefaultComponent, Attach = YawAxis)
	USceneComponent PitchAxis;

	UPROPERTY(DefaultComponent, Attach = PitchAxis)
	UHazeCharacterSkeletalMeshComponent BeanstalkHead;

	UPROPERTY(DefaultComponent)
	UHazeAsyncTraceComponent AsyncTrace;

	UPROPERTY(DefaultComponent, Attach = BeanstalkHead)
	USphereComponent PlayerCollision;
	default PlayerCollision.bGenerateOverlapEvents = false;
	default PlayerCollision.CollisionProfileName = n"BlockOnlyPlayerCharacter";

	UPROPERTY()
	UGardenVegetablePatchVOBank VegetablePatchVOBank;

	UPROPERTY(Category = Settings)
	protected UBeanstalkSettings DefaultBeanstalkSettings = UBeanstalkSettingsDefault;
	UPROPERTY(Category = Settings)
	UBeanstalkSettings SubmergeSettings = UBeanstalkSettingsDefault;
	UBeanstalkSettings BeanstalkSettings;

	// Number of maximum available leaf pairs at one time.
	UPROPERTY(Category = LeafPair)
	int LeafPairsMaximum = 3;

	// Required distance between leaf pairs to be spawned.
	UPROPERTY(Category = LeafPair)
	float LeafPairDistanceMinimum = 750.0f;

	// Remove a leaf pair when the beanstalk is this distance or closer.
	UPROPERTY(Category = LeafPair, meta = (DisplayName = "RemoveLeafPairDistance"))
	float _RemoveLeafPairDistance = 250.0f;

	float GetRemoveLeafPairDistance() const property
	{
		if(CurrentState == EBeanstalkState::Submerging)
			return _RemoveLeafPairDistance * 2.0f;

		return _RemoveLeafPairDistance;
	}

	UPROPERTY(Category = LeafPair)
	float LeafPairPitchLimit = 25.0f;

	UPROPERTY(Category = LeafPair)
	float LeafPairRollLimit = 15.0f;

	// As long as this is zero, Beanstalk should be able to spawn leaf pairs. 
	private int LeafPairCounter = 0;

	UPROPERTY(Category = LeafPair)
	bool bCanSpawnLeafPair = true;

	UPROPERTY(meta = (DisplayName = "BeanstalkMaxLength"))
	float _BeanstalkMaxLength = 8000.0f;

	float GetBeanstalkMaxLength() const property
	{
		if(BeanstalkSoil != nullptr && BeanstalkSoil.bOverrideMaxLength)
			return BeanstalkSoil.BeanstalkMaxLength;

		return _BeanstalkMaxLength;
	}

	float MinimumMovementDistance = 0.0f;

	UPROPERTY(meta = (ClampMin = 0, DisplayName = "MaxHeight"))
	float _MaxHeight = 6000.0f;

	UPROPERTY(meta = (ClampMin = 0, DisplayName = "MinHeight"))
	float _MinHeight = 6000.0f;

	float GetMinHeight() const property
	{
		if(BeanstalkSoil != nullptr && BeanstalkSoil.bOverrideMinHeight)
			return BeanstalkSoil.BeanstalkMinHeight;

		return _MinHeight;
	}

	float GetMaxHeight() const property
	{
		if(BeanstalkSoil != nullptr && BeanstalkSoil.bOverrideMaxHeight)
			return BeanstalkSoil.BeanstalkMaxHeight;

		return _MaxHeight;
	}

	float AppearVFXDistance = 0.0f;

	UPROPERTY(Category = Tutorial)
	FText Revert;

	UPROPERTY(Category = Tutorial)
	FText Extend;

	UPROPERTY(Category = Tutorial)
	FText GrowLeaves;

	UPROPERTY(Category = Tutorial)
	FText Turn;

	float WantedZFacing = 0.0f;
	float WantedMovementDirection = 0.0f;
	float StopDistance = 0.0f;
	FVector WantedFacingDirection = FVector::ForwardVector;
	FVector RawInput = FVector::ZeroVector;

	FVector BeanstalkStartLocation;
	float CurrentVelocity;

	EBeanstalkState CurrentState = EBeanstalkState::Inactive;

	float InputModifier = 1.0f;
	float InputModifierElapsed = 0.0f;

	bool bIsStretching = false;

	//Checked by tutorialPrompt logic in beanstalkSpawnCapability.
	bool bHasExtended = false;

	bool bWasReverseStopped = false;
	bool bUseTopViewCamera = false;
	float TopViewYawAngle = 0.0f;

	float SegmentLength = 150.0f;

	private int NetworkSpawnCounter = 0;

	//ABeanstalkLeafPair LeafPairPreview = nullptr;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LeafPreviewRoot;
	default LeafPreviewRoot.bAbsoluteLocation = true;
	default LeafPreviewRoot.bAbsoluteRotation = true;
	default LeafPreviewRoot.bAbsoluteScale = true;

	UPROPERTY(DefaultComponent, Attach = LeafPreviewRoot)
	UStaticMeshComponent LeftLeafPreview;
	default LeftLeafPreview.CollisionEnabled = ECollisionEnabled::NoCollision;
	
	UPROPERTY(DefaultComponent, Attach = LeafPreviewRoot)
	UStaticMeshComponent RightLeafPreview;
	default RightLeafPreview.CollisionEnabled = ECollisionEnabled::NoCollision;

	UHazeCameraComponent Camera;

	UPROPERTY(Category = Animation)
	UBlendSpace BeanstalkBlendSpace;

	UPROPERTY(Category = Animation)
	UAnimSequence AppearAnim;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;

	bool bCanExitBeanstalk = false;

	bool CanExitPlant() const override
	{
		return false;
	}

	default CrumbComp.IncludeCustomParamsInActorReplication(FVector::ZeroVector, FRotator::ZeroRotator, this);

	UPROPERTY(Category = Camera)
	UBeanstalkCameraSpringArmSettingsDataAsset CameraSettings;

	default CameraLazyChaseSettings = BeanStalkCameraLazyChaseSettings;

	bool bBeanstalkActive = false;
	bool bSpawningDone = false;

	ASubmersibleSoilBeanstalk BeanstalkSoil = nullptr;

	UPROPERTY(EditDefaultsOnly)
	UStaticMesh BeanstalkMesh;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance BeanstalkMaterial;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ABeanstalkLeafPair> LeafPairClass;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect LeafReadyForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect SpawnLeafForceFeedback;

	UPROPERTY(DefaultComponent, NotVisible)
	UHazeSplineFollowComponent SplineFollow;

	TArray<ABeanstalkLeafPair> LeafPairCollection;
	// When we despawn leaf pairs we put them back in this list and re-use them.
	TArray<ABeanstalkLeafPair> CachedLeafPairs;

	TArray<USplineMeshComponent> ActiveSplineMeshes;
	TArray<USplineMeshComponent> AllSplineMeshes;

	FHazeSplineSystemPosition SplineSystemPosition;

	float LastLeafPairDistance;

	FVector2D BeanstalkLengthRange = FVector2D(0.f, 10000.f);

	int NumberOfSplineMeshes = 30;
	int NumberOfActiveSplineMeshes = 0;

	float MovementDirection = 0.0f;

	bool bDrawEnvironmentScanHitLocations = false;

	ABeanstalkRoot BeanstalkRoot;

	UPROPERTY(Category = Audio)
	TSubclassOf<UHazeCapability> AudioCapabilityClass;

	UPROPERTY(Category = Audio)
	TSubclassOf<UHazeCapability> LeafAudioCapabilityClass;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSplineComponent SplineComp;
	default SplineComp.AutoTangents = true;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSplineComponent VisualSpline;
	default VisualSpline.AutoTangents = true;

	// Store visual splines local locations so we can offset them slightly.
	TArray<FVector> LocalSplinePoints;

	// Used as a copy when reversing
	UPROPERTY(DefaultComponent, Attach = RootComp, NotVisible)
	UHazeSplineComponent ReversalSplineComp;
	default ReversalSplineComp.AutoTangents = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ApplySettings(DefaultBeanstalkSettings, this);
		BeanstalkSettings = UBeanstalkSettings::GetSettings(this);
		MovementComponent.Setup(CollisionComp);
		Camera = UHazeCameraComponent::Get(OwnerPlayer);

		AddCapabilities();
		SetupSplineMeshes();
		SetActorHiddenInGame(true);
	}

	private float EnvironmentHitFraction = 0.0f;

	UFUNCTION(BlueprintPure)
	float GetEnvironmentHitFraction() const
	{
		return EnvironmentHitFraction;
	}

	bool bPerformingAsyncTrace = false;

	void PerformAsyncTrace()
	{
		if(bPerformingAsyncTrace)
			return;

		bPerformingAsyncTrace = true;

		FHazeTraceParams TraceParams;
		TraceParams.InitWithTraceChannel(ETraceTypeQuery::Visibility);
		TraceParams.IgnoreActor(this);
		TraceParams.IgnoreActor(this, false);
		TraceParams.IgnoreActor(Game::Cody, false);
		TraceParams.IgnoreActor(Game::Cody);

		TraceParams.SetToSphere(BeanstalkSettings.EnvironmentSphereRadius);
		TraceParams.From = HeadCenterLocation - HeadRotationNode.ForwardVector * 10.0f;
		TraceParams.To = HeadCenterLocation + HeadRotationNode.ForwardVector * 10.0f;

		AsyncTrace.TraceSingle(TraceParams, this, n"Beanstalk_EnvironmentScan", FHazeAsyncTraceComponentCompleteDelegate(this, n"Handle_AsyncTraceComplete"));
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_AsyncTraceComplete(UObject InInstigator, FName TraceId, TArray<FHitResult> Obstructions)
	{
		bPerformingAsyncTrace = false;
		EnvironmentHitFraction = 0.0f;

		if(Obstructions.Num() == 0)
			return;

		float ClosestDistanceSq = Math::MaxFloat;
		const float CollisionRadius = CollisionComp.SphereRadius;
		const float CollisionRadiusSq = FMath::Square(CollisionRadius);
		const FVector Origin = HeadCenterLocation;
		const float OffsetSq = FMath::Square(BeanstalkSettings.EnvironmentScanOffset);

		for(FHitResult Hit : Obstructions)
		{
			const float HitDistanceSq = OffsetSq + Origin.DistSquared(Hit.ImpactPoint) - CollisionRadiusSq;
			if(HitDistanceSq < ClosestDistanceSq)
				ClosestDistanceSq = HitDistanceSq;

#if TEST
			if(bDrawEnvironmentScanHitLocations)
			{
				System::DrawDebugPoint(Hit.ImpactPoint, 20.0f, FLinearColor::Red, 0.1f);
			}
#endif // TEST
		}
		
		const float EnvironmentScanRadiusSq = OffsetSq + FMath::Square(BeanstalkSettings.EnvironmentSphereRadius) - CollisionRadiusSq;
		EnvironmentHitFraction = (FMath::Clamp(ClosestDistanceSq / EnvironmentScanRadiusSq, 0.0f, 1.0f) - 1.0f) * -1.0f;
	}

	void StartBlendSpace()
	{
		if(BeanstalkHead.SkeletalMesh != nullptr && BeanstalkBlendSpace != nullptr)
		{
			FHazePlayBlendSpaceParams Params;
			Params.BlendSpace = BeanstalkBlendSpace;
			Params.PlayRate = 1.0f;
			BeanstalkHead.PlayBlendSpace(Params);
		}
	}

	void AddCapabilities()
	{
		AddCapability(n"BeanstalkSpawnCapability");
		AddCapability(n"BeanstalkMovementCapability");
		AddCapability(n"BeanstalkStemCapability");
		AddCapability(n"BeanstalkLeafPreviewCapability");
		AddCapability(n"BeanstalkSpawnLeafCapability");
		AddCapability(n"BeanstalkRemoveLeafCapability");
		AddCapability(n"BeanstalkInputModifierCapability");
		AddCapability(n"BeanstalkEmergeCapability");
		AddCapability(n"BeanstalkSubmergeCapability");
		AddCapability(n"BeanstalkHurtCapability");
		AddCapability(AudioCapabilityClass);
		AddCapability(LeafAudioCapabilityClass);

		AddDebugCapability(n"BeanstalkDebugCapability");
	}

	void SetupSplineMeshes()
	{
		SplineComp.DetachFromParent(true);
		ReversalSplineComp.DetachFromParent(true);
		VisualSpline.DetachFromParent(true);

		BeanstalkRoot = Cast<ABeanstalkRoot>(SpawnActor(ABeanstalkRoot::StaticClass(), GetActorLocation()));
		//BeanstalkRoot.RootComp.SetMobility(EComponentMobility::Movable);
		InstantiateSplineMeshes(40);
	}

	private void InstantiateSplineMeshes(int NumToInstantiate)
	{
		BeanstalkRoot.RootComp.SetMobility(EComponentMobility::Static);
		for (int Index = 0, Count = NumToInstantiate; Index < Count; ++Index)
		{
			USplineMeshComponent NewSplineMesh = USplineMeshComponent::Create(BeanstalkRoot);
			NewSplineMesh.SetMobility(EComponentMobility::Movable);
			NewSplineMesh.SetStaticMesh(BeanstalkMesh);
			NewSplineMesh.SetMaterial(0, BeanstalkMaterial);
			NewSplineMesh.SetCollisionProfileName(n"NoCollision");
			NewSplineMesh.SetGenerateOverlapEvents(false);
			AllSplineMeshes.Add(NewSplineMesh);
		}
		BeanstalkRoot.RootComp.SetMobility(EComponentMobility::Movable);
	}

	void EnableBeanstalkCollisionSphere()
	{
		CollisionComp.SetCollisionProfileName(n"PlayerCharacter");
		PlayerCollision.SetCollisionProfileName(n"BlockOnlyPlayerCharacter");
	}

	void DisableBeanstalkCollisionSphere()
	{
		CollisionComp.SetCollisionProfileName(n"NoCollision");
		PlayerCollision.SetCollisionProfileName(n"NoCollision");
	}

	void BlockLeafPair()
	{
		if(!HasControl())
			return;
		
		const int OldCount = LeafPairCounter;
		LeafPairCounter++;

		if(OldCount <= 0 && LeafPairCounter > 0)
			NetSetCanSpawnLeafPair(false);
	}

	void UnblockLeafPair()
	{
		if(!HasControl())
			return;

		int OldCount = LeafPairCounter;
		LeafPairCounter--;

		if(OldCount > 0 && LeafPairCounter <= 0)
			NetSetCanSpawnLeafPair(true);
	}

	UFUNCTION(NetFunction)
	private void NetSetCanSpawnLeafPair(bool bValue)
	{
		bCanSpawnLeafPair = bValue;
	}

	bool IsLeafPairBlocked() const
	{
		return !bCanSpawnLeafPair;
	}

	void PreActivate(FVector InPlayerLocation, FRotator InPlayerRotation) override
	{
		AddPlayerSheet();
		bCanExitBeanstalk = false;
		bBeanstalkActive = true;
		LastLeafPairDistance = 0.0f;
	}

	void OnActivatePlant()
	{

	}

	void BeanstalkFullySpawned()
	{
		bIsPlantActive = true;
	}

	void AttemptToSpawnLeaf()
	{
		SetCapabilityActionState(n"SpawnLeaf", EHazeActionState::ActiveForOneFrame);
	}

	void PreDeactivate() override
	{
		
		bIsPlantActive = false;
		bBeanstalkActive = false;
		LastLeafPairDistance = 0.0f;
	}

	void OnDeactivatePlant()
	{
		OnUnpossessPlant(PlayerLocationOnEnter, PlayerRotationOnEnter, EControllablePlantExitBehavior::ExitSoil);
		SetCapabilityActionState(n"Audio_OnExitSoil", EHazeActionState::ActiveForOneFrame);
	}

	void UpdatePlayerInput(FVector NewInput, float NewMovementDirection, bool bShouldSpawnLeafPair, bool bShouldExit, bool bInWasReverseStopped)
	{
		float DistanceFromStart = FMath::Abs(BeanstalkStartLocation.Z - HeadRotationNode.WorldLocation.Z);

		if(CurrentState == EBeanstalkState::Active && bShouldExit)
			CurrentState = EBeanstalkState::Submerging;
		else if(CurrentState == EBeanstalkState::Submerging 
		&& NewMovementDirection > 0.0f
		&& DistanceOnSplineCurrent > (StopDistance * 1.2f))
		{
			CurrentState = EBeanstalkState::Active;
		}
			
		if (bIsPlantActive)
		{
			bWasReverseStopped = bInWasReverseStopped;
			const FRotator ViewRotation = Camera.GetViewRotation();
			const FVector Up = MovementComponent.WorldUp * NewInput.Y;
			const FVector Right = HeadRotationNode.GetRightVector() * NewInput.X;
			const FVector ProjectedDirection = (Up + Right);
			WantedZFacing = NewInput.Y;
			WantedFacingDirection = (HeadRotationNode.GetForwardVector() + (ProjectedDirection * NewInput.Size()));
			WantedMovementDirection = NewMovementDirection;
			RawInput.X = NewInput.X;
			RawInput.Y = NewInput.Y;
			bWantsToExit = bShouldExit;

#if !RELEASE
			if(CVar_BeanstalkDebugDraw.GetInt() == 1)
			{
				const float ArrowSize = 5.0f;
				const float ArrowLength = 400.0f;
				const FVector BeanstalkHeadLocation = HeadRotationNode.GetWorldLocation();
				
				System::DrawDebugArrow(BeanstalkHeadLocation, BeanstalkHeadLocation + (ProjectedDirection * ArrowLength));
				System::DrawDebugArrow(BeanstalkHeadLocation, BeanstalkHeadLocation + (HeadRotationNode.GetForwardVector() * ArrowLength), ArrowSize, FLinearColor::Green);
				System::DrawDebugArrow(BeanstalkHeadLocation, BeanstalkHeadLocation + (WantedFacingDirection * ArrowLength), ArrowSize, FLinearColor::Red);
			}
#endif // !RELEASE

			if(bShouldSpawnLeafPair)
			{
				SetCapabilityActionState(BeanstalkTags::SpawnLeaf, EHazeActionState::ActiveForOneFrame);
			}
		}
	}

	FVector GetLastSplineLocation() const
	{
		return SplineComp.NumberOfSplinePoints > 0 ? SplineComp.GetLocationAtSplinePoint(SplineComp.NumberOfSplinePoints - 2, ESplineCoordinateSpace::World) : GetActorLocation();
	}

	bool ShouldAddNewSegment() const
	{
		if(SplineComp.NumberOfSplinePoints > 1)
		{
			const float CurrentSplineSegmentDistance = FMath::Abs(SplineComp.GetDistanceAlongSplineAtWorldLocation(HeadCenterLocation) - SplineComp.GetDistanceAlongSplineAtSplinePoint(SplineComp.NumberOfSplinePoints - 2));
			return CurrentSplineSegmentDistance >= SegmentLength;
		}

		return false;
	}

	void AddNewSegment(FVector LocationToAdd)
	{
		AddSplinePoint(LocationToAdd);
		AddSplineMesh();
		UpdateSplineMeshes();
	}

	void AddSplineMesh()
	{
		NumberOfActiveSplineMeshes++;

		if(NumberOfActiveSplineMeshes > AllSplineMeshes.Num() - 1)
		{
			InstantiateSplineMeshes(20);
		}

		ActiveSplineMeshes.Add(AllSplineMeshes[NumberOfActiveSplineMeshes]);
	}

	void AddSplinePoint(FVector SplinePointToAdd)
	{
		SplineComp.AddSplinePoint(SplinePointToAdd, ESplineCoordinateSpace::World, false);
		VisualSpline.AddSplinePoint(SplinePointToAdd, ESplineCoordinateSpace::World, false);
		//SplineComp.AddSplinePointAtIndex(SplinePointToAdd, SplineComp.NumberOfSplinePoints - 2, ESplineCoordinateSpace::World, false);
		//VisualSpline.AddSplinePointAtIndex(SplinePointToAdd, SplineComp.NumberOfSplinePoints - 2, ESplineCoordinateSpace::World, false);
		const FVector LocalPosition = VisualSpline.GetLocationAtSplinePoint(SplineComp.NumberOfSplinePoints - 3, ESplineCoordinateSpace::Local);
		LocalSplinePoints.Add(LocalPosition);
		//System::DrawDebugSphere(SplinePointToAdd, 100.0f, 12, FLinearColor::Red, 5);
	}

	void RemoveLastSegment()
	{
		if(SplineComp.NumberOfSplinePoints == 0)
		{
			return;
		}

		SplineComp.RemoveSplinePoint(SplineComp.NumberOfSplinePoints - 1, true);
		VisualSpline.RemoveSplinePoint(SplineComp.NumberOfSplinePoints - 1, true);
		ActiveSplineMeshes[NumberOfActiveSplineMeshes - 1].SetStartAndEnd(FVector::ZeroVector, FVector::ZeroVector, FVector::ZeroVector, FVector::ZeroVector);
		ActiveSplineMeshes.Remove(AllSplineMeshes[NumberOfActiveSplineMeshes]);
		LocalSplinePoints.RemoveAt(LocalSplinePoints.Num() - 1);
		NumberOfActiveSplineMeshes--;
		UpdateSplineMeshes();
	}

	int GetNumSplinePoints() const
	{
		return SplineComp.NumberOfSplinePoints;
	}

	void UpdateSplineMeshes()
	{
		if(NumberOfActiveSplineMeshes <= 1)
			return;

		for(int Index = 0; Index < NumberOfActiveSplineMeshes; ++Index)
		{
			USplineMeshComponent CurSplineMesh = ActiveSplineMeshes[Index];

			const FVector StartLocation = VisualSpline.GetLocationAtSplinePoint(Index, ESplineCoordinateSpace::Local);
			const FVector StartTangent = VisualSpline.GetTangentAtSplinePoint(Index, ESplineCoordinateSpace::Local);
			const FVector EndLocation = VisualSpline.GetLocationAtSplinePoint(Index + 1, ESplineCoordinateSpace::Local);
			const FVector EndTangent = VisualSpline.GetTangentAtSplinePoint(Index + 1, ESplineCoordinateSpace::Local);

			CurSplineMesh.SetStartAndEnd(StartLocation, StartTangent, EndLocation, EndTangent, true);
		}
	}

	void StretchSplineMesh(float Percent)
	{
		if(NumberOfActiveSplineMeshes == 0)
		{
			return;
		}

		USplineMeshComponent CurSplineMesh = ActiveSplineMeshes[NumberOfActiveSplineMeshes -2];

		float Value = FMath::Max(0.25f, Percent);

		CurSplineMesh.SetEndScale(FVector2D(Value, Value));
	}

	void ClearSplines()
	{
		for(ABeanstalkLeafPair LeafPair : LeafPairCollection)
		{
			if(LeafPair == nullptr)
				continue;
			LeafPair.DespawnLeaf();
		}

		LeafPairCollection.Empty();

		for (USplineMeshComponent CurSplineMesh : ActiveSplineMeshes)
		{
			if(CurSplineMesh == nullptr)
				continue;
			CurSplineMesh.SetStartAndEnd(FVector::ZeroVector, FVector::ZeroVector, FVector::ZeroVector, FVector::ZeroVector);
		}

		ActiveSplineMeshes.Empty();
		SplineComp.ClearSplinePoints();
		VisualSpline.ClearSplinePoints();
		ReversalSplineComp.ClearSplinePoints();
		LocalSplinePoints.Empty();

		NumberOfActiveSplineMeshes = 0;
	}

	float GetSplineLength() const property
	{
		return SplineComp.SplineLength;
	}

	float GetSplineLengthSpill() const
	{
		const float MaxSpill = 300.0f;
		float Frac = 0.0f;

		if(HasReachedMaxHeight())
		{
			float _MaxHeightDiff = HeightDiff - MaxHeight;
			Frac = _MaxHeightDiff / MaxSpill;
		}
		else if(HasReachedMinHeight())
		{
			float _MaxHeightDiff = (HeightDiff + MinHeight) * -1.0f;
			Frac = _MaxHeightDiff / MaxSpill;
		}
		else if(HasReachedMaxLength())
		{
			float MaxLengthDiff = SplineComp.SplineLength - BeanstalkMaxLength;
			Frac = MaxLengthDiff / MaxSpill;
		}

		return Frac;
	}

	float GetDistanceAlongSplineFromLastPoint() const property
	{
		if(SplineComp.NumberOfSplinePoints == 0)
		{
			return 0.0f;
		}

		return SplineComp.GetDistanceAlongSplineAtSplinePoint(SplineComp.NumberOfSplinePoints - 2);
	}

	void GetLeafSpawnParams(FVector& OutLocation, FRotator& OutRotation) const
	{
		OutLocation = LeafPreviewRoot.WorldLocation;
		OutRotation = LeafPreviewRoot.WorldRotation;
	}

	bool HasEnoughDistanceToSpawnLeafPair() const
	{
		return GetSplineLength() - LeafPairDistanceMinimum > LastLeafPairDistance;
	}

	bool CanSpawnNewLeafPair(float& LeftLeafTargetScale, float& RightLeafTargetScale) const
	{
		LeftLeafTargetScale = RightLeafTargetScale = 0.0f;
		if(GetSplineLength() - LeafPairDistanceMinimum < LastLeafPairDistance)
		{
			return false;
		}

		const bool bLeftLeafOk = TestLeafOverlaps(LeftLeafPreview, LeftLeafTargetScale);
		const bool bRightLeafOk = TestLeafOverlaps(RightLeafPreview, RightLeafTargetScale);

		return bLeftLeafOk || bRightLeafOk;
	}

	void OnHitThorns()
	{

	}

	bool TestLeafOverlaps(USceneComponent InLeafRoot, float& TargetScale) const
	{
		TargetScale = 0.0f;

		for(float Scale = 1.1f; Scale > 0.0f; Scale -= 0.3f)
		{
			if(!TestOverlapBox(InLeafRoot, Scale, Scale))
			{
				TargetScale = (Scale * 0.9f);
				return true;
			}
		}

		return false;
	}

	bool TestOverlapBox(USceneComponent InLeafRoot, float ExtentScale, float ForwardScale) const
	{
		const FVector Center = InLeafRoot.GetWorldLocation() + InLeafRoot.GetForwardVector() * (250.0f * ForwardScale);
		const float Width = 200.0f * ExtentScale;
		const FVector Extent(Width, Width, 50.0f);

		TArray<AActor> OutActors;
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(this);
		TArray<EObjectTypeQuery> ObjectTypes;
		ObjectTypes.Add(EObjectTypeQuery::WorldStatic);

		FHitResult OutHit;
		System::BoxTraceSingle(Center, Center + (InLeafRoot.ForwardVector * ExtentScale), 
		Extent, GetClampedLeafRotation(InLeafRoot.WorldRotation), ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, OutHit, false);

#if EDITOR
		//System::DrawDebugBox(Center, Extent, bHit ? FLinearColor::Red : FLinearColor::Green, InLeafRoot.GetWorldRotation(), 1.0f);
#endif // EDITOR
		return OutHit.bBlockingHit;
	}

	FRotator GetClampedLeafRotation(FRotator InRotation) const
	{
		return FRotator(FMath::Clamp(InRotation.Pitch, -LeafPairPitchLimit, LeafPairPitchLimit), InRotation.Yaw, FMath::Clamp(InRotation.Roll, -LeafPairRollLimit, LeafPairRollLimit));
	}

	bool SpawnLeafPair(float LeftLeafTargetScale, float RightLeafTargetScale)
	{
		ABeanstalkLeafPair NewLeafPair = nullptr;
			
		for(int Index = CachedLeafPairs.Num() - 1; Index >= 0; --Index)
		{
			ABeanstalkLeafPair Leaf = CachedLeafPairs[Index];
			if(Leaf.HasFinishidedDespawning())
			{
				NewLeafPair = Leaf;
				CachedLeafPairs.RemoveAt(Index);
				break;
			}
		}

		if(NewLeafPair == nullptr)
			NewLeafPair = Internal_SpawnLeafPair();
		
		if(NewLeafPair == nullptr)
			return false;

		LeafPairCollection.Add(NewLeafPair);

		FVector LeafPairSpawnLocation = GetLeafPairPreviewLocation();
		
		NewLeafPair.SetLeafScale(LeftLeafTargetScale, RightLeafTargetScale);
		NewLeafPair.SpawnLeafPair(LeafPairSpawnLocation, LeafPreviewRoot.WorldRotation);
		BP_OnSpawnLeaf(LeafPreviewRoot.WorldLocation, -LeafPreviewRoot.RightVector, LeafPreviewRoot.RightVector);

		if(LeafPairCollection.Num() > LeafPairsMaximum)
		{
			RemoveFirstLeafPair();
		}
		else
		{
			LastLeafPairDistance = GetDistanceAlongSplineFromLastPoint() - 250.f;
		}
		
		return true;
	}

	// This is where we would like the leaf pair preview to be at
	float GetLeafPairPreviewDistanceTarget() const
	{
		const float DistanceOrigin = VisualSpline.GetDistanceAlongSplineAtWorldLocation(HeadRotationNode.WorldLocation) - BeanstalkSettings.LeafPairDistance;
		const float SplineDistanceOffset = (VisualSpline.SplineLength - SplineComp.SplineLength) * 0.5f;
		const float Distance = DistanceOrigin + SplineDistanceOffset;
		return Distance;
	}

	// This is the current location calculated from the root location of the preview
	FVector GetLeafPairPreviewLocation() const
	{
		const float DistanceToLeafPair = VisualSpline.GetDistanceAlongSplineAtWorldLocation(LeafPreviewRoot.WorldLocation);
		const float SplineDistanceOffset = VisualSpline.SplineLength - SplineComp.SplineLength;
		const float Distance = DistanceToLeafPair - SplineDistanceOffset;
		const FVector Loc = VisualSpline.GetLocationAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World);
		return Loc;
	}

	float GetNearestLeafPairDistanceAlongSpline() const
	{
		if(!HasSpawnedLeafPairs())
			return 1.0f;

		ABeanstalkLeafPair NearestLeafPair = LeafPairCollection[LeafPairCollection.Num() - 1];
		const float NearestLeafPairDistance = VisualSpline.GetDistanceAlongSplineAtWorldLocation(NearestLeafPair.ActorLocation);
		return NearestLeafPairDistance;
	}

	private ABeanstalkLeafPair Internal_SpawnLeafPair()
	{
		if(!devEnsure(LeafPairClass.IsValid(), "No BeanstalkLeafPair class is selected. Spawning will fail."))
			return nullptr;

		ABeanstalkLeafPair LeafPair = Cast<ABeanstalkLeafPair>(SpawnActor(LeafPairClass, LeafPreviewRoot.WorldLocation, LeafPreviewRoot.WorldRotation, bDeferredSpawn = true));
		LeafPair.Beanstalk = this;
		LeafPair.BeanstalkVisualSpline = VisualSpline;
		LeafPair.BeanstalkSpline = SplineComp;
		// Needs to be networked because movement needs it to be this way
		LeafPair.MakeNetworked(this, NetworkSpawnCounter);
		LeafPair.SetControlSide(this);
		FinishSpawningActor(LeafPair);
		NetworkSpawnCounter++;
		MovementComponent.StartIgnoringActor(LeafPair);
		
		return LeafPair;
	}

	bool HasSpawnedLeafPairs() const
	{
		return LeafPairCollection.Num() > 0;
	}

	void RemoveFirstLeafPair()
	{
		if(!HasSpawnedLeafPairs())
			return;

		RemoveHangingMay(ReturnLeafPair(0));
	}

	void RemoveLastLeafPair()
	{
		if(!HasSpawnedLeafPairs())
			return;

		RemoveHangingMay(ReturnLeafPair(LeafPairCollection.Num() - 1));
	}

	// Should be called from BeanstalkSubmergeCapability
	void RemoveAllLeafPairs()
	{
		while(HasSpawnedLeafPairs())
			RemoveHangingMay(ReturnLeafPair(LeafPairCollection.Num() - 1));
	}

	void RemoveHangingMay(ABeanstalkLeafPair RemovedLeafPair) const
	{
		if(RemovedLeafPair == nullptr)
			return;

		// check if May is hanging onto a leaf pair
		if(!HasControl() && RemovedLeafPair != nullptr)
		{
			ULedgeGrabComponent LedgeGrab = ULedgeGrabComponent::Get(Game::GetMay());
			if(LedgeGrab != nullptr && (LedgeGrab.GrabData.LedgeGrabbed == RemovedLeafPair.LeftLeaf || LedgeGrab.GrabData.LedgeGrabbed == RemovedLeafPair.RightLeaf))
			{
				LedgeGrab.LetGoOfLedge(ELedgeReleaseType::LetGo);
				LedgeGrab.SetState(ELedgeGrabStates::None);
			}
		}
	}

	private ABeanstalkLeafPair ReturnLeafPair(int LeafPairIndex)
	{
		if(!devEnsure(LeafPairIndex >= 0))
			return nullptr;

		if(!devEnsure(LeafPairIndex < LeafPairCollection.Num()))
			return nullptr;

		ABeanstalkLeafPair LeafPair = LeafPairCollection[LeafPairIndex];
		LeafPair.DespawnLeaf();
		SetCapabilityAttributeVector(n"AudioOnLeafRemoved", LeafPair.ActorLocation);

		CachedLeafPairs.Add(LeafPair);
		LeafPairCollection.RemoveAt(LeafPairIndex);

		LastLeafPairDistance = !HasSpawnedLeafPairs() ? 0.0f : SplineComp.GetDistanceAlongSplineAtWorldLocation(GetLocationOfLastLeafPair());

		return LeafPair;
	}

	void OnInputPressed(bool bIsMoving)
	{
		FHazeDelegateCrumbParams CrumbParams;

		if(bIsMoving)
			CrumbParams.AddActionState(n"IsMoving");

		CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_OnInputPressed"), CrumbParams);
	}

	UFUNCTION()
	private void Crumb_OnInputPressed(FHazeDelegateCrumbData CrumbData)
	{
		if(CrumbData.GetActionState(n"IsMoving"))
		{
			SetCapabilityActionState(n"IsMoving_Audio", EHazeActionState::Active);
		}
		else
		{
			SetCapabilityActionState(n"IsNotMoving_Audio", EHazeActionState::Active);
		}
	}

	bool IsMoving() const
	{
		return FMath::Abs(WantedMovementDirection) > 0.0f;
	}

	bool HasReachedMaxLength() const
	{
		return SplineComp.SplineLength > BeanstalkMaxLength;
	}

	bool HasReachedMaxMinHeight() const
	{
		return HeightDiff > MaxHeight || HeightDiff < (-MinHeight);
	}

	bool HasReachedMaxHeight() const
	{
		return HeightDiff > MaxHeight;
	}

	bool HasReachedMinHeight() const
	{
		return HeightDiff < (-MinHeight);
	}

	float GetMinHeightDiff() const property
	{
		if(!HasReachedMinHeight())
			return 0.0f;

		const float Diff = HeadRotationNode.WorldLocation.Z - (BeanstalkStartLocation.Z - MinHeight);
		return Diff;
	}

	float GetMaxHeightDiff() const property
	{
		if(!HasReachedMaxHeight())
			return 0.0f;

		const float Diff = (HeadRotationNode.WorldLocation.Z - BeanstalkStartLocation.Z) - MaxHeight;
		return Diff;
	}

	float GetMinMaxHeightDiff() const property
	{
		if(HasReachedMaxHeight())
		{
			return MaxHeightDiff;
		}
		else if(HasReachedMinHeight())
		{
			return MinHeightDiff;
		}

		return 0.0f;
	}

	float GetHeightDiff() const property
	{
		return HeadRotationNode.WorldLocation.Z - BeanstalkStartLocation.Z;
	}

	float GetDistanceOnSplineCurrent() const property
	{
		const float DistanceOnSpline = SplineComp.GetDistanceAlongSplineAtWorldLocation(HeadRotationNode.WorldLocation);
		return DistanceOnSpline;
	}

	float HurtPushback = 0.0f;

	void Hurt(float InPushback)
	{
		if(CurrentState != EBeanstalkState::Active)
			return;

		HurtPushback = InPushback;
		CurrentState = EBeanstalkState::Hurt;
	}

	FVector GetLocationOfLastLeafPair() const property
	{
		if(HasSpawnedLeafPairs())
		{
			return LeafPairCollection[LeafPairCollection.Num() - 1].GetActorLocation();
		}

		return FVector::OneVector;
	}

	FVector GetHeadCenterLocation() const property
	{
		return BeanstalkHead.GetSocketLocation(n"Head");
	}

	FRotator GetTargetRotation() const property
	{
		return HeadRotationNode.GetWorldRotation();
	}

	float GetCurrentMovementDirection() const property
	{
		return WantedMovementDirection;
	}

	FVector GetBeanstalkCenterLocation() const property
	{
		return BeanstalkHead.GetSocketLocation(n"Jaw");
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "OnBeanstalkAppear"))
	void BP_OnBeanstalkAppear(FVector Location, FVector FacingDirection) {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "OnSpawnLeaf"))
	void BP_OnSpawnLeaf(FVector Location, FVector LeftDirection, FVector RightDirection) {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "OnHurt"))
	void BP_OnHurt() {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "OnMaxLengthReached"))
	void BP_OnMaxLengthReached() {}


}

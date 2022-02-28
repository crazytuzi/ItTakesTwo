import Peanuts.Spline.SplineComponent;

event void FPigCartEvent();

class AClockTownPigCart : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CartRoot;

	UPROPERTY(DefaultComponent, Attach = CartRoot)
	UStaticMeshComponent CartMesh;

	UPROPERTY(DefaultComponent, Attach = CartRoot)
	UHazeSkeletalMeshComponentBase LeftOx;

	UPROPERTY(DefaultComponent, Attach = CartRoot)
	UHazeSkeletalMeshComponentBase RightOx;

	UPROPERTY(DefaultComponent, Attach = CartRoot)
	UHazeSkeletalMeshComponentBase Rider;

	UPROPERTY(DefaultComponent, Attach = CartRoot)
	USceneComponent RampRoot;

	UPROPERTY(DefaultComponent, Attach = RampRoot)
	UStaticMeshComponent RampMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayMovementAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopMovementAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayRattleAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopRattleAudioEvent;

	UPROPERTY()
	FPigCartEvent OnReachedEnd;

	UPROPERTY()
	AHazeActor LeftRampTrack;

	UPROPERTY()
	AHazeActor RightRampTrack;

	UPROPERTY()
	AHazeActor LeftCartTrack;

	UPROPERTY()
	AHazeActor RightCartTrack;

	UPROPERTY()
	AHazeActor LeftPig;

	UPROPERTY()
	AHazeActor RightPig;

	UPROPERTY()
	AHazeActor Track;
	UHazeSplineComponent SplineComp;

	float CurrentDistanceAlongSpline = 620.f;
	float SpeedAlongSpline = 500.f;
	bool bMoving = false;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		CartMesh.SetCullDistance(Editor::GetDefaultCullingDistance(CartMesh) * CullDistanceMultiplier);
		LeftOx.SetCullDistance(Editor::GetDefaultCullingDistance(LeftOx) * CullDistanceMultiplier);
		RightOx.SetCullDistance(Editor::GetDefaultCullingDistance(RightOx) * CullDistanceMultiplier);
		Rider.SetCullDistance(Editor::GetDefaultCullingDistance(Rider) * CullDistanceMultiplier);
		RampMesh.SetCullDistance(Editor::GetDefaultCullingDistance(RampMesh) * CullDistanceMultiplier);
		PlatformMesh.SetCullDistance(Editor::GetDefaultCullingDistance(PlatformMesh) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (LeftRampTrack != nullptr)
			LeftRampTrack.AttachToComponent(RampRoot, NAME_None, EAttachmentRule::KeepWorld);
		if (RightRampTrack != nullptr)
			RightRampTrack.AttachToComponent(RampRoot, NAME_None, EAttachmentRule::KeepWorld);
		if (LeftCartTrack != nullptr)
			LeftCartTrack.AttachToComponent(CartRoot, NAME_None, EAttachmentRule::KeepWorld);
		if (RightCartTrack != nullptr)
			RightCartTrack.AttachToComponent(CartRoot, NAME_None, EAttachmentRule::KeepWorld);
		if (LeftPig != nullptr)
			LeftPig.AttachToComponent(CartRoot, NAME_None, EAttachmentRule::KeepWorld);
		if (RightPig != nullptr)
			RightPig.AttachToComponent(CartRoot, NAME_None, EAttachmentRule::KeepWorld);

		if (Track != nullptr)
			SplineComp = UHazeSplineComponent::Get(Track);

		LowerRamp();
	}

	UFUNCTION()
	void RaiseRamp()
	{
		BP_RaiseRamp();
	}

	UFUNCTION(BlueprintEvent)
	void BP_RaiseRamp() {}

	UFUNCTION()
	void LowerRamp()
	{
		BP_LowerRamp();
	}

	UFUNCTION(BlueprintEvent)
	void BP_LowerRamp() {}

	UFUNCTION()
	void StartMoving()
	{
		bMoving = true;
		HazeAkComp.HazePostEvent(PlayMovementAudioEvent);
		HazeAkComp.HazePostEvent(PlayRattleAudioEvent);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bMoving)
			return;

		if (SplineComp == nullptr)
			return;

		CurrentDistanceAlongSpline += SpeedAlongSpline * DeltaTime;
		FTransform CurTransform = SplineComp.GetTransformAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);
		SetActorTransform(CurTransform);

		if (CurrentDistanceAlongSpline >= SplineComp.SplineLength)
		{
			bMoving = false;
			OnReachedEnd.Broadcast();
			LowerRamp();
			HazeAkComp.HazePostEvent(StopMovementAudioEvent);
			HazeAkComp.HazePostEvent(StopRattleAudioEvent);
		}
	}
}
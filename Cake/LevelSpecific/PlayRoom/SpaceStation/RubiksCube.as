import Peanuts.Audio.AudioStatics;

UCLASS(Abstract)
class ARubiksCube : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent RootComp;

    UPROPERTY(DefaultComponent, Attach = RootComp)
    UArrowComponent TopAttachmentPoint;
    default TopAttachmentPoint.RelativeLocation = FVector(0.f, 0.f, 100.f);
    default TopAttachmentPoint.RelativeRotation = FRotator(90.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = TopAttachmentPoint)
	USceneComponent TopRotatePoint;

    UPROPERTY(DefaultComponent, Attach = RootComp)
    UArrowComponent LeftAttachmentPoint;
    default LeftAttachmentPoint.RelativeLocation = FVector(0.f, -100.f, 0.f);
    default LeftAttachmentPoint.RelativeRotation = FRotator(0.f, -90.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = LeftAttachmentPoint)
	USceneComponent LeftRotatePoint;

    UPROPERTY(DefaultComponent, Attach = RootComp)
    UArrowComponent RightAttachmentPoint;
    default RightAttachmentPoint.RelativeLocation = FVector(0.f, 100.f, 0.f);
    default RightAttachmentPoint.RelativeRotation = FRotator(0.f, 90.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = RightAttachmentPoint)
	USceneComponent RightRotatePoint;

    UPROPERTY(DefaultComponent, Attach = RootComp)
    UArrowComponent FrontAttachmentPoint;
    default FrontAttachmentPoint.RelativeLocation = FVector(100.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = FrontAttachmentPoint)
	USceneComponent FrontRotatePoint;

    UPROPERTY(DefaultComponent, Attach = RootComp)
    UArrowComponent BackAttachmentPoint;
    default BackAttachmentPoint.RelativeLocation = FVector(-100.f, 0.f, 0.f);
    default BackAttachmentPoint.RelativeRotation = FRotator(0.f, 180.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = BackAttachmentPoint)
	USceneComponent BackRotatePoint;

    UPROPERTY(DefaultComponent, Attach = RootComp)
    UArrowComponent BottomAttachmentPoint;
    default BottomAttachmentPoint.RelativeLocation = FVector(0.f, 0.f, -100.f);
    default BottomAttachmentPoint.RelativeRotation = FRotator(-90.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = BottomAttachmentPoint)
	USceneComponent BottomRotatePoint;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComponent;

	UPROPERTY(DefaultComponent)
	URotatingMovementComponent RotComp;
	default RotComp.RotationRate = FRotator(8.f, 6.f, 10.f);

	UPROPERTY(EditDefaultsOnly)
    UStaticMesh CubeMeshAsset;

    float DistanceBetweenPieces = 75.f;

    TArray<UStaticMeshComponent> CubeMeshes;

    USceneComponent SideToRotate;

	UPROPERTY()
	bool bStartActive = true;

    UPROPERTY()
    FHazeTimeLike RotateSideTimeLike;
    default RotateSideTimeLike.Duration = 1.f;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent UnsolveRotationEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent SolveRotationEvent;

    float StartRotation;
    float EndRotation;

    UPROPERTY()
    bool bRepeatOnFinished = true;

	UPROPERTY()
	float StartDelay = 0.f;

	UPROPERTY()
	float DelayBetweenRotations = 1.f;

	TArray<float> SavedRots;
	TArray<USceneComponent> RotatedSides;

	bool bSolving = false;

	int SpinsBeforeSolve;
	int CurrentSpins;
	FVector2D SpinsBeforeSolveRange = FVector2D(8.f, 20.f);

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.f;

	FTimerHandle RotateSideTimerHandle;

	TArray<FTransform> InitialTransforms;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		SetSpinsBeforeSolve();

		RotateSideTimeLike.SetPlayRate(2.f);
        RotateSideTimeLike.BindUpdate(this, n"UpdateRotateSide");
        RotateSideTimeLike.BindFinished(this, n"FinishRotateSide");

        TArray<UActorComponent> Comps;
        GetAllComponents(UStaticMeshComponent::StaticClass(), Comps);

        for (UActorComponent Comp : Comps)
        {
            CubeMeshes.Add(Cast<UStaticMeshComponent>(Comp));
			InitialTransforms.Add(Cast<UStaticMeshComponent>(Comp).RelativeTransform);
        }

		if (bStartActive)
		{
			if (StartDelay == 0.f)
				RotateRandomSide();
			else
				System::SetTimer(this, n"RotateRandomSide", StartDelay, false);
		}
    }

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		RotateSideTimeLike.Stop();
		System::ClearAndInvalidateTimerHandle(RotateSideTimerHandle);

		RotatedSides.Empty();
		SavedRots.Empty();
		CurrentSpins = 0;
		SpinsBeforeSolve = 0;
		bSolving = false;

		TopRotatePoint.SetRelativeRotation(FRotator::ZeroRotator);
		BottomRotatePoint.SetRelativeRotation(FRotator::ZeroRotator);
		LeftRotatePoint.SetRelativeRotation(FRotator::ZeroRotator);
		RightRotatePoint.SetRelativeRotation(FRotator::ZeroRotator);
		FrontRotatePoint.SetRelativeRotation(FRotator::ZeroRotator);
		BackRotatePoint.SetRelativeRotation(FRotator::ZeroRotator);

		for (int Index = 0, Count = InitialTransforms.Num(); Index < Count; ++ Index)
		{
			CubeMeshes[Index].DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
			CubeMeshes[Index].AttachToComponent(RootComp, NAME_None, EAttachmentRule::KeepWorld);
			CubeMeshes[Index].SetRelativeTransform(InitialTransforms[Index]);
		}

		if (bStartActive)
		{
			if (StartDelay == 0.f)
				RotateRandomSide();
			else
				System::SetTimer(this, n"RotateRandomSide", StartDelay, false);
		}
	}

	void SetSpinsBeforeSolve()
	{
		SpinsBeforeSolve = FMath::RandRange(SpinsBeforeSolveRange.Min, SpinsBeforeSolveRange.Max);
	}

    UFUNCTION()
    void RotateRandomSide()
    {
        if (IsAlreadyRotating())
            return;

        int RandomInt = FMath::RandRange(0, 5);

        if (RandomInt == 0)
            SideToRotate = TopRotatePoint;
        else if (RandomInt == 1)
            SideToRotate = LeftRotatePoint;
        else if (RandomInt == 2)
            SideToRotate = RightRotatePoint;
        else if (RandomInt == 3)
            SideToRotate = FrontRotatePoint;
        else if (RandomInt == 4)
            SideToRotate = BackRotatePoint;
        else if (RandomInt == 5)
            SideToRotate = BottomRotatePoint;

        StartRotatingSide();
    }

    UFUNCTION()
    void RotateSpecificSide(ERubiksCubeSide Side)
    { 
        if (IsAlreadyRotating())
            return;

        switch (Side)
        {
            case ERubiksCubeSide::Top:
                SideToRotate = TopRotatePoint;
            break;
            case ERubiksCubeSide::Left:
                SideToRotate = LeftRotatePoint;
            break;
            case ERubiksCubeSide::Right:
                SideToRotate = RightRotatePoint;
            break;
            case ERubiksCubeSide::Front:
                SideToRotate = FrontRotatePoint;
            break;
            case ERubiksCubeSide::Back:
                SideToRotate = BackRotatePoint;
            break;
            case ERubiksCubeSide::Bottom:
                SideToRotate = BottomRotatePoint;
            break;
        }

        StartRotatingSide();
    }

    void StartRotatingSide()
    {
		if (bSolving)
		{
			SideToRotate = RotatedSides.Last();
			StartRotation = SideToRotate.RelativeRotation.Roll;
			EndRotation = SavedRots.Last();
			RotatedSides.RemoveAt(RotatedSides.Num() - 1);
			SavedRots.RemoveAt(SavedRots.Num() - 1);

			if (SolveRotationEvent != nullptr)
				UHazeAkComponent::HazePostEventFireForget(SolveRotationEvent, ActorTransform);
		}
		else
		{
			int RotValue = FMath::RandBool() ? -90 : 90;

			StartRotation = SideToRotate.RelativeRotation.Roll;
			EndRotation = SideToRotate.RelativeRotation.Roll + RotValue;

			RotatedSides.Add(SideToRotate);
			SavedRots.Add(StartRotation);

			CurrentSpins++;

			if (UnsolveRotationEvent != nullptr)
				UHazeAkComponent::HazePostEventFireForget(UnsolveRotationEvent, ActorTransform);
		}

		TArray<UPrimitiveComponent> OverlappingComponents;
		Trace::CapsuleOverlapComponents(SideToRotate.WorldLocation, SideToRotate.WorldRotation, 50.f * ActorScale3D.Z, 100.f * ActorScale3D.Z, n"OverlapAllDynamic", OverlappingComponents);

		for (UPrimitiveComponent PrimComp : OverlappingComponents)
		{
			UStaticMeshComponent StaticMeshComp = Cast<UStaticMeshComponent>(PrimComp);

			if (StaticMeshComp != nullptr && CubeMeshes.Contains(StaticMeshComp))
			{
				StaticMeshComp.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, false);
				StaticMeshComp.AttachToComponent(SideToRotate, AttachmentRule = EAttachmentRule::KeepWorld);
			}
		}

        RotateSideTimeLike.PlayFromStart();
    }

	UFUNCTION()
	void StartSolvingCube()
	{
		CurrentSpins = 0;
		SetSpinsBeforeSolve();
		bSolving = true;
		RotateSideTimeLike.SetPlayRate(5.5f);
		StartRotatingSide();
	}

    bool IsAlreadyRotating()
    {
        return RotateSideTimeLike.IsPlaying();
    }

    UFUNCTION(NotBlueprintCallable)
    void UpdateRotateSide(float Value)
    {
        float CurYaw = FMath::Lerp(StartRotation, EndRotation, Value);

        SideToRotate.SetRelativeRotation(FRotator(0.f, 0.f, CurYaw));
    }

    UFUNCTION(NotBlueprintCallable)
    void FinishRotateSide()
    {
		if (CurrentSpins >= SpinsBeforeSolve)
		{
			StartSolvingCube();
		}

		else if (bSolving && RotatedSides.Num() != 0)
		{
			StartRotatingSide();
		}

        else if (bRepeatOnFinished)
		{
			bSolving = false;
			RotateSideTimeLike.SetPlayRate(2.f);
            RotateSideTimerHandle = System::SetTimer(this, n"RotateRandomSide", DelayBetweenRotations, false);
		}
    }

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        CubeMeshes.Empty();

        for (int Index = 0, Count = 9; Index < Count; ++ Index)
        {
            UStaticMeshComponent CubeMeshComp = UStaticMeshComponent(this);
            CubeMeshComp.SetStaticMesh(CubeMeshAsset);
			CubeMeshComp.SetCastShadow(false);

            if (Index < 3)
            {
                CubeMeshComp.SetRelativeLocation(FVector(DistanceBetweenPieces, -DistanceBetweenPieces + (Index * DistanceBetweenPieces), + DistanceBetweenPieces));
            }
            else if (Index >= 3 && Index < 6)
            {
                CubeMeshComp.SetRelativeLocation(FVector(0.f, -DistanceBetweenPieces + (Index - 3) * DistanceBetweenPieces, DistanceBetweenPieces));
            }
            else if (Index >= 6)
            {
                CubeMeshComp.SetRelativeLocation(FVector(-DistanceBetweenPieces, -DistanceBetweenPieces + (Index - 6) * 75, DistanceBetweenPieces));
            }
            CubeMeshes.Add(CubeMeshComp);
        }

        for (int Index = 0, Count = 9; Index < Count; ++ Index)
        {
            UStaticMeshComponent CubeMeshComp = UStaticMeshComponent(this);
            CubeMeshComp.SetStaticMesh(CubeMeshAsset);
			CubeMeshComp.SetCastShadow(false);

            if (Index < 3)
            {
                CubeMeshComp.SetRelativeLocation(FVector(DistanceBetweenPieces, -DistanceBetweenPieces + (Index * DistanceBetweenPieces), 0.f));
            }
            else if (Index >= 3 && Index < 6)
            {
                CubeMeshComp.SetRelativeLocation(FVector(0.f, -DistanceBetweenPieces + (Index - 3) * DistanceBetweenPieces, 0.f));
            }
            else if (Index >= 6)
            {
                CubeMeshComp.SetRelativeLocation(FVector(-DistanceBetweenPieces, -DistanceBetweenPieces + (Index - 6) * 75, 0.f));
            }
            CubeMeshes.Add(CubeMeshComp);
        }

        for (int Index = 0, Count = 9; Index < Count; ++ Index)
        {
            UStaticMeshComponent CubeMeshComp = UStaticMeshComponent(this);
            CubeMeshComp.SetStaticMesh(CubeMeshAsset);
			CubeMeshComp.SetCastShadow(false);

            if (Index < 3)
            {
                CubeMeshComp.SetRelativeLocation(FVector(DistanceBetweenPieces, -DistanceBetweenPieces + (Index * DistanceBetweenPieces), -DistanceBetweenPieces));
            }
            else if (Index >= 3 && Index < 6)
            {
                CubeMeshComp.SetRelativeLocation(FVector(0.f, -DistanceBetweenPieces + (Index - 3) * DistanceBetweenPieces, -DistanceBetweenPieces));
            }
            else if (Index >= 6)
            {
                CubeMeshComp.SetRelativeLocation(FVector(-DistanceBetweenPieces, -DistanceBetweenPieces + (Index - 6) * 75, -DistanceBetweenPieces));
            }
            CubeMeshes.Add(CubeMeshComp);
        }
    }
}

enum ERubiksCubeSide
{
    Top,
    Left,
    Right,
    Front,
    Back,
    Bottom
}